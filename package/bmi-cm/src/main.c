#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <string.h>
#include <errno.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <pthread.h>
#include <alloca.h>
#include "atchannel.h"
#include <getopt.h>
#include <sys/socket.h>
#include <sys/wait.h>
#include <termios.h>

//static int s_port = -1;
static const char * s_device_path = "/dev/ttyUSB2";
static char * ppp_tty_path = "/dev/ttyUSB10";

static pthread_mutex_t s_state_mutex = PTHREAD_MUTEX_INITIALIZER;
static pthread_cond_t s_state_cond = PTHREAD_COND_INITIALIZER;

static int s_closed = 0;
//static int flag_creg = 0;
//static int flag_cereg = 0;
static int supportedTechs = -1;
static int currentoperator = -1;//0:w,1:c,2:t
static int data_active = -1;

static const struct timeval TIMEVAL_0 = {0,0};

pthread_t s_tid_mainloop;

void probeForModemMode()
{
    int err;
    char *line;
    ATResponse *p_response = NULL;

    err = at_send_command_numeric("AT+QCIMI", &p_response);
    if (err < 0 || p_response->success == 0){
        err = at_send_command_numeric("AT+CIMI", &p_response);
        if (err < 0 || p_response->success == 0) {
            printf("Unknown operator!");
            at_response_free(p_response);
            return;
        }
    }

    line = p_response->p_intermediates->line;
    *(line+5) = '\0';
    if (strcmp(line,"46003") == 0 || strcmp(line,"46011") == 0 || strcmp(line,"46005") == 0 || strcmp(line,"46009") == 0)
        currentoperator = 1;  
    else if (strcmp(line,"46000") == 0 || strcmp(line,"46002") == 0 || strcmp(line,"46007") == 0)
        currentoperator = 2;
    else if (strcmp(line,"46001") == 0 || strcmp(line,"46006") == 0 || strcmp(line,"46010") == 0 || strcmp(line,"46020") == 0)
        currentoperator = 0;
    else
        printf("Request not supported %s ",line);

    at_response_free(p_response);
}
void supportedTechstate() 
{
    ATResponse *p_response = NULL;
    const char *cmd;
    const char *prefix;
    char *line;
    int err=0;
	
    cmd = "AT+BMRAT";
    prefix = "+BMRAT:";
    err = at_send_command_singleline(cmd, prefix, &p_response);
    if (err == 0 && p_response->success != 0) {
	line = p_response->p_intermediates->line;
	err = at_tok_start(&line);
	if (err == 0) {
            if ((strstr(line, "LTE") != NULL) || (strstr(line, "FDD LTE") != NULL) || (strstr(line, "TDD LTE") != NULL)){
                supportedTechs = 1;
	    }else if (strstr(line, "TDS") != NULL){
                supportedTechs = 2;
            }else if (strstr(line, "UMTS") != NULL){
                supportedTechs = 3;
            }else if (strstr(line, "WCDMA") != NULL){
                supportedTechs = 4;
	    }else if (strstr(line, "HSDPA") != NULL){
                supportedTechs = 5;
	    }else if (strstr(line, "HSDPA+") != NULL){
                supportedTechs = 6;
	    }else if (strstr(line, "DC HSDPA") != NULL){
                supportedTechs = 7;
	    }else if (strstr(line, "HSUPA") != NULL){
                supportedTechs = 8;
            }else if (strstr(line, "HSPA+") != NULL){
                supportedTechs = 9;
	    }else if (strstr(line, "GPRS") != NULL){
                supportedTechs = 10;
            }else if (strstr(line, "EDGE") != NULL){
                supportedTechs = 11;
            }else if (strstr(line, "HSPA") != NULL){
                supportedTechs = 12;
	    }else if (strstr(line, "1x") != NULL){   
                supportedTechs = 13;
            }else if (strstr(line, "HDR RevA") != NULL){
                supportedTechs = 14;
            }else if (strstr(line, "HDR RevB") != NULL){
                supportedTechs = 15;
            }else if (strstr(line, "HDR Rev0") != NULL){
                supportedTechs = 16;  
            }else if (strstr(line, "GSM") != NULL){
                supportedTechs = 17;             
	    }else {
                 supportedTechs = 0;          
            }
        }
    }
}

int requestRegistrationState()
{
    ATResponse *p_response = NULL;
    int response[4];
    const char *cmd;
    const char *prefix;
    char *line;
    int err=0;
    
    cmd = "AT^SYSINFO";
    prefix = "^SYSINFO:";
  
    err = at_send_command_singleline(cmd, prefix, &p_response);

    if ((err != 0) || (p_response->success == 0) ) {
	    printf("no registration");
	    return 0;
    }
    line = p_response->p_intermediates->line;

    err = at_tok_start(&line);
    if (err < 0) return 0;
    at_tok_nextint(&line, &response[0]);
    at_tok_nextint(&line, &response[1]);
    at_tok_nextint(&line, &response[2]);
    at_tok_nextint(&line, &response[3]);

    if((response[0] != 0) && (response[0] != 4) && (response[1] == 2 || response[1] == 3 || response[1] == 255)){
        return 1;
    }else{
        return 0;
    }
}

void stopDhcp()
{
    system("killall udhcpc");    
    if((13 == supportedTechs) || (14 == supportedTechs) || (15 == supportedTechs) || (16 == supportedTechs)){
        at_send_command("AT$QCRMCALL=0,1,1,1", NULL);
        at_send_command("AT$QCRMCALL=0,1", NULL);
    }else{
        at_send_command("AT$QCRMCALL=0,1,1,2,1", NULL);
        at_send_command("AT$QCRMCALL=0,1", NULL);
    } 
}

void requestSetupDataCall()
{
    char *line;
    ATResponse *p_response = NULL;
    int retry=7;
    int response;

    if((13 == supportedTechs) || (14 == supportedTechs) || (15 == supportedTechs) || (16 == supportedTechs)){
        at_send_command("AT$QCRMCALL=1,1,1,1", NULL);
    }else{
        at_send_command("AT$QCRMCALL=1,1,1,2,1", NULL);
    }
    system("udhcpc -i wwan0");

   do {
       at_send_command_singleline("AT+BMDATASTATUS", "+BMDATASTATUS:", &p_response);
       line = p_response->p_intermediates->line;
       at_tok_start(&line);
       at_tok_nextint(&line, &response);  
       if (response == 1){
           printf("success\n");
           break;
        }
           sleep(3);
   } while (--retry);

    if(retry == 0){
        printf("dhcp fail!\n"); 
        stopDhcp(); 
        data_active = 0;
    }else{
        at_send_command_singleline("AT+DHCP4?", "+DHCP4:", &p_response);
        data_active = 1;
    }
}

int getSIMStatus()
{
    ATResponse *p_response = NULL;
    int err;
    err = at_send_command_singleline("AT+CPIN?", "+CPIN:", &p_response);
    if ((err != 0) || (p_response->success == 0)) {
        printf("SIM_NOT_READY\n");
        return 0;
    }else{
        return 1;
    }
}

int findusb0()
{
    char cmd[256]={0};
    int fd = -1;
    sprintf(cmd, "/sys/class/net/%s", "wwan0");
    fd  = open(cmd, O_RDONLY);
    if (fd < 0) {
        printf("NO INTERFACE >>>look kernel!!\n");
	return 0;
    }
    close(fd);

    system("ifconfig wwan0 up");
    return 1;
}

static void onUnsolicited (const char *s, const char *sms_pdu)
{
//    char *line = NULL;
//    int err;

    if (strStartsWith(s,"RING")
                || strStartsWith(s,"+CRING:")
                || strStartsWith(s,"+CCWA:")
                || strStartsWith(s,"^CEND:")
                || strStartsWith(s,"+DISC:")
                || strStartsWith(s,"NO CARRIER")

    ){
        printf ("RIL_UNSOL_RESPONSE_CALL_STATE_CHANGED\n");

    } else if (strStartsWith(s,"+CREG:")
                || strStartsWith(s,"+CGREG:")
                || strStartsWith(s,"+CEREG:")
                || strStartsWith(s,"^MODE:")
    ) {
       printf("RIL_UNSOL_RESPONSE_VOICE_NETWORK_STATE_CHANGED\n");
    } else if (strStartsWith(s, "^DATADISCONN")) {
 //       RIL_requestTimedCallback (onDeactiveDataCallList, NULL, NULL);
    } 
}

static void *dhcp_main_loop()	
{		
    unsigned int count = 3;
    char *line;
    ATResponse *p_response = NULL;
    int response;

    for(;;){
        if(data_active == 1){

 //           at_send_command("AT+BMTCELLINFO", NULL);	
            at_send_command("AT^SYSINFO", NULL);	
            at_send_command("AT+CSQ", NULL);
            supportedTechstate();
                    
            count = 3;
            do {
                at_send_command_singleline("AT+BMDATASTATUS", "+BMDATASTATUS:", &p_response);
                line = p_response->p_intermediates->line;
                at_tok_start(&line);
                at_tok_nextint(&line, &response);  
                if (response == 1){
                    printf("bmdatastatus is ok!!!\n");
                    data_active = 1;
                    break;
                }else{
                    printf("bmdatastatus is bad!!!\n");
                    data_active = 0;                     
                }
                sleep(3);
             } while (--count);

	     if((0 == count)&&(data_active == 0))
	     {
                  stopDhcp();             	
             }

        }else if(0 == data_active){

            at_send_command("AT+BMTCELLINFO", NULL);	
            at_send_command("AT^SYSINFO", NULL);	
            at_send_command("AT+CSQ", NULL);

            while(1 == getSIMStatus()){
                sleep(3);
                break;
            }

            if(1 == requestRegistrationState()){
                if (0 == findusb0()) continue;
                supportedTechstate(); 
                requestSetupDataCall();
            }
        }

        sleep(4);

    }
	return ((void *)0);
}

int start_dhcp_check_pthread()
{	
    int ret = -1;
    pthread_attr_t attr;
    pthread_attr_init (&attr);
    pthread_attr_setdetachstate(&attr, PTHREAD_CREATE_DETACHED);
    ret = pthread_create(&s_tid_mainloop, &attr, dhcp_main_loop,  NULL);
    return ret;
}

void getVersion(void)
{
    printf("arm32 ver1.0 -180809\n");
}

static void initializeCallback(void)
{
    int ret;

    getVersion();

    at_send_command("ATE0Q0V1", NULL);
    at_send_command("ATS0=0", NULL);
    at_send_command("AT+CMEE=1", NULL);
    at_send_command("AT+CFUN=1", NULL);
    at_send_command("AT+BMMODODR=5", NULL);
    at_send_command("AT+BMDATASTATUSEN=1", NULL);	
    at_send_command("AT^SYSINFO", NULL);	
    at_send_command("AT+CSQ", NULL);
    at_send_command("AT+BMRAT", NULL);
    at_send_command("ATI", NULL);
    at_send_command("AT+BMMEID", NULL);
    at_send_command("AT+BMSWVER", NULL);
    at_send_command("AT+CGSN", NULL);

    if(1 == getSIMStatus()){
        probeForModemMode();
    }else
        return;

    if(currentoperator == 1){
	at_send_command("AT+CGDCONT=1,\"IP\",\"ctnet\"",NULL);
        at_send_command("AT+BM3GPP2CGDCONT=0,3,ctnet@mycdma.cn,vnet.mobi,ctnet,2,3,0",NULL);
    }else if(currentoperator == 2){
	at_send_command("AT+CGDCONT=1,\"IP\",\"cmnet\"",NULL);
    }else if(currentoperator == 0){
	at_send_command("AT+CGDCONT=1,\"IP\",\"3gnet\"",NULL);
    }else{
        at_send_command("AT+CGDCONT=1,\"IP\",\"\"",NULL);
    }

    if(1 == requestRegistrationState()){
        if (0 == findusb0()) return;
        supportedTechstate(); 
        requestSetupDataCall();
    }else{
        data_active = 0;
    }

    if((ret = start_dhcp_check_pthread())<0)
    {
        printf("start_dhcp_check_pthread failed\n");
        return;
    }

}

static void waitForClose()
{
    pthread_mutex_lock(&s_state_mutex);

    while (s_closed == 0) {
        pthread_cond_wait(&s_state_cond, &s_state_mutex);
    }

    pthread_mutex_unlock(&s_state_mutex);
}


static void usage(char *s)
{
    printf("usage: %s [-d <at port>] [-m <modem port>\n", s);
 //   exit(-1);
}

static void *mainLoop(void *param)
{
    int fd;
    int ret;
    for (;;) {
        fd = -1;
        while  (fd < 0) {
            if (s_device_path != NULL) {
                fd = open (s_device_path, O_RDWR);
                if ( fd >= 0 && !memcmp( s_device_path, "/dev/ttyU", 9 )) {

                    /* disable echo on serial ports */
                    struct termios  ios;   
                    tcgetattr( fd, &ios );
                    ios.c_lflag = 0;  /* disable ECHO, ICANON, etc... */
                    tcsetattr( fd, TCSANOW, &ios );

                }
            }

            if (fd < 0) {
                printf("opening AT interface. retrying...\n");
                sleep(10);
                /* never returns */
            }
        }

        s_closed = 0;
        ret = at_open(fd, onUnsolicited);

        if (ret < 0) {
            printf("AT error %d on at_open\n", ret);
            return 0;
        }     
       initializeCallback();

        sleep(1);

        waitForClose();
        printf("Re-opening after close\n");
   }
   at_close();
}

void Stop(int signo) 
{
    printf("oops! stop!!!\n");
    system("killall  udhcpc");
    at_close();
    _exit(0);
}

int main (int argc, char **argv)
{
//    int ret;
//    int fd = -1;
    int opt;

	signal(SIGINT, Stop); 
    while ( -1 != (opt = getopt(argc, argv, "d:m:"))) {
        switch (opt) {
            case 'd':
                s_device_path = optarg;
                printf("Opening at port %s\n", s_device_path);
            break;

            case 'm':
                ppp_tty_path = optarg;
                printf("Opening modem port %s\n", ppp_tty_path);
            break;
            case 'h':
                usage(argv[0]);
                break;

            default:
                s_device_path = "/dev/ttyUSB2";
                ppp_tty_path = "/dev/ttyUSB1";
        }
    }

    mainLoop(NULL);

    return 0;
}

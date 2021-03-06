#!/bin/sh

ROOTER=/usr/lib/rooter

log() {
	logger -t "USB730 Data" "$@"
}

CURRMODEM=$1
COMMPORT=$2

fix_data() {
	OY=$(echo $OY)
	O=$($ROOTER/common/processat.sh "$OY")
	O=$(echo $O" " | tr "$" "+")
}

process_csq() {
	CSQ=$(echo "$O" | awk -F[,\ ] '/^\+CSQ:/ {print $2}')
	[ "x$CSQ" = "x" ] && CSQ=-1
	if [ $CSQ -ge 0 -a $CSQ -le 31 ]; then
		CSQ_PER=$(($CSQ * 100/31))
		CSQ_RSSI=$((2 * CSQ - 113))
		CSQX=$CSQ_RSSI
		[ $CSQ -eq 0 ] && CSQ_RSSI="<= "$CSQ_RSSI
		[ $CSQ -eq 31 ] && CSQ_RSSI=">= "$CSQ_RSSI
		CSQ_PER=$CSQ_PER"%"
		CSQ_RSSI=$CSQ_RSSI" dBm"
	else
		CSQ="-"
		CSQ_PER="-"
		CSQ_RSSI="-"
	fi
}

CSQ="-"
CSQ_PER="-"
CSQ_RSSI="-"
ECIO="-"
RSCP="-"
ECIO1=" "
RSCP1=" "
MODE="-"
MODETYPE="-"
NETMODE="-"
LBAND="-"
TEMP="-"

OY=$($ROOTER/gcom/gcom-locked "$COMMPORT" "novatelinfo.gcom" "$CURRMODEM")

fix_data
process_csq

DEG=$(echo $O" " | grep -o "+NWDEGC: .\+ OK " | tr " " ",")
TMP=$(echo $DEG | cut -d, -f2)
if [ ! -z "$TMP" ]; then
	TEMP=$TMP"°C"
fi

MODE="-"
PSRAT=$(echo $O" " | grep -o "+NWRAT: .\+ OK " | tr " " ",")
TECH=$(echo $PSRAT | cut -d, -f4)
if [ ! -z "$TECH" ]; then
	case "$TECH" in
		"1"|"2"|"3")
			MODE="UMTS"
			;;
		"4"|"5"|"6")
			MODE="GSM"
			;;
		"7"|"8"|"9")
			MODE="LTE"
			RSRP=$(echo $O" " | grep -o "+VZWRSRP: .\+ OK " | tr " " ",")
			TMP=$(echo $RSRP | cut -d, -f4)
			if [ ! -z "$TMP" ]; then
				temp="${TMP%\"}"
				temp="${temp#\"}"
				RSCP=$temp" (RSRP)"
			fi
			RSRQ=$(echo $O" " | grep -o "+VZWRSRQ: .\+ OK " | tr " " ",")
			TMP=$(echo $RSRQ | cut -d, -f4)
			if [ ! -z "$TMP" ]; then
				temp="${TMP%\"}"
				temp="${temp#\"}"
				ECIO=$temp" (RSRQ)"
			fi
			;;
		*)
			MODE="CDMA/HDR"
			;;
	esac
fi


echo 'CSQ="'"$CSQ"'"' > /tmp/signal$CURRMODEM.file
echo 'CSQ_PER="'"$CSQ_PER"'"' >> /tmp/signal$CURRMODEM.file
echo 'CSQ_RSSI="'"$CSQ_RSSI"'"' >> /tmp/signal$CURRMODEM.file
echo 'ECIO="'"$ECIO"'"' >> /tmp/signal$CURRMODEM.file
echo 'RSCP="'"$RSCP"'"' >> /tmp/signal$CURRMODEM.file
echo 'ECIO1="'"$ECIO1"'"' >> /tmp/signal$CURRMODEM.file
echo 'RSCP1="'"$RSCP1"'"' >> /tmp/signal$CURRMODEM.file
echo 'MODE="'"$MODE"'"' >> /tmp/signal$CURRMODEM.file
echo 'MODTYPE="'"$MODTYPE"'"' >> /tmp/signal$CURRMODEM.file
echo 'NETMODE="'"$NETMODE"'"' >> /tmp/signal$CURRMODEM.file
echo 'LBAND="'"$LBAND"'"' >> /tmp/signal$CURRMODEM.file
echo 'TEMP="'"$TEMP"'"' >> /tmp/signal$CURRMODEM.file

CONNECT=$(uci get modem.modem$CURRMODEM.connected)
if [ $CONNECT -eq 0 ]; then
	exit 0
fi

ENB="0"
if [ -e /etc/config/failover ]; then
	ENB=$(uci get failover.enabled.enabled)
fi
if [ $ENB = "1" ]; then
	exit 0
fi

WWANX=$(uci get modem.modem$CURRMODEM.interface)
OPER=$(cat /sys/class/net/$WWANX/operstate 2>/dev/null)

if [ ! $OPER ]; then
	exit 0
fi
if echo $OPER | grep -q "unknown"; then
	exit 0
fi

if echo $OPER | grep -q "down"; then
	echo "1" > "/tmp/connstat"$CURRMODEM
fi

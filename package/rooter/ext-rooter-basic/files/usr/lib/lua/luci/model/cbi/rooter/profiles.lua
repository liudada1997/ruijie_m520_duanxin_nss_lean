local utl = require "luci.util"

local maxmodem = luci.model.uci.cursor():get("modem", "general", "max")

m = Map("profile", translate("模块连接配置文件"),
	translate("创建用于在连接时提供信息的配置文件"))

m.on_after_commit = function(self)
	--luci.sys.call("/etc/modpwr")
end

--
-- Default profile
--

di = m:section(TypedSection, "default", translate("默认 配置文件"), translate("在未找到匹配的自定义配置文件时使用"))
di.anonymous = true
di:tab("default", translate("默认"))
di:tab("advance", translate("高级"))
di:tab("connect", translate("连接 监视"))

this_tab = "default"

ma = di:taboption(this_tab, Value, "apn", "APN :"); 
ma.rmempty = true;

mu = di:taboption(this_tab, Value, "user", "连接用户名 :"); 
mu.optional=false; 
mu.rmempty = true;

mp = di:taboption(this_tab, Value, "passw", "连接密码 :"); 
mp.optional=false; 
mp.rmempty = true;
mp.password = true

mpi = di:taboption(this_tab, Value, "pincode", "PIN :"); 
mpi.optional=false; 
mpi.rmempty = true;

mau = di:taboption(this_tab, ListValue, "auth", "身份验证协议 :")
mau:value("0", "None")
mau:value("1", "PAP")
mau:value("2", "CHAP")
mau.default = "0"

this_taba = "advance"

mf = di:taboption(this_taba, ListValue, "ppp", "强制使用模块为PPP协议 :");
mf:value("0", "No")
mf:value("1", "Yes")
mf.default=0

md = di:taboption(this_taba, Value, "delay", "连接延迟（秒） :"); 
md.optional=false; 
md.rmempty = false;
md.default = 5
md.datatype = "and(uinteger,min(5))"

ml = di:taboption(this_taba, ListValue, "lock", "锁定与提供程序的连接 :");
ml:value("0", "No")
ml:value("1", "Yes")
ml.default=0

mcc = di:taboption(this_taba, Value, "mcc", "提供商国家代码 :");
mcc.optional=false; 
mcc.rmempty = true;
mcc.datatype = "and(uinteger,min(1),max(999))"
mcc:depends("lock", "1")

mnc = di:taboption(this_taba, Value, "mnc", "提供商网络代码 :");
mnc.optional=false; 
mnc.rmempty = true;
mnc.datatype = "and(uinteger,min(1),max(999))"
mnc:depends("lock", "1")

mdns1 = di:taboption(this_taba, Value, "dns1", "自定义DNS服务器1 :"); 
mdns1.rmempty = true;
mdns1.optional=false;
mdns1.datatype = "ipaddr"

mdns2 = di:taboption(this_taba, Value, "dns2", "自定义DNS服务器2 :"); 
mdns2.rmempty = true;
mdns2.optional=false;
mdns2.datatype = "ipaddr"

mdns3 = di:taboption(this_taba, Value, "dns3", "自定义DNS服务器3 :"); 
mdns3.rmempty = true;
mdns3.optional=false;
mdns3.datatype = "ipaddr"

mdns4 = di:taboption(this_taba, Value, "dns4", "自定义DNS服务器4 :"); 
mdns4.rmempty = true;
mdns4.optional=false;
mdns4.datatype = "ipaddr"


mlog = di:taboption(this_taba, ListValue, "log", "启用连接日志记录 :");
mlog:value("0", "No")
mlog:value("1", "Yes")
mlog.default=0

if nixio.fs.access("/etc/config/mwan3") then
	mlb = di:taboption(this_taba, ListValue, "lb", "在连接时启用负载均衡 :");
	mlb:value("0", "No")
	mlb:value("1", "Yes")
	mlb.default=0
end

mat = di:taboption(this_taba, ListValue, "at", "在连接时启用AT返回信息 :");
mat:value("0", "No")
mat:value("1", "Yes")
mat.default=0

matc = di:taboption(this_taba, Value, "atc", "启动时自定义命令 :");
matc.optional=false;
matc.rmempty = true;

--
-- Default Connection Monitoring
--

this_tab = "connect"

alive = di:taboption(this_tab, ListValue, "alive", "连接监视状态 :"); 
alive.rmempty = true;
alive:value("0", "关闭")
alive:value("1", "启用")
alive:value("2", "开启路由重新启动")
alive:value("3", "开启模块重新连接")
alive:value("4", "通过电源开关或调制解调器重新连接启用")
alive.default=0

reliability = di:taboption(this_tab, Value, "reliability", translate("Tracking reliability"),
		translate("Acceptable values: 1-100. This many Tracking IP addresses must respond for the link to be deemed up"))
reliability.datatype = "range(1, 100)"
reliability.default = "1"
reliability:depends("alive", "1")
reliability:depends("alive", "2")
reliability:depends("alive", "3")
reliability:depends("alive", "4")

count = di:taboption(this_tab, ListValue, "count", translate("Ping count"))
count.default = "1"
count:value("1")
count:value("2")
count:value("3")
count:value("4")
count:value("5")
count:depends("alive", "1")
count:depends("alive", "2")
count:depends("alive", "3")
count:depends("alive", "4")

interval = di:taboption(this_tab, ListValue, "pingtime", translate("Ping interval"),
		translate("Amount of time between tracking tests"))
interval.default = "10"
interval:value("5", translate("5 seconds"))
interval:value("10", translate("10 seconds"))
interval:value("20", translate("20 seconds"))
interval:value("30", translate("30 seconds"))
interval:value("60", translate("1 minute"))
interval:value("300", translate("5 minutes"))
interval:value("600", translate("10 minutes"))
interval:value("900", translate("15 minutes"))
interval:value("1800", translate("30 minutes"))
interval:value("3600", translate("1 hour"))
interval:depends("alive", "1")
interval:depends("alive", "2")
interval:depends("alive", "3")
interval:depends("alive", "4")

timeout = di:taboption(this_tab, ListValue, "pingwait", translate("Ping timeout"))
timeout.default = "2"
timeout:value("1", translate("1 second"))
timeout:value("2", translate("2 seconds"))
timeout:value("3", translate("3 seconds"))
timeout:value("4", translate("4 seconds"))
timeout:value("5", translate("5 seconds"))
timeout:value("6", translate("6 seconds"))
timeout:value("7", translate("7 seconds"))
timeout:value("8", translate("8 seconds"))
timeout:value("9", translate("9 seconds"))
timeout:value("10", translate("10 seconds"))
timeout:depends("alive", "1")
timeout:depends("alive", "2")
timeout:depends("alive", "3")
timeout:depends("alive", "4")

packetsize = di:taboption(this_tab, Value, "packetsize", translate("Ping packet size in bytes"),
		translate("可接受值：4-56。要在ping数据包中发送的数据字节数。这可能需要针对某些ISP进行调整"))
	packetsize.datatype = "range(4, 56)"
	packetsize.default = "56"
	packetsize:depends("alive", "1")
	packetsize:depends("alive", "2")
	packetsize:depends("alive", "3")
	packetsize:depends("alive", "4")

down = di:taboption(this_tab, ListValue, "down", translate("Interface down"),
		translate("This IP address will be pinged to dermine if the link is up or down"))
down.default = "3"
down:value("1")
down:value("2")
down:value("3")
down:value("4")
down:value("5")
down:value("6")
down:value("7")
down:value("8")
down:value("9")
down:value("10")
down:depends("alive", "1")
down:depends("alive", "2")
down:depends("alive", "3")
down:depends("alive", "4")

up = di:taboption(this_tab, ListValue, "up", translate("Interface up"),
		translate("Downed interface will be deemed up after this many successful ping tests"))
up.default = "3"
up:value("1")
up:value("2")
up:value("3")
up:value("4")
up:value("5")
up:value("6")
up:value("7")
up:value("8")
up:value("9")
up:value("10")
up:depends("alive", "1")
up:depends("alive", "2")
up:depends("alive", "3")
up:depends("alive", "4")

cb2 = di:taboption(this_tab, DynamicList, "trackip", translate("Tracking IP"),
		translate("This IP address will be pinged to dermine if the link is up or down."))
cb2.datatype = "ipaddr"
cb2:depends("alive", "1")
cb2:depends("alive", "2")
cb2:depends("alive", "3")
cb2:depends("alive", "4")
cb2.optional=false;

--
-- Custom profile
--

s = m:section(TypedSection, "custom", translate("自定义配置文件"), translate("将特定的模块和SIM卡组合与配置文件相匹配"))
s.anonymous = true
s.addremove = true
s:tab("custom", translate("默认"))
s:tab("cadvanced", translate("高级"))
s:tab("cconnect", translate("监视连接"))

this_ctab = "custom"

name = s:taboption(this_ctab, Value, "name", translate("配置文件名称"))

enabled = s:taboption(this_ctab, Flag, "enabled", translate("启用"))
enabled.default="1"
enabled.optional=false;

select = s:taboption(this_ctab, ListValue, "select", "选择模块方式 :");
select:value("0", "模块 ID")
select:value("1", "模块 IMEI")
select:value("2", "模块 Name")
select:value("3", "SIM IMSI")
select:value("4", "SIM ICCID")
select.default=0

idV = s:taboption(this_ctab, Value, "vid", "转换 Vendor ID :"); 
idV.optional=false;
idV:depends("select", "0")
idV.default="xxxx"

idP = s:taboption(this_ctab, Value, "pid", "转换 Product ID :"); 
idP.optional=false;
idP:depends("select", "0") 
idP.default="xxxx"

imei = s:taboption(this_ctab, Value, "imei", "模块 IMEI Number :"); 
imei.optional=false;
imei:depends("select", "1")
imei.datatype = "uinteger"
imei.default="1234567"

model = s:taboption(this_ctab, Value, "model", "包含模块名称 :"); 
model.optional=false;
model:depends("select", "2")
model.default="xxxx"

imsi = s:taboption(this_ctab, Value, "imsi", "SIM IMSI Number :"); 
imsi.optional=false;
imsi:depends("select", "3")
imsi.datatype = "uinteger"
imsi.default="1234567"

iccid = s:taboption(this_ctab, Value, "iccid", "SIM ICCID Number :"); 
iccid.optional=false;
iccid:depends("select", "4")
iccid.datatype = "uinteger"
iccid.default="1234567"

select1 = s:taboption(this_ctab, ListValue, "select1", "可选选择依据 :");
select1:value("0", "Modem ID")
select1:value("1", "Modem IMEI")
select1:value("2", "Model Name")
select1:value("3", "SIM IMSI")
select1:value("4", "SIM ICCID")
select1:value("10", "None")
select1.default=10

idV1 = s:taboption(this_ctab, Value, "vid1", "转换 Vendor ID :"); 
idV1.optional=false;
idV1:depends("select1", "0")
idV1.default="xxxx"

idP1 = s:taboption(this_ctab, Value, "pid1", "转换 Product ID :"); 
idP1.optional=false;
idP1:depends("select1", "0") 
idP1.default="xxxx"

imei1 = s:taboption(this_ctab, Value, "imei1", "Modem IMEI Number :"); 
imei1.optional=false;
imei1:depends("select1", "1")
imei1.datatype = "uinteger"
imei1.default="1234567"

model1 = s:taboption(this_ctab, Value, "model1", "包含模块名称 :"); 
model1.optional=false;
model1:depends("select1", "2")
model1.default="xxxx"

imsi1 = s:taboption(this_ctab, Value, "imsi1", "SIM IMSI Number :"); 
imsi1.optional=false;
imsi1:depends("select1", "3")
imsi1.datatype = "uinteger"
imsi1.default="1234567"

iccid1 = s:taboption(this_ctab, Value, "iccid1", "SIM ICCID Number :"); 
iccid1.optional=false;
iccid1:depends("select1", "4")
iccid1.datatype = "uinteger"
iccid1.default="1234567"

cma = s:taboption(this_ctab, Value, "apn", "APN :"); 
cma.rmempty = true;

cmu = s:taboption(this_ctab, Value, "user", "连接用户名 :"); 
cmu.optional=false; 
cmu.rmempty = true;

cmp = s:taboption(this_ctab, Value, "passw", "连接密码:"); 
cmp.optional=false; 
cmp.rmempty = true;
cmp.password = true

cmpi = s:taboption(this_ctab, Value, "pincode", "PIN :"); 
cmpi.optional=false; 
cmpi.rmempty = true;

cmau = s:taboption(this_ctab, ListValue, "auth", "身份验证协议 :")
cmau:value("0", "None")
cmau:value("1", "PAP")
cmau:value("2", "CHAP")
cmau.default = "0"

this_ctaba = "cadvanced"

cmf = s:taboption(this_ctaba, ListValue, "ppp", "强制使用模块为PPP协议 :");
cmf:value("0", "No")
cmf:value("1", "Yes")
cmf.default=0

cmw = s:taboption(this_ctaba, ListValue, "inter", "模块接口选择 :");
cmw:value("0", "Auto")
cmw:value("1", "WAN1")
cmw:value("2", "WAN2")
cmw.default=0

cmd = s:taboption(this_ctaba, Value, "delay", "连接延迟（秒） :"); 
cmd.optional=false; 
cmd.rmempty = false;
cmd.default = 5
cmd.datatype = "and(uinteger,min(5))"

cml = s:taboption(this_ctaba, ListValue, "lock", "锁定与提供程序的连接 :");
cml:value("0", "No")
cml:value("1", "Yes")
cml.default=0

cmcc = s:taboption(this_ctaba, Value, "mcc", "提供商国家代码 :");
cmcc.optional=false; 
cmcc.rmempty = true;
cmcc.datatype = "and(uinteger,min(1),max(999))"
cmcc:depends("lock", "1")

cmnc = s:taboption(this_ctaba, Value, "mnc", "提供商网络代码 :");
cmnc.optional=false; 
cmnc.rmempty = true;
cmnc.datatype = "and(uinteger,min(1),max(999))"
cmnc:depends("lock", "1")

cmdns1 = s:taboption(this_ctaba, Value, "dns1", "自定义DNS服务器1 :"); 
cmdns1.rmempty = true;
cmdns1.optional=false;
cmdns1.datatype = "ipaddr"

cmdns2 = s:taboption(this_ctaba, Value, "dns2", "自定义DNS服务器2 :"); 
cmdns2.rmempty = true;
cmdns2.optional=false;
cmdns2.datatype = "ipaddr"

cmdns3 = s:taboption(this_ctaba, Value, "dns3", "自定义DNS服务器3 :"); 
cmdns3.rmempty = true;
cmdns3.optional=false;
cmdns3.datatype = "ipaddr"

cmdns4 = s:taboption(this_ctaba, Value, "dns4", "自定义DNS服务器4 :"); 
cmdns4.rmempty = true;
cmdns4.optional=false;
cmdns4.datatype = "ipaddr"

cmlog = s:taboption(this_ctaba, ListValue, "log", "启用连接日志记录 :");
cmlog:value("0", "No")
cmlog:value("1", "Yes")
cmlog.default=0

if nixio.fs.access("/etc/config/mwan3") then
	cmlb = s:taboption(this_ctaba, ListValue, "lb", "在连接时启用负载平衡 :");
	cmlb:value("0", "No")
	cmlb:value("1", "Yes")
	cmlb.default=0
end

cmat = s:taboption(this_ctaba, ListValue, "at", "在连接时启用AT返回信息 :");
cmat:value("0", "No")
cmat:value("1", "Yes")
cmat.default=0

cmatc = s:taboption(this_ctaba, Value, "atc", "启动时自定义命令 :");
cmatc.optional=false;
cmatc.rmempty = true;

--
-- Custom Connection Monitoring
--

this_ctab = "cconnect"

calive = s:taboption(this_ctab, ListValue, "alive", "监视连接状态 :"); 
calive.rmempty = true;
calive:value("0", "关闭")
calive:value("1", "开启")
calive:value("2", "启用路由器重新启动")
calive:value("3", "启用模块重新连接")
calive:value("4", "通过电源开关或模块重新连接启用")
calive.default=0

reliability = s:taboption(this_ctab, Value, "reliability", translate("Tracking reliability"),
		translate("Acceptable values: 1-100. This many Tracking IP addresses must respond for the link to be deemed up"))
reliability.datatype = "range(1, 100)"
reliability.default = "1"
reliability:depends("alive", "1")
reliability:depends("alive", "2")
reliability:depends("alive", "3")
reliability:depends("alive", "4")

count = s:taboption(this_ctab, ListValue, "count", translate("Ping count"))
count.default = "1"
count:value("1")
count:value("2")
count:value("3")
count:value("4")
count:value("5")
count:depends("alive", "1")
count:depends("alive", "2")
count:depends("alive", "3")
count:depends("alive", "4")

interval = s:taboption(this_ctab, ListValue, "pingtime", translate("Ping interval"),
		translate("Amount of time between tracking tests"))
interval.default = "10"
interval:value("5", translate("5 seconds"))
interval:value("10", translate("10 seconds"))
interval:value("20", translate("20 seconds"))
interval:value("30", translate("30 seconds"))
interval:value("60", translate("1 minute"))
interval:value("300", translate("5 minutes"))
interval:value("600", translate("10 minutes"))
interval:value("900", translate("15 minutes"))
interval:value("1800", translate("30 minutes"))
interval:value("3600", translate("1 hour"))
interval:depends("alive", "1")
interval:depends("alive", "2")
interval:depends("alive", "3")
interval:depends("alive", "4")

timeout = s:taboption(this_ctab, ListValue, "pingwait", translate("Ping timeout"))
timeout.default = "2"
timeout:value("1", translate("1 second"))
timeout:value("2", translate("2 seconds"))
timeout:value("3", translate("3 seconds"))
timeout:value("4", translate("4 seconds"))
timeout:value("5", translate("5 seconds"))
timeout:value("6", translate("6 seconds"))
timeout:value("7", translate("7 seconds"))
timeout:value("8", translate("8 seconds"))
timeout:value("9", translate("9 seconds"))
timeout:value("10", translate("10 seconds"))
timeout:depends("alive", "1")
timeout:depends("alive", "2")
timeout:depends("alive", "3")
timeout:depends("alive", "4")

packetsize = s:taboption(this_ctab, Value, "packetsize", translate("Ping packet size in bytes"),
		translate("可接受值：4-56。要在ping数据包中发送的数据字节数。这可能需要针对某些ISP进行调整"))
	packetsize.datatype = "range(4, 56)"
	packetsize.default = "56"
	packetsize:depends("alive", "1")
	packetsize:depends("alive", "2")
	packetsize:depends("alive", "3")
	packetsize:depends("alive", "4")

down = s:taboption(this_ctab, ListValue, "down", translate("Interface down"),
		translate("在多次ping测试失败后，接口将被视为关闭"))
down.default = "3"
down:value("1")
down:value("2")
down:value("3")
down:value("4")
down:value("5")
down:value("6")
down:value("7")
down:value("8")
down:value("9")
down:value("10")
down:depends("alive", "1")
down:depends("alive", "2")
down:depends("alive", "3")
down:depends("alive", "4")

up = s:taboption(this_ctab, ListValue, "up", translate("Interface up"),
		translate("在这些成功的ping测试之后，被关闭的接口将被视为启动"))
up.default = "3"
up:value("1")
up:value("2")
up:value("3")
up:value("4")
up:value("5")
up:value("6")
up:value("7")
up:value("8")
up:value("9")
up:value("10")
up:depends("alive", "1")
up:depends("alive", "2")
up:depends("alive", "3")
up:depends("alive", "4")

cb2 = s:taboption(this_ctab, DynamicList, "trackip", translate("Tracking IP"),
		translate("This IP address will be pinged to dermine if the link is up or down."))
cb2.datatype = "ipaddr"
cb2:depends("alive", "1")
cb2:depends("alive", "2")
cb2:depends("alive", "3")
cb2:depends("alive", "4")
cb2.optional=false;

return m
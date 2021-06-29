local utl = require "luci.util"
local uci  = require "luci.model.uci".cursor()

m = Map("guestwifi", "创建 a Guest Wifi 网络",
	translate("创建具有可选带宽速度限制的Guest Wifi网络"))

m.on_after_save = function(self)
	luci.sys.call("/usr/lib/rooter/luci/guestwifi.sh &")
end

gw = m:section(TypedSection, "guestwifi", translate("Guest Wifi 信息"))
gw.anonymous = true

luci.sys.call("/usr/lib/rooter/luci/wifiradio.sh")

radio = gw:option(ListValue, "radio", translate("Wifi Radio"))
radio.rmempty = true
local file = io.open("/tmp/wifi-device", "r")
if file ~= nil then
	ix=0
	repeat
		local line = file:read("*line")
		if line == nil then
			break
		end
		if ix == 0 then
			radio.default=line
		end
		ix=1
		radio:value(line)
	until 1==0
	file:close()
end

--gw1 = m:section(TypedSection, "guestwifi", translate("Guest Network Information"))
--gw1.anonymous = true

ssid = gw:option(Value, "ssid", translate("网络 名称 :")); 
ssid.optional=false; 
ssid.rmempty = true;
ssid.default="guest"

ip = gw:option(Value, "ip", translate("网络IP地址 :"), translate("必须与路由器的子网不同")); 
ip.rmempty = true;
ip.optional=false;
ip.default="192.168.3.1";
ip.datatype = "ipaddr"

file = io.open("/etc/config/sqm", "r")
if file ~= nil then
	file:close()
--	gw2 = m:section(TypedSection, "guestwifi", translate("Bandwidth Speed Limiting"))
--	gw2.anonymous = true
	bl = gw:option(ListValue, "limit", "启用带宽速度限制 :");
	bl:value("0", "Disable")
	bl:value("1", "Enable")
	bl.default=0

	dl = gw:option(Value, "dl", "下载 速度 (kbit/s) :");
	dl.optional=false; 
	dl.rmempty = true;
	dl.datatype = "and(uinteger,min(1))"
	dl:depends("limit", "1")
	dl.default=1024

	ul = gw:option(Value, "ul", "上传 速度 (kbit/s) :");
	ul.optional=false; 
	ul.rmempty = true;
	ul.datatype = "and(uinteger,min(1))"
	ul:depends("limit", "1")
	ul.default=128
else
	gw2 = m:section(TypedSection, "guestwifi", translate("不启用带宽速度限制"))
	gw2.anonymous = true
end

return m

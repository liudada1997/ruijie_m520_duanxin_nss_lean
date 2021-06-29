local fs  = require "nixio.fs"
local sys = require "luci.sys"
local uci = require "luci.model.uci".cursor()
require("luci.util")
require("luci.model.ipkg")



local button = "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<input type=\"button\" value=\" " .. translate("Click Here to Open the YAMon 3 Web Interface") .. " \" onclick=\"window.open('http://'+window.location.hostname+'/yamon/index.html" .. "')\"/>"

local m = Map("yamon3", translate("YAMon 3 Bandwidth Monitor"), translate(" ") .. button)

m.on_after_save = function(self)
	luci.sys.call("/usr/lib/YAMon3/setconfig.sh &")
end

gwx = m:section(TypedSection, "yamon3", translate("Management"))
gwx.anonymous = true


bl = gwx:option(ListValue, "enabled", "Enable YAMon 3 :");
bl:value("0", "Disabled")
bl:value("1", "Enabled")
bl.default=0

gw = m:section(TypedSection, "tmpyamon3", translate("Configuration"))
gw.anonymous = true
	
upf = gw:option(Value, "upfreq", "Update Frequency :", translate("Number of seconds between updates"));
upf.default=15	
upf.datatype = "and(uinteger,min(15))"

pi = gw:option(Value, "pubint", "Publish Interval :", translate("Number of updates before updating web page"));
pi.default=12	
pi.datatype = "and(uinteger,min(2))"

mrday = gw:option(ListValue, "isp", "Roll-over day of the month for ISP billing :");
mrday.default=1
mrday:value("1", "1st")
mrday:value("2", "2nd")
mrday:value("3", "3rd")
mrday:value("4", "4th")
mrday:value("5", "5th")
mrday:value("6", "6th")
mrday:value("7", "7th")
mrday:value("8", "8th")
mrday:value("9", "9th")
mrday:value("10", "10th")
mrday:value("11", "11th")
mrday:value("12", "12th")
mrday:value("13", "13th")
mrday:value("14", "14th")
mrday:value("15", "15th")
mrday:value("16", "16th")
mrday:value("17", "17th")
mrday:value("18", "18th")
mrday:value("19", "19th")
mrday:value("20", "20th")
mrday:value("21", "21st")
mrday:value("22", "22nd")
mrday:value("23", "23rd")
mrday:value("24", "24th")
mrday:value("25", "25th")
mrday:value("26", "26th")
mrday:value("27", "27th")
mrday:value("28", "28th")
mrday:value("29", "29th")
mrday:value("30", "30th")
mrday:value("31", "31st")


unlimit = gw:option(ListValue, "unlimited_usage", translate("Unlimited Usage Available :"), translate("You are allowed to use unlimited bandwidth without charge at specific times of day."))
unlimit.rmempty = true
unlimit:value("0", "No")
unlimit:value("1", "Yes")
unlimit.default = "0"

sdhour = gw:option(ListValue, "unlimited_start", translate("Unlimited Start Time :"), translate("Starting Time if Unlimted Data Usage is available "))
sdhour.rmempty = true
sdhour:value("0:00", "12:00 AM")
sdhour:value("0:15", "12:15 AM")
sdhour:value("0:30", "12:30 AM")
sdhour:value("0:45", "12:45 AM")
sdhour:value("1:00", "01:00 AM")
sdhour:value("1:15", "01:15 AM")
sdhour:value("1:30", "01:30 AM")
sdhour:value("1:45", "01:45 AM")
sdhour:value("2:00", "02:00 AM")
sdhour:value("2:15", "02:15 AM")
sdhour:value("2:30", "02:30 AM")
sdhour:value("2:45", "02:45 AM")
sdhour:value("3:00", "03:00 AM")
sdhour:value("3:15", "03:15 AM")
sdhour:value("3:30", "03:30 AM")
sdhour:value("3:45", "03:45 AM")
sdhour:value("4:00", "04:00 AM")
sdhour:value("4:15", "04:15 AM")
sdhour:value("4:30", "04:30 AM")
sdhour:value("4:45", "04:45 AM")
sdhour:value("5:00", "05:00 AM")
sdhour:value("5:15", "05:15 AM")
sdhour:value("5:30", "05:30 AM")
sdhour:value("5:45", "05:45 AM")
sdhour:value("6:00", "06:00 AM")
sdhour:value("6:15", "06:15 AM")
sdhour:value("6:30", "06:30 AM")
sdhour:value("6:45", "06:45 AM")
sdhour:value("7:00", "07:00 AM")
sdhour:value("7:15", "07:15 AM")
sdhour:value("7:30", "07:30 AM")
sdhour:value("7:45", "07:45 AM")
sdhour:value("8:00", "08:00 AM")
sdhour:value("8:15", "08:15 AM")
sdhour:value("8:30", "08:30 AM")
sdhour:value("8:45", "08:45 AM")
sdhour:value("9:00", "09:00 AM")
sdhour:value("9:15", "09:15 AM")
sdhour:value("9:30", "09:30 AM")
sdhour:value("9:45", "09:45 AM")
sdhour:value("10:00", "10:00 AM")
sdhour:value("10:15", "10:15 AM")
sdhour:value("10:30", "10:30 AM")
sdhour:value("10:45", "10:45 AM")
sdhour:value("11:00", "11:00 AM")
sdhour:value("11:15", "11:15 AM")
sdhour:value("11:30", "11:30 AM")
sdhour:value("11:45", "11:45 AM")
sdhour:value("12:00", "12:00 PM")
sdhour:value("12:15", "12:15 PM")
sdhour:value("12:30", "12:30 PM")
sdhour:value("12:45", "12:45 PM")
sdhour:value("13:00", "01:00 PM")
sdhour:value("13:15", "01:15 PM")
sdhour:value("13:30", "01:30 PM")
sdhour:value("13:45", "01:45 PM")
sdhour:value("14:00", "02:00 PM")
sdhour:value("14:15", "02:15 PM")
sdhour:value("14:30", "02:30 PM")
sdhour:value("14:45", "02:45 PM")
sdhour:value("15:00", "03:00 PM")
sdhour:value("15:15", "03:15 PM")
sdhour:value("15:30", "03:30 PM")
sdhour:value("15:45", "03:45 PM")
sdhour:value("16:00", "04:00 PM")
sdhour:value("16:15", "04:15 PM")
sdhour:value("16:30", "04:30 PM")
sdhour:value("16:45", "04:45 PM")
sdhour:value("17:00", "05:00 PM")
sdhour:value("17:15", "05:15 PM")
sdhour:value("17:30", "05:30 PM")
sdhour:value("17:45", "05:45 PM")
sdhour:value("18:00", "06:00 PM")
sdhour:value("18:15", "06:15 PM")
sdhour:value("18:30", "06:30 PM")
sdhour:value("18:45", "06:45 PM")
sdhour:value("19:00", "07:00 PM")
sdhour:value("19:15", "07:15 PM")
sdhour:value("19:30", "07:30 PM")
sdhour:value("19:45", "07:45 PM")
sdhour:value("20:00", "08:00 PM")
sdhour:value("20:15", "08:15 PM")
sdhour:value("20:30", "08:30 PM")
sdhour:value("20:45", "08:45 PM")
sdhour:value("21:00", "09:00 PM")
sdhour:value("21:15", "09:15 PM")
sdhour:value("21:30", "09:30 PM")
sdhour:value("21:45", "09:45 PM")
sdhour:value("22:00", "10:00 PM")
sdhour:value("22:15", "10:15 PM")
sdhour:value("22:30", "10:30 PM")
sdhour:value("22:45", "10:45 PM")
sdhour:value("23:00", "11:00 PM")
sdhour:value("23:15", "11:15 PM")
sdhour:value("23:30", "11:30 PM")
sdhour:value("23:45", "11:45 PM")

--sdhour:depends("unlimited_usage", "1")
sdhour.default = "0:00"

edhour = gw:option(ListValue, "unlimited_end", translate("Unlimited End Time :"), translate("Ending Time if Unlimted Data Usage is available "))
edhour.rmempty = true
edhour:value("0:00", "12:00 AM")
edhour:value("0:15", "12:15 AM")
edhour:value("0:30", "12:30 AM")
edhour:value("0:45", "12:45 AM")
edhour:value("1:00", "01:00 AM")
edhour:value("1:15", "01:15 AM")
edhour:value("1:30", "01:30 AM")
edhour:value("1:45", "01:45 AM")
edhour:value("2:00", "02:00 AM")
edhour:value("2:15", "02:15 AM")
edhour:value("2:30", "02:30 AM")
edhour:value("2:45", "02:45 AM")
edhour:value("3:00", "03:00 AM")
edhour:value("3:15", "03:15 AM")
edhour:value("3:30", "03:30 AM")
edhour:value("3:45", "03:45 AM")
edhour:value("4:00", "04:00 AM")
edhour:value("4:15", "04:15 AM")
edhour:value("4:30", "04:30 AM")
edhour:value("4:45", "04:45 AM")
edhour:value("5:00", "05:00 AM")
edhour:value("5:15", "05:15 AM")
edhour:value("5:30", "05:30 AM")
edhour:value("5:45", "05:45 AM")
edhour:value("6:00", "06:00 AM")
edhour:value("6:15", "06:15 AM")
edhour:value("6:30", "06:30 AM")
edhour:value("6:45", "06:45 AM")
edhour:value("7:00", "07:00 AM")
edhour:value("7:15", "07:15 AM")
edhour:value("7:30", "07:30 AM")
edhour:value("7:45", "07:45 AM")
edhour:value("8:00", "08:00 AM")
edhour:value("8:15", "08:15 AM")
edhour:value("8:30", "08:30 AM")
edhour:value("8:45", "08:45 AM")
edhour:value("9:00", "09:00 AM")
edhour:value("9:15", "09:15 AM")
edhour:value("9:30", "09:30 AM")
edhour:value("9:45", "09:45 AM")
edhour:value("10:00", "10:00 AM")
edhour:value("10:15", "10:15 AM")
edhour:value("10:30", "10:30 AM")
edhour:value("10:45", "10:45 AM")
edhour:value("11:00", "11:00 AM")
edhour:value("11:15", "11:15 AM")
edhour:value("11:30", "11:30 AM")
edhour:value("11:45", "11:45 AM")
edhour:value("12:00", "12:00 PM")
edhour:value("12:15", "12:15 PM")
edhour:value("12:30", "12:30 PM")
edhour:value("12:45", "12:45 PM")
edhour:value("13:00", "01:00 PM")
edhour:value("13:15", "01:15 PM")
edhour:value("13:30", "01:30 PM")
edhour:value("13:45", "01:45 PM")
edhour:value("14:00", "02:00 PM")
edhour:value("14:15", "02:15 PM")
edhour:value("14:30", "02:30 PM")
edhour:value("14:45", "02:45 PM")
edhour:value("15:00", "03:00 PM")
edhour:value("15:15", "03:15 PM")
edhour:value("15:30", "03:30 PM")
edhour:value("15:45", "03:45 PM")
edhour:value("16:00", "04:00 PM")
edhour:value("16:15", "04:15 PM")
edhour:value("16:30", "04:30 PM")
edhour:value("16:45", "04:45 PM")
edhour:value("17:00", "05:00 PM")
edhour:value("17:15", "05:15 PM")
edhour:value("17:30", "05:30 PM")
edhour:value("17:45", "05:45 PM")
edhour:value("18:00", "06:00 PM")
edhour:value("18:15", "06:15 PM")
edhour:value("18:30", "06:30 PM")
edhour:value("18:45", "06:45 PM")
edhour:value("19:00", "07:00 PM")
edhour:value("19:15", "07:15 PM")
edhour:value("19:30", "07:30 PM")
edhour:value("19:45", "07:45 PM")
edhour:value("20:00", "08:00 PM")
edhour:value("20:15", "08:15 PM")
edhour:value("20:30", "08:30 PM")
edhour:value("20:45", "08:45 PM")
edhour:value("21:00", "09:00 PM")
edhour:value("21:15", "09:15 PM")
edhour:value("21:30", "09:30 PM")
edhour:value("21:45", "09:45 PM")
edhour:value("22:00", "10:00 PM")
edhour:value("22:15", "10:15 PM")
edhour:value("22:30", "10:30 PM")
edhour:value("22:45", "10:45 PM")
edhour:value("23:00", "11:00 PM")
edhour:value("23:15", "11:15 PM")
edhour:value("23:30", "11:30 PM")
edhour:value("23:45", "11:45 PM")

--edhour:depends("unlimited_usage", "1")
edhour.default = "8:00"	

dc = gw:option(ListValue, "datacap", "Monthly Data Cap :", translate("Does your Data plan have a limit on the amount you can use?"));
dc:value("0", "Unlimited")
dc:value("1", "Limited")
dc.default=0

dl = gw:option(Value, "capval", "Data Cap in GB :", translate("Size of Cap if Monthly Data Cap is Limited"));
dl.rmempty = true;
dl.datatype = "and(uinteger,min(1))"
--dl:depends("datacap", "1")
dl.default=1

bc = gw:option(ListValue, "bridge", "Bridge on Network :", translate("Do you have a bridge on your network like a second router or other device to extend the wireless range?"));
bc:value("0", "No")
bc:value("1", "Yes")
bc.default=0

bm = gw:option(Value, "bmac", "MAC Address of Bridge :", translate("MAC address for your bridge devices"));
bm.rmempty = false;
bm.default="00:00:00:00:00:00"

ibc = gw:option(ListValue, "ipv6", "Include IPv6 Traffic :", translate("Include IPv6 traffic in the reports?"));
ibc:value("0", "No")
ibc:value("1", "Yes")
ibc.default=0
	
return m
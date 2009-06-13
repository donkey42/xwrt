--------------------------------------------------------------------------------
-- translator.lua
--
-- Description:
--      to translate text ...
--      before this script must be load some files functions and set some VARS
--
-- Author(s) [in order of work date]:
--       Fabi�n Omar Franzotti .
--
-- Configuration files referenced:
--   
--------------------------------------------------------------------------------
require("common")
__tr = {}
function tr_load()
	local lang = uci.get("webif","general","lang") or "en"
	if lang == "en" then return end
	local file = "/usr/lib/webif/lang/"..lang.."/common.txt"

	local data = ""
	local BUFSIZE = 2^15
	local f = io.input(file)   -- open input file
	while true do
		local lines, rest = f:read(BUFSIZE, "*line")
		if not lines then break end
		if rest then lines = lines .. rest .. '\n' end
		data = data..lines
	end
	data = string.gsub(data,"	"," ")
	for line in string.gmatch(data,"[^\n]+") do
		_, _, key, val = string.find(line, "(.+)[=][>]%s*(.*)")
		if key then
			key = string.trim(key)
--			val = string.trim(val)
			__tr[key] = val
		end
	end
end

function tr(k)
	local str = "" 
	local u, text = unpack(string.split(k,"#"))
--	print(v,u,text,"<BR>")
	if text == nil then text = u end
	mytr = string.trim(__tr[u])
--	print (u,mytr,"<br>")
	if mytr == nil or mytr == "" then mytr = text end
	str = str .. mytr
	return str
end

function trsh(linea)
	local ret=""
	linea = string.gsub(linea,"@TR<<","}{")
	linea = string.gsub(linea,">>","}{").."}"
	for v in string.gmatch(linea,"%b{}") do
		ret = ret .. tr(string.gsub("@aa"..v, "@(%a+){(.-)}", "%2")).." "
	end	
	return ret
end

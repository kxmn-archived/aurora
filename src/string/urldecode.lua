local char = string.char
local function hex2char(x) return string.char(tonumber(x,16)) end
local _PLUS='+'
local _SPACE=' '
local _LF="\n"
local _CRLF="\r\n"
local _HEXMATCH="%%(%x%x)"

--[[md:
### string.urldecode(encodedstring, component?) : decodedstring
* encodedstring: string encoded
* component: (optional) if true, process "+" as spaces before % decoding
]]
return function(str,component)

	if component then
		return str:gsub(_PLUS,_SPACE):gsub(_HEXMATCH,hex2char):gsub(_CRLF,_LF)
	else
		return str:gsub(_HEXMATCH,hex2char):gsub(_CRLF,_LF)
	end
end

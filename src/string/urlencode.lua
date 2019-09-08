local byte = string.byte

local _URLALLOW="([^%w%-%_%.%~])"
local _URLCALLOW="([^%w %-%_%.%~])"
local _FMTMASK="%%%02X"
local _NBSP=" "
local _PLUS="+"
local function _formatchar(c)
	return _FMTMASK:format(byte(c))
end

--[[md:
### string.urlencode(str,component?) : encodedStr
* str: string which will be encoded
* component: (optional) if true, encoded as urlcomponent, i.e., treat spaces as "+" instead "%20"
]]
return function(str,component)
	if component then
		return str:gsub(_URLCALLOW, _formatchar):gsub(_NBSP, _PLUS)
	else
		return str:gsub(_URLALLOW, _formatchar)
   	end
end

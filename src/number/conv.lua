local M = {}

--[[md:
### aurora.number.conv.toValues(base,value)

* base : base used to convert value
* value : a number
* Returns a table with each result digit at one position;

Example:
```
local digits = aurora.number.toValues(16,4095))
print(table.concat(digits,','))
= "15,15,15"
```
]]
function M.toValues (b,v)
	local l={}
	while v > 0 do
		table.insert(l,1,v%b)
		v = v//b
	end
	return l
end


--[[md:
### aurora.number.conv.fromValues(base,value) : number

* base : base number that represents previous used to encode
* value : a table where each digit is in one position;
* Returns a number

Example:
```
print(aurora.number.conv.fromValues({15,15,15},16))
= "4095"
```
]]
function M.fromValues(b,l)
	local v=0

	for _,d in pairs(l) do
		v = b * v + d
	end
	return v
end

local Digits = '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'

--[[md:
### aurora.number.conv.toBase(base,decimal)

* base : target base for conversion (maximum 62)
* decimal : integer number to be converted
* Returns a string with converted data

The base is a integer until maximum of 62. The order is 0-9,a-z,A-Z.
if you use in a case insensitive context, prefer use base 36 instead 62

Example:
```
print(aurora.number.conv.toBase(16,4095))
= "fff"
```

]]
function M.toBase(b,d)
	local l = M.toValues(b,d)
	local li=0
	for i=1, #l, 1 do li=l[i]+1 l[i]=Digits:sub(li,li) end
	return table.concat(l,'')
end

--[[md:
### aurora.number.conv.fromBase(base,string)

* base : target base for conversion (maximum 62) (see toBase for info)
* string : string representation that should be converted back to decimal
* Returns a number with converted data

Example:
```
print(aurora.number.conv.fromBase(16,'fff'))
= 4095
```
]]
function M.fromBase(b,d)
	local li={}
	for i=1, #d, 1 do li[#li+1]=Digits:find(d:sub(i,i))-1 end
	return M.fromValues(b,li)
end

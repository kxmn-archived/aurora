--[[md:
### string.split(string, delimiter)

* string : text intended to be splited
* delimiter : character or substring that divides the string in parts.
returns list table with strings
]]

return function(s, d)
   local t, ll
   t={}
   ll=0
   if(#s == 1) then
      return {s}
   end
   while true do
      l = string.find(s, d, ll, true)
      if l ~= nil then
         table.insert(t, string.sub(s,ll,l-1))
         ll = l + 1
      else
         table.insert(t, string.sub(s,ll))
         break
      end
   end
   return t
end

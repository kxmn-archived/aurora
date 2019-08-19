--[[md:
### fs.isFile(path)

* path : path to the file 
* returns true if path is file, false otherwise
]]

return function (f)
	local f=io.open(f,"r")
   	if f~=nil then
		io.close(f)
		return true
	else
		return false
	end
end

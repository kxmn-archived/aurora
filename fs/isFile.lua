--- Check if path is a file
-- @name isFile
-- @param filename string
-- @return boolean if ok
M.isFile = function (f)
	local f=io.open(name,"r")
   	if f~=nil then
		io.close(f)
		return true
	else
		return false
	end
end

--[[md:
### fs.getFileContents(filename)
* filename : the file name including path
* returns the content of file or, in errors, false
]]
return function (file)
	local f,c = io.open(file), false
	if f then
		c = f:read('a')
		f:close()
	end
	return c
end


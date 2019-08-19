local fs = aurora.fs

--[[md:
### fs.setFileContents(file,content,append)

* file : filename including its path
* content : content to be written on file
* append : if set, writes to end of file else the file is replaced
* returns true if ok or false otherwise
]]

return function (f, c, append)
	if not fs.isDir(fs.dirname(f)) then
		fs.mkdir(fs.dirname(f))
	end
	local f = io.open(f, append and 'a' or 'w')
	if f then
		f:write(c)
		f:flush()
		f:close()
		return true
	else
		return false
	end
end



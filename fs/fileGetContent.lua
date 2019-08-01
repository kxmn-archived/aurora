--- Get contents of a file
-- @name fileGetContent
-- @param filename string
-- @return string if ok
-- @return nil if error
return function (f)
	local f,c = io.open(f), false
	if f then c = f:read('a') end
	f:close()
	return c
end


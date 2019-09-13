local split = aurora.string.split
local lfs = require('lfs')
local fs = aurora.fs

--[[md:
### fs.mkdir(path)

* path : string of the path to be created
* returns true, nil on success or false, message on error

Observe that this function create recursively dirs
]]
return function (path)
	local cat = table.concat
	if fs.isDir(path) then return true end

	local p = split(path,'/')
	local s = {}
	local m, me;
	for i,d in ipairs(p) do
		s[i * 2 - 1] = d
		s[i * 2] = '/'
		m, me = lfs.mkdir(cat(s))
	end
	if fs.isDir(path) then
		return true,nil
	else
		return m,me
	end
end

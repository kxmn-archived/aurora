local split = aurora.string.split
local lfs = require('lfs')
local fs = aurora.fs

--[[md:
fs.mkdir(path)

* path : string of the path to be created
* returns true, nil on success or false, message on error

Observe that this function create recursively dirs
]]
return function (p)
	if fs.isDir(p) then return true end

	local p = split(p,'/')
	local s = ''
	local m, me;
	for i,d in ipairs(p) do
		s = s..d..'/'
		m, me = lfs.mkdir(s)
	end
	if fs.isDir(p) then
		return true,nil
	else
		return m,me
	end
end

local split = require('Kosmo.String.split')
local LFS = require('lfs')
local KFS = require('Kosmo.FileSystem')

--- Recursive directory creation
-- @name mkdir
-- @param path Complete path including desired subdirs
-- @return true if alredy exists
-- @return void
return function (path)
	if .isDir(p) then return true end

	local p = split(p,'/')
	local s = ''
	for i,d in ipairs(p) do
		s = s..d..'/'
		local m, me = KFS.mkdir(s)
	end
end

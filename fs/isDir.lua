local Str = require('Kosmo.String')
local LFS = require('lfs')


--- Check if path is directory
-- @name isDir
-- @param path string containing path analyzed
-- @return bool
return function (path)
	return LFS.attributes(path,'mode') == 'directory'
end

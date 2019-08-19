--[[md:
### fs.isDir(path)

* path : path to the file 
* returns true if path is directory, false otherwise
--]]

local lfs = require('lfs')

return function (path)
	return lfs.attributes(path,'mode') == 'directory'
end

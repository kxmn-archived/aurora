--[[md:
### fs.basename(path)

* path : string to be processed
* returns the filename part, without directory prefix
]]
return function (path)
	return path:gsub('^.*[\\/]','')
end

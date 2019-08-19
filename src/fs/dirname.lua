--[[md:
### fs.dirname(path)

* path : string to be processed
* returns the directory part, excluding filename
]]
return function (p)
	return p:gsub('[^\\/]+[\\/]?$', '')
end

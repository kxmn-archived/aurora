local liluat = require('lunar.template.liluat')
local fs = require('lunar.fs')
local M={}


--- Generate pages from templates and data
-- @class Template
-- @name render
-- @param tplFile string relative template name
-- @param data table key,values
-- @param cache boolean
-- @return string
M.render = function(tplFile, data, cache)
		local compFile = PATH..'/cache/views/'..tplFile
		local tplFile  = PATH..'/views/'..tplFile

		if cache and fs.isFile(compfile)  then
			return _.liluat(fs.fileGetContent(compFile) ,data)
		else
			local cpl = _.liluat.compile_file(tplFile,{render=false})
			fs.filePutContent(compFile,cpl)
			return _.render(cpl, data)
		end
end
return M

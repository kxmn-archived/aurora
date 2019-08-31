--[[md:
## aurora.table - utils for handling tables

]]
local M = ondemand('aurora.table')


--[[md:
### table.toSet (list)

* list : a list table
* returns a table indexed with values of list, easily searchable
]]
function M.toSet (list)
	local set = {}
	for _,v in ipairs(list) do set[v]=true end
	return set
end


return M

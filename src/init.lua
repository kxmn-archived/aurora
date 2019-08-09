--- Aurora
-- Lua tool set of functions
-- Copyright (c) 2019 Kxmn
-- License MIT


--[[md
	ondemand(thisModuleName) : table
	* `thisModuleName`: submodules will be search under this name
	* `table`: return table where inexistent properties will auto request
	This function is set on global scope when you just `require "aurora"`
--]]
_G.ondemand = function(m)
		return setmetatable ({},{
			__index = function(t,k)
				return require(m..'.'..k)
			end
		})
end

-- As wide as possible
-- instead of requires, just use the "namespace"
-- if performance worry, bring to scope with a `local a = aurora`
_G.aurora = _G.ondemand('aurora')

-- Just to avoid mistakes
return _G.aurora

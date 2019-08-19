local ws = require('aurora.ws.pegasus');

--[[md:
## aurora.ws - WebServer utility

]]



--[[md
### ws.new(conf) : Pegasus
* conf: table with configuration
* returns a Pegasus like webserver instance
]]
return {
	new = function(conf)

		local S = ws:new({
			port     = conf.port or 8080,
			location = conf.location or PATH..'/www',
			plugins  = conf.compress and { require('aurora.ws.pegasus.compress'):new() } or {}
		})

		S:start(function(request,response)
			if conf.beforeRules	then
				conf.beforeRules(request,response)
			end
			local rules, path, query = conf.rules, request:path(), request:get()

			for i=1, #rules do
				local match = table.pack(path:match(rules[i][1]))
				if match[1] then
					require(rules[i][2])(request,response,match)
					break
				end
			end
			if conf.afterRules then conf.afterRules(request,response) end
		end)

		return S
	end
}

local ws = require('aurora.ws.pegasus');

--[[md:
## aurora.ws - WebServer utility

### ws.new(ConfTable) : Pegasus
* ConfTable: table with configuration
* returns a Pegasus like webserver instance

### ConfTable
```Lua
{
	port: 8080,
	location: PATH..'/www',
	plugins: { require('aurora.ws.pegasus.compress'):new},
	rules: RulesTable
}
```

### RulesTable
```
{
	{ '/api', 'module' },
	{ MATCH, MODULE }
}
```
* MATCH - Lua expression that make processing stop and call MODULE
* MODULE - A lua module that returns a function

### Rule module file
The MODULE file looks like:
```
return function ( conn ) end
```
Where conn has these methods:
* `.path()` - requested path
* `.headers()` - headers data table from request
* `.methods()` - GET, POST, etc...
* `.querystring()` - requested get parameters
* `.post()` - requested post parameters
* `.addHeader(key, value)` - add a response header
* `.addHeaders(table)` - table with addHeader values
* `.statusCode(numer, string)` - returns status code and message
* `.contentType(string)` - mime of response
* `.write(responseBodyString)` - write back to client
* `.writeFile(filename)` - write the file content back to client

]]

local handle = function (req,res)
	return {
		path = function(...) return req:path(...) end,
		header = function(...) return req:header(...) end,
		method = function(...) return req:method(...) end,
		querystring = function(...) return req:querystring(...) end,
		get = function(...) return req:get(...) end,
		post = function(...) return req:post(...) end,
		addHeaders = function(...) return res:addHeaders(...) end,
		addHeader = function(...) return res:addHeader(...) end,
		statusCode = function(...) return res:statusCode(...) end,
		contentType = function(...) return res:contentType(...) end,
		write = function(...) return res:write(...) end,
		writeFile = function(...) return res:writeFile(...) end
	}
end

return {
	new = function(conf)

		local S = ws:new({
			port     = conf.port or 8080,
			location = conf.location or PATH..'/www',
			plugins  = conf.compress and { require('aurora.ws.pegasus.compress'):new() } or {}
		})

		S:start( function (request,response)
			local conn = handle (request,response)

			if conf.beforeRules	then
				conf.beforeRules (conn)
			end
			local rules, path, query = conf.rules, conn.path(), conn.get()

			for i=1, #rules do
				local match = table.pack (path:match (rules[i][1]))
				if match[1] then
					conn.match = match
					if type (rules[i][2]) == 'number' then
						conn.statusCode (rules[i][2])
						if type (rules[i][3]) == 'table' then
							conn.addHeaders (rules[i][3])
						end
						conn.write()
					else
						require (rules[i][2]) (conn)
					end
					break
				end
			end
			if conf.afterRules then conf.afterRules(conn) end
		end)

		return S
	end
}

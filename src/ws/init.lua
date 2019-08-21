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
return function( request, response, match ) end
```
Where:
* request: request info table
* response: table with methods that handle output to client
* match: what was matched on the rule

#### request
* `:path()` - requested path
* `:headers()` - headers data table
* `:methods()` - GET, POST, etc...
* `:querystring()` - get parameters
* `:post()` - post parameters

#### response
* `:addHeader(key, value)` - add a response headers
* `:addHeaders(table)` - table with addHeader values
* `:statusCode(numer, string)` - returns status code and message
* `:contentType(string)` - mime of response
* `:write(responseBodyString)` - write back to client
* `:writeFile(filename)` - ?

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

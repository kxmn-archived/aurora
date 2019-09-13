--- Ruler function
-- This function filters each request trying to match a given rule.
-- When a match occurs, the respective module processes the request.

local NUMBER, TABLE, STRING, FUNCTION = 'number', 'table', 'string', 'function'


local function ruler (server, request, response)

	local r, p = server.rules, request:path()

	for i=1, #r do
		local match = table.pack (p:match (r[i][1]))
		if match[1] then
			local rule = r[i][2]

			request.match = match
			request.root = rule.root
			print(request.root)
			if rule.headers then response:addHeaders(rule.headers) end

			if rule.process then
				rule.process(server,request,response)
			elseif server.handler:tryFile(request,response,request.root) then
				return
			else
				response:statusCode(rule.status or 404)
				response:write()
			end
			break
		end
	end
end

return ruler

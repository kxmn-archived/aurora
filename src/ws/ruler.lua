--- Ruler function
-- This function filters each request trying to match a given rule.
-- When a match occurs, the respective module processes the request.

local NUMBER, TABLE, STRING, FUNCTION = 'number', 'table', 'string', 'function'


local function ruler (server,request,response)

	local r, p = server.rules, request:path()

	for i=1, #r do
		local match = table.pack (p:match (r[i][1]))
		if match[1] then
			request.match = match
			local act = type (r[i][2])
			if act == NUMBER then
				response:statusCode (r[i][2])
				if type (r[i][3]) == TABLE then
					response:addHeaders (r[i][3])
				end
				response:write()
			elseif act == STRING then
				require (r[i][2]) (server, request, response)
			elseif act == FUNCTION then
				r[i][2](server,request,response)
			end
			break
		end
	end
end

return ruler

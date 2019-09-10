-- local function roTable(t)
-- 	return setmetatable({},{
-- 	__index = table,
-- 	__newindex = function(...) end,
-- 	__metatable = false
-- 	})
-- end

local AuroraWS = {}
local Handler = require 'aurora.ws.handler'
local socket = require 'socket'
local copas = require 'copas'

function AuroraWS.addServer(conf,ruler)

	local h = Handler:new(conf, ruler or require('aurora.ws.ruler'))
	local s = assert(socket.bind(h.host, h.port))
	local ip,port = s:getsockname()

	copas.addserver(s, copas.handler(function(ch) h:processRequest(ch) end))
	return AuroraWS
end

function AuroraWS.run()
	copas.loop()
end

return AuroraWS

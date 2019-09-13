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
	print('AuroraWS - Added server for '..h.host..' on port '..h.port)
	return AuroraWS
end

function AuroraWS.run()
	print('AuroraWS started')
	copas.loop()
end

function AuroraWS.configure(conf)
	local ports = {}

	for si,server in pairs(conf.servers) do
		local sport = tostring(server.port)
		server.compress = conf.compress or nil

		if not ports[sport] then ports[sport] = {} end
		if server.default then ports[sport].default = server end

		-- Avoid tests during runtime setting a default root for all rule
		if server.rules then for _,rule in pairs(server.rules) do
				rule[2].root = rule[2].root or server.root
		end end
		ports[sport][server.name] = server
	end

	for port,vhosts in pairs(ports) do
		local h = Handler:new(vhosts, conf.ruler or require('aurora.ws.ruler'))
		local skt = assert(socket.bind(conf.host, tonumber(port)))
		local ip,port = skt:getsockname()
		copas.addserver(skt, copas.handler(function(ch) h:processRequest(ch) end))
		print('AuroraWS: listening on '..h.host..':'..h.port)
	end
	return AuroraWS
end



return AuroraWS

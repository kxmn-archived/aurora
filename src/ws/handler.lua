local Request = require 'aurora.ws.request'
local Response = require 'aurora.ws.response'
local mimetypes = require 'mimetypes'
local lfs = require 'lfs'

local Handler = {
	host     = '*',
	port     = 8080,
	compress = false,
	tempdir  = '/tmp/',
	hits = 0, -- it's not configurable... just a counter
}
Handler.__index = Handler

function Handler:new(conf, callback)
	local s = {
		plugins = {},
		callback = callback,
		startdate = os.date('%y%m%d%H%M%S'),
		conf = conf
	}

	if conf.compress then s.plugins[#s.plugins+1] = require('aurora.ws.compress'):new() end

	local server = setmetatable(s, self)
	server:pluginsAlterRequestResponseMetatable()
	return server
end

function Handler:pluginsAlterRequestResponseMetatable()
	for _, plugin in ipairs(self.plugins) do
		if plugin.alterRequestResponseMetaTable then
			local stop = plugin:alterRequestResponseMetaTable(Request, Response)
			if stop then
				return stop
			end
		end
	end
end

function Handler:pluginsNewRequestResponse(request, response)
  for _, plugin in ipairs(self.plugins) do
    if plugin.newRequestResponse then
      local stop = plugin:newRequestResponse(request, response)
      if stop then
        return stop
      end
    end
  end
end

function Handler:pluginsBeforeProcess(request, response)
  for _, plugin in ipairs(self.plugins) do
    if plugin.beforeProcess then
      local stop = plugin:beforeProcess(request, response)
      if stop then
        return stop
      end
    end
  end
end

function Handler:pluginsAfterProcess(request, response)
  for _, plugin in ipairs(self.plugins) do
    if plugin.afterProcess then
      local stop = plugin:afterProcess(request, response)
      if stop then
        return stop
      end
    end
  end
end

function Handler:pluginsProcessFile(request, response, filename)
  for _, plugin in ipairs(self.plugins) do
    if plugin.processFile then
      local stop = plugin:processFile(request, response, filename)
      if stop then
        return stop
      end
    end
  end
end

function Handler:processBodyData(data, stayOpen, response)
  local localData = data

  for _, plugin in ipairs(self.plugins or {}) do
    if plugin.processBodyData then
      localData = plugin:processBodyData(
				localData,
				stayOpen,
        response.request,
				response
			)
    end
  end

  return localData
end

function Handler:tryFile(request,response,root)
	local path = request:path();
	if path == ''	then
		path ='/index.html'
	elseif path:sub(-1) == '/' then
		path=path..'index.html'
	end
	local filename = root .. path
	if not lfs.attributes(filename) then
		response:statusCode(404)
	end

	if self:pluginsProcessFile(request, response, filename) then
		return
	end

	local file = io.open(filename, 'rb')
	if file then
		response:writeFile(file, mimetypes.guess(filename or '') or 'text/html')
	else
		response:statusCode(404)
	end
end

function Handler:processRequest(client, port)
	self.hits = self.hits + 1
  local request = Request:new(client, port)
	request.number = self.hits

  -- if we get some invalid request just close it
  -- do not try handle or response
  if not request:method() then
    client:close()
    return
  end

	local hostname, _, hostport = request:headers()['Host']:match("([^:]-)(:?([%d]+))")
	local host = self.conf[hostname] or self.conf.default or nil

	if not host then return end

	host.handler = self
  local response =  Response:new(client, self)
  response.request = request

  if self:pluginsNewRequestResponse(request, response) then
    return
  end

	if self:tryFile(request, response, host.root) then return end

  if self.callback then
    self.callback(host, request, response)

		-- Clear temp files
		if request._files then
			for _,v in pairs(request._files) do
				for i=1, #v do os.remove(v[i].tmpname) end
			end
		end
  end

  if response.status == 404 then
    response:writeDefaultErrorMessage(404)
  end
end

return Handler

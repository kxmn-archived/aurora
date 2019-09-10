local Request = {}
Request.__index = Request

function Request:new(client, port)
  local newObj = {}
  newObj.client = client
  newObj.serverPort = port
  newObj.clientIP = client:getpeername()
  newObj.firstLine = nil
  newObj._method = nil
  newObj._path = nil
  newObj._params = {}
  newObj._headers_parsed = false
  newObj._headers = {}
  newObj._form = {}
  newObj._is_valid = false
  newObj._body = ''
  newObj._content_done = 0

  return setmetatable(newObj, self)
end

local MATCH_METHOD = '^(.-)%s'
local MATCH_PATH = '(%S+)%s*'
local MATCH_PROTOCOL = '(HTTP%/%d%.%d)'
local MATCH_REQUEST = table.concat{MATCH_METHOD, MATCH_PATH, MATCH_PROTOCOL}
local MATCH_HEADER = '([%w-]+): ([%w %p]+=?)'
local MATCH_QUERY_STRING = '([^=]*)=([^&]*)&?'

local MATCH_FORMDATA_FILE_HEADER =
	'Content%-Disposition:%s*form%-data;%s*name="([^%s"]-)";?(%s*filename="([^%s"]-)")'
local MATCH_FORMDATA_FILE_MIME   =
	'Content%-Type:%s*([%w%d/_-]+)'
local MATCH_FORMDATA_FIELD_HEADER=
	'Content%-Disposition:%s*form%-data;%s*name="([^%s"]-)"'

function Request:parseFirstLine()
  if (self.firstLine ~= nil) then
    return
  end

  local status, partial, path, protocol
  self.firstLine, status, partial = self.client:receive()

  if (self.firstLine == nil or status == 'timeout' or partial == '' or status == 'closed') then
    return
  end

  -- Parse firstline http: METHOD PATH PROTOCOL,
  -- GET Makefile HTTP/1.1
  self._method, path, protocol = string.match(
  	self.firstLine, -- luacheck: ignore protocol
    MATCH_REQUEST
  )

  if not self._method then
	  --TODO:
    --! @todo close client socket immediately
    return
  end

  local filename
  if #path > 0 then
    filename, self._get = string.match(path, '^([^#?]+)[#|?]?(.*)')
  else
    filename = ''
  end

  if not filename then return end

  self._path = filename or path
end

-- Get all the request body
local function _getBody(request)
	local b,c={}
	repeat
		c = request:receiveBody(8192)
		if c then b[#b+1] = c end
	until not c
	return table.concat(b)
end

-- Parses the content of request when it is a single sent file
local function _getFileData(request,mime)
	local t = os.tmpname()
	io.open(t,'w+'):write(_getBody(request)):close()

	return { [request:method()] = {{
		tmpname = t,
		name = request:path(),
		mime = mime
	}}}
end


-- Parses the content of request when in multipart/form-data format
local function _getFormData(request,boundary,length)
	local D, F = {}, {} -----------> Data and File list
	local cont = _getBody(request) ---> Full multipart content
	local part  -------------------> each part of the multipart
	local phead = {} --------------> Head of each piece
	local bstart,bend,lbend = 0,0,0 -- positions for matching purpose
	local dname, dfile, dmime -----> data name, data file and data file mime
	local _ -----------------------> just ignore

	bstart,bend = cont:find(boundary,bend,1)
	boundary = "\r\n"..boundary
	repeat
		lbend,bstart,bend = bend, cont:find(boundary,bend,1)
		if bstart then
			part = cont:sub(lbend+3,bstart-1)
			phead = part:match("(.-)\r\n\r\n")

			dname,_,dfile = phead:match(MATCH_FORMDATA_FILE_HEADER)
			if dfile then
				dmime = phead:match(MATCH_FORMDATA_FILE_MIME)
				if dmime then
					local tmpname = os.tmpname()
					F[dname] = F[dname] or {}
					F[dname][#F[dname]+1] = {tmpname = tmpname,	name=dfile,	mime=dmime }
					io.open(tmpname,'w+'):write(part:sub(#phead+5)):close()
				end
			else
				dname=phead:match(MATCH_FORMDATA_FIELD_HEADER)
				D[dname] = D[dname] or {}
				D[dname][#D[dname]+1] = part:sub(#phead+5)
			end
		end
	until not bstart

	return D,F
end

local urldecode = aurora.string.urldecode

local function _parseURLEncoded(value)
	local d = {}
	if value then
		for k,v in string.gmatch(value, MATCH_QUERY_STRING) do
			if d[k] then d[k][#d[k]] = urldecode(v,1) else d[k]={urldecode(v,1)} end
		end
	end
	return d
end

function Request:data()
	if self._bodyData and self._files then return self._bodyData, self._files end
	local h = self:headers()
	local d = {}
	local ctype = h['Content-Type'] or 'application/octet-stream'
	local clength = tonumber(h['Content-Length'])


	if clength < 10 then return d end
	if clength > 3145728 then -- >= 3MB
		--TODO use parsing from a file
	else
		-- Ex: curl $url -X PUT -H 'Content-Type: application/x-www-form-urlencoded' --data 'a=A&b=B'
		if ctype == 'application/x-www-form-urlencoded' then
			self._bodyData = _parseURLEncoded(_getBody(self))
			self._files = {}

		-- Ex: curl $url -X put -v -F upload=@/dir/file1 -F upload=@/dir/file2 -F oi=teste
		elseif ctype:find('multipart/form-data;',0,1) == 1 then
			self._bodyData, self._files = _getFormData(self, '--'..ctype:match('boundary=([^%s]+)'),clength)

		-- Ex: curl $url -T /dir/file
		else
			self._bodyData = {}
			self._files = _getFileData(self,ctype)
		end
	end

	return self._bodyData, self._files
end


function Request:parseURLEncoded(value, _table) -- luacheck: ignore self
  --value exists and _table is empty
  if value and next(_table) == nil then
    for k, v in  string.gmatch(value, MATCH_QUERY_STRING) do
        _table[k] = v
    end
  end

  return _table
end

function Request:queryData()
  self:parseFirstLine()
  return self:parseURLEncoded(self._get, self._params)
end

function Request:path()
  self:parseFirstLine()
  return self._path
end

function Request:method()
  self:parseFirstLine()
  return self._method
end

function Request:headers()
  if self._headers_parsed then
    return self._headers
  end

  self:parseFirstLine()

  local data = self.client:receive()

  while (data ~= nil) and (data:len() > 0) do
    local key, value = string.match(data, MATCH_HEADER)

    if key and value then
      self._headers[key] = value
    end

    data = self.client:receive()
  end

  self._headers_parsed = true
  self._content_length = tonumber(self._headers["Content-Length"] or 0)

  return self._headers
end

function Request:receiveBody(size)
  size = size or self._content_length

  -- do we have content?
  if (self._content_length == nil) or (self._content_done >= self._content_length) then return false end

  -- fetch in chunks
  local fetch = math.min(self._content_length-self._content_done, size)

  local data, err, partial = self.client:receive(fetch)

  if err == 'timeout' then
    data = partial
  end

  self._content_done = self._content_done + #data

  return data
end

return Request

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
return function ( Conn ) end
```

### Conn:receiveBody(size)
* size : (optional) length of body
* = the body content as string

### Conn:path()
* = the requested path

### Conn:getHeaders()
* = a dictionary with header=values

###	Conn:getHeader(headerName)
* = header

### Conn:method()
* = requested method

### Conn:querystring()
* = querystring

### Conn:queryData()
* = dictionary with data passed on querystring

### Conn:requestData() : DataTable, Files
Returns a table with field data and a second table only with files

Example:
```
local data, file = Conn:requestData()
```

Observe that data will always be a dictionary of lists, what means that you
can repeat a named input in a form, that it will be understood

Structure of the data table:
```
data = {
	[fieldname] = {
		fieldValue,
		fieldValue,
		...
	}
}
```

The files table is a dictionary indexing each form field name with a list of values.
Each value is a table containg information of distinct uploaded files.
Observe that the tmpfile is removed from disk after request.

Structure of the data table:
```
files = {
	[fieldname or method] = {
		{ name = "name of the file", tmpname = "tmpfile on disk", mime = "mimetype" },
		{...}
	}
}```


### Conn:addHeaders(table)
* table : dictionary with header=value to be sent client
* = Conn

### Conn:addHeader(key, value)
* = Conn

### Conn:statusCode(httpStatusNumber)
* = Conn

### Conn:contentType(mime)

### Conn:write(string, stayOpen)
* string : data to be sent client
* stayOpen : if true, keep connection for following writes

This function automatically send headers before content.

### Conn:writeFile(file, contentType)
Send a file content to client and close connection
]]
local match = {
	formdataFileHead=[=[Content%-Disposition:%s*form%-data;%s*name="([^%s"]-)";?(%s*filename="([^%s"]-)")]=],
	formdataFileType=[=[Content%-Type:%s*([%w%d/_-]+)]=],
	formdataFieldHead=[=[Content%-Disposition:%s*form%-data;%s*name="([^%s"]-)"]=],
	queryString=[=[([^=]*)=([^&]*)&?]=]

}
local Conn = {}
function Conn:receiveBody(...) return self._request:receiveBody(...) end
function Conn:path(...) return self._request:path(...) end
function Conn:getHeaders() return self._request:headers() end
function Conn:getHeader(x) return self._request:headers()[x] end
function Conn:method(...) return self._request:method(...) end
function Conn:querystring(...) return self._request:querystring(...) end
function Conn:queryData(...) return self._request:queryData(...) end
function Conn:addHeaders(...) return self._response:addHeaders(...) end
function Conn:addHeader(...) return self._response:addHeader(...) end
function Conn:statusCode(...) return self._response:statusCode(...) end
function Conn:contentType(...) return self._response:contentType(...) end
function Conn:write(...) return self._response:write(...) end
function Conn:writeFile(...) return self._response:writeFile(...) end

-- Get all the request body
local function _getBody(conn)
	local b,c={}
	repeat
		c = conn:receiveBody(8192)
		if c then b[#b+1] = c end
	until not c
	return table.concat(b)
end

-- Parses the content of request when it is a single sent file
local function _getFileData(conn,mime)
	local t = os.tmpname()
	io.open(t,'w+'):write(_getBody(conn)):close()

	return { [conn:method()] = {{
		tmpname = t,
		name = conn:path(),
		mime = mime
	}}}
end

-- Parses the content of request when in multipart/form-data format
local function _getFormData(conn,boundary,length)
	local D, F = {}, {} -----------> Data and File list
	local cont = _getBody(conn) ---> Full multipart content
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

			dname,_,dfile = phead:match(match.formdataFileHead)
			if dfile then
				dmime = phead:match(match.formdataFileType)
				if dmime then
					local tmpname = os.tmpname()
					F[dname] = F[dname] or {}
					F[dname][#F[dname]+1] = {tmpname = tmpname,	name=dfile,	mime=dmime }
					io.open(tmpname,'w+'):write(part:sub(#phead+5)):close()
				end
			else
				dname=phead:match(match.formdataFieldHead)
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
		for k,v in string.gmatch(value, match.queryString) do
			if d[k] then d[k][#d[k]] = urldecode(v,1) else d[k]={urldecode(v,1)} end
		end
	end
	return d
end

function Conn:requestData()
	if self._bodyData and self._files then return self._bodyData, self._files end
	local h = self:getHeaders()
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


return {
	new = function(S)
		--[[

		### Conn.server.startdate
		Date (yymmddHHMMSS) when server started

		### Conn.server.hit
		Number of server hits
		]]
		local datestart = os.date('%y%m%d%H%M%S')
		local hit = 0
		S.conf.tempdir  = '/tmp'

		local R = S.rules
		local Server = ws:new({
			port     = S.conf.port or 8080,
			location = S.conf.location or PATH..'/www',
			plugins  = S.conf.compress and { require('aurora.ws.pegasus.compress'):new() } or {}
		})

		Server:start( function (request,response)
			hit = hit + 1

			local conn = setmetatable(
				{ _request = request, _response = response,	_socketConn = request.client },
				{ __index = Conn }
			)
			local path, query = conn:path(), conn:queryData()

			for i=1, #S.rules do
				local match = table.pack (path:match (R[i][1]))
				if match[1] then
					conn.server = {
						hit = hit,
						datestart = datestart,
						conf = S.conf,
						match = match
					}

					if type (R[i][2]) == 'number' then
						conn:statusCode (R[i][2])
						if type (R[i][3]) == 'table' then
							conn:addHeaders (R[i][3])
						end
						conn:write()
					else
						require (R[i][2]) (conn)
					end
					break
				end
			end

			if conn._files then for _,v in pairs(conn._files) do
				for i=1, #v do os.remove(v[i].tmpname) end
			end end
		end)

		return Server
	end
}

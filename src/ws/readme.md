## Aurora WebServer utility

An HTTP server that handles asynchronous connections, allowing user to serve
static files or create content service or apis using lua scripts. Provides some
facilities like upload and form data handling.

Aurora WebServer started from a fork of Pegasus.lua (https://evandrolg.github.io/pegasus.lua)
using from the start Copas, i.e., allowing assynchronous connections.

### Basic Usage


```Lua
local conf = {
	server = {
		port: 8080,
		host: '*',
		location: "/document/root/path",
		compress: true,
	},
	rules = {
		{ "/api"       , "web.api"  }
		{ "/something" , 301       , { "Location" = "/" } }
	}
}
```


### Rules

Rules are defined in a simple Lua table format; The root table is a list where
each item is a rule as follows:

```Lua
	conf.rules = { rule1, rule2, ruleN }
```

Each rule is a table too, having three values.

```Lua
	{ MATCH_PATTERN, LUA_MODULE, DEFAULT_HEADERS_TABLE }
	or
	{ MATCH_PATTERN, STATUSCODE, DEFAULT_HEADERS_TABLE }
```

#### MATCH_PATTERN

It is ever the first value, being a Lua match pattern that, if matches
the query path then proceeds to evaluating 2nd and the optional 3rd values.

Observe that if the rule matched, the next rules will be ignored.

#### LUA_MODULE

Here you can put the name of the module as if you require it using Lua `require`
This module returns a function, as in the followinf module example.

```Lua
local function Module (request, response, server)
	local q = request:queryData()["query"]
	if q then
		response:write(q)
	else
		response:statusCode(404)
	end
end

return Module
```

#### STATUS_CODE

Instead of LUA_MODULE you can serve a number with status code. A shorthand for
redirects and notfounds.

Observe that it is the 2nd rule table value. You cannot use both LUA_MODULE and
STATUS_CODE at the same 2nd position of rule table at the same time.

#### DEFAULT_HEADERS_TABLE

An optional parameter to add default header to response.


### Request

#### Request Properties

* number : number of this request, since server start


#### path() : string
Gets the requested path

#### querystring() : string
Gets the querystring part of request

#### queryData() : table
Gets a dictionary with data passed through query string

#### receiveBody(size) : string

* size : (optional) length of body

Gets the body content as string. If informed size, starts getting only chunk


#### headers() : table

Returns a table dictionary with header=values pairs

#### method() : str

Gets the method name from HTTP request (GET, POST, PUT etc.)

#### data() : DataTable, Files
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
}
```

### Response

#### Response:statusCode(httpStatusNumber) : Request
Define correctly the HTTP status code on response

#### contentType(mime) : Request
Shorthand to add Content-Type header to response

#### addHeaders(table) : Request
Adds a dictionary table with pairs name=value

#### addHeader(key, value) : Request
Add a single header per call.

#### write(string, stayOpen)

* string : data to be sent client
* stayOpen : if true, keep connection for following writes

This function automatically send headers before content.

#### writeFile(file, contentType)

Send a file content to client and close connection


### Server

The server parameter passed to rule module is filled with properties that shows
the server info:

* startdate: (yymmddHHMMSS) when server started
* hits: Number of server hits
* port: Listening server port
* tempdir: temporary directory (Ex. used to save temp uploaded files)

## Aurora WebServer utility

An HTTP server that handles asynchronous connections, allowing user to serve
static files or create content service or apis using lua scripts. Provides some
facilities like upload and form data handling.

Aurora WebServer started from a fork of Pegasus.lua (https://evandrolg.github.io/pegasus.lua)
using from the start Copas, i.e., allowing assynchronous connections.

### Basic Usage


```Lua
local conf = {
	compress = true,
	host = '*',
	servers = {
		{
			port = 8080,
			name = 'yourhostname.com',
			default = false,
			root = '/your/document/root/',
			tempdir = DIR..'/var/adm.akasha/tmp/',

			rules = {
				{ '^/api/', {
					process=require('srv.api'),
				}},
				{ '^/other/', {
					root='/other/specific/document/root/',
				}},
				{ '^/test', {
					status = 301,
					headers = {
						Location = '/',
					}
				}}
			},

			-- custom server data
			var = {
				yourvar = 'custom var accessible through processes and execs'
			}
		}
	},
},
-- function that process rules.
-- default is aurora.ws.ruler
-- just one allowed on conf, affects all servers
ruler = nil
```


### Rules

Rules are defined in a simple Lua table format; The root table is a list where
each item is a rule as follows:

```Lua
	conf.rules{
		{ MATCH_PATTERN, INSTRUCTIONS },
		...
	}
```

Where:
* `matchPattern` is a simple Lua pattern matched against location path excluding
host name.
* `instructions` is a Lua table containg instructions of how process request:


#### Rule MATCH_PATTERN

It is ever the first value of a rule entry, being a Lua match pattern that, if matches
the query path then proceeds to evaluating 2nd rule entry value, i.e. INSTRUCTIONS.

Observe that if the rule matched, the next rules will be ignored.

#### Rule INSTRUCTIONS

It is a table indicating if will be processed with Lua, if has default headers etc.

Possible values:

* instruction.process : (optional) a function that receives current (Vhost, Request, Response)
* instruction.headers : a dictionary with default headers
* instruction.status : default HTTP status
* instruction.root : document root for this specific rule

If the rule doens't have a instruction.process then the server will try to find
a files in the custom document root (if set) or the server default

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

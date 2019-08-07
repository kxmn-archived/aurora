package = "Lunar"
version = "0.1-1"
source = {
   url = "git://github.com/kxmn/lunar", -- We don't have one yet
	 tag = "v0.1"
}
description = {
   summary = "Tools to make Lua feels like home",
   detailed = [[
      Set to provide functionalities from others languages in an
			easy and ready to use way.
   ]],
   homepage = "http://...", -- We don't have one yet
   license = "MIT" -- or whatever you like
}
dependencies = {
   "lua >= 5.3",
   "luafilesystem >= 1.7.0-2",
	 "luasocket > 3.0rc1-2",
	 "lua-cjson = 2.1.0-1",
	 "lzlib >= 0.4.1.53-1",
	 "mimetypes 1.0.0-2"
}
build = {
   -- We'll start here.
	type = "builtin",
	modules = {
		lunar = "init.lua",
		["lunar.fs"] = "fs/init.lua",
		["lunar.fs.basename"] = "fs/basename.lua",
		["lunar.fs.dirname"] = "fs/dirname.lua",
		["lunar.fs.getFileContents"] = "fs/getFileContents.lua",
		["lunar.fs.isDir"] = "fs/isDir.lua",
		["lunar.fs.isFile"] = "fs/isFile.lua",
		["lunar.fs.mkdir"] = "fs/mkdir.lua",
		["lunar.fs.putFileContents"] = "fs/putFileContents.lua",
		["lunar.httpserver"] = "httpserver/init.lua",
		["lunar.httpserver.pegasus.compress"] = "httpserver/pegasus/compress.lua",
		["lunar.httpserver.pegasus.file"] = "httpserver/pegasus/file.lua",
		["lunar.httpserver.pegasus.handler"] = "httpserver/pegasus/handler.lua",
		["lunar.httpserver.pegasus"] = "httpserver/pegasus/init.lua",
		["lunar.httpserver.pegasus.request"] = "httpserver/pegasus/request.lua",
		["lunar.httpserver.pegasus.response"] = "httpserver/pegasus/response.lua",
		["lunar.string"] = "string/init.lua",
		["lunar.string.split"] = "string/split.lua",
		["lunar.template"] = "template/init.lua",
	}
}

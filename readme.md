# LUNAR

Making Lua feels like home

* On demand method loader
* Missing Lua functions implemented from other languages
* Some abstraction over tiny and very useful 3rd party code


### On Demand method loader

On `your/awful/proj/init.lua` put just this:

```Lua
	require('lunar')
	ondemand('my.awful.proj')
```

And just create a bunch of files inside `your/awful/proj` folder,
like... hmmm... `implode.lua`

```Lua
	return function(t,glue) 
		return table.concat(t,glue)
	end
```
Now, in your works you just `require "your.awful.proj"` and use
any of the files inside your `proj` folder, like this:

```Lua
	local p = require("your.awful.proj")
	p.concat({'just this'},'-')
```


# 3rd party credit

Below, a list with 3rd party snippets mixed in Lunar code.
Some of these were changed and adapted.

* Template: using Lilua
* HTTP Server: using Pegasus

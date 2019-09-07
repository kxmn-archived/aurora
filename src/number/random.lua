--[[md:
### number.random(bytes,mask)

* bytes : (default=4) bytes that should be read from /dev/urandom
* mask : (default=256) mask used incrementally for each
* Returns a random number

]]

return function(b,m)
	b=b or 4
	local f = io.open ('/dev/urandom','rb')
	local n, input = 0, f:read (b)
	for i=1, input:len () do
		n = 256 * n + input:byte (i)
	end
	f:close()
	return n
end

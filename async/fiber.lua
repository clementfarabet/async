-- c lib / bindings for libuv
local uv = require 'luv'

-- tcp
local tcp = require 'async.tcp'

-- handle
local handle = require 'async.handle'

-- new fiber:
local fiber = function(func)
   -- start new coroutine:
   coroutine.wrap(func)()
end

-- return
return fiber

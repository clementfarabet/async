-- c lib / bindings for libuv
local uv = require 'luv'

-- Time routines:
local time = {}

function time.setTimeout(timeout, callback)
   local timer = uv.new_timer()
   function timer:ontimeout()
      uv.timer_stop(timer)
      uv.close(timer)
      callback(self)
   end
   uv.timer_start(timer, timeout, 0)
   function timer.clear()
      uv.timer_stop(timer)
      uv.close(timer)
   end
   return timer
end

function time.setInterval(interval, callback)
   local timer = uv.new_timer()
   function timer:ontimeout()
      callback(self)
   end
   uv.timer_start(timer, interval, interval)
   function timer.clear()
      uv.timer_stop(timer)
      uv.close(timer)
   end
   return timer
end

-- return
return time

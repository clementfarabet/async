local uv = require 'luv'

-- make handle out of uv client
local function handle(client)
   local h = {}
   h.ondata = function(cb)
      client.ondata = function(self,data)
         if cb then cb(data) end
      end
   end
   h.onend = function(cb)
      client.onend = function(self)
         if cb then cb() end
      end
   end
   h.onclose = function(cb)
      client.onclose = function(self)
         if cb then cb() end
      end
   end
   h.write = function(data,cb)
      uv.write(client, data, cb)
   end
   h.close = function(cb)
      uv.shutdown(client, function()
         uv.close(client)
         if cb then cb() end
      end)
   end
   return h
end

-- auto bind stdin/stdout:
io.stdin = uv.new_tty(0,1)
io.stdout = uv.new_tty(1)
io.stderr = uv.new_tty(2)
io.stdout.write = uv.write
io.stderr.write = uv.write
uv.read_start(io.stdin)

-- handlify stds:
local stdin = handle(io.stdin)
local stdout = handle(io.stdout)
local stderr = handle(io.stderr)

-- TCP server/client:
local tcp = {}

function tcp.listen(domain, cb)
   local host = domain.host
   local port = domain.port
   local server = uv.new_tcp()
   uv.tcp_bind(server, host, port)
   function server:onconnection()
      local client = uv.new_tcp()
      uv.accept(server, client)
      cb(handle(client))
      uv.read_start(client)
   end
   uv.listen(server)
   return handle(server)
end

function tcp.connect(domain, cb)
   local host = domain.host
   local port = domain.port
   local client = uv.new_tcp()
   local h = handle(client)
   uv.tcp_connect(client, host, port, function()
      cb(h)
      uv.read_start(client)
   end)
   return h
end

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
   
-- Eval:
local function eval(str)
   -- capture:
   local function captureResults(success, ...)
      local n = select('#', ...)
      return success, { n = n, ... }
   end

   -- eval:
   local f,err = loadstring('return ' .. str, 'REPL')
   if not f then
      f,err = loadstring(str, 'REPL')
   end
   if f then
      local ok,results = captureResults(xpcall(f, debug.traceback))
       if ok then
          print(unpack(results))
       else
          print(results[1])
       end
   else
      print(err)
   end
end

-- repl:
local function lrepl(self,prompt)
   -- prompt:
   prompt = prompt or _PROMPT or '> '
   stdout.write(prompt)
   
   -- capture stdin:
   stdin.ondata(function(line)
      local res = eval(line)
      stdout.write(prompt)
   end)

   -- terminate:
   stdin.onend(function()
      os.exit()
   end)
end

-- remote repl:
local repl = {}
setmetatable(repl, {
   __call = lrepl
})

-- repl server:
function repl.listen(domain)
   -- prompt
   local prompt = domain.prompt or 'remote> '

   -- list of connected clients, to mirror:
   local clients = {}
   local iowrite = io.write
   io.write = function(...)
      for client in pairs(clients) do
         client.write(...)
      end
      iowrite(...)
      io.flush()
   end

   -- listen:
   tcp.listen(domain, function(client)
      -- wait for remote commands:
      client.ondata(function(data)
         --iowrite(data)
         eval(data)
         client.write(prompt)
      end)

      -- on end, disconnect mirroring:
      client.onend(function()
         clients[client] = nil
      end)

      -- connect:
      clients[client] = true

      -- prompt:
      client.write(prompt)
   end)
end

-- repl client:
function repl.connect(domain)
   tcp.connect(domain, function(client)
      -- receive results from server
      client.ondata(function(data)
         stdout.write(data)
      end)

      -- capture stdin:
      stdin.ondata(function(line)
         client.write(line)
      end)

      -- terminate:
      stdin.onend(function()
         os.exit()
      end)
   end)
end

-- run loop:
local function go()
   -- start event loop:
   uv.run('once')
end

-- return package:
return {
   tcp = tcp,
   setInterval = time.setInterval,
   setTimeout = time.setTimeout,
   uv = uv,
   go = go,
   cpuInfo = uv.cpuInfo,
   hrtime = uv.hrtime,
   getTotalMemory = uv.get_total_memory,
   getFreeMemory = uv.get_free_memory,
   repl = repl,
   stdin = stdin,
   stdout = stdout,
   stderr = stderr
}

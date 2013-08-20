-- c lib / bindings for libuv
local uv = require 'luv'

-- tcp
local tcp = require 'async.tcp'

-- handle
local handle = require 'async.handle'

-- repl:
local repl = {}

-- bind io:
local bindok = false
local stdin,stdout,stderr
local function bindio()
   if not bindok then
      -- auto bind stdin/stdout:
      io.stdin = uv.new_tty(0,1)
      io.stdout = uv.new_tty(1)
      io.stderr = uv.new_tty(2)
      io.stdout.write = uv.write
      io.stderr.write = uv.write
      uv.read_start(io.stdin)

      -- handlify stds:
      stdin = handle(io.stdin)
      stdout = handle(io.stdout)
      stderr = handle(io.stderr)

      -- done
      bindok = true

      -- export
      repl.stdin = stdin
      repl.stdout = stdout
      repl.stderr = stderr
   end
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
   -- bind io
   bindio()

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
setmetatable(repl, {
   __call = lrepl
})

-- repl server:
function repl.listen(domain)
   -- prompt
   local prompt = 'remote> '
   if type(domain) == 'table' and domain.prompt then
      prompt = domain.prompt
   end

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
      client.onsplitdata('\n', function(data)
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
   -- bind io
   bindio()

   -- connect
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

-- return 
return repl

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
repl.bindio = bindio

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
   local prompt
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
      -- prompt:
      local s = client.sockname
      prompt = prompt or (s.address..':'..s.port..'> ')

      -- verbose:
      io.write(prompt .. 'remote client @ ' .. client.peername.address..':'..client.peername.port..'\n')

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
         client.write(' '..line)
      end)

      -- terminate:
      stdin.onend(function()
         os.exit()
      end)
   end)
end

-- useful: colors
repl.colors = {
   none = '\27[0m',
   black = '\27[0;30m',
   red = '\27[0;31m',
   green = '\27[0;32m',
   yellow = '\27[0;33m',
   blue = '\27[0;34m',
   magenta = '\27[0;35m',
   cyan = '\27[0;36m',
   white = '\27[0;37m',
   Black = '\27[1;30m',
   Red = '\27[1;31m',
   Green = '\27[1;32m',
   Yellow = '\27[1;33m',
   Blue = '\27[1;34m',
   Magenta = '\27[1;35m',
   Cyan = '\27[1;36m',
   White = '\27[1;37m',
   _black = '\27[40m',
   _red = '\27[41m',
   _green = '\27[42m',
   _yellow = '\27[43m',
   _blue = '\27[44m',
   _magenta = '\27[45m',
   _cyan = '\27[46m',
   _white = '\27[47m'
}
function colorize(str,color)
   return repl.colors[color] .. str .. repl.colors.none
end
local short = {}
for color in pairs(repl.colors) do
   short[color] = function(str)
      return colorize(str,color)
   end
end
repl.colorize = short

-- return 
return repl

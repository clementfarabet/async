-- c lib / bindings for libuv
local uv = require 'luv'

-- handle
local handle = require 'async.handle'

-- Process lib
local process = {}

-- Spawn
function process.spawn(path, args, handler)
   -- spawn process:
   local h, stdin, stdout, stderr, pid = uv.spawn(path, args)

   -- handlify pipes:
   local _stdin = handle(stdin)
   local _stdout = handle(stdout)
   local _stderr = handle(stderr)

   -- package client:
   local client = {
      kill = function(code)
         code = code or 'SIGTERM'
         uv.process_kill(h, code)
      end,
      onexit = function(cb)
         h.onexit = function(self,status,signal)
            if cb then cb(status,signal) end
            uv.close(h)
            uv.close(stdin)
            if not _stdout.reading then
               uv.close(stdout)
            end
            if not _stderr.reading then
               uv.close(stderr)
            end
         end
      end,
      pid = pid,
      stdin = _stdin,
      stdout = _stdout,
      stderr = _stderr,
   }

   -- Default handler
   client.onexit()

   -- Handler
   if handler then handler(client) end

   -- return client
   return client
end

-- Exec
function process.exec(path, args, callback)
   -- Spawn:
   process.spawn(path, args, function(process)
      local result = {}
      local term = false
      process.stdout.ondata(function(chunk)
         table.insert(result,chunk)
      end)
      process.stdout.onend(function()
         result = table.concat(result)
         if term then
            callback(result,unpack(term))
         end
      end)
      process.onexit(function(code,signal)
         if type(result) == 'string' then
            callback(result,code,signal)
         else
            term = {code,signal}
         end
      end)
   end)
end

-- Process lib
return process

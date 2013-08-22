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
   stdin = handle(stdin)
   stdout = handle(stdout)
   stderr = handle(stderr)

   -- package client:
   local client = {
      kill = function(code)
         code = code or 15 
         os.execute('kill -' .. code .. ' ' .. pid)
      end,
      onexit = function(cb)
         h.onexit = function(self,status,signal)
            if cb then cb(status,signal) end
         end
      end,
      pid = pid,
      stdin = stdin,
      stdout = stdout,
      stderr = stderr,
   }

   -- Handler
   handler(client)

   -- return client
   return client
end

-- Exec
function process.exec(path, args, callback)
   -- Spawn:
   process.spawn(path, args, function(process)
      local result = {}
      process.stdout.ondata(function(chunk)
         table.insert(result,chunk)
      end)
      process.onexit(function(code,signal)
         result = table.concat(result)
         callback(result,code,signal)
      end)
   end)
end

-- Process lib
return process

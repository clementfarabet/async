-- c lib / bindings for libuv
local uv = require 'luv'

-- handle
local handle = require 'async.handle'

-- Process lib
local process = {}

-- Spawn
function process.spawn(path, args, handler)
   -- TODO: bind actual uv_spawn call
   -- this is temporary crap...
   local cmd = path .. ' ' .. table.concat(args, ' ') .. ' & \n echo $!'
   require 'sys'
   local pid = sys.execute(cmd)

   -- fake client for now
   local client, cbonclose
   client = {
      kill = function(code)
         code = code or 9
         os.execute('kill -' .. code .. ' ' .. pid)
         if cbonclose then cbonclose() end
      end,
      onclose = function(f)
         cbonclose = f
      end,
      pid = pid,
   }

   -- Hanldler
   handler(client)
end

-- Process lib
return process

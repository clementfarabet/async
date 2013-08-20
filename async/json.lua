-- c lib / bindings for libuv
local uv = require 'luv'

-- tcp
local tcp = require 'async.tcp'

-- JSON server/client
-- This is a non-standard protocol, which is very handy
-- to serialize data from one process to another. Each packet
-- is a table, serialized as a JSON string. Each JSON string
-- is separated by a \0. See examples.
local _,json = pcall(require,'cjson')

function json.listen(domain, cb)
   tcp.listen(domain, function(client)
      client.onsplitdata('\0', function(req)
         -- decode json:
         req = json.decode(req)

         -- call user handle:
         cb(req, function(res)
            res = json.encode(res) .. '\0'
            client.write(res)
         end)
      end)
   end)
end

function json.connect(domain, cb)
   tcp.connect(domain, function(client)
      client.send = function(tbl)
         local req = json.encode(tbl) .. '\0'
         client.write(req)
      end
      local receive
      client.receive = function(f)
         receive = f
      end
      client.onsplitdata('\0', function(req)
         -- decode json:
         req = json.decode(req)

         -- call user receive function:
         if receive then
            receive(req)
         end
      end)
      cb(client)
   end)
end

-- return
return json

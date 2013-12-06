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
      client.onsplitdata('\n', function(req)
         -- decode json:
	local ok, req = pcall(json.decode, req)
	if not ok then print('bad json request'); client.close(); return; end

         -- call user handle:
         cb(req, function(res)
            res = json.encode(res) .. '\n'
            client.write(res)
         end)
      end)
   end)
end

function json.connect(domain, cb)
   tcp.connect(domain, function(client)
      client.send = function(tbl)
         local req = json.encode(tbl) .. '\n'
         client.write(req)
      end
      local receive
      client.receive = function(f)
         receive = f
      end
      client.onsplitdata('\n', function(req)
         -- decode json:
	 local ok, req = pcall(json.decode, req)
         if not ok then print('bad json request'); client.close(); return; end

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

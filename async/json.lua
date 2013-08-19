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
pcall(require,'pl')

function json.listen(domain, cb)
   tcp.listen(domain, function(client)
      local fullpacket = {}
      client.ondata(function(chunk)
         local chunks = stringx.split(chunk,'\0')
         for i,chunk in ipairs(chunks) do
            table.insert(fullpacket,chunk)
            if i < #chunks then
               local req = table.concat(fullpacket)
               req = json.decode(req)
               fullpacket = {}
               cb(req, function(res)
                  res = json.encode(res) .. '\0'
                  client.write(res)
               end)
            end
         end
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
      local fullpacket = {}
      client.ondata(function(chunk)
         local chunks = stringx.split(chunk,'\0')
         for i,chunk in ipairs(chunks) do
            table.insert(fullpacket,chunk)
            if i < #chunks then
               local req = table.concat(fullpacket)
               req = json.decode(req)
               fullpacket = {}
               if receive then
                  receive(req)
               end
            end
         end
      end)
      cb(client)
   end)
end

-- return
return json

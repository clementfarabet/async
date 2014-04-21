async = require 'async'
require 'torch'

-- tests serialization/deserialization of torch objects
-- tests communication of data through fiber.resume(data)/fiber.yield()
-- tests a tcp repeater between a client and a server (a chain)
-- can be used for chained RPC using fibers : replace torch.tensor with a Command design pattern

local separator = '<347 SPLIT 879>'

-- repeater : receives and forwards to/from another repeater
local repeater = async.tcp.listen({host='localhost', port=8080}, function(client)
   async.fiber(function()
      client.sync()
      --listens to incomming commands from the network
      print('repeater: new connection:',client)
      local data = client.readsplit(separator)
      print('repeater: received #data :', #data)
      local tensor = torch.deserialize(data)
      print('repeater: received tensor :', torch.typename(tensor))
      -- coroutine is yielded after SEND when waiting for async client.
      -- returns after final resume()
      local f = async.fiber.context()
      ------- SEND --------
      -- execute command within a session (yields after send)
      local client2 = async.tcp.connect({host='localhost', port=8483}, function(client)
         local data = torch.serialize(tensor)
         client.onsplitdata(separator, function(data)
            local reply = torch.deserialize(data)
            print('repeater: closing connection to server')
            client.close()
            print('repeater: sending reply via resume/yield')
            f.resume(reply)
         end)
         client.write(data)
         client.write(separator)
      end)
      -- this should be resumed by tcp client when reply is received
      local reply = f.yield()
      print('repeater: after yield')
      -------- REPLY ----------
      -- send back reply to client
      local data = torch.serialize(reply, mode)
      client.write(data)
      client.write(separator)
      print('repeater: after write')
   end)
end)

local server = async.tcp.listen({host='localhost', port=8483}, function(client)
   print('server: new connection:',client)
   client.onsplitdata(separator, function(data)
	   print('server: received #data :', #data)
	   local tensor = torch.deserialize(data)
      print('server: received tensor :', torch.typename(tensor))
      data = torch.serialize(tensor)
      print('server: sending data', #data)
      client.write(data)
      client.write(separator)
      print('server: after write')
   end)
   client.onend(function()
      print('server: ended')
   end)
   client.onclose(function()
      print('server: closed.')
      collectgarbage()
      print(collectgarbage("count") * 1024)
   end)
end)

async.go()

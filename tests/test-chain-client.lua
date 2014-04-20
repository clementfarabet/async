async = require 'async'
require 'torch'

local separator = '<347 SPLIT 879>'
local tensor = torch.randn(3,3)

local client = async.tcp.connect({host='localhost', port='8080'}, function(client)
   print('new connection:',client)
   client.onsplitdata(separator, function(data)
      print('received:', #data)
      local tensor2 = torch.deserialize(data)
      assert(torch.eq(tensor2, tensor):sum() == tensor:nElement())
      print('received tensor :', torch.typename(tensor2))
      client.close()
   end)
   client.onend(function()
      print('client ended')
   end)
   client.onclose(function()
      print('closed.')
   end)
   local data = torch.serialize(tensor)
   print('sending :', #data)
   client.write(data)
   client.write(separator)
   print('wrote data')
end)

async.go()

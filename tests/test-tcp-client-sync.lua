local async = require 'async'

local client = async.tcp.connect('tcp://127.0.0.1:8483/', function(client)
   async.fiber(function()
      client.write('test')
      local res = client.read()
      print('received, sync: ', res)

      client.write('test')
      local res = client.read()
      print('received, sync: ', res)

      client.close()
   end)
end)

async.go()

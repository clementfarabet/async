local async = require 'async'

local client = async.tcp.connect('tcp://127.0.0.1:8483/', function(client)
   print('new connection:',client)
   client.ondata(function(data)
      print('received:',data)
   end)
   client.onend(function()
      print('client ended')
   end)
   client.onclose(function()
      print('closed.')
   end)
   client.write('test')

   local interval = async.setInterval(1000, function()
      client.write('test_ontimer')
   end)

   async.setTimeout(5000, function()
      client.close()
      interval.clear()
   end)
end)

async.go()

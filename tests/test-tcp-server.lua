local async = require 'async'

local server = async.tcp.listen({host='localhost', port=8483}, function(client)
   print('new connection:',client)
   client.ondata(function(data)
      print('received:',data)
      client.write(data)
   end)
   client.onend(function()
      print('client ended')
   end)
   client.onclose(function()
      print('closed.')
   end)
end)

async.repl()

async.go()

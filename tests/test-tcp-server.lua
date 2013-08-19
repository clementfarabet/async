local async = require 'async'

local server = async.tcp.listen({host='0.0.0.0', port=8483}, function(client)
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

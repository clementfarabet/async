local async = require 'async'
local b = require 'buffer'

local server = async.tcp.listen({host='localhost', port=8483}, function(client)
   client.onrawdata(function(data)
      client.write(data)
   end)
end)

async.setTimeout(1000, function()
   local client = async.tcp.connect('tcp://localhost:8483/', function(client)
      client.onrawdata(function(data)
         print('received:',data:toString())
      end)

      local counter = 0
      local interval = async.setInterval(200, function()
         client.write(b('test_ontimer' .. counter))
         counter = counter + 1
      end)

      async.setTimeout(1000, function()
         client.close()
         interval.clear()
      end)
   end)
end)

async.go()

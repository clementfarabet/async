local async = require 'async'

async.json.connect({host='localhost', port=8483}, function(client)
   client.receive(function(res)
      print('response:',res)
   end)
   local int = async.setInterval(200,function()
      client.send({
         msg = 'hey, how are you man?',
         attached = 'how are you?'
      })
   end)
   async.setTimeout(1000, function()
      client.close()
      int.clear()
   end)
end)

async.go()

local async = require 'async'

local count = 1
local countt = 1

async.setInterval(10, function()
   async.process.exec('ls', {'-l'}, function(result, code)
      count = count + 1
      print('exec:',count)
   end)
   
   async.process.spawn('ls', {}, function(client)
      countt = countt + 1
      print('spawn:',countt)
   end)
end)

async.go()

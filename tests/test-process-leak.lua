
async = require 'async'

function doo()
   async.process.spawn('ls', {'.'}, function(process)
      process.kill()
      process.onexit(function()
         collectgarbage()
         print( collectgarbage('count') * 1024 )
         doo()
      end)
   end)
end
doo()

async.go()

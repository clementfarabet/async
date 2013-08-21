local async = require 'async'

async.process.spawn('th', {'-e','"while true do a=1 end"'}, function(process)
   print('spawned: ', process)
   process.onend(function()
      print('process: ' .. process.pid .. ' dead...')
   end)
   process.kill()
end)

async.go()

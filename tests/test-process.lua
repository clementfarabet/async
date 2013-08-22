local async = require 'async'

async.process.spawn('th', {'-e','"while true do a=1 end"'}, function(process)
   print('spawned process: ' .. process.pid)
   process.onexit(function(status, signal)
      print('process: ' .. process.pid .. ' exit with status/signal: ' .. status .. ', ' .. signal)
   end)
   process.kill()
end)

async.process.exec('ls', {'-l'}, function(result, code)
   print('ls output:')
   io.write(result)
   print('ls terminated with code: ' .. code)
end)

async.go()

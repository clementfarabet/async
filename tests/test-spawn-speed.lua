local async = require 'async'

async.setInterval(2000, function()
   local t = async.hrtime()
   async.process.spawn('th', {'-e','a = io.read("*line") print(a) for i = 1,3 do print(i) end'}, function(process)
      t = async.hrtime() - t
      print('spawned process: ' .. process.pid .. ' in ' .. t .. 'ms')
      process.stdout.ondata(function(data)
         io.write(''..process.pid.. ': ' .. data)
      end)
      process.stderr.ondata(function(data)
         io.write(''..process.pid.. ': ' .. data)
      end)
      process.stdin.write('go\n')
   end)
end)

async.go()

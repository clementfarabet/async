local async = require 'async'

async.process.spawn('th', {'-e','require "sys" a = io.read("*line") print(a) io.flush() for i = 1,10 do sys.sleep(1) print(10) io.flush() end'}, function(process)
   async.fiber(function()
      print('spawned process: ' .. process.pid)
      process.stdin.write('go\n')
      while true do
         local read = process.stdout.readsplit('\n')
         io.write(''..process.pid.. ': ' .. read .. '\n')
      end
   end)
end)

async.go()

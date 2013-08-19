local async = require 'async'

async.fs.readFile('test-fileio.lua', function(file)
   print(file)
   async.fs.writeFile('test-fileio.lua.backup', file, function(err)
      print(err)
   end)
end)

async.fs.stat('test-fileio.lua', function(stats)
   print(stats)
end)
async.go()

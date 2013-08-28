local async = require 'async'
local setTimeout = require 'async'.setTimeout
local fiber = require 'async.fiber'
local wait = require 'async.fiber'.wait

fiber(function()
   -- wait on one function:
   local result = wait(setTimeout, {1000}, function(timer)
      return 'something produced asynchronously'
   end)
   print(result)

   -- wait on multiple functions:
   local results = wait({setTimeout, setTimeout}, {{500},{3000}}, function(timer)
      return 'some result',timer
   end)
   print(results)
end)

async.go()

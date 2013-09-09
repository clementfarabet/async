local async = require 'async'
local setTimeout = require 'async'.setTimeout
local fiber = require 'async.fiber'
local wait = require 'async.fiber'.wait
local exec = require 'async.process'.exec

fiber(function()
   -- wait on one function:
   local result,aux = wait(setTimeout, {1000}, function(timer)
      return 'something produced asynchronously', 'test'
   end)
   print(result,aux)

   -- wait on multiple functions:
   local results = wait({setTimeout, setTimeout}, {{500},{1000}}, function(timer)
      return 'some result',timer
   end)
   print(results)
   
   -- spawn job, default callback
   local res = wait(exec, {'ls', {'-l'}})
   print(res)
end)

async.go()

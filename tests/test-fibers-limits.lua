local async = require 'async'
local setTimeout = require 'async'.setTimeout
local fiber = require 'async.fiber'
local wait = require 'async.fiber'.wait
local sync = require 'async.fiber'.sync
local exec = require 'async.process'.exec

fiber(function()
   -- functions to run in //
   local funcs,args = {},{}
   for i = 1,2000 do
      funcs[i] = function(cb) 
         async.process.exec('ls', {}, cb) 
      end
      args[i] = {}
   end
   
   -- run!
   local res = wait(funcs, args, function(res)
      return res
   end)
   print(#res)
   print(res[1])
end)

async.go()

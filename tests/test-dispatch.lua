-- Async
local async = require 'async'

-- Nb of jobs:
local N = 32

-- Run:
async.run(function()
   for i = 1,N do
      local code = [[
         local jobid = ${jobid}
         local njobs = ${njobs}
         print("running job " .. jobid .. " out of " .. njobs)
      ]]

      async.process.dispatch(code, {jobid = i, njobs = N}, function(process)
         process.onexit(function(status, signal)
         end)
         process.stdout.ondata(function(data)
            io.write('[process:'..process.pid.. '] ' .. data)
            io.flush()
         end)
      end)
   end
end)

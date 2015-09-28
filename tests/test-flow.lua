local async = require 'async'

local limiter = async.flow.ratelimiter(5)

for i = 1,100 do
   limiter(function(idx,cb)
      print(idx)
      cb()
   end, {i})
end

async.go()

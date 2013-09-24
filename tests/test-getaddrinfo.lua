local async = require 'async'

async.getAddrInfo(nil, '80', function(...)
   print(...)
end)

async.go()

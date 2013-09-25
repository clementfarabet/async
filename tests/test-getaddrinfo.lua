local async = require 'async'

async.getAddrInfo({port=80}, function(...)
   print(...)
end)

async.getAddrInfo({path='google.com', port=80, {socktype='STREAM', addrconfig=true}}, function(...)
   print(...)
end)

async.go()

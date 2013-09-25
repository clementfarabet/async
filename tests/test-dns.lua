local async = require 'async'

async.getAddrInfo({port=80}, function(results)
   print('localhost:')
   for i = 1,math.min(3,#results) do
      print(results[i])
   end
end)

async.getAddrInfo({path='google.com', port=80, {socktype='STREAM', addrconfig=true}}, function(results)
   print('')
   print('google.com:')
   for i = 1,math.min(3,#results) do
      print(results[i])
   end
end)

async.go()

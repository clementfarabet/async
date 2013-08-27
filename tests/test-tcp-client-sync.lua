local async = require 'async'

local test = ''
for i = 1,10000 do
   test = test .. 'something\n'
end

local client = async.tcp.connect('tcp://127.0.0.1:8483/', function(client)
   async.fiber(function()
      client.write('test')
      local res = client.read()
      print('received, sync: ', res)

      client.write(test, function(s)
         print('wrote ' .. #test .. ' bytes')
      end)
      
      local read = ''
      while true do
         local res = client.read()
         read = read .. res
         if #read == #test then
            break
         end
      end
      print('read ' .. #read .. ' bytes') 

      print('read==wrote:', read==test)

      client.write('line1\nline2\nsomething long\n')
      for i = 1,3 do
         local line = client.readsplit('\n')
         print('read one line: ' .. line)
      end
      client.write('line1\nline2\nsomething long\n')
      client.write('line1\nline2\nsomething long\n')
      for i = 1,6 do
         local line = client.readsplit('\n')
         print('read one line: ' .. line)
      end

      client.close()
   end)
end)

async.go()

local async = require 'async'

async.json.listen({host='0.0.0.0', port=8483}, function(req,res)
   print('request:',req)
   res({
      msg = 'my answer:',
      attached = 'pretty pretty pretty goooood.'
   })

   collectgarbage()
   print(collectgarbage("count") * 1024)
end)

async.go()

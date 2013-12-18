local async = require 'async'
require('pl.text').format_operator()

async.http.listen('http://0.0.0.0:8082/', function(req,res)
   print('request:',req)

   local resp
   if req.url.path == '/test' then
      resp  = [[
      <p>You requested route /test</p>
      ]]
   else
      -- Produce a random story:
      resp = [[
      <h1>From my server</h1>
      <p>It's working!<p>
      <p>Randomly generated number: ${number}</p>
      <p>A variable in the global scope: ${ret}</p>
      ]] % {
         number = math.random(),
         ret = ret
      }
   end
   
   res(resp, {['Content-Type']='text/html'})
end)

async.go()

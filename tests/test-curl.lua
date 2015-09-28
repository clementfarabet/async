local async = require 'async'

-- simple URL:
async.curl.get('http://www.google.com', function(res)
    print(res)
end)

-- complete API:
async.curl.get({
    host = 'http://blogname.blogspot.com',
    path = '/feeds/posts/default',
    query = {
        alt = 'json'
    },
    format = 'json' -- parses the output: json -> Lua table
}, function(res)
   print(res)
end)

-- Getting an image, and decoding it:
async.curl.get('http://www.webstandards.org/files/acid2/reference.png', function(res)
   async.fs.writeFile('/tmp/test.jpg', res, function()
      async.process.spawn('open', {'/tmp/test.jpg'}, function()
      end)
   end)
end)

-- post has the same API, with a form parameter (instead of query)
--[[
async.curl.post({
    host = 'http://myserver.com',
    path = '/',
    form = {
        username = 'bob',
        password = 'key',
        somefiletoupload = '@test-curl.jpg'
    }
}, function(res)
   print(res)
end)
--]]

async.go()

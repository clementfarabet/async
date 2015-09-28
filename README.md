ASyNC
=====

An async framework for Lua/Torch, based on [LibUV](https://github.com/joyent/libuv)
(using Tim Caswell's [luv](https://github.com/creationix/luv) library).

This lib is heavily inspired on the Node.js architecture. It's fun, elegant, and
should be extremely efficient (a lot of testing is required).

The examples in `tests/` should provide enough documentation on the API.

License
-------

MIT License

Examples
--------

Starting the event loop. At the end of any program, the event loop must be started.
Nothing will be interpreted after this call, as it takes control of the runtime.

```lua
async.go()
```

It's useful to have a REPL (interpreter) running asynchronously, for debugging and
live control of your programs:

```lua
async.repl()  -- fires up an asyncronous repl
```

```lua
async.repl.listen({host='0.0.0.0', port=8080})   -- fires up an async repl through a TCP server
async.repl.connect({host='0.0.0.0', port=8080})  -- connects to a remote repl through a TCP client
```

Common JS like timer controls:
```lua
async.setInterval(millis, function()
   print('printed every N millis')
end)
async.setTimeout(millis, function()
   print('printed once in N millis')
end)
```

CPU Info. Useful to know how many processors are available.
This is a synchronous call.

```lua
print(async.cpuInfo())
```

A TCP server:

```lua
async.tcp.listen({host='0.0.0.0', port=8080}, function(client)
   -- Receive:
   client.ondata(function(chunk)
      -- Data:
      print('received: ' .. chunk)

      -- Reply:
      client.write('thanks!')
   end)

   -- Done:
   client.onend(function()
      print('client gone...')
   end)
end)
```

A TCP client:

```lua
async.tcp.connect({host='127.0.0.1', port=8080}, function(client)
   -- Write something
   client.write('something .. ' .. i)

   -- Callbacks
   client.ondata(function(chunk)
      print('received: ' .. chunk)
      client.close()
   end)

   -- Done:
   client.onend(function()
      print('connection closed...')
   end)
end)
```

File I/O. The low level interface is not complete yet, but the high-level one
is final:

```lua
async.fs.readFile('LICENSE', function(content)
   print(content)
   async.fs.writeFile('LICENSE.copy', content, function(status, err)
      print('==> wrote file: ' .. (status or err))
   end)
end)
```

A lower-level interface is also available, for C-level performance. The upside:
no copy is done, the user callback gets the raw pointer to the network buffer (read)
and writes tap directly into the raw buffer, provided by the user. The downside:
the buffer returned by the "ondata" callback lives only for the scope of that callback,
and must be copied by the user...

```lua
-- assuming a client handle:

local b = require 'buffer'

client.onrawdata(function(chunk)
   -- chunk is a Buffer object (https://github.com/clementfarabet/buffer)
   print(chunk)

   -- chunk will not be valid past this point, so its content must be copied,
   -- not just referenced...
   local safe = chunk:clone()
   -- safe can be past around...

   -- the most common use is to copy that chunk into an existing storage,
   -- for instance a tensor:
   -- (assuming tensor is a torch.Tensor)
   local dst = b(tensor)  -- creates a destination buffer on the tensor (a view, no copy)
   dst:copy(src)
end)

-- write() also accepts buffers:
client.write( b'this is a string saved in a buffer object' )

-- last, the sync() interface can be set up in raw mode:
client.syncraw()
local buffer = client.read()
-- ...
```

We also provide a simple async interface to CURL.

Provides two functions: `get` and `post`.

`get`:

```lua
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
curl.get('http://www.webstandards.org/files/acid2/reference.png', function(res)
  local decoded = require('graphicsmagick').Image():fromString(res)
end)
```

`post`:

```lua
-- post has the same API, with a form parameter (instead of query):
async.curl.post({
    host = 'http://myserver.com',
    path = '/',
    form = {
        username = 'bob',
        password = 'key',
        somefiletoupload = '@/local/path/to/file.jpg'
    }
}, function(res)
   print(res)
end)

-- or a simple file upload:
async.curl.post({
    host = 'http://myserver.com',
    path = '/',
    file = '@/path/to/file.png',
}, function(res)
   print(res)
end)
```


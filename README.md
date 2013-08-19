ASyNC
=====

An async framework for Lua/Torch, based on [LibUV](https://github.com/joyent/libuv)
(using Tim Caswell's [luv](https://github.com/creationix/luv) library).

TODO
----

* async.spawn() : spawn a child process, with control over stdin,out,err
* async.exec() : spawn a child process, just read out stdout in one block, when complete
* async.getAddrInfo() : get addr info (DNS) - requires wrapping `uv_getaddrinfo`
* async.http.listen/connect : http server and client (simple using `http_parser`)

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


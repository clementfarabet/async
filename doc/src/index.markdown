---
title: ASyNC - an asynchronous, libUV-based event-loop for LuaJIT
layout: doc
---

# ASyNC

An async framework for LuaJIT, based on [LibUV](https://github.com/joyent/libuv)
(using Tim Caswell's [luv](https://github.com/creationix/luv) library).

This lib is heavily inspired on the Node.js architecture. It's fun, elegant, and
should be extremely efficient (a lot of testing is required).
It is currently being used in production.

## Documentation

### Starting the event loop

ASyNC is an abstraction over LibUV. It is recommended to read LibUV's documentation
to better understand the concepts of event loop, and asynchronous flow control.
At the heard of LibUV is an event loop, which runs forever, and processes incoming
events. At any point in a Lua program, the event loop can be started like this:

```lua
local async = require 'async'
async.go()
```

Async then takes control of the execution flow, meaning that this function will
only return when there is no more event to process (i.e. when the program is done).
Therefore, all the logic must be declared prior to calling `async.go`.

### Timers
#### async.setInterval/setTimeout

The most basic and useful tool when interacting with event loops is the timer.
Two basic functions are provided to setup one shot or recurrent timers:

```lua
local async = require 'async'

async.setInterval(1000, function(tm)
   print('I am called every second')
end)

async.setTimeout(1000, function(tm)
   print('I am called only once')
end)

async.go()
```

In the example above, the program will never terminate, as there will always be
events to process (the `setInterval` method will re-schedule an event every second,
forever). Timers can be cleared, to interupt the execution. When no event is left
to process, the program terminates. From now we will omit the call to `async.go()`,
which is assumed to be included at the end of each program.

```lua
local tm = async.setInveral(1000, function(tm)
    print('will be printed during 5 seconds')
end)

async.setTimeout(5000, function()
   tm.clear()
end)
```

### REPL (local and remote)
#### async.repl

### Processes
#### async.process

### File System
#### async.fs

### Sockets
#### async.tcp
#### async.http
#### async.json
#### async.getAddrInfo

### Fibers: Synchronous flow control
#### async.fiber

### Utilities
#### async.hrtime
#### async.getTotalMemory
#### async.getFreeMemory
#### async.getCpuInfo

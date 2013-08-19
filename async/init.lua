-- c lib / bindings for libuv
local uv = require 'luv'

-- bindings for lhttp_parser
local newHttpParser = require 'lhttp_parser'.new
local parseUrl = require 'lhttp_parser'.parseUrl

-- make handle out of uv client
local handle = require 'async.handle'

-- TCP server/client:
local tcp = require 'async.tcp'

-- JSON server/client:
local json = require 'async.json'

-- Time routines:
local time = require 'async.time'

-- Repl:
local repl = require 'async.repl'

-- FS:
local fs = require 'async.fs'

-- run loop:
local function go()
   -- start event loop:
   uv.run('once')
end

-- return package:
return {
   tcp = tcp,
   setInterval = time.setInterval,
   setTimeout = time.setTimeout,
   uv = uv,
   go = go,
   cpuInfo = uv.cpuInfo,
   hrtime = uv.hrtime,
   getTotalMemory = uv.get_total_memory,
   getFreeMemory = uv.get_free_memory,
   repl = repl,
   fs = fs,
   json = json,
   parseUrl = parseUrl
}

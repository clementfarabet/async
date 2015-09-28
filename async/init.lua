-- package:
return {
   tcp = require('async.tcp'),
   fiber = require('async.fiber'),
   setInterval = require('async.time').setInterval,
   setTimeout = require('async.time').setTimeout,
   uv = require('luv'),
   cpuInfo = require('luv').cpu_info,
   hrtime = require('luv').hrtime,
   getTotalMemory = require('luv').get_total_memory,
   getFreeMemory = require('luv').get_free_memory,
   getAddrInfo = function(opts,cb)
      require('luv').getaddrinfo(opts.path, opts.port, opts[1], cb)
   end,
   repl = require('async.repl'),
   fs = require('async.fs'),
   json = require('async.json'),
   http = require('async.http'),
   url = require('async.url'),
   curl = require('async.curl'),
   flow = require('async.flow'),
   process = require('async.process'),
   pcall = require('async.pcall'),
   go = function(fn)
      -- Optional function to schedule at every event loop:
      if fn then
         local to = require('async.time').setTimeout
         local function cycle()
            fn()
            to(1,cycle)
         end
         cycle()
      end
      -- Start event loop:
      require('luv').run('default')
   end,
   run = function(fn)
      -- Run code within a fiber:
      require('async.fiber')(fn)
      require('luv').run('default')
   end,
}

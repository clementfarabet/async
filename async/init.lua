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
   process = require('async.process'),
   go = function(fn)
      if fn then
         local to = require('async.time').setTimeout
         local function cycle()
            fn()
            to(1,cycle)
         end
         cycle()
      end
      require('luv').run('default')
   end,
}

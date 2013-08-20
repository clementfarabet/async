-- package:
return {
   tcp = require('async.tcp'),
   setInterval = require('async.time').setInterval,
   setTimeout = require('async.time').setTimeout,
   uv = require('luv'),
   go = function()
      require('luv').run('default')
   end,
   cpuInfo = require('luv').cpuInfo,
   hrtime = require('luv').hrtime,
   getTotalMemory = require('luv').get_total_memory,
   getFreeMemory = require('luv').get_free_memory,
   repl = require('async.repl'),
   fs = require('async.fs'),
   json = require('async.json'),
   http = require('async.http'),
   process = require('async.process')
}

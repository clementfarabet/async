local async = require 'async'

async.repl()

i = 1
async.go(function()
   print('do something in a loop: ' .. i .. ' (try typing: i = 1e6)')
   i = i + 1
end)

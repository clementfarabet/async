local async = require 'async'

local urls = {}
for i = 1,1e5 do
   urls[i] = 'https://developers.google.com/earth/documentation/images/groundoverlay_example.gif'
end

-- simple URL:
async.run(function()
   local res = async.curl.getn(urls, {max = 16}, function(res)
      print(collectgarbage('count')*1024)
      collectgarbage()
   end)
end)

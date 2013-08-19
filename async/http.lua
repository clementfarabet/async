-- c lib / bindings for libuv
local uv = require 'luv'

-- tcp
local tcp = require 'async.tcp'

-- bindings for lhttp_parser
local newHttpParser = require 'lhttp_parser'.new
local parseUrl = require 'lhttp_parser'.parseUrl

-- HTTP server/client
local http = {}

function http.listen(domain, cb)
   tcp.listen(domain, function(client)
   end)
end

function http.connect(domain, cb)
   tcp.connect(domain, function(client)
   end)
end

http.parseUrl = parseUrl

-- return
return http

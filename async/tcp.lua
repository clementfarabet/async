-- c lib / bindings for libuv
local uv = require 'luv'

-- handle
local handle = require 'async.handle'

-- TCP server/client:
local tcp = {}

-- protocols:
tcp.protocols = {
   http = 80,
   https = 443,
}

-- url parser:
tcp.parseUrl = function(url, cb)
   if type(url) == 'string' then
      local parseUrl = require 'lhttp_parser'.parseUrl
      local parsed = parseUrl(url)
      parsed.port = parsed.port or http.protocols[parsed.schema]
      url = parsed
   end
   local isip = url.host:find('^%d*%.%d*%.%d*%.%d*$')
   if not isip then
      uv.getaddrinfo(url.host, url.port, nil, function(res)
         url.host = (res[1] and res[1].addr) or error('could not resolve address: ' .. url.host)
         cb(url)
      end)
   else
      cb(url)
   end
end

function tcp.listen(domain, cb)
   local server = uv.new_tcp()
   tcp.parseUrl(domain, function(domain)
      local host = domain.host
      local port = domain.port
      uv.tcp_bind(server, host, port)
      function server:onconnection()
         local client = uv.new_tcp()
         uv.accept(server, client)
         local h = handle(client)
         h.sockname = uv.tcp_getsockname(client)
         h.peername = uv.tcp_getpeername(client)
         cb(h)
      end
      uv.listen(server)
   end)
   return handle(server)
end

function tcp.connect(domain, cb)
   local client = uv.new_tcp()
   local h = handle(client)
   tcp.parseUrl(domain, function(domain)
      local host = domain.host
      local port = domain.port
      uv.tcp_connect(client, host, port, function()
         h.sockname = uv.tcp_getsockname(client)
         h.peername = uv.tcp_getpeername(client)
         cb(h)
      end)
   end)
   return h
end

-- TCP lib
return tcp

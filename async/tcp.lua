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
tcp.parseUrl = function(url)
   local parseUrl = require 'lhttp_parser'.parseUrl
   if type(url) == 'table' then
      return url
   else
      local parsed = parseUrl(url)
      parsed.port = parsed.port or http.protocols[parsed.schema]
      return parsed
   end
end

function tcp.listen(domain, cb)
   domain = tcp.parseUrl(domain)
   local host = domain.host
   local port = domain.port
   local server = uv.new_tcp()
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
   return handle(server)
end

function tcp.connect(domain, cb)
   domain = tcp.parseUrl(domain)
   local host = domain.host
   local port = domain.port
   local client = uv.new_tcp()
   local h = handle(client)
   uv.tcp_connect(client, host, port, function()
      h.sockname = uv.tcp_getsockname(client)
      h.peername = uv.tcp_getpeername(client)
      cb(h)
   end)
   return h
end

-- TCP lib
return tcp

-- c lib / bindings for libuv
local uv = require 'luv'

-- tcp
local tcp = require 'async.tcp'
local json = require 'cjson'

-- bindings for lhttp_parser
local newHttpParser = require 'lhttp_parser'.new
local parseUrl = require 'lhttp_parser'.parseUrl

-- HTTP server/client
local http = {}

-- Status codes:
http.codes = {
   [100] = 'Continue',
   [101] = 'Switching Protocols',
   [102] = 'Processing',                 -- RFC 2518, obsoleted by RFC 4918
   [200] = 'OK',
   [201] = 'Created',
   [202] = 'Accepted',
   [203] = 'Non-Authoritative Information',
   [204] = 'No Content',
   [205] = 'Reset Content',
   [206] = 'Partial Content',
   [207] = 'Multi-Status',               -- RFC 4918
   [300] = 'Multiple Choices',
   [301] = 'Moved Permanently',
   [302] = 'Moved Temporarily',
   [303] = 'See Other',
   [304] = 'Not Modified',
   [305] = 'Use Proxy',
   [307] = 'Temporary Redirect',
   [400] = 'Bad Request',
   [401] = 'Unauthorized',
   [402] = 'Payment Required',
   [403] = 'Forbidden',
   [404] = 'Not Found',
   [405] = 'Method Not Allowed',
   [406] = 'Not Acceptable',
   [407] = 'Proxy Authentication Required',
   [408] = 'Request Time-out',
   [409] = 'Conflict',
   [410] = 'Gone',
   [411] = 'Length Required',
   [412] = 'Precondition Failed',
   [413] = 'Request Entity Too Large',
   [414] = 'Request-URI Too Large',
   [415] = 'Unsupported Media Type',
   [416] = 'Requested Range Not Satisfiable',
   [417] = 'Expectation Failed',
   [418] = 'I\'m a teapot',              -- RFC 2324
   [422] = 'Unprocessable Entity',       -- RFC 4918
   [423] = 'Locked',                     -- RFC 4918
   [424] = 'Failed Dependency',          -- RFC 4918
   [425] = 'Unordered Collection',       -- RFC 4918
   [426] = 'Upgrade Required',           -- RFC 2817
   [500] = 'Internal Server Error',
   [501] = 'Not Implemented',
   [502] = 'Bad Gateway',
   [503] = 'Service Unavailable',
   [504] = 'Gateway Time-out',
   [505] = 'HTTP Version not supported',
   [506] = 'Variant Also Negotiates',    -- RFC 2295
   [507] = 'Insufficient Storage',       -- RFC 4918
   [509] = 'Bandwidth Limit Exceeded',
   [510] = 'Not Extended'                -- RFC 2774
}

function http.listen(domain, handler)
   tcp.listen(domain, function(client)
      -- Http Request Parser:
      local currentField, headers, lurl, request, parser, keepAlive, body
      body = {}
      parser = newHttpParser("request", {
         onMessageBegin = function ()
            headers = {}
         end,
         onUrl = function (value)
            lurl = parseUrl(value)
         end,
         onHeaderField = function (field)
            currentField = field
         end,
         onHeaderValue = function (value)
            headers[currentField:lower()] = value
         end,
         onHeadersComplete = function (info)
            request = info
         end,
         onBody = function (chunk)
            table.insert(body, chunk)
         end,
         onMessageComplete = function ()
	    request.body = table.concat(body)
            request.url = lurl
            request.headers = headers
            request.parser = parser
            request.socket = request.socket
            keepAlive = request.should_keep_alive
	    
	    if request.method == 'POST' and request.headers['content-type'] == "application/json" then
	       local ok, j = pcall(json.decode, request.body)
	       if ok then request.body = j end
	    end

            -- headers ready? -> call user handler
            handler(request, function(body,headers,statusCode)
               -- Code:
               local statusCode = statusCode or 200
               local reasonPhrase = http.codes[statusCode]
               
               -- Body length:
               if type(body) == "table" then
                  body = table.concat(body)
               end
               local length = #body

               -- Header:
               local head = {
                  string.format("HTTP/1.1 %s %s\r\n", statusCode, reasonPhrase)
               }
               headers = headers or {['Content-Type']='text/plain'}
               headers['Date'] = os.date("!%a, %d %b %Y %H:%M:%S GMT")
               headers['Server'] = 'ASyNC'
               headers['Content-Length']=length
               --headers["Connection"] = "close"
               for key, value in pairs(headers) do
                  if type(key) == "number" then
                     table.insert(head, value)
                     table.insert(head, "\r\n")
                  else
                     table.insert(head, string.format("%s: %s\r\n", key, value))
                  end
               end

               -- Write:
               table.insert(head, "\r\n")
               table.insert(head, body)
               client.write(table.concat(head))

               -- Keep alive?
               if keepAlive then
                  parser:reinitialize('request')

                  -- TODO: not sure how to handle keep alive sessions, closing for now
                  parser:finish()
                  client.close()
               else
                  parser:finish()
                  client.close()
               end
            end)
         end
      })

      -- Pipe data into parser:
      client.ondata(function(chunk)
         -- parse chunk:
         parser:execute(chunk,0,#chunk)
      end)
   end)
end

function http.connect(domain, cb)
   tcp.connect(domain, function(client)
   end)
end

-- return
return http

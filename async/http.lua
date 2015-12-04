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

            if request.should_keep_alive then
               -- For a persistent connection, all messages must have
               -- a self-defined length (not one defined by closure of
               -- the connection)
               headers['Content-Length']=#body -- TODO: luvit uses #chunk but not sure where chunk is defined

               if info.version_minor < 1 then -- HTTP/1.0: insert Connection: keep-alive
                  headers['connection']='keep-alive'
               end
            else
               if info.version_minor >= 1 then -- HTTP/1.1+: insert Connection: close for last msg
                  headers['connection']='close'
               end
            end
         end,
         onBody = function (chunk)
            table.insert(body, chunk)
         end,
         onMessageComplete = function ()
            request.body = table.concat(body)
            request.url = lurl
            request.headers = headers
            request.parser = parser
            keepAlive = request.should_keep_alive

            -- Flush the body when complete
            body = {}

            -- Parse body:
            -- TODO: these decoders should be abstracted in a separate file/func, and done as chunks come in
            if request.method == 'POST' and request.headers['content-type']
	    and request.headers['content-type']:find("^multipart%/form%-data") then
               -- Multipart form, decode:
               local _,_,boundary = request.headers['content-type']:find("^multipart%/form%-data%; boundary%=(.*)")
               local elts = stringx.split(request.body, boundary)
               request.body = {}
               for i = 2,#elts-1 do
                  -- Parse content disposition:
                  local _,_,type,data = elts[i]:find('..Content%-Disposition%:%s*(.-)%;%s*(.*)\r\n%-%-$')

                  -- Parse form data
                  if type == 'form-data' then
                     local _,last,name,fname = data:find('name="(.-)"(.-)\r\n')
                     local _,_,filename = fname:find('filename="(.-)"$')
                     data = data:sub(last+1,#data)
                     local _,last,contentType = data:find('^Content%-Type:%s*(.-)\r\n')
                     if contentType then
                        data = data:sub(last+1,#data)
                     end
                     data = data:sub(3,#data)
                     request.body[name] = {
                        data = data,
                        filename = filename,
                        ['content-type'] = contentType,
                     }
                  else
                     table.insert(request.body, {
                        type = type,
                        data = data,
                     })
                  end
               end
            elseif request.method == 'POST'
	    and request.headers['content-type'] == "application/json" then
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
	       if not (headers['Transfer-Encoding']
		       and headers['Transfer-Encoding'] == 'chunked') then
		  headers['Content-Length'] = length
	       end

               for key, value in pairs(headers) do
                  if type(key) == "number" then
                     table.insert(head, value)
                     table.insert(head, "\r\n")
                  else
                     local entry = string.format("%s: %s\r\n", key, value)
                     table.insert(head, entry)
                  end
               end

               -- Write:
               table.insert(head, "\r\n")
               table.insert(head, body)
               client.write(table.concat(head))

               -- Keep alive?
               if keepAlive then
                  parser:reinitialize('request')

                  --[[ Rather than close a keep-alive connection, we leave the
		     socket open to maintain the persistent connection.
		     The client (browser) will time out after inactivity
		     (http://www.w3.org/Protocols/rfc2616/rfc2616-sec8.html)
		     To test that sockets are closed after the timeout,
		     compare the output of this command:
		     lsof -n | grep -i "luajit" | grep "http-alt" [optional: | grep -c "ESTABLISHED" for count]
		  ]]--
                  parser:finish()
               else
                  parser:finish()
                  client.close()
               end
            end, client) -- give the raw client socket as the last argument
         end
      })

      -- Pipe data into parser:
      client.ondata(function(chunk)
         -- parse chunk:
         if #chunk > 0 then
             parser:execute(chunk,0,#chunk)
         end
      end)
   end)
end

function http.connect(domain, cb)
   tcp.connect(domain, function(client)
   end)
end

-- return
return http

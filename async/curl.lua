-- Libs
local json = require 'cjson'
local escape = require 'async.url'.escape

-- curl interface
local curl = {}

-- Format options:
local function formatUrl(url,options)
   -- Format query:
   local query
   if options and next(options) then
      query = {}
      for k,v in pairs(options) do
         v = tostring(v)
         table.insert(query, escape(k) .. '=' .. escape(v))
      end
      query = table.concat(query,'&')
   end

   -- Create full URL:
   if query then url = url .. '?' .. query end
   return url
end

-- Format form:
local function formatForm(options)
   -- Format form:
   local form = {}
   if options and next(options) then
      for k,v in pairs(options) do
         v = tostring(v)
         table.insert(form, '-F')
         table.insert(form,  k .. '=' .. v )
      end
   end
   return form
end

-- Parse HTTP header for resumeId:
local function getResumeId(httpResponse)
   local pattern = "location: .*%?resumable=true&resumeId=(%d+)"
   return tonumber(httpResponse:match(pattern))
end

-- Parse HTTP header for HTTP status code:
local function getStatusCode(httpResponse)
   local pattern = 'HTTP%/%d%.%d%s+(%d+)%s+.*'
   local _, _, code = httpResponse:find(pattern)
   return tonumber(code)
end

-- deps
local process = require 'async.process'
local fiber = require 'async.fiber'
local sync = require 'async.fiber'.sync

-- GET
curl.get = function(args, callback)
   -- URL:
   if type(args) == 'string' then
      args = {
         url = args
      }
   end
   local url = args.url or (args.host .. (args.path or '/'))
   local query = args.query
   local format = args.format or 'raw' -- or 'json'
   local cookie = (args.cookie and ('-b ' .. args.cookie))
   local auth = args.auth
   local verbose = args.verbose
   local maxTime = args.maxTime
   local maxConnectTime = args.maxConnectTime
   local retry = args.retry
   local headers = args.headers or {}
   local method = args.method

   -- Build args:
   local cargs = {'-sk', '-w', '\n%{http_code}'}

   if method then
      table.insert(cargs, '-X')
      table.insert(cargs, method)
   end

   -- Basic auth
   if auth then
      table.insert(cargs, '--user')
      table.insert(cargs, auth.user .. ':' .. auth.password)
   end

   -- Cookie
   if cookie then
      table.insert(cargs, cookie)
   end

   -- Headers
   if headers then
      for key,val in pairs(headers) do
         table.insert(cargs, '--header')
         table.insert(cargs, key..':'..val)
      end
   end

   -- Max time for query
   if maxTime then
      table.insert(cargs, '--max-time')
      table.insert(cargs, maxTime)
   end

   -- Max time for connection
   if maxConnectTime then
      table.insert(cargs, '--connect-timeout')
      table.insert(cargs, maxConnectTime)
   end

   -- Retry?
   if retry then
      table.insert(cargs, '--retry')
      table.insert(cargs, retry)
   end

   -- Format URL:
   table.insert(cargs, formatUrl(url,query))

   -- GET:
   if verbose then print('curl ' .. table.concat(cargs,' '):gsub('\n','%n')) end
   process.exec('curl', cargs, function(res)
      -- Split code from response
      local _,_,res,code = res:find('(.*)\n(%d*)$')
      code = tonumber(code)

      -- Format?
      local ok
      if format == 'json' then
         ok,res = pcall(function() return json.decode(res) end)
         if not ok then return nil,res end
      end

      -- Response
      if callback then
         callback(res,code)
      end
   end)
end

-- curl alias for DELETE
curl.delete = function(args, callback)
   args.method = "DELETE"
   curl.get(args, callback)
end

-- curl alias for PUT
curl.put = function(args, callback)
   args.method = "PUT"
   curl.get(args, callback)
end

-- GET N in //
curl.getn = function(urls, opts, callback)
   -- max in //
   local max = opts.max or 32 opts.max = nil

   -- fetch:
   local fetch = {}
   for i,url in ipairs(urls) do
      fetch[i] = function(cb)
         local args
         if type(url) == 'string' then
            args = {
               url = url
            }
         else
            args = url
         end
         for k,v in pairs(opts) do
            args[k] = v
         end
         curl.get(args, function(res)
            callback(res, url)
            cb(res, url)
            fetch[i] = nil
         end)
      end
   end
   fiber(function()
      fiber.wait(fetch, nil, max)
   end)
end

-- POST
curl.post = function(args, callback)
   -- URL:
   local url = args.url or (args.host .. (args.path or '/'))
   local format = args.format or 'raw' -- or 'json'
   local cookie = (args.cookie and ('-b ' .. args.cookie))
   local saveCookie = (args.saveCookie and ('-c ' .. args.saveCookie))
   local headers = args.headers or {}
   local auth = args.auth
   local query = args.query
   local verbose = args.verbose
   local form = args.form
   local file = args.file
   local retry = args.retry
   local raw = args.raw
   local jsonpost = args.json
   local output = args.output or 'code'

   -- Build args:
   local cargs = {'-sk', '--request', 'POST'}

   -- output full headers?
   if output == 'full' then
      table.insert(cargs, '-i')
   else
      table.insert(cargs, '-w')
      table.insert(cargs, '\n%{http_code}')
   end

   -- Basic auth
   if auth then
      table.insert(cargs, '--user ' .. auth.user .. ':' .. auth.password)
   end

   -- Cookies
   if saveCookie then
      table.insert(cargs, saveCookie)
   end
   if cookie then
      table.insert(cargs, cookie)
   end

   -- Headers
   for key,val in pairs(headers) do
      table.insert(cargs, '--header')
      table.insert(cargs, key..':'..val)
   end

   -- Retry?
   if retry then
      table.insert(cargs, '--retry')
      table.insert(cargs, retry)
   end

   -- URL:

   -- Format URL:
   table.insert(cargs, formatUrl(url,query))

   -- Format data:
   if form then
      data = formatForm(form)
      for i,val in ipairs(data) do
         table.insert(cargs, val)
      end
   elseif file then
      table.insert(cargs, '--data-binary')
      table.insert(cargs, '@'..file)
   elseif raw then
      table.insert(cargs, '--data-binary')
      table.insert(cargs, '@-')
   elseif jsonpost then
      raw = json.encode(jsonpost)
      table.insert(cargs, '--data-binary')
      table.insert(cargs, '@-')
      table.insert(cargs, '--header')
      table.insert(cargs, 'content-type'..':'..'application/json')
   end

   -- GET:
   if verbose then print('curl ' .. table.concat(cargs,' '):gsub('\n','%n')) end

   if raw then
      -- have to write it to stdin, otherwise it'll try to put it in the url
      process.spawn('curl', cargs, function(handle)
         local result = {}
         local httpcode
         local term = false
         handle.stdout.ondata(function(chunk)
            table.insert(result,chunk)
         end)
         handle.stdout.onend(function()
            result = table.concat(result)
            local _,_,res,code = result:find('(.*)\n(%d*)$')
            httpcode = tonumber(code)

            if term then
               -- Format?
               local ok
               if format == 'json' then
                  ok,res = pcall(function() return json.decode(res) end)
                  if not ok then res = nil end
               end
               callback(res, httpcode)
            end
         end)
         handle.onexit(function(code,signal)
            if type(result) == 'string' then
               local _,_,res,code = result:find('(.*)\n(%d*)$')
               httpcode = tonumber(code)
               local ok
               if format == 'json' then
                  ok,res = pcall(function() return json.decode(res) end)
                  if not ok then res = nil end
               end
               callback(res,httpcode)
            else
               term = {code,signal}
            end
         end)

         if data then
            handle.stdin.write(raw)
            handle.stdin.close()
         end
      end)
   else
      process.exec('curl', cargs, function(res)
         -- Split code from response
         local _,_,res,code = res:find('(.*)\n(%d*)$')
         code = tonumber(code)

         -- Format?
         local ok
         if format == 'json' then
            ok,res = pcall(function() return json.decode(res) end)
            if not ok then res = nil end
         end

         -- Response
         if callback then
            callback(res,code)
         end
      end)
   end
end

-- POST N in //
curl.postn = function(urls, opts, callback)
   -- max in //
   local max = opts.max or 32 opts.max = nil

   -- fetch:
   local fetch = {}
   for i,url in ipairs(urls) do
      fetch[i] = function(cb)
         local args
         if type(url) == 'string' then
            args = {
               url = url
            }
         else
            args = url
         end
         for k,v in pairs(opts) do
            args[k] = v
         end
         curl.post(args, function(res)
            callback(res, url)
            cb(res, url)
            fetch[i] = nil
         end)
      end
   end
   fiber(function()
      fiber.wait(fetch, nil, max)
   end)
end

-- POST large file
curl.postLargeFile = function(args, callback)
   fiber(function()
      -- Packages
      local color = require 'trepl.colorize'
      local sync = require 'async.fiber'.sync
      local httpCodes = require 'async.http'.codes

      -- Args:
      local filename = args.filename
      local url = args.url or (args.host .. (args.path or '/'))
      local verbose = args.verbose

      -- Load file:
      local f = assert(io.open(filename))
      local fileSize = sync.stat(filename).size

      -- Content options:
      local contentType = 'application/octet-stream'
      local chunkSize = args.chunkSize or 8388608 * 4 -- min chunk size * 4
      local totalChunks = math.floor(fileSize / chunkSize)
      local remainderSize = fileSize % chunkSize

      -- POST initial query:
      if verbose then print(color.red('1. Initialization for ' .. filename)) end

      local headers = {}
      headers['Content-Type'] = contentType
      headers['X-TON-Content-Type'] = contentType
      headers['X-TON-Content-Length'] = fileSize

      local httpResponse = sync.post({
         url = url,
         query = {
            resumable = true
         },
         headers = headers,
         output = 'full'
      })

      -- HTTP status code?
      local code = getStatusCode(httpResponse)
      if code ~= 200 then
         callback(nil, httpCodes[code])
         return
      end

      -- resumeId
      local resumeId = getResumeId(httpResponse)
      if verbose then print(color.cyan('Resume upload accepted with id = ' .. resumeId)) end

      -- Build chunks
      if verbose then print(color.red('2. Build chunks')) end
      local chunks = {}
      local lastOffset = -1

      for i=0, totalChunks, 1 do
         -- default
         local endOff = lastOffset + chunkSize
         local size = chunkSize

         -- last chunk?
         if endOff > fileSize then
            endOff = lastOffset + remainderSize
            size = remainderSize
         end

         local c = {
            index = i + 1,
            startOff = lastOffset + 1,
            endOff = endOff,
            size = size
         }

         table.insert(chunks, c)

         -- update offset
         lastOffset = c.endOff
      end

      if verbose then print(color.cyan(#chunks .. ' chunks ready for upload')) end

      -- Upload chunks
      if verbose then print(color.red('3. Upload')) end

      local headers = {}
      headers['Content-Type'] = contentType

      for i=1, #chunks, 1 do
         -- Chunk info
         local c = chunks[i]

         -- Read chunk
         local raw_chunk = f:read(c.size)

         headers['Content-Length'] = c.size
         headers['Content-Range'] = 'bytes ' .. c.startOff .. '-' .. c.endOff .. '/' .. fileSize

         if verbose then print(color.cyan('Posting chunk ' .. c.index .. '/' .. #chunks)) end

         local res, code = sync.post({
            url = url,
            query = {
               resumable = true,
               resumeId = resumeId
            },
            headers = headers,
            format = 'raw',
            raw = raw_chunk
         })

         if code == 201 then
            callback(true)
         elseif code ~= 308 then
            callback(nil, httpCodes[code]) -- error
            return
         end
      end

      f:close()
   end)
end

-- return curl:
return curl

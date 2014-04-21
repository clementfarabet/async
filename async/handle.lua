-- c lib / bindings for libuv
local uv = require 'luv'

-- we need penlight for a few convenience functions
require 'pl'

-- use fibers for sync reads
local fiber = require 'async.fiber'

-- make handle out of uv client
local function handle(client)
   -- handle wraper:
   local h = {}

   -- default callbacks:
   client.onend = function()
      if h.reading then
         uv.read_stop(client)
         uv.close(client)
      end
   end
   client.onerr = function()
      if h.reading then uv.read_stop(client) end
      uv.close(client)
   end

   -- common read/write abstractions:
   h.reading = false
   h.ondata = function(cb)
      client.ondata = function(self,data)
         if cb then cb(data) end
      end
      uv.read_start(client)
      h.reading = true
   end
   h.onerr = function(cb)
      client.onerr = function(self,code)
         if cb then cb(code) end
         if h.reading then uv.read_stop(client) end
         uv.close(client)
      end
   end
   h.onend = function(cb)
      client.onend = function(self)
         if cb then cb() end
         if h.reading then
            uv.read_stop(client)
            uv.close(client)
         end
      end
   end
   h.onclose = function(cb)
      client.onclose = function(self)
         if cb then cb() end
      end
   end
   h.write = function(data,cb)
      uv.write(client, data, cb)
   end
   h.close = function(cb)
      uv.shutdown(client, function()
         if h.reading then uv.read_stop(client); end
         uv.close(client)
         if cb then cb() end
      end)
   end

   -- default error handler
   client.onerr = function(self, code)
      print('error on client - code: ' .. code)
      if h.reading then uv.read_stop(client); end
      uv.close(client)
   end

   -- convenience function to split a stream,
   -- and call a callback each time a full split is found
   h.onsplitdata = function(split,cb)
      local splitter
      if type(split) == 'function' then
         splitter = function(chunk)
            local chunks,leftover = split(chunk)
            if leftover then
               table.insert(chunks,leftover)
            end
            return chunks
         end
      else
         splitter = function(chunk)
            local chunks = stringx.split(chunk,split)
            return chunks
         end
      end
      local fullpacket = {}
      h.ondata(function(chunk)
         table.insert(fullpacket, chunk)
         chunk = table.concat(fullpacket)
         fullpacket = {}

         local chunks = splitter(chunk)
         for i,chunk in ipairs(chunks) do
            table.insert(fullpacket,chunk)
            if i < #chunks then
               local req = table.concat(fullpacket)
               fullpacket = {}
               cb(req)
            end
         end
      end)
   end

   -- activate sync read (must be used within fiber)
   h.sync = function()
      -- local buffers:
      local fibers = {}
      local data = {}

      -- capture all data:
      h.ondata(function(d)
         local cfibers = fibers
         fibers = {}
         for f in pairs(cfibers) do
            data[f] = d
            f.resume()
         end
      end)

      -- synchronous read:
      h.read = function()
         -- get coroutine:
         local f = fiber.context()
         if not f then
            print('read() can only be used within a fiber(function() client.read() end) context')
            return nil
         end
         fibers[f] = true

         -- yield
         f.yield()

         -- coroutine has been resumed, data is available
         local d = data[f]
         data[f] = nil
         return d
      end

      -- synchronous readsplit:
      -- TODO: this function seems to be 100% correct, but given the way
      -- it's constructed, it implies that the user really knows what he's doing:
      -- if readsplit(split) is called with the same split symbol over and over,
      -- then it will be ok all the time. If the split symbol changes, results will
      -- be unpredictable, because of the buffering.
      local lines = {}
      local buffer = {}
      h.readsplit = function(split)
         -- get coroutine:
         local f = fiber.context()
         if not f then
            print('read() can only be used within a fiber(function() client.read() end) context')
            return nil
         end
         lines[f] = lines[f] or {}
         buffer[f] = buffer[f] or {}

         -- lines cached?
         if #lines[f] > 0 then
            local line = lines[f][1]
            lines[f] = tablex.sub(lines[f],2,#lines[f])
            return line
         end
     
         -- splitter function:
         local splitter
         if type(split) == 'function' then
            splitter = function(chunk)
               local chunks,leftover = split(chunk)
               if leftover then
                  table.insert(chunks,leftover)
               end
               return chunks
            end
         else
            splitter = function(chunk)
               local chunks = stringx.split(chunk,split)
               return chunks
            end
         end

         -- grab next lines:
         while true do
            local res = h.read()
            local chunks = splitter(res)
            for i,chunk in ipairs(chunks) do
               if chunk == "" then
                  -- stringx.split returns "" as placeholders for the splits
                  table.insert(buffer[f],chunk)
                  local line = table.concat(buffer[f])
                  table.insert(lines[f],line)
                  buffer[f] = {}
               elseif i == #chunks then
                  -- last chunk : assume split not reached afterwors
                  table.insert(buffer[f],chunk)
               elseif i == 1 then
                  -- first but not last chunk : split reached
                  table.insert(buffer[f],chunk)
                  local line = table.concat(buffer[f])
                  table.insert(lines[f],line)
                  buffer[f] = {}
               else
                  table.insert(lines[f],chunk)
               end
            end
            break
         end

         -- GC:
         for f in pairs(lines) do
            if not fiber.fibers[f.co] then
               lines[f] = nil
               buffer[f] = nil
            end
         end

         -- lines are buffered, return some:
         return h.readsplit(split)
      end

      -- shortcut
      h.readline = function()
         return h.readsplit('\n')
      end
   end

   return h
end

-- handle
return handle

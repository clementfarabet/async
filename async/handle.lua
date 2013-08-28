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

   -- common read/write abstractions:
   h.ondata = function(cb)
      client.ondata = function(self,data)
         if cb then cb(data) end
      end
      uv.read_start(client)
   end
   h.onend = function(cb)
      client.onend = function(self)
         if cb then cb() end
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
         uv.close(client)
         if cb then cb() end
      end)
   end

   -- convenience function to split a stream,
   -- and call a callback each time a full split is found
   h.onsplitdata = function(limit,cb)
      local fullpacket = {}
      h.ondata(function(chunk)
         local chunks = stringx.split(chunk,limit)
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

         -- grab next lines:
         while true do
            local res = h.read()
            local chunks = stringx.split(res,split)
            for i,chunk in ipairs(chunks) do
               if i == #chunks then
                  table.insert(buffer[f],chunk)
               elseif i == 1 then
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

-- c lib / bindings for libuv
local uv = require 'luv'

-- we need penlight for a few convenience functions
require 'pl'

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

   -- provide a synchronous read:
   h.read = function()
      -- get coroutine:
      local co = coroutine.running()
      if not co then
         print('read() can only be used within a fiber(function() client.read() end) context')
         return nil
      end

      -- read data, and resume coroutine once done
      local data
      h.ondata(function(d)
         data = d
         client.ondata = nil
         coroutine.resume(co)
      end)

      -- yield...
      coroutine.yield()

      -- coroutine has been resumed, data is available
      return data
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
      split = split or '\n'
      if #lines > 0 then
         local line = lines[1]
         lines = tablex.sub(lines,2,#lines)
         return line
      end
      while true do
         local res = h.read()
         local chunks = stringx.split(res,split)
         for i,chunk in ipairs(chunks) do
            if i == 0 then
               table.insert(buffer,chunk)
               local line = table.concat(buffer)
               table.insert(lines,line)
               buffer = {}
            elseif i < #chunks then
               table.insert(lines,chunk)
            else
               table.insert(buffer,chunk)
            end
         end
         break
      end
      return h.readsplit(split)
   end

   return h
end

-- handle
return handle

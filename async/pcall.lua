local setpcall = function(cb, handler)
   local framelocation = debug.traceback()
   local debuginfo = {}
   local i = 2

   while debug.getinfo(i) ~= nil do
      table.insert(debuginfo, debug.getinfo(i))
      i = i + 1
   end

   return function(...)
      local args = {...}

      xpcall(function() cb(unpack(args)) end, function()

         local currenttraceback = debug.traceback()
         if handler then
            handler(currenttraceback, framelocation, debuginfo)
         else
            print(currenttraceback .. "\n----------------------------------------\n" .. framelocation)
         end

      end)
   end
end

return setpcall

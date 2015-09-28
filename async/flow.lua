local setTimeout = require('async.time').setTimeout

local flow = {}

flow.ratelimiter = function(persecond)
   local func_list = {}
   local arg_list = {}
   local currently_running = 0
   local waiting = false
   local rate = 1000 / (persecond or 100)

   local exec_next
   exec_next = function()
      if #func_list > 0 then
         waiting = true
         if currently_running < persecond then
            local func = func_list[1]
            local args = arg_list[1]

            table.remove(func_list, 1)
            table.remove(arg_list, 1)

            currently_running = currently_running + 1

            -- if the function has a callback, wrap that callback with our currently_running counter decrement
            if type(args[#args]) == "function" then
               local cb = args[#args]
               args[#args] = function(...)
                  currently_running = currently_running - 1
                  cb(...)
               end
            else
               table.insert(args,  function()
                  currently_running = currently_running - 1
               end)
            end

            func(unpack(args))
         end
         setTimeout(rate, exec_next)
      else
         waiting = false
      end
   end

   return function(func, args)
      table.insert(func_list, func)
      table.insert(arg_list, args)
      if waiting == false then
         exec_next()
      end
   end
end

return flow

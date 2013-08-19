-- c lib / bindings for libuv
local uv = require 'luv'

-- FS
local fs = {
   bufferSize = 1024
}

function fs.open(path, flags, mode, callback)
   mode = tonumber(mode or "666", 8)
   uv.fs_open(path, flags, mode, function(err,fd)
      callback(fd,err)
   end)
end

function fs.close(fd, callback)
   uv.fs_close(fd, function(err)
      callback(err)
   end)
end

function fs.stat(path, callback)
   uv.fs_stat(path, function(err,stats)
      callback(stats,err)
   end)
end

function fs.fstat(fd, callback)
   uv.fs_fstat(fd, function(err,stats)
      callback(stats,err)
   end)
end

function fs.lstat(path, callback)
   uv.fs_lstat(path, function(err,stats)
      callback(stats,err)
   end)
end

function fs.read(fd, length, offset, callback)
   uv.fs_read(fd, length, offset, function(err,data)
      callback(data,err)
   end)
end

function fs.readFile(path, callback)
   fs.open(path, 'r', '666', function(fd)
      local length = fs.bufferSize
      local offset = 0
      local buffer = {}
      local function read()
         fs.read(fd, length, offset, function(data,err)
            table.insert(buffer,data)
            if #data == length then
               offset = offset + length
               read()
            else
               buffer = table.concat(buffer)
               callback(buffer)
               fs.close(fd)
            end
         end)
      end
      read()
   end)
end

function fs.write(fd, data, callback)
   uv.fs_write(fd, data, 0, function(err)
      callback(err)
   end)
end

function fs.writeFile(path, data, callback)
   -- TODO: implement chunked version using fs.bufferSize
   -- (to avoid stalling the event loop for too long)
   fs.open(path, 'w', '666', function(fd)
      fs.write(fd, data, function(err)
         callback(err)
         fs.close(fd)
      end)
   end)
end

-- return
return fs

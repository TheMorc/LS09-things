Files = {}
local Files_mt = Class(Files)
function Files:new(path)
  local instance = {}
  setmetatable(instance, Files_mt)
  instance.files = {}
  getFiles(path, "fileCallbackFunction", instance)
  return instance
end
function Files:fileCallbackFunction(filename, isDirectory)
  local file = {}
  file.filename = filename
  file.isDirectory = isDirectory
  table.insert(self.files, file)
end

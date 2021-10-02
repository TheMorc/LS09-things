SpecializationUtil = {}
SpecializationUtil.specializations = {}
function SpecializationUtil.callSpecializationsFunction(func)
  return function(self, ...)
    for k, v in pairs(self.specializations) do
      local f = v[func]
      if f ~= nil then
        f(self, ...)
      end
    end
  end
end
function SpecializationUtil.registerSpecialization(name, className, filename, customEnvironment)
  local entry = {}
  entry.name = name
  entry.className = className
  entry.filename = filename
  source(filename, customEnvironment)
  SpecializationUtil.specializations[name] = entry
end
function SpecializationUtil.getSpecialization(name)
  local entry = SpecializationUtil.specializations[name]
  if entry == nil then
    return nil
  end
  local callString = "g_asd_tempSpec = " .. entry.className
  loadstring(callString)()
  local returnValue = g_asd_tempSpec
  g_asd_tempSpec = nil
  return returnValue
end
function SpecializationUtil.hasSpecialization(spec, specializations)
  for k, v in pairs(specializations) do
    if v == spec then
      return true
    end
  end
  return false
end

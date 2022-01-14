VehicleTypeUtil = {}
VehicleTypeUtil.vehicleTypes = {}
function VehicleTypeUtil.registerVehicleType(typeName, className, filename, specializationNames, customEnvironment)
  if VehicleTypeUtil.vehicleTypes[typeName] ~= nil then
    print("Error vehicle types: multiple specifications of type '" .. typeName .. "'")
  elseif className == nil then
    print("Error vehicle types: no className specified for '" .. typeName .. "'")
  elseif filename == nil then
    print("Error vehicle types: no filename specified for '" .. typeName .. "'")
  else
    local specializations = {}
    for k, specName in pairs(specializationNames) do
      local spec = SpecializationUtil.getSpecialization(specName)
      if spec == nil then
        print("Error vehicle types: unknown specialization " .. specName)
        return
      end
      if not spec.prerequisitesPresent(specializations) then
        print("Error: not all prerequistes of specialization " .. specName .. " are fulfilled")
        return
      end
      table.insert(specializations, spec)
    end
    source(filename, customEnvironment)
    local typeEntry = {}
    typeEntry.name = typeName
    typeEntry.className = className
    typeEntry.filename = filename
    typeEntry.specializations = specializations
    print("register vehicle type: " .. typeName)
    VehicleTypeUtil.vehicleTypes[typeName] = typeEntry
  end
end
function VehicleTypeUtil.loadVehicleTypes()
  local xmlFile = loadXMLFile("VehicleTypesXML", "data/vehicleTypes.xml")
  local i = 0
  while true do
    local baseName = string.format("vehiclesTypes.type(%d)", i)
    local typeName = getXMLString(xmlFile, baseName .. "#name")
    if typeName == nil then
      break
    end
    local className = getXMLString(xmlFile, baseName .. "#className")
    local filename = getXMLString(xmlFile, baseName .. "#filename")
    local specializationNames = {}
    local j = 0
    while true do
      local baseSpecName = baseName .. string.format(".specialization(%d)", j)
      local specName = getXMLString(xmlFile, baseSpecName .. "#name")
      if specName == nil then
        break
      end
      table.insert(specializationNames, specName)
      j = j + 1
    end
    VehicleTypeUtil.registerVehicleType(typeName, className, filename, specializationNames, "")
    i = i + 1
  end
  delete(xmlFile)
end

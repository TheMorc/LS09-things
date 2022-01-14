TrafficVehicle = {}
function TrafficVehicle.prerequisitesPresent(specializations)
  return SpecializationUtil.hasSpecialization(PathVehicle, specializations)
end
function TrafficVehicle:load(xmlFile)
  self.isSunOn = false
  self.counter = 10
  self.lightsId = Utils.indexToObject(self.components, getXMLString(xmlFile, "vehicle.lights#groupIndex"))
  local numStaticLights = Utils.getNoNil(getXMLInt(xmlFile, "vehicle.lights#numStaticLights"), 0)
  self.coronas = {}
  for i = numStaticLights, getNumOfChildren(self.lightsId) - 1 do
    table.insert(self.coronas, getChildAt(self.lightsId, i))
  end
  local colorNode = Utils.indexToObject(self.components, getXMLString(xmlFile, "vehicle.colors#index"))
  if colorNode ~= nil then
    local colors = {}
    table.insert(colors, {
      1,
      1,
      1
    })
    local i = 0
    while true do
      local key = string.format("vehicle.colors.color(%d)", i)
      local rgb = getXMLString(xmlFile, key .. "#rbg")
      if rgb == nil then
        break
      end
      local r, g, b = Utils.getVectorFromString(rgb)
      if r ~= nil and g ~= nil and b ~= nil then
        table.insert(colors, {
          r,
          g,
          b
        })
      end
      i = i + 1
    end
    local index = math.random(1, table.getn(colors))
    setShaderParameter(colorNode, "partScale", colors[index][1], colors[index][2], colors[index][3], 0, false)
  end
  self.soundId = createAudioSource("trafficSample", "data/vehicles/cars/carSound.wav", 25, 2, 1, 0)
  link(self.components[1].node, self.soundId)
end
function TrafficVehicle:delete()
end
function TrafficVehicle:mouseEvent(posX, posY, isDown, isUp, button)
end
function TrafficVehicle:keyEvent(unicode, sym, modifier, isDown)
end
function TrafficVehicle:update(dt)
  if self.isSunOn ~= g_currentMission.environment.isSunOn then
    setVisibility(self.lightsId, self.isSunOn)
    self.isSunOn = g_currentMission.environment.isSunOn
  end
  if not g_currentMission.environment.isSunOn then
    if self.counter <= 0 then
      local camera = getCamera()
      local px, py, pz = getWorldTranslation(camera)
      for k, v in pairs(self.coronas) do
        local bx, by, bz = getWorldTranslation(v)
        local dx = px - bx
        local dy = py - by
        local dz = pz - bz
        local ux, uy, uz = localDirectionToWorld(camera, 0, 1, 0)
        dx, dy, dz = worldDirectionToLocal(getParent(v), dx, dy, dz)
        ux, uy, uz = worldDirectionToLocal(getParent(v), ux, uy, uz)
        setDirection(v, dx, dy, dz, ux, uy, uz)
      end
      self.counter = 10
    end
    self.counter = self.counter - 1
  end
end
function TrafficVehicle:draw()
end

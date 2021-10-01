SiloTrigger = {}
local SiloTrigger_mt = Class(SiloTrigger)
function SiloTrigger:onCreate(id)
  table.insert(g_currentMission.siloTriggers, SiloTrigger:new(id))
end
function SiloTrigger:new(id, customMt)
  local instance = {}
  if customMt ~= nil then
    setmetatable(instance, customMt)
  else
    setmetatable(instance, SiloTrigger_mt)
  end
  instance.triggerIds = {}
  table.insert(instance.triggerIds, id)
  addTrigger(id, "triggerCallback", instance)
  for i = 1, 3 do
    local child = getChildAt(id, i - 1)
    table.insert(instance.triggerIds, child)
    addTrigger(child, "triggerCallback", instance)
  end
  instance.fillType = FruitUtil.FRUITTYPE_UNKNOWN
  local fruitType = getUserAttribute(id, "fruitType")
  if fruitType ~= nil then
    local desc = FruitUtil.fruitTypes[fruitType]
    if desc ~= nil then
      instance.fillType = desc.index
    end
  elseif Utils.getNoNil(getUserAttribute(id, "fillTypeWheat"), false) then
    instance.fillType = FruitUtil.FRUITTYPE_WHEAT
  elseif Utils.getNoNil(getUserAttribute(id, "fillTypeGrass"), false) then
    instance.fillType = FruitUtil.FRUITTYPE_GRASS
  end
  local particlePositionStr = getUserAttribute(id, "particlePosition")
  if particlePositionStr ~= nil then
    local x, y, z = Utils.getVectorFromString(particlePositionStr)
    if x ~= nil and y ~= nil and z ~= nil then
      instance.particlePosition = {
        x,
        y,
        z
      }
    end
  end
  instance.isEnabled = true
  instance.fill = 0
  instance.siloTrailerId = 0
  instance.fillDone = false
  local particleSystem = Utils.getNoNil(getUserAttribute(id, "particleSystem"), "wheatParticleSystemLong")
  instance.siloParticleSystemRoot = loadI3DFile("data/vehicles/particleSystems/" .. particleSystem .. ".i3d")
  local x, y, z = getTranslation(id)
  if instance.particlePosition ~= nil then
    x = x + instance.particlePosition[1]
    y = y + instance.particlePosition[2]
    z = z + instance.particlePosition[3]
  end
  setTranslation(instance.siloParticleSystemRoot, x, y, z)
  link(getParent(id), instance.siloParticleSystemRoot)
  for i = 0, getNumOfChildren(instance.siloParticleSystemRoot) - 1 do
    local child = getChildAt(instance.siloParticleSystemRoot, i)
    if getClassName(child) == "Shape" then
      local geometry = getGeometry(child)
      if geometry ~= 0 and getClassName(geometry) == "ParticleSystem" then
        instance.siloParticleSystem = geometry
      end
    end
  end
  if instance.siloParticleSystem ~= nil then
    setEmittingState(instance.siloParticleSystem, false)
  end
  instance.siloFillSound = createSample("siloFillSound")
  loadSample(instance.siloFillSound, "data/maps/sounds/siloFillSound.wav", false)
  return instance
end
function SiloTrigger:delete()
  delete(self.siloFillSound)
  for i = 1, table.getn(self.triggerIds) do
    removeTrigger(self.triggerIds[i])
  end
end
function SiloTrigger:update(dt)
  if self.fill >= 4 and self.siloTrailer ~= nil and not self.fillDone then
    local trailer = self.siloTrailer
    local fillLevel = trailer.fillLevel
    local siloAmount = g_currentMission:getSiloAmount(self.fillType)
    if 0 < siloAmount then
      local deltaFillLevel = math.min(dt / 2, siloAmount)
      trailer:setFillLevel(fillLevel + deltaFillLevel, self.fillType)
      local newFillLevel = trailer.fillLevel
      g_currentMission:setSiloAmount(self.fillType, math.max(siloAmount - (newFillLevel - fillLevel), 0))
      if not self.siloFillSoundEnabled and fillLevel ~= newFillLevel then
        playSample(self.siloFillSound, 0, 1, 0)
        self.siloFillSoundEnabled = true
      end
      if fillLevel == newFillLevel then
        self.fillDone = true
        self:stopFillSound()
      end
    else
      self.fillDone = true
      self:stopFillSound()
    end
  end
  if self.siloParticleSystem ~= nil then
    setEmittingState(self.siloParticleSystem, self.fill >= 4 and self.siloTrailer ~= nil and not self.fillDone)
  end
end
function SiloTrigger:stopFillSound()
  stopSample(self.siloFillSound)
  self.siloFillSoundEnabled = false
end
function SiloTrigger:triggerCallback(triggerId, otherActorId, onEnter, onLeave, onStay, otherShapeId)
  if self.isEnabled then
    local trailer = g_currentMission.objectToTrailer[otherShapeId]
    if trailer ~= nil and trailer:allowFillType(self.fillType, true) and trailer.allowFillFromAir then
      if onEnter then
        self.fill = self.fill + 1
        self.siloTrailer = trailer
        self.fillDone = false
      elseif onLeave then
        self.fill = math.max(self.fill - 1, 0)
        self.siloTrailer = nil
        self.fillDone = false
        self:stopFillSound()
      end
    end
  end
end

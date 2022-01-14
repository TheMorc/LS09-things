Sprayer = {}
function Sprayer.prerequisitesPresent(specializations)
  return true
end
function Sprayer:load(xmlFile)
  self.setIsTurnedOn = SpecializationUtil.callSpecializationsFunction("setIsTurnedOn")
  self.sprayValves = {}
  local psFile = getXMLString(xmlFile, "vehicle.sprayParticleSystem#file")
  if psFile ~= nil then
    local i = 0
    while true do
      local baseName = string.format("vehicle.sprayValves.sprayValve(%d)", i)
      local node = getXMLString(xmlFile, baseName .. "#index")
      if node == nil then
        break
      end
      node = Utils.indexToObject(self.components, node)
      if node ~= nil then
        local sprayValve = {}
        sprayValve.particleSystems = {}
        Utils.loadParticleSystem(xmlFile, sprayValve.particleSystems, "vehicle.sprayParticleSystem", node, false, nil, self.baseDirectory)
        table.insert(self.sprayValves, sprayValve)
      end
      i = i + 1
    end
  end
  local spraySound = getXMLString(xmlFile, "vehicle.spraySound#file")
  if spraySound ~= nil and spraySound ~= "" then
    spraySound = Utils.getFilename(spraySound, self.baseDirectory)
    self.spraySound = createSample("spraySound")
    self.spraySoundEnabled = false
    loadSample(self.spraySound, spraySound, false)
    self.spraySoundPitchOffset = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.spraySound#pitchOffset"), 1)
    self.spraySoundVolume = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.spraySound#volume"), 1)
  end
  self.isTurnedOn = false
  self.speedViolationMaxTime = 2500
  self.speedViolationTimer = self.speedViolationMaxTime
end
function Sprayer:delete()
  for k, sprayValve in pairs(self.sprayValves) do
    Utils.deleteParticleSystem(sprayValve.particleSystems)
  end
  if self.spraySound ~= nil then
    delete(self.spraySound)
  end
end
function Sprayer:mouseEvent(posX, posY, isDown, isUp, button)
end
function Sprayer:keyEvent(unicode, sym, modifier, isDown)
end
function Sprayer:update(dt)
  if self:getIsActiveForInput() and InputBinding.hasEvent(InputBinding.IMPLEMENT_EXTRA) then
    self:setIsTurnedOn(not self.isTurnedOn)
  end
  if self.isTurnedOn and self:getIsActive() then
    if self.lastSpeed * 3600 > 31 then
      self.speedViolationTimer = self.speedViolationTimer - dt
    else
      self.speedViolationTimer = self.speedViolationMaxTime
    end
    if self.speedViolationTimer > 0 then
      for k, cuttingArea in pairs(self.cuttingAreas) do
        local x, y, z = getWorldTranslation(cuttingArea.start)
        local x1, y1, z1 = getWorldTranslation(cuttingArea.width)
        local x2, y2, z2 = getWorldTranslation(cuttingArea.height)
        Utils.updateSprayArea(x, z, x1, z1, x2, z2)
      end
    end
    if not self.spraySoundEnabled and self:getIsActiveForSound() then
      playSample(self.spraySound, 0, self.spraySoundVolume, 0)
      setSamplePitch(self.spraySound, self.spraySoundPitchOffset)
      self.spraySoundEnabled = true
    end
  else
    self.speedViolationTimer = self.speedViolationMaxTime
  end
  if not self.isTurnedOn and self.spraySoundEnabled then
    stopSample(self.spraySound)
    self.spraySoundEnabled = false
  end
end
function Sprayer:draw()
  if self.isTurnedOn then
    g_currentMission:addHelpButtonText(string.format(g_i18n:getText("turn_off_OBJECT"), self.typeDesc), InputBinding.IMPLEMENT_EXTRA)
  else
    g_currentMission:addHelpButtonText(string.format(g_i18n:getText("turn_on_OBJECT"), self.typeDesc), InputBinding.IMPLEMENT_EXTRA)
  end
  if math.abs(self.speedViolationTimer - self.speedViolationMaxTime) > 2 then
    g_currentMission:addWarning(g_i18n:getText("Dont_drive_to_fast") .. "\n" .. string.format(g_i18n:getText("Cruise_control_levelN"), "2", InputBinding.getButtonKeyName(InputBinding.SPEED_LEVEL2)), 0.092, 0.048)
  end
end
function Sprayer:onDetach()
  if self.deactivateOnDetach then
    Sprayer.onDeactivate(self)
  else
    Sprayer.onDeactivateSounds(self)
  end
end
function Sprayer:onLeave()
  if self.deactivateOnLeave then
    Sprayer.onDeactivate(self)
  else
    Sprayer.onDeactivateSounds(self)
  end
end
function Sprayer:onDeactivate()
  self.speedViolationTimer = self.speedViolationMaxTime
  self:setIsTurnedOn(false)
  Sprayer.onDeactivateSounds(self)
end
function Sprayer:onDeactivateSounds()
  if self.spraySoundEnabled then
    stopSample(self.spraySound)
    self.spraySoundEnabled = false
  end
end
function Sprayer:setIsTurnedOn(turnedOn)
  self.isTurnedOn = turnedOn
  for k, sprayValve in pairs(self.sprayValves) do
    Utils.setEmittingState(sprayValve.particleSystems, self.isTurnedOn)
  end
  self.speedViolationTimer = self.speedViolationMaxTime
end

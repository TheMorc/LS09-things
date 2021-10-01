ForageWagon = {}
function ForageWagon.prerequisitesPresent(specializations)
  return SpecializationUtil.hasSpecialization(Trailer, specializations)
end
function ForageWagon:load(xmlFile)
  local forageWgnSound = getXMLString(xmlFile, "vehicle.forageWgnSound#file")
  if forageWgnSound ~= nil and forageWgnSound ~= "" then
    forageWgnSound = Utils.getFilename(forageWgnSound, self.baseDirectory)
    self.forageWgnSound = createSample("forageWgnSound")
    self.forageWgnSoundEnabled = false
    loadSample(self.forageWgnSound, forageWgnSound, false)
    self.forageWgnSoundPitchOffset = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.forageWgnSound#pitchOffset"), 1)
    self.forageWgnSoundVolume = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.forageWgnSound#volume"), 1)
  end
  self.fillScale = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.fillScale#value"), 1)
  self.wasToFast = false
  self.isTurnedOn = false
end
function ForageWagon:delete()
  if self.forageWgnSound ~= nil then
    delete(self.forageWgnSound)
  end
end
function ForageWagon:mouseEvent(posX, posY, isDown, isUp, button)
end
function ForageWagon:keyEvent(unicode, sym, modifier, isDown)
end
function ForageWagon:update(dt)
  if self:getIsActiveForInput() and InputBinding.hasEvent(InputBinding.IMPLEMENT_EXTRA) then
    self.isTurnedOn = not self.isTurnedOn
  end
  self.wasToFast = false
  if self:getIsActive() then
    if self.isTurnedOn and self:allowFillType(FruitUtil.FRUITTYPE_GRASS) and self.capacity > self.fillLevel then
      local toFast = self:doCheckSpeedLimit() and self.attacherVehicle.lastSpeed * 3600 > 29
      if not toFast then
        for k, cuttingArea in pairs(self.cuttingAreas) do
          local x, y, z = getWorldTranslation(cuttingArea.start)
          local x1, y1, z1 = getWorldTranslation(cuttingArea.width)
          local x2, y2, z2 = getWorldTranslation(cuttingArea.height)
          local area = Utils.updateCuttedMeadowArea(x, z, x1, z1, x2, z2)
          local fruitType = FruitUtil.FRUITTYPE_GRASS
          local pixelToQm = 0.25 / g_currentMission.maxFruitValue
          local literPerQm = FruitUtil.fruitIndexToDesc[fruitType].literPerQm * (1 + 0.5 * (3 - g_currentMission.missionStats.difficulty))
          local qm = area * pixelToQm
          local deltaLevel = qm * literPerQm * self.fillScale
          self:setFillLevel(self.fillLevel + deltaLevel, FruitUtil.FRUITTYPE_GRASS)
        end
      end
      self.wasToFast = toFast
      if not self.forageWgnSoundEnabled and self:getIsActiveForSound() then
        playSample(self.forageWgnSound, 0, self.forageWgnSoundVolume, 0)
        setSamplePitch(self.forageWgnSound, self.forageWgnSoundPitchOffset)
        self.forageWgnSoundEnabled = true
      end
    end
    if self.forageWgnSoundEnabled and not self.isTurnedOn then
      stopSample(self.forageWgnSound)
      self.forageWgnSoundEnabled = false
    end
  end
end
function ForageWagon:draw()
  if self.wasToFast then
    g_currentMission:addWarning(g_i18n:getText("Dont_drive_to_fast") .. "\n" .. string.format(g_i18n:getText("Cruise_control_levelN"), "2", InputBinding.getButtonKeyName(InputBinding.SPEED_LEVEL2)), 0.092, 0.048)
  end
  if self.isTurnedOn then
    g_currentMission:addHelpButtonText(string.format(g_i18n:getText("turn_off_OBJECT"), self.typeDesc), InputBinding.IMPLEMENT_EXTRA)
  else
    g_currentMission:addHelpButtonText(string.format(g_i18n:getText("turn_on_OBJECT"), self.typeDesc), InputBinding.IMPLEMENT_EXTRA)
  end
end
function ForageWagon:onDetach()
  if self.deactivateOnDetach then
    ForageWagon.onDeactivate(self)
  else
    ForageWagon.onDeactivateSounds(self)
  end
end
function ForageWagon:onLeave()
  if self.deactivateOnLeave then
    ForageWagon.onDeactivate(self)
  else
    ForageWagon.onDeactivateSounds(self)
  end
end
function ForageWagon:onDeactivate()
  self.isTurnedOn = false
  ForageWagon.onDeactivateSounds(self)
end
function ForageWagon:onDeactivateSounds()
  if self.forageWgnSoundEnabled then
    stopSample(self.forageWgnSound)
    self.forageWgnSoundEnabled = false
  end
end

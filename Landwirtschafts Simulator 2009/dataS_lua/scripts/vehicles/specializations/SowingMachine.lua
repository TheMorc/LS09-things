SowingMachine = {}
function SowingMachine.prerequisitesPresent(specializations)
  return true
end
function SowingMachine:load(xmlFile)
  self.groundContactReport = SpecializationUtil.callSpecializationsFunction("groundContactReport")
  self.contactReportNode = Utils.indexToObject(self.components, getXMLString(xmlFile, "vehicle.contactReportNode#index"))
  if self.contactReportNode == nil then
    self.contactReportNode = self.components[1].node
  end
  self.groundReferenceThreshold = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.groundReferenceNode#threshold"), 0.2)
  self.groundReferenceNode = Utils.indexToObject(self.components, getXMLString(xmlFile, "vehicle.groundReferenceNode#index"))
  self.hasGroundContact = false
  self.speedViolationMaxTime = 2500
  self.speedViolationTimer = self.speedViolationMaxTime
  self.seeds = {}
  for k, fruitType in pairs(FruitUtil.fruitTypes) do
    if fruitType.allowsSeeding then
      self.seeds[fruitType.index] = fruitType.index
    end
  end
  self.groundParticleSystems = {}
  local psName = "vehicle.groundParticleSystem"
  Utils.loadParticleSystem(xmlFile, self.groundParticleSystems, psName, self.components, false, nil, self.baseDirectory)
  self.groundParticleSystemActive = false
  self.isTurnedOn = false
  self.needsActivation = Utils.getNoNil(getXMLBool(xmlFile, "vehicle.needsActivation#value"), false)
  self.aiTerrainDetailChannel1 = g_currentMission.cultivatorChannel
  self.aiTerrainDetailChannel2 = g_currentMission.ploughChannel
  local sowingSound = getXMLString(xmlFile, "vehicle.sowingSound#file")
  if sowingSound ~= nil and sowingSound ~= "" then
    sowingSound = Utils.getFilename(sowingSound, self.baseDirectory)
    self.sowingSound = createSample("sowingSound")
    loadSample(self.sowingSound, sowingSound, false)
    self.sowingSoundPitchOffset = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.sowingSound#pitchOffset"), 0)
    self.sowingSoundVolume = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.sowingSound#volume"), 1)
    self.sowingSoundEnabled = false
  end
  self.currentSeed = 1
  self.selectable = true
  self.sowingMachineActive = false
end
function SowingMachine:delete()
  Utils.deleteParticleSystem(self.groundParticleSystems)
  removeContactReport(self.contactReportNode)
  if self.sowingSound ~= nil then
    delete(self.sowingSound)
  end
end
function SowingMachine:mouseEvent(posX, posY, isDown, isUp, button)
end
function SowingMachine:keyEvent(unicode, sym, modifier, isDown)
end
function SowingMachine:update(dt)
  if self:getIsActiveForInput() then
    if InputBinding.hasEvent(InputBinding.IMPLEMENT_EXTRA2) and self.selectable then
      self.currentSeed = self.currentSeed + 1
      if self.currentSeed > table.getn(self.seeds) then
        self.currentSeed = 1
      else
      end
    end
    if InputBinding.hasEvent(InputBinding.IMPLEMENT_EXTRA) then
      self.isTurnedOn = not self.isTurnedOn
    end
  end
  if self:getIsActive() then
    local hasGroundContact = self.hasGroundContact
    if not hasGroundContact then
      for k, v in pairs(self.wheels) do
        if v.hasGroundContact then
          hasGroundContact = true
          break
        end
      end
      if not hasGroundContact and self.groundReferenceNode ~= nil then
        local x, y, z = getWorldTranslation(self.groundReferenceNode)
        local terrainHeight = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, 0, z)
        if y <= terrainHeight + self.groundReferenceThreshold then
          hasGroundContact = true
        end
      end
    end
    if 0 < self.movingDirection and hasGroundContact then
      if not self.needsActivation or self.isTurnedOn then
        for v, cuttingArea in pairs(self.cuttingAreas) do
          local x, y, z = getWorldTranslation(cuttingArea.start)
          local x1, y1, z1 = getWorldTranslation(cuttingArea.width)
          local x2, y2, z2 = getWorldTranslation(cuttingArea.height)
          local area = Utils.updateSowingArea(self.seeds[self.currentSeed], x, z, x1, z1, x2, z2)
          local fruitDesc = FruitUtil.fruitIndexToDesc[self.seeds[self.currentSeed]]
          local pixelToQm = 0.0625
          local qm = area * pixelToQm
          local ha = qm / 10000
          local usage = fruitDesc.seedUsagePerQm * qm
          g_currentMission.missionStats.seedUsageTotal = g_currentMission.missionStats.seedUsageTotal + usage
          g_currentMission.missionStats.seedUsageSession = g_currentMission.missionStats.seedUsageSession + usage
          g_currentMission.missionStats.hectaresSeededTotal = g_currentMission.missionStats.hectaresSeededTotal + ha
          g_currentMission.missionStats.hectaresSeededSession = g_currentMission.missionStats.hectaresSeededSession + ha
          local seedPrice = fruitDesc.seedPricePerLiter * usage
          g_currentMission.missionStats.expensesTotal = g_currentMission.missionStats.expensesTotal + seedPrice
          g_currentMission.missionStats.expensesSession = g_currentMission.missionStats.expensesSession + seedPrice
          g_currentMission.missionStats.money = g_currentMission.missionStats.money - seedPrice
        end
        g_currentMission.missionStats.seedingDurationTotal = g_currentMission.missionStats.seedingDurationTotal + dt / 60000
        g_currentMission.missionStats.seedingDurationSession = g_currentMission.missionStats.seedingDurationSession + dt / 60000
      end
      if self.lastSpeed * 3600 > 20 then
        self.speedViolationTimer = self.speedViolationTimer - dt
        if 0 > self.speedViolationTimer and self.attacherVehicle ~= nil then
          self.attacherVehicle:detachImplementByObject(self)
        end
      else
        self.speedViolationTimer = self.speedViolationMaxTime
      end
      if not self.groundParticleSystemActive then
        self.groundParticleSystemActive = true
        Utils.setEmittingState(self.groundParticleSystems, true)
      end
      if self.sowingSound ~= nil and not self.sowingSoundEnabled and self.lastSpeed * 3600 > 3 and self:getIsActiveForSound() then
        playSample(self.sowingSound, 0, self.sowingSoundVolume, 0)
        setSamplePitch(self.sowingSound, self.sowingSoundPitchOffset)
        self.sowingSoundEnabled = true
      end
    else
      if self.groundParticleSystemActive then
        self.groundParticleSystemActive = false
        Utils.setEmittingState(self.groundParticleSystems, false)
      end
      self.speedViolationTimer = self.speedViolationMaxTime
      SowingMachine.onDeactivateSounds(self)
    end
  end
  if self.sowingSoundEnabled and self.lastSpeed * 3600 < 3 then
    SowingMachine.onDeactivateSounds(self)
  end
end
function SowingMachine:draw()
  g_currentMission.fruitOverlays[self.seeds[self.currentSeed]]:render()
  if self.selectable then
    g_currentMission:addHelpButtonText(g_i18n:getText("ChooseSeed"), InputBinding.IMPLEMENT_EXTRA2)
  end
  if self.needsActivation then
    if self.isTurnedOn then
      g_currentMission:addHelpButtonText(string.format(g_i18n:getText("turn_off_OBJECT"), self.typeDesc), InputBinding.IMPLEMENT_EXTRA)
    else
      g_currentMission:addHelpButtonText(string.format(g_i18n:getText("turn_on_OBJECT"), self.typeDesc), InputBinding.IMPLEMENT_EXTRA)
    end
  end
  if math.abs(self.speedViolationTimer - self.speedViolationMaxTime) > 2 then
    g_currentMission:addWarning(g_i18n:getText("Dont_drive_to_fast") .. "\n" .. string.format(g_i18n:getText("Cruise_control_levelN"), "1", InputBinding.getButtonKeyName(InputBinding.SPEED_LEVEL1)), 0.092, 0.048)
  end
end
function SowingMachine:onAttach(attacherVehicle)
  SowingMachine.onActivate(self)
end
function SowingMachine:onDetach()
  if self.deactivateOnDetach then
    SowingMachine.onDeactivate(self)
  else
    SowingMachine.onDeactivateSounds(self)
  end
end
function SowingMachine:onEnter()
  SowingMachine.onActivate(self)
end
function SowingMachine:onLeave()
  if self.deactivateOnLeave then
    SowingMachine.onDeactivate(self)
  end
end
function SowingMachine:onActivate()
  if not self.sowingMachineActive then
    addContactReport(self.contactReportNode, 1.0E-4, "groundContactReport", self)
    self.sowingMachineActive = true
  end
end
function SowingMachine:onDeactivate()
  if self.sowingMachineActive then
    self.speedViolationTimer = self.speedViolationMaxTime
    removeContactReport(self.contactReportNode)
    self.sowingMachineActive = false
    if self.groundParticleSystemActive then
      self.groundParticleSystemActive = false
      Utils.setEmittingState(self.groundParticleSystems, false)
    end
    SowingMachine.onDeactivateSounds(self)
  end
end
function SowingMachine:onDeactivateSounds()
  if self.sowingSoundEnabled then
    stopSample(self.sowingSound)
    self.sowingSoundEnabled = false
  end
end
function SowingMachine:aiTurnOn()
  self.isTurnedOn = true
end
function SowingMachine:groundContactReport(objectId, otherObjectId, isStart, normalForce, tangentialForce)
  if otherObjectId == g_currentMission.terrainRootNode then
    self.hasGroundContact = isStart or 0 < normalForce or 0 < tangentialForce
  end
end

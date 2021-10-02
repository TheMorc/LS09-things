SowingMachine = {}
function SowingMachine.prerequisitesPresent(specializations)
  return true
end
function SowingMachine:load(xmlFile)
  self.speedRotatingParts = {}
  local i = 0
  while true do
    local baseName = string.format("vehicle.speedRotatingParts.speedRotatingPart(%d)", i)
    local index = getXMLString(xmlFile, baseName .. "#index")
    if index == nil then
      break
    end
    local node = Utils.indexToObject(self.components, index)
    if node ~= nil then
      local entry = {}
      entry.node = node
      entry.rotationSpeedScale = getXMLFloat(xmlFile, baseName .. "#rotationSpeedScale")
      if entry.rotationSpeedScale == nil then
        entry.rotationSpeedScale = 1 / Utils.getNoNil(getXMLFloat(xmlFile, baseName .. "#radius"), 1)
      end
      entry.foldMinLimit = Utils.getNoNil(getXMLFloat(xmlFile, baseName .. "#foldMinLimit"), 0)
      entry.foldMaxLimit = Utils.getNoNil(getXMLFloat(xmlFile, baseName .. "#foldMaxLimit"), 1)
      table.insert(self.speedRotatingParts, entry)
    end
    i = i + 1
  end
  local drumNode = Utils.indexToObject(self.components, getXMLString(xmlFile, "vehicle.drum#index"))
  if drumNode ~= nil then
    print("Warning: vehicle.drum is no longer used, use speedRotatingParts\n")
  end
  self.groundContactReport = SpecializationUtil.callSpecializationsFunction("groundContactReport")
  self.setSeedFruitType = SpecializationUtil.callSpecializationsFunction("setSeedFruitType")
  self.contactReportNode = Utils.indexToObject(self.components, getXMLString(xmlFile, "vehicle.contactReportNode#index"))
  if self.contactReportNode == nil then
    self.contactReportNode = self.components[1].node
  end
  self.contactReportNodes = {}
  local contactReportNodeFound = false
  local i = 0
  while true do
    local baseName = string.format("vehicle.contactReportNodes.contactReportNode(%d)", i)
    local index = getXMLString(xmlFile, baseName .. "#index")
    if index == nil then
      break
    end
    local node = Utils.indexToObject(self.components, index)
    if node ~= nil then
      local entry = {}
      entry.node = node
      entry.hasGroundContact = false
      self.contactReportNodes[node] = entry
      contactReportNodeFound = true
    end
    i = i + 1
  end
  if not contactReportNodeFound then
    local entry = {}
    entry.node = self.contactReportNode
    entry.hasGroundContact = false
    self.contactReportNodes[entry.node] = entry
  end
  self.groundReferenceThreshold = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.groundReferenceNode#threshold"), 0.2)
  self.groundReferenceNode = Utils.indexToObject(self.components, getXMLString(xmlFile, "vehicle.groundReferenceNode#index"))
  local numCuttingAreas = Utils.getNoNil(getXMLInt(xmlFile, "vehicle.cuttingAreas#count"), 0)
  for i = 1, numCuttingAreas do
    local areanamei = string.format("vehicle.cuttingAreas.cuttingArea%d", i)
    self.cuttingAreas[i].foldMinLimit = Utils.getNoNil(getXMLFloat(xmlFile, areanamei .. "#foldMinLimit"), 0)
    self.cuttingAreas[i].foldMaxLimit = Utils.getNoNil(getXMLFloat(xmlFile, areanamei .. "#foldMaxLimit"), 1)
  end
  self.hasGroundContact = false
  self.maxSpeedLevel = Utils.getNoNil(getXMLInt(xmlFile, "vehicle.maxSpeedLevel#value"), 1)
  self.speedViolationMaxTime = 2500
  self.speedViolationTimer = self.speedViolationMaxTime
  self.seeds = {}
  for k, fruitType in pairs(FruitUtil.fruitTypes) do
    if fruitType.allowsSeeding then
      table.insert(self.seeds, fruitType.index)
    end
  end
  self.groundParticleSystems = {}
  local psName = "vehicle.groundParticleSystem"
  Utils.loadParticleSystem(xmlFile, self.groundParticleSystems, psName, self.components, false, nil, self.baseDirectory)
  self.groundParticleSystemActive = false
  self.newGroundParticleSystems = {}
  local i = 0
  while true do
    local baseName = string.format("vehicle.groundParticleSystems.groundParticleSystem(%d)", i)
    if not hasXMLProperty(xmlFile, baseName) then
      break
    end
    local entry = {}
    entry.ps = {}
    Utils.loadParticleSystem(xmlFile, entry.ps, baseName, self.components, false, nil, self.baseDirectory)
    if 0 < table.getn(entry.ps) then
      entry.isActive = false
      table.insert(self.newGroundParticleSystems, entry)
    end
    i = i + 1
  end
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
  self.sowingMachineContactReportsActive = false
  self.foldInputButton = InputBinding.IMPLEMENT_EXTRA3
end
function SowingMachine:delete()
  Utils.deleteParticleSystem(self.groundParticleSystems)
  for _, v in pairs(self.newGroundParticleSystems) do
    Utils.deleteParticleSystem(v.ps)
  end
  SowingMachine.removeContactReports(self)
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
    if self.needsActivation and InputBinding.hasEvent(InputBinding.IMPLEMENT_EXTRA) then
      self.isTurnedOn = not self.isTurnedOn
    end
  end
  if self:getIsActive() then
    local hasGroundContact = false
    for k, v in pairs(self.contactReportNodes) do
      if v.hasGroundContact then
        hasGroundContact = true
        break
      end
    end
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
    local foldAnimTime = self.foldAnimTime
    if 0 < self.movingDirection and hasGroundContact then
      local enableGroundParticleSystems = false
      if not self.needsActivation or self.isTurnedOn then
        if self.lastSpeed * 3600 > 5 then
          enableGroundParticleSystems = true
        end
        for k, cuttingArea in pairs(self.cuttingAreas) do
          local ps = self.newGroundParticleSystems[k]
          if foldAnimTime == nil or foldAnimTime <= cuttingArea.foldMaxLimit and foldAnimTime >= cuttingArea.foldMinLimit then
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
            if ps ~= nil and enableGroundParticleSystems and not ps.isActive then
              ps.isActive = true
              Utils.setEmittingState(ps.ps, true)
            end
          elseif ps ~= nil and ps.isActive then
            ps.isActive = false
            Utils.setEmittingState(ps.ps, false)
          end
        end
        g_currentMission.missionStats.seedingDurationTotal = g_currentMission.missionStats.seedingDurationTotal + dt / 60000
        g_currentMission.missionStats.seedingDurationSession = g_currentMission.missionStats.seedingDurationSession + dt / 60000
        local speedLimit = 20
        if self.maxSpeedLevel == 2 then
          speedLimit = 30
        elseif self.maxSpeedLevel == 3 then
          speedLimit = 100
        end
        if self:doCheckSpeedLimit() and speedLimit < self.lastSpeed * 3600 then
          self.speedViolationTimer = self.speedViolationTimer - dt
          if 0 > self.speedViolationTimer and self.attacherVehicle ~= nil then
            self.attacherVehicle:detachImplementByObject(self)
          end
        else
          self.speedViolationTimer = self.speedViolationMaxTime
        end
      else
        self.speedViolationTimer = self.speedViolationMaxTime
      end
      if enableGroundParticleSystems and not self.groundParticleSystemActive then
        self.groundParticleSystemActive = true
        Utils.setEmittingState(self.groundParticleSystems, true)
      end
      if not enableGroundParticleSystems and self.groundParticleSystemActive then
        self.groundParticleSystemActive = false
        Utils.setEmittingState(self.groundParticleSystems, false)
      end
      if not enableGroundParticleSystems then
        for k, ps in pairs(self.newGroundParticleSystems) do
          if ps.isActive then
            ps.isActive = false
            Utils.setEmittingState(ps.ps, false)
          end
        end
      end
      if self.sowingSound ~= nil then
        if self.lastSpeed * 3600 > 3 and (not self.needsActivation or self.isTurnedOn) then
          if not self.sowingSoundEnabled and self:getIsActiveForSound() then
            playSample(self.sowingSound, 0, self.sowingSoundVolume, 0)
            setSamplePitch(self.sowingSound, self.sowingSoundPitchOffset)
            self.sowingSoundEnabled = true
          end
        elseif self.sowingSoundEnabled then
          self.sowingSoundEnabled = false
          stopSample(self.sowingSound)
        end
      end
      for k, v in pairs(self.speedRotatingParts) do
        if foldAnimTime == nil or foldAnimTime <= v.foldMaxLimit and foldAnimTime >= v.foldMinLimit then
          rotate(v.node, v.rotationSpeedScale * self.lastSpeedReal * self.movingDirection * dt, 0, 0)
        end
      end
    else
      if self.groundParticleSystemActive then
        self.groundParticleSystemActive = false
        Utils.setEmittingState(self.groundParticleSystems, false)
      end
      for k, ps in pairs(self.newGroundParticleSystems) do
        if ps.isActive then
          ps.isActive = false
          Utils.setEmittingState(ps.ps, false)
        end
      end
      self.speedViolationTimer = self.speedViolationMaxTime
      SowingMachine.onDeactivateSounds(self)
    end
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
    local buttonName = InputBinding.SPEED_LEVEL1
    if self.maxSpeedLevel == 2 then
      buttonName = InputBinding.SPEED_LEVEL2
    elseif self.maxSpeedLevel == 3 then
      buttonName = InputBinding.SPEED_LEVEL3
    end
    g_currentMission:addWarning(g_i18n:getText("Dont_drive_to_fast") .. "\n" .. string.format(g_i18n:getText("Cruise_control_levelN"), tostring(self.maxSpeedLevel), InputBinding.getButtonKeyName(buttonName)), 0.092, 0.048)
  end
end
function SowingMachine:onAttach(attacherVehicle)
  SowingMachine.onActivate(self)
  SowingMachine.addContactReports(self)
end
function SowingMachine:onDetach()
  if self.deactivateOnDetach then
    SowingMachine.onDeactivate(self)
    SowingMachine.removeContactReports(self)
  else
    SowingMachine.onDeactivateSounds(self)
  end
end
function SowingMachine:onEnter()
  SowingMachine.onActivate(self)
  SowingMachine.addContactReports(self)
end
function SowingMachine:onLeave()
  if self.deactivateOnLeave then
    SowingMachine.onDeactivate(self)
    SowingMachine.removeContactReports(self)
  end
end
function SowingMachine:onActivate()
end
function SowingMachine:onDeactivate()
  self.speedViolationTimer = self.speedViolationMaxTime
  if self.groundParticleSystemActive then
    self.groundParticleSystemActive = false
    Utils.setEmittingState(self.groundParticleSystems, false)
  end
  for k, ps in pairs(self.newGroundParticleSystems) do
    if ps.isActive then
      ps.isActive = false
      Utils.setEmittingState(ps.ps, false)
    end
  end
  SowingMachine.onDeactivateSounds(self)
end
function SowingMachine:onDeactivateSounds()
  if self.sowingSoundEnabled then
    stopSample(self.sowingSound)
    self.sowingSoundEnabled = false
  end
end
function SowingMachine:setSeedFruitType(fruitType)
  for i, v in ipairs(self.seeds) do
    if v == fruitType then
      self.currentSeed = i
      break
    end
  end
end
function SowingMachine:aiTurnOn()
  self.isTurnedOn = true
end
function SowingMachine:aiLower()
  self.isTurnedOn = true
end
function SowingMachine:aiRaise()
  self.isTurnedOn = false
end
function SowingMachine:addContactReports()
  if not self.sowingMachineContactReportsActive then
    for k, v in pairs(self.contactReportNodes) do
      addContactReport(v.node, 1.0E-4, "groundContactReport", self)
    end
    self.sowingMachineContactReportsActive = true
  end
end
function SowingMachine:removeContactReports()
  if self.sowingMachineContactReportsActive then
    for k, v in pairs(self.contactReportNodes) do
      removeContactReport(v.node)
      v.hasGroundContact = false
    end
    self.sowingMachineContactReportsActive = false
  end
end
function SowingMachine:groundContactReport(objectId, otherObjectId, isStart, normalForce, tangentialForce)
  if otherObjectId == g_currentMission.terrainRootNode then
    local entry = self.contactReportNodes[objectId]
    if entry ~= nil then
      entry.hasGroundContact = isStart or 0 < normalForce or 0 < tangentialForce
    end
  end
end

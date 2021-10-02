Cultivator = {}
function Cultivator.prerequisitesPresent(specializations)
  return true
end
function Cultivator:load(xmlFile)
  self.groundContactReport = SpecializationUtil.callSpecializationsFunction("groundContactReport")
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
      entry.rotateOnGroundContact = Utils.getNoNil(getXMLBool(xmlFile, baseName .. "#rotateOnGroundContact"), false)
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
    entry.node = self.components[1].node
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
  local cultivatorSound = getXMLString(xmlFile, "vehicle.cultivatorSound#file")
  if cultivatorSound ~= nil and cultivatorSound ~= "" then
    cultivatorSound = Utils.getFilename(cultivatorSound, self.baseDirectory)
    self.cultivatorSound = createSample("cultivatorSound")
    loadSample(self.cultivatorSound, cultivatorSound, false)
    self.cultivatorSoundPitchOffset = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.cultivatorSound#pitchOffset"), 0)
    self.cultivatorSoundVolume = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.cultivatorSound#volume"), 1)
    self.cultivatorSoundEnabled = false
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
  self.onlyActiveWhenLowered = Utils.getNoNil(getXMLBool(xmlFile, "vehicle.onlyActiveWhenLowered#value"), true)
  self.aiTerrainDetailChannel1 = g_currentMission.ploughChannel
  self.aiTerrainDetailChannel2 = g_currentMission.sowingChannel
  self.maxSpeedLevel = Utils.getNoNil(getXMLInt(xmlFile, "vehicle.maxSpeedLevel#value"), 1)
  self.speedViolationMaxTime = 2500
  self.speedViolationTimer = self.speedViolationMaxTime
  self.cultivatorContactReportsActive = false
  self.startActivationTimeout = 2000
  self.startActivationTime = 0
end
function Cultivator:delete()
  Utils.deleteParticleSystem(self.groundParticleSystems)
  for _, v in pairs(self.newGroundParticleSystems) do
    Utils.deleteParticleSystem(v.ps)
  end
  Cultivator.removeContactReports(self)
  if self.cultivatorSound ~= nil then
    delete(self.cultivatorSound)
  end
end
function Cultivator:mouseEvent(posX, posY, isDown, isUp, button)
end
function Cultivator:keyEvent(unicode, sym, modifier, isDown)
end
function Cultivator:update(dt)
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
    local rotateRotatingParts = false
    local foldAnimTime = self.foldAnimTime
    if hasGroundContact and (not self.onlyActiveWhenLowered or self:isLowered(false)) then
      rotateRotatingParts = true
      local enableGroundParticleSystems = self.lastSpeed * 3600 > 5
      if self.startActivationTime <= self.time then
        for k, cuttingArea in pairs(self.cuttingAreas) do
          local ps = self.newGroundParticleSystems[k]
          if foldAnimTime == nil or foldAnimTime <= cuttingArea.foldMaxLimit and foldAnimTime >= cuttingArea.foldMinLimit then
            local x, y, z = getWorldTranslation(cuttingArea.start)
            local x1, y1, z1 = getWorldTranslation(cuttingArea.width)
            local x2, y2, z2 = getWorldTranslation(cuttingArea.height)
            Utils.updateCultivatorArea(x, z, x1, z1, x2, z2)
            if ps ~= nil and enableGroundParticleSystems and not ps.isActive then
              ps.isActive = true
              Utils.setEmittingState(ps.ps, true)
            end
          elseif ps ~= nil and ps.isActive then
            ps.isActive = false
            Utils.setEmittingState(ps.ps, false)
          end
        end
        local speedLimit = 20
        if self.maxSpeedLevel == 2 then
          speedLimit = 30
        elseif self.maxSpeedLevel == 3 then
          speedLimit = 100
        end
        if self:doCheckSpeedLimit() and speedLimit < self.lastSpeed * 3600 then
          self.speedViolationTimer = self.speedViolationTimer - dt
          if 0 > self.speedViolationTimer and self.attacherVehicle then
            self.attacherVehicle:detachImplementByObject(self)
          end
        else
          self.speedViolationTimer = self.speedViolationMaxTime
        end
      end
      if self.cultivatorSound ~= nil and not self.cultivatorSoundEnabled and self:getIsActiveForSound() and self.lastSpeed * 3600 > 3 then
        playSample(self.cultivatorSound, 0, self.cultivatorSoundVolume, 0)
        setSamplePitch(self.cultivatorSound, self.cultivatorSoundPitchOffset)
        self.cultivatorSoundEnabled = true
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
    else
      self.speedViolationTimer = self.speedViolationMaxTime
      if self.cultivatorSoundEnabled then
        stopSample(self.cultivatorSound)
        self.cultivatorSoundEnabled = false
      end
      Cultivator.disableGroundParticleSystems(self)
    end
    local updateWheelRotatingParts = hasGroundContact
    if not updateWheelRotatingParts then
      for k, v in pairs(self.wheels) do
        if v.hasGroundContact then
          updateWheelRotatingParts = true
          break
        end
      end
    end
    if updateWheelRotatingParts then
      for k, v in pairs(self.speedRotatingParts) do
        if (rotateRotatingParts or v.rotateOnGroundContact) and (foldAnimTime == nil or foldAnimTime <= v.foldMaxLimit and foldAnimTime >= v.foldMinLimit) then
          rotate(v.node, v.rotationSpeedScale * self.lastSpeedReal * self.movingDirection * dt, 0, 0)
        end
      end
    end
  else
  end
  if self.cultivatorSoundEnabled and self.lastSpeed * 3600 < 3 then
    stopSample(self.cultivatorSound)
    self.cultivatorSoundEnabled = false
  end
end
function Cultivator:disableGroundParticleSystems()
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
end
function Cultivator:draw()
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
function Cultivator:onAttach(attacherVehicle)
  Cultivator.onActivate(self)
  Cultivator.addContactReports(self)
  self.startActivationTime = self.time + self.startActivationTimeout
end
function Cultivator:onDetach()
  if self.deactivateOnDetach then
    Cultivator.onDeactivate(self)
    Cultivator.removeContactReports(self)
  else
    Cultivator.onDeactivateSounds(self)
  end
end
function Cultivator:onEnter()
  Cultivator.onActivate(self)
  Cultivator.addContactReports(self)
end
function Cultivator:onLeave()
  if self.deactivateOnLeave then
    Cultivator.onDeactivate(self)
    Cultivator.removeContactReports(self)
  else
    Cultivator.onDeactivateSounds(self)
  end
end
function Cultivator:onActivate()
end
function Cultivator:onDeactivate()
  self.speedViolationTimer = self.speedViolationMaxTime
  Cultivator.disableGroundParticleSystems(self)
  Cultivator.onDeactivateSounds(self)
end
function Cultivator:onDeactivateSounds()
  if self.cultivatorSoundEnabled then
    stopSample(self.cultivatorSound)
    self.cultivatorSoundEnabled = false
  end
end
function Cultivator:addContactReports()
  if not self.cultivatorContactReportsActive then
    for k, v in pairs(self.contactReportNodes) do
      addContactReport(v.node, 1.0E-4, "groundContactReport", self)
    end
    self.cultivatorContactReportsActive = true
  end
end
function Cultivator:removeContactReports()
  if self.cultivatorContactReportsActive then
    for k, v in pairs(self.contactReportNodes) do
      removeContactReport(v.node)
      v.hasGroundContact = false
    end
    self.cultivatorContactReportsActive = false
  end
end
function Cultivator:groundContactReport(objectId, otherObjectId, isStart, normalForce, tangentialForce)
  if otherObjectId == g_currentMission.terrainRootNode then
    local entry = self.contactReportNodes[objectId]
    if entry ~= nil then
      entry.hasGroundContact = isStart or 0 < normalForce or 0 < tangentialForce
    end
  end
end

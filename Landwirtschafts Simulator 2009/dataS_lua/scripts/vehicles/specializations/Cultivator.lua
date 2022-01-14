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
  self.aiTerrainDetailChannel1 = g_currentMission.ploughChannel
  self.aiTerrainDetailChannel2 = g_currentMission.sowingChannel
  self.speedViolationMaxTime = 2500
  self.speedViolationTimer = self.speedViolationMaxTime
  self.cultivatorActive = false
  self.startActivationTimeout = 2000
  self.startActivationTime = 0
end
function Cultivator:delete()
  Utils.deleteParticleSystem(self.groundParticleSystems)
  removeContactReport(self.contactReportNode)
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
    if not hasGroundContact and self.groundReferenceNode ~= nil then
      local x, y, z = getWorldTranslation(self.groundReferenceNode)
      local terrainHeight = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, 0, z)
      if y <= terrainHeight + self.groundReferenceThreshold then
        hasGroundContact = true
      end
    end
    if hasGroundContact then
      local foldAnimTime = self.foldAnimTime
      if self.startActivationTime <= self.time then
        for k, cuttingArea in pairs(self.cuttingAreas) do
          if foldAnimTime == nil or foldAnimTime <= cuttingArea.foldMaxLimit and foldAnimTime >= cuttingArea.foldMinLimit then
            local x, y, z = getWorldTranslation(cuttingArea.start)
            local x1, y1, z1 = getWorldTranslation(cuttingArea.width)
            local x2, y2, z2 = getWorldTranslation(cuttingArea.height)
            Utils.updateCultivatorArea(x, z, x1, z1, x2, z2)
          end
        end
        if self.lastSpeed * 3600 > 20 then
          self.speedViolationTimer = self.speedViolationTimer - dt
          if 0 > self.speedViolationTimer and self.attacherVehicle then
            self.attacherVehicle:detachImplementByObject(self)
          end
        else
          self.speedViolationTimer = self.speedViolationMaxTime
        end
      end
      for k, v in pairs(self.speedRotatingParts) do
        if foldAnimTime == nil or foldAnimTime <= v.foldMaxLimit and foldAnimTime >= v.foldMinLimit then
          rotate(v.node, v.rotationSpeedScale * self.lastSpeedReal * self.movingDirection * dt, 0, 0)
        end
      end
      if self.cultivatorSound ~= nil and not self.cultivatorSoundEnabled and self:getIsActiveForSound() and self.lastSpeed * 3600 > 3 then
        playSample(self.cultivatorSound, 0, self.cultivatorSoundVolume, 0)
        setSamplePitch(self.cultivatorSound, self.cultivatorSoundPitchOffset)
        self.cultivatorSoundEnabled = true
      end
      if self.lastSpeed * 3600 > 5 and not self.groundParticleSystemActive then
        self.groundParticleSystemActive = true
        Utils.setEmittingState(self.groundParticleSystems, true)
      end
      if self.lastSpeed * 3600 < 5 and self.groundParticleSystemActive then
        self.groundParticleSystemActive = false
        Utils.setEmittingState(self.groundParticleSystems, false)
      end
    else
      self.speedViolationTimer = self.speedViolationMaxTime
      if self.cultivatorSoundEnabled then
        stopSample(self.cultivatorSound)
        self.cultivatorSoundEnabled = false
      end
      if self.groundParticleSystemActive then
        self.groundParticleSystemActive = false
        Utils.setEmittingState(self.groundParticleSystems, false)
      end
    end
  elseif self.groundParticleSystemActive then
    self.groundParticleSystemActive = false
    Utils.setEmittingState(self.groundParticleSystems, false)
  end
  if self.cultivatorSoundEnabled and self.lastSpeed * 3600 < 3 then
    stopSample(self.cultivatorSound)
    self.cultivatorSoundEnabled = false
  end
end
function Cultivator:draw()
  if math.abs(self.speedViolationTimer - self.speedViolationMaxTime) > 2 then
    g_currentMission:addWarning(g_i18n:getText("Dont_drive_to_fast") .. "\n" .. string.format(g_i18n:getText("Cruise_control_levelN"), "1", InputBinding.getButtonKeyName(InputBinding.SPEED_LEVEL1)), 0.092, 0.048)
  end
end
function Cultivator:onAttach(attacherVehicle)
  Cultivator.onActivate(self)
end
function Cultivator:onDetach()
  if self.deactivateOnDetach then
    Cultivator.onDeactivate(self)
  else
    Cultivator.onDeactivateSounds(self)
  end
end
function Cultivator:onEnter()
  Cultivator.onActivate(self)
end
function Cultivator:onLeave()
  if self.deactivateOnLeave then
    Cultivator.onDeactivate(self)
  else
    Cultivator.onDeactivateSounds(self)
  end
end
function Cultivator:onActivate()
  if not self.cultivatorActive then
    for k, v in pairs(self.contactReportNodes) do
      addContactReport(v.node, 1.0E-4, "groundContactReport", self)
    end
    self.startActivationTime = self.time + self.startActivationTimeout
    self.cultivatorActive = true
  end
end
function Cultivator:onDeactivate()
  if self.cultivatorActive then
    self.speedViolationTimer = self.speedViolationMaxTime
    for k, v in pairs(self.contactReportNodes) do
      removeContactReport(v.node)
    end
    self.cultivatorActive = false
    if self.groundParticleSystemActive then
      self.groundParticleSystemActive = false
      Utils.setEmittingState(self.groundParticleSystems, false)
    end
    Cultivator.onDeactivateSounds(self)
  end
end
function Cultivator:onDeactivateSounds()
  if self.cultivatorSoundEnabled then
    stopSample(self.cultivatorSound)
    self.cultivatorSoundEnabled = false
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

Tedder = {}
function Tedder.prerequisitesPresent(specializations)
  return true
end
function Tedder:load(xmlFile)
  self.groundReferenceThreshold = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.groundReferenceNode#threshold"), 0.2)
  self.groundReferenceNode = Utils.indexToObject(self.components, getXMLString(xmlFile, "vehicle.groundReferenceNode#index"))
  if self.groundReferenceNode == nil then
    self.groundReferenceNode = self.components[1].node
  end
  self.rotors = {}
  local psFile = getXMLString(xmlFile, "vehicle.rotors.rotor(1)#index")
  if psFile ~= nil then
    local i = 0
    while true do
      local baseName = string.format("vehicle.rotors.rotor(%d)", i)
      local node = {}
      node.index = getXMLString(xmlFile, baseName .. "#index")
      node.direction = getXMLInt(xmlFile, baseName .. "#direction")
      if node.index == nil then
        break
      end
      node.index = Utils.indexToObject(self.components, node.index)
      if node ~= nil then
        table.insert(self.rotors, node)
      end
      i = i + 1
    end
  end
  local numTedderDropAreas = Utils.getNoNil(getXMLInt(xmlFile, "vehicle.tedderDropAreas#count"), 0)
  if numTedderDropAreas ~= table.getn(self.cuttingAreas) then
    print("Warning: number of cutting areas and drop areas should be equal")
  end
  self.tedderDropAreas = {}
  for i = 1, numTedderDropAreas do
    self.tedderDropAreas[i] = {}
    local areanamei = string.format("vehicle.tedderDropAreas.tedderDropArea%d", i)
    self.tedderDropAreas[i].start = Utils.indexToObject(self.components, getXMLString(xmlFile, areanamei .. "#startIndex"))
    self.tedderDropAreas[i].width = Utils.indexToObject(self.components, getXMLString(xmlFile, areanamei .. "#widthIndex"))
    self.tedderDropAreas[i].height = Utils.indexToObject(self.components, getXMLString(xmlFile, areanamei .. "#heightIndex"))
  end
  local numCuttingAreas = Utils.getNoNil(getXMLInt(xmlFile, "vehicle.cuttingAreas#count"), 0)
  for i = 1, numCuttingAreas do
    local areanamei = string.format("vehicle.cuttingAreas.cuttingArea%d", i)
    self.cuttingAreas[i].foldMinLimit = Utils.getNoNil(getXMLFloat(xmlFile, areanamei .. "#foldMinLimit"), 0)
    self.cuttingAreas[i].foldMaxLimit = Utils.getNoNil(getXMLFloat(xmlFile, areanamei .. "#foldMaxLimit"), 1)
    self.cuttingAreas[i].grassParticleSystemIndex = getXMLInt(xmlFile, areanamei .. "#particleSystemIndex")
  end
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
  self.grassParticleSystems = {}
  local i = 0
  while true do
    local baseName = string.format("vehicle.grassParticleSystems.grassParticleSystem(%d)", i)
    local particleSystem = {}
    particleSystem.ps = {}
    local ps = Utils.loadParticleSystem(xmlFile, particleSystem.ps, baseName, self.components, false, nil, self.baseDirectory)
    if ps == nil then
      break
    end
    particleSystem.disableTime = 0
    table.insert(self.grassParticleSystems, particleSystem)
    i = i + 1
  end
  local tedderSound = getXMLString(xmlFile, "vehicle.tedderSound#file")
  if tedderSound ~= nil and tedderSound ~= "" then
    tedderSound = Utils.getFilename(tedderSound, self.baseDirectory)
    self.tedderSound = createSample("tedderSound")
    self.tedderSoundEnabled = false
    loadSample(self.tedderSound, tedderSound, false)
    self.tedderSoundPitchOffset = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.tedderSound#pitchOffset"), 1)
    self.tedderSoundVolume = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.tedderSound#volume"), 1)
  end
  self.isTurnedOn = false
  self.wasToFast = false
end
function Tedder:delete()
  for k, v in pairs(self.grassParticleSystems) do
    Utils.deleteParticleSystem(v.ps)
  end
  if self.tedderSound ~= nil then
    delete(self.tedderSound)
  end
end
function Tedder:mouseEvent(posX, posY, isDown, isUp, button)
end
function Tedder:keyEvent(unicode, sym, modifier, isDown)
end
function Tedder:update(dt)
  self.wasToFast = false
  if self:getIsActiveForInput() and InputBinding.hasEvent(InputBinding.IMPLEMENT_EXTRA) then
    self.isTurnedOn = not self.isTurnedOn
  end
  if self:getIsActive() then
    local hasGroundContact = false
    local x, y, z = getWorldTranslation(self.groundReferenceNode)
    local terrainHeight = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, 0, z)
    if y <= terrainHeight + self.groundReferenceThreshold then
      hasGroundContact = true
    end
    for k, v in pairs(self.grassParticleSystems) do
      if self.time > v.disableTime then
        Utils.setEmittingState(v.ps, false)
      end
    end
    if hasGroundContact then
      local foldAnimTime = self.foldAnimTime
      if self.isTurnedOn then
        local toFast = self:doCheckSpeedLimit() and self.lastSpeed * 3600 > 31
        if not toFast then
          local numDropAreas = table.getn(self.tedderDropAreas)
          for i = 1, table.getn(self.cuttingAreas) do
            local cuttingArea = self.cuttingAreas[i]
            if foldAnimTime == nil or foldAnimTime <= cuttingArea.foldMaxLimit and foldAnimTime >= cuttingArea.foldMinLimit then
              local x, y, z = getWorldTranslation(cuttingArea.start)
              local x1, y1, z1 = getWorldTranslation(cuttingArea.width)
              local x2, y2, z2 = getWorldTranslation(cuttingArea.height)
              local ratio = g_currentMission.windrowCutLongRatio
              local area = Utils.updateFruitCutLongArea(FruitUtil.FRUITTYPE_GRASS, x, z, x1, z1, x2, z2, 0)
              area = area + Utils.updateFruitCutLongArea(FruitUtil.FRUITTYPE_DRYGRASS, x, z, x1, z1, x2, z2, 0)
              area = area + Utils.updateFruitWindrowArea(FruitUtil.FRUITTYPE_GRASS, x, z, x1, z1, x2, z2, 0) * ratio
              area = area + Utils.updateFruitWindrowArea(FruitUtil.FRUITTYPE_DRYGRASS, x, z, x1, z1, x2, z2, 0) * ratio
              if 0 < area then
                if i <= numDropAreas then
                  local dropArea = self.tedderDropAreas[i]
                  local x, y, z = getWorldTranslation(dropArea.start)
                  local x1, y1, z1 = getWorldTranslation(dropArea.width)
                  local x2, y2, z2 = getWorldTranslation(dropArea.height)
                  local old, total = Utils.getFruitCutLongArea(FruitUtil.FRUITTYPE_DRYGRASS, x, z, x1, z1, x2, z2)
                  area = area + old
                  local value = area / total
                  if value < 1 and 0.1 < value then
                    value = 1
                  else
                    value = math.floor(value + 0.6)
                  end
                  if 1 <= value then
                    value = math.min(value, g_currentMission.maxCutLongValue)
                    Utils.updateFruitCutLongArea(FruitUtil.FRUITTYPE_DRYGRASS, x, z, x1, z1, x2, z2, value, true)
                  end
                end
                local ps
                if cuttingArea.grassParticleSystemIndex ~= nil then
                  ps = self.grassParticleSystems[cuttingArea.grassParticleSystemIndex + 1]
                  if ps ~= nil then
                    ps.disableTime = self.time + 300
                    Utils.setEmittingState(ps.ps, true)
                  end
                end
              end
            end
          end
        end
        self.wasToFast = toFast
      end
      for k, v in pairs(self.speedRotatingParts) do
        if foldAnimTime == nil or foldAnimTime <= v.foldMaxLimit and foldAnimTime >= v.foldMinLimit then
          rotate(v.node, v.rotationSpeedScale * self.lastSpeedReal * self.movingDirection * dt, 0, 0)
        end
      end
    end
    if self.isTurnedOn then
      for i = 1, table.getn(self.rotors) do
        local rotor = self.rotors[i].index
        local rotorRot = -0.008 * self.rotors[i].direction * dt
        rotate(rotor, 0, rotorRot, 0)
      end
      if not self.tedderSoundEnabled and self:getIsActiveForSound() then
        playSample(self.tedderSound, 0, self.tedderSoundVolume, 0)
        setSamplePitch(self.tedderSound, self.tedderSoundPitchOffset)
        self.tedderSoundEnabled = true
      end
    end
  end
  if not self.isTurnedOn and self.tedderSoundEnabled then
    stopSample(self.tedderSound)
    self.tedderSoundEnabled = false
  end
end
function Tedder:draw()
  if self.isTurnedOn then
    g_currentMission:addHelpButtonText(string.format(g_i18n:getText("turn_off_OBJECT"), self.typeDesc), InputBinding.IMPLEMENT_EXTRA)
  else
    g_currentMission:addHelpButtonText(string.format(g_i18n:getText("turn_on_OBJECT"), self.typeDesc), InputBinding.IMPLEMENT_EXTRA)
  end
  if self.wasToFast then
    g_currentMission:addWarning(g_i18n:getText("Dont_drive_to_fast") .. "\n" .. string.format(g_i18n:getText("Cruise_control_levelN"), "2", InputBinding.getButtonKeyName(InputBinding.SPEED_LEVEL2)), 0.092, 0.048)
  end
end
function Tedder:onDetach()
  if self.deactivateOnDetach then
    Tedder.onDeactivate(self)
  end
end
function Tedder:onLeave()
  if self.deactivateOnLeave then
    Tedder.onDeactivate(self)
  end
end
function Tedder:onDeactivate()
  if self.animationEnabled then
    disableAnimTrack(self.animation.animCharSet, 0)
    self.animationEnabled = false
  end
  for k, v in pairs(self.grassParticleSystems) do
    Utils.setEmittingState(v.ps, false)
  end
  self.isTurnedOn = false
end

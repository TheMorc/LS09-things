Trailer = {}
Trailer.TIPSTATE_CLOSED = 0
Trailer.TIPSTATE_OPENING = 1
Trailer.TIPSTATE_OPEN = 2
Trailer.TIPSTATE_CLOSING = 3
function Trailer.prerequisitesPresent(specializations)
  return SpecializationUtil.hasSpecialization(Attachable, specializations)
end
function Trailer:load(xmlFile)
  self.toggleTipState = SpecializationUtil.callSpecializationsFunction("toggleTipState")
  self.onStartTip = SpecializationUtil.callSpecializationsFunction("onStartTip")
  self.onEndTip = SpecializationUtil.callSpecializationsFunction("onEndTip")
  self.allowFillType = Trailer.allowFillType
  self.setFillLevel = SpecializationUtil.callSpecializationsFunction("setFillLevel")
  self.lastFillDelta = 0
  self.fillLevel = 0
  self.capacity = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.capacity"), 0)
  self.minThreshold = 0.05
  self.fillRootNode = Utils.indexToObject(self.components, getXMLString(xmlFile, "vehicle.fillRootNode#index"))
  if self.fillRootNode == nil then
    self.fillRootNode = self.components[1].node
  end
  self.grainPlanes = {}
  local i = 0
  while true do
    local key = string.format("vehicle.grainPlane.node(%d)", i)
    local t = getXMLString(xmlFile, key .. "#type")
    local index = getXMLString(xmlFile, key .. "#index")
    if t == nil or index == nil then
      break
    end
    local node = Utils.indexToObject(self.components, index)
    if node ~= nil then
      setVisibility(node, false)
      if self.defaultGrainPlane == nil then
        self.defaultGrainPlane = node
      end
      self.grainPlanes[t] = node
    end
    i = i + 1
  end
  if self.defaultGrainPlane == nil then
    self.grainPlanes = nil
  end
  self.grainPlaneMinY, self.grainPlaneMaxY = Utils.getVectorFromString(getXMLString(xmlFile, "vehicle.grainPlane#minMaxY"))
  if self.grainPlaneMinY == nil or self.grainPlaneMaxY == nil then
    local grainAnimCurve = AnimCurve:new(linearInterpolator4)
    local keyI = 0
    while true do
      local key = string.format("vehicle.grainPlane.key(%d)", keyI)
      local t = getXMLFloat(xmlFile, key .. "#time")
      local yValue = getXMLFloat(xmlFile, key .. "#y")
      local scaleX, scaleY, scaleZ = Utils.getVectorFromString(getXMLString(xmlFile, key .. "#scale"))
      if y == nil or scaleX == nil or scaleY == nil or scaleZ == nil then
        break
      end
      grainAnimCurve:addKeyframe({
        x = scaleX,
        y = scaleY,
        z = scaleZ,
        w = yValue,
        time = t
      })
      keyI = keyI + 1
    end
    if 0 < keyI then
      self.grainAnimCurve = grainAnimCurve
    end
    self.grainPlaneMinY = 0
    self.grainPlaneMaxY = 0
  end
  self.tipDischargeEndTime = getXMLFloat(xmlFile, "vehicle.tipDischargeEndTime#value")
  local tipAnimRootNode = Utils.indexToObject(self.components, getXMLString(xmlFile, "vehicle.tipAnimation#rootNode"))
  self.tipAnimCharSet = 0
  if tipAnimRootNode ~= nil and tipAnimRootNode ~= 0 then
    self.tipAnimCharSet = getAnimCharacterSet(tipAnimRootNode)
    if self.tipAnimCharSet ~= 0 then
      local clip = getAnimClipIndex(self.tipAnimCharSet, getXMLString(xmlFile, "vehicle.tipAnimation#clip"))
      assignAnimTrackClip(self.tipAnimCharSet, 0, clip)
      setAnimTrackLoopState(self.tipAnimCharSet, 0, false)
      self.tipAnimSpeedScale = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.tipAnimation#speedScale"), 1)
      self.tipAnimDuration = getAnimClipDuration(self.tipAnimCharSet, clip)
      if self.tipDischargeEndTime == nil then
        self.tipDischargeEndTime = self.tipAnimDuration * 2
      end
    end
  end
  self.tipState = Trailer.TIPSTATE_CLOSED
  self.tipReferencePoint = Utils.indexToObject(self.components, getXMLString(xmlFile, "vehicle.tipReferencePoint#index"))
  if self.tipReferencePoint == nil then
    self.tipReferencePoint = self.components[1].node
  end
  self.dischargeParticleSystems = {}
  Utils.loadParticleSystem(xmlFile, self.dischargeParticleSystems, "vehicle.dischargeParticleSystem", self.components, false, nil, self.baseDirectory)
  self.fillTypes = {}
  self.fillTypes[FruitUtil.FRUITTYPE_UNKNOWN] = true
  local fruitTypes = getXMLString(xmlFile, "vehicle.fillTypes#fruitTypes")
  if fruitTypes ~= nil then
    local types = Utils.splitString(" ", fruitTypes)
    for k, v in pairs(types) do
      local desc = FruitUtil.fruitTypes[v]
      if desc ~= nil then
        self.fillTypes[desc.index] = true
      end
    end
  end
  local hydraulicSound = getXMLString(xmlFile, "vehicle.hydraulicSound#file")
  if hydraulicSound ~= nil and hydraulicSound ~= "" then
    self.hydraulicSound = createSample("hydraulicSound")
    loadSample(self.hydraulicSound, hydraulicSound, false)
    self.hydraulicSoundPitchOffset = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.hydraulicSound#pitchOffset"), 1)
    self.hydraulicSoundVolume = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.hydraulicSound#pitchMax"), 2)
    self.hydraulicSoundEnabled = false
  end
  local fillSound = getXMLString(xmlFile, "vehicle.fillSound#file")
  if fillSound ~= nil and fillSound ~= "" then
    self.fillSound = createSample("fillSound")
    loadSample(self.fillSound, fillSound, false)
    self.fillSoundPitchOffset = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.fillSound#pitchOffset"), 1)
    self.fillSoundVolume = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.fillSound#pitchMax"), 2)
    self.fillSoundEnabled = false
  end
  self.currentFillType = FruitUtil.FRUITTYPE_UNKNOWN
  self.allowFillFromAir = Utils.getNoNil(getXMLBool(xmlFile, "vehicle.allowFillFromAir#value"), true)
  self.allowTipDischarge = Utils.getNoNil(getXMLBool(xmlFile, "vehicle.allowTipDischarge#value"), true)
  self.massScale = 9.1E-5 * Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.massScale#value"), 1)
  setUserAttribute(self.fillRootNode, "vehicleType", "Integer", 2)
  self:setFillLevel(0, FruitUtil.FRUITTYPE_UNKNOWN)
end
function Trailer:delete()
  Utils.deleteParticleSystem(self.dischargeParticleSystems)
  if self.hydraulicSound ~= nil then
    delete(self.hydraulicSound)
  end
  if self.fillSound ~= nil then
    delete(self.fillSound)
  end
end
function Trailer:loadFromAttributesAndNodes(xmlFile, key, resetVehicles)
  local fillLevel = getXMLFloat(xmlFile, key .. "#fillLevel")
  local fillType = getXMLString(xmlFile, key .. "#fillType")
  if fillLevel ~= nil and fillType ~= nil then
    local fillTypeDesc = FruitUtil.fruitTypes[fillType]
    if fillTypeDesc ~= nil then
      self:setFillLevel(fillLevel, fillTypeDesc.index)
    end
  end
  return BaseMission.VEHICLE_LOAD_OK
end
function Trailer:getSaveAttributesAndNodes(nodeIdent)
  local fillType = "unknown"
  if self.currentFillType ~= FruitUtil.FRUITTYPE_UNKNOWN then
    fillType = FruitUtil.fruitIndexToDesc[self.currentFillType].name
  end
  local attributes = "fillLevel=\"" .. self.fillLevel .. "\" fillType=\"" .. fillType .. "\""
  return attributes, nil
end
function Trailer:mouseEvent(posX, posY, isDown, isUp, button)
end
function Trailer:keyEvent(unicode, sym, modifier, isDown)
end
function Trailer:update(dt)
  self.lastFillDelta = 0
  if self.tipState == Trailer.TIPSTATE_OPENING or self.tipState == Trailer.TIPSTATE_OPEN then
    local m = self.capacity / (self.tipDischargeEndTime / self.tipAnimSpeedScale)
    local curFill = self.fillLevel
    self:setFillLevel(self.fillLevel - m * dt, self.currentFillType)
    self.lastFillDelta = self.fillLevel - curFill
    g_currentMission.trailerIsTipping = true
    if self.currentFillType ~= FruitUtil.FRUITTYPE_UNKNOWN and self.currentTipTrigger ~= nil then
      if self.currentTipTrigger.isFarmTrigger then
        g_currentMission.missionStats.farmSiloFruitAmount[self.currentFillType] = g_currentMission.missionStats.farmSiloFruitAmount[self.currentFillType] - self.lastFillDelta
      else
        local priceMultiplier = self.currentTipTrigger.priceMultipliers[self.currentFillType]
        local difficultyMultiplier = math.max(3 * (3 - g_currentMission.missionStats.difficulty), 1)
        local money = FruitUtil.fruitIndexToDesc[self.currentFillType].pricePerLiter * priceMultiplier * difficultyMultiplier * self.lastFillDelta
        g_currentMission.missionStats.money = g_currentMission.missionStats.money - money
      end
    end
    if not self.hydraulicSoundEnabled and self.hydraulicSound ~= nil and self:getIsActiveForSound() then
      playSample(self.hydraulicSound, 0, self.hydraulicSoundVolume, 0)
      setSamplePitch(self.hydraulicSound, self.hydraulicSoundPitchOffset - 0.4)
      self.hydraulicSoundEnabled = true
    end
    if not self.fillSoundEnabled and 0 < self.fillLevel and self.fillSound ~= nil and self:getIsActiveForSound() then
      playSample(self.fillSound, 0, self.fillSoundVolume, 0)
      self.fillSoundEnabled = true
    end
    if self.fillSoundEnabled and self.fillLevel == 0 then
      stopSample(self.fillSound)
      self.fillSoundEnabled = false
    end
    if self.tipState == Trailer.TIPSTATE_OPENING then
      if getAnimTrackTime(self.tipAnimCharSet, 0) > self.tipAnimDuration then
        self.tipState = Trailer.TIPSTATE_OPEN
      end
    elseif getAnimTrackTime(self.tipAnimCharSet, 0) > self.tipDischargeEndTime then
      self:onEndTip()
    end
    if self.tipState == Trailer.TIPSTATE_OPEN and self.hydraulicSoundEnabled then
      stopSample(self.hydraulicSound)
      self.hydraulicSoundEnabled = false
    end
  elseif self.tipState == Trailer.TIPSTATE_CLOSING then
    if not self.hydraulicSoundEnabled and self.hydraulicSound ~= nil and self:getIsActiveForSound() then
      playSample(self.hydraulicSound, 0, self.hydraulicSoundVolume, 0)
      setSamplePitch(self.hydraulicSound, self.hydraulicSoundPitchOffset)
      self.hydraulicSoundEnabled = true
    end
    g_currentMission.trailerIsTipping = false
    if 0 > getAnimTrackTime(self.tipAnimCharSet, 0) then
      g_currentMission.allowSteerableMoving = true
      g_currentMission.fixedCamera = false
      self.tipState = Trailer.TIPSTATE_CLOSED
    end
  elseif self.tipState == Trailer.TIPSTATE_CLOSED and self.hydraulicSoundEnabled then
    stopSample(self.hydraulicSound)
    self.hydraulicSoundEnabled = false
  end
  Utils.setEmittingState(self.dischargeParticleSystems, self.lastFillDelta < 0)
  if self.firstTimeRun then
    if self.emptyMass == nil then
      self.emptyMass = getMass(self.fillRootNode)
      self.currentMass = self.emptyMass
    end
    local newMass = self.emptyMass + self.fillLevel * self.massScale
    if newMass ~= self.currentMass then
      setMass(self.fillRootNode, newMass)
      self.currentMass = newMass
      for k, v in pairs(self.components) do
        if v.node == self.fillRootNode then
          if v.centerOfMass ~= nil then
            setCenterOfMass(v.node, v.centerOfMass[1], v.centerOfMass[2], v.centerOfMass[3])
          end
          break
        end
      end
    end
  end
end
function Trailer:draw()
  if self.currentFillType ~= FruitUtil.FRUITTYPE_UNKNOWN then
    local overlay = g_currentMission.fruitOverlays[self.currentFillType]
    if overlay ~= nil then
      g_currentMission.fruitOverlays[self.currentFillType]:render()
    end
  end
end
function Trailer:toggleTipState(currentTipTrigger)
  if self.tipState == 0 then
    self:onStartTip(currentTipTrigger)
  else
    self:onEndTip()
  end
end
function Trailer:onStartTip(currentTipTrigger)
  self.currentTipTrigger = currentTipTrigger
  if self.tipAnimCharSet ~= 0 then
    if 0 > getAnimTrackTime(self.tipAnimCharSet, 0) then
      setAnimTrackTime(self.tipAnimCharSet, 0, 0)
    end
    setAnimTrackSpeedScale(self.tipAnimCharSet, 0, self.tipAnimSpeedScale)
    enableAnimTrack(self.tipAnimCharSet, 0)
  end
  self.tipState = Trailer.TIPSTATE_OPENING
  g_currentMission.allowSteerableMoving = false
  g_currentMission.fixedCamera = true
end
function Trailer:onEndTip()
  self.currentTipTrigger = nil
  if self.tipAnimCharSet ~= 0 then
    if getAnimTrackTime(self.tipAnimCharSet, 0) > self.tipAnimDuration then
      setAnimTrackTime(self.tipAnimCharSet, 0, self.tipAnimDuration)
    end
    setAnimTrackSpeedScale(self.tipAnimCharSet, 0, -self.tipAnimSpeedScale)
    enableAnimTrack(self.tipAnimCharSet, 0)
  end
  self.tipState = Trailer.TIPSTATE_CLOSING
end
function Trailer:allowFillType(fillType, allowEmptying)
  local allowed = false
  if self.fillTypes[fillType] then
    if self.currentFillType ~= FruitUtil.FRUITTYPE_UNKNOWN then
      if self.currentFillType ~= fillType then
        if self.fillLevel / self.capacity <= self.minThreshold then
          allowed = true
          if allowEmptying then
            self.fillLevel = 0
          end
        end
      else
        allowed = true
      end
    else
      allowed = true
    end
  end
  return allowed
end
function Trailer:setFillLevel(fillLevel, fillType)
  if not self:allowFillType(fillType, false) then
    return
  end
  self.currentFillType = fillType
  self.fillLevel = fillLevel
  if self.fillLevel > self.capacity then
    self.fillLevel = self.capacity
  end
  if self.fillLevel < 0 then
    self.fillLevel = 0
    self.currentFillType = FruitUtil.FRUITTYPE_UNKNOWN
  end
  if self.currentGrainPlane ~= nil then
    setVisibility(self.currentGrainPlane, false)
  end
  if self.grainPlanes ~= nil and self.defaultGrainPlane ~= nil and fillType ~= FruitUtil.FRUITTYPE_UNKNOWN then
    local fillTypeName = FruitUtil.fruitIndexToDesc[fillType].name
    local grainPlane = self.grainPlanes[fillTypeName]
    if grainPlane == nil then
      grainPlane = self.defaultGrainPlane
    end
    local yTranslation
    if self.grainAnimCurve then
      local scaleX, scaleY, scaleZ, yTrans = self.grainAnimCurve:get(self.fillLevel / self.capacity)
      yTranslation = yTrans
      setScale(grainPlane, scaleX, scaleY, scaleZ)
    else
      local m = (self.grainPlaneMaxY - self.grainPlaneMinY) / self.capacity
      yTranslation = m * self.fillLevel + self.grainPlaneMinY
    end
    local xPos, yPos, zPos = getTranslation(grainPlane)
    setTranslation(grainPlane, xPos, yTranslation, zPos)
    setVisibility(grainPlane, self.fillLevel > 0)
    self.currentGrainPlane = grainPlane
  end
end
function Trailer:onDetach()
  if self.deactivateOnDetach then
    Trailer.onDeactivate(self)
  else
    Trailer.onDeactivateSounds(self)
  end
end
function Trailer:onLeave()
  if self.deactivateOnLeave then
    Trailer.onDeactivate(self)
  else
    Trailer.onDeactivateSounds(self)
  end
end
function Trailer:onDeactivate()
  Trailer.onDeactivateSounds(self)
end
function Trailer:onDeactivateSounds()
  if self.fillSoundEnabled and self.fillLevel == 0 then
    stopSample(self.fillSound)
    self.fillSoundEnabled = false
  end
  if self.hydraulicSoundEnabled then
    stopSample(self.hydraulicSound)
    self.hydraulicSoundEnabled = false
  end
end

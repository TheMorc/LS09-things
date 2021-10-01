Combine = {}
function Combine.prerequisitesPresent(specializations)
  Vehicle.registerJointType("cutter")
  Vehicle.registerJointType("trailerCombine")
  return SpecializationUtil.hasSpecialization(Steerable, specializations)
end
function Combine:load(xmlFile)
  self.allowGrainTankFruitType = Combine.allowGrainTankFruitType
  self.emptyGrainTankIfLowFillLevel = Combine.emptyGrainTankIfLowFillLevel
  self.setGrainTankFillLevel = SpecializationUtil.callSpecializationsFunction("setGrainTankFillLevel")
  self.startThreshing = SpecializationUtil.callSpecializationsFunction("startThreshing")
  self.stopThreshing = SpecializationUtil.callSpecializationsFunction("stopThreshing")
  self.openPipe = SpecializationUtil.callSpecializationsFunction("openPipe")
  self.closePipe = SpecializationUtil.callSpecializationsFunction("closePipe")
  self.findTrailerRaycastCallback = Combine.findTrailerRaycastCallback
  local threshingStartSound = getXMLString(xmlFile, "vehicle.threshingStartSound#file")
  if threshingStartSound ~= nil and threshingStartSound ~= "" then
    threshingStartSound = Utils.getFilename(threshingStartSound, self.baseDirectory)
    self.threshingStartSound = createSample("threshingStartSound")
    loadSample(self.threshingStartSound, threshingStartSound, false)
    self.threshingStartSoundPitchOffset = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.threshingStartSound#pitchOffset"), 1)
    self.threshingStartSoundPitchScale = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.threshingStartSound#pitchScale"), 0)
    self.threshingStartSoundPitchMax = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.threshingStartSound#pitchMax"), 2)
  end
  local threshingSound = getXMLString(xmlFile, "vehicle.threshingSound#file")
  if threshingSound ~= nil and threshingSound ~= "" then
    threshingSound = Utils.getFilename(threshingSound, self.baseDirectory)
    self.threshingSound = createSample("threshingSound")
    loadSample(self.threshingSound, threshingSound, false)
    self.threshingSoundPitchOffset = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.threshingSound#pitchOffset"), 1)
    self.threshingSoundPitchScale = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.threshingSound#pitchScale"), 0)
    self.threshingSoundPitchMax = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.threshingSound#pitchMax"), 2)
  end
  local threshingStopSound = getXMLString(xmlFile, "vehicle.threshingStopSound#file")
  if threshingStopSound ~= nil and threshingStopSound ~= "" then
    threshingStopSound = Utils.getFilename(threshingStopSound, self.baseDirectory)
    self.threshingStopSound = createSample("threshingStopSound")
    loadSample(self.threshingStopSound, threshingStopSound, false)
    self.threshingStopSoundPitchOffset = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.threshingStopSound#pitchOffset"), 1)
    self.threshingStopSoundPitchScale = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.threshingStopSound#pitchScale"), 0)
    self.threshingStopSoundPitchMax = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.threshingStopSound#pitchMax"), 2)
  end
  local pipeSound = getXMLString(xmlFile, "vehicle.pipeSound#file")
  if pipeSound ~= nil and pipeSound ~= "" then
    pipeSound = Utils.getFilename(pipeSound, self.baseDirectory)
    self.pipeSound = createSample("pipeSound")
    loadSample(self.pipeSound, pipeSound, false)
    self.pipeSoundPitchOffset = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.pipeSound#pitchOffset"), 1)
    self.pipeSoundPitchScale = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.pipeSound#pitchScale"), 0)
    self.pipeSoundPitchMax = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.pipeSound#pitchMax"), 2)
  end
  self.chopperBlind = Utils.indexToObject(self.components, getXMLString(xmlFile, "vehicle.chopperBlind#index"))
  self.pipeParticleSystems = {}
  self.pipe = Utils.indexToObject(self.components, getXMLString(xmlFile, "vehicle.pipe#index"))
  if self.pipe ~= nil then
    self.pipeRaycastNode = Utils.indexToObject(self.components, getXMLString(xmlFile, "vehicle.pipe#raycastNodeIndex"))
    local i = 0
    while true do
      local key = string.format("vehicle.pipeParticleSystems.pipeParticleSystem(%d)", i)
      local t = getXMLString(xmlFile, key .. "#type")
      if t == nil then
        break
      end
      local desc = FruitUtil.fruitTypes[t]
      if desc ~= nil then
        local currentPS = {}
        local particleNode = Utils.loadParticleSystem(xmlFile, currentPS, key, self.pipe, false, "$data/vehicles/particleSystems/wheatParticleSystem.i3d", self.baseDirectory)
        self.pipeParticleSystems[desc.index] = currentPS
        if self.defaultPipeParticleSystem == nil then
          self.defaultPipeParticleSystem = currentPS
        end
        if self.pipeRaycastNode == nil then
          self.pipeRaycastNode = particleNode
        end
      end
      i = i + 1
    end
    if self.pipeRaycastNode == nil then
      self.pipeRaycastNode = self.components[1].node
    end
  end
  self.allowsThreshing = true
  self.isThreshingStarted = false
  self.pipeLight = Utils.indexToObject(self.components, getXMLString(xmlFile, "vehicle.pipeLight#index"))
  self.pipeFlapLid = Utils.indexToObject(self.components, getXMLString(xmlFile, "vehicle.pipeFlapLid#index"))
  self.rotorFan = Utils.indexToObject(self.components, getXMLString(xmlFile, "vehicle.rotorFan#index"))
  self.grainTankCapacity = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.grainTankCapacity"), 200)
  self.grainTankUnloadingCapacity = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.grainTankUnloadingCapacity"), 10)
  self.grainTankCrowded = false
  self.grainTankPlanes = {}
  local i = 0
  while true do
    local key = string.format("vehicle.grainTankPlane.node(%d)", i)
    local t = getXMLString(xmlFile, key .. "#type")
    local index = getXMLString(xmlFile, key .. "#index")
    if t == nil or index == nil then
      break
    end
    local node = Utils.indexToObject(self.components, index)
    if node ~= nil then
      setVisibility(node, false)
      local entry = {}
      entry.node = node
      local windowNode = Utils.indexToObject(self.components, getXMLString(xmlFile, key .. "#windowIndex"))
      if windowNode ~= nil then
        entry.windowNode = windowNode
        setVisibility(windowNode, false)
      end
      if self.defaultGrainTankPlane == nil then
        self.defaultGrainTankPlane = entry
      end
      self.grainTankPlanes[t] = entry
    end
    i = i + 1
  end
  if self.defaultGrainTankPlane == nil then
    self.grainTankPlanes = nil
  end
  self.grainTankPlaneMinY, self.grainTankPlaneMaxY = Utils.getVectorFromString(getXMLString(xmlFile, "vehicle.grainTankPlane#minMaxY"))
  if self.grainTankPlaneMinY == nil or self.grainTankPlaneMaxY == nil then
    local animCurve = AnimCurve:new(linearInterpolator4)
    local i = 0
    while true do
      local key = string.format("vehicle.grainTankPlane.key(%d)", i)
      local t = getXMLFloat(xmlFile, key .. "#time")
      local yValue = getXMLFloat(xmlFile, key .. "#y")
      local scaleX, scaleY, scaleZ = Utils.getVectorFromString(getXMLString(xmlFile, key .. "#scale"))
      if y == nil or scaleX == nil or scaleY == nil or scaleZ == nil then
        break
      end
      animCurve:addKeyframe({
        x = scaleX,
        y = scaleY,
        z = scaleZ,
        w = yValue,
        time = t
      })
      i = i + 1
    end
    if 0 < i then
      self.grainTankPlaneAnimCurve = animCurve
    end
    self.grainTankPlaneMinY = 0
    self.grainTankPlaneMaxY = 0
  end
  self.grainTankPlaneWindowMinY, self.grainTankPlaneWindowMaxY = Utils.getVectorFromString(getXMLString(xmlFile, "vehicle.grainTankPlane#windowMinMaxY"))
  if self.grainTankPlaneWindowMinY == nil or self.grainTankPlaneWindowMaxY == nil then
    local animCurve = AnimCurve:new(linearInterpolatorN)
    local i = 0
    while true do
      local key = string.format("vehicle.grainTankPlane.windowKey(%d)", i)
      local t = getXMLFloat(xmlFile, key .. "#time")
      local yValue = getXMLFloat(xmlFile, key .. "#y")
      local visibility = getXMLBool(xmlFile, key .. "#visibility")
      local scaleX, scaleY, scaleZ = Utils.getVectorFromString(getXMLString(xmlFile, key .. "#scale"))
      if y == nil or scaleX == nil or scaleY == nil or scaleZ == nil or visibility == nil then
        break
      end
      animCurve:addKeyframe({
        v = {
          scaleX,
          scaleY,
          scaleZ,
          yValue
        },
        time = t
      })
      i = i + 1
    end
    if 0 < i then
      self.grainTankPlaneWindowAnimCurve = animCurve
    end
    self.grainTankPlaneWindowMinY = 0
    self.grainTankPlaneWindowMaxY = 0
  end
  self.grainTankPlaneWindowStartY = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.grainTankPlane#windowStartY"), 0)
  self.chopperParticleSystems = {}
  local i = 0
  while true do
    local key = string.format("vehicle.chopperParticleSystems.chopperParticleSystem(%d)", i)
    local t = getXMLString(xmlFile, key .. "#type")
    if t == nil then
      break
    end
    local desc = FruitUtil.fruitTypes[t]
    if desc ~= nil then
      local currentPS = {}
      local particleNode = Utils.loadParticleSystem(xmlFile, currentPS, key, self.components, false, "$data/vehicles/particleSystems/threshingChopperParticleSystem.i3d", self.baseDirectory)
      self.chopperParticleSystems[desc.index] = currentPS
      if self.defaultChopperParticleSystem == nil then
        self.defaultChopperParticleSystem = currentPS
      end
    end
    i = i + 1
  end
  self.chopperToggleTime = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.chopperParticleSystems#toggleTime"), 2500)
  self.chopperEnableTime = nil
  self.chopperDisableTime = nil
  self.strawParticleSystems = {}
  local i = 0
  while true do
    local key = string.format("vehicle.strawParticleSystems.strawParticleSystem(%d)", i)
    local t = getXMLString(xmlFile, key .. "#type")
    if t == nil then
      break
    end
    local desc = FruitUtil.fruitTypes[t]
    if desc ~= nil then
      local currentPS = {}
      local particleNode = Utils.loadParticleSystem(xmlFile, currentPS, key, self.components, false, "$data/vehicles/particleSystems/threshingStrawParticleSystem.i3d", self.baseDirectory)
      self.strawParticleSystems[desc.index] = currentPS
      if self.defaultStrawParticleSystem == nil then
        self.defaultStrawParticleSystem = currentPS
      end
    end
    i = i + 1
  end
  self.strawToggleTime = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.strawParticleSystems#toggleTime"), 2500)
  self.strawEnableTime = nil
  self.strawDisableTime = nil
  self.strawEmitState = false
  self.combineSize = Utils.getNoNil(getXMLInt(xmlFile, "vehicle.combineSize"), 1)
  local numStrawAreas = Utils.getNoNil(getXMLInt(xmlFile, "vehicle.strawAreas#count"), 0)
  self.strawAreas = {}
  for i = 1, numStrawAreas do
    local area = {}
    local areanamei = string.format("vehicle.strawAreas.strawArea%d", i)
    area.start = Utils.indexToObject(self.components, getXMLString(xmlFile, areanamei .. "#startIndex"))
    area.width = Utils.indexToObject(self.components, getXMLString(xmlFile, areanamei .. "#widthIndex"))
    area.height = Utils.indexToObject(self.components, getXMLString(xmlFile, areanamei .. "#heightIndex"))
    table.insert(self.strawAreas, area)
  end
  self.isThreshing = false
  self.chopperActivated = false
  self.defaultChopperState = false
  self.pipeOpening = false
  self.pipeOpen = false
  self.pipeClose = true
  self.pipeParticleActivated = false
  self.threshingScale = 1
  self.grainTankFruitTypes = {}
  self.grainTankFruitTypes[FruitUtil.FRUITTYPE_UNKNOWN] = true
  local fruitTypes = getXMLString(xmlFile, "vehicle.grainTankFruitTypes#fruitTypes")
  if fruitTypes ~= nil then
    local types = Utils.splitString(" ", fruitTypes)
    for k, v in pairs(types) do
      local desc = FruitUtil.fruitTypes[v]
      if desc ~= nil then
        self.grainTankFruitTypes[desc.index] = true
      end
    end
  end
  self.currentGrainTankFruitType = FruitUtil.FRUITTYPE_UNKNOWN
  self.grainTankFillLevel = 0
  self:setGrainTankFillLevel(0, FruitUtil.FRUITTYPE_UNKNOWN)
  self.minThreshold = 0.05
  self.speedDisplayScale = 1
  self.drawFillLevel = true
  self.attachedCutters = {}
  self.numAttachedCutters = 0
  self.lastLastArea = 0
  self.lastArea = 0
end
function Combine:delete()
  for k, v in pairs(self.pipeParticleSystems) do
    Utils.deleteParticleSystem(v)
  end
  for k, v in pairs(self.chopperParticleSystems) do
    Utils.deleteParticleSystem(v)
  end
  for k, v in pairs(self.strawParticleSystems) do
    Utils.deleteParticleSystem(v)
  end
  if self.threshingStartSound ~= nil then
    delete(self.threshingStartSound)
  end
  if self.threshingSound ~= nil then
    delete(self.threshingSound)
  end
  if self.threshingStopSound ~= nil then
    delete(self.threshingStopSound)
  end
  if self.pipeSound ~= nil then
    delete(self.pipeSound)
  end
end
function Combine:loadFromAttributesAndNodes(xmlFile, key, resetVehicles)
  local fillLevel = getXMLFloat(xmlFile, key .. "#grainTankFillLevel")
  local fruitType = getXMLString(xmlFile, key .. "#grainTankFruitType")
  if fillLevel ~= nil and fruitType ~= nil then
    local fruitTypeDesc = FruitUtil.fruitTypes[fruitType]
    if fruitTypeDesc ~= nil then
      self:setGrainTankFillLevel(fillLevel, fruitTypeDesc.index)
    end
  end
  return BaseMission.VEHICLE_LOAD_OK
end
function Combine:getSaveAttributesAndNodes(nodeIdent)
  local fruitType = "unknown"
  if self.currentGrainTankFruitType ~= FruitUtil.FRUITTYPE_UNKNOWN then
    fruitType = FruitUtil.fruitIndexToDesc[self.currentGrainTankFruitType].name
  end
  local attributes = "grainTankFillLevel=\"" .. self.grainTankFillLevel .. "\" grainTankFruitType=\"" .. fruitType .. "\""
  return attributes, nil
end
function Combine:mouseEvent(posX, posY, isDown, isUp, button)
end
function Combine:keyEvent(unicode, sym, modifier, isDown)
end
function Combine:update(dt)
  if self:getIsActive() then
    if self.isThreshingStarted and self.playThreshingSound and self:getIsActiveForSound() and self.threshingSound ~= nil and self.playThreshingSoundTime <= self.time then
      playSample(self.threshingSound, 0, 1, 0)
      self.playThreshingSound = false
      self.threshingSoundActive = true
    end
    if self:getIsActiveForInput() then
      if self.grainTankFillLevel < self.grainTankCapacity and InputBinding.hasEvent(InputBinding.ACTIVATE_THRESHING) then
        if self.isThreshing then
          self:stopThreshing()
        else
          self:startThreshing()
        end
      end
      if InputBinding.hasEvent(InputBinding.EMPTY_GRAIN) then
        if self.pipeOpening then
          self:closePipe()
        else
          self:openPipe()
        end
      end
    end
    if self.grainTankFillLevel >= self.grainTankCapacity then
      self:stopThreshing()
    end
    if self.isThreshing and self.rotorFan ~= nil then
      rotate(self.rotorFan, dt * 0.005, 0, 0)
    end
    local disableChopperEmit = true
    local disableStrawEmit = true
    if self.isThreshing then
      local lastArea = 0
      local fruitType = FruitUtil.FRUITTYPE_UNKNOWN
      for cutter, implement in pairs(self.attachedCutters) do
        if cutter.reelStarted and 0 < cutter.lastArea then
          for cutter, implement in pairs(self.attachedCutters) do
            cutter:setFruitType(cutter.currentFruitType)
            self.currentGrainTankFruitType = cutter.currentFruitType
          end
          fruitType = cutter.currentFruitType
          lastArea = lastArea + cutter.lastArea
        end
      end
      self.lastArea = lastArea
      if 0 < lastArea then
        local fruitDesc = FruitUtil.fruitIndexToDesc[fruitType]
        if fruitDesc.hasStraw then
          self.chopperActivated = false
        else
          self.chopperActivated = true
        end
        if self.chopperActivated then
          if self.chopperEnableTime == nil then
            self.chopperEnableTime = self.time + self.chopperToggleTime
          else
            self.chopperDisableTime = nil
          end
          disableChopperEmit = false
        else
          if self.strawEnableTime == nil then
            self.strawEnableTime = self.time + self.strawToggleTime
          else
            self.strawDisableTime = nil
          end
          disableStrawEmit = false
        end
        local pixelToQm = 0.25 / g_currentMission.maxFruitValue
        local literPerQm = 1
        if fruitType ~= FruitUtil.FRUITTYPE_UNKNOWN then
          literPerQm = FruitUtil.fruitIndexToDesc[fruitType].literPerQm * (1 + 0.5 * (3 - g_currentMission.missionStats.difficulty))
        end
        local qm = lastArea * pixelToQm
        local newFillLevel = self.grainTankFillLevel + qm * literPerQm * self.threshingScale
        self:setGrainTankFillLevel(newFillLevel, fruitType)
      end
    end
    if disableChopperEmit and self.chopperDisableTime == nil then
      self.chopperDisableTime = self.time + self.chopperToggleTime
    end
    if disableStrawEmit and self.strawDisableTime == nil then
      self.strawDisableTime = self.time + self.strawToggleTime
    end
    if 0 >= self.grainTankFillLevel then
      for cutter, implement in pairs(self.attachedCutters) do
        cutter:resetFruitType()
      end
      self.currentGrainTankFruitType = FruitUtil.FRUITTYPE_UNKNOWN
    end
    local chopperBlindRotationSpeed = 0.001
    local minRotX = -1.4485805555555555
    if self.chopperBlind ~= nil then
      local x, y, z = getRotation(self.chopperBlind)
      if self.chopperActivated then
        x = x - dt * chopperBlindRotationSpeed
        if minRotX > x then
          x = minRotX
        end
      else
        x = x + dt * chopperBlindRotationSpeed
        if 0 < x then
          x = 0
        end
      end
      setRotation(self.chopperBlind, x, y, z)
    end
    local pipeRotationSpeed = 6.0E-4
    local pipeMinRotY = -1.57075
    local pipeMaxRotX = 0.17452777777777778
    local pipeXRotationSpeed = 6.0E-5
    if self.pipe ~= nil then
      local x, y, z = getRotation(self.pipe)
      if self.pipeOpening then
        y = y - dt * pipeRotationSpeed
        if pipeMinRotY > y then
          y = pipeMinRotY
        end
        x = x + dt * pipeXRotationSpeed
        if pipeMaxRotX < x then
          x = pipeMaxRotX
        end
      else
        y = y + dt * pipeRotationSpeed
        if 0 < y then
          y = 0
        end
        x = x - dt * pipeXRotationSpeed
        if x < 0 then
          x = 0
        end
      end
      setRotation(self.pipe, x, y, z)
      setRotation(self.pipeFlapLid, 0, y, 0)
      self.pipeOpen = math.abs(pipeMinRotY - y) < 0.01
      self.pipeClose = x == 0 and y == 0
    end
    if self.motor ~= nil then
      if self.motor.speedLevel == 1 then
        self.speedDisplayScale = 0.5
      elseif self.motor.speedLevel == 2 then
        self.speedDisplayScale = 0.6
      else
        self.speedDisplayScale = 1
      end
    end
    if (not self.pipeOpen or not self.pipeClose) and self.pipeSound ~= nil and not self.pipeSoundEnabled and self:getIsActiveForSound() then
      setSamplePitch(self.pipeSound, self.pipeSoundPitchOffset)
      playSample(self.pipeSound, 0, 1, 0)
      self.pipeSoundEnabled = true
    end
    if self.pipeOpen and self.pipeSound ~= nil and self.pipeSoundEnabled then
      stopSample(self.pipeSound)
      self.pipeSoundEnabled = false
    end
    if self.pipeClose and self.pipeSound ~= nil and self.pipeSoundEnabled then
      stopSample(self.pipeSound)
      self.pipeSoundEnabled = false
    end
    if self.chopperEnableTime ~= nil and self.chopperEnableTime <= self.time then
      if self.currentChopperParticleSystem ~= nil then
        Utils.setEmittingState(self.currentChopperParticleSystem, false)
      end
      self.currentChopperParticleSystem = self.chopperParticleSystems[self.currentGrainTankFruitType]
      if self.currentChopperParticleSystem == nil then
        self.currentChopperParticleSystem = self.defaultChopperParticleSystem
      end
      Utils.setEmittingState(self.currentChopperParticleSystem, true)
      self.chopperEnableTime = nil
    end
    if self.strawEnableTime ~= nil and self.strawEnableTime <= self.time then
      if self.currentStrawParticleSystem ~= nil then
        Utils.setEmittingState(self.currentStrawParticleSystem, false)
      end
      self.currentStrawParticleSystem = self.strawParticleSystems[self.currentGrainTankFruitType]
      if self.currentStrawParticleSystem == nil then
        self.currentStrawParticleSystem = self.defaultStrawParticleSystem
      end
      Utils.setEmittingState(self.currentStrawParticleSystem, true)
      self.strawEnableTime = nil
      self.strawEmitState = true
    end
    if self.strawEmitState then
      for k, strawArea in pairs(self.strawAreas) do
        local x, y, z = getWorldTranslation(strawArea.start)
        local x1, y1, z1 = getWorldTranslation(strawArea.width)
        local x2, y2, z2 = getWorldTranslation(strawArea.height)
        local old, total = Utils.getFruitWindrowArea(self.currentGrainTankFruitType, x, z, x1, z1, x2, z2)
        local value = 1 + math.floor(old / total + 0.7)
        value = math.min(value, g_currentMission.maxWindrowValue)
        Utils.updateFruitWindrowArea(self.currentGrainTankFruitType, x, z, x1, z1, x2, z2, value, true)
      end
    end
  end
  if self.chopperDisableTime ~= nil and self.chopperDisableTime <= self.time then
    if self.currentChopperParticleSystem ~= nil then
      Utils.setEmittingState(self.currentChopperParticleSystem, false)
    end
    self.currentChopperParticleSystem = self.chopperParticleSystems[self.currentGrainTankFruitType]
    if self.currentChopperParticleSystem == nil then
      self.currentChopperParticleSystem = self.defaultChopperParticleSystem
    end
    Utils.setEmittingState(self.currentChopperParticleSystem, false)
    self.chopperDisableTime = nil
  end
  if self.strawDisableTime ~= nil and self.strawDisableTime <= self.time then
    if self.currentStrawParticleSystem ~= nil then
      Utils.setEmittingState(self.currentStrawParticleSystem, false)
    end
    self.currentStrawParticleSystem = self.strawParticleSystems[self.currentGrainTankFruitType]
    if self.currentStrawParticleSystem == nil then
      self.currentStrawParticleSystem = self.defaultStrawParticleSystem
    end
    Utils.setEmittingState(self.currentStrawParticleSystem, false)
    self.strawDisableTime = nil
    self.strawEmitState = false
  end
  self.lastUnloadingTrailer = nil
  self.pipeParticleActivated = false
  if self.pipeOpen and 0 < self.grainTankFillLevel then
    self.pipeParticleActivated = true
    self.trailerFound = 0
    local x, y, z = getWorldTranslation(self.pipeRaycastNode)
    raycastAll(x, y, z, 0, -1, 0, "findTrailerRaycastCallback", 10, self)
    local trailer = g_currentMission.objectToTrailer[self.trailerFound]
    self.lastUnloadingTrailer = trailer
    if not (self.trailerFound ~= 0 and trailer ~= nil and trailer:allowFillType(self.currentGrainTankFruitType, true)) or not trailer.allowFillFromAir then
      self.pipeParticleActivated = false
    else
      local deltaLevel = self.grainTankUnloadingCapacity * dt / 1000
      deltaLevel = math.min(deltaLevel, trailer.capacity - trailer.fillLevel)
      self.grainTankFillLevel = self.grainTankFillLevel - deltaLevel
      if 0 >= self.grainTankFillLevel then
        deltaLevel = deltaLevel + self.grainTankFillLevel
        self.grainTankFillLevel = 0
        self.pipeParticleActivated = false
      end
      if deltaLevel == 0 then
        self.pipeParticleActivated = false
      end
      self:setGrainTankFillLevel(self.grainTankFillLevel, self.currentGrainTankFruitType)
      trailer:setFillLevel(trailer.fillLevel + deltaLevel, self.currentGrainTankFruitType)
    end
  end
  if self.currentGrainTankFruitType ~= FruitUtil.FRUITTYPE_UNKNOWN then
    if self.currentPipeParticleSystem ~= nil then
      Utils.setEmittingState(self.currentPipeParticleSystem, false)
    end
    if self.pipeParticleActivated then
      self.currentPipeParticleSystem = self.pipeParticleSystems[self.currentGrainTankFruitType]
      if self.currentPipeParticleSystem == nil then
        self.currentPipeParticleSystem = self.defaultPipeParticleSystem
      end
      Utils.setEmittingState(self.currentPipeParticleSystem, true)
    end
  end
end
function Combine:draw()
  local percent = self.grainTankFillLevel / self.grainTankCapacity * 100
  if self.drawFillLevel then
    self:drawGrainLevel(self.grainTankFillLevel, self.grainTankCapacity, 95)
  end
  if self.pipeOpen and not self.pipeParticleActivated and self.grainTankFillLevel > 0 then
    g_currentMission:addExtraPrintText(g_i18n:getText("Move_the_pipe_over_a_trailer"))
  elseif self.grainTankFillLevel == self.grainTankCapacity then
    g_currentMission:addExtraPrintText(g_i18n:getText("Dump_corn_to_continue_threshing"))
  end
  if 0 < self.numAttachedCutters then
    if self.isThreshing then
      g_currentMission:addHelpButtonText(g_i18n:getText("Turn_off_cutter"), InputBinding.ACTIVATE_THRESHING)
    else
      g_currentMission:addHelpButtonText(g_i18n:getText("Turn_on_cutter"), InputBinding.ACTIVATE_THRESHING)
    end
  end
  if self.pipeOpening then
    g_currentMission:addHelpButtonText(g_i18n:getText("Pipe_in"), InputBinding.EMPTY_GRAIN)
  elseif 80 < percent then
    g_currentMission:addHelpButtonText(g_i18n:getText("Dump_corn"), InputBinding.EMPTY_GRAIN)
  end
  if self.currentGrainTankFruitType ~= FruitUtil.FRUITTYPE_UNKNOWN then
    g_currentMission.fruitOverlays[self.currentGrainTankFruitType]:render()
  end
end
function Combine:onEnter()
  if self.isThreshingStarted then
    self.playThreshingSound = true
  end
end
function Combine:onLeave()
  if self.deactivateOnLeave then
    Combine.onDeactivate(self)
  else
    Combine.onDeactivateSounds(self)
  end
end
function Combine:onDeactivate()
  self:stopThreshing()
  for k, v in pairs(self.chopperParticleSystems) do
    Utils.setEmittingState(v, false)
  end
  for k, v in pairs(self.strawParticleSystems) do
    Utils.setEmittingState(v, false)
  end
  self.chopperEnableTime = nil
  self.chopperDisableTime = nil
  self.strawEnableTime = nil
  self.strawDisableTime = nil
  self.strawEmitState = false
  Combine.onDeactivateSounds(self)
end
function Combine:onDeactivateSounds()
  if self.pipeSound ~= nil and self.pipeSoundEnabled then
    stopSample(self.pipeSound)
    self.pipeSoundEnabled = false
  end
  if self.threshingSound ~= nil then
    stopSample(self.threshingSound)
  end
end
function Combine:attachImplement(implement)
  local object = implement.object
  if object.attacherJoint.jointType == Vehicle.JOINTTYPE_CUTTER then
    self.attachedCutters[object] = implement
    self.numAttachedCutters = self.numAttachedCutters + 1
    object:setFruitType(self.currentGrainTankFruitType)
  end
end
function Combine:detachImplement(implementIndex)
  local object = self.attachedImplements[implementIndex].object
  if object.attacherJoint.jointType == Vehicle.JOINTTYPE_CUTTER then
    self.numAttachedCutters = self.numAttachedCutters - 1
    if self.numAttachedCutters == 0 then
      self:stopThreshing()
    end
    self.attachedCutters[object] = nil
  end
end
function Combine:allowGrainTankFruitType(fruitType)
  local allowed = false
  if self.grainTankFruitTypes[fruitType] then
    if self.currentGrainTankFruitType ~= FruitUtil.FRUITTYPE_UNKNOWN then
      if self.currentGrainTankFruitType ~= fruitType then
        if self.grainTankFillLevel / self.grainTankCapacity <= self.minThreshold then
          allowed = true
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
function Combine:emptyGrainTankIfLowFillLevel()
  if self.grainTankFillLevel / self.grainTankCapacity <= self.minThreshold then
    self.grainTankFillLevel = 0
  end
end
function Combine:setGrainTankFillLevel(fillLevel, fruitType)
  if not self:allowGrainTankFruitType(fruitType) then
    return
  end
  self.grainTankFillLevel = Utils.clamp(fillLevel, 0, self.grainTankCapacity)
  if self.currentGrainTankFruitType ~= fruitType then
    self.currentGrainTankFruitType = fruitType
    if self.currentGrainTankPlane ~= nil then
      setVisibility(self.currentGrainTankPlane, false)
    end
    if self.currentGrainTankPlaneWindow ~= nil then
      setVisibility(self.currentGrainTankPlaneWindow, false)
    end
  end
  if self.grainTankPlanes ~= nil and self.defaultGrainTankPlane ~= nil and fruitType ~= FruitUtil.FRUITTYPE_UNKNOWN then
    local fruitTypeName = FruitUtil.fruitIndexToDesc[fruitType].name
    local grainPlane = self.grainTankPlanes[fruitTypeName]
    if grainPlane == nil then
      grainPlane = self.defaultGrainTankPlane
    end
    if grainPlane.node ~= nil then
      local yTranslation = 0
      if self.grainTankPlaneAnimCurve then
        local scaleX, scaleY, scaleZ, yTrans = self.grainTankPlaneAnimCurve:get(self.grainTankFillLevel / self.grainTankCapacity)
        yTranslation = yTrans
        setScale(grainPlane.node, scaleX, scaleY, scaleZ)
      else
        local m = (self.grainTankPlaneMaxY - self.grainTankPlaneMinY) / self.grainTankCapacity
        yTranslation = m * self.grainTankFillLevel + self.grainTankPlaneMinY
      end
      local xPos, yPos, zPos = getTranslation(grainPlane.node)
      setTranslation(grainPlane.node, xPos, yTranslation, zPos)
      setVisibility(grainPlane.node, self.grainTankFillLevel > 0)
      self.currentGrainTankPlane = grainPlane.node
    end
    if grainPlane.windowNode ~= nil then
      local yTranslation = 0
      if self.grainTankPlaneWindowAnimCurve then
        local scaleX, scaleY, scaleZ, yTrans, visiblity = self.grainTankPlaneWindowAnimCurve:get(self.grainTankFillLevel / self.grainTankCapacity)
        yTranslation = yTrans
        setScale(grainPlane.windowNode, scaleX, scaleY, scaleZ)
        setVisibility(self.grainPlaneWindow, visiblity)
      else
        local m = (self.grainTankPlaneMaxY - self.grainTankPlaneMinY) / self.grainTankCapacity
        local startFillLevel = (self.grainTankPlaneWindowStartY - self.grainTankPlaneMinY) / m
        local yTranslation = math.min(m * (self.grainTankFillLevel - startFillLevel) + self.grainTankPlaneWindowMinY, self.grainTankPlaneWindowMaxY)
        setVisibility(grainPlane.windowNode, startFillLevel <= self.grainTankFillLevel)
      end
      local xPos, yPos, zPos = getTranslation(grainPlane.windowNode)
      setTranslation(grainPlane.windowNode, xPos, yTranslation, zPos)
      self.currentGrainTankPlaneWindow = grainPlane.windowNode
    end
  end
end
function Combine:startThreshing()
  if not self.isThreshing and self.numAttachedCutters > 0 then
    self.chopperActivated = self.defaultChopperState
    self.isThreshing = true
    for cutter, implement in pairs(self.attachedCutters) do
      local jointDesc = self.attacherJoints[implement.jointDescIndex]
      jointDesc.moveDown = true
      cutter:setReelSpeed(0.003)
      cutter:onStartReel()
    end
    if not self.isThreshingStarted then
      self.isThreshingStarted = true
      local threshingSoundOffset = 0
      if self.threshingStartSound ~= nil and self:getIsActiveForSound() then
        setSamplePitch(self.threshingStartSound, self.threshingStartSoundPitchOffset)
        playSample(self.threshingStartSound, 1, 1, 0)
        threshingSoundOffset = getSampleDuration(self.threshingStartSound)
      end
      self.playThreshingSound = true
      self.playThreshingSoundTime = self.time + threshingSoundOffset
    end
  end
end
function Combine:stopThreshing()
  if self.isThreshing then
    self.isThreshingStarted = false
    self.playThreshingSound = false
    if self.threshingSound ~= nil then
      stopSample(self.threshingSound)
    end
    if self.threshingStopSound ~= nil and self.threshingSoundActive and self:getIsActiveForSound() then
      setSamplePitch(self.threshingStopSound, self.threshingStopSoundPitchOffset)
      playSample(self.threshingStopSound, 1, 1, 0)
      self.threshingSoundActive = false
    end
    self.chopperActivated = false
    self.isThreshing = false
    for cutter, implement in pairs(self.attachedCutters) do
      local jointDesc = self.attacherJoints[implement.jointDescIndex]
      jointDesc.moveDown = false
      cutter:onStopReel()
    end
  end
end
function Combine:findTrailerRaycastCallback(transformId, x, y, z, distance)
  if getUserAttribute(transformId, "vehicleType") == 2 then
    self.trailerFound = transformId
  end
  return false
end
function Combine:openPipe()
  self.pipeOpening = true
end
function Combine:closePipe()
  self.pipeOpening = false
end

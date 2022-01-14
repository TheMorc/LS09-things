AICombine = {}
function AICombine.prerequisitesPresent(specializations)
  return SpecializationUtil.hasSpecialization(Hirable, specializations) and SpecializationUtil.hasSpecialization(Combine, specializations)
end
function AICombine:load(xmlFile)
  self.startAIThreshing = SpecializationUtil.callSpecializationsFunction("startAIThreshing")
  self.stopAIThreshing = SpecializationUtil.callSpecializationsFunction("stopAIThreshing")
  self.onTrafficCollisionTrigger = AICombine.onTrafficCollisionTrigger
  self.onCutterTrafficCollisionTrigger = AICombine.onCutterTrafficCollisionTrigger
  self.onTrailerTrigger = AICombine.onTrailerTrigger
  self.isAIThreshing = false
  self.aiTreshingDirectionNode = Utils.indexToObject(self.components, getXMLString(xmlFile, "vehicle.aiTreshingDirectionNode#index"))
  if self.aiTreshingDirectionNode == nil then
    self.aiTreshingDirectionNode = self.components[1].node
  end
  self.lookAheadDistance = 10
  self.turnTimeout = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.turnTimeout"), 1000)
  self.turnTimeoutLong = self.turnTimeout * 10
  self.turnTimer = self.turnTimeout
  self.turnEndDistance = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.turnEndDistance"), 4)
  self.waitForTurnTimeout = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.waitForTurnTime"), 1000)
  self.waitForTurnTime = 0
  self.sideWatchDirOffset = -4
  self.sideWatchDirSize = 4
  self.waitingForDischarge = false
  self.waitForDischargeTime = 0
  self.waitForDischargeTimeout = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.waitForDischargeTime"), 5000)
  self.turnStage = 0
  self.aiTrafficCollisionTrigger = Utils.indexToObject(self.components, getXMLString(xmlFile, "vehicle.aiTrafficCollisionTrigger#index"))
  self.aiTrailerTrigger = Utils.indexToObject(self.components, getXMLString(xmlFile, "vehicle.aiTrailerTrigger#index"))
  self.aiTurnThreshWidthScale = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.aiTurnThreshWidthScale#value"), 0.9)
  self.isTrailerInRange = false
  self.trafficCollisionIgnoreList = {}
  for k, v in pairs(self.components) do
    self.trafficCollisionIgnoreList[v.node] = true
  end
  self.numCollidingVehicles = 0
  self.numCutterCollidingVehicles = {}
  self.driveBackTimeout = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.driveBackTimeout"), 2000)
  self.driveBackTime = 0
  self.driveBackAfterDischarge = false
  self.dtSum = 0
  local aiMotorSound = getXMLString(xmlFile, "vehicle.aiMotorSound#file")
  if aiMotorSound ~= nil and aiMotorSound ~= "" then
    aiMotorSound = Utils.getFilename(aiMotorSound, self.baseDirectory)
    self.aiMotorSoundPitchOffset = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.aiMotorSound#pitchOffset"), 0)
    self.aiMotorSoundRadius = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.aiMotorSound#radius"), 50)
    self.aiMotorSoundInnerRadius = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.aiMotorSound#innerRadius"), 10)
    self.aiMotorSoundVolume = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.aiMotorSound#volume"), 1)
    self.aiMotorSound = createAudioSource("aiMotorSound", aiMotorSound, self.aiMotorSoundRadius, self.aiMotorSoundInnerRadius, self.aiMotorSoundVolume, 0)
    link(self.components[1].node, self.aiMotorSound)
    setVisibility(self.aiMotorSound, false)
  end
  local aiThreshingSound = getXMLString(xmlFile, "vehicle.aiTreshingSound#file")
  if aiThreshingSound ~= nil and aiThreshingSound ~= "" then
    aiThreshingSound = Utils.getFilename(aiThreshingSound, self.baseDirectory)
    self.aiThreshingSoundPitchOffset = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.aiTreshingSound#pitchOffset"), 0)
    self.aiThreshingSoundRadius = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.aiTreshingSound#radius"), 50)
    self.aiThreshingSoundInnerRadius = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.aiTreshingSound#innerRadius"), 10)
    self.aiThreshingSoundVolume = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.aiTreshingSound#volume"), 1)
    self.aiThreshingSound = createAudioSource("aiThreshingSound", aiThreshingSound, self.aiThreshingSoundRadius, self.aiThreshingSoundInnerRadius, self.aiThreshingSoundVolume, 0)
    link(self.components[1].node, self.aiThreshingSound)
    setVisibility(self.aiThreshingSound, false)
  end
end
function AICombine:delete()
  self:stopAIThreshing()
end
function AICombine:mouseEvent(posX, posY, isDown, isUp, button)
end
function AICombine:keyEvent(unicode, sym, modifier, isDown)
end
function AICombine:update(dt)
  if self:getIsActiveForInput() and not g_currentMission.disableCombineAI and g_currentMission.allowSteerableMoving and InputBinding.hasEvent(InputBinding.TOGGLE_AI) then
    if self.isAIThreshing then
      self:stopAIThreshing()
    else
      self:startAIThreshing()
    end
  end
  if self.isAIThreshing then
    if self.isBroken then
      self:stopAIThreshing()
    end
    self.dtSum = self.dtSum + dt
    if self.dtSum > 20 then
      AICombine.updateAIMovement(self, self.dtSum)
      self.dtSum = 0
    end
    if 0 < self.grainTankFillLevel and (self.grainTankFillLevel >= self.grainTankCapacity * 0.8 or self.isTrailerInRange) then
      self:openPipe()
      if self.isTrailerInRange then
        self.waitForDischargeTime = self.time + self.waitForDischargeTimeout
      end
      if self.grainTankFillLevel >= self.grainTankCapacity then
        self.driveBackAfterDischarge = true
        self.waitingForDischarge = true
        self.waitForDischargeTime = self.time + self.waitForDischargeTimeout
      end
    elseif self.waitingForDischarge and 0 >= self.grainTankFillLevel or self.waitForDischargeTime <= self.time then
      self.waitingForDischarge = false
      if self.driveBackAfterDischarge then
        self.driveBackTime = self.time + self.driveBackTimeout
        self.driveBackAfterDischarge = false
      end
      self:closePipe()
      self:startThreshing()
    end
    self.isTrailerInRange = false
  else
    self.dtSum = 0
  end
end
function AICombine:draw()
  if not g_currentMission.disableCombineAI and self.numAttachedCutters > 0 then
    if self.isAIThreshing then
      g_currentMission:addHelpButtonText(g_i18n:getText("DismissEmployee"), InputBinding.TOGGLE_AI)
    else
      g_currentMission:addHelpButtonText(g_i18n:getText("HireEmployee"), InputBinding.TOGGLE_AI)
    end
  end
end
function AICombine:startAIThreshing()
  self:hire()
  if not self.isAIThreshing then
    self.isAIThreshing = true
    self.turnTimer = self.turnTimeoutLong
    self.turnStage = 0
    local x, y, z = localDirectionToWorld(self.aiTreshingDirectionNode, 0, 0, 1)
    local length = Utils.vector2Length(x, z)
    self.aiThreshingDirectionX = x / length
    self.aiThreshingDirectionZ = z / length
    local x, y, z = getWorldTranslation(self.aiTreshingDirectionNode)
    self.aiThreshingTargetX = x
    self.aiThreshingTargetZ = z
    self.speedDisplayScale = 0.5
    self.waitingForDischarge = false
    if not self.isThreshing then
      self:startThreshing()
    end
    if self.aiTrailerTrigger ~= nil then
      addTrigger(self.aiTrailerTrigger, "onTrailerTrigger", self)
    end
    self.numCollidingVehicles = 0
    if self.aiTrafficCollisionTrigger ~= nil then
      addTrigger(self.aiTrafficCollisionTrigger, "onTrafficCollisionTrigger", self)
    end
    for cutter, implement in pairs(self.attachedCutters) do
      AICombine.addCutterTrigger(self, cutter)
    end
    self.isTrailerInRange = false
    setVisibility(self.aiMotorSound, true)
    setVisibility(self.aiThreshingSound, true)
  end
end
function AICombine:stopAIThreshing()
  self:dismiss()
  if self.isAIThreshing then
    self.speedDisplayScale = 1
    if self.isThreshing then
      self:stopThreshing()
    end
    self.motor:setSpeedLevel(0, false)
    self.motor.maxRpmOverride = nil
    WheelsUtil.updateWheelsPhysics(self, 0, self.lastSpeed, 0, false, self.requiredDriveMode)
    if self.aiTrailerTrigger ~= nil then
      removeTrigger(self.aiTrailerTrigger)
    end
    if self.aiTrafficCollisionTrigger ~= nil then
      removeTrigger(self.aiTrafficCollisionTrigger)
    end
    for cutter, implement in pairs(self.attachedCutters) do
      AICombine.removeCutterTrigger(self, cutter)
    end
    self.isAIThreshing = false
    if not self:getIsActive() then
      Combine.onDeactivate(self)
    end
    setVisibility(self.aiMotorSound, false)
    setVisibility(self.aiThreshingSound, false)
  end
end
function AICombine:updateAIMovement(dt)
  local allowedToDrive = true
  if self.grainTankFillLevel >= self.grainTankCapacity or self.waitingForDischarge or self.numCollidingVehicles > 0 then
    allowedToDrive = false
  end
  for k, v in pairs(self.numCutterCollidingVehicles) do
    if 0 < v then
      allowedToDrive = false
      break
    end
  end
  if 0 < self.turnStage and (self.waitForTurnTime > self.time or self.lastUnloadingTrailer ~= nil) then
    allowedToDrive = false
  end
  if not allowedToDrive then
    local lx, lz = 0, 1
    AIVehicleUtil.driveInDirection(self, dt, 30, 0, 0, 28, false, moveForwards, lx, lz)
    return
  end
  local speedLevel = 2
  local leftMarker, rightMarker
  local fruitType = self.currentGrainTankFruitType
  for cutter, implement in pairs(self.attachedCutters) do
    if cutter.aiLeftMarker ~= nil and leftMarker == nil then
      leftMarker = cutter.aiLeftMarker
    end
    if cutter.aiRightMarker ~= nil and rightMarker == nil then
      rightMarker = cutter.aiRightMarker
    end
    if Cutter.getUseLowSpeedLimit(cutter) then
      speedLevel = 1
    end
  end
  if leftMarker == nil or rightMarker == nil then
    self:stopAIThreshing()
    return
  end
  if self.driveBackTime >= self.time then
    local x, y, z = getWorldTranslation(self.aiTreshingDirectionNode)
    local lx, lz = AIVehicleUtil.getDriveDirection(self.aiTreshingDirectionNode, self.aiThreshingTargetX, y, self.aiThreshingTargetZ)
    AIVehicleUtil.driveInDirection(self, dt, 30, 0, 0, 28, true, false, lx, lz, speedLevel, 1)
    return
  end
  if 1 > self.lastArea then
    self.turnTimer = self.turnTimer - dt
  else
    self.turnTimer = self.turnTimeout
  end
  local newTargetX, newTargetY, newTargetZ
  local moveForwards = true
  local updateWheels = true
  if 0 > self.turnTimer or 0 < self.turnStage then
    if 0 < self.turnStage then
      local x, y, z = getWorldTranslation(self.aiTreshingDirectionNode)
      local dirX, dirZ = self.aiThreshingDirectionX, self.aiThreshingDirectionZ
      local myDirX, myDirY, myDirZ = localDirectionToWorld(self.aiTreshingDirectionNode, 0, 0, 1)
      newTargetX = self.aiThreshingTargetX
      newTargetY = y
      newTargetZ = self.aiThreshingTargetZ
      if self.turnStage == 1 then
        if 0.2 < myDirX * dirX + myDirZ * dirZ then
          self.turnStage = 2
          moveForwards = false
        end
      elseif self.turnStage == 2 then
        if 0.8 < myDirX * dirX + myDirZ * dirZ then
          self.turnStage = 3
          for cutter, implement in pairs(self.attachedCutters) do
            local jointDesc = self.attacherJoints[implement.jointDescIndex]
            jointDesc.moveDown = true
          end
        else
          moveForwards = false
        end
      elseif self.turnStage == 3 and Utils.vector2Length(x - newTargetX, z - newTargetZ) < self.turnEndDistance then
        self.turnTimer = self.turnTimeoutLong
        self.turnStage = 0
      end
    elseif fruitType == FruitUtil.FRUITTYPE_UNKNOWN then
      self:stopAIThreshing()
      return
    else
      local x, y, z = getWorldTranslation(self.aiTreshingDirectionNode)
      local dirX, dirZ = self.aiThreshingDirectionX, self.aiThreshingDirectionZ
      local sideX, sideZ = -dirZ, dirX
      local lInX, lInY, lInZ = getWorldTranslation(leftMarker)
      local rInX, rInY, rInZ = getWorldTranslation(rightMarker)
      local threshWidth = Utils.vector2Length(lInX - rInX, lInZ - rInZ)
      local turnLeft = true
      local lWidthX = x - sideX * 0.5 * threshWidth + dirX * self.sideWatchDirOffset
      local lWidthZ = z - sideZ * 0.5 * threshWidth + dirZ * self.sideWatchDirOffset
      local lStartX = lWidthX - sideX * 0.7 * threshWidth
      local lStartZ = lWidthZ - sideZ * 0.7 * threshWidth
      local lHeightX = lStartX + dirX * self.sideWatchDirSize
      local lHeightZ = lStartZ + dirZ * self.sideWatchDirSize
      local rWidthX = x + sideX * 0.5 * threshWidth + dirX * self.sideWatchDirOffset
      local rWidthZ = z + sideZ * 0.5 * threshWidth + dirZ * self.sideWatchDirOffset
      local rStartX = rWidthX + sideX * 0.7 * threshWidth
      local rStartZ = rWidthZ + sideZ * 0.7 * threshWidth
      local rHeightX = rStartX + dirX * self.sideWatchDirSize
      local rHeightZ = rStartZ + dirZ * self.sideWatchDirSize
      local leftFruit = Utils.getFruitArea(fruitType, lStartX, lStartZ, lWidthX, lWidthZ, lHeightX, lHeightZ)
      local rightFruit = Utils.getFruitArea(fruitType, rStartX, rStartZ, rWidthX, rWidthZ, rHeightX, rHeightZ)
      if 0 < leftFruit or 0 < rightFruit then
        if leftFruit > rightFruit then
          turnLeft = true
        else
          turnLeft = false
        end
      else
        self:stopAIThreshing()
        return
      end
      local targetX, targetZ = self.aiThreshingTargetX, self.aiThreshingTargetZ
      local dx, dz = x - targetX, z - targetZ
      local dot = dx * dirX + dz * dirZ
      threshWidth = threshWidth * self.aiTurnThreshWidthScale
      if turnLeft then
        newTargetX = x - sideX * threshWidth
        newTargetY = y
        newTargetZ = z - sideZ * threshWidth
      else
        newTargetX = x + sideX * threshWidth
        newTargetY = y
        newTargetZ = z + sideZ * threshWidth
      end
      self.aiThreshingDirectionX = -dirX
      self.aiThreshingDirectionZ = -dirZ
      self.turnStage = 1
      self.waitForTurnTime = self.time + self.waitForTurnTimeout
      for cutter, implement in pairs(self.attachedCutters) do
        local jointDesc = self.attacherJoints[implement.jointDescIndex]
        jointDesc.moveDown = false
      end
      updateWheels = false
      if turnLeft then
      else
      end
    end
  else
    local x, y, z = getWorldTranslation(self.aiTreshingDirectionNode)
    local dirX, dirZ = self.aiThreshingDirectionX, self.aiThreshingDirectionZ
    local targetX, targetZ = self.aiThreshingTargetX, self.aiThreshingTargetZ
    local dx, dz = x - targetX, z - targetZ
    local dot = dx * dirX + dz * dirZ
    local projTargetX = targetX + dirX * dot
    local projTargetZ = targetZ + dirZ * dot
    newTargetX = projTargetX + self.aiThreshingDirectionX * self.lookAheadDistance
    newTargetY = y
    newTargetZ = projTargetZ + self.aiThreshingDirectionZ * self.lookAheadDistance
  end
  if updateWheels then
    local lx, lz = AIVehicleUtil.getDriveDirection(self.aiTreshingDirectionNode, newTargetX, newTargetY, newTargetZ)
    AIVehicleUtil.driveInDirection(self, dt, 25, 0.5, 0.5, 20, true, moveForwards, lx, lz, speedLevel, 0.9)
    local maxlx = 0.7071067
    local colDirX = lx
    local colDirZ = lz
    if maxlx < colDirX then
      colDirX = maxlx
      colDirZ = 0.7071067
    elseif colDirX < -maxlx then
      colDirX = -maxlx
      colDirZ = 0.7071067
    end
    if self.aiTrafficCollisionTrigger ~= nil then
      AIVehicleUtil.setCollisionDirection(self.aiTreshingDirectionNode, self.aiTrafficCollisionTrigger, colDirX, colDirZ)
    end
    for k, v in pairs(self.numCutterCollidingVehicles) do
      AIVehicleUtil.setCollisionDirection(self.aiTreshingDirectionNode, k, colDirX, colDirZ)
    end
  end
  self.aiThreshingTargetX = newTargetX
  self.aiThreshingTargetZ = newTargetZ
end
function AICombine:switchToDirection(myDirX, myDirZ)
  self.aiThreshingDirectionX = myDirX
  self.aiThreshingDirectionZ = myDirZ
end
function AICombine:addCutterTrigger(cutter)
  if cutter.aiTrafficCollisionTrigger ~= nil then
    addTrigger(cutter.aiTrafficCollisionTrigger, "onCutterTrafficCollisionTrigger", self)
    self.numCutterCollidingVehicles[cutter.aiTrafficCollisionTrigger] = 0
  end
  for k, v in pairs(cutter.components) do
    self.trafficCollisionIgnoreList[v.node] = true
  end
end
function AICombine:removeCutterTrigger(cutter)
  if cutter.aiTrafficCollisionTrigger ~= nil then
    removeTrigger(cutter.aiTrafficCollisionTrigger)
    self.numCutterCollidingVehicles[cutter.aiTrafficCollisionTrigger] = nil
  end
  for k, v in pairs(cutter.components) do
    self.trafficCollisionIgnoreList[v.node] = nil
  end
end
function AICombine:attachImplement(implement)
  local object = implement.object
  if object.attacherJoint.jointType == Vehicle.JOINTTYPE_CUTTER and self.isAIThreshing then
    AICombine.removeCutterTrigger(self, object)
  end
end
function AICombine:detachImplement(implementIndex)
  local object = self.attachedImplements[implementIndex].object
  if object.attacherJoint.jointType == Vehicle.JOINTTYPE_CUTTER and self.isAIThreshing then
    AICombine.removeCutterTrigger(self, object)
  end
end
function AICombine:onTrafficCollisionTrigger(triggerId, otherId, onEnter, onLeave, onStay, otherShapeId)
  if onEnter or onLeave then
    if otherId == Player.rootNode then
      if onEnter then
        self.numCollidingVehicles = self.numCollidingVehicles + 1
      elseif onLeave then
        self.numCollidingVehicles = math.max(self.numCollidingVehicles - 1, 0)
      end
    else
      local vehicle = g_currentMission.nodeToVehicle[otherId]
      if vehicle ~= nil and self.trafficCollisionIgnoreList[otherId] == nil then
        if onEnter then
          self.numCollidingVehicles = self.numCollidingVehicles + 1
        elseif onLeave then
          self.numCollidingVehicles = math.max(self.numCollidingVehicles - 1, 0)
        end
      end
    end
  end
end
function AICombine:onCutterTrafficCollisionTrigger(triggerId, otherId, onEnter, onLeave, onStay, otherShapeId)
  if onEnter or onLeave then
    if otherId == Player.rootNode then
      if onEnter then
        self.numCutterCollidingVehicles[triggerId] = self.numCutterCollidingVehicles[triggerId] + 1
      elseif onLeave then
        self.numCutterCollidingVehicles[triggerId] = math.max(self.numCutterCollidingVehicles[triggerId] - 1, 0)
      end
    else
      local vehicle = g_currentMission.nodeToVehicle[otherId]
      if vehicle ~= nil and self.trafficCollisionIgnoreList[otherId] == nil then
        if onEnter then
          self.numCutterCollidingVehicles[triggerId] = self.numCutterCollidingVehicles[triggerId] + 1
        elseif onLeave then
          self.numCutterCollidingVehicles[triggerId] = math.max(self.numCutterCollidingVehicles[triggerId] - 1, 0)
        end
      end
    end
  end
end
function AICombine:onTrailerTrigger(triggerId, otherId, onEnter, onLeave, onStay, otherShapeId)
  if onEnter or onStay then
    self.isTrailerInRange = true
  end
end

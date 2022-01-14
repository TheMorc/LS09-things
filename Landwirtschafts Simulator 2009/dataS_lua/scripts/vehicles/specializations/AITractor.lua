AITractor = {}
function AITractor.prerequisitesPresent(specializations)
  return SpecializationUtil.hasSpecialization(Hirable, specializations) and SpecializationUtil.hasSpecialization(Steerable, specializations)
end
function AITractor:load(xmlFile)
  self.startAITractor = SpecializationUtil.callSpecializationsFunction("startAITractor")
  self.stopAITractor = SpecializationUtil.callSpecializationsFunction("stopAITractor")
  self.onTrafficCollisionTrigger = AITractor.onTrafficCollisionTrigger
  self.onToolTrafficCollisionTrigger = AITractor.onToolTrafficCollisionTrigger
  self.isAITractorActivated = false
  self.aiTractorDirectionNode = Utils.indexToObject(self.components, getXMLString(xmlFile, "vehicle.aiTractorDirectionNode#index"))
  if self.aiTractorDirectionNode == nil then
    self.aiTractorDirectionNode = self.components[1].node
  end
  self.aiTractorLookAheadDistance = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.aiTractorLookAheadDistance"), 10)
  self.turnTimeout = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.turnTimeout"), 800)
  self.turnTimeoutLong = self.turnTimeout * 10
  self.turnTime = 0
  self.frontMarkerDistanceScale = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.frontMarkerDistanceScale"), 1.2)
  self.lastFrontMarkerDistance = 0
  self.turnTargetMoveBack = 7
  self.turnEndDistance = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.turnEndDistance"), 4)
  self.turnEndBackDistance = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.turnEndBackDistance"), 1) + self.turnTargetMoveBack
  self.waitForTurnTimeout = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.waitForTurnTime"), 1000)
  self.waitForTurnTime = 0
  self.sideWatchDirOffset = -8
  self.sideWatchDirSize = 6
  self.turnStage = 0
  self.aiTrafficCollisionTrigger = Utils.indexToObject(self.components, getXMLString(xmlFile, "vehicle.aiTrafficCollisionTrigger#index"))
  self.aiTurnWidthScale = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.aiTurnWidthScale#value"), 0.9)
  self.trafficCollisionIgnoreList = {}
  for k, v in pairs(self.components) do
    self.trafficCollisionIgnoreList[v.node] = true
  end
  self.numCollidingVehicles = 0
  self.numToolsCollidingVehicles = {}
  self.aiToolsDirty = true
  self.dtSum = 0
  local aiMotorSound = getXMLString(xmlFile, "vehicle.aiMotorSound#file")
  if aiMotorSound ~= nil and aiMotorSound ~= "" then
    aiMotorSound = Utils.getFilename(aiMotorSound, self.baseDirectory)
    self.aiMotorSoundPitchOffset = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.motorSoundRun#pitchOffset"), 0)
    self.aiMotorSoundRadius = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.motorSoundRun#radius"), 50)
    self.aiMotorSoundInnerRadius = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.motorSoundRun#innerRadius"), 10)
    self.aiMotorSoundVolume = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.motorSoundRun#volume"), 1)
    self.aiMotorSound = createAudioSource("aiMotorSound", aiMotorSound, self.aiMotorSoundRadius, self.aiMotorSoundInnerRadius, self.aiMotorSoundVolume, 0)
    link(self.components[1].node, self.aiMotorSound)
    setVisibility(self.aiMotorSound, false)
  end
end
function AITractor:delete()
  self:stopAITractor()
end
function AITractor:mouseEvent(posX, posY, isDown, isUp, button)
end
function AITractor:keyEvent(unicode, sym, modifier, isDown)
end
function AITractor:update(dt)
  if self:getIsActiveForInput() and not g_currentMission.disableTractorAI and g_currentMission.allowSteerableMoving and InputBinding.hasEvent(InputBinding.TOGGLE_AI) then
    if self.isAITractorActivated then
      self:stopAITractor()
    else
      self:startAITractor()
    end
  end
  if self.aiToolsDirty then
    AITractor.updateToolsInfo(self)
  end
  if self.isAITractorActivated then
    if self.isBroken then
      self:stopAITractor()
    end
    self.dtSum = self.dtSum + dt
    if self.dtSum > 20 then
      AITractor.updateAIMovement(self, self.dtSum)
      self.dtSum = 0
    end
    AITractor.updateAIMovement(self, dt)
  else
    self.dtSum = 0
  end
end
function AITractor:draw()
  if not g_currentMission.disableTractorAI and self.aiLeftMarker ~= nil and self.aiRightMarker ~= nil and self.aiBackMarker ~= nil then
    if self.isAITractorActivated then
      g_currentMission:addHelpButtonText(g_i18n:getText("DismissEmployee"), InputBinding.TOGGLE_AI)
    else
      g_currentMission:addHelpButtonText(g_i18n:getText("HireEmployee"), InputBinding.TOGGLE_AI)
    end
  end
end
function AITractor:startAITractor()
  self:hire()
  if not self.isAITractorActivated then
    self.isAITractorActivated = true
    self.turnTime = self.time + self.turnTimeoutLong
    self.turnStage = 0
    local x, y, z = localDirectionToWorld(self.aiTractorDirectionNode, 0, 0, 1)
    local length = Utils.vector2Length(x, z)
    self.aiTractorDirectionX = x / length
    self.aiTractorDirectionZ = z / length
    local x, y, z = getWorldTranslation(self.aiTractorDirectionNode)
    self.aiTractorTargetX = x
    self.aiTractorTargetZ = z
    self.numCollidingVehicles = 0
    if self.aiTrafficCollisionTrigger ~= nil then
      addTrigger(self.aiTrafficCollisionTrigger, "onTrafficCollisionTrigger", self)
    end
    AITractor.updateToolsInfo(self)
    for k, implement in pairs(self.attachedImplements) do
      if implement.object.needsLowering then
        local jointDesc = self.attacherJoints[implement.jointDescIndex]
        jointDesc.moveDown = true
      end
      implement.object:aiTurnOn()
    end
    setVisibility(self.aiMotorSound, true)
  end
end
function AITractor:stopAITractor()
  self:dismiss()
  if self.isAITractorActivated then
    self.motor:setSpeedLevel(0, false)
    self.motor.maxRpmOverride = nil
    WheelsUtil.updateWheelsPhysics(self, 0, self.lastSpeed, 0, false, self.requiredDriveMode)
    if self.aiTrafficCollisionTrigger ~= nil then
      removeTrigger(self.aiTrafficCollisionTrigger)
    end
    self.isAITractorActivated = false
    setVisibility(self.aiMotorSound, false)
  end
end
function AITractor:updateAIMovement(dt)
  local allowedToDrive = true
  if self.numCollidingVehicles > 0 then
    allowedToDrive = false
  end
  for k, v in pairs(self.numToolsCollidingVehicles) do
    if 0 < v then
      allowedToDrive = false
      break
    end
  end
  if self.waitForTurnTime > self.time then
    allowedToDrive = false
  end
  if not allowedToDrive then
    local lx, lz = 0, 1
    AIVehicleUtil.driveInDirection(self, dt, 30, 0, 0, 28, false, moveForwards, lx, lz)
    return
  end
  local speedLevel = 1
  local leftMarker = self.aiLeftMarker
  local rightMarker = self.aiRightMarker
  local backMarker = self.aiBackMarker
  local terrainDetailChannel1 = self.aiTerrainDetailChannel1
  local terrainDetailChannel2 = self.aiTerrainDetailChannel2
  if leftMarker == nil or rightMarker == nil or backMarker == nil then
    self:stopAITractor()
    return
  end
  local newTargetX, newTargetY, newTargetZ
  local moveForwards = true
  local updateWheels = true
  if self.turnTime <= self.time or 0 < self.turnStage then
    if 1 < self.turnStage then
      local x, y, z = getWorldTranslation(self.aiTractorDirectionNode)
      local dirX, dirZ = self.aiTractorDirectionX, self.aiTractorDirectionZ
      local myDirX, myDirY, myDirZ = localDirectionToWorld(self.aiTractorDirectionNode, 0, 0, 1)
      newTargetX = self.aiTractorTargetX
      newTargetY = y
      newTargetZ = self.aiTractorTargetZ
      if self.turnStage == 2 then
        if 0.2 < myDirX * dirX + myDirZ * dirZ then
          self.turnStage = 3
          moveForwards = false
        end
      elseif self.turnStage == 3 then
        if 0.95 < myDirX * dirX + myDirZ * dirZ then
          self.turnStage = 4
        else
          moveForwards = false
        end
      elseif self.turnStage == 4 then
        local dx, dz = x - newTargetX, z - newTargetZ
        local dot = dx * dirX + dz * dirZ
        if -dot < self.turnEndDistance then
          newTargetX = self.aiTractorTargetX + dirX * self.turnTargetMoveBack
          newTargetY = y
          newTargetZ = self.aiTractorTargetZ + dirZ * self.turnTargetMoveBack
          self.turnStage = 5
        end
      elseif self.turnStage == 5 then
        local backX, backY, backZ = getWorldTranslation(backMarker)
        local dx, dz = backX - newTargetX, backZ - newTargetZ
        local dot = dx * dirX + dz * dirZ
        if -dot < self.turnEndBackDistance then
          self.turnTime = self.time + self.turnTimeoutLong
          self.turnStage = 0
          for k, implement in pairs(self.attachedImplements) do
            if implement.object.needsLowering then
              local jointDesc = self.attacherJoints[implement.jointDescIndex]
              jointDesc.moveDown = true
            end
          end
          self.waitForTurnTime = self.time + self.waitForTurnTimeout
        end
      end
    elseif self.turnStage == 1 then
      local x, y, z = getWorldTranslation(self.aiTractorDirectionNode)
      local dirX, dirZ = self.aiTractorDirectionX, self.aiTractorDirectionZ
      local sideX, sideZ = -dirZ, dirX
      local lX, lY, lZ = getWorldTranslation(leftMarker)
      local rX, rY, rZ = getWorldTranslation(rightMarker)
      local markerWidth = Utils.vector2Length(lX - rX, lZ - rZ)
      local turnLeft = true
      local lWidthX = lX + dirX * self.sideWatchDirOffset
      local lWidthZ = lZ + dirZ * self.sideWatchDirOffset
      local lStartX = lWidthX - sideX * 0.7 * markerWidth
      local lStartZ = lWidthZ - sideZ * 0.7 * markerWidth
      local lHeightX = lStartX + dirX * self.sideWatchDirSize
      local lHeightZ = lStartZ + dirZ * self.sideWatchDirSize
      local rWidthX = rX + dirX * self.sideWatchDirOffset
      local rWidthZ = rZ + sideZ * 0.5 * markerWidth + dirZ * self.sideWatchDirOffset
      local rStartX = rWidthX + sideX * 0.7 * markerWidth
      local rStartZ = rWidthZ + sideZ * 0.7 * markerWidth
      local rHeightX = rStartX + dirX * self.sideWatchDirSize
      local rHeightZ = rStartZ + dirZ * self.sideWatchDirSize
      local leftArea = 0
      if 0 <= terrainDetailChannel1 then
        local id = g_currentMission.terrainDetailId
        local x, z, widthX, widthZ, heightX, heightZ = Utils.getXZWidthAndHeight(id, lStartX, lStartZ, lWidthX, lWidthZ, lHeightX, lHeightZ)
        leftArea = getDensityParallelogram(id, x, z, widthX, widthZ, heightX, heightZ, terrainDetailChannel1, 1)
        if leftArea == 0 and 0 <= terrainDetailChannel2 then
          leftArea = getDensityParallelogram(id, x, z, widthX, widthZ, heightX, heightZ, terrainDetailChannel2, 1)
        end
      end
      local rightArea = 0
      if 0 <= terrainDetailChannel1 then
        local id = g_currentMission.terrainDetailId
        local x, z, widthX, widthZ, heightX, heightZ = Utils.getXZWidthAndHeight(id, rStartX, rStartZ, rWidthX, rWidthZ, rHeightX, rHeightZ)
        rightArea = getDensityParallelogram(id, x, z, widthX, widthZ, heightX, heightZ, terrainDetailChannel1, 1)
        if rightArea == 0 and 0 <= terrainDetailChannel2 then
          rightArea = getDensityParallelogram(id, x, z, widthX, widthZ, heightX, heightZ, terrainDetailChannel2, 1)
        end
      end
      if 0 < leftArea or 0 < rightArea then
        if leftArea > rightArea then
          turnLeft = true
        else
          turnLeft = false
        end
      else
        self:stopAITractor()
        return
      end
      local lX, lY, lZ = getWorldTranslation(leftMarker)
      local rX, rY, rZ = getWorldTranslation(rightMarker)
      local x = (lX + rX) / 2
      local z = (lZ + rZ) / 2
      local markerSideOffset, lY, lZ = worldToLocal(self.aiTractorDirectionNode, x, (lY + rY) / 2, z)
      markerSideOffset = math.abs(markerSideOffset)
      local targetX, targetZ = self.aiTractorTargetX, self.aiTractorTargetZ
      local dx, dz = x - targetX, z - targetZ
      local dot = dx * dirX + dz * dirZ
      local x, z = targetX + dirX * dot, targetZ + dirZ * dot
      markerWidth = markerWidth * self.aiTurnWidthScale - markerSideOffset
      if turnLeft then
        newTargetX = x - sideX * markerWidth
        newTargetY = y
        newTargetZ = z - sideZ * markerWidth
        for k, implement in pairs(self.attachedImplements) do
          implement.object:aiRotateLeft()
        end
      else
        newTargetX = x + sideX * markerWidth
        newTargetY = y
        newTargetZ = z + sideZ * markerWidth
        for k, implement in pairs(self.attachedImplements) do
          implement.object:aiRotateRight()
        end
      end
      self.aiTractorDirectionX = -dirX
      self.aiTractorDirectionZ = -dirZ
      self.turnStage = 2
      if turnLeft then
      else
      end
    else
      self.turnStage = 1
      self.waitForTurnTime = self.time + self.waitForTurnTimeout
      for k, implement in pairs(self.attachedImplements) do
        if implement.object.needsLowering then
          local jointDesc = self.attacherJoints[implement.jointDescIndex]
          jointDesc.moveDown = false
        end
      end
      updateWheels = false
    end
  else
    local dirX, dirZ = self.aiTractorDirectionX, self.aiTractorDirectionZ
    local lX, lY, lZ = getWorldTranslation(leftMarker)
    local rX, rY, rZ = getWorldTranslation(rightMarker)
    self.lastFrontMarkerDistance = self.lastSpeed * self.turnTimeout
    local scaledDistance = self.lastFrontMarkerDistance * self.frontMarkerDistanceScale
    lX = lX + dirX * scaledDistance
    lZ = lZ + dirZ * scaledDistance
    rX = rX + dirX * scaledDistance
    rZ = rZ + dirZ * scaledDistance
    local heightX = lX + dirX * 0.2
    local heightZ = lZ + dirZ * 0.2
    local area = 0
    if 0 <= terrainDetailChannel1 then
      local id = g_currentMission.terrainDetailId
      local x, z, widthX, widthZ, heightX, heightZ = Utils.getXZWidthAndHeight(id, lX, lZ, rX, rZ, heightX, heightZ)
      area = getDensityParallelogram(id, x, z, widthX, widthZ, heightX, heightZ, terrainDetailChannel1, 1)
      if area == 0 and 0 <= terrainDetailChannel2 then
        area = getDensityParallelogram(id, x, z, widthX, widthZ, heightX, heightZ, terrainDetailChannel2, 1)
      end
    end
    if 1 <= area then
      self.turnTime = self.time + self.turnTimeout
    end
    local x, y, z = getWorldTranslation(self.aiTractorDirectionNode)
    local dirX, dirZ = self.aiTractorDirectionX, self.aiTractorDirectionZ
    local targetX, targetZ = self.aiTractorTargetX, self.aiTractorTargetZ
    local dx, dz = x - targetX, z - targetZ
    local dot = dx * dirX + dz * dirZ
    local projTargetX = targetX + dirX * dot
    local projTargetZ = targetZ + dirZ * dot
    newTargetX = projTargetX + self.aiTractorDirectionX * self.aiTractorLookAheadDistance
    newTargetY = y
    newTargetZ = projTargetZ + self.aiTractorDirectionZ * self.aiTractorLookAheadDistance
  end
  if updateWheels then
    local lx, lz = AIVehicleUtil.getDriveDirection(self.aiTractorDirectionNode, newTargetX, newTargetY, newTargetZ)
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
      AIVehicleUtil.setCollisionDirection(self.aiTractorDirectionNode, self.aiTrafficCollisionTrigger, colDirX, colDirZ)
    end
    for k, v in pairs(self.numToolsCollidingVehicles) do
      AIVehicleUtil.setCollisionDirection(self.aiTractorDirectionNode, k, colDirX, colDirZ)
    end
  end
  if newTargetX ~= nil and newTargetZ ~= nil then
    self.aiTractorTargetX = newTargetX
    self.aiTractorTargetZ = newTargetZ
  end
end
function AITractor:switchToDirection(myDirX, myDirZ)
  self.aiTractorDirectionX = myDirX
  self.aiTractorDirectionZ = myDirZ
end
function AITractor:addToolTrigger(tool)
  if tool.aiTrafficCollisionTrigger ~= nil then
    addTrigger(tool.aiTrafficCollisionTrigger, "ontoolTrafficCollisionTrigger", self)
    self.numToolsCollidingVehicles[tool.aiTrafficCollisionTrigger] = 0
  end
  for k, v in pairs(tool.components) do
    self.trafficCollisionIgnoreList[v.node] = true
  end
end
function AITractor:removeToolTrigger(tool)
  if tool.aiTrafficCollisionTrigger ~= nil then
    removeTrigger(tool.aiTrafficCollisionTrigger)
    self.numToolsCollidingVehicles[tool.aiTrafficCollisionTrigger] = nil
  end
  for k, v in pairs(tool.components) do
    self.trafficCollisionIgnoreList[v.node] = nil
  end
end
function AITractor:attachImplement(implement)
  local object = implement.object
  if self.isAITractorActivated then
    AITractor.removeToolTrigger(self, object)
  end
  self.aiToolsDirty = true
end
function AITractor:detachImplement(implementIndex)
  local object = self.attachedImplements[implementIndex].object
  if self.isAITractorActivated then
    AITractor.removeToolTrigger(self, object)
  end
  self.aiToolsDirty = true
end
function AITractor:onTrafficCollisionTrigger(triggerId, otherId, onEnter, onLeave, onStay, otherShapeId)
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
function AITractor:onToolTrafficCollisionTrigger(triggerId, otherId, onEnter, onLeave, onStay, otherShapeId)
  if onEnter or onLeave then
    if otherId == Player.rootNode then
      if onEnter then
        self.numToolsCollidingVehicles[triggerId] = self.numToolsCollidingVehicles[triggerId] + 1
      elseif onLeave then
        self.numToolsCollidingVehicles[triggerId] = math.max(self.numToolsCollidingVehicles[triggerId] - 1, 0)
      end
    else
      local vehicle = g_currentMission.nodeToVehicle[otherId]
      if vehicle ~= nil and self.trafficCollisionIgnoreList[otherId] == nil then
        if onEnter then
          self.numToolsCollidingVehicles[triggerId] = self.numToolsCollidingVehicles[triggerId] + 1
        elseif onLeave then
          self.numToolsCollidingVehicles[triggerId] = math.max(self.numToolsCollidingVehicles[triggerId] - 1, 0)
        end
      end
    end
  end
end
function AITractor:updateToolsInfo()
  local leftMarker, rightMarker, backMarker
  local terrainDetailChannel1 = -1
  local terrainDetailChannel2 = -1
  for k, implement in pairs(self.attachedImplements) do
    local object = implement.object
    if object.aiLeftMarker ~= nil and leftMarker == nil then
      leftMarker = object.aiLeftMarker
    end
    if object.aiRightMarker ~= nil and rightMarker == nil then
      rightMarker = object.aiRightMarker
    end
    if object.aiBackMarker ~= nil and backMarker == nil then
      backMarker = object.aiBackMarker
    end
    if terrainDetailChannel1 < 0 and 0 <= object.aiTerrainDetailChannel1 then
      terrainDetailChannel1 = object.aiTerrainDetailChannel1
      if 0 <= object.aiTerrainDetailChannel2 then
        terrainDetailChannel2 = object.aiTerrainDetailChannel2
      end
    end
  end
  self.aiLeftMarker = leftMarker
  self.aiRightMarker = rightMarker
  self.aiBackMarker = backMarker
  self.aiTerrainDetailChannel1 = terrainDetailChannel1
  self.aiTerrainDetailChannel2 = terrainDetailChannel2
  self.aiToolsDirty = false
end

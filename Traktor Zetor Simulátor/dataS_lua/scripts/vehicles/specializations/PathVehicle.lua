PathVehicle = {}
PathVehicle.doDebugPrint = false
function PathVehicle.debugPrint(...)
  if PathVehicle.doDebugPrint then
    print(...)
  end
end
function PathVehicle.prerequisitesPresent(specializations)
  return SpecializationUtil.hasSpecialization(Motorized, specializations)
end
function PathVehicle:load(xmlFile)
  self.followSequence = SpecializationUtil.callSpecializationsFunction("followSequence")
  self.setupFromCrossroads = SpecializationUtil.callSpecializationsFunction("setupFromCrossroads")
  self.onCollidingTrafficVehicleDeleted = PathVehicle.onCollidingTrafficVehicleDeleted
  self.onTrafficCollisionTriggerNear = PathVehicle.onTrafficCollisionTriggerNear
  self.onTrafficCollisionTriggerFar = PathVehicle.onTrafficCollisionTriggerFar
  self.onTrafficCollisionTriggerOthers = PathVehicle.onTrafficCollisionTriggerOthers
  self.lookAheadDistance = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.lookAheadDistance#value"), 10)
  self.trafficCollisionTriggerFar = Utils.indexToObject(self.components, getXMLString(xmlFile, "vehicle.trafficCollisionTrigger#farIndex"))
  if self.trafficCollisionTriggerFar ~= nil then
    addTrigger(self.trafficCollisionTriggerFar, "onTrafficCollisionTriggerFar", self)
  end
  self.trafficCollisionTriggerNear = Utils.indexToObject(self.components, getXMLString(xmlFile, "vehicle.trafficCollisionTrigger#nearIndex"))
  if self.trafficCollisionTriggerNear ~= nil then
    addTrigger(self.trafficCollisionTriggerNear, "onTrafficCollisionTriggerNear", self)
  end
  self.trafficCollisionTriggerOthers = Utils.indexToObject(self.components, getXMLString(xmlFile, "vehicle.trafficCollisionTrigger#othersIndex"))
  if self.trafficCollisionTriggerOthers ~= nil then
    addTrigger(self.trafficCollisionTriggerOthers, "onTrafficCollisionTriggerOthers", self)
  end
  self.forceJunctionTime = g_currentMission.time + 20
  self.waitingForJunction = false
  self.collidingTrafficVehicles = {}
  self.nearCollidingTrafficVehicles = {}
  self.numCollidingVehicles = 0
  self.numNearCollidingVehicles = 0
  self.unableToDriveWaitingTime = 0
  self.collisionWaitingTime = 0
  self.maxCollisionWaitingTime = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.collisionWaitingTime#maxTime"), 20) * 1000
  self.honkWaitingTime = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.collisionWaitingTime#honkTime"), 20) * 1000
  self.pathFollowDirectionNode = Utils.indexToObject(self.components, getXMLString(xmlFile, "vehicle.pathFollowDirectionNode#index"))
  if self.pathFollowDirectionNode == nil then
    self.pathFollowDirectionNode = self.components[1].node
  end
  self.brakeDistance = 10
  self.vehicleWidth = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.size#width"), 2)
  self.vehicleLength = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.size#length"), 6)
  self.isPathVehicle = true
  self.lastSplineTime = 0
  self.currentRoad = nil
  self.currentDirection = RoadUtil.DIRECTION_FORWARD
  self.currentSequence = nil
  self.currentSequenceIndex = 1
  self.nextCrossroads = nil
  self.currentDestination = {0, 0}
  self.blockedVehicles = {}
  self.splineTransitionDistance = 0
  self.dtSum = 0
end
function PathVehicle:delete()
  for k, v in pairs(self.blockedVehicles) do
    k:onCollidingTrafficVehicleDeleted(self)
  end
  RoadUtil.onTrafficVehicleDeleted(self)
  if self.trafficCollisionTriggerFar ~= nil then
    removeTrigger(self.trafficCollisionTriggerFar)
  end
  if self.trafficCollisionTriggerNear ~= nil then
    removeTrigger(self.trafficCollisionTriggerNear)
  end
  if self.trafficCollisionTriggerOthers ~= nil then
    removeTrigger(self.trafficCollisionTriggerOthers)
  end
end
function PathVehicle:mouseEvent(posX, posY, isDown, isUp, button)
end
function PathVehicle:keyEvent(unicode, sym, modifier, isDown)
end
function PathVehicle:update(dt)
  self.dtSum = self.dtSum + dt
  if self.dtSum > 100 then
    PathVehicle.updateAIMovement(self, self.dtSum)
    self.dtSum = 0
  end
end
function PathVehicle:draw()
  if self.currentRoad then
    renderText(0.5, 0.3, 0.04, "Name: " .. getName(self.currentRoad.spline))
    renderText(0.5, 0.36, 0.04, string.format("SplineTime: %f", self.lastSplineTime))
    renderText(0.5, 0.42, 0.04, string.format("Direction: %d", self.currentDirection))
    local timeDir = 1
    if self.currentDirection == RoadUtil.DIRECTION_BACKWARD then
      timeDir = -1
    end
    local splinePosTime = math.min(self.lastSplineTime + self.lookAheadDistance / self.splineLength * timeDir, 1)
    renderText(0.5, 0.48, 0.04, string.format("splinePosTime: %f", splinePosTime))
    renderText(0.5, 0.54, 0.04, string.format("Num traffic vehicles: %d", table.getn(g_currentMission.trafficVehicles)))
  end
end
function PathVehicle:updateAIMovement(dt)
  local allowedToDrive = true
  self.collisionWaitingTime = self.collisionWaitingTime + dt
  allowedToDrive = allowedToDrive and not self.waitingForJunction and self.numCollidingVehicles <= 0 and 0 >= self.numNearCollidingVehicles
  if allowedToDrive then
    self.collisionWaitingTime = 0
  end
  if self.currentRoad ~= nil then
    self.steeringEnabled = false
    self.unableToDriveWaitingTime = self.unableToDriveWaitingTime + dt
    if math.abs(self.lastSpeed) > 1.0E-5 then
      self.unableToDriveWaitingTime = 0
    end
    if self.collisionWaitingTime > self.honkWaitingTime then
    end
    if self.collisionWaitingTime > self.maxCollisionWaitingTime then
      PathVehicle.setVehicleToDeleted(self)
      return
    end
    if self.unableToDriveWaitingTime > self.maxCollisionWaitingTime then
      PathVehicle.setVehicleToDeleted(self)
      return
    end
    local timeDir = 1
    if self.currentDirection == RoadUtil.DIRECTION_BACKWARD then
      timeDir = -1
    end
    local nearestTime = PathVehicle.getNearestPositionOfSpline(self, self.lastSplineTime, 3 / self.splineLength, 0.5 / self.splineLength, self.currentRoad.spline, timeDir)
    self.lastSplineTime = nearestTime
    self.splineTransitionDistance = math.max(self.splineTransitionDistance - self.lastSpeed * dt, 0)
    local aheadDistance = math.max(self.lookAheadDistance - self.splineTransitionDistance, 0)
    local splinePosTime = math.min(nearestTime + aheadDistance / self.splineLength * timeDir, 1)
    if self.nextCrossroads ~= nil and splinePosTime * timeDir >= self.nextCrossroads.timePos * timeDir then
      local distanceOn1 = math.max(timeDir * (self.nextCrossroads.timePos - nearestTime), 0) * self.splineLength
      self:setupFromCrossroads()
      timeDir = 1
      if self.currentDirection == RoadUtil.DIRECTION_BACKWARD then
        timeDir = -1
      end
      local distanceOn2 = self.lookAheadDistance - distanceOn1
      self.splineTransitionDistance = distanceOn1
      splinePosTime = self.lastSplineTime + timeDir * math.min(distanceOn2 / self.splineLength, 1)
      PathVehicle.debugPrint(string.format("self.lastSplineTime: %f nearestTime: %f distanceOn1: %f distanceOn2: %f splinePosTime: %f", self.lastSplineTime, nearestTime, distanceOn1, distanceOn2, splinePosTime))
    end
    local node = self.pathFollowDirectionNode
    if self.currentRoad == nil or self.nextCrossroads == nil and (0 < timeDir and 1 <= splinePosTime or timeDir < 0 and splinePosTime <= 0) then
      PathVehicle.debugPrint(self.currentSequenceIndex, " ", timeDir, " ", splinePosTime)
      PathVehicle.setVehicleToDeleted(self)
      self.currentRoad = nil
      return
    end
    local myX, myY, myZ = getWorldTranslation(node)
    local x, y, z = PathVehicle.getTrackPosition(self.currentRoad, splinePosTime, self.currentDirection)
    y = myY
    self.currentDestination[1] = x
    self.currentDestination[2] = z
    local lx, lz = AIVehicleUtil.getDriveDirection(node, x, y, z)
    local colDirX = lx
    local colDirZ = lz
    if self.trafficCollisionTriggerNear ~= nil then
      AIVehicleUtil.setCollisionDirection(node, self.trafficCollisionTriggerNear, colDirX, colDirZ)
    end
    if self.trafficCollisionTriggerOthers ~= nil then
      AIVehicleUtil.setCollisionDirection(node, self.trafficCollisionTriggerOthers, colDirX, colDirZ)
    end
    AIVehicleUtil.driveInDirection(self, dt, 30, 1, 0.7, 26, allowedToDrive, true, lx, lz)
  else
    PathVehicle.setVehicleToDeleted(self)
  end
end
function PathVehicle:followSequence(sequence, loopIndex, setPosition)
  self.currentSequence = sequence
  self.currentLoopIndex = loopIndex
  self.currentSequenceIndex = 2
  self.currentRoad = sequence[1].road2
  self.currentDirection = sequence[1].directionOnRoad2
  self.lastSplineTime = sequence[1].timePos2
  self.nextCrossroads = self.currentSequence[2]
  self.splineLength = getSplineLength(self.currentRoad.spline)
  if setPosition then
    local x, y, z = PathVehicle.getTrackPosition(self.currentRoad, self.lastSplineTime, self.currentDirection)
    local dx, dy, dz = getSplineDirection(self.currentRoad.spline, self.lastSplineTime)
    if self.currentDirection == RoadUtil.DIRECTION_BACKWARD then
      dx = -dx
      dz = -dz
    end
    local node = self.pathFollowDirectionNode
    self:setRelativePosition(x, 1.5, z, Utils.getYRotationFromDirection(dx, dz))
  end
end
function PathVehicle:setupFromCrossroads()
  PathVehicle.debugPrint("switch road")
  if self.nextCrossroads ~= nil then
    self.currentRoad = self.nextCrossroads.road2
    self.currentDirection = self.nextCrossroads.directionOnRoad2
    self.lastSplineTime = self.nextCrossroads.timePos2
    self.currentSequenceIndex = self.currentSequenceIndex + 1
    if self.currentSequenceIndex > table.getn(self.currentSequence) then
      if self.currentLoopIndex ~= 0 and self.currentRoad ~= nil then
        self.nextCrossroads = self.currentSequence[self.currentLoopIndex]
        self.currentSequenceIndex = self.currentLoopIndex
      else
        self.nextCrossroads = nil
      end
    else
      self.nextCrossroads = self.currentSequence[self.currentSequenceIndex]
    end
    local roadName = "end"
    if self.currentRoad ~= nil then
      self.splineLength = getSplineLength(self.currentRoad.spline)
      roadName = getName(self.currentRoad.spline)
    end
    PathVehicle.debugPrint(" new spline: " .. roadName)
    PathVehicle.debugPrint("   direction " .. self.currentDirection)
    PathVehicle.debugPrint("   lastSplineTime " .. self.lastSplineTime)
  end
end
function PathVehicle:getNearestPositionOfSpline(startTime, length, stepSize, spline, timeDir)
  local vx, vy, vz = getWorldTranslation(self.pathFollowDirectionNode)
  local nearestTime = startTime
  local nearestDistance = 999999999
  startTime = math.min(math.max(startTime - timeDir * stepSize, 0), 1)
  local endTime = math.min(startTime + length, 1)
  if timeDir < 0 then
    endTime = startTime
    startTime = math.max(startTime - length, 0)
  end
  for i = startTime, endTime, stepSize do
    local x, y, z = getSplinePosition(spline, i)
    local dist = Utils.vector2Length(x - vx, z - vz)
    if nearestDistance > dist then
      nearestDistance = dist
      nearestTime = i
    end
  end
  return nearestTime
end
function PathVehicle.getTrackPosition(road, t, direction)
  if road.isOneWay or road.trackDistance == 0 then
    return getSplinePosition(road.spline, t)
  else
    local x, y, z = getSplinePosition(road.spline, t)
    local dx, dy, dz = getSplineDirection(road.spline, t)
    local sideX, sideY, sideZ
    if direction == RoadUtil.DIRECTION_FORWARD then
      sideX, sideY, sideZ = Utils.crossProduct(dx, dy, dz, 0, 1, 0)
    else
      sideX, sideY, sideZ = Utils.crossProduct(dx, dy, dz, 0, -1, 0)
    end
    local sideScale = road.trackDistance * 0.5 / Utils.vector2Length(sideX, sideZ)
    return x + sideX * sideScale, y, z + sideZ * sideScale
  end
end
function PathVehicle:setVehicleToDeleted()
  local x, y, z = getWorldTranslation(self.pathFollowDirectionNode)
  if PathVehicle.isVehicleAllowedToChange(x, y, z, 50, 100) then
    g_currentMission:removeVehicle(self)
  end
end
function PathVehicle.isVehicleAllowedToChange(x, y, z, nearDist, farDist)
  local cam = getCamera()
  local cx, cy, cz = getWorldTranslation(cam)
  local dx = x - cx
  local dy = y - cy
  local dz = z - cz
  local dist = Utils.vector3Length(dx, dy, dz)
  if nearDist < dist then
    if farDist < dist then
      return true
    else
      local dirX, dirY, dirZ = localDirectionToWorld(cam, 0, 0, -1)
      if dirX * dx + dirY * dy + dirZ * dz < -0.766 * dist then
        return true
      end
    end
  end
  return false
end
function PathVehicle:onTrafficCollisionTriggerOthers(triggerId, otherId, onEnter, onLeave, onStay, otherShapeId)
  if onEnter or onLeave then
    if otherId == Player.rootNode then
      if onEnter then
        self.numCollidingVehicles = self.numCollidingVehicles + 1
      elseif onLeave then
        self.numCollidingVehicles = math.max(self.numCollidingVehicles - 1, 0)
      end
    else
      local vehicle = g_currentMission.nodeToVehicle[otherId]
      if vehicle ~= nil and vehicle ~= self and (vehicle.isPathVehicle == nil or not vehicle.isPathVehicle) then
        if onEnter then
          self.numCollidingVehicles = self.numCollidingVehicles + 1
        elseif onLeave then
          self.numCollidingVehicles = math.max(self.numCollidingVehicles - 1, 0)
        end
      end
    end
  end
end
function PathVehicle:onTrafficCollisionTriggerNear(triggerId, otherId, onEnter, onLeave, onStay, otherShapeId)
  if onEnter or onLeave then
    local vehicle = g_currentMission.nodeToVehicle[otherId]
    if vehicle ~= nil and vehicle ~= self and vehicle.isPathVehicle then
      if onEnter then
        if self.nearCollidingTrafficVehicles[vehicle] == nil then
          self.nearCollidingTrafficVehicles[vehicle] = vehicle
          self.numNearCollidingVehicles = self.numNearCollidingVehicles + 1
          vehicle.blockedVehicles[self] = Utils.getNoNil(vehicle.blockedVehicles[self], 0) + 1
        end
      elseif onLeave and self.nearCollidingTrafficVehicles[vehicle] ~= nil then
        self.nearCollidingTrafficVehicles[vehicle] = nil
        self.numNearCollidingVehicles = self.numNearCollidingVehicles - 1
        if vehicle.blockedVehicles[self] == 1 then
          vehicle.blockedVehicles[self] = nil
        else
          vehicle.blockedVehicles[self] = vehicle.blockedVehicles[self] - 1
        end
      end
    end
  end
end
function PathVehicle:onTrafficCollisionTriggerFar(triggerId, otherId, onEnter, onLeave, onStay, otherShapeId)
  if onEnter or onLeave then
    local vehicle = g_currentMission.nodeToVehicle[otherId]
    if vehicle ~= nil and vehicle ~= self and vehicle.isPathVehicle then
      if onEnter then
        self.collidingTrafficVehicles[vehicle] = vehicle
        vehicle.blockedVehicles[self] = Utils.getNoNil(vehicle.blockedVehicles[self], 0) + 1
      elseif onLeave then
        self.collidingTrafficVehicles[vehicle] = nil
        if vehicle.blockedVehicles[self] == 1 then
          vehicle.blockedVehicles[self] = nil
        else
          vehicle.blockedVehicles[self] = vehicle.blockedVehicles[self] - 1
        end
      end
    end
  end
end
function PathVehicle:onCollidingTrafficVehicleDeleted(vehicle)
  self.collidingTrafficVehicles[vehicle] = nil
  if self.nearCollidingTrafficVehicles[vehicle] ~= nil then
    self.nearCollidingTrafficVehicles[vehicle] = nil
    self.numNearCollidingVehicles = self.numNearCollidingVehicles - 1
  end
  self.blockedVehicles[vehicle] = nil
end
function PathVehicle.isProblem(col, t1, t2, minTime1, minTime2)
  return col and minTime1 < t1 and minTime2 < t2
end

Attachable = {}
function Attachable.prerequisitesPresent(specializations)
  return true
end
function Attachable:load(xmlFile)
  self.onAttach = SpecializationUtil.callSpecializationsFunction("onAttach")
  self.onDetach = SpecializationUtil.callSpecializationsFunction("onDetach")
  self.onSelect = SpecializationUtil.callSpecializationsFunction("onSelect")
  self.onDeselect = SpecializationUtil.callSpecializationsFunction("onDeselect")
  self.onBrake = SpecializationUtil.callSpecializationsFunction("onBrake")
  self.onReleaseBrake = SpecializationUtil.callSpecializationsFunction("onReleaseBrake")
  self.aiTurnOn = SpecializationUtil.callSpecializationsFunction("aiTurnOn")
  self.aiTurnOff = SpecializationUtil.callSpecializationsFunction("aiTurnOff")
  self.aiLower = SpecializationUtil.callSpecializationsFunction("aiLower")
  self.aiRaise = SpecializationUtil.callSpecializationsFunction("aiRaise")
  self.aiRotateLeft = SpecializationUtil.callSpecializationsFunction("aiRotateLeft")
  self.aiRotateRight = SpecializationUtil.callSpecializationsFunction("aiRotateRight")
  self.name = Utils.getNoNil(getXMLString(xmlFile, "vehicle.name." .. g_languageShort), "Attachable")
  local attacherJoint = {}
  attacherJoint.node = Utils.indexToObject(self.components, getXMLString(xmlFile, "vehicle.attacherJoint#index"))
  if attacherJoint.node ~= nil then
    attacherJoint.topReferenceNode = Utils.indexToObject(self.components, getXMLString(xmlFile, "vehicle.attacherJoint#topReferenceNode"))
    attacherJoint.rootNode = Utils.getNoNil(Utils.indexToObject(self.components, getXMLString(xmlFile, "vehicle.attacherJoint#rootNode")), self.components[1].node)
    attacherJoint.fixedRotation = Utils.getNoNil(getXMLBool(xmlFile, "vehicle.attacherJoint#fixedRotation"), false)
    attacherJoint.allowsJointRotLimitMovement = Utils.getNoNil(getXMLBool(xmlFile, "vehicle.attacherJoint#allowsJointRotLimitMovement"), true)
    attacherJoint.allowsJointTransLimitMovement = Utils.getNoNil(getXMLBool(xmlFile, "vehicle.attacherJoint#allowsJointTransLimitMovement"), true)
    local x, y, z = Utils.getVectorFromString(getXMLString(xmlFile, "vehicle.attacherJoint#rotLimitScale"))
    attacherJoint.rotLimitScale = {
      Utils.getNoNil(x, 1),
      Utils.getNoNil(y, 1),
      Utils.getNoNil(z, 1)
    }
    local x, y, z = Utils.getVectorFromString(getXMLString(xmlFile, "vehicle.attacherJoint#transLimitScale"))
    attacherJoint.transLimitScale = {
      Utils.getNoNil(x, 1),
      Utils.getNoNil(y, 1),
      Utils.getNoNil(z, 1)
    }
    local jointTypeStr = getXMLString(xmlFile, "vehicle.attacherJoint#jointType")
    local jointType
    if jointTypeStr ~= nil then
      jointType = Vehicle.jointTypeNameToInt[jointTypeStr]
      if jointType == nil then
        print("Warning: invalid jointType " .. jointTypeStr)
      end
    else
      print("Warning: missing jointType")
    end
    if jointType == nil then
      local needsTrailerJoint = Utils.getNoNil(getXMLBool(xmlFile, "vehicle.attacherJoint#needsTrailerJoint"), false)
      local needsLowTrailerJoint = Utils.getNoNil(getXMLBool(xmlFile, "vehicle.attacherJoint#needsLowJoint"), false)
      if needsTrailerJoint then
        if needsLowTrailerJoint then
          jointType = Vehicle.JOINTTYPE_TRAILERLOW
        else
          jointType = Vehicle.JOINTTYPE_TRAILER
        end
      else
        jointType = Vehicle.JOINTTYPE_IMPLEMENT
      end
    end
    attacherJoint.jointType = jointType
    self.attacherJoint = attacherJoint
  end
  if getXMLString(xmlFile, "vehicle.topReferenceNode#index") ~= nil then
    print("Warning: vehicle.topReferenceNode is ignored, update to vehicle.attacherJoint#topReferenceNode")
  end
  if getXMLString(xmlFile, "vehicle.attachRootNode#index") ~= nil then
    print("Warning: vehicle.attachRootNode is ignored, update to vehicle.attacherJoint#rootNode")
  end
  self.brakeForce = Utils.getNoNil(getXMLInt(xmlFile, "vehicle.brakeForce"), 0) * 10
  self.isBraking = true
  self.updateWheels = true
  self.updateSteeringAxleAngle = true
  self.isSelected = false
  self.attachTime = 0
  local defaultNeedsLowering = true
  if self.attacherJoint ~= nil and (self.attacherJoint.jointType == Vehicle.JOINTTYPE_TRAILER or self.attacherJoint.jointType == Vehicle.JOINTTYPE_TRAILERLOW) then
    defaultNeedsLowering = false
  end
  self.needsLowering = Utils.getNoNil(getXMLBool(xmlFile, "vehicle.needsLowering#value"), defaultNeedsLowering)
  local defaultAllowsLowering = false
  if self.attacherJoint ~= nil and self.attacherJoint.jointType ~= Vehicle.JOINTTYPE_TRAILER and self.attacherJoint.jointType ~= Vehicle.JOINTTYPE_TRAILERLOW then
    defaultAllowsLowering = true
  end
  self.allowsLowering = Utils.getNoNil(getXMLBool(xmlFile, "vehicle.allowsLowering#value"), defaultAllowsLowering)
  self.isDefaultLowered = Utils.getNoNil(getXMLBool(xmlFile, "vehicle.isDefaultLowered#value"), false)
  self.steeringAxleAngleScaleStart = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.steeringAxleAngleScale#startSpeed"), 10)
  self.steeringAxleAngleScaleEnd = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.steeringAxleAngleScale#endSpeed"), 30)
  self.aiLeftMarker = Utils.indexToObject(self.components, getXMLString(xmlFile, "vehicle.aiLeftMarker#index"))
  self.aiRightMarker = Utils.indexToObject(self.components, getXMLString(xmlFile, "vehicle.aiRightMarker#index"))
  self.aiBackMarker = Utils.indexToObject(self.components, getXMLString(xmlFile, "vehicle.aiBackMarker#index"))
  self.aiTrafficCollisionTrigger = Utils.indexToObject(self.components, getXMLString(xmlFile, "vehicle.aiTrafficCollisionTrigger#index"))
  self.aiNeedsLowering = Utils.getNoNil(getXMLBool(xmlFile, "vehicle.aiNeedsLowering#value"), self.needsLowering)
  self.aiForceTurnNoBackward = Utils.getNoNil(getXMLBool(xmlFile, "vehicle.aiForceTurnNoBackward#value"), false)
  self.aiTerrainDetailChannel1 = -1
  self.aiTerrainDetailChannel2 = -1
  self.deactivateOnDetach = true
end
function Attachable:delete()
  if self.attacherVehicle ~= nil then
    self.attacherVehicle:detachImplementByObject(self)
  end
end
function Attachable:mouseEvent(posX, posY, isDown, isUp, button)
end
function Attachable:keyEvent(unicode, sym, modifier, isDown)
end
function Attachable:update(dt)
  if self:getIsActive() then
    if self.updateSteeringAxleAngle then
      if self.attacherVehicle ~= nil and self.movingDirection >= 0 then
        local x, y, z = worldDirectionToLocal(self.steeringAxleNode, localDirectionToWorld(self.attacherVehicle.steeringAxleNode, 0, 0, 1))
        local dot = z
        dot = dot / Utils.vector2Length(x, z)
        local angle = math.acos(dot)
        if x < 0 then
          angle = -angle
        end
        local startSpeed = self.steeringAxleAngleScaleStart
        local endSpeed = self.steeringAxleAngleScaleEnd
        local scale = Utils.clamp(1 + (self.lastSpeed * 3600 - startSpeed) * 1 / (startSpeed - endSpeed), 0, 1)
        self.steeringAxleAngle = angle * scale
      else
        self.steeringAxleAngle = 0
      end
    end
    if self.firstTimeRun and self.updateWheels then
      local brakeForce = 0
      if self.isBraking then
        brakeForce = self.brakeForce
      end
      for k, wheel in pairs(self.wheels) do
        setWheelShapeProps(wheel.node, wheel.wheelShape, 0, brakeForce, wheel.steeringAngle)
      end
    end
  end
end
function Attachable:draw()
end
function Attachable:onAttach(attacherVehicle)
  self.attacherVehicle = attacherVehicle
  self:setLightsVisibility(attacherVehicle.lightsActive)
  self.attachTime = self.time
  self:onReleaseBrake()
end
function Attachable:onDetach()
  if self.deactivateOnDetach then
    Attachable.onDeactivate(self)
  else
    self:setLightsVisibility(false)
  end
  self.attacherVehicle = nil
end
function Attachable:onDeactivate()
  self:onBrake(true)
  self.steeringAxleAngle = 0
  self:setLightsVisibility(false)
end
function Attachable:onSelect()
  self.isSelected = true
end
function Attachable:onDeselect()
  self.isSelected = false
end
function Attachable:onBrake(forced)
  if self.attachTime + 2000 < self.time or forced then
    self.isBraking = true
    for k, wheel in pairs(self.wheels) do
      setWheelShapeProps(wheel.node, wheel.wheelShape, 0, self.brakeForce, wheel.steeringAngle)
    end
    for k, implement in pairs(self.attachedImplements) do
      implement.object:onBrake(forced)
    end
  end
end
function Attachable:onReleaseBrake()
  self.isBraking = false
  for k, wheel in pairs(self.wheels) do
    setWheelShapeProps(wheel.node, wheel.wheelShape, 0, 0, wheel.steeringAngle)
  end
  for k, implement in pairs(self.attachedImplements) do
    implement.object:onReleaseBrake()
  end
end

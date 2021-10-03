Steerable = {}
function Steerable.prerequisitesPresent(specializations)
  return SpecializationUtil.hasSpecialization(Motorized, specializations)
end
function Steerable:load(xmlFile)
  self.onEnter = SpecializationUtil.callSpecializationsFunction("onEnter")
  self.onLeave = SpecializationUtil.callSpecializationsFunction("onLeave")
  self.drawGrainLevel = SpecializationUtil.callSpecializationsFunction("drawGrainLevel")
  self.enterReferenceNode = Utils.indexToObject(self.components, getXMLString(xmlFile, "vehicle.enterReferenceNode#index"))
  self.exitPoint = Utils.indexToObject(self.components, getXMLString(xmlFile, "vehicle.exitPoint#index"))
  self.steering = Utils.indexToObject(self.components, getXMLString(xmlFile, "vehicle.steering#index"))
  if self.steering ~= nil then
    self.steeringSpeed = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.steering#rotationSpeed"), 0)
  end
  self.numCameras = Utils.getNoNil(getXMLInt(xmlFile, "vehicle.cameras#count"), 0)
  if self.numCameras == 0 then
    print("Error: no cameras in xml file: ", configFile)
  end
  self.cameras = {}
  for i = 1, self.numCameras do
    local cameranamei = string.format("vehicle.cameras.camera%d", i)
    local camIndexStr = getXMLString(xmlFile, cameranamei .. "#index")
    local cameraNode = Utils.indexToObject(self.components, camIndexStr)
    local rotatable = getXMLBool(xmlFile, cameranamei .. "#rotatable")
    local limit = getXMLBool(xmlFile, cameranamei .. "#limit")
    local rotMinX = getXMLFloat(xmlFile, cameranamei .. "#rotMinX")
    local rotMaxX = getXMLFloat(xmlFile, cameranamei .. "#rotMaxX")
    local transMin = getXMLFloat(xmlFile, cameranamei .. "#transMin")
    local transMax = getXMLFloat(xmlFile, cameranamei .. "#transMax")
    local rotateNode = ""
    if rotatable then
      rotateNode = Utils.indexToObject(self.components, getXMLString(xmlFile, cameranamei .. "#rotateNode"))
    end
    self.cameras[i] = VehicleCamera:new(cameraNode, rotatable, rotateNode, limit, rotMinX, rotMaxX, transMin, transMax)
  end
  self.camIndex = 1
  self.tipCamera = Utils.indexToObject(self.components, getXMLString(xmlFile, "vehicle.tipCamera#index"))
  self.characterNode = Utils.indexToObject(self.components, getXMLString(xmlFile, "vehicle.characterNode#index"))
  if self.characterNode ~= nil then
    self.characterCameraMinDistance = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.characterNode#cameraMinDistance"), 1.5)
    setVisibility(self.characterNode, false)
  end
  self.speedRotScale = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.speedRotScale#scale"), 80)
  self.speedRotScaleOffset = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.speedRotScale#offset"), 0.7)
  self.isEntered = false
  self.steeringEnabled = true
  self.stopMotorOnLeave = true
  self.disableCharacterOnLeave = true
  self.deactivateOnLeave = true
  self.stopRefuelOnLeave = true
  self.deactivateLightsOnLeave = true
  self.showWaterWarning = false
  self.waterSplashSample = nil
  self.hudBasePoxX = 0.8325
  self.hudBasePoxY = 0.010000000000000009
  self.hudBaseWidth = 0.16
  self.hudBaseHeight = 0.1625
  self.hudBaseOverlay = Overlay:new("hudBaseOverlay", "dataS/missions/hud_vehicle_base" .. g_languageSuffix .. ".png", self.hudBasePoxX, self.hudBasePoxY, self.hudBaseWidth, self.hudBaseHeight)
end
function Steerable:delete()
  for i = 1, table.getn(self.cameras) do
    self.cameras[i]:delete()
  end
  if self.waterSplashSample ~= nil then
    delete(self.waterSplashSample)
  end
  if self.hudBaseOverlay then
    self.hudBaseOverlay:delete()
  end
end
function Steerable:mouseEvent(posX, posY, isDown, isUp, button)
  self.cameras[self.camIndex]:mouseEvent(posX, posY, isDown, isUp, button)
end
function Steerable:keyEvent(unicode, sym, modifier, isDown)
end
function Steerable:update(dt)
  if self:getIsActive() then
    if self.steering ~= nil then
      setRotation(self.steering, 0, self.rotatedTime * self.steeringSpeed, 0)
    end
    local xt, yt, zt = getTranslation(self.components[1].node)
    local deltaWater = yt - g_currentMission.waterY + 2.5
    if deltaWater < 0 then
      self.isBroken = true
      g_currentMission:onSunkVehicle()
      if self.isEntered then
        g_currentMission:onLeaveVehicle()
        if self:getIsActiveForSound() then
          local volume = math.min(1, self.lastSpeed * 3600 / 30)
          if self.waterSplashSample == nil then
            self.waterSplashSample = createSample("waterSplashSample")
            loadSample(self.waterSplashSample, "data/maps/sounds/waterSplash.wav", false)
          end
          playSample(self.waterSplashSample, 1, volume, 0)
        end
      end
    end
    self.showWaterWarning = deltaWater < 2
  end
  if self.isEntered then
    if InputBinding.hasEvent(InputBinding.REFUEL) then
      if self.doRefuel then
        self:stopRefuel()
      else
        self:startRefuel()
      end
    end
    if self.characterNode ~= nil then
      local cx, cy, cz = getWorldTranslation(self.characterNode)
      local x, y, z = getWorldTranslation(getCamera())
      local dist = Utils.vector3Length(cx - x, cy - y, cz - z)
      if dist < self.characterCameraMinDistance then
        setVisibility(self.characterNode, false)
      else
        setVisibility(self.characterNode, true)
      end
    end
    if not g_currentMission.fixedCamera then
      setCamera(self.cameras[self.camIndex].cameraNode)
      self.cameras[self.camIndex]:update(dt)
    elseif self.tipCamera ~= nil then
      setCamera(self.tipCamera)
    else
      self.cameras[self.camIndex]:resetCamera()
    end
    if self.steeringEnabled then
      local fuelUsed = self.lastMovedDistance * self.fuelUsage
      self:setFuelFillLevel(self.fuelFillLevel - fuelUsed)
      g_currentMission.missionStats.fuelUsageTotal = g_currentMission.missionStats.fuelUsageTotal + fuelUsed
      g_currentMission.missionStats.fuelUsageSession = g_currentMission.missionStats.fuelUsageSession + fuelUsed
      g_currentMission.missionStats.traveledDistanceTotal = g_currentMission.missionStats.traveledDistanceTotal + self.lastMovedDistance * 0.001
      g_currentMission.missionStats.traveledDistanceSession = g_currentMission.missionStats.traveledDistanceSession + self.lastMovedDistance * 0.001
      local acceleration = 0
      if g_currentMission.allowSteerableMoving and not self.playMotorSound then
        acceleration = -InputBinding.getAnalogInputAxis(InputBinding.AXIS_FORWARD)
        if InputBinding.isAxisZero(acceleration) then
          acceleration = -InputBinding.getDigitalInputAxis(InputBinding.AXIS_FORWARD)
        end
        if math.abs(acceleration) > 0.8 then
          self.motor:setSpeedLevel(0, true)
        end
        if self.motor.speedLevel ~= 0 then
          acceleration = 1
        end
      end
      if self.fuelFillLevel == 0 then
        acceleration = 0
      end
      local inputAxisX = InputBinding.getAnalogInputAxis(InputBinding.AXIS_SIDE)
      if not InputBinding.isAxisZero(inputAxisX) then
        if inputAxisX < 0 then
          self.rotatedTime = math.min(-self.maxRotTime * inputAxisX, self.maxRotTime)
        else
          self.rotatedTime = math.max(self.minRotTime * inputAxisX, self.minRotTime)
        end
      else
        local rotScale = math.min(1 / (self.lastSpeed * self.speedRotScale + self.speedRotScaleOffset), 1)
        local inputAxisX = InputBinding.getDigitalInputAxis(InputBinding.AXIS_SIDE)
        if inputAxisX < 0 then
          self.rotatedTime = math.min(self.rotatedTime - dt / 1000 * inputAxisX * rotScale, self.maxRotTime)
        elseif 0 < inputAxisX then
          self.rotatedTime = math.max(self.rotatedTime - dt / 1000 * inputAxisX * rotScale, self.minRotTime)
        elseif self.autoRotateBackSpeed ~= 0 then
          if 0 < self.rotatedTime then
            self.rotatedTime = math.max(self.rotatedTime - dt / 1000 * self.autoRotateBackSpeed * rotScale, 0)
          else
            self.rotatedTime = math.min(self.rotatedTime + dt / 1000 * self.autoRotateBackSpeed * rotScale, 0)
          end
        end
      end
      if self.firstTimeRun then
        WheelsUtil.updateWheelsPhysics(self, dt, self.lastSpeed, acceleration, false, self.requiredDriveMode)
      end
    end
    if InputBinding.hasEvent(InputBinding.SWITCH_IMPLEMENT) then
      local selected = self.selectedImplement
      local numImplements = table.getn(self.attachedImplements)
      if selected ~= 0 and 1 < numImplements then
        selected = selected + 1
        if numImplements < selected then
          selected = 1
        end
        self:setSelectedImplement(selected)
      end
    end
    if not g_currentMission.fixedCamera and InputBinding.hasEvent(InputBinding.CAMERA_SWITCH) then
      self.cameras[self.camIndex]:onDeactivate()
      self.camIndex = self.camIndex + 1
      if self.camIndex > self.numCameras then
        self.camIndex = 1
      end
      self.cameras[self.camIndex]:onActivate()
    end
    if InputBinding.hasEvent(InputBinding.TOGGLE_LIGHTS) then
      self:setLightsVisibility(not self.lightsActive)
    end
    if InputBinding.hasEvent(InputBinding.SPEED_LEVEL1) then
      self.motor:setSpeedLevel(1, false)
    elseif InputBinding.hasEvent(InputBinding.SPEED_LEVEL2) then
      self.motor:setSpeedLevel(2, false)
    elseif InputBinding.hasEvent(InputBinding.SPEED_LEVEL3) then
      self.motor:setSpeedLevel(3, false)
    end
    if InputBinding.hasEvent(InputBinding.ATTACH) then
      self:handleAttachEvent()
    end
    if InputBinding.hasEvent(InputBinding.LOWER_IMPLEMENT) then
      self:handleLowerImplementEvent()
    end
  end
end
function Steerable:draw()
  local kmh = self.lastSpeed * self.speedDisplayScale * 3600
  self.hudBaseOverlay:render()
  setTextBold(true)
  setTextColor(1, 1, 1, 1)
  if 0 < kmh and kmh < 100 then
    setTextAlignment(RenderText.ALIGN_RIGHT)
    renderText(self.hudBasePoxX + 0.053, self.hudBasePoxY + 0.095, 0.06, string.format("%2d", kmh))
    setTextAlignment(RenderText.ALIGN_LEFT)
  end
  renderText(self.hudBasePoxX + 0.062, self.hudBasePoxY + 0.097, 0.05, g_i18n:getText("speedometer"))
  renderText(self.hudBasePoxX + 0.031, self.hudBasePoxY + 0.071, 0.03, string.format("%d", g_currentMission.missionStats.money))
  local fuelWarn = 50
  if fuelWarn > self.fuelFillLevel then
    setTextColor(1, 0, 0, 1)
  end
  renderText(self.hudBasePoxX + 0.031, self.hudBasePoxY + 0.039, 0.03, string.format("%d " .. g_i18n:getText("fluid_unit_long"), self.fuelFillLevel))
  if fuelWarn > self.fuelFillLevel then
    setTextColor(1, 1, 1, 1)
  end
  setTextBold(false)
  if self.hasRefuelStationInRange and not self.doRefuel and self.fuelFillLevel ~= self.fuelCapacity then
    g_currentMission:addHelpButtonText(g_i18n:getText("Refuel"), InputBinding.REFUEL)
    g_currentMission.hudFuelOverlay:render()
  end
  if self.showWaterWarning then
    g_currentMission:addWarning(g_i18n:getText("Dont_drive_to_depth_into_the_water"), 0.05, 0.032)
  end
  local trailerFillLevel, trailerCapacity = self:getAttachedTrailersFillLevelAndCapacity()
  if trailerFillLevel ~= nil and trailerCapacity ~= nil then
    self:drawGrainLevel(trailerFillLevel, trailerCapacity, 101)
  end
  if 1 < table.getn(self.attachedImplements) then
    g_currentMission:addHelpButtonText(g_i18n:getText("Change_tools"), InputBinding.SWITCH_IMPLEMENT)
  end
end
function Steerable:onEnter()
  self.isEntered = true
  self:startMotor()
  self.camIndex = 1
  self.cameras[self.camIndex]:onActivate()
  if self.characterNode ~= nil then
    setVisibility(self.characterNode, true)
  end
  self:onActivateAttachements()
end
function Steerable:onLeave()
  self.cameras[self.camIndex]:onDeactivate()
  if self.stopRefuelOnLeave then
    self:stopRefuel()
  end
  if self.deactivateLightsOnLeave then
    self:setLightsVisibility(false)
  end
  if self.characterNode ~= nil then
    if self.disableCharacterOnLeave then
      setVisibility(self.characterNode, false)
    else
      setVisibility(self.characterNode, true)
    end
  end
  if self.stopMotorOnLeave then
    self:stopMotor()
  else
    Motorized.stopSounds(self)
  end
  if self.deactivateOnLeave then
    for k, wheel in pairs(self.wheels) do
      setWheelShapeProps(wheel.node, wheel.wheelShape, 0, self.motor.brakeForce, 0)
    end
    self:onDeactivateAttachements()
  else
    if self.deactivateLightsOnLeave then
      self:onDeactivateAttachementsLights()
    end
    self:onDeactivateAttachementsSounds()
  end
  self.isEntered = false
end
function Steerable:drawGrainLevel(level, capacity, warnPercent)
  local percent = 0
  if 0 < capacity then
    percent = level / capacity * 100
  end
  setTextBold(true)
  if warnPercent <= percent then
    setTextColor(1, 0, 0, 1)
  else
    setTextColor(1, 1, 1, 1)
  end
  renderText(self.hudBasePoxX + 0.031, self.hudBasePoxY + 0.006, 0.03, string.format("%d(%d%%)", level, percent))
  if warnPercent <= percent then
    setTextColor(1, 1, 1, 1)
  end
  setTextBold(false)
end

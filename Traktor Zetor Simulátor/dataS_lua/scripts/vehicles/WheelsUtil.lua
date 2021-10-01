WheelsUtil = {}
function WheelsUtil:updateWheelsPhysics(dt, currentSpeed, acceleration, doHandbrake, requiredDriveMode)
  local brakeAcc = false
  if self.movingDirection * currentSpeed * acceleration < -0.001 then
    brakeAcc = true
  end
  local accelerationPedal, brakePedal
  if math.abs(acceleration) < 0.001 then
    accelerationPedal = 0
    brakePedal = 1
  elseif not brakeAcc then
    accelerationPedal = acceleration
    brakePedal = 0
  else
    accelerationPedal = 0
    brakePedal = math.abs(acceleration)
  end
  local numTouching = 0
  local numNotTouching = 0
  local numHandbrake = 0
  local axleSpeedSum = 0
  self.lastWheelRpm = 0
  for k, wheel in pairs(self.wheels) do
    local hasGroundContact = wheel.hasGroundContact
    if requiredDriveMode <= wheel.driveMode then
      if doHandbrake and wheel.hasHandbrake then
        numHandbrake = numHandbrake + 1
      elseif hasGroundContact then
        numTouching = numTouching + 1
      else
        numNotTouching = numNotTouching + 1
      end
    end
  end
  local motorTorque = 0
  if 0 < numTouching and math.abs(accelerationPedal) > 0.01 then
    local axisTorque = WheelsUtil.computeAxisTorque(self, accelerationPedal)
    if axisTorque ~= 0 then
      motorTorque = axisTorque / (numTouching + numNotTouching)
    else
      brakePedal = 0.5
    end
  else
    self.motor:computeMotorRpm(self.wheelRpm, accelerationPedal)
  end
  local doBrake = 0 < brakePedal and self.lastSpeed > 2.0E-4 or doHandbrake
  for k, implement in pairs(self.attachedImplements) do
    if doBrake then
      implement.object:onBrake()
    else
      implement.object:onReleaseBrake()
    end
  end
  for k, wheel in pairs(self.wheels) do
    WheelsUtil.updateWheelPhysics(self, wheel, doHandbrake, motorTorque, brakePedal, requiredDriveMode, dt)
  end
end
function WheelsUtil:computeAxisTorque(accelerationPedal)
  self.motor:computeMotorRpm(self.wheelRpm, accelerationPedal)
  local torque = accelerationPedal * self.motor:getTorque()
  return torque * self.motor:getGearRatio(accelerationPedal) * self.motor.differentialRatio * self.motor.transmissionEfficiency
end
function WheelsUtil:updateWheelPhysics(wheel, handbrake, motorTorque, brakePedal, requiredDriveMode, dt)
  local brakeForce = brakePedal * self.motor.brakeForce
  if handbrake and wheel.hasHandbrake then
    brakeForce = self.motor.brakeForce * 10
  end
  local actMotorTorque = 0
  if requiredDriveMode <= wheel.driveMode then
    actMotorTorque = motorTorque
  end
  if not wheel.hasGroundContact then
    actMotorTorque = actMotorTorque * 0.7
  end
  local steeringAngle = wheel.steeringAngle
  setWheelShapeProps(wheel.node, wheel.wheelShape, actMotorTorque, brakeForce, steeringAngle)
end
function WheelsUtil.updateWheelHasGroundContact(wheel)
  local x, y, z = getWheelShapeContactPoint(wheel.node, wheel.wheelShape)
  wheel.hasGroundContact = x ~= nil
end
function WheelsUtil:updateWheelSteeringAngle(wheel)
  local steeringAngle = 0
  if wheel.rotSpeed ~= 0 then
    steeringAngle = self.rotatedTime * wheel.rotSpeed
    if steeringAngle > wheel.rotMax then
      steeringAngle = wheel.rotMax
    elseif steeringAngle < wheel.rotMin then
      steeringAngle = wheel.rotMin
    end
  elseif wheel.steeringAxleScale ~= 0 then
    steeringAngle = Utils.clamp(self.steeringAxleAngle * wheel.steeringAxleScale, wheel.steeringAxleRotMin, wheel.steeringAxleRotMax)
  end
  wheel.steeringAngle = steeringAngle
end
function WheelsUtil:computeRpmFromWheels()
  local wheelRpm = 0
  local numWheels = 0
  for k, wheel in pairs(self.wheels) do
    local axleSpeed = math.rad(getWheelShapeAxleSpeed(wheel.node, wheel.wheelShape))
    wheel.axleSpeed = axleSpeed
    if wheel.hasGroundContact then
      wheelRpm = wheelRpm + axleSpeed / (math.pi * 2) * 60
      numWheels = numWheels + 1
    end
  end
  if 0 < numWheels then
    self.wheelRpm = math.abs(wheelRpm) / numWheels
  else
    self.wheelRpm = 0
  end
end
function WheelsUtil:updateWheelsGraphics(dt)
  WheelsUtil.computeRpmFromWheels(self)
  for k, wheel in pairs(self.wheels) do
    WheelsUtil.updateWheelHasGroundContact(wheel)
    WheelsUtil.updateWheelSteeringAngle(self, wheel)
    local steeringAngle = wheel.steeringAngle
    local x, y, z = getRotation(wheel.repr)
    local xDrive, yDrive, zDrive
    if wheel.repr == wheel.driveNode then
      xDrive, yDrive, zDrive = x, y, z
    else
      xDrive, yDrive, zDrive = getRotation(wheel.driveNode)
    end
    xDrive = xDrive + wheel.axleSpeed * dt / 1000
    local newX, newY, newZ = getWheelShapePosition(wheel.node, wheel.wheelShape)
    setTranslation(wheel.repr, newX, newY, newZ)
    if wheel.repr == wheel.driveNode then
      setRotation(wheel.repr, xDrive, steeringAngle, z)
    else
      setRotation(wheel.repr, x, steeringAngle, z)
      setRotation(wheel.driveNode, xDrive, yDrive, zDrive)
    end
  end
end

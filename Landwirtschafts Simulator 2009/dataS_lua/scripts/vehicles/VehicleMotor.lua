VehicleMotor = {}
VehicleMotor_mt = Class(VehicleMotor)
function VehicleMotor:new(minRpm, maxRpm, torqueCurve, brakeForce, forwardGearRatios, backwardGearRatio, differentialRatio, rpmFadeOutRange)
  local instance = {}
  setmetatable(instance, VehicleMotor_mt)
  instance.minRpm = minRpm
  instance.maxRpm = maxRpm
  instance.torqueCurve = torqueCurve
  instance.brakeForce = brakeForce
  instance.forwardGearRatios = forwardGearRatios
  instance.backwardGearRatio = backwardGearRatio
  instance.differentialRatio = differentialRatio
  instance.transmissionEfficiency = 1
  instance.lastMotorRpm = 0
  instance.rpmFadeOutRange = rpmFadeOutRange
  instance.speedLevel = 0
  instance.nonClampedMotorRpm = 0
  return instance
end
function VehicleMotor:getTorque()
  local torque = self.torqueCurve:get(self.lastMotorRpm)
  local maxRpm = self:getMaxRpm()
  if self.nonClampedMotorRpm > maxRpm - self.rpmFadeOutRange then
    torque = math.max(torque - (self.nonClampedMotorRpm - (maxRpm - self.rpmFadeOutRange)) * torque / self.rpmFadeOutRange, 0)
  end
  return torque
end
function VehicleMotor:computeMotorRpm(wheelRpm, acceleration)
  local temp = self:getGearRatio(acceleration) * self.differentialRatio
  self.nonClampedMotorRpm = wheelRpm * temp
  self.lastMotorRpm = math.max(self.nonClampedMotorRpm, self.minRpm)
end
function VehicleMotor:getGearRatio(acceleration)
  if 0 <= acceleration then
    if self.speedLevel ~= 0 then
      return self.forwardGearRatios[self.speedLevel]
    else
      return self.forwardGearRatios[3]
    end
  else
    return self.backwardGearRatio
  end
end
function VehicleMotor:getMaxRpm()
  if self.maxRpmOverride ~= nil then
    return self.maxRpmOverride
  elseif self.speedLevel ~= 0 then
    return self.maxRpm[self.speedLevel]
  else
    return self.maxRpm[3]
  end
end
function VehicleMotor:setSpeedLevel(level, force)
  if level ~= 0 and self.speedLevel == level and not force then
    self.speedLevel = 0
  else
    self.speedLevel = level
  end
end

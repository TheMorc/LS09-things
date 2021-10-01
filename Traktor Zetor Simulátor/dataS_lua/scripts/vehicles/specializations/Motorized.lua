Motorized = {}
function Motorized.prerequisitesPresent(specializations)
  return true
end
function Motorized:load(xmlFile)
  self.startMotor = SpecializationUtil.callSpecializationsFunction("startMotor")
  self.stopMotor = SpecializationUtil.callSpecializationsFunction("stopMotor")
  self.startRefuel = SpecializationUtil.callSpecializationsFunction("startRefuel")
  self.stopRefuel = SpecializationUtil.callSpecializationsFunction("stopRefuel")
  self.setFuelFillLevel = SpecializationUtil.callSpecializationsFunction("setFuelFillLevel")
  self.fuelCapacity = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.fuelCapacity"), 500)
  self.fuelUsage = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.fuelUsage"), 0.01)
  self.hasRefuelStationInRange = false
  self.doRefuel = false
  self:setFuelFillLevel(self.fuelCapacity)
  self.refuelSampleRunning = false
  self.refuelSample = createSample("refuelSample")
  loadSample(self.refuelSample, "data/maps/sounds/refuel.wav", false)
  local motorMinRpm = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.motor#minRpm"), 1000)
  local motorMaxRpmStr = getXMLString(xmlFile, "vehicle.motor#maxRpm")
  local motorMaxRpm1, motorMaxRpm2, motorMaxRpm3 = Utils.getVectorFromString(motorMaxRpmStr)
  motorMaxRpm1 = Utils.getNoNil(motorMaxRpm1, 800)
  motorMaxRpm2 = Utils.getNoNil(motorMaxRpm2, 1000)
  motorMaxRpm3 = Utils.getNoNil(motorMaxRpm3, 1800)
  local motorMaxRpm = {
    motorMaxRpm1,
    motorMaxRpm2,
    motorMaxRpm3
  }
  local motorTorque = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.motor#torque"), 15)
  local brakeForce = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.motor#brakeForce"), 10) * 2
  local forwardGearRatioStr = getXMLString(xmlFile, "vehicle.motor#forwardGearRatio")
  local forwardGearRatio1, forwardGearRatio2, forwardGearRatio3 = Utils.getVectorFromString(forwardGearRatioStr)
  forwardGearRatio1 = Utils.getNoNil(forwardGearRatio1, 2)
  forwardGearRatio2 = Utils.getNoNil(forwardGearRatio2, forwardGearRatio1)
  forwardGearRatio3 = Utils.getNoNil(forwardGearRatio3, forwardGearRatio2)
  local forwardGearRatios = {
    forwardGearRatio1,
    forwardGearRatio2,
    forwardGearRatio3
  }
  local backwardGearRatio = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.motor#backwardGearRatio"), 1.5)
  local differentialRatio = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.motor#differentialRatio"), 1)
  local rpmFadeOutRange = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.motor#rpmFadeOutRange"), 20)
  local torqueCurve = AnimCurve:new(linearInterpolator1)
  local torqueI = 0
  while true do
    local key = string.format("vehicle.motor.torque(%d)", torqueI)
    local rpm = getXMLFloat(xmlFile, key .. "#rpm")
    local torque = getXMLFloat(xmlFile, key .. "#torque")
    if torque == nil or rpm == nil then
      break
    end
    torqueCurve:addKeyframe({
      v = torque * 3,
      time = rpm
    })
    torqueI = torqueI + 1
  end
  self.motor = VehicleMotor:new(motorMinRpm, motorMaxRpm, torqueCurve, brakeForce, forwardGearRatios, backwardGearRatio, differentialRatio, rpmFadeOutRange)
  local motorStartSound = getXMLString(xmlFile, "vehicle.motorStartSound#file")
  if motorStartSound ~= nil and motorStartSound ~= "" then
    motorStartSound = Utils.getFilename(motorStartSound, self.baseDirectory)
    self.motorStartSound = createSample("motorStartSound")
    loadSample(self.motorStartSound, motorStartSound, false)
    self.motorStartSoundPitchOffset = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.motorStartSound#pitchOffset"), 0)
    self.motorStartSoundVolume = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.motorStartSound#volume"), 1)
  end
  local motorStopSound = getXMLString(xmlFile, "vehicle.motorStopSound#file")
  if motorStopSound ~= nil and motorStopSound ~= "" then
    motorStopSound = Utils.getFilename(motorStopSound, self.baseDirectory)
    self.motorStopSound = createSample("motorStopSound")
    loadSample(self.motorStopSound, motorStopSound, false)
    self.motorStopSoundPitchOffset = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.motorStopSound#pitchOffset"), 0)
    self.motorStopSoundVolume = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.motorStopSound#volume"), 1)
  end
  local motorSound = getXMLString(xmlFile, "vehicle.motorSound#file")
  if motorSound ~= nil and motorSound ~= "" then
    motorSound = Utils.getFilename(motorSound, self.baseDirectory)
    self.motorSound = createSample("motorSound")
    loadSample(self.motorSound, motorSound, false)
    self.motorSoundPitchOffset = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.motorSound#pitchOffset"), 0)
    self.motorSoundPitchScale = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.motorSound#pitchScale"), 0.05)
    self.motorSoundPitchMax = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.motorSound#pitchMax"), 2)
    self.motorSoundVolume = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.motorSound#volume"), 1)
  end
  local motorSoundRun = getXMLString(xmlFile, "vehicle.motorSoundRun#file")
  if motorSoundRun ~= nil and motorSoundRun ~= "" then
    motorSoundRun = Utils.getFilename(motorSoundRun, self.baseDirectory)
    self.motorSoundRun = createSample("motorSoundRun")
    loadSample(self.motorSoundRun, motorSoundRun, false)
    self.motorSoundRunPitchOffset = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.motorSoundRun#pitchOffset"), 0)
    self.motorSoundRunPitchScale = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.motorSoundRun#pitchScale"), 0.05)
    self.motorSoundRunPitchMax = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.motorSoundRun#pitchMax"), 2)
    self.motorSoundRunVolume = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.motorSoundRun#volume"), 1)
  end
  self.isFadingInMotorSndRun = false
  self.fadeTime = 4000
  self.currentFadeTime = 0
  self.motorSoundActualVolume = 0
  local reverseDriveSound = getXMLString(xmlFile, "vehicle.reverseDriveSound#file")
  if reverseDriveSound ~= nil and reverseDriveSound ~= "" then
    reverseDriveSound = Utils.getFilename(reverseDriveSound, self.baseDirectory)
    self.reverseDriveSound = createSample("reverseDriveSound")
    self.reverseDriveSoundEnabled = false
    loadSample(self.reverseDriveSound, reverseDriveSound, false)
    self.reverseDriveSoundVolume = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.reverseDriveSound#volume"), 1)
  end
  local compressedAirSound = getXMLString(xmlFile, "vehicle.compressedAirSound#file")
  if compressedAirSound ~= nil and compressedAirSound ~= "" then
    compressedAirSound = Utils.getFilename(compressedAirSound, self.baseDirectory)
    self.compressedAirSound = createSample("compressedAirSound")
    self.compressedAirSoundEnabled = false
    loadSample(self.compressedAirSound, compressedAirSound, false)
    self.compressedAirSoundPitchOffset = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.compressedAirSound#pitchOffset"), 1)
    self.compressedAirSoundVolume = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.compressedAirSound#volume"), 1)
  end
  local compressionSound = getXMLString(xmlFile, "vehicle.compressionSound#file")
  if compressionSound ~= nil and compressionSound ~= "" then
    compressionSound = Utils.getFilename(compressionSound, self.baseDirectory)
    self.compressionSound = createSample("compressionSound")
    loadSample(self.compressionSound, compressionSound, false)
    self.compressionSoundPitchOffset = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.compressionSound#pitchOffset"), 1)
    self.compressionSoundVolume = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.compressionSound#volume"), 1)
    self.compressionSoundTime = 0
    self.compressionSoundEnabled = false
  end
  self.isMotorStarted = false
  self.exhaustParticleSystems = {}
  local exhaustParticleSystemCount = Utils.getNoNil(getXMLInt(xmlFile, "vehicle.exhaustParticleSystems#count"), 0)
  for i = 1, exhaustParticleSystemCount do
    local namei = string.format("vehicle.exhaustParticleSystems.exhaustParticleSystem%d", i)
    Utils.loadParticleSystem(xmlFile, self.exhaustParticleSystems, namei, self.components, false, nil, self.baseDirectory)
  end
  self.lastRoundPerMinute = 0
end
function Motorized:delete()
  Utils.deleteParticleSystem(self.exhaustParticleSystems)
  if self.refuelSample ~= nil then
    delete(self.refuelSample)
  end
  if self.motorSound ~= nil then
    delete(self.motorSound)
  end
  if self.motorSoundRun ~= nil then
    delete(self.motorSoundRun)
  end
  if self.motorStartSound ~= nil then
    delete(self.motorStartSound)
  end
  if self.motorStopSound ~= nil then
    delete(self.motorStopSound)
  end
  if self.reverseDriveSound ~= nil then
    delete(self.reverseDriveSound)
  end
  if self.compressedAirSound ~= nil then
    delete(self.compressedAirSound)
  end
  if self.compressionSound ~= nil then
    delete(self.compressionSound)
  end
end
function Motorized:mouseEvent(posX, posY, isDown, isUp, button)
end
function Motorized:keyEvent(unicode, sym, modifier, isDown)
end
function Motorized:update(dt)
  self.doRefuel = self.doRefuel and self.hasRefuelStationInRange
  if self.doRefuel then
    if not self.refuelSampleRunning and self:getIsActiveForSound() then
      playSample(self.refuelSample, 0, 1, 0)
      self.refuelSampleRunning = true
    end
    local refuelSpeed = 0.01
    local currentFillLevel = self.fuelFillLevel
    self:setFuelFillLevel(self.fuelFillLevel + refuelSpeed * dt)
    local delta = self.fuelFillLevel - currentFillLevel
    if delta <= 0.05 then
      self.doRefuel = false
    end
    delta = delta * g_fuelPricePerLiter
    g_currentMission.missionStats.expensesTotal = g_currentMission.missionStats.expensesTotal + delta
    g_currentMission.missionStats.expensesSession = g_currentMission.missionStats.expensesSession + delta
    g_currentMission.missionStats.money = g_currentMission.missionStats.money - delta
  elseif self.refuelSampleRunning then
    stopSample(self.refuelSample)
    self.refuelSampleRunning = false
  end
  if self.isMotorStarted then
    if self:getIsActiveForSound() then
      if self.playMotorSound and self.motorSound ~= nil and self.playMotorSoundTime <= self.time then
        playSample(self.motorSound, 0, self.motorSoundVolume, 0)
        self.playMotorSound = false
        if self.motorSoundRun ~= nil then
          playSample(self.motorSoundRun, 0, 0, 0)
        end
      end
      if self.compressionSound ~= nil and self.compressionSoundTime < self.time then
        playSample(self.compressionSound, 1, self.compressionSoundVolume, 0)
        setSamplePitch(self.compressionSound, self.compressionSoundPitchOffset)
        self.compressionSoundTime = self.time + 180000
        self.compressionSoundEnabled = true
      end
    end
    if self.reverseDriveSound ~= nil then
      if self.movingDirection == -1 then
        if not self.reverseDriveSoundEnabled and self:getIsActiveForSound() then
          playSample(self.reverseDriveSound, 0, self.reverseDriveSoundVolume, 0)
          self.reverseDriveSoundEnabled = true
        end
      elseif self.reverseDriveSoundEnabled then
        stopSample(self.reverseDriveSound)
        self.reverseDriveSoundEnabled = false
      end
    end
    if 0 < table.getn(self.wheels) then
      local alpha = 0.9
      local roundPerMinute = self.lastRoundPerMinute * alpha + (1 - alpha) * (self.motor.lastMotorRpm - self.motor.minRpm)
      self.lastRoundPerMinute = roundPerMinute
      local roundPerSecond = roundPerMinute / 60
      if self.motorSound ~= nil then
        setSamplePitch(self.motorSound, math.min(self.motorSoundPitchOffset + self.motorSoundPitchScale * math.abs(roundPerSecond), self.motorSoundPitchMax))
        if self.motorSoundRun ~= nil then
          setSamplePitch(self.motorSoundRun, math.min(self.motorSoundRunPitchOffset + self.motorSoundRunPitchScale * math.abs(roundPerSecond), self.motorSoundRunPitchMax))
        end
      end
      self.input = InputBinding.getAnalogInputAxis(InputBinding.AXIS_FORWARD)
      if InputBinding.isAxisZero(self.input) then
        self.input = InputBinding.getDigitalInputAxis(InputBinding.AXIS_FORWARD)
      end
      if self.compressedAirSound ~= nil then
        local maxRpm = self.motor:getMaxRpm()
        if maxRpm / 2 < self.motor.lastMotorRpm then
          self.enoughRpm = true
        else
          self.enoughRpm = false
        end
        if self.input == -1 and self.compressedAirSoundEnabled and self.enoughRpm then
          self.compressedAirSoundEnabled = false
        end
        if self.input == 1 and not self.compressedAirSoundEnabled and self.enoughRpm then
          if self:getIsActiveForSound() then
            playSample(self.compressedAirSound, 1, self.compressedAirSoundVolume, 0)
            setSamplePitch(self.compressedAirSound, self.compressedAirSoundPitchOffset)
          end
          self.compressedAirSoundEnabled = true
        end
      end
      if self.motorSoundRun ~= nil then
        local maxRpm = self.motor.maxRpm[3]
        if self.input ~= 0 or self.motor.speedLevel ~= 0 then
          local rpmVolume = Utils.clamp(math.abs(roundPerMinute) / (maxRpm - self.motor.minRpm), 0, 1)
          setSampleVolume(self.motorSoundRun, rpmVolume)
        else
          local rpmVolume = Utils.clamp(math.abs(roundPerMinute) / ((maxRpm - self.motor.minRpm) * 2), 0, 1)
          setSampleVolume(self.motorSoundRun, rpmVolume)
        end
      end
    end
  end
end
function Motorized:draw()
end
function Motorized:startMotor()
  if not self.isMotorStarted then
    self.isMotorStarted = true
    self.reverseDriveSoundEnabled = false
    local motorSoundOffset = 0
    if self.motorStartSound ~= nil and self:getIsActiveForSound() then
      playSample(self.motorStartSound, 1, self.motorStartSoundVolume, 0)
      setSamplePitch(self.motorStartSound, self.motorStartSoundPitchOffset)
      motorSoundOffset = getSampleDuration(self.motorStartSound)
    end
    self.playMotorSound = true
    self.playMotorSoundTime = self.time + motorSoundOffset
    self.playCompressionSoundTime = self.time + motorSoundOffset
    self.compressionSoundTime = self.time + 180000
    self.lastRoundPerMinute = 0
    Utils.setEmittingState(self.exhaustParticleSystems, true)
  else
    self.playMotorSound = true
  end
end
function Motorized:stopMotor()
  self.isMotorStarted = false
  Motorized.stopSounds(self)
  if self:getIsActiveForSound() and self.motorStopSound ~= nil then
    setSamplePitch(self.motorStopSound, self.motorStopSoundPitchOffset)
    playSample(self.motorStopSound, 1, self.motorStopSoundVolume, 0)
  end
  self.motor:setSpeedLevel(0, false)
  Utils.setEmittingState(self.exhaustParticleSystems, false)
end
function Motorized:stopSounds()
  self.playMotorSound = false
  if self.motorSound ~= nil then
    stopSample(self.motorSound)
  end
  self.playMotorRunSound = false
  if self.motorSoundRun ~= nil then
    stopSample(self.motorSoundRun)
  end
  if self.motorStartSound ~= nil then
    stopSample(self.motorStartSound)
  end
  if self.compressionSoundEnabled then
    stopSample(self.compressionSound)
    self.compressionSoundEnabled = false
  end
  if self.reverseDriveSoundEnabled then
    stopSample(self.reverseDriveSound)
    self.reverseDriveSoundEnabled = false
  end
end
function Motorized:startRefuel()
  if self.hasRefuelStationInRange then
    self.doRefuel = true
  end
end
function Motorized:stopRefuel()
  self.doRefuel = false
  if self.refuelSampleRunning then
    stopSample(self.refuelSample)
    self.refuelSampleRunning = false
  end
end
function Motorized:setFuelFillLevel(newFillLevel)
  self.fuelFillLevel = math.max(math.min(newFillLevel, self.fuelCapacity), 0)
end

Frontloader = {}
function Frontloader.prerequisitesPresent(specializations)
  Vehicle.registerJointType("frontloader")
  return true
end
function Frontloader:load(xmlFile)
  local jointTransform = Utils.indexToObject(self.components, getXMLString(xmlFile, "vehicle.frontloader#jointIndex"))
  if jointTransform ~= nil then
    local entry = {}
    entry.jointTransform = jointTransform
    local jointTypeStr = getXMLString(xmlFile, "vehicle.frontloader#jointType")
    local jointType
    if jointTypeStr ~= nil then
      jointType = Vehicle.jointTypeNameToInt[jointTypeStr]
      if jointType == nil then
        print("Warning: invalid jointType " .. jointTypeStr)
      end
    end
    if jointType == nil then
      jointType = Vehicle.JOINTTYPE_FRONTLOADER
    end
    entry.jointType = jointType
    entry.allowsJointLimitMovement = Utils.getNoNil(getXMLBool(xmlFile, "vehicle.frontloader#allowsJointLimitMovement"), false)
    entry.allowsLowering = Utils.getNoNil(getXMLBool(xmlFile, "vehicle.frontloader#allowsLowering"), false)
    entry.maxRotLimit = {
      0,
      0,
      0
    }
    entry.maxTransLimit = {
      0,
      0,
      0
    }
    entry.moveDirection1 = 0
    entry.moveDirection2 = 0
    local rootNode1 = Utils.indexToObject(self.components, getXMLString(xmlFile, "vehicle.frontloader#rootNode1"))
    entry.animCharSet1 = 0
    if rootNode1 ~= nil then
      entry.animCharSet1 = getAnimCharacterSet(rootNode1)
      if entry.animCharSet1 ~= 0 then
        local clip = getAnimClipIndex(entry.animCharSet1, getXMLString(xmlFile, "vehicle.frontloader#animationClip1"))
        assignAnimTrackClip(entry.animCharSet1, 0, clip)
        setAnimTrackLoopState(entry.animCharSet1, 0, false)
        entry.speedScale1 = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.frontloader#speedScale1"), 1)
        entry.animDuration1 = getAnimClipDuration(entry.animCharSet1, clip)
      end
    end
    local rootNode2 = Utils.indexToObject(self.components, getXMLString(xmlFile, "vehicle.frontloader#rootNode2"))
    entry.animCharSet2 = 0
    if rootNode2 ~= nil then
      entry.animCharSet2 = getAnimCharacterSet(rootNode2)
      if entry.animCharSet2 ~= 0 then
        local clip = getAnimClipIndex(entry.animCharSet2, getXMLString(xmlFile, "vehicle.frontloader#animationClip2"))
        assignAnimTrackClip(entry.animCharSet2, 0, clip)
        setAnimTrackLoopState(entry.animCharSet2, 0, false)
        entry.speedScale2 = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.frontloader#speedScale2"), 1)
        entry.animDuration2 = getAnimClipDuration(entry.animCharSet2, clip)
        entry.compensationSpeedScale = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.frontloader#compensationSpeedScale"), entry.speedScale2)
      end
    end
    entry.rootNode = Utils.getNoNil(Utils.indexToObject(self.components, getXMLString(xmlFile, "vehicle.frontloader#rootNode")), self.components[1].node)
    entry.jointIndex = 0
    self.frontloaderJointDesc = entry
    table.insert(self.attacherJoints, entry)
  end
  self.frontloaderJointInvalid = false
  self.hydraulicSounds = {
    {},
    {}
  }
  self.hydraulicSoundsEnabled = {
    {false, false},
    {false, false}
  }
  local hydraulicUpSound = getXMLString(xmlFile, "vehicle.hydraulicUpSound#file")
  if hydraulicUpSound ~= nil and hydraulicUp ~= "" then
    hydraulicUpSound = Utils.getFilename(hydraulicUpSound, self.baseDirectory)
    self.hydraulicSounds[1][1] = createSample("hydraulicUpSound")
    loadSample(self.hydraulicSounds[1][1], hydraulicUpSound, false)
    local pitch = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.hydraulicUpSound#pitchOffset"), 0)
    setSamplePitch(self.hydraulicSounds[1][1], pitch)
  end
  local hydraulicDownSound = getXMLString(xmlFile, "vehicle.hydraulicDownSound#file")
  if hydraulicDownSound ~= nil and hydraulicDownSound ~= "" then
    hydraulicDownSound = Utils.getFilename(hydraulicDownSound, self.baseDirectory)
    self.hydraulicSounds[2][1] = createSample("hydraulicDownSound")
    loadSample(self.hydraulicSounds[2][1], hydraulicDownSound, false)
    local pitch = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.hydraulicDownSound#pitchOffset"), 0)
    setSamplePitch(self.hydraulicSounds[2][1], pitch)
  end
  local hydraulicTiltUpSound = getXMLString(xmlFile, "vehicle.hydraulicTiltUpSound#file")
  if hydraulicTiltUpSound ~= nil and hydraulicTiltUpSound ~= "" then
    hydraulicTiltUpSound = Utils.getFilename(hydraulicTiltUpSound, self.baseDirectory)
    self.hydraulicSounds[1][2] = createSample("hydraulicTiltUpSound")
    loadSample(self.hydraulicSounds[1][2], hydraulicTiltUpSound, false)
    local pitch = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.hydraulicTiltUpSound#pitchOffset"), 0)
    setSamplePitch(self.hydraulicSounds[1][2], pitch)
  end
  local hydraulicTiltDownSound = getXMLString(xmlFile, "vehicle.hydraulicTiltDownSound#file")
  if hydraulicTiltDownSound ~= nil and hydraulicTiltDownSound ~= "" then
    hydraulicTiltDownSound = Utils.getFilename(hydraulicTiltDownSound, self.baseDirectory)
    self.hydraulicSounds[2][2] = createSample("hydraulicTiltDownSound")
    loadSample(self.hydraulicSounds[2][2], hydraulicTiltDownSound, false)
    local pitch = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.hydraulicTiltDownSound#pitchOffset"), 0)
    setSamplePitch(self.hydraulicSounds[2][2], pitch)
  end
end
function Frontloader:delete()
  for i = 1, table.getn(self.hydraulicSounds) do
    for j = 1, table.getn(self.hydraulicSounds[i]) do
      delete(self.hydraulicSounds[i][j])
    end
  end
end
function Frontloader:mouseEvent(posX, posY, isDown, isUp, button)
end
function Frontloader:keyEvent(unicode, sym, modifier, isDown)
end
function Frontloader:update(dt)
  if self.frontloaderJointDesc ~= nil then
    self.frontloaderJointDesc.moveDirection1 = 0
    self.frontloaderJointDesc.moveDirection2 = 0
    self.frontloaderJointInvalid = false
  end
  if self:getIsActiveForInput() and self.frontloaderJointDesc ~= nil then
    if InputBinding.isPressed(InputBinding.FRONTLOADER_ARM_POS) then
      self.frontloaderJointDesc.moveDirection1 = self.frontloaderJointDesc.moveDirection1 + 1
    end
    if InputBinding.isPressed(InputBinding.FRONTLOADER_ARM_NEG) then
      self.frontloaderJointDesc.moveDirection1 = self.frontloaderJointDesc.moveDirection1 - 1
    end
    if InputBinding.isPressed(InputBinding.FRONTLOADER_TILT_POS) then
      self.frontloaderJointDesc.moveDirection2 = self.frontloaderJointDesc.moveDirection2 + 1
    end
    if InputBinding.isPressed(InputBinding.FRONTLOADER_TILT_NEG) then
      self.frontloaderJointDesc.moveDirection2 = self.frontloaderJointDesc.moveDirection2 - 1
    end
  end
  if self:getIsActive() and self.frontloaderJointDesc ~= nil then
    local charSets = {
      self.frontloaderJointDesc.animCharSet1,
      self.frontloaderJointDesc.animCharSet2
    }
    local moveDirections = {
      self.frontloaderJointDesc.moveDirection1,
      self.frontloaderJointDesc.moveDirection2
    }
    local speedScales = {
      self.frontloaderJointDesc.speedScale1,
      self.frontloaderJointDesc.speedScale2
    }
    local durations = {
      self.frontloaderJointDesc.animDuration1,
      self.frontloaderJointDesc.animDuration2
    }
    if moveDirections[2] == 0 then
      moveDirections[2] = -moveDirections[1]
      speedScales[2] = self.frontloaderJointDesc.compensationSpeedScale
    end
    for i = 1, 2 do
      local charSet = charSets[i]
      if charSet ~= 0 then
        local speedScale
        local playUp = false
        local playDown = false
        if 0.1 < moveDirections[i] then
          speedScale = speedScales[i]
          playUp = true
        elseif moveDirections[i] < -0.1 then
          speedScale = -speedScales[i]
          playDown = true
        end
        if speedScale ~= nil then
          local animTrackTime = getAnimTrackTime(charSet, 0)
          if 0 < speedScale then
            if animTrackTime < 0 then
              setAnimTrackTime(charSet, 0, 0)
            elseif animTrackTime > durations[i] then
              playUp = false
              playDown = false
            end
          elseif animTrackTime > durations[i] then
            setAnimTrackTime(charSet, 0, durations[i])
          elseif animTrackTime < 0 then
            playUp = false
            playDown = false
          end
          setAnimTrackSpeedScale(charSet, 0, speedScale)
          enableAnimTrack(charSet, 0)
          self.frontloaderJointInvalid = true
        else
          disableAnimTrack(charSet, 0)
        end
        Frontloader.updateHydraulicSound(self, 1, i, playUp)
        Frontloader.updateHydraulicSound(self, 2, i, playDown)
      end
    end
  end
end
function Frontloader:draw()
end
function Frontloader:onDetach()
  if self.deactivateOnDetach then
    Frontloader.onDeactivate(self)
  end
end
function Frontloader:onLeave()
  if self.deactivateOnLeave then
    Frontloader.onDeactivate(self)
  end
end
function Frontloader:onDeactivate()
  for i = 1, 2 do
    Frontloader.updateHydraulicSound(self, 1, i, false)
    Frontloader.updateHydraulicSound(self, 2, i, false)
  end
  if self.frontloaderJointDesc ~= nil then
    if self.frontloaderJointDesc.animCharSet1 ~= 0 then
      disableAnimTrack(self.frontloaderJointDesc.animCharSet1, 0)
    end
    if self.frontloaderJointDesc.animCharSet2 ~= 0 then
      disableAnimTrack(self.frontloaderJointDesc.animCharSet2, 0)
    end
  end
end
function Frontloader:validateAttacherJoint(implement, jointDesc, dt)
  if jointDesc == self.frontloaderJointDesc and self.frontloaderJointInvalid then
    self.frontloaderJointInvalid = false
    return true
  end
  return false
end
function Frontloader:updateHydraulicSound(dirIndex, posIndex, play)
  local sound = self.hydraulicSounds[dirIndex][posIndex]
  if sound ~= nil then
    if play then
      if not self.hydraulicSoundsEnabled[dirIndex][posIndex] and self:getIsActiveForSound() then
        playSample(sound, 0, 1, 0)
        self.hydraulicSoundsEnabled[dirIndex][posIndex] = true
      end
    elseif self.hydraulicSoundsEnabled[dirIndex][posIndex] then
      stopSample(sound)
      self.hydraulicSoundsEnabled[dirIndex][posIndex] = false
    end
  end
end

Baler = {}
function Baler.prerequisitesPresent(specializations)
  return SpecializationUtil.hasSpecialization(Trailer, specializations)
end
function Baler:load(xmlFile)
  self.getTimeFromLevel = Baler.getTimeFromLevel
  self.moveBales = SpecializationUtil.callSpecializationsFunction("moveBales")
  self.moveBale = SpecializationUtil.callSpecializationsFunction("moveBale")
  self.allowFillType = Baler.allowFillType
  self.fillScale = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.fillScale#value"), 1)
  local firstBaleMarker = getXMLFloat(xmlFile, "vehicle.baleAnimation#firstBaleMarker")
  if firstBaleMarker ~= nil then
    local baleAnimCurve = AnimCurve:new(linearInterpolatorN)
    local keyI = 0
    while true do
      local key = string.format("vehicle.baleAnimation.key(%d)", keyI)
      local t = getXMLFloat(xmlFile, key .. "#time")
      local x, y, z = Utils.getVectorFromString(getXMLString(xmlFile, key .. "#pos"))
      if x == nil or y == nil or z == nil then
        break
      end
      local rx, ry, rz = Utils.getVectorFromString(getXMLString(xmlFile, key .. "#rot"))
      rx = math.rad(Utils.getNoNil(rx, 0))
      ry = math.rad(Utils.getNoNil(ry, 0))
      rz = math.rad(Utils.getNoNil(rz, 0))
      baleAnimCurve:addKeyframe({
        v = {
          x,
          y,
          z,
          rx,
          ry,
          rz
        },
        time = t
      })
      keyI = keyI + 1
    end
    if 0 < keyI then
      self.baleAnimCurve = baleAnimCurve
      self.baleAnimRoot = Utils.getNoNil(Utils.indexToObject(self.components, getXMLString(xmlFile, "vehicle.baleAnimation#node")), self.components[1].node)
      self.firstBaleMarker = firstBaleMarker
      self.baleTypes = {}
      local i = 0
      while true do
        local key = string.format("vehicle.baleTypes.baleType(%d)", i)
        local t = getXMLString(xmlFile, key .. "#fruitType")
        local filename = getXMLString(xmlFile, key .. "#filename")
        if t == nil or filename == nil then
          break
        end
        local entry = {}
        entry.filename = filename
        local desc = FruitUtil.fruitTypes[t]
        if desc ~= nil then
          self.baleTypes[desc.index] = entry
          if self.defaultBaleType == nil then
            self.defaultBaleType = entry
          end
        end
        i = i + 1
      end
      if self.defaultBaleType == nil then
        self.baleTypes = nil
      end
    end
  end
  local balerSound = getXMLString(xmlFile, "vehicle.balerSound#file")
  if balerSound ~= nil and balerSound ~= "" then
    balerSound = Utils.getFilename(balerSound, self.baseDirectory)
    self.balerSound = createSample("balerSound")
    self.balerSoundEnabled = false
    loadSample(self.balerSound, balerSound, false)
    self.balerSoundPitchOffset = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.balerSound#pitchOffset"), 1)
    self.balerSoundVolume = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.balerSound#volume"), 1)
  end
  self.baleMoveLastTime = 0
  self.bales = {}
  self.wasToFast = false
  self.isTurnedOn = false
end
function Baler:delete()
  if self.balerSound ~= nil then
    delete(self.balerSound)
  end
end
function Baler:mouseEvent(posX, posY, isDown, isUp, button)
end
function Baler:keyEvent(unicode, sym, modifier, isDown)
end
function Baler:update(dt)
  if self:getIsActiveForInput() and InputBinding.hasEvent(InputBinding.IMPLEMENT_EXTRA) then
    self.isTurnedOn = not self.isTurnedOn
  end
  self.wasToFast = false
  if self:getIsActive() then
    if self.isTurnedOn then
      local toFast = self:doCheckSpeedLimit() and self.lastSpeed * 3600 > 29
      if not toFast then
        local totalArea = 0
        local usedFruitType = FruitUtil.FRUITTYPE_UNKNOWN
        for k, cuttingArea in pairs(self.cuttingAreas) do
          local x, y, z = getWorldTranslation(cuttingArea.start)
          local x1, y1, z1 = getWorldTranslation(cuttingArea.width)
          local x2, y2, z2 = getWorldTranslation(cuttingArea.height)
          for fruitType, v in pairs(self.fillTypes) do
            if fruitType ~= FruitUtil.FRUITTYPE_UNKNOWN then
              local area = Utils.updateFruitWindrowArea(fruitType, x, z, x1, z1, x2, z2, 0) * g_currentMission.windrowCutLongRatio
              area = area + Utils.updateFruitCutLongArea(fruitType, x, z, x1, z1, x2, z2, 0)
              if 0 < area then
                totalArea = totalArea + area
                usedFruitType = fruitType
              end
            end
          end
        end
        if 0 < totalArea then
          local literPerPixel = 0.8333333333333334
          local deltaLevel = totalArea * literPerPixel * self.fillScale
          local deltaTime = self:getTimeFromLevel(deltaLevel)
          self:moveBales(deltaTime)
          local oldFillLevel = self.fillLevel
          self:setFillLevel(self.fillLevel + deltaLevel, usedFruitType)
          if self.fillLevel == self.capacity then
            local restDeltaFillLevel = deltaLevel - (self.fillLevel - oldFillLevel)
            self:setFillLevel(restDeltaFillLevel, usedFruitType)
            if self.baleAnimCurve ~= nil and self.baleTypes ~= nil then
              local baleType = self.baleTypes[usedFruitType]
              if baleType == nil then
                baleType = self.defaultBaleType
              end
              local baleRoot = Utils.loadSharedI3DFile(baleType.filename, self.baseDirectory)
              local baleId = getChildAt(baleRoot, 0)
              setRigidBodyType(baleId, "None")
              link(self.baleAnimRoot, baleId)
              delete(baleRoot)
              local bale = {}
              bale.id = baleId
              bale.time = 0
              bale.filename = Utils.getFilename(baleType.filename, self.baseDirectory)
              table.insert(self.bales, bale)
              self:moveBale(table.getn(self.bales), self:getTimeFromLevel(restDeltaFillLevel))
            end
          end
        end
      end
      if not self.balerSoundEnabled and self:getIsActiveForSound() then
        setSamplePitch(self.balerSound, self.balerSoundPitchOffset)
        playSample(self.balerSound, 0, self.balerSoundVolume, 0)
        self.balerSoundEnabled = true
      end
      self.wasToFast = toFast
    end
    if not self.isTurnedOn and self.balerSoundEnabled then
      stopSample(self.balerSound)
      self.balerSoundEnabled = false
    end
  end
end
function Baler:draw()
  if self.wasToFast then
    g_currentMission:addWarning(g_i18n:getText("Dont_drive_to_fast") .. "\n" .. string.format(g_i18n:getText("Cruise_control_levelN"), "2", InputBinding.getButtonKeyName(InputBinding.SPEED_LEVEL2)), 0.092, 0.048)
  end
  if self.isTurnedOn then
    g_currentMission:addHelpButtonText(string.format(g_i18n:getText("turn_off_OBJECT"), self.typeDesc), InputBinding.IMPLEMENT_EXTRA)
  else
    g_currentMission:addHelpButtonText(string.format(g_i18n:getText("turn_on_OBJECT"), self.typeDesc), InputBinding.IMPLEMENT_EXTRA)
  end
end
function Baler:onDetach()
  if self.deactivateOnDetach then
    Baler.onDeactivate(self)
  end
end
function Baler:onLeave()
  if self.deactivateOnLeave then
    Baler.onDeactivate(self)
  else
    Baler.onDeactivateSounds(self)
  end
end
function Baler:onDeactivate()
  self.wasToFast = false
  self.isTurnedOn = false
  Baler.onDeactivateSounds(self)
end
function Baler:onDeactivateSounds()
  if self.balerSoundEnabled then
    stopSample(self.balerSound)
    self.balerSoundEnabled = false
  end
end
function Baler:getTimeFromLevel(level)
  if self.firstBaleMarker ~= nil then
    return level / self.capacity * self.firstBaleMarker
  end
  return 0
end
function Baler:moveBales(dt)
  for i = table.getn(self.bales), 1, -1 do
    self:moveBale(i, dt)
  end
  self.baleMoveLastTime = self.time
end
function Baler:moveBale(i, dt)
  local bale = self.bales[i]
  bale.time = bale.time + dt
  local v = self.baleAnimCurve:get(bale.time)
  setTranslation(bale.id, v[1], v[2], v[3])
  setRotation(bale.id, v[4], v[5], v[6])
  if bale.time >= 1 then
    local deltaRealTime = (self.time - self.baleMoveLastTime) / 1000
    local lx, ly, lz = bale.lastX, bale.lastY, bale.lastZ
    local x, y, z = getWorldTranslation(bale.id)
    local rx, ry, rz = getWorldRotation(bale.id)
    link(getRootNode(), bale.id)
    g_currentMission:addItemToSave(bale.filename, bale.id, 0)
    setTranslation(bale.id, x, y, z)
    setRotation(bale.id, rx, ry, rz)
    setRigidBodyType(bale.id, "Dynamic")
    setLinearVelocity(bale.id, (x - lx) / deltaRealTime, (y - ly) / deltaRealTime, (z - lz) / deltaRealTime)
    table.remove(self.bales, i)
    if g_currentMission.baleCount ~= nil then
      g_currentMission.baleCount = g_currentMission.baleCount + 1
    end
  else
    bale.lastX, bale.lastY, bale.lastZ = getWorldTranslation(bale.id)
  end
end
function Baler:allowFillType(fillType)
  return self.fillTypes[fillType] == true
end

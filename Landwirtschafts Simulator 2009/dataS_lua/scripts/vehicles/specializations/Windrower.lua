Windrower = {}
function Windrower.prerequisitesPresent(specializations)
  return true
end
function Windrower:load(xmlFile)
  self.groundReferenceThreshold = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.groundReferenceNode#threshold"), 0.2)
  self.groundReferenceNode = Utils.indexToObject(self.components, getXMLString(xmlFile, "vehicle.groundReferenceNode#index"))
  if self.groundReferenceNode == nil then
    self.groundReferenceNode = self.components[1].node
  end
  self.animation = {}
  self.animation.animCharSet = 0
  self.animationEnabled = false
  local rootNode = Utils.indexToObject(self.components, getXMLString(xmlFile, "vehicle.animation#rootNode"))
  if rootNode ~= nil then
    self.animation.animCharSet = getAnimCharacterSet(rootNode)
    if self.animation.animCharSet ~= 0 then
      self.animation.clip = getAnimClipIndex(self.animation.animCharSet, getXMLString(xmlFile, "vehicle.animation#animationClip"))
      if 0 <= self.animation.clip then
        assignAnimTrackClip(self.animation.animCharSet, 0, self.animation.clip)
        self.animation.speedScale = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.animation#speedScale"), 1)
        setAnimTrackSpeedScale(self.animation.animCharSet, self.animation.clip, self.animation.speedScale)
        setAnimTrackLoopState(self.animation.animCharSet, 0, true)
      end
    end
  end
  local numWindrowerDropAreas = Utils.getNoNil(getXMLInt(xmlFile, "vehicle.windrowerDropAreas#count"), 0)
  if numWindrowerDropAreas ~= 1 or numWindrowerDropAreas ~= table.getn(self.cuttingAreas) then
    print("Warning: number of cutting areas and drop areas should be equal")
  end
  self.windrowerDropAreas = {}
  for i = 1, numWindrowerDropAreas do
    self.windrowerDropAreas[i] = {}
    local areanamei = string.format("vehicle.windrowerDropAreas.windrowerDropArea%d", i)
    self.windrowerDropAreas[i].start = Utils.indexToObject(self.components, getXMLString(xmlFile, areanamei .. "#startIndex"))
    self.windrowerDropAreas[i].width = Utils.indexToObject(self.components, getXMLString(xmlFile, areanamei .. "#widthIndex"))
    self.windrowerDropAreas[i].height = Utils.indexToObject(self.components, getXMLString(xmlFile, areanamei .. "#heightIndex"))
  end
  local numCuttingAreas = Utils.getNoNil(getXMLInt(xmlFile, "vehicle.cuttingAreas#count"), 0)
  for i = 1, numCuttingAreas do
    local areanamei = string.format("vehicle.cuttingAreas.cuttingArea%d", i)
    self.cuttingAreas[i].foldMinLimit = Utils.getNoNil(getXMLFloat(xmlFile, areanamei .. "#foldMinLimit"), 0)
    self.cuttingAreas[i].foldMaxLimit = Utils.getNoNil(getXMLFloat(xmlFile, areanamei .. "#foldMaxLimit"), 1)
  end
  local windrowerSound = getXMLString(xmlFile, "vehicle.windrowerSound#file")
  if windrowerSound ~= nil and windrowerSound ~= "" then
    windrowerSound = Utils.getFilename(windrowerSound, self.baseDirectory)
    self.windrowerSound = createSample("windrowerSound")
    self.windrowerSoundEnabled = false
    loadSample(self.windrowerSound, windrowerSound, false)
    self.windrowerSoundPitchOffset = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.windrowerSound#pitchOffset"), 1)
    self.windrowerSoundVolume = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.windrowerSound#volume"), 1)
  end
  self.isTurnedOn = false
  self.wasToFast = false
end
function Windrower:delete()
  if self.windrowerSound ~= nil then
    delete(self.windrowerSound)
  end
end
function Windrower:mouseEvent(posX, posY, isDown, isUp, button)
end
function Windrower:keyEvent(unicode, sym, modifier, isDown)
end
function Windrower:update(dt)
  self.wasToFast = false
  if self:getIsActiveForInput() and InputBinding.hasEvent(InputBinding.IMPLEMENT_EXTRA) then
    self.isTurnedOn = not self.isTurnedOn
  end
  if self:getIsActive() then
    if self.isTurnedOn then
      local toFast = self.lastSpeed * 3600 > 31
      if not toFast then
        local x, y, z = getWorldTranslation(self.groundReferenceNode)
        local terrainHeight = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, 0, z)
        if y <= terrainHeight + self.groundReferenceThreshold then
          local numDropAreas = table.getn(self.windrowerDropAreas)
          local numAreas = table.getn(self.cuttingAreas)
          local sum = 0
          local fruitType = FruitUtil.FRUITTYPE_GRASS
          local fruitTypeFix = false
          local foldAnimTime = self.foldAnimTime
          for i = 1, numAreas do
            local cuttingArea = self.cuttingAreas[i]
            if foldAnimTime == nil or foldAnimTime <= cuttingArea.foldMaxLimit and foldAnimTime >= cuttingArea.foldMinLimit then
              local x, y, z = getWorldTranslation(cuttingArea.start)
              local x1, y1, z1 = getWorldTranslation(cuttingArea.width)
              local x2, y2, z2 = getWorldTranslation(cuttingArea.height)
              local ratio = g_currentMission.windrowCutLongRatio
              if not fruitTypeFix then
                fruitType = FruitUtil.FRUITTYPE_GRASS
              end
              local area = Utils.updateFruitCutLongArea(fruitType, x, z, x1, z1, x2, z2, 0) / ratio
              area = area + Utils.updateFruitWindrowArea(fruitType, x, z, x1, z1, x2, z2, 0)
              if area == 0 and not fruitTypeFix then
                fruitType = FruitUtil.FRUITTYPE_DRYGRASS
                area = Utils.updateFruitCutLongArea(fruitType, x, z, x1, z1, x2, z2, 0) / ratio
                area = area + Utils.updateFruitWindrowArea(fruitType, x, z, x1, z1, x2, z2, 0)
              end
              if 0 < area then
                fruitTypeFix = true
              end
              if numDropAreas >= numAreas then
                if 0 < area then
                  local dropArea = self.windrowerDropAreas[i]
                  local x, y, z = getWorldTranslation(dropArea.start)
                  local x1, y1, z1 = getWorldTranslation(dropArea.width)
                  local x2, y2, z2 = getWorldTranslation(dropArea.height)
                  local old, total = Utils.getFruitWindrowArea(fruitType, x, z, x1, z1, x2, z2)
                  area = area + old
                  local value = math.floor(area / total + 0.7)
                  if 1 <= value then
                    value = math.min(value, g_currentMission.maxWindrowValue)
                    Utils.updateFruitWindrowArea(fruitType, x, z, x1, z1, x2, z2, value, true)
                  end
                end
              else
                sum = sum + area
              end
            end
          end
          if 0 < sum and 0 < numDropAreas then
            local dropArea = self.windrowerDropAreas[1]
            local x, y, z = getWorldTranslation(dropArea.start)
            local x1, y1, z1 = getWorldTranslation(dropArea.width)
            local x2, y2, z2 = getWorldTranslation(dropArea.height)
            local old, total = Utils.getFruitWindrowArea(fruitType, x, z, x1, z1, x2, z2)
            sum = sum + old
            local value = math.floor(sum / total + 0.7)
            if 1 <= value then
              value = math.min(value, g_currentMission.maxWindrowValue)
              Utils.updateFruitWindrowArea(fruitType, x, z, x1, z1, x2, z2, value, true)
            end
          end
        end
      end
      if not self.animationEnabled then
        enableAnimTrack(self.animation.animCharSet, 0)
        self.animationEnabled = true
      end
      if not self.windrowerSoundEnabled and self:getIsActiveForSound() then
        playSample(self.windrowerSound, 0, self.windrowerSoundVolume, 0)
        setSamplePitch(self.windrowerSound, self.windrowerSoundPitchOffset)
        self.windrowerSoundEnabled = true
      end
      self.wasToFast = toFast
    elseif self.animationEnabled then
      disableAnimTrack(self.animation.animCharSet, 0)
      self.animationEnabled = false
    end
  end
  if not self.isTurnedOn and self.windrowerSoundEnabled then
    stopSample(self.windrowerSound)
    self.windrowerSoundEnabled = false
  end
end
function Windrower:draw()
  if self.isTurnedOn then
    g_currentMission:addHelpButtonText(string.format(g_i18n:getText("turn_off_OBJECT"), self.typeDesc), InputBinding.IMPLEMENT_EXTRA)
  else
    g_currentMission:addHelpButtonText(string.format(g_i18n:getText("turn_on_OBJECT"), self.typeDesc), InputBinding.IMPLEMENT_EXTRA)
  end
  if self.wasToFast then
    g_currentMission:addWarning(g_i18n:getText("Dont_drive_to_fast") .. "\n" .. string.format(g_i18n:getText("Cruise_control_levelN"), "2", InputBinding.getButtonKeyName(InputBinding.SPEED_LEVEL2)), 0.092, 0.048)
  end
end
function Windrower:onDetach()
  if self.deactivateOnDetach then
    Windrower.onDeactivate(self)
  end
end
function Windrower:onLeave()
  if self.deactivateOnLeave then
    Windrower.onDeactivate(self)
  end
end
function Windrower:onDeactivate()
  if self.animationEnabled then
    disableAnimTrack(self.animation.animCharSet, 0)
    self.animationEnabled = false
  end
  self.isTurnedOn = false
end

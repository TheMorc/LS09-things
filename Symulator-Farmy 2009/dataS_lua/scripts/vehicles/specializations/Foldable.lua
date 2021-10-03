Foldable = {}
function Foldable.prerequisitesPresent(specializations)
  return true
end
function Foldable:load(xmlFile)
  self.setFoldDirection = SpecializationUtil.callSpecializationsFunction("setFoldDirection")
  self.posDirectionText = Utils.getNoNil(getXMLString(xmlFile, "vehicle.foldingParts#posDirectionText"), "fold_OBJECT")
  self.negDirectionText = Utils.getNoNil(getXMLString(xmlFile, "vehicle.foldingParts#negDirectionText"), "unfold_OBJECT")
  local startMoveDirection = Utils.getNoNil(getXMLInt(xmlFile, "vehicle.foldingParts#startMoveDirection"), 0)
  self.startAnimTime = 0
  if 0.1 < startMoveDirection then
    self.startAnimTime = 1
  end
  self.foldAnimTime = 0
  self.maxFoldAnimDuration = 1.0E-4
  self.foldingParts = {}
  local i = 0
  while true do
    local baseName = string.format("vehicle.foldingParts.foldingPart(%d)", i)
    local index = getXMLInt(xmlFile, baseName .. "#componentJointIndex")
    if index == nil then
      break
    end
    local componentJoint = self.componentJoints[index + 1]
    if componentJoint ~= nil then
      local entry = {}
      entry.componentJoint = componentJoint
      entry.anchorActor = Utils.getNoNil(getXMLInt(xmlFile, baseName .. "#anchorActor"), 0)
      local rootNode = Utils.indexToObject(self.components, getXMLString(xmlFile, baseName .. "#rootNode"))
      entry.animCharSet = 0
      if rootNode ~= nil then
        entry.animCharSet = getAnimCharacterSet(rootNode)
        if entry.animCharSet ~= 0 then
          local clip = getAnimClipIndex(entry.animCharSet, getXMLString(xmlFile, baseName .. "#animationClip"))
          if 0 <= clip then
            assignAnimTrackClip(entry.animCharSet, 0, clip)
            setAnimTrackLoopState(entry.animCharSet, 0, false)
            entry.speedScale = Utils.getNoNil(getXMLFloat(xmlFile, baseName .. "#speedScale"), 1)
            entry.animDuration = getAnimClipDuration(entry.animCharSet, clip)
            self.maxFoldAnimDuration = math.max(self.maxFoldAnimDuration, entry.animDuration)
            local node = self.components[componentJoint.componentIndices[(entry.anchorActor + 1) % 2 + 1]].node
            entry.x, entry.y, entry.z = worldToLocal(componentJoint.jointNode, getWorldTranslation(node))
            entry.upX, entry.upY, entry.upZ = worldDirectionToLocal(componentJoint.jointNode, localDirectionToWorld(node, 0, 1, 0))
            entry.dirX, entry.dirY, entry.dirZ = worldDirectionToLocal(componentJoint.jointNode, localDirectionToWorld(node, 0, 0, 1))
            table.insert(self.foldingParts, entry)
          end
        end
      end
    end
    i = i + 1
  end
  self.foldMoveDirection = startMoveDirection
  Foldable.setAnimTime(self, self.startAnimTime)
end
function Foldable:delete()
end
function Foldable:loadFromAttributesAndNodes(xmlFile, key, resetVehicles)
  Foldable.setAnimTime(self, self.startAnimTime)
  return BaseMission.VEHICLE_LOAD_OK
end
function Foldable:setRelativePosition(positionX, offsetY, positionZ, yRot)
  Foldable.setAnimTime(self, self.startAnimTime)
end
function Foldable:mouseEvent(posX, posY, isDown, isUp, button)
end
function Foldable:keyEvent(unicode, sym, modifier, isDown)
end
function Foldable:update(dt)
  if self:getIsActive() then
    for k, foldingPart in pairs(self.foldingParts) do
      local isInvalid = false
      local charSet = foldingPart.animCharSet
      if self.foldMoveDirection > 0.1 then
        local trackTime = getAnimTrackTime(charSet, 0)
        if trackTime < foldingPart.animDuration then
          isInvalid = true
        end
        self.foldAnimTime = trackTime / self.maxFoldAnimDuration
      elseif self.foldMoveDirection < -0.1 then
        local trackTime = getAnimTrackTime(charSet, 0)
        if 0 < trackTime then
          isInvalid = true
        end
        self.foldAnimTime = trackTime / self.maxFoldAnimDuration
      end
      if isInvalid then
        setJointFrame(foldingPart.componentJoint.jointIndex, foldingPart.anchorActor, foldingPart.componentJoint.jointNode)
      end
    end
    self.foldAnimTime = Utils.clamp(self.foldAnimTime, 0, 1)
  end
  if self:getIsActiveForInput() and InputBinding.hasEvent(InputBinding.IMPLEMENT_EXTRA2) then
    if self.foldMoveDirection > 0.1 or self.foldMoveDirection == 0 and self.foldAnimTime > 0.5 then
      self:setFoldDirection(-1)
    else
      self:setFoldDirection(1)
    end
  end
end
function Foldable:draw()
  if table.getn(self.foldingParts) > 0 then
    if self.foldMoveDirection > 0.1 or self.foldMoveDirection == 0 and self.foldAnimTime > 0.5 then
      g_currentMission:addHelpButtonText(string.format(g_i18n:getText(self.negDirectionText), self.typeDesc), InputBinding.IMPLEMENT_EXTRA2)
    else
      g_currentMission:addHelpButtonText(string.format(g_i18n:getText(self.posDirectionText), self.typeDesc), InputBinding.IMPLEMENT_EXTRA2)
    end
  end
end
function Foldable:onDetach()
  if self.deactivateOnDetach then
    Foldable.onDeactivate(self)
  end
end
function Foldable:onLeave()
  if self.deactivateOnLeave then
    Foldable.onDeactivate(self)
  end
end
function Foldable:onDeactivate()
  self:setFoldDirection(0)
end
function Foldable:setFoldDirection(direction)
  self.foldMoveDirection = direction
  for k, foldingPart in pairs(self.foldingParts) do
    local charSet = foldingPart.animCharSet
    local speedScale
    if self.foldMoveDirection > 0.1 then
      speedScale = foldingPart.speedScale
    elseif self.foldMoveDirection < -0.1 then
      speedScale = -foldingPart.speedScale
    end
    if speedScale ~= nil then
      if 0 < speedScale then
        if 0 > getAnimTrackTime(charSet, 0) then
          setAnimTrackTime(charSet, 0, 0)
        end
      elseif getAnimTrackTime(charSet, 0) > foldingPart.animDuration then
        setAnimTrackTime(charSet, 0, foldingPart.animDuration)
      end
      setAnimTrackSpeedScale(charSet, 0, speedScale)
      enableAnimTrack(charSet, 0)
    else
      disableAnimTrack(charSet, 0)
    end
  end
end
function Foldable:setAnimTime(animTime)
  self.foldAnimTime = animTime
  for k, foldingPart in pairs(self.foldingParts) do
    enableAnimTrack(foldingPart.animCharSet, 0)
    setAnimTrackTime(foldingPart.animCharSet, 0, animTime * foldingPart.animDuration, true)
    disableAnimTrack(foldingPart.animCharSet, 0)
  end
  for k, foldingPart in pairs(self.foldingParts) do
    local componentJoint = foldingPart.componentJoint
    local node = self.components[componentJoint.componentIndices[(foldingPart.anchorActor + 1) % 2 + 1]].node
    local x, y, z = localToWorld(componentJoint.jointNode, foldingPart.x, foldingPart.y, foldingPart.z)
    local upX, upY, upZ = localDirectionToWorld(componentJoint.jointNode, foldingPart.upX, foldingPart.upY, foldingPart.upZ)
    local dirX, dirY, dirZ = localDirectionToWorld(componentJoint.jointNode, foldingPart.dirX, foldingPart.dirY, foldingPart.dirZ)
    Utils.setWorldTranslation(node, x, y, z)
    Utils.setWorldDirection(node, dirX, dirY, dirZ, upX, upY, upZ)
    setJointFrame(componentJoint.jointIndex, foldingPart.anchorActor, componentJoint.jointNode)
  end
end

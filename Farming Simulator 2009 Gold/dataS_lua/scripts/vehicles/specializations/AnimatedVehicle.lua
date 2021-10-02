AnimatedVehicle = {}
function AnimatedVehicle.prerequisitesPresent(specializations)
  return true
end
function AnimatedVehicle:load(xmlFile)
  self.playAnimation = SpecializationUtil.callSpecializationsFunction("playAnimation")
  self.stopAnimation = SpecializationUtil.callSpecializationsFunction("stopAnimation")
  self.getIsAnimationPlaying = AnimatedVehicle.getIsAnimationPlaying
  self.getRealAnimationTime = AnimatedVehicle.getRealAnimationTime
  self.getAnimationTime = AnimatedVehicle.getAnimationTime
  self.getAnimationDuration = AnimatedVehicle.getAnimationDuration
  self.setAnimationTime = SpecializationUtil.callSpecializationsFunction("setAnimationTime")
  self.setAnimationStopTime = SpecializationUtil.callSpecializationsFunction("setAnimationStopTime")
  self.setAnimationSpeed = SpecializationUtil.callSpecializationsFunction("setAnimationSpeed")
  self.animations = {}
  local i = 0
  while true do
    local key = string.format("vehicle.animations.animation(%d)", i)
    if not hasXMLProperty(xmlFile, key) then
      break
    end
    local name = getXMLString(xmlFile, key .. "#name")
    if name ~= nil then
      local animation = {}
      animation.name = name
      animation.parts = {}
      animation.currentTime = 0
      animation.currentSpeed = 1
      local partI = 0
      while true do
        local partKey = key .. string.format(".part(%d)", partI)
        if not hasXMLProperty(xmlFile, partKey) then
          break
        end
        local node = Utils.indexToObject(self.components, getXMLString(xmlFile, partKey .. "#node"))
        local startTime = getXMLFloat(xmlFile, partKey .. "#startTime")
        local duration = getXMLFloat(xmlFile, partKey .. "#duration")
        local endTime = getXMLFloat(xmlFile, partKey .. "#endTime")
        local startRot = Utils.getRadiansFromString(getXMLString(xmlFile, partKey .. "#startRot"), 3)
        local endRot = Utils.getRadiansFromString(getXMLString(xmlFile, partKey .. "#endRot"), 3)
        local startTrans = Utils.getVectorNFromString(getXMLString(xmlFile, partKey .. "#startTrans"), 3)
        local endTrans = Utils.getVectorNFromString(getXMLString(xmlFile, partKey .. "#endTrans"), 3)
        local hasRot = endRot ~= nil
        local hasTrans = endTrans ~= nil
        if node ~= nil and startTime ~= nil and (duration ~= nil or endTime ~= nil) and (hasRot or hasTrans) then
          if endTime ~= nil then
            duration = endTime - startTime
          end
          if hasRot and startRot == nil then
            local x, y, z = getRotation(node)
            startRot = {
              x,
              y,
              z
            }
          end
          if hasTrans and startTrans == nil then
            local x, y, z = getTranslation(node)
            startTrans = {
              x,
              y,
              z
            }
          end
          local part = {}
          part.node = node
          part.startTime = startTime * 1000
          part.duration = duration * 1000
          if hasRot then
            part.startRot = startRot
            part.endRot = endRot
          end
          if hasTrans then
            part.startTrans = startTrans
            part.endTrans = endTrans
          end
          table.insert(animation.parts, part)
        end
        partI = partI + 1
      end
      animation.partsReverse = {}
      for i, part in ipairs(animation.parts) do
        table.insert(animation.partsReverse, part)
      end
      table.sort(animation.parts, AnimatedVehicle.animPartSorter)
      table.sort(animation.partsReverse, AnimatedVehicle.animPartSorterReverse)
      animation.currentPartIndex = 1
      animation.duration = 0
      for _, part in ipairs(animation.parts) do
        animation.duration = math.max(animation.duration, part.startTime + part.duration)
      end
      self.animations[name] = animation
    end
    i = i + 1
  end
  self.activeAnimations = {}
end
function AnimatedVehicle:delete()
end
function AnimatedVehicle:mouseEvent(posX, posY, isDown, isUp, button)
end
function AnimatedVehicle:keyEvent(unicode, sym, modifier, isDown)
end
function AnimatedVehicle:update(dt)
  AnimatedVehicle.updateAnimations(self, dt)
end
function AnimatedVehicle:draw()
end
function AnimatedVehicle:onDetach()
end
function AnimatedVehicle:onLeave()
end
function AnimatedVehicle:onDeactivate()
end
function AnimatedVehicle:onDeactivateSounds()
end
function AnimatedVehicle:playAnimation(name, speed, animTime)
  local animation = self.animations[name]
  if animation ~= nil then
    self.activeAnimations[name] = animation
    if speed ~= nil then
      animation.currentSpeed = speed
    end
    if animTime ~= nil then
      animation.currentTime = animTime * animation.duration
    elseif animation.currentSpeed > 0 then
      animation.currentTime = 0
    else
      animation.currentTime = animation.duration
    end
    AnimatedVehicle.findCurrentPartIndex(animation)
    for k, part in ipairs(animation.parts) do
      part.curRot = nil
      part.speedRot = nil
      part.curTrans = nil
      part.speedTrans = nil
    end
  end
end
function AnimatedVehicle:stopAnimation(name)
  local animation = self.animations[name]
  if animation ~= nil then
    animation.stopTime = nil
  end
  self.activeAnimations[name] = nil
end
function AnimatedVehicle:getIsAnimationPlaying(name)
  return self.activeAnimations[name] ~= nil
end
function AnimatedVehicle:getRealAnimationTime(name)
  local animation = self.animations[name]
  if animation ~= nil then
    return animation.currentTime
  end
  return 0
end
function AnimatedVehicle:getAnimationTime(name)
  local animation = self.animations[name]
  if animation ~= nil then
    return animation.currentTime / animation.duration
  end
  return 0
end
function AnimatedVehicle:getAnimationDuration(name)
  local animation = self.animations[name]
  if animation ~= nil then
    return animation.duration
  end
  return 1
end
function AnimatedVehicle:setAnimationSpeed(name, speed)
  local animation = self.animations[name]
  if animation ~= nil then
    local speedReversed = false
    if animation.currentSpeed > 0 ~= (0 < speed) then
      speedReversed = true
    end
    animation.currentSpeed = speed
    if self:getIsAnimationPlaying(name) and speedReversed then
      AnimatedVehicle.findCurrentPartIndex(animation)
      for k, part in ipairs(animation.parts) do
        part.curRot = nil
        part.speedRot = nil
        part.curTrans = nil
        part.speedTrans = nil
      end
    end
  end
end
function AnimatedVehicle:setAnimationStopTime(name, stopTime)
  local animation = self.animations[name]
  if animation ~= nil then
    animation.stopTime = stopTime * animation.duration
  end
end
function AnimatedVehicle.animPartSorter(a, b)
  if a.startTime < b.startTime then
    return true
  elseif a.startTime == b.startTime then
    return a.duration < b.duration
  end
  return false
end
function AnimatedVehicle.animPartSorterReverse(a, b)
  local endTimeA = a.startTime + a.duration
  local endTimeB = b.startTime + b.duration
  if endTimeA > endTimeB then
    return true
  elseif endTimeA == endTimeB then
    return a.startTime > b.startTime
  end
  return false
end
function AnimatedVehicle.getMovedLimitedValue(currentValue, destValue, speed, dt)
  local limitF = math.min
  if destValue < currentValue then
    limitF = math.max
  elseif destValue == currentValue then
    return currentValue
  end
  local ret = limitF(currentValue + speed * dt, destValue)
  return ret
end
function AnimatedVehicle.findCurrentPartIndex(animation)
  if animation.currentSpeed > 0 then
    animation.currentPartIndex = 1
    for i, part in ipairs(animation.parts) do
      if part.startTime <= animation.currentTime then
        animation.currentPartIndex = i
        break
      end
    end
  else
    local num = table.getn(animation.partsReverse)
    animation.currentPartIndex = num
    for i, part in ipairs(animation.partsReverse) do
      if part.startTime + part.duration >= animation.currentTime then
        animation.currentPartIndex = i
        break
      end
    end
  end
end
function AnimatedVehicle:updateAnimations(dt)
  for name, anim in pairs(self.activeAnimations) do
    anim.currentTime = anim.currentTime + dt * anim.currentSpeed
    local absSpeed = math.abs(anim.currentSpeed)
    local dtToUse = dt * absSpeed
    local stopAnim = false
    if anim.stopTime ~= nil then
      if anim.currentSpeed > 0 then
        if anim.stopTime < anim.currentTime then
          dtToUse = dtToUse - (anim.currentTime - anim.stopTime)
          anim.currentTime = anim.stopTime
          stopAnim = true
        end
      elseif anim.stopTime > anim.currentTime then
        dtToUse = dtToUse - (anim.stopTime - anim.currentTime)
        anim.currentTime = anim.stopTime
        stopAnim = true
      end
    end
    local numParts = table.getn(anim.parts)
    local parts = anim.parts
    if anim.currentSpeed < 0 then
      parts = anim.partsReverse
    end
    for i = anim.currentPartIndex, numParts do
      local part = parts[i]
      local doBreak = false
      if anim.currentSpeed > 0 then
        if part.startTime + part.duration < anim.currentTime then
          part.curRot = nil
          part.speedRot = nil
          part.curTrans = nil
          part.speedTrans = nil
          anim.currentPartIndex = anim.currentPartIndex + 1
        end
        if part.startTime > anim.currentTime then
          break
        end
      else
        if part.startTime > anim.currentTime then
          part.curRot = nil
          part.speedRot = nil
          part.curTrans = nil
          part.speedTrans = nil
          anim.currentPartIndex = anim.currentPartIndex + 1
        end
        if part.startTime + part.duration < anim.currentTime then
          break
        end
      end
      local hasChanged = false
      if part.startRot ~= nil then
        if part.curRot == nil then
          local x, y, z = getRotation(part.node)
          part.curRot = {
            x,
            y,
            z
          }
          if anim.currentSpeed > 0 then
            local duration = part.startTime + math.max(part.duration - anim.currentTime, 0)
            part.speedRot = {
              (part.endRot[1] - x) / duration,
              (part.endRot[2] - y) / duration,
              (part.endRot[3] - z) / duration
            }
          else
            local duration = anim.currentTime - part.startTime
            part.speedRot = {
              (part.startRot[1] - x) / duration,
              (part.startRot[2] - y) / duration,
              (part.startRot[3] - z) / duration
            }
          end
        end
        local destRot = part.endRot
        if anim.currentSpeed < 0 then
          destRot = part.startRot
        end
        local hasRotChanged = false
        for i = 1, 3 do
          local newRot = AnimatedVehicle.getMovedLimitedValue(part.curRot[i], destRot[i], part.speedRot[i], dtToUse)
          if part.curRot[i] ~= newRot then
            hasRotChanged = true
            part.curRot[i] = newRot
          end
        end
        if hasRotChanged then
          setRotation(part.node, part.curRot[1], part.curRot[2], part.curRot[3])
          hasChanged = true
        end
      end
      if part.startTrans ~= nil then
        if part.curTrans == nil then
          local x, y, z = getTranslation(part.node)
          part.curTrans = {
            x,
            y,
            z
          }
          if anim.currentSpeed > 0 then
            local duration = part.startTime + math.max(part.duration - anim.currentTime, 0)
            part.speedTrans = {
              (part.endTrans[1] - x) / duration,
              (part.endTrans[2] - y) / duration,
              (part.endTrans[3] - z) / duration
            }
          else
            local duration = anim.currentTime - part.startTime
            part.speedTrans = {
              (part.startTrans[1] - x) / duration,
              (part.startTrans[2] - y) / duration,
              (part.startTrans[3] - z) / duration
            }
          end
        end
        local destTrans = part.endTrans
        if anim.currentSpeed < 0 then
          destTrans = part.startTrans
        end
        local hasTransChanged = false
        for i = 1, 3 do
          local newTrans = AnimatedVehicle.getMovedLimitedValue(part.curTrans[i], destTrans[i], part.speedTrans[i], dtToUse)
          if newTrans ~= part.curTrans[i] then
            hasTransChanged = true
            part.curTrans[i] = newTrans
          end
        end
        if hasTransChanged then
          setTranslation(part.node, part.curTrans[1], part.curTrans[2], part.curTrans[3])
          hasChanged = true
        end
      end
      if hasChanged and self.setMovingToolDirty ~= nil then
        self:setMovingToolDirty(part.node)
      end
      if not hasChanged and (anim.currentSpeed > 0 and anim.currentPartIndex == numParts or anim.currentSpeed < 0 and anim.currentPartIndex == 1) then
        if anim.currentSpeed > 0 then
          anim.currentTime = anim.duration
        else
          anim.currentTime = 0
        end
        anim.currentPartIndex = 0
        break
      end
    end
    if stopAnim or numParts < anim.currentPartIndex or anim.currentPartIndex < 1 then
      anim.currentTime = math.min(math.max(anim.currentTime, 0), anim.duration)
      anim.stopTime = nil
      self.activeAnimations[name] = nil
    end
  end
end

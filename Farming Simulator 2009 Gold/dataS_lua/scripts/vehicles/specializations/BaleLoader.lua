BaleLoader = {}
function BaleLoader.prerequisitesPresent(specializations)
  return SpecializationUtil.hasSpecialization(Trailer, specializations)
end
BaleLoader.GRAB_MOVE_UP = 1
BaleLoader.GRAB_MOVE_DOWN = 2
BaleLoader.GRAB_DROP_BALE = 3
BaleLoader.EMPTY_TO_WORK = 1
BaleLoader.EMPTY_ROTATE_PLATFORM = 2
BaleLoader.EMPTY_ROTATE1 = 3
BaleLoader.EMPTY_CLOSE_GRIPPERS = 4
BaleLoader.EMPTY_HIDE_PUSHER1 = 5
BaleLoader.EMPTY_HIDE_PUSHER2 = 6
BaleLoader.EMPTY_ROTATE2 = 7
BaleLoader.EMPTY_WAIT_TO_DROP = 8
BaleLoader.EMPTY_WAIT_TO_SINK = 9
BaleLoader.EMPTY_CLOSE = 10
BaleLoader.EMPTY_CANCEL = 11
BaleLoader.EMPTY_WAIT_TO_REDO = 12
function BaleLoader:load(xmlFile)
  self.balesToLoad = {}
  self.isInWorkPosition = false
  self.moveGrabber = false
  self.allowGrabbing = false
  self.itemsToSave = {}
  self.fillLevel = 0
  self.fillLevelMax = Utils.getNoNil(getXMLInt(xmlFile, "vehicle.capacity"), 0)
  self.baleGrabber = {}
  self.baleGrabber.grabNode = Utils.indexToObject(self.components, getXMLString(xmlFile, "vehicle.baleGrabber#grabNode"))
  self.startBalePlace = {}
  self.startBalePlace.bales = {}
  self.startBalePlace.node = Utils.indexToObject(self.components, getXMLString(xmlFile, "vehicle.balePlaces#startBalePlace"))
  if self.startBalePlace.node ~= nil then
    if getNumOfChildren(self.startBalePlace.node) < 4 then
      self.startBalePlace.node = nil
    else
      self.startBalePlace.origRot = {}
      self.startBalePlace.origTrans = {}
      for i = 1, 4 do
        local node = getChildAt(self.startBalePlace.node, i - 1)
        local x, y, z = getRotation(node)
        self.startBalePlace.origRot[i] = {
          x,
          y,
          z
        }
        local x, y, z = getTranslation(node)
        self.startBalePlace.origTrans[i] = {
          x,
          y,
          z
        }
      end
    end
  end
  self.startBalePlace.count = 0
  self.currentBalePlace = 1
  self.balePlaces = {}
  local i = 0
  while true do
    local key = string.format("vehicle.balePlaces.balePlace(%d)", i)
    if not hasXMLProperty(xmlFile, key) then
      break
    end
    local node = Utils.indexToObject(self.components, getXMLString(xmlFile, key .. "#node"))
    if node ~= nil then
      local entry = {}
      entry.node = node
      table.insert(self.balePlaces, entry)
    end
    i = i + 1
  end
  self.baleGrabSound = {}
  local baleGrabSoundFile = getXMLString(xmlFile, "vehicle.baleGrabSound#file")
  if baleGrabSoundFile ~= nil then
    self.baleGrabSound.sample = createSample("baleDropSound")
    loadSample(self.baleGrabSound.sample, baleGrabSoundFile, false)
    local pitch = getXMLFloat(xmlFile, "vehicle.baleDropSound#pitchOffset")
    if pitch ~= nil then
      setSamplePitch(self.baleGrabSound.sample, pitch)
    end
    self.baleGrabSound.volume = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.baleGrabSound#volume"), 1)
  end
  self.baleGrabParticleSystems = {}
  local psName = "vehicle.baleGrabParticleSystem"
  Utils.loadParticleSystem(xmlFile, self.baleGrabParticleSystems, psName, self.components, false, nil, self.baseDirectory)
  self.baleGrabParticleSystemDisableTime = 0
  self.baleGrabParticleSystemDisableDuration = Utils.getNoNil(getXMLFloat(xmlFile, psName .. "#disableDuration"), 0.6) * 1000
  self.hydraulicSound = {}
  local hydraulicSoundFile = getXMLString(xmlFile, "vehicle.hydraulicSound#file")
  if hydraulicSoundFile ~= nil then
    self.hydraulicSound.sample = createSample("hydraulicSound")
    loadSample(self.hydraulicSound.sample, hydraulicSoundFile, false)
    local pitch = getXMLFloat(xmlFile, "vehicle.hydraulicSound#pitchOffset")
    if pitch ~= nil then
      setSamplePitch(self.hydraulicSound.sample, pitch)
    end
    self.hydraulicSound.volume = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.hydraulicSound#volume"), 1)
    self.hydraulicSound.enabled = false
  end
  self.workTransportButton = InputBinding.IMPLEMENT_EXTRA
  self.emptyAbortButton = InputBinding.IMPLEMENT_EXTRA2
  self.emptyButton = InputBinding.IMPLEMENT_EXTRA3
  self.baleTypes = {}
  local i = 0
  while true do
    local key = string.format("vehicle.baleTypes.baleType(%d)", i)
    if not hasXMLProperty(xmlFile, key) then
      break
    end
    local filename = getXMLString(xmlFile, key .. "#filename")
    if filename ~= nil then
      table.insert(self.baleTypes, filename)
    end
    i = i + 1
  end
  if table.getn(self.baleTypes) == 0 then
    table.insert(self.baleTypes, "data/maps/models/objects/strawbale/strawbaleBaler.i3d")
  end
end
function BaleLoader:delete()
  if self.baleGrabSound.sample ~= nil then
    delete(self.baleGrabSound.sample)
  end
end
function BaleLoader:mouseEvent(posX, posY, isDown, isUp, button)
end
function BaleLoader:draw()
  if self.attacherVehicle ~= nil then
    if self.emptyState == nil then
      if self.grabberMoveState == nil then
        if self.isInWorkPosition then
          g_currentMission:addHelpButtonText(g_i18n:getText("BALELOADER_TRANSPORT"), self.workTransportButton)
        else
          g_currentMission:addHelpButtonText(g_i18n:getText("BALELOADER_WORK"), self.workTransportButton)
        end
      end
      if self.fillLevel > 0 and self.rotatePlatformDirection == nil and self.frontBalePusherDirection == nil and not self.moveGrabber and self.grabberMoveState == nil then
        g_currentMission:addHelpButtonText(g_i18n:getText("BALELOADER_UNLOAD"), self.emptyButton)
      end
    elseif self.emptyState >= BaleLoader.EMPTY_TO_WORK and self.emptyState <= BaleLoader.EMPTY_ROTATE2 then
      g_currentMission:addExtraPrintText(g_i18n:getText("BALELOADER_UP"))
    elseif self.emptyState == BaleLoader.EMPTY_CANCEL or self.emptyState == BaleLoader.EMPTY_CLOSE then
      g_currentMission:addExtraPrintText(g_i18n:getText("BALELOADER_DOWN"))
    elseif self.emptyState == BaleLoader.EMPTY_WAIT_TO_DROP then
      g_currentMission:addHelpButtonText(g_i18n:getText("BALELOADER_READY"), self.emptyButton)
      g_currentMission:addHelpButtonText(g_i18n:getText("BALELOADER_ABORT"), self.emptyAbortButton)
    elseif self.emptyState == BaleLoader.EMPTY_WAIT_TO_SINK then
      g_currentMission:addHelpButtonText(g_i18n:getText("BALELOADER_SINK"), self.emptyButton)
    elseif self.emptyState == BaleLoader.EMPTY_WAIT_TO_REDO then
      g_currentMission:addHelpButtonText(g_i18n:getText("BALELOADER_UNLOAD"), self.emptyButton)
    end
  end
end
function BaleLoader:keyEvent(unicode, sym, modifier, isDown)
end
function BaleLoader:update(dt)
  if self.firstTimeRun then
    for k, v in pairs(self.balesToLoad) do
      local baleRoot = Utils.loadSharedI3DFile(v.filename, self.baseDirectory)
      local baleId = getChildAt(baleRoot, v.childIndex)
      setRigidBodyType(baleId, "None")
      setRotation(baleId, unpack(v.rotation))
      setTranslation(baleId, unpack(v.translation))
      link(v.parentNode, baleId)
      table.insert(v.bales, {
        node = baleId,
        i3dFilename = v.filename,
        childIndex = v.childIndex
      })
      delete(baleRoot)
    end
    self.balesToLoad = {}
  end
  if self:getIsActive() then
    if self:getIsActiveForInput() then
      if InputBinding.hasEvent(self.emptyButton) then
        if self.emptyState ~= nil then
          if self.emptyState == BaleLoader.EMPTY_WAIT_TO_DROP then
            self.currentBalePlace = 1
            for _, balePlace in pairs(self.balePlaces) do
              if balePlace.bales ~= nil then
                for _, bale in pairs(balePlace.bales) do
                  local node = bale.node
                  local x, y, z = getWorldTranslation(node)
                  setTranslation(node, x, y, z)
                  local x, y, z = getWorldRotation(node)
                  setRotation(node, x, y, z)
                  setRigidBodyType(node, "Dynamic")
                  link(getRootNode(), node)
                  table.insert(g_currentMission.itemsToSave, bale)
                end
                balePlace.bales = nil
              end
            end
            self.fillLevel = 0
            self:playAnimation("closeGrippers", -1)
            self.emptyState = BaleLoader.EMPTY_WAIT_TO_SINK
          elseif self.emptyState == BaleLoader.EMPTY_WAIT_TO_SINK then
            self:playAnimation("emptyRotate", -1)
            self:playAnimation("moveBalePlacesToEmpty", -5)
            self:playAnimation("emptyHidePusher1", -1)
            self:playAnimation("rotatePlatform", -1)
            if not self.isInWorkPosition then
              self:playAnimation("closeGrippers", 1, self:getAnimationTime("closeGrippers"))
              self:playAnimation("baleGrabberTransportToWork", -1)
            end
            self.emptyState = BaleLoader.EMPTY_CLOSE
          elseif self.emptyState == BaleLoader.EMPTY_WAIT_TO_REDO then
            self:playAnimation("emptyRotate", 1)
            self.emptyState = BaleLoader.EMPTY_ROTATE2
          end
        elseif self.fillLevel > 0 and self.rotatePlatformDirection == nil and self.frontBalePusherDirection == nil and not self.moveGrabber and self.grabberMoveState == nil then
          BaleLoader.moveToWorkPosition(self)
          self.emptyState = BaleLoader.EMPTY_TO_WORK
        end
      end
      if InputBinding.hasEvent(self.emptyAbortButton) and self.emptyState ~= nil and self.emptyState == BaleLoader.EMPTY_WAIT_TO_DROP then
        self:playAnimation("emptyRotate", -1)
        self.emptyState = BaleLoader.EMPTY_CANCEL
      end
      if InputBinding.hasEvent(self.workTransportButton) and self.emptyState == nil and self.grabberMoveState == nil then
        self.moveGrabber = true
        self.isInWorkPosition = not self.isInWorkPosition
        if self.isInWorkPosition then
          BaleLoader.moveToWorkPosition(self)
        else
          BaleLoader.moveToTransportPosition(self)
        end
      end
    end
    if self.baleGrabParticleSystemDisableTime ~= 0 and self.baleGrabParticleSystemDisableTime < self.time then
      Utils.setEmittingState(self.baleGrabParticleSystems, false)
      self.baleGrabParticleSystemDisableTime = 0
    end
    if self.moveGrabber and not self:getIsAnimationPlaying("baleGrabberTransportToWork") then
      self.moveGrabber = false
    end
    self.allowGrabbing = false
    if self.isInWorkPosition and not self.moveGrabber and self.grabberMoveState == nil and self.startBalePlace.count < 4 and self.frontBalePusherDirection == nil and self.rotatePlatformDirection == nil and self.emptyState == nil and self.fillLevel < self.fillLevelMax then
      self.allowGrabbing = true
    end
    if self.allowGrabbing and self.baleGrabber.grabNode ~= nil and self.baleGrabber.currentBale == nil then
      local nearestBaleIndex = BaleLoader.getBaleInRange(self, self.baleGrabber.grabNode)
      if nearestBaleIndex ~= nil then
        local bale = g_currentMission.itemsToSave[nearestBaleIndex]
        self.baleGrabber.currentBale = bale
        setRigidBodyType(bale.node, "None")
        link(self.baleGrabber.grabNode, bale.node)
        setRotation(bale.node, 0, 0, 0)
        setTranslation(bale.node, 0, 0, 0)
        self.grabberMoveState = BaleLoader.GRAB_MOVE_UP
        self:playAnimation("baleGrabberWorkToDrop", 1)
        if self.baleGrabSound.sample ~= nil then
          playSample(self.baleGrabSound.sample, 1, self.baleGrabSound.volume, 0)
        end
        Utils.setEmittingState(self.baleGrabParticleSystems, true)
        self.baleGrabParticleSystemDisableTime = self.time + self.baleGrabParticleSystemDisableDuration
        table.remove(g_currentMission.itemsToSave, nearestBaleIndex)
      end
    end
    if self.grabberMoveState ~= nil then
      if self.grabberMoveState == BaleLoader.GRAB_MOVE_UP then
        if not self:getIsAnimationPlaying("baleGrabberWorkToDrop") then
          self:playAnimation("baleGrabberDropBale", 1)
          if self.startBalePlace.count == 1 then
            self:playAnimation("bale1ToOtherSide", 1)
          elseif self.startBalePlace.count == 3 then
            self:playAnimation("bale3ToOtherSide", 1)
          end
          self.grabberMoveState = BaleLoader.GRAB_DROP_BALE
        end
      elseif self.grabberMoveState == BaleLoader.GRAB_DROP_BALE then
        if not self:getIsAnimationPlaying("baleGrabberDropBale") and self.startBalePlace.count < 4 and self.startBalePlace.node ~= nil then
          local attachNode = getChildAt(self.startBalePlace.node, self.startBalePlace.count)
          local baleNode = self.baleGrabber.currentBale.node
          link(attachNode, baleNode)
          self.startBalePlace.count = self.startBalePlace.count + 1
          table.insert(self.startBalePlace.bales, self.baleGrabber.currentBale)
          self.baleGrabber.currentBale = nil
          if self.startBalePlace.count == 2 then
            self.frontBalePusherDirection = 1
            self:playAnimation("balesToOtherRow", 1)
            self:playAnimation("frontBalePusher", 1)
          elseif self.startBalePlace.count == 4 then
            BaleLoader.rotatePlatform(self)
          end
          self.fillLevel = self.fillLevel + 1
          self:playAnimation("baleGrabberDropBale", -5)
          self:playAnimation("baleGrabberWorkToDrop", -1)
          self.grabberMoveState = BaleLoader.GRAB_MOVE_DOWN
        end
      elseif self.grabberMoveState == BaleLoader.GRAB_MOVE_DOWN and not self:getIsAnimationPlaying("baleGrabberWorkToDrop") then
        self.grabberMoveState = nil
      end
    end
    if self.frontBalePusherDirection ~= nil and not self:getIsAnimationPlaying("frontBalePusher") then
      if 0 < self.frontBalePusherDirection then
        self:playAnimation("frontBalePusher", -1)
        self.frontBalePusherDirection = -1
      else
        self.frontBalePusherDirection = nil
      end
    end
    if self.rotatePlatformDirection ~= nil and not self:getIsAnimationPlaying("rotatePlatform") then
      if 0 < self.rotatePlatformDirection then
        if not self:getIsAnimationPlaying("rotatePlatformMoveBales") and not self:getIsAnimationPlaying("moveBalePlaces") then
          local balePlace = self.balePlaces[self.currentBalePlace]
          self.currentBalePlace = self.currentBalePlace + 1
          for i = 1, table.getn(self.startBalePlace.bales) do
            local node = getChildAt(self.startBalePlace.node, i - 1)
            local x, y, z = getTranslation(node)
            local baleNode = self.startBalePlace.bales[i].node
            setTranslation(baleNode, x, y, z)
            link(balePlace.node, baleNode)
          end
          balePlace.bales = self.startBalePlace.bales
          self.startBalePlace.bales = {}
          self.startBalePlace.count = 0
          for i = 1, 4 do
            local node = getChildAt(self.startBalePlace.node, i - 1)
            setRotation(node, unpack(self.startBalePlace.origRot[i]))
            setTranslation(node, unpack(self.startBalePlace.origTrans[i]))
          end
          if self.emptyState == nil then
            self.rotatePlatformDirection = -1
            self:playAnimation("rotatePlatform", -1)
          else
            self.rotatePlatformDirection = nil
          end
        end
      else
        self.rotatePlatformDirection = nil
      end
    end
    if self.emptyState ~= nil then
      if self.emptyState == BaleLoader.EMPTY_TO_WORK then
        if not self:getIsAnimationPlaying("baleGrabberTransportToWork") then
          if self.startBalePlace.count == 0 then
            self:playAnimation("rotatePlatform", 1)
          else
            BaleLoader.rotatePlatform(self)
          end
          self.emptyState = BaleLoader.EMPTY_ROTATE_PLATFORM
        end
      elseif self.emptyState == BaleLoader.EMPTY_ROTATE_PLATFORM then
        if not self:getIsAnimationPlaying("rotatePlatform") then
          self.rotatePlatformDirection = nil
          self:playAnimation("emptyRotate", 1)
          self:setAnimationStopTime("emptyRotate", 0.2)
          local balePlacesTime = self:getRealAnimationTime("moveBalePlaces")
          self:playAnimation("moveBalePlacesToEmpty", 1.5, balePlacesTime / self:getAnimationDuration("moveBalePlacesToEmpty"))
          self:playAnimation("moveBalePusherToEmpty", 1.5, balePlacesTime / self:getAnimationDuration("moveBalePusherToEmpty"))
          self.emptyState = BaleLoader.EMPTY_ROTATE1
        end
      elseif self.emptyState == BaleLoader.EMPTY_ROTATE1 then
        if not self:getIsAnimationPlaying("emptyRotate") and not self:getIsAnimationPlaying("moveBalePlacesToEmpty") then
          self:playAnimation("closeGrippers", 1)
          self.emptyState = BaleLoader.EMPTY_CLOSE_GRIPPERS
        end
      elseif self.emptyState == BaleLoader.EMPTY_CLOSE_GRIPPERS then
        if not self:getIsAnimationPlaying("closeGrippers") then
          self:playAnimation("emptyHidePusher1", 1)
          self.emptyState = BaleLoader.EMPTY_HIDE_PUSHER1
        end
      elseif self.emptyState == BaleLoader.EMPTY_HIDE_PUSHER1 then
        if not self:getIsAnimationPlaying("emptyHidePusher1") then
          self:playAnimation("moveBalePusherToEmpty", -2)
          self.emptyState = BaleLoader.EMPTY_HIDE_PUSHER2
        end
      elseif self.emptyState == BaleLoader.EMPTY_HIDE_PUSHER2 then
        if self:getAnimationTime("moveBalePusherToEmpty") < 0.7 then
          self:playAnimation("emptyRotate", 1, self:getAnimationTime("emptyRotate"))
          self.emptyState = BaleLoader.EMPTY_ROTATE2
        end
      elseif self.emptyState == BaleLoader.EMPTY_ROTATE2 then
        if not self:getIsAnimationPlaying("emptyRotate") then
          self.emptyState = BaleLoader.EMPTY_WAIT_TO_DROP
        end
      elseif self.emptyState == BaleLoader.EMPTY_CLOSE then
        if not self:getIsAnimationPlaying("emptyRotate") and not self:getIsAnimationPlaying("moveBalePlacesToEmpty") and not self:getIsAnimationPlaying("emptyHidePusher1") and not self:getIsAnimationPlaying("rotatePlatform") then
          self.emptyState = nil
        end
      elseif self.emptyState == BaleLoader.EMPTY_CANCEL and not self:getIsAnimationPlaying("emptyRotate") then
        self.emptyState = BaleLoader.EMPTY_WAIT_TO_REDO
      end
    end
    if self.hydraulicSound.sample ~= nil then
      local hasAnimationsPlaying = false
      for _, v in pairs(self.activeAnimations) do
        hasAnimationsPlaying = true
        break
      end
      if hasAnimationsPlaying then
        if not self.hydraulicSound.enabled then
          playSample(self.hydraulicSound.sample, 0, self.hydraulicSound.volume, 0)
          self.hydraulicSound.enabled = true
        end
      elseif self.hydraulicSound.enabled then
        stopSample(self.hydraulicSound.sample)
        self.hydraulicSound.enabled = false
      end
    end
  end
end
function BaleLoader:getBaleInRange(refNode)
  local px, py, pz = getWorldTranslation(refNode)
  local nearestDistance = 3
  local nearestIndex
  for index, item in pairs(g_currentMission.itemsToSave) do
    for _, filename in pairs(self.baleTypes) do
      if item.i3dFilename == filename then
        local vx, vy, vz = getWorldTranslation(item.node)
        local distance = Utils.vector3Length(px - vx, py - vy, pz - vz)
        if nearestDistance > distance then
          nearestDistance = distance
          nearestIndex = index
        end
        break
      end
    end
  end
  return nearestIndex
end
function BaleLoader:onDetach()
  if self.deactivateOnDetach then
    BaleLoader.onDeactivate(self)
  else
    BaleLoader.onDeactivateSounds(self)
  end
end
function BaleLoader:onAttach()
end
function BaleLoader:onDeactivate()
  Utils.setEmittingState(self.baleGrabParticleSystems, false)
  BaleLoader.onDeactivateSounds(self)
end
function BaleLoader:onDeactivateSounds()
  if self.hydraulicSound.sample ~= nil then
    stopSample(self.hydraulicSound.sample)
  end
end
function BaleLoader:loadFromAttributesAndNodes(xmlFile, key, resetVehicles)
  self.currentBalePlace = 1
  self.startBalePlace.count = 0
  local numBales = 0
  local i = 0
  while true do
    local baleKey = key .. string.format(".bale(%d)", i)
    if not hasXMLProperty(xmlFile, baleKey) then
      break
    end
    local filename = getXMLString(xmlFile, baleKey .. "#filename")
    if filename ~= nil then
      local childIndex = getXMLInt(xmlFile, baleKey .. "#childIndex")
      if childIndex == nil then
        childIndex = 0
      end
      local x, y, z = Utils.getVectorFromString(getXMLString(xmlFile, baleKey .. "#position"))
      local xRot, yRot, zRot = Utils.getVectorFromString(getXMLString(xmlFile, baleKey .. "#rotation"))
      local balePlace = getXMLInt(xmlFile, baleKey .. "#balePlace")
      local helper = getXMLInt(xmlFile, baleKey .. "#helper")
      if balePlace == nil or 0 < balePlace and (x == nil or y == nil or z == nil or xRot == nil or yRot == nil or zRot == nil) or balePlace < 1 and helper == nil then
        print("Warning: corrupt savegame, bale " .. filename .. " could not be loaded")
      else
        local translation, rotation
        if 0 < balePlace then
          translation = {
            x,
            y,
            z
          }
          rotation = {
            xRot,
            yRot,
            zRot
          }
        else
          translation = {
            0,
            0,
            0
          }
          rotation = {
            0,
            0,
            0
          }
        end
        local parentNode, bales
        if balePlace < 1 then
          if helper <= getNumOfChildren(self.startBalePlace.node) then
            parentNode = getChildAt(self.startBalePlace.node, helper - 1)
            if self.startBalePlace.bales == nil then
              self.startBalePlace.bales = {}
            end
            bales = self.startBalePlace.bales
            self.startBalePlace.count = self.startBalePlace.count + 1
          end
        elseif balePlace <= table.getn(self.balePlaces) then
          self.currentBalePlace = math.max(self.currentBalePlace, balePlace + 1)
          parentNode = self.balePlaces[balePlace].node
          if self.balePlaces[balePlace].bales == nil then
            self.balePlaces[balePlace].bales = {}
          end
          bales = self.balePlaces[balePlace].bales
        end
        if parentNode ~= nil then
          numBales = numBales + 1
          table.insert(self.balesToLoad, {
            parentNode = parentNode,
            filename = filename,
            bales = bales,
            translation = translation,
            rotation = rotation,
            childIndex = childIndex
          })
        end
      end
    end
    i = i + 1
  end
  if self.currentBalePlace > 2 then
    self:playAnimation("moveBalePlaces", 20, 0)
    self:setAnimationStopTime("moveBalePlaces", (self.currentBalePlace - 2) / (table.getn(self.balePlaces) - 1))
    AnimatedVehicle.updateAnimations(self, 99999999)
  end
  if 1 <= self.startBalePlace.count then
    self:playAnimation("bale1ToOtherSide", 20)
    AnimatedVehicle.updateAnimations(self, 99999999)
    if self.startBalePlace.count >= 2 then
      self:playAnimation("balesToOtherRow", 20)
      AnimatedVehicle.updateAnimations(self, 99999999)
      if self.startBalePlace.count >= 3 then
        self:playAnimation("bale3ToOtherSide", 20)
        AnimatedVehicle.updateAnimations(self, 99999999)
        if self.startBalePlace.count >= 4 then
          BaleLoader.rotatePlatform(self)
        end
      end
    end
  end
  self.fillLevel = numBales
  return BaseMission.VEHICLE_LOAD_OK
end
function BaleLoader:getSaveAttributesAndNodes(nodeIdent)
  local attributes = ""
  local nodes = ""
  local baleNum = 0
  for i, balePlace in pairs(self.balePlaces) do
    if balePlace.bales ~= nil then
      for _, bale in pairs(balePlace.bales) do
        local node = bale.node
        local x, y, z = getTranslation(node)
        local rx, ry, rz = getRotation(node)
        local childIndex = 0
        if bale.childIndex ~= nil then
          childIndex = bale.childIndex
        end
        if 0 < baleNum then
          nodes = nodes .. "\n"
        end
        nodes = nodes .. nodeIdent .. "<bale filename=\"" .. Utils.encodeToHTML(bale.i3dFilename) .. "\" position=\"" .. x .. " " .. y .. " " .. z .. "\" rotation=\"" .. rx .. " " .. ry .. " " .. rz .. "\" childIndex=\"" .. childIndex .. "\" balePlace=\"" .. i .. "\" />"
        baleNum = baleNum + 1
      end
    end
  end
  for i, bale in ipairs(self.startBalePlace.bales) do
    local childIndex = 0
    if bale.childIndex ~= nil then
      childIndex = bale.childIndex
    end
    if 0 < baleNum then
      nodes = nodes .. "\n"
    end
    nodes = nodes .. nodeIdent .. "<bale filename=\"" .. Utils.encodeToHTML(bale.i3dFilename) .. "\" childIndex=\"" .. childIndex .. "\" balePlace=\"0\" helper=\"" .. i .. "\"/>"
    baleNum = baleNum + 1
  end
  return attributes, nodes
end
function BaleLoader:rotatePlatform()
  self.rotatePlatformDirection = 1
  self:playAnimation("rotatePlatform", 1)
  if self.startBalePlace.count > 0 then
    self:playAnimation("rotatePlatformMoveBales" .. self.startBalePlace.count, 1)
  end
  if 1 < self.currentBalePlace then
    self:playAnimation("moveBalePlaces", 1, (self.currentBalePlace - 2) / (table.getn(self.balePlaces) - 1))
    self:setAnimationStopTime("moveBalePlaces", (self.currentBalePlace - 1) / (table.getn(self.balePlaces) - 1))
  end
end
function BaleLoader:moveToWorkPosition()
  self:playAnimation("baleGrabberTransportToWork", 1, Utils.clamp(self:getAnimationTime("baleGrabberTransportToWork"), 0, 1))
  self:playAnimation("closeGrippers", -1, Utils.clamp(self:getAnimationTime("closeGrippers"), 0, 1))
  if self.startBalePlace.count == 1 then
    self:playAnimation("bale1ToOtherSide", -0.5)
  elseif self.startBalePlace.count == 3 then
    self:playAnimation("bale3ToOtherSide", -0.5)
  end
end
function BaleLoader:moveToTransportPosition()
  self:playAnimation("baleGrabberTransportToWork", -1, Utils.clamp(self:getAnimationTime("baleGrabberTransportToWork"), 0, 1))
  self:playAnimation("closeGrippers", 1, Utils.clamp(self:getAnimationTime("closeGrippers"), 0, 1))
  if self.startBalePlace.count == 1 then
    self:playAnimation("bale1ToOtherSide", 0.5)
  elseif self.startBalePlace.count == 3 then
    self:playAnimation("bale3ToOtherSide", 0.5)
  end
end

MissionStacking = {}
local MissionStacking_mt = Class(MissionStacking, BaseMission)
function MissionStacking:new()
  local instance = MissionStacking:superClass():new(MissionStacking_mt)
  instance.playerStartX = 4.35
  instance.playerStartY = -0.8
  instance.playerStartZ = -868
  instance.playerRotX = 0
  instance.playerRotY = Utils.degToRad(-213.5)
  instance.state = BaseMission.STATE_INTRO
  instance.animTracksReset = false
  instance.palletsCount = 1
  instance.frameCount = 0
  instance.missionTriggers = {}
  return instance
end
function MissionStacking:delete()
  for k, triggerId in pairs(self.missionTriggers) do
    if triggerId ~= nil then
      removeTrigger(triggerId)
    end
  end
  MissionStacking:superClass().delete(self)
end
function MissionStacking:load()
  self.environment = Environment:new("data/sky/sky_mission_race1.i3d", false, 12)
  self.environment.timeScale = 1
  MissionStacking:superClass().loadMap(self, "map01")
  self.missionMap = MissionStacking:superClass().loadMissionMap(self, "mission_stacking/mission_stacking.i3d")
  setFog("exp", 0.0027, 1, 0.47058823529411764, 0.5254901960784314, 0.5882352941176471)
  local triggerId = getChild(self.missionMap, "stackTrigger")
  if triggerId ~= 0 then
    addTrigger(triggerId, "triggerCallback", self)
    table.insert(self.missionTriggers, triggerId)
  end
  self.pallets = {}
  local palletsParentId = getChild(self.missionMap, "pallets")
  if palletsParentId ~= 0 then
    local numChildren = getNumOfChildren(palletsParentId)
    for i = 0, numChildren - 1 do
      local id = getChildAt(palletsParentId, i)
      self.pallets[id] = {}
      self.pallets[id].inTriggerCount = 0
    end
  end
  self.frontloader = self:loadVehicle("data/vehicles/steerable/fendt/fendt614_frontloader.xml", -1.24968, 1, -861.51398, Utils.degToRad(-78))
  self:loadVehicle("data/vehicles/tools/extraWeight02.xml", 3.41345, 1, -862.52063, Utils.degToRad(-78))
  self:loadVehicle("data/vehicles/tools/frontloaderPalletfork.xml", -7.05178, 0.3, -860.24695, Utils.degToRad(102))
  self.frontloader.motor.forwardGearRatios[1] = self.frontloader.motor.forwardGearRatios[1] / 1.5
  self.frontloader.motor.forwardGearRatios[2] = self.frontloader.motor.forwardGearRatios[2] / 1.5
  self.frontloader.motor.forwardGearRatios[3] = self.frontloader.motor.forwardGearRatios[3] / 1.5
  self.frontloader.motor.backwardGearRatio = self.frontloader.motor.backwardGearRatio / 1.6
  local charSet = self.frontloader.frontloaderJointDesc.animCharSet1
  if charSet ~= 0 then
    enableAnimTrack(charSet, 0)
    setAnimTrackTime(charSet, 0, 0.858 * getAnimClipDuration(charSet, 0))
  end
  charSet = self.frontloader.frontloaderJointDesc.animCharSet2
  if charSet ~= 0 then
    enableAnimTrack(charSet, 0)
    setAnimTrackTime(charSet, 0, 0.67 * getAnimClipDuration(charSet, 0))
  end
  g_currentMission.missionStats.showPDA = false
  MissionStacking:superClass().load(self)
  self.minTime = 240000
  setRotation(self.environment.sunLightId, Utils.degToRad(115), Utils.degToRad(-18), Utils.degToRad(-170))
  self.showHudMissionBase = true
end
function MissionStacking:mouseEvent(posX, posY, isDown, isUp, button)
  MissionStacking:superClass().mouseEvent(self, posX, posY, isDown, isUp, button)
end
function MissionStacking:keyEvent(unicode, sym, modifier, isDown)
  local controlPlayer = not self.controlPlayer
  RaceMission:superClass().keyEvent(self, unicode, sym, modifier, isDown)
  if self.state == BaseMission.STATE_INTRO and controlPlayer and not self.controlPlayer then
    self.state = BaseMission.STATE_RUNNING
  end
end
function MissionStacking:update(dt)
  MissionStacking:superClass().update(self, dt)
  if self.isRunning then
    if not animTracksReset then
      local charSets = {
        self.frontloader.frontloaderJointDesc.animCharSet1,
        self.frontloader.frontloaderJointDesc.animCharSet2
      }
      for i = 1, 2 do
        local charSet = charSets[i]
        if charSet ~= 0 then
          disableAnimTrack(charSet, 0)
        end
      end
      animTracksReset = true
    end
    if self.state == BaseMission.STATE_RUNNING then
      self.missionTime = self.missionTime + dt
      self.frameCount = self.frameCount + 1
      if self.frameCount > 30 then
        self.frameCount = 0
        self.palletsCount = 0
        for k, v in pairs(self.pallets) do
          if 0 < v.inTriggerCount then
            self.palletsCount = self.palletsCount + 1
          end
        end
        if self.missionTime > self.minTime then
          if self.state ~= BaseMission.STATE_FINISHED and self.palletsCount >= self.bronzeTime then
            self.state = BaseMission.STATE_FINISHED
            self.endTime = self.missionTime
            self.endTimeStamp = self.time + self.endDelayTime
            self:finishMission(self.palletsCount)
          end
          if self.state ~= BaseMission.STATE_FAILED and self.palletsCount < self.bronzeTime then
            self.state = BaseMission.STATE_FAILED
            self.endTime = self.missionTime
            self.endTimeStamp = self.time + self.endDelayTime
          end
        end
      end
    end
    if (self.state == BaseMission.STATE_FINISHED or self.state == BaseMission.STATE_FAILED) and self.endTimeStamp < self.time then
      OnInGameMenuMenu()
    end
  end
end
function MissionStacking:draw()
  MissionStacking:superClass().draw(self)
  if self.isRunning then
    local time = self.minTime - self.missionTime
    if time < 60000 then
      setTextColor(1, time / 60000, time / 60000, 1)
      if time < 0 then
        time = 0
      end
    end
    MissionStacking:superClass().drawTime(self, true, time / 60000)
    setTextColor(1, 1, 1, 1)
    setTextBold(true)
    renderText(self.hudMissionBasePosX + 0.005, 0.926, 0.04, g_i18n:getText("palletsMissionGoal") .. string.format(" %d", self.palletsCount))
    setTextBold(false)
    if self.state == BaseMission.STATE_FINISHED then
      self:drawMissionCompleted()
    end
    if self.state == BaseMission.STATE_FAILED then
      MissionStacking:superClass().drawMissionFailed(self)
    end
  end
end
function MissionStacking:triggerCallback(triggerId, otherId, onEnter, onLeave, onStay)
  local obj = self.pallets[otherId]
  if obj ~= nil then
    if onEnter then
      obj.inTriggerCount = obj.inTriggerCount + 1
    elseif onLeave then
      obj.inTriggerCount = obj.inTriggerCount - 1
    end
  end
end
function MissionStacking:drawMissionCompleted()
  if self.missionFailedOverlayId == nil then
    self.missionCompletedOverlayId = createOverlay("mission_completed", "dataS/missions/mission_completed" .. g_languageSuffix .. ".png")
  end
  renderOverlay(self.missionCompletedOverlayId, self.completeDisplayX, self.completeDisplayY, self.completeDisplayWidth, self.completeDisplayHeight)
  if self.medalOverlay ~= nil then
    self.medalOverlay:render()
  end
  local timePosX = self.completeDisplayX + self.completeDisplayWidth * 0.275
  local timePosY = self.completeDisplayY + self.completeDisplayHeight * 0.25
  setTextAlignment(RenderText.ALIGN_CENTER)
  setTextBold(true)
  renderText(0.5, timePosY, 0.045, g_i18n:getText("stackSize") .. self.palletsCount)
  setTextBold(false)
  setTextAlignment(RenderText.ALIGN_LEFT)
end
function MissionStacking:finishMission(record)
  if g_finishedMissions[self.missionId] == nil then
    g_finishedMissions[self.missionId] = 1
  end
  if g_finishedMissionsRecord[self.missionId] == nil or record > g_finishedMissionsRecord[self.missionId] then
    g_finishedMissionsRecord[self.missionId] = record
  end
  local finishedStr = ""
  local recordStr = ""
  for k, v in pairs(g_finishedMissions) do
    finishedStr = finishedStr .. k .. " "
    recordStr = recordStr .. math.floor(g_finishedMissionsRecord[k]) .. " "
  end
  setXMLString(g_savegameXML, "savegames.missions#finished", finishedStr)
  setXMLString(g_savegameXML, "savegames.missions#record", recordStr)
  saveXMLFile(g_savegameXML)
  local medalPosX = self.completeDisplayX + self.completeDisplayWidth * 0.295
  local medalPosY = self.completeDisplayY + self.completeDisplayHeight * 0.38
  local medalHeight = 0.204
  self.record = record
  local filename = "dataS/missions/empty_medal.png"
  if record >= self.bronzeTime then
    filename = "dataS/missions/bronze_medal.png"
  end
  if record >= self.silverTime then
    filename = "dataS/missions/silver_medal.png"
  end
  if record >= self.goldTime then
    filename = "dataS/missions/gold_medal.png"
  end
  self.medalOverlay = Overlay:new("emptyMedalOverlay", filename, medalPosX, medalPosY, medalHeight * 0.75, medalHeight)
end

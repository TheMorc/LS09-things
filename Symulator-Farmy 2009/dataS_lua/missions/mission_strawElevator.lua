MissionStrawElevator = {}
local MissionStrawElevator_mt = Class(MissionStrawElevator, BaseMission)
function MissionStrawElevator:new()
  local instance = MissionStrawElevator:superClass():new(MissionStrawElevator_mt)
  instance.playerStartX = 164
  instance.playerStartY = 0.1
  instance.playerStartZ = 153.9
  instance.playerRotX = 0
  instance.playerRotY = Utils.degToRad(-61)
  instance.state = BaseMission.STATE_INTRO
  instance.animTracksReset = false
  instance.baleCount = 0
  instance.frameCount = 0
  return instance
end
function MissionStrawElevator:delete()
  MissionStrawElevator:superClass().delete(self)
end
function MissionStrawElevator:load()
  self.environment = Environment:new("data/sky/sky_day_night2.i3d", true, 7, true, false)
  self.environment.timeScale = 30
  self.environment:startRain(36000000)
  MissionStrawElevator:superClass().loadMap(self, "map01")
  self.missionMap = MissionStrawElevator:superClass().loadMissionMap(self, "mission_strawElevator/mission_strawElevator.i3d")
  self.frontloader = self:loadVehicle("data/vehicles/steerable/fendt/fendt614_frontloader.xml", 172, 5, 150, Utils.degToRad(270))
  self:loadVehicle("data/vehicles/tools/frontloaderBalefork.xml", 167, 5, 150, Utils.degToRad(90))
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
  MissionStrawElevator:superClass().load(self)
  self.minTime = 420000
  self.showHudMissionBase = true
end
function MissionStrawElevator:mouseEvent(posX, posY, isDown, isUp, button)
  MissionStrawElevator:superClass().mouseEvent(self, posX, posY, isDown, isUp, button)
end
function MissionStrawElevator:keyEvent(unicode, sym, modifier, isDown)
  local controlPlayer = not self.controlPlayer
  RaceMission:superClass().keyEvent(self, unicode, sym, modifier, isDown)
  if self.state == BaseMission.STATE_INTRO and controlPlayer and not self.controlPlayer then
    self.state = BaseMission.STATE_RUNNING
  end
end
function MissionStrawElevator:update(dt)
  MissionStrawElevator:superClass().update(self, dt)
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
        if self.missionTime > self.minTime or self.baleCount == self.goldTime then
          if self.state ~= BaseMission.STATE_FINISHED and self.baleCount >= self.bronzeTime or self.baleCount == self.goldTime then
            self.state = BaseMission.STATE_FINISHED
            self.endTime = self.missionTime
            self.endTimeStamp = self.time + self.endDelayTime
            self:finishMission(self.baleCount)
          end
          if self.state ~= BaseMission.STATE_FAILED and self.baleCount < self.bronzeTime then
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
function MissionStrawElevator:draw()
  MissionStrawElevator:superClass().draw(self)
  if self.isRunning then
    local time = self.minTime - self.missionTime
    if time < 60000 then
      setTextColor(1, time / 60000, time / 60000, 1)
      if time < 0 then
        time = 0
      end
    end
    MissionStrawElevator:superClass().drawTime(self, true, time / 60000)
    setTextColor(1, 1, 1, 1)
    setTextBold(true)
    renderText(self.hudMissionBasePosX + 0.005, 0.926, 0.04, g_i18n:getText("strawElevatorMissionGoal") .. string.format(" %d", self.baleCount))
    setTextBold(false)
    if self.state == BaseMission.STATE_FINISHED then
      self:drawMissionCompleted()
    end
    if self.state == BaseMission.STATE_FAILED then
      MissionStrawElevator:superClass().drawMissionFailed(self)
    end
  end
end
function MissionStrawElevator:drawMissionCompleted()
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
  renderText(0.5, timePosY, 0.045, g_i18n:getText("strawElevatorMissionGoal") .. self.baleCount)
  setTextBold(false)
  setTextAlignment(RenderText.ALIGN_LEFT)
end
function MissionStrawElevator:finishMission(record)
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

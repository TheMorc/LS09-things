HotspotMission = {}
local HotspotMission_mt = Class(HotspotMission, BaseMission)
function HotspotMission:new(customMt)
  local instance = HotspotMission:superClass():new(customMt)
  instance.touchedATrigger = false
  instance.timeAttack = true
  instance.touchedTriggerCount = 0
  return instance
end
function HotspotMission:delete()
  self.inGameMessage:delete()
  HotspotMission:superClass().delete(self)
end
function HotspotMission:load()
  HotspotMission:superClass().load(self)
  self.finishEndTriggerIndex = self.numTriggers
  self.state = HotspotMission.STATE_INTRO
  self.showHudMissionBase = true
  self.inGameMessage = InGameMessage:new()
end
function HotspotMission:mouseEvent(posX, posY, isDown, isUp, button)
  self.inGameMessage:mouseEvent(posX, posY, isDown, isUp, button)
  HotspotMission:superClass().mouseEvent(self, posX, posY, isDown, isUp, button)
end
function HotspotMission:keyEvent(unicode, sym, modifier, isDown)
  local controlPlayer = not self.controlPlayer
  HotspotMission:superClass().keyEvent(self, unicode, sym, modifier, isDown)
end
function HotspotMission:update(dt)
  HotspotMission:superClass().update(self, dt)
  self.inGameMessage:update(dt)
  if self.state == BaseMission.STATE_INTRO and self.touchedATrigger then
    self.state = BaseMission.STATE_RUNNING
  end
  if self.isRunning then
    if self.state == BaseMission.STATE_RUNNING then
      self.missionTime = self.missionTime + dt
      if self.sunk or self.missionTime > self.minTime then
        self.state = BaseMission.STATE_FAILED
        self.endTime = self.missionTime
        self.endTimeStamp = self.time + self.endDelayTime
      elseif self.touchedTriggerCount == self.numTriggers then
        self.state = BaseMission.STATE_FINISHED
        self.endTime = self.missionTime
        self.endTimeStamp = self.time + self.endDelayTime
        HotspotMission:superClass().finishMission(self, self.endTime)
      end
    end
    if (self.state == BaseMission.STATE_FINISHED or self.state == BaseMission.STATE_FAILED) and self.endTimeStamp < self.time then
      OnInGameMenuMenu()
    end
  end
end
function HotspotMission:draw()
  HotspotMission:superClass().draw(self)
  if self.isRunning then
    if self.timeAttack then
      local time = self.minTime - self.missionTime
      if time < 10000 then
        setTextColor(1, 0, 0, 1)
        if time < 0 then
          time = 0
        end
      end
      HotspotMission:superClass().drawTime(self, true, time / 60000)
      setTextColor(1, 1, 1, 1)
    end
    setTextColor(1, 1, 1, 1)
    setTextBold(true)
    renderText(self.hudMissionBasePosX + 0.005, 0.926, 0.035, g_i18n:getText("hotspotMissionGoal") .. tostring(self.numTriggers - self.touchedTriggerCount))
    setTextBold(false)
    if self.state == BaseMission.STATE_FINISHED then
      HotspotMission:superClass().drawMissionCompleted(self)
    end
    if self.state == BaseMission.STATE_FAILED then
      HotspotMission:superClass().drawMissionFailed(self)
    end
    self.inGameMessage:draw()
  end
end
function HotspotMission:hotspotTouched(triggerId)
  self.touchedATrigger = true
  self.touchedTriggerCount = self.touchedTriggerCount + 1
  if self.touchedTriggerCount < self.numTriggers then
    self:showMessage(triggerId)
  end
end

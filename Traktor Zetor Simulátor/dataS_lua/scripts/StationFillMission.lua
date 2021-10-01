StationFillMission = {}
local StationFillMission_mt = Class(StationFillMission, BaseMission)
function StationFillMission:new(customMt)
  local instance = StationFillMission:superClass():new(customMt)
  instance.savedGrain = 0
  instance.renderTime2 = true
  return instance
end
function StationFillMission:delete()
  StationFillMission:superClass().delete(self)
end
function StationFillMission:load()
  StationFillMission:superClass().load(self)
  self.showHudMissionBase = true
end
function StationFillMission:mouseEvent(posX, posY, isDown, isUp, button)
  StationFillMission:superClass().mouseEvent(self, posX, posY, isDown, isUp, button)
end
function StationFillMission:keyEvent(unicode, sym, modifier, isDown)
  StationFillMission:superClass().keyEvent(self, unicode, sym, modifier, isDown)
end
function StationFillMission:update(dt)
  StationFillMission:superClass().update(self, dt)
  if self.isRunning then
    if not self.controlPlayer and self.controlledVehicle ~= nil and self.controlledVehicle.attachedTrailer ~= nil then
      local trailer = self.controlledVehicle.attachedTrailer
      if (trailer.tipState == Trailer.TIPSTATE_OPENING or trailer.tipState == Trailer.TIPSTATE_OPEN) and trailer.lastFillDelta < 0 then
        self.savedGrain = self.savedGrain - trailer.lastFillDelta
      end
    end
    if self.savedGrain > self.gainGoal then
      self.savedGrain = self.gainGoal
      self.state = BaseMission.STATE_FINISHED
      self.endTime = self.time
      self.endTimeStamp = self.time + self.endDelayTime
      StationFillMission:superClass().finishMission(self, self.endTime)
    end
    if self.state == BaseMission.STATE_RUNNING and self.sunk then
      self.state = BaseMission.STATE_FAILED
      self.endTime = self.time
      self.endTimeStamp = self.time + self.endDelayTime
    end
    if (self.state == BaseMission.STATE_FINISHED or self.state == BaseMission.STATE_FAILED) and self.endTimeStamp < self.time then
      OnInGameMenuMenu()
    end
  end
end
function StationFillMission:draw()
  StationFillMission:superClass().draw(self)
  if self.isRunning then
    local left = self.gainGoal - self.savedGrain
    if 0 < left then
      setTextBold(true)
      renderText(0.05, 0.93, 0.035, string.format(g_i18n:getText("missionStationFill") .. ": %.0f ", left))
      setTextBold(false)
    end
    if self.renderTime2 then
      StationFillMission:superClass().drawTime(self, true, self.time / 60000)
    end
    if self.state == BaseMission.STATE_FINISHED then
      StationFillMission:superClass().drawMissionCompleted(self)
    end
    if self.state == BaseMission.STATE_FAILED then
      StationFillMission:superClass().drawMissionFailed(self)
    end
  end
end

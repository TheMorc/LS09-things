FieldMission = {}
local FieldMission_mt = Class(FieldMission, BaseMission)
function FieldMission:new(customMt)
  local instance = FieldMission:superClass().new(self, customMt)
  instance.densityId = 0
  instance.densityRegions = {}
  instance.startDensity = 0
  instance.targetDensity = 100000
  instance.currentDensity = 0
  instance.isLowerLimit = false
  instance.numRegionsPerFrame = 1
  instance.densityChannel = 0
  instance.timeAttack = false
  instance.renderTimeAttackCountdown = true
  instance.minTime = 0
  instance.endTime = 0
  instance.state = BaseMission.STATE_INTRO
  instance.currentDensityIndex = 1
  return instance
end
function FieldMission:delete()
  FieldMission:superClass().delete(self)
end
function FieldMission:load()
  FieldMission:superClass().load(self)
  self.state = BaseMission.STATE_INTRO
  self.showHudMissionBase = true
end
function FieldMission:mouseEvent(posX, posY, isDown, isUp, button)
  FieldMission:superClass().mouseEvent(self, posX, posY, isDown, isUp, button)
end
function FieldMission:keyEvent(unicode, sym, modifier, isDown)
  FieldMission:superClass().keyEvent(self, unicode, sym, modifier, isDown)
  if self.state == BaseMission.STATE_INTRO and not self.controlPlayer then
    self.state = BaseMission.STATE_RUNNING
  end
end
function FieldMission:update(dt)
  FieldMission:superClass().update(self, dt)
  if self.isRunning then
    self:updateDensity()
    if self.state == BaseMission.STATE_RUNNING then
      self.missionTime = self.missionTime + dt
      if self.timeAttack and self.missionTime > self.minTime then
        self.state = BaseMission.STATE_FAILED
        self.endTime = self.time
        self.endTimeStamp = self.time + self.endDelayTime
      elseif self.isLowerLimit and self.currentDensity < self.targetDensity or not self.isLowerLimit and self.currentDensity > self.targetDensity then
        self.state = BaseMission.STATE_FINISHED
        self.endTime = self.time
        self.endTimeStamp = self.time + self.endDelayTime
        FieldMission:superClass().finishMission(self, self.endTime)
      end
    end
  end
  if (self.state == BaseMission.STATE_FINISHED or self.state == BaseMission.STATE_FAILED) and self.endTimeStamp < self.time then
    OnInGameMenuMenu()
  end
end
function FieldMission:draw()
  FieldMission:superClass().draw(self)
  if self.isRunning then
    if self.timeAttack and self.renderTimeAttackCountdown then
      local time = self.minTime - self.missionTime
      if time < 10000 then
        setTextColor(1, 0, 0, 1)
        if time < 0 then
          time = 0
        end
      else
        setTextColor(1, 1, 1, 1)
      end
      StationFillMission:superClass().drawTime(self, true, time / 60000)
    end
    setTextColor(1, 1, 1, 1)
    local percent
    if self.isLowerLimit then
      percent = 1 - math.max(math.min((self.currentDensity - self.targetDensity) / (self.startDensity - self.targetDensity), 1), 0)
    else
      percent = math.min(self.currentDensity / (self.targetDensity - self.startDensity), 1)
    end
    setTextBold(true)
    renderText(self.hudMissionBasePosX + 0.005, 0.926, 0.032, string.format(g_i18n:getText("fieldMissionGoal"), percent * 100))
    setTextBold(false)
    if self.state == BaseMission.STATE_FINISHED then
      FieldMission:superClass().drawMissionCompleted(self)
    end
    if self.state == BaseMission.STATE_FAILED then
      FieldMission:superClass().drawMissionFailed(self)
    end
  end
end
function FieldMission:updateDensity()
  if self.densityId ~= 0 then
    for i = 1, self.numRegionsPerFrame do
      local densityRegion = self.densityRegions[self.currentDensityIndex]
      local density
      if densityRegion.worldSpace then
        density = getDensityRegionWorld(self.densityId, densityRegion.x, densityRegion.y, densityRegion.width, densityRegion.height, self.densityChannel, 1)
      else
        density = getDensityRegion(self.densityId, densityRegion.x, densityRegion.y, densityRegion.width, densityRegion.height, self.densityChannel, 1)
      end
      self.currentDensity = self.currentDensity + (density - densityRegion.lastDensity)
      densityRegion.lastDensity = density
      self.currentDensityIndex = self.currentDensityIndex + 1
      if self.currentDensityIndex > table.getn(self.densityRegions) then
        self.currentDensityIndex = 1
      end
    end
  end
end
function FieldMission:getDensity(id, channel)
  local densitySum = 0
  for i = 1, table.getn(self.densityRegions) do
    local densityRegion = self.densityRegions[i]
    local density
    if densityRegion.worldSpace then
      density = getDensityRegionWorld(id, densityRegion.x, densityRegion.y, densityRegion.width, densityRegion.height, channel, 1)
    else
      density = getDensityRegion(id, densityRegion.x, densityRegion.y, densityRegion.width, densityRegion.height, channel, 1)
    end
    densitySum = densitySum + density
  end
  return densitySum
end
function FieldMission:addDensityRegion(x, y, width, height, worldSpace)
  table.insert(self.densityRegions, {
    x = x,
    y = y,
    width = width,
    height = height,
    worldSpace = worldSpace,
    lastDensity = 0
  })
end

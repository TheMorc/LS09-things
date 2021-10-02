MissionRocks = {}
local MissionRocks_mt = Class(MissionRocks, BaseMission)
function MissionRocks:new()
  local instance = MissionRocks:superClass():new(MissionRocks_mt)
  instance.playerStartX = -692.8
  instance.playerStartY = 0.1
  instance.playerStartZ = -40.9
  instance.playerRotX = 0
  instance.playerRotY = Utils.degToRad(-47)
  instance.rocksCount = 0
  instance.rockHotspots = {}
  instance.missionTriggers = {}
  instance.frameCount = 0
  instance.state = BaseMission.STATE_RUNNING
  return instance
end
function MissionRocks:delete()
  for k, triggerId in pairs(self.missionTriggers) do
    if triggerId ~= nil then
      removeTrigger(triggerId)
    end
  end
  MissionRocks:superClass().delete(self)
end
function MissionRocks:load()
  self.environment = Environment:new("data/sky/sky_foggy.i3d", false, 12)
  self.environment.timeScale = 1
  MissionRocks:superClass().loadMap(self, "map01")
  self.missionMap = MissionRocks:superClass().loadMissionMap(self, "mission_rocks/mission_rocks.i3d")
  setFog("exp", 0.03, 1, 0.6509803921568628, 0.6705882352941176, 0.6745098039215687)
  setLightDiffuseColor(self.environment.sunLightId, 0.6509803921568628, 0.6705882352941176, 0.6745098039215687)
  setLightSpecularColor(self.environment.sunLightId, 0.6509803921568628, 0.6705882352941176, 0.6745098039215687)
  local triggerParentId = getChild(self.missionMap, "mission_rocks_triggers")
  if triggerParentId ~= 0 then
    local numChildren = getNumOfChildren(triggerParentId)
    for i = 0, numChildren - 1 do
      local id = getChildAt(triggerParentId, i)
      addTrigger(id, "triggerCallback", self)
      table.insert(self.missionTriggers, id)
    end
  end
  self.rocks = {}
  local rocksParentId = getChild(self.missionMap, "FieldRocks")
  if rocksParentId ~= 0 then
    local numChildren = getNumOfChildren(rocksParentId)
    for i = 0, numChildren - 1 do
      local id = getChildAt(rocksParentId, i)
      if g_currentMission ~= nil then
        local x, y, z = getTranslation(id)
        g_currentMission.missionStats:createMapHotspot(tostring(id), "dataS/missions/hud_pda_spot_rock.png", x + 1024, z + 1024, g_currentMission.missionStats.pdaMapArrowSize * 0.6, g_currentMission.missionStats.pdaMapArrowSize * 0.6 * 1.3333333333333333, false, false, id)
      end
      self.rocks[id] = {}
      self.rocks[id].inTriggerCount = 0
    end
  end
  self:loadVehicle("data/vehicles/steerable/fendt/fendt936BBvario.xml", -684.8, 5, -46, Utils.degToRad(160))
  self:loadVehicle("data/vehicles/tools/plow01.xml", -682.6, 5, -51.6, Utils.degToRad(-20))
  MissionRocks:superClass().load(self)
  g_currentMission.missionStats.showPDA = false
  self.showHudMissionBase = true
end
function MissionRocks:mouseEvent(posX, posY, isDown, isUp, button)
  MissionRocks:superClass().mouseEvent(self, posX, posY, isDown, isUp, button)
end
function MissionRocks:keyEvent(unicode, sym, modifier, isDown)
  MissionRocks:superClass().keyEvent(self, unicode, sym, modifier, isDown)
end
function MissionRocks:update(dt)
  MissionRocks:superClass().update(self, dt)
  if self.isRunning then
    if self.state == BaseMission.STATE_RUNNING then
      self.missionTime = self.missionTime + dt
      self.frameCount = self.frameCount + 1
      if self.frameCount > 10 then
        self.rocksCount = 0
        for k, v in pairs(self.rocks) do
          if 0 < v.inTriggerCount then
            self.rocksCount = self.rocksCount + 1
          end
        end
        if self.state ~= BaseMission.STATE_FINISHED and self.rocksCount == 0 then
          self.state = BaseMission.STATE_FINISHED
          self.endTime = self.missionTime
          self.endTimeStamp = self.time + self.endDelayTime
          MissionRocks:superClass().finishMission(self, self.endTime)
        end
        if self.state ~= BaseMission.STATE_FAILED and self.missionTime > self.minTime then
          self.state = BaseMission.STATE_FAILED
          self.endTime = self.missionTime
          self.endTimeStamp = self.time + self.endDelayTime
        end
      end
    end
    if (self.state == BaseMission.STATE_FINISHED or self.state == BaseMission.STATE_FAILED) and self.endTimeStamp < self.time then
      OnInGameMenuMenu()
    end
  end
end
function MissionRocks:draw()
  MissionRocks:superClass().draw(self)
  if self.isRunning then
    local time = self.minTime - self.missionTime
    if time < 60000 then
      setTextColor(1, 0, 0, 1)
      if time < 0 then
        time = 0
      end
    end
    MissionRocks:superClass().drawTime(self, true, time / 60000)
    setTextColor(1, 1, 1, 1)
    setTextBold(true)
    renderText(self.hudMissionBasePosX + 0.005, 0.926, 0.03, g_i18n:getText("rocksMissionGoal") .. string.format(" %d", self.rocksCount))
    setTextBold(false)
    if self.state == BaseMission.STATE_FINISHED then
      MissionRocks:superClass().drawMissionCompleted(self)
    end
    if self.state == BaseMission.STATE_FAILED then
      MissionRocks:superClass().drawMissionFailed(self)
    end
  end
end
function MissionRocks:triggerCallback(triggerId, otherId, onEnter, onLeave, onStay)
  local obj = self.rocks[otherId]
  if obj ~= nil then
    if onEnter then
      obj.inTriggerCount = obj.inTriggerCount + 1
    elseif onLeave then
      obj.inTriggerCount = obj.inTriggerCount - 1
    end
  end
end

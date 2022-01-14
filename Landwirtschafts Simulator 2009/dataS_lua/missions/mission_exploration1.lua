MissionExploration1 = {}
local MissionExploration1_mt = Class(MissionExploration1, HotspotMission)
function MissionExploration1:new()
  local instance = MissionExploration1:superClass():new(MissionExploration1_mt)
  instance.playerStartX = 182
  instance.playerStartY = -0.8
  instance.playerStartZ = 115
  instance.playerRotX = 0
  instance.playerRotY = 0
  instance.numTriggers = 12
  instance.triggerShapeCount = 1
  instance.triggerPrefix = "mission_exploration1_trigger"
  instance.messages = {}
  local xmlFile = loadXMLFile("messages.xml", "dataS/missions/messages_exploration1" .. g_languageSuffix .. ".xml")
  local eom = false
  local i = 0
  repeat
    local message = {}
    local baseXMLName = string.format("messages.message(%d)", i)
    message.id = getXMLInt(xmlFile, baseXMLName .. "#id")
    if message.id ~= nil then
      message.title = getXMLString(xmlFile, baseXMLName .. ".title")
      message.content = getXMLString(xmlFile, baseXMLName .. ".content")
      message.duration = getXMLInt(xmlFile, baseXMLName .. ".duration")
      instance.messages[message.id] = message
    else
      eom = true
    end
    i = i + 1
  until eom
  delete(xmlFile)
  return instance
end
function MissionExploration1:delete()
  if self.hotspotSound ~= nil then
    delete(self.hotspotSound)
  end
  MissionExploration1:superClass().delete(self)
end
function MissionExploration1:load()
  self.environment = Environment:new("data/sky/sky_mission_race1.i3d", false, 15)
  self.environment.timeScale = 1
  MissionExploration1:superClass().loadMap(self, "map01")
  self.missionMap = MissionExploration1:superClass().loadMissionMap(self, "mission_exploration1/mission_exploration1.i3d")
  setFog("exp2", 0.0025, 1, 0.47058823529411764, 0.5254901960784314, 0.5882352941176471)
  self:loadVehicle("data/vehicles/steerable/fendt/fendt936BBvario.xml", 185, 12, 105, Utils.degToRad(180))
  self.hotspotSound = createSample("hotspotSound")
  loadSample(self.hotspotSound, "data/maps/sounds/hotspotSound.wav", false)
  g_currentMission.missionStats.showPDA = false
  MissionExploration1:superClass().load(self)
end
function MissionExploration1:mouseEvent(posX, posY, isDown, isUp, button)
  MissionExploration1:superClass().mouseEvent(self, posX, posY, isDown, isUp, button)
end
function MissionExploration1:keyEvent(unicode, sym, modifier, isDown)
  MissionExploration1:superClass().keyEvent(self, unicode, sym, modifier, isDown)
end
function MissionExploration1:update(dt)
  MissionExploration1:superClass().update(self, dt)
end
function MissionExploration1:draw()
  MissionExploration1:superClass().draw(self)
end
function MissionExploration1:showMessage(triggerId)
  local triggerName = getName(triggerId)
  local triggerNumber = tonumber(string.sub(triggerName, string.len(triggerName) - 1))
  if self.messages[triggerNumber] ~= nil then
    self.inGameMessage:showMessage(self.messages[triggerNumber].title, self.messages[triggerNumber].content, self.messages[triggerNumber].duration, false)
  end
end

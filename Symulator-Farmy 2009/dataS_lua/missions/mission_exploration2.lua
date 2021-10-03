MissionExploration2 = {}
local MissionExploration2_mt = Class(MissionExploration2, HotspotMission)
function MissionExploration2:new()
  local instance = MissionExploration2:superClass():new(MissionExploration2_mt)
  instance.playerStartX = 556.3
  instance.playerStartY = 16.7
  instance.playerStartZ = -218.3
  instance.playerRotX = Utils.degToRad(10)
  instance.playerRotY = Utils.degToRad(222.2)
  instance.numTriggers = 12
  instance.triggerShapeCount = 1
  instance.triggerPrefix = "mission_exploration2_trigger"
  instance.messages = {}
  local xmlFile = loadXMLFile("messages.xml", "dataS/missions/messages_exploration2" .. g_languageSuffix .. ".xml")
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
function MissionExploration2:delete()
  if self.hotspotSound ~= nil then
    delete(self.hotspotSound)
  end
  MissionExploration2:superClass().delete(self)
end
function MissionExploration2:load()
  self.environment = Environment:new("data/sky/sky_mission_exploration2.i3d", false, 8)
  self.environment.timeScale = 1
  MissionExploration2:superClass().loadMap(self, "map01")
  self.missionMap = MissionExploration2:superClass().loadMissionMap(self, "mission_exploration2/mission_exploration2.i3d")
  setFog("exp", 0.0055, 1, 0.058823529411764705, 0.07058823529411765, 0.09803921568627451)
  setLightDiffuseColor(self.environment.sunLightId, 0.5882352941176471, 0.5098039215686274, 0.6666666666666666)
  setLightSpecularColor(self.environment.sunLightId, 0.5882352941176471, 0.5098039215686274, 0.6666666666666666)
  setRotation(self.environment.sunLightId, Utils.degToRad(-68.7103), Utils.degToRad(-17.49849), Utils.degToRad(15.70314))
  self:loadVehicle("data/vehicles/steerable/fendt/fendt936BBvario.xml", 562.5, 15, -213, 0)
  self.hotspotSound = createSample("hotspotSound")
  loadSample(self.hotspotSound, "data/maps/sounds/hotspotSound.wav", false)
  g_currentMission.missionStats.showPDA = false
  MissionExploration2:superClass().load(self)
end
function MissionExploration2:mouseEvent(posX, posY, isDown, isUp, button)
  MissionExploration2:superClass().mouseEvent(self, posX, posY, isDown, isUp, button)
end
function MissionExploration2:keyEvent(unicode, sym, modifier, isDown)
  MissionExploration2:superClass().keyEvent(self, unicode, sym, modifier, isDown)
end
function MissionExploration2:update(dt)
  MissionExploration2:superClass().update(self, dt)
end
function MissionExploration2:draw()
  MissionExploration2:superClass().draw(self)
end
function MissionExploration2:showMessage(triggerId)
  local triggerName = getName(triggerId)
  local triggerNumber = tonumber(string.sub(triggerName, string.len(triggerName) - 1))
  if self.messages[triggerNumber] ~= nil then
    self.inGameMessage:showMessage(self.messages[triggerNumber].title, self.messages[triggerNumber].content, self.messages[triggerNumber].duration, false)
  end
end

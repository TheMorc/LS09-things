MissionTutorialSowing = {}
local MissionTutorialSowing_mt = Class(MissionTutorialSowing, FieldMission)
function MissionTutorialSowing:new()
  local instance = MissionTutorialSowing:superClass():new(MissionTutorialSowing_mt)
  instance.state = BaseMission.STATE_INTRO
  instance.playerStartX = -470.2
  instance.playerStartY = 0.1
  instance.playerStartZ = 433.7
  instance.playerRotX = Utils.degToRad(0)
  instance.playerRotY = Utils.degToRad(242)
  instance.messages = {}
  local xmlFile = loadXMLFile("messages.xml", "dataS/missions/messages_tutorial_sowing" .. g_languageSuffix .. ".xml")
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
  instance.showHudEnv = false
  return instance
end
function MissionTutorialSowing:delete()
  self.inGameMessage:delete()
  MissionTutorialSowing:superClass().delete(self)
end
function MissionTutorialSowing:load()
  self.environment = Environment:new("data/sky/sky_mission_dusk1.i3d", false, 16)
  self.environment.timeScale = 1
  MissionTutorialSowing:superClass().loadMap(self, "map01")
  setFog("exp2", 0.0025, 1, 0.2549019607843137, 0.27450980392156865, 0.29411764705882354)
  setRotation(self.environment.sunLightId, Utils.degToRad(-33), Utils.degToRad(-62.5), Utils.degToRad(0))
  setLightDiffuseColor(self.environment.sunLightId, 0.8, 0.7, 0.4)
  setLightSpecularColor(self.environment.sunLightId, 0.8, 0.7, 0.4)
  self.missionMapInfospots = self:superClass().loadMissionMap(self, "mission_tutorial_sowing/mission_tutorial_sowing.i3d")
  self:loadVehicle("data/vehicles/steerable/fendt/fendt936vario.xml", -463, 5, 441, 0)
  local sowingMachine = self:loadVehicle("data/vehicles/tools/vitasemA301.xml", -463, 5, 435, 0)
  sowingMachine:setSeedFruitType(FruitUtil.FRUITTYPE_BARLEY)
  sowingMachine.selectable = false
  self.densityId = self.terrainDetailId
  setDensityMaskedParallelogram(self.densityId, -464.5, 443, 37.5, 0, 0, 57, 1, 1, self.densityId, 2, 1, 1)
  setDensityParallelogram(self.densityId, -464.5, 443, 37.5, 0, 0, 57, 2, 1, 0)
  self.densityChannel = 2
  self.targetDensity = 29000
  self:addDensityRegion(-464, 443, 37, 57, true)
  MissionTutorialSowing:superClass().load(self)
  self.inGameMessage = InGameMessage:new()
end
function MissionTutorialSowing:mouseEvent(posX, posY, isDown, isUp, button)
  self.inGameMessage:mouseEvent(posX, posY, isDown, isUp, button)
  MissionTutorialSowing:superClass().mouseEvent(self, posX, posY, isDown, isUp, button)
end
function MissionTutorialSowing:keyEvent(unicode, sym, modifier, isDown)
  MissionTutorialSowing:superClass().keyEvent(self, unicode, sym, modifier, isDown)
end
function MissionTutorialSowing:update(dt)
  self.inGameMessage:update(dt)
  MissionTutorialSowing:superClass().update(self, dt)
end
function MissionTutorialSowing:draw()
  self.inGameMessage:draw()
  MissionTutorialSowing:superClass().draw(self)
end
function MissionTutorialSowing:infospotTouched(triggerId)
  local triggerName = getName(triggerId)
  local triggerNumber = tonumber(string.sub(triggerName, string.len(triggerName) - 1))
  if self.messages[triggerNumber] ~= nil then
    self.inGameMessage:showMessage(self.messages[triggerNumber].title, self.messages[triggerNumber].content, self.messages[triggerNumber].duration, false)
  end
end

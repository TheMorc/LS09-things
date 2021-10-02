MissionSprinter8ST = {}
local MissionSprinter8ST_mt = Class(MissionSprinter8ST, FieldMission)
function MissionSprinter8ST:new()
  local instance = MissionSprinter8ST:superClass():new(MissionSprinter8ST_mt)
  instance.state = BaseMission.STATE_INTRO
  instance.playerStartX = -180.45
  instance.playerStartY = 0.1
  instance.playerStartZ = 101.8
  instance.playerRotX = Utils.degToRad(0)
  instance.playerRotY = Utils.degToRad(-134)
  instance.messages = {}
  instance.showHudEnv = false
  return instance
end
function MissionSprinter8ST:delete()
  self.inGameMessage:delete()
  MissionSprinter8ST:superClass().delete(self)
end
function MissionSprinter8ST:load()
  self.environment = Environment:new("data/sky/sky_gold2.i3d", false, 16)
  self.environment.timeScale = 1
  MissionSprinter8ST:superClass().loadMap(self, "map01")
  setFog("exp2", 0.0025, 1, 0.30980392156862746, 0.34509803921568627, 0.3843137254901961)
  setRotation(self.environment.sunLightId, Utils.degToRad(120), Utils.degToRad(-40), Utils.degToRad(-155))
  setLightDiffuseColor(self.environment.sunLightId, 0.8, 0.6, 0.3)
  setLightSpecularColor(self.environment.sunLightId, 0.8, 0.6, 0.3)
  setAmbientColor(0.45098039215686275, 0.43137254901960786, 0.43137254901960786)
  self:loadVehicle("data/vehicles/steerable/fendt/fendt936BBvario.xml", -175, 0.5, 109.5, Utils.degToRad(270))
  local sowingMachine = self:loadVehicle("data/vehicles/tools/horsch/sprinter8ST.xml", -168.4, 0.5, 109.5, Utils.degToRad(270))
  sowingMachine:setSeedFruitType(FruitUtil.FRUITTYPE_RAPE)
  self.densityId = self.terrainDetailId
  setDensityMaskedParallelogram(self.densityId, -247, 63, 75, 0, 0, 50, 1, 1, self.densityId, 2, 1, 1)
  setDensityParallelogram(self.densityId, -247, 63, 75, 0, 0, 50, 2, 1, 0)
  self.densityChannel = 2
  self.targetDensity = 52000
  self:addDensityRegion(-247, 63, 75, 50, true)
  MissionSprinter8ST:superClass().load(self)
  self.inGameMessage = InGameMessage:new()
end
function MissionSprinter8ST:mouseEvent(posX, posY, isDown, isUp, button)
  self.inGameMessage:mouseEvent(posX, posY, isDown, isUp, button)
  MissionSprinter8ST:superClass().mouseEvent(self, posX, posY, isDown, isUp, button)
end
function MissionSprinter8ST:keyEvent(unicode, sym, modifier, isDown)
  MissionSprinter8ST:superClass().keyEvent(self, unicode, sym, modifier, isDown)
end
function MissionSprinter8ST:update(dt)
  self.inGameMessage:update(dt)
  MissionSprinter8ST:superClass().update(self, dt)
end
function MissionSprinter8ST:draw()
  self.inGameMessage:draw()
  MissionSprinter8ST:superClass().draw(self)
end
function MissionSprinter8ST:infospotTouched(triggerId)
  local triggerName = getName(triggerId)
  local triggerNumber = tonumber(string.sub(triggerName, string.len(triggerName) - 1))
  if self.messages[triggerNumber] ~= nil then
    self.inGameMessage:showMessage(self.messages[triggerNumber].title, self.messages[triggerNumber].content, self.messages[triggerNumber].duration, false)
  end
end

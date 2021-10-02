MissionJoker6CT = {}
local MissionJoker6CT_mt = Class(MissionJoker6CT, FieldMission)
function MissionJoker6CT:new()
  local instance = MissionJoker6CT:superClass():new(MissionJoker6CT_mt)
  instance.state = BaseMission.STATE_INTRO
  instance.playerStartX = -167.5
  instance.playerStartY = 0.2
  instance.playerStartZ = 103.15
  instance.playerRotX = Utils.degToRad(0)
  instance.playerRotY = Utils.degToRad(143)
  instance.showHudEnv = false
  return instance
end
function MissionJoker6CT:delete()
  MissionJoker6CT:superClass().delete(self)
end
function MissionJoker6CT:load()
  self.environment = Environment:new("data/sky/sky_gold1.i3d", false, 12)
  MissionJoker6CT:superClass().loadMap(self, "map01")
  setFog("exp2", 0.0025, 1, 0.3803921568627451, 0.4196078431372549, 0.4235294117647059)
  setRotation(self.environment.sunLightId, Utils.degToRad(155), Utils.degToRad(-70), Utils.degToRad(165))
  setLightDiffuseColor(self.environment.sunLightId, 0.9, 0.9, 0.8)
  setLightSpecularColor(self.environment.sunLightId, 0.9, 0.9, 0.8)
  setAmbientColor(0.47058823529411764, 0.47058823529411764, 0.49019607843137253)
  self:loadVehicle("data/vehicles/steerable/fendt/fendt936vario.xml", -175, 0.5, 110, Utils.degToRad(270))
  self:loadVehicle("data/vehicles/tools/horsch/joker6CT.xml", -170.7, 0.5, 110, Utils.degToRad(270))
  self.densityId = self.terrainDetailId
  local cuttedWheatId = self.cuttedWheatId
  local cutBarleyId = g_currentMission.fruits[FruitUtil.FRUITTYPE_BARLEY].cutShortId
  setDensityMaskedParallelogram(cutBarleyId, -247, 63, 75, 0, 0, 50, 0, 1, self.terrainDetailId, self.sowingChannel, 1, 1)
  self.densityChannel = self.cultivatorChannel
  self.targetDensity = 52000
  self:addDensityRegion(-247, 63, 75, 50, true)
  MissionJoker6CT:superClass().load(self)
end
function MissionJoker6CT:mouseEvent(posX, posY, isDown, isUp, button)
  MissionJoker6CT:superClass().mouseEvent(self, posX, posY, isDown, isUp, button)
end
function MissionJoker6CT:keyEvent(unicode, sym, modifier, isDown)
  MissionJoker6CT:superClass().keyEvent(self, unicode, sym, modifier, isDown)
end
function MissionJoker6CT:update(dt)
  MissionJoker6CT:superClass().update(self, dt)
end
function MissionJoker6CT:draw()
  MissionJoker6CT:superClass().draw(self)
end

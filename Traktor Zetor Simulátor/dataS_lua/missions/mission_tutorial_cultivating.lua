MissionTutorialCultivating = {}
local MissionTutorialCultivating_mt = Class(MissionTutorialCultivating, FieldMission)
function MissionTutorialCultivating:new()
  local instance = MissionTutorialCultivating:superClass():new(MissionTutorialCultivating_mt)
  instance.state = BaseMission.STATE_INTRO
  instance.playerStartX = -470.3
  instance.playerStartY = 0.2
  instance.playerStartZ = 432
  instance.playerRotX = Utils.degToRad(0)
  instance.playerRotY = Utils.degToRad(240)
  instance.showHudEnv = false
  return instance
end
function MissionTutorialCultivating:delete()
  MissionTutorialCultivating:superClass().delete(self)
end
function MissionTutorialCultivating:load()
  self.environment = Environment:new("data/sky/sky_mission_dusk1.i3d", false, 12)
  MissionTutorialCultivating:superClass().loadMap(self, "map01")
  setFog("exp2", 0.0025, 1, 0.2549019607843137, 0.27450980392156865, 0.29411764705882354)
  setRotation(self.environment.sunLightId, Utils.degToRad(-33), Utils.degToRad(-62.5), Utils.degToRad(0))
  setLightDiffuseColor(self.environment.sunLightId, 0.8, 0.7, 0.4)
  setLightSpecularColor(self.environment.sunLightId, 0.8, 0.7, 0.4)
  self:loadVehicle("data/vehicles/steerable/fendt/fendt936vario.xml", -462.5, 0.5, 440, 0)
  self:loadVehicle("data/vehicles/tools/synkro2600.xml", -462.5, 0.5, 435, 0)
  self.densityId = self.terrainDetailId
  local cuttedWheatId = self.cuttedWheatId
  local cutBarleyId = g_currentMission.fruits[FruitUtil.FRUITTYPE_BARLEY].cutShortId
  setDensityMaskedParallelogram(cutBarleyId, -464.5, 443, 37.5, 0, 0, 57, 0, 1, self.terrainDetailId, self.sowingChannel, 1, 1)
  self.densityChannel = self.cultivatorChannel
  self.targetDensity = 29000
  self:addDensityRegion(-464, 443, 37, 57, true)
  MissionTutorialCultivating:superClass().load(self)
end
function MissionTutorialCultivating:mouseEvent(posX, posY, isDown, isUp, button)
  MissionTutorialCultivating:superClass().mouseEvent(self, posX, posY, isDown, isUp, button)
end
function MissionTutorialCultivating:keyEvent(unicode, sym, modifier, isDown)
  MissionTutorialCultivating:superClass().keyEvent(self, unicode, sym, modifier, isDown)
end
function MissionTutorialCultivating:update(dt)
  MissionTutorialCultivating:superClass().update(self, dt)
end
function MissionTutorialCultivating:draw()
  MissionTutorialCultivating:superClass().draw(self)
end

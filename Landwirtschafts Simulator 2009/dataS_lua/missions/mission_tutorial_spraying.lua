MissionTutorialSpraying = {}
local MissionTutorialSpraying_mt = Class(MissionTutorialSpraying, FieldMission)
function MissionTutorialSpraying:new()
  local instance = MissionTutorialSpraying:superClass():new(MissionTutorialSpraying_mt)
  instance.state = BaseMission.STATE_INTRO
  instance.playerStartX = -456
  instance.playerStartY = -0.8
  instance.playerStartZ = 433.5
  instance.playerRotX = Utils.degToRad(0)
  instance.playerRotY = Utils.degToRad(128)
  instance.showHudEnv = false
  return instance
end
function MissionTutorialSpraying:delete()
  MissionTutorialSpraying:superClass().delete(self)
end
function MissionTutorialSpraying:load()
  self.environment = Environment:new("data/sky/sky_mission_race1.i3d", false, 14)
  self.environment.timeScale = 1
  MissionTutorialSpraying:superClass().loadMap(self, "map01")
  setFog("exp2", 0.0025, 1, 0.47058823529411764, 0.5254901960784314, 0.5882352941176471)
  self:loadVehicle("data/vehicles/steerable/fendt/fendt716vario.xml", -462, 5, 440, 0)
  self:loadVehicle("data/vehicles/tools/triton200.xml", -462, 5, 435, 0)
  self.densityId = self.terrainDetailId
  local barleyId = g_currentMission.fruits[FruitUtil.FRUITTYPE_BARLEY].id
  setDensityMaskedParallelogram(barleyId, -464.5, 443, 37.5, 0, 0, 57, 2, 1, self.densityId, 2, 1, 1)
  setEnableGrowth(barleyId, false)
  self.densityChannel = 3
  self.targetDensity = 29000
  self:addDensityRegion(-464, 443, 37, 57, true)
  MissionTutorialSpraying:superClass().load(self)
end
function MissionTutorialSpraying:mouseEvent(posX, posY, isDown, isUp, button)
  MissionTutorialSpraying:superClass().mouseEvent(self, posX, posY, isDown, isUp, button)
end
function MissionTutorialSpraying:keyEvent(unicode, sym, modifier, isDown)
  MissionTutorialSpraying:superClass().keyEvent(self, unicode, sym, modifier, isDown)
end
function MissionTutorialSpraying:update(dt)
  MissionTutorialSpraying:superClass().update(self, dt)
end
function MissionTutorialSpraying:draw()
  MissionTutorialSpraying:superClass().draw(self)
end

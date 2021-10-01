MissionTutorialPloughing = {}
local MissionTutorialPloughing_mt = Class(MissionTutorialPloughing, FieldMission)
function MissionTutorialPloughing:new()
  local instance = MissionTutorialPloughing:superClass():new(MissionTutorialPloughing_mt)
  instance.state = BaseMission.STATE_INTRO
  instance.playerStartX = -457.7
  instance.playerStartY = 0.1
  instance.playerStartZ = 431.5
  instance.playerRotX = Utils.degToRad(0)
  instance.playerRotY = Utils.degToRad(130)
  instance.showHudEnv = false
  return instance
end
function MissionTutorialPloughing:delete()
  MissionTutorialPloughing:superClass().delete(self)
end
function MissionTutorialPloughing:load()
  self.environment = Environment:new("data/sky/sky_mission_race1.i3d", false, 14)
  self.environment.timeScale = 1
  MissionTutorialPloughing:superClass().loadMap(self, "map01")
  setFog("exp2", 0.0025, 1, 0.47058823529411764, 0.5254901960784314, 0.5882352941176471)
  self:loadVehicle("data/vehicles/steerable/fendt/fendt716vario.xml", -464.2, 5, 441, 0)
  self:loadVehicle("data/vehicles/tools/servo35s.xml", -464.2, 5, 435, 0)
  self.densityId = self.terrainDetailId
  self.densityChannel = 1
  self.targetDensity = 27000
  self:addDensityRegion(-464, 443, 37, 57, true)
  MissionTutorialPloughing:superClass().load(self)
end
function MissionTutorialPloughing:mouseEvent(posX, posY, isDown, isUp, button)
  MissionTutorialPloughing:superClass().mouseEvent(self, posX, posY, isDown, isUp, button)
end
function MissionTutorialPloughing:keyEvent(unicode, sym, modifier, isDown)
  MissionTutorialPloughing:superClass().keyEvent(self, unicode, sym, modifier, isDown)
end
function MissionTutorialPloughing:update(dt)
  MissionTutorialPloughing:superClass().update(self, dt)
end
function MissionTutorialPloughing:draw()
  MissionTutorialPloughing:superClass().draw(self)
end

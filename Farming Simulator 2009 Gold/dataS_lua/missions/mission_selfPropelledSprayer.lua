MissionSelfPropelledSprayer = {}
local MissionSelfPropelledSprayer_mt = Class(MissionSelfPropelledSprayer, FieldMission)
function MissionSelfPropelledSprayer:new()
  local instance = MissionSelfPropelledSprayer:superClass():new(MissionSelfPropelledSprayer_mt)
  instance.state = BaseMission.STATE_INTRO
  instance.playerStartX = -337.85
  instance.playerStartY = 0.1
  instance.playerStartZ = 644.25
  instance.playerRotX = Utils.degToRad(0)
  instance.playerRotY = Utils.degToRad(215)
  instance.showHudEnv = false
  return instance
end
function MissionSelfPropelledSprayer:delete()
  MissionSelfPropelledSprayer:superClass().delete(self)
end
function MissionSelfPropelledSprayer:load()
  self.environment = Environment:new("data/sky/sky_mission_race1.i3d", false, 14)
  self.environment.timeScale = 1
  MissionSelfPropelledSprayer:superClass().loadMap(self, "map01")
  setFog("exp2", 0.0025, 1, 0.47058823529411764, 0.5254901960784314, 0.5882352941176471)
  setLightDiffuseColor(self.environment.sunLightId, 0.8, 0.8, 0.85)
  setLightSpecularColor(self.environment.sunLightId, 0.9, 0.9, 0.8)
  setAmbientColor(0.47058823529411764, 0.47058823529411764, 0.5098039215686274)
  self:loadVehicle("data/vehicles/steerable/fendt/selfPropelledSprayer.xml", -332, 2, 652, Utils.degToRad(90))
  self.densityId = self.terrainDetailId
  self.densityChannel = 3
  self.targetDensity = 437000
  self:addDensityRegion(-320, 473, 149, 197, true)
  MissionSelfPropelledSprayer:superClass().load(self)
end
function MissionSelfPropelledSprayer:mouseEvent(posX, posY, isDown, isUp, button)
  MissionSelfPropelledSprayer:superClass().mouseEvent(self, posX, posY, isDown, isUp, button)
end
function MissionSelfPropelledSprayer:keyEvent(unicode, sym, modifier, isDown)
  MissionSelfPropelledSprayer:superClass().keyEvent(self, unicode, sym, modifier, isDown)
end
function MissionSelfPropelledSprayer:update(dt)
  MissionSelfPropelledSprayer:superClass().update(self, dt)
end
function MissionSelfPropelledSprayer:draw()
  MissionSelfPropelledSprayer:superClass().draw(self)
end

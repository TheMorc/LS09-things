MissionTutorialThreshing = {}
local MissionTutorialThreshing_mt = Class(MissionTutorialThreshing, FieldMission)
function MissionTutorialThreshing:new()
  local instance = MissionTutorialThreshing:superClass():new(MissionTutorialThreshing_mt)
  instance.state = BaseMission.STATE_INTRO
  instance.playerStartX = -452.6
  instance.playerStartY = 0.1
  instance.playerStartZ = 429.3
  instance.playerRotX = Utils.degToRad(0)
  instance.playerRotY = Utils.degToRad(128)
  instance.showHudEnv = false
  return instance
end
function MissionTutorialThreshing:delete()
  MissionTutorialThreshing:superClass().delete(self)
end
function MissionTutorialThreshing:load()
  self.environment = Environment:new("data/sky/sky_mission_race1.i3d", false, 14)
  self.environment.timeScale = 1
  MissionTutorialThreshing:superClass().loadMap(self, "map01")
  setFog("exp2", 0.0025, 1, 0.47058823529411764, 0.5254901960784314, 0.5882352941176471)
  local missionCombine = self:loadVehicle("data/vehicles/steerable/fendt/fendt5270.xml", -461, 5, 435, 0)
  self:loadVehicle("data/vehicles/cutters/fendt/fendtCutter6000.xml", -461, 5, 440, Utils.degToRad(180))
  local trailer = self:loadVehicle("data/vehicles/trailers/smallTipper.xml", -442, 5, 428, Utils.degToRad(90))
  local tractor = self:loadVehicle("data/vehicles/steerable/fendt/fendt716vario.xml", -436, 5, 428, Utils.degToRad(90))
  tractor:attachImplement(trailer, 3)
  self.densityId = self.terrainDetailId
  local barleyId = g_currentMission.fruits[FruitUtil.FRUITTYPE_BARLEY].id
  local barleyDesc = FruitUtil.fruitIndexToDesc[FruitUtil.FRUITTYPE_BARLEY]
  barleyDesc.literPerQm = 3
  missionCombine.threshingScale = 2
  setDensityMaskedParallelogram(barleyId, -464.5, 443, 37.5, 0, 0, 57, 0, 1, self.densityId, self.sowingChannel, 1, 1)
  setDensityMaskedParallelogram(barleyId, -464.5, 443, 37.5, 0, 0, 57, 2, 1, self.densityId, self.sowingChannel, 1, 1)
  self.densityId = barleyId
  setEnableGrowth(barleyId, false)
  self.densityChannel = 0
  self.targetDensity = 150
  self.isLowerLimit = true
  self:addDensityRegion(-464, 443, 37, 57, true)
  self.numRegionsPerFrame = 2
  self:updateDensity()
  self.numRegionsPerFrame = 1
  self.startDensity = self.currentDensity
  MissionTutorialThreshing:superClass().load(self)
end
function MissionTutorialThreshing:mouseEvent(posX, posY, isDown, isUp, button)
  MissionTutorialThreshing:superClass().mouseEvent(self, posX, posY, isDown, isUp, button)
end
function MissionTutorialThreshing:keyEvent(unicode, sym, modifier, isDown)
  MissionTutorialThreshing:superClass().keyEvent(self, unicode, sym, modifier, isDown)
end
function MissionTutorialThreshing:update(dt)
  MissionTutorialThreshing:superClass().update(self, dt)
end
function MissionTutorialThreshing:draw()
  MissionTutorialThreshing:superClass().draw(self)
end

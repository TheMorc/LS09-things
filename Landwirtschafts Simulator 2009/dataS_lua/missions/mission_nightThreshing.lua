MissionNightThreshing = {}
local MissionNightThreshing_mt = Class(MissionNightThreshing, FieldMission)
function MissionNightThreshing:new()
  local instance = MissionNightThreshing:superClass():new(MissionNightThreshing_mt)
  instance.state = BaseMission.STATE_INTRO
  instance.playerStartX = 532.26
  instance.playerStartY = -0.8
  instance.playerStartZ = 290.33
  instance.playerRotX = Utils.degToRad(0)
  instance.playerRotY = Utils.degToRad(287.67)
  instance.showWeatherForecast = true
  return instance
end
function MissionNightThreshing:delete()
  MissionNightThreshing:superClass().delete(self)
end
function MissionNightThreshing:load()
  self.environment = Environment:new("data/sky/sky_day_night2.i3d", true, 24, true, false)
  self.environment.timeScale = 30
  local hailStartTime = self.environment.timeScale * self.minTime / 60000 - self.environment.rainFadeDuration * 0.9
  self.environment:startRain(36000000, 1, hailStartTime)
  MissionNightThreshing:superClass().loadMap(self, "map01")
  self.missionMap = MissionNightThreshing:superClass().loadMissionMap(self, "mission_nightThreshing/mission_nightThreshing.i3d")
  local missionCombine = self:loadVehicle("data/vehicles/steerable/fendt/fendt9460.xml", 549, 5, 289, Utils.degToRad(180))
  self:loadVehicle("data/vehicles/cutters/fendt/fendtCutter7700.xml", 549, 5, 283, Utils.degToRad(0))
  local trailer = self:loadVehicle("data/vehicles/trailers/bigTipper.xml", 630, 5, 183, Utils.degToRad(90))
  local tractor = self:loadVehicle("data/vehicles/steerable/fendt/fendt716vario.xml", 640, 5, 183, Utils.degToRad(90))
  tractor:attachImplement(trailer, 3)
  self.densityId = self.terrainDetailId
  local barleyDesc = FruitUtil.fruitIndexToDesc[FruitUtil.FRUITTYPE_BARLEY]
  barleyDesc.literPerQm = 2
  missionCombine.threshingScale = 1.3
  local barleyId = g_currentMission.fruits[FruitUtil.FRUITTYPE_BARLEY].id
  setDensityMaskedParallelogram(barleyId, 545, 192, 92, 0, 0, 88, 0, 1, self.densityId, self.sowingChannel, 1, 1)
  setDensityMaskedParallelogram(barleyId, 545, 192, 92, 0, 0, 88, 2, 1, self.densityId, self.sowingChannel, 1, 1)
  self.densityId = barleyId
  setEnableGrowth(barleyId, false)
  self.densityChannel = 0
  self.targetDensity = 1500
  self.isLowerLimit = true
  self:addDensityRegion(545, 192, 92, 88, true)
  self.numRegionsPerFrame = 2
  self:updateDensity()
  self.numRegionsPerFrame = 1
  self.startDensity = self.currentDensity
  self.timeAttack = true
  self.renderTime = true
  self.renderTimeAttackCountdown = false
  MissionNightThreshing:superClass().load(self)
end
function MissionNightThreshing:mouseEvent(posX, posY, isDown, isUp, button)
  MissionNightThreshing:superClass().mouseEvent(self, posX, posY, isDown, isUp, button)
end
function MissionNightThreshing:keyEvent(unicode, sym, modifier, isDown)
  MissionNightThreshing:superClass().keyEvent(self, unicode, sym, modifier, isDown)
end
function MissionNightThreshing:update(dt)
  MissionNightThreshing:superClass().update(self, dt)
end
function MissionNightThreshing:draw()
  MissionNightThreshing:superClass().draw(self)
end

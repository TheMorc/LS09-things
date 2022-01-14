MissionRace2 = {}
local MissionRace2_mt = Class(MissionRace2, RaceMission)
function MissionRace2:new()
  local instance = MissionRace2:superClass():new(MissionRace2_mt)
  instance.playerStartX = -37.6
  instance.playerStartY = -0.8
  instance.playerStartZ = -644.2
  instance.playerRotX = 0
  instance.playerRotY = Utils.degToRad(55.5)
  instance.numTriggers = 17
  instance.triggerShapeCount = 6
  instance.triggerSoundPlayed = {}
  instance.triggerPrefix = "mission_race2_trigger"
  return instance
end
function MissionRace2:delete()
  if self.triggerSound ~= nil then
    delete(self.triggerSound)
  end
  MissionRace2:superClass().delete(self)
end
function MissionRace2:load()
  self.environment = Environment:new("data/sky/sky_mission_race1.i3d", false, 9)
  self.environment.timeScale = 1
  MissionRace2:superClass().loadMap(self, "map01")
  self.missionMap = MissionRace2:superClass().loadMissionMap(self, "mission_race2/mission_race2.i3d")
  setFog("exp", 0.0027, 1, 0.47058823529411764, 0.5254901960784314, 0.5882352941176471)
  self:loadVehicle("data/vehicles/steerable/fendt/fendt716vario.xml", -46.5, 5, -656, Utils.degToRad(180))
  self:loadVehicle("data/vehicles/trailers/smallTipper.xml", -46.5, 5, -647.5, Utils.degToRad(180))
  self.triggerSound = createSample("triggerSound")
  loadSample(self.triggerSound, "data/maps/sounds/checkpointSound.wav", false)
  g_currentMission.missionStats.showPDA = false
  MissionRace2:superClass().load(self)
end
function MissionRace2:mouseEvent(posX, posY, isDown, isUp, button)
  MissionRace2:superClass().mouseEvent(self, posX, posY, isDown, isUp, button)
end
function MissionRace2:keyEvent(unicode, sym, modifier, isDown)
  MissionRace2:superClass().keyEvent(self, unicode, sym, modifier, isDown)
end
function MissionRace2:update(dt)
  MissionRace2:superClass().update(self, dt)
end
function MissionRace2:draw()
  MissionRace2:superClass().draw(self)
end

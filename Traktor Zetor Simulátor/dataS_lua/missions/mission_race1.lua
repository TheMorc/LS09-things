MissionRace1 = {}
local MissionRace1_mt = Class(MissionRace1, RaceMission)
function MissionRace1:new()
  local instance = MissionRace1:superClass():new(MissionRace1_mt)
  instance.playerStartX = -35
  instance.playerStartY = 0.1
  instance.playerStartZ = -654
  instance.playerRotX = 0
  instance.playerRotY = Utils.degToRad(65)
  instance.numTriggers = 19
  instance.triggerShapeCount = 1
  instance.triggerSoundPlayed = {}
  instance.triggerPrefix = "mission_race1_trigger"
  return instance
end
function MissionRace1:delete()
  if self.triggerSound ~= nil then
    delete(self.triggerSound)
  end
  MissionRace1:superClass().delete(self)
end
function MissionRace1:load()
  self.environment = Environment:new("data/sky/sky_mission_race1.i3d", false, 9)
  self.environment.timeScale = 1
  MissionRace1:superClass().loadMap(self, "map01")
  self.missionMap = MissionRace1:superClass().loadMissionMap(self, "mission_race1/mission_race1.i3d")
  setFog("exp", 0.0027, 1, 0.47058823529411764, 0.5254901960784314, 0.5882352941176471)
  self:loadVehicle("data/vehicles/steerable/fendt/fendt209.xml", -46.5, 5, -656, Utils.degToRad(180))
  self.triggerSound = createSample("triggerSound")
  loadSample(self.triggerSound, "data/maps/sounds/checkpointSound.wav", false)
  g_currentMission.missionStats.showPDA = false
  MissionRace1:superClass().load(self)
end
function MissionRace1:mouseEvent(posX, posY, isDown, isUp, button)
  MissionRace1:superClass().mouseEvent(self, posX, posY, isDown, isUp, button)
end
function MissionRace1:keyEvent(unicode, sym, modifier, isDown)
  MissionRace1:superClass().keyEvent(self, unicode, sym, modifier, isDown)
end
function MissionRace1:update(dt)
  MissionRace1:superClass().update(self, dt)
end
function MissionRace1:draw()
  MissionRace1:superClass().draw(self)
end

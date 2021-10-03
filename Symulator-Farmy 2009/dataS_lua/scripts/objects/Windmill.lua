Windmill = {}
local Windmill_mt = Class(Windmill)
function Windmill:onCreate(id)
  table.insert(g_currentMission.updateables, Windmill:new(id))
end
function Windmill:new(name)
  local instance = {}
  setmetatable(instance, Windmill_mt)
  local soundId = createAudioSource("windmillSample", "data/maps/sounds/windmill.wav", 100, 30, 0.5, 0)
  link(name, soundId)
  local topId = getChildAt(name, 0)
  instance.rotorId = getChildAt(topId, 0)
  instance.lightUnlitId = getChildAt(topId, 1)
  instance.lightLitId = getChildAt(topId, 2)
  local rot = math.random(0, 360)
  rotate(instance.rotorId, 0, 0, Utils.degToRad(rot))
  instance.blinkInterval = 1000
  instance.currentBlinkTime = math.random(0, instance.blinkInterval)
  instance.lightOn = true
  instance.counter = 10
  return instance
end
function Windmill:delete()
end
function Windmill:update(dt)
  local rotorRot = -0.002 * dt
  rotate(self.rotorId, 0, 0, rotorRot)
  if not g_currentMission.environment.isSunOn then
    self.currentBlinkTime = self.currentBlinkTime - dt
    if 0 > self.currentBlinkTime then
      self.lightOn = not self.lightOn
      self.currentBlinkTime = self.blinkInterval
      setVisibility(self.lightLitId, self.lightOn)
      setVisibility(self.lightUnlitId, not self.lightOn)
    end
  elseif self.lightOn then
    self.lightOn = false
    setVisibility(self.lightLitId, self.lightOn)
    setVisibility(self.lightUnlitId, not self.lightOn)
  end
end

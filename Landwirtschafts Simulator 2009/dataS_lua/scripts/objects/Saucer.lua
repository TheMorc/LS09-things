Saucer = {}
local Saucer_mt = Class(Saucer)
function Saucer:onCreate(id)
  table.insert(g_currentMission.updateables, Saucer:new(id))
end
function Saucer:new(name)
  local instance = {}
  setmetatable(instance, Saucer_mt)
  instance.triggerId = getChildAt(name, 0)
  addTrigger(instance.triggerId, "triggerCallback", instance)
  instance.saucerId = getChildAt(name, 1)
  instance.saucerBeamId = getChildAt(instance.saucerId, 0)
  instance.saucerLightId = getChildAt(instance.saucerId, 1)
  instance.isActive = false
  instance.currentStage = 1
  local x, y, z = getTranslation(instance.saucerId)
  instance.yPos = 400
  instance.startXPos = x
  setVisibility(instance.saucerId, false)
  setVisibility(instance.saucerBeamId, false)
  setVisibility(instance.saucerLightId, false)
  instance.soundId = createAudioSource("saucerSample", "data/maps/sounds/saucer.wav", 500, 100, 1, 0)
  link(instance.saucerId, instance.soundId)
  setVisibility(instance.soundId, false)
  return instance
end
function Saucer:delete()
  removeTrigger(self.triggerId)
end
function Saucer:update(dt)
  if self.isActive then
    rotate(self.saucerId, 0, 0.002 * dt, 0)
    if self.currentStage == 1 then
      self.yPos = self.yPos - 1 * (self.yPos / 128 - 1)
      local x, y, z = getTranslation(self.saucerId)
      setTranslation(self.saucerId, x, self.yPos, z)
      if self.yPos <= 128.2 then
        self.currentStage = 2
        setVisibility(self.saucerBeamId, false)
        setVisibility(self.saucerLightId, false)
      end
    elseif self.currentStage == 2 then
      self.yPos = self.yPos + 1 * (self.yPos / 128 - 1)
      local x, y, z = getTranslation(self.saucerId)
      setTranslation(self.saucerId, x + 0.5, self.yPos, z)
      if self.yPos > 800 then
        self.currentStage = 1
        self.isActive = false
        setVisibility(self.saucerId, false)
        setVisibility(self.soundId, false)
        self.yPos = 400
        setTranslation(self.saucerId, self.startXPos, self.yPos, z)
      end
    end
  end
end
function Saucer:triggerCallback(triggerId, otherId, onEnter, onLeave, onStay)
  if onStay and otherId == Player.rootNode and not self.isActive then
    local time = g_currentMission.environment.dayTime - 540000
    if 0 < time and time < 10000 then
      self.isActive = true
      setVisibility(self.saucerId, true)
      setVisibility(self.saucerBeamId, true)
      setVisibility(self.saucerLightId, true)
      setVisibility(self.soundId, true)
    end
  end
end

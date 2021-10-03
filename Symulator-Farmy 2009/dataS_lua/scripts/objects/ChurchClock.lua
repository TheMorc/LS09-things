ChurchClock = {}
local ChurchClock_mt = Class(ChurchClock)
function ChurchClock:onCreate(id)
  table.insert(g_currentMission.updateables, ChurchClock:new(id))
end
function ChurchClock:new(name)
  local instance = {}
  setmetatable(instance, ChurchClock_mt)
  instance.timerId = 0
  instance.tollCounter = 0
  instance.waitingForBell = false
  instance.tollNow = true
  instance.shortHands = {}
  instance.longHands = {}
  instance.init = false
  instance.timeOld = 86400001
  instance.lastHourTolled = 0
  if getNumOfChildren(name) == 8 then
    for i = 1, getNumOfChildren(name) / 2 do
      instance.shortHands[i] = getChildAt(name, i * 2 - 2)
      instance.longHands[i] = getChildAt(name, i * 2 - 1)
    end
    instance.init = true
  end
  instance.soundId = createAudioSource("churchBellSample", "data/maps/sounds/churchBell01.wav", 300, 50, 1, 1)
  link(name, instance.soundId)
  setVisibility(instance.soundId, false)
  return instance
end
function ChurchClock:delete()
  if self.timerId ~= 0 then
    removeTimer(self.timerId)
  end
end
function ChurchClock:update(dt)
  if self.init and g_currentMission.environment ~= nil and (g_currentMission.environment.dayTime < self.timeOld or g_currentMission.environment.dayTime - self.timeOld > 60000) then
    local shortHandRot = 2 * math.pi * (g_currentMission.environment.dayTime / 43200000)
    local longHandRot = 2 * math.pi * (g_currentMission.environment.dayTime / 3600000)
    setRotation(self.shortHands[1], 0, 0, -shortHandRot)
    setRotation(self.longHands[1], 0, 0, -longHandRot)
    setRotation(self.shortHands[2], -shortHandRot, 0, 0)
    setRotation(self.longHands[2], -longHandRot, 0, 0)
    setRotation(self.shortHands[3], 0, 0, shortHandRot)
    setRotation(self.longHands[3], 0, 0, longHandRot)
    setRotation(self.shortHands[4], shortHandRot, 0, 0)
    setRotation(self.longHands[4], longHandRot, 0, 0)
    self.timeOld = g_currentMission.environment.dayTime
    if math.floor(g_currentMission.environment.dayTime / 3600000) ~= self.lastHourTolled then
      if self.lastHourTolled == 0 then
        self.lastHourTolled = math.floor(g_currentMission.environment.dayTime / 3600000)
        return
      end
      self.lastHourTolled = math.floor(g_currentMission.environment.dayTime / 3600000)
      if not self.waitingForBell then
        self.tollCounter = self.lastHourTolled % 12
        if self.tollCounter == 0 then
          self.tollCounter = 12
        end
        self.tollCounter = self.tollCounter * 2 - 1
        local sampleDuration = getSampleDuration(getAudioSourceSample(self.soundId))
        self.timerId = addTimer(sampleDuration / 2, "timerCallback", self)
        setVisibility(self.soundId, true)
        self.tollNow = false
        self.waitingForBell = true
      end
    end
  end
end
function ChurchClock:timerCallback()
  if self.tollCounter > 0 then
    setVisibility(self.soundId, self.tollNow)
    self.tollNow = not self.tollNow
    self.tollCounter = self.tollCounter - 1
    return true
  end
  self.waitingForBell = false
  return false
end

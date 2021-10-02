PalletTrigger = {}
local PalletTrigger_mt = Class(PalletTrigger)
function PalletTrigger:onCreate(id)
  table.insert(g_currentMission.updateables, PalletTrigger:new(id))
end
function PalletTrigger:new(id, customMt)
  local instance = {}
  if customMt ~= nil then
    setmetatable(instance, customMt)
  else
    setmetatable(instance, PalletTrigger_mt)
  end
  instance.triggerId = id
  addTrigger(instance.triggerId, "triggerCallback", instance)
  instance.palletTriggerSound = createSample("palletTriggerSound")
  loadSample(instance.palletTriggerSound, "data/maps/sounds/cashRegistry.wav", false)
  instance.currentPallet = 0
  instance.waitingForDeletion = false
  instance.timerId = 0
  return instance
end
function PalletTrigger:update()
end
function PalletTrigger:delete()
  removeTrigger(self.triggerId)
  if self.timerId ~= 0 then
    removeTimer(self.timerId)
  end
  delete(self.palletTriggerSound)
end
function PalletTrigger:triggerCallback(triggerId, otherId, onEnter, onLeave, onStay)
  if onLeave and otherId ~= 0 then
    local isPallet = getUserAttribute(otherId, "isPallet")
    if isPallet ~= nil and isPallet then
      self.currentPallet = 0
    end
  end
  if onStay and otherId ~= 0 then
    local isPallet = getUserAttribute(otherId, "isPallet")
    if isPallet ~= nil and isPallet then
      self.currentPallet = otherId
    end
  end
  if not self.waitingForDeletion and onLeave and otherId ~= 0 then
    local isPalletFork = getUserAttribute(otherId, "isPalletFork")
    if isPalletFork ~= nil and isPalletFork and self.currentPallet ~= 0 then
      self.waitingForDeletion = true
      self.timerId = addTimer(2000, "timerCallback", self)
    end
  end
end
function PalletTrigger:timerCallback()
  if self.currentPallet ~= 0 then
    delete(self.currentPallet)
    self.currentPallet = 0
    local difficultyMultiplier = 2 ^ (3 - g_currentMission.missionStats.difficulty)
    g_currentMission.missionStats.money = g_currentMission.missionStats.money + 400 * difficultyMultiplier
    g_currentMission:increaseReputation(1)
    if self.palletTriggerSound ~= nil then
      playSample(self.palletTriggerSound, 1, 1, 0)
    end
  end
  self.waitingForDeletion = false
  return false
end

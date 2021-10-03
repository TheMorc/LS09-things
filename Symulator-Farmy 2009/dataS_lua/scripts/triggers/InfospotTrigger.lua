InfospotTrigger = {}
local InfospotTrigger_mt = Class(InfospotTrigger)
function InfospotTrigger:onCreate(id)
  table.insert(g_currentMission.infospotTriggers, InfospotTrigger:new(id))
end
function InfospotTrigger:new(name)
  local instance = {}
  setmetatable(instance, InfospotTrigger_mt)
  instance.triggerId = name
  addTrigger(name, "triggerCallback", instance)
  instance.deleteListenerId = addDeleteListener(name, "delete", instance)
  instance.infoSymbol = getChildAt(name, 0)
  local x, y, z = getTranslation(instance.infoSymbol)
  instance.posY = y
  instance.jump = 0.05
  instance.isEnabled = true
  return instance
end
function InfospotTrigger:delete()
  removeTrigger(self.triggerId)
  removeDeleteListener(self.triggerId, self.deleteListenerId)
end
function InfospotTrigger:update(dt)
  if self.isEnabled then
    rotate(self.infoSymbol, 0, 0.005 * dt, 0)
    self.jump = self.jump - 1.5E-4 * dt
    local x, y, z = getTranslation(self.infoSymbol)
    setTranslation(self.infoSymbol, x, y + self.jump, z)
    if y + self.jump <= self.posY then
      self.jump = 0.05
    end
    if not getVisibility(self.triggerId) then
      self.isEnabled = false
    end
  end
end
function InfospotTrigger:triggerCallback(triggerId, otherId, onEnter, onLeave, onStay)
  if onEnter and self.isEnabled and (otherId == Player.rootNode or g_currentMission.currentVehicle ~= nil and otherId == g_currentMission.currentVehicle.components[1].node) then
    if g_currentMission.infospotSound ~= nil then
      playSample(g_currentMission.infospotSound, 1, 1, 0)
    end
    g_currentMission:infospotTouched(triggerId)
    self.isEnabled = false
    setVisibility(self.triggerId, false)
  end
end

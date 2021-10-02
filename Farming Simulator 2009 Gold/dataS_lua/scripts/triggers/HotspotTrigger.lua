HotspotTrigger = {}
local HotspotTrigger_mt = Class(HotspotTrigger)
function HotspotTrigger:onCreate(id)
  table.insert(g_currentMission.hotspotTriggers, HotspotTrigger:new(id))
end
function HotspotTrigger:new(name)
  local instance = {}
  setmetatable(instance, HotspotTrigger_mt)
  instance.triggerId = name
  addTrigger(name, "triggerCallback", instance)
  instance.deleteListenerId = addDeleteListener(name, "delete", instance)
  instance.ring1 = getChildAt(name, 0)
  instance.ring2 = getChildAt(name, 1)
  local x, y, z = getTranslation(name)
  instance.mapHotspot = g_currentMission.missionStats:createMapHotspot(tostring(name), "dataS/missions/hud_pda_spot_red.png", x + 1024, z + 1024, g_currentMission.missionStats.pdaMapArrowSize, g_currentMission.missionStats.pdaMapArrowSize * 1.3333333333333333, false, true, 0)
  instance.distanceToPlayer = 0
  instance.isEnabled = true
  return instance
end
function HotspotTrigger:delete()
  removeTrigger(self.triggerId)
  removeDeleteListener(self.triggerId, self.deleteListenerId)
end
function HotspotTrigger:update(dt)
  rotate(self.ring1, 0, 5.0E-4 * dt, 0)
  rotate(self.ring2, 0, 3.0E-4 * dt, 0)
end
function HotspotTrigger:triggerCallback(triggerId, otherId, onEnter, onLeave, onStay)
  if onEnter and self.isEnabled and g_currentMission.currentVehicle ~= nil and otherId == g_currentMission.currentVehicle.components[1].node then
    if g_currentMission.hotspotSound ~= nil then
      playSample(g_currentMission.hotspotSound, 1, 1, 0)
    end
    g_currentMission:hotspotTouched(triggerId)
    self.mapHotspot:delete()
    self.isEnabled = false
    setVisibility(self.triggerId, false)
  end
end

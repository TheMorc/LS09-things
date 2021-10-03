PlayerPickupTrigger = {}
local PlayerPickupTrigger_mt = Class(PlayerPickupTrigger)
function PlayerPickupTrigger:onCreate(id)
  table.insert(g_currentMission.miscTriggers, PlayerPickupTrigger:new(id))
end
function PlayerPickupTrigger:new(id)
  local instance = {}
  setmetatable(instance, PlayerPickupTrigger_mt)
  instance.triggerId = id
  addTrigger(id, "triggerCallback", instance)
  if getNumOfChildren(id) > 0 then
    local child = getChildAt(id, 0)
    instance.originalTranslation = {
      getTranslation(child)
    }
    instance.originalRotation = {
      getRotation(child)
    }
  end
  return instance
end
function PlayerPickupTrigger:delete()
  removeTrigger(self.triggerId)
end
function PlayerPickupTrigger:triggerCallback(triggerId, otherId, onEnter, onLeave, onStay)
  if otherId == Player.rootNode then
    if onEnter then
      if getNumOfChildren(self.triggerId) > 0 then
        Player.triggeredPickupTrigger = self
      end
    elseif onLeave then
      Player.triggeredPickupTrigger = nil
    end
  end
end
function PlayerPickupTrigger:resetPickup(pickup)
  link(self.triggerId, pickup)
  if self.originalTranslation ~= nil and self.originalRotation ~= nil then
    setTranslation(pickup, unpack(self.originalTranslation))
    setRotation(pickup, unpack(self.originalRotation))
  else
    setTranslation(pickup, 0, 0, 0)
    setRotation(pickup, 0, 0, 0)
  end
end

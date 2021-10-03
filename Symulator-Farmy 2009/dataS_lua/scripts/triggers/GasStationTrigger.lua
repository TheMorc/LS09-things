GasStation = {}
local GasStation_mt = Class(GasStation)
function GasStation:onCreate(id)
  table.insert(g_currentMission.gasStations, GasStation:new(id))
end
function GasStation:new(id, customMt)
  local instance = {}
  if customMt ~= nil then
    setmetatable(instance, customMt)
  else
    setmetatable(instance, GasStation_mt)
  end
  instance.triggerId = id
  addTrigger(id, "triggerCallback", instance)
  instance.deleteListenerId = addDeleteListener(id, "delete", instance)
  instance.isEnabled = true
  self.shapesCount = {}
  return instance
end
function GasStation:delete()
  removeTrigger(self.triggerId)
  removeDeleteListener(self.triggerId, self.deleteListenerId)
end
function GasStation:triggerCallback(triggerId, otherId, onEnter, onLeave, onStay)
  if self.isEnabled then
    if self.shapesCount[otherId] == nil then
      self.shapesCount[otherId] = 0
    end
    if onEnter then
      self.shapesCount[otherId] = self.shapesCount[otherId] + 1
    elseif onLeave then
      self.shapesCount[otherId] = self.shapesCount[otherId] - 1
    end
    if g_currentMission.currentVehicle ~= nil and self.shapesCount[g_currentMission.currentVehicle.components[1].node] ~= nil then
      g_currentMission.currentVehicle.hasRefuelStationInRange = 0 < self.shapesCount[g_currentMission.currentVehicle.components[1].node]
    end
  end
end

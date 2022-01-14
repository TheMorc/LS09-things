Barrier = {}
local Barrier_mt = Class(Barrier)
function Barrier:onCreate(id)
  table.insert(g_currentMission.barriers, Barrier:new(id))
end
function Barrier:new(id, customMt)
  local instance = {}
  if customMt ~= nil then
    setmetatable(instance, customMt)
  else
    setmetatable(instance, Barrier_mt)
  end
  instance.triggerId = id
  addTrigger(id, "triggerCallback", instance)
  instance.deleteListenerId = addDeleteListener(id, "delete", instance)
  instance.barriers = {}
  local num = getNumOfChildren(id)
  for i = 0, num - 1 do
    local childLevel1 = getChildAt(id, i)
    if childLevel1 ~= 0 and getNumOfChildren(id) >= 1 then
      local barrierId = getChildAt(childLevel1, 0)
      if barrierId ~= 0 then
        table.insert(instance.barriers, barrierId)
      end
    end
  end
  instance.isEnabled = true
  self.count = 0
  self.angle = 0
  self.maxAngle = 1.5
  self.minAngle = 0
  return instance
end
function Barrier:delete()
  removeTrigger(self.triggerId)
  removeDeleteListener(self.triggerId, self.deleteListenerId)
end
function Barrier:update(dt)
  local old = self.angle
  if self.count > 0 then
    if self.angle < self.maxAngle then
      self.angle = self.angle + dt * 0.001
    end
  elseif self.angle > self.minAngle then
    self.angle = self.angle - dt * 0.001
  end
  if old ~= self.angle then
    for i = 1, table.getn(self.barriers) do
      setRotation(self.barriers[i], 0, 0, self.angle)
    end
  end
end
function Barrier:triggerCallback(triggerId, otherId, onEnter, onLeave, onStay)
  if onEnter and self.isEnabled then
    self.count = self.count + 1
  elseif onLeave then
    self.count = self.count - 1
  end
end

BarnMoverTrigger = {}
local BarnMoverTrigger_mt = Class(BarnMoverTrigger)
function BarnMoverTrigger:onCreate(id)
  table.insert(g_currentMission.updateables, BarnMoverTrigger:new(id))
end
function BarnMoverTrigger:new(id, customMt)
  local instance = {}
  if customMt ~= nil then
    setmetatable(instance, customMt)
  else
    setmetatable(instance, BarnMoverTrigger_mt)
  end
  instance.triggerId = getChildAt(id, 0)
  instance.triggerTargetId = getChildAt(id, 1)
  addTrigger(instance.triggerId, "triggerCallback", instance)
  addTrigger(instance.triggerTargetId, "triggerCallbackTarget", instance)
  instance.barnMoverTriggerSound = createSample("barnMoverTriggerSound")
  loadSample(instance.barnMoverTriggerSound, "data/maps/sounds/cashRegistry.wav", false)
  instance.dirLength = 0.008
  instance.dirX, instance.dirY, instance.dirZ = localDirectionToWorld(instance.triggerId, 0, 0, 1)
  instance.dirX = instance.dirX * instance.dirLength
  instance.dirY = instance.dirY * instance.dirLength
  instance.dirZ = instance.dirZ * instance.dirLength
  instance.targetVelocity = 2
  instance.touched = {}
  return instance
end
function BarnMoverTrigger:delete()
  removeTrigger(self.triggerId)
  removeTrigger(self.triggerTargetId)
  delete(self.barnMoverTriggerSound)
end
function BarnMoverTrigger:update(dt)
  for k, touched in pairs(self.touched) do
    local vx, vy, vz = getLinearVelocity(k)
    local dot = vx * self.dirX + vy * self.dirY + vz * self.dirZ
    local v = dot / self.dirLength
    if v < self.targetVelocity then
      local scale = dt * touched.mass
      addForce(k, self.dirX * dt, self.dirY * dt, self.dirZ * dt, 0, 0, 0, true)
    end
  end
end
function BarnMoverTrigger:triggerCallback(triggerId, otherId, onEnter, onLeave, onStay)
  if onEnter then
    local touched = self.touched[otherId]
    if touched ~= nil then
      touched.count = touched.count + 1
    else
      local mass = getMass(otherId)
      self.touched[otherId] = {mass = mass, count = 1}
    end
  elseif onLeave then
    local touched = self.touched[otherId]
    if touched ~= nil then
      if touched.count > 1 then
        touched.count = touched.count - 1
      else
        self.touched[otherId] = nil
      end
    end
  end
end
function BarnMoverTrigger:triggerCallbackTarget(triggerId, otherId, onEnter, onLeave, onStay)
  if onEnter and otherId ~= 0 then
    local isStrawbale = getUserAttribute(otherId, "isStrawbale")
    local isHaybale = getUserAttribute(otherId, "isHaybale")
    if isStrawbale ~= nil and isStrawbale or isHaybale ~= nil and isHaybale then
      local difficultyMultiplier = 2 ^ (3 - g_currentMission.missionStats.difficulty)
      local baseValue = 400
      if isHaybale ~= nil and isHaybale then
        baseValue = 800
      end
      g_currentMission.missionStats.money = g_currentMission.missionStats.money + baseValue * difficultyMultiplier
      if g_currentMission.baleCount ~= nil then
        g_currentMission.baleCount = g_currentMission.baleCount + 1
      end
      g_currentMission:removeItemToSave(otherId)
      if self.barnMoverTriggerSound ~= nil then
        playSample(self.barnMoverTriggerSound, 1, 1, 0)
      end
    end
    self.touched[otherId] = nil
    delete(otherId)
  end
end

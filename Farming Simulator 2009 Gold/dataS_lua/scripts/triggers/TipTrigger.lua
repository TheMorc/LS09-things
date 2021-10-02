TipTrigger = {}
local TipTrigger_mt = Class(TipTrigger)
function TipTrigger:onCreate(id)
  table.insert(g_currentMission.tipTriggers, TipTrigger:new(id))
end
function TipTrigger:new(id, customMt)
  local instance = {}
  if customMt ~= nil then
    setmetatable(instance, customMt)
  else
    setmetatable(instance, TipTrigger_mt)
  end
  instance.triggerId = id
  addTrigger(id, "triggerCallback", instance)
  instance.deleteListenerId = addDeleteListener(id, "delete", instance)
  instance.appearsOnPDA = Utils.getNoNil(getUserAttribute(id, "appearsOnPDA"), false)
  instance.isFarmTrigger = Utils.getNoNil(getUserAttribute(id, "isFarmTrigger"), false)
  instance.stationName = Utils.getNoNil(getUserAttribute(id, "stationName"), "Station")
  instance.acceptedFruitTypes = {}
  instance.priceMultipliers = {}
  local fruitTypes = getUserAttribute(id, "fruitTypes")
  local priceMultipliersString = getUserAttribute(id, "priceMultipliers")
  if fruitTypes ~= nil then
    local types = Utils.splitString(" ", fruitTypes)
    local multipliers = Utils.splitString(" ", priceMultipliersString)
    for k, v in pairs(types) do
      local desc = FruitUtil.fruitTypes[v]
      if desc ~= nil then
        instance.acceptedFruitTypes[desc.index] = true
        instance.priceMultipliers[desc.index] = tonumber(multipliers[k])
      end
    end
  end
  local parent = getParent(id)
  local movingIndex = getUserAttribute(id, "movingIndex")
  if movingIndex ~= nil then
    instance.movingId = Utils.indexToObject(parent, movingIndex)
    if instance.movingId ~= nil then
      instance.moveMinY = Utils.getNoNil(getUserAttribute(id, "moveMinY"), 0)
      instance.moveMaxY = Utils.getNoNil(getUserAttribute(id, "moveMaxY"), 0)
      instance.moveScale = Utils.getNoNil(getUserAttribute(id, "moveScale"), 0.001) * 0.01
      instance.moveBackScale = (instance.moveMaxY - instance.moveMinY) / Utils.getNoNil(getUserAttribute(id, "moveBackTime"), 10000)
    end
  end
  instance.isEnabled = true
  return instance
end
function TipTrigger:delete()
  removeTrigger(self.triggerId)
  removeDeleteListener(self.triggerId, self.deleteListenerId)
end
function TipTrigger:update(dt)
  if self.movingId ~= nil then
    local x, y, z = getTranslation(self.movingId)
    local newY = math.max(y - dt * self.moveBackScale, self.moveMinY)
    setTranslation(self.movingId, x, newY, z)
  end
end
function TipTrigger:updateMoving(delta)
  if self.movingId ~= nil then
    local x, y, z = getTranslation(self.movingId)
    local newY = math.min(y + delta * self.moveScale, self.moveMaxY)
    setTranslation(self.movingId, x, newY, z)
  end
end
function TipTrigger:triggerCallback(triggerId, otherId, onEnter, onLeave, onStay, otherShapeId)
  if self.isEnabled then
    if onEnter then
      local trailer = g_currentMission.objectToTrailer[otherShapeId]
      if trailer ~= nil and trailer.allowTipDischarge then
        if g_currentMission.trailerTipTriggers[trailer] == nil then
          g_currentMission.trailerTipTriggers[trailer] = {}
        end
        table.insert(g_currentMission.trailerTipTriggers[trailer], self)
      end
    elseif onLeave then
      local trailer = g_currentMission.objectToTrailer[otherShapeId]
      if trailer ~= nil and trailer.allowTipDischarge then
        local triggers = g_currentMission.trailerTipTriggers[trailer]
        if triggers ~= nil then
          for i = 1, table.getn(triggers) do
            if triggers[i] == self then
              table.remove(triggers, i)
              if table.getn(triggers) == 0 then
                g_currentMission.trailerTipTriggers[trailer] = nil
              end
              break
            end
          end
        end
      end
    end
  end
end

HouseLight = {}
local HouseLight_mt = Class(HouseLight)
function HouseLight:onCreate(id)
  table.insert(g_currentMission.updateables, HouseLight:new(id))
end
function HouseLight:new(name)
  local instance = {}
  setmetatable(instance, HouseLight_mt)
  instance.init = false
  if getNumOfChildren(name) > 0 then
    instance.lightId = getChildAt(name, 0)
    instance.init = true
  end
  instance.isSunOn = true
  instance.isActive = false
  if math.random() >= 0.33 then
    instance.isActive = true
  end
  return instance
end
function HouseLight:delete()
end
function HouseLight:update(dt)
  if self.init and g_currentMission.environment ~= nil and g_currentMission.environment.isSunOn ~= self.isSunOn then
    self.isSunOn = g_currentMission.environment.isSunOn
    if not self.isSunOn and self.isActive then
      setVisibility(self.lightId, true)
    end
    if self.isSunOn then
      setVisibility(self.lightId, false)
      self.isActive = false
      if math.random() >= 0.33 then
        self.isActive = true
      end
    end
  end
end

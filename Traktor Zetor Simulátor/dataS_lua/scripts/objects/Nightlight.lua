Nightlight = {}
local Nightlight_mt = Class(Nightlight)
function Nightlight:onCreate(id)
  table.insert(g_currentMission.updateables, Nightlight:new(id))
end
function Nightlight:new(name)
  local instance = {}
  setmetatable(instance, Nightlight_mt)
  instance.init = false
  if getNumOfChildren(name) == 2 then
    instance.dayId = getChildAt(name, 0)
    instance.nightId = getChildAt(name, 1)
    instance.init = true
  end
  instance.isSunOn = true
  return instance
end
function Nightlight:delete()
end
function Nightlight:update(dt)
  if self.init and g_currentMission.environment ~= nil and g_currentMission.environment.isSunOn ~= self.isSunOn then
    self.isSunOn = g_currentMission.environment.isSunOn
    setVisibility(self.dayId, self.isSunOn)
    setVisibility(self.nightId, not self.isSunOn)
  end
end

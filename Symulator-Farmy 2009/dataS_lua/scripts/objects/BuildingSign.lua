BuildingSign = {}
local BuildingSign_mt = Class(BuildingSign)
function BuildingSign:onCreate(id)
  table.insert(g_currentMission.updateables, BuildingSign:new(id))
end
function BuildingSign:new(name)
  local instance = {}
  setmetatable(instance, BuildingSign_mt)
  instance.signId = getChildAt(name, 0)
  instance.swing = 0
  return instance
end
function BuildingSign:delete()
end
function BuildingSign:update(dt)
  self.swing = self.swing + 0.03
  if self.swing > 2 * math.pi then
    self.swing = 0
  end
  local signRot = math.sin(self.swing) * 0.2
  setRotation(self.signId, 0, 0, signRot)
end

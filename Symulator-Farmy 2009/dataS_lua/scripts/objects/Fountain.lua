Fountain = {}
local Fountain_mt = Class(Fountain)
function Fountain:onCreate(id)
  table.insert(g_currentMission.updateables, Fountain:new(id))
end
function Fountain:new(name)
  local instance = {}
  setmetatable(instance, Fountain_mt)
  local rootNode = name
  instance.siloParticleSystemRoot = loadI3DFile("data/vehicles/particleSystems/fountainParticleSystem.i3d")
  local x, y, z = getTranslation(rootNode)
  x = x + 0.125
  y = y + 0.9
  z = z + 0.132
  setTranslation(instance.siloParticleSystemRoot, x, y, z)
  link(getParent(rootNode), instance.siloParticleSystemRoot)
  for i = 0, getNumOfChildren(instance.siloParticleSystemRoot) - 1 do
    local child = getChildAt(instance.siloParticleSystemRoot, i)
    if getClassName(child) == "Shape" then
      local geometry = getGeometry(child)
      if geometry ~= 0 and getClassName(geometry) == "ParticleSystem" then
        instance.siloParticleSystem = geometry
      end
    end
  end
  if instance.siloParticleSystem ~= nil then
    setEmittingState(instance.siloParticleSystem, true)
  end
  return instance
end
function Fountain:delete()
end
function Fountain:update(dt)
end

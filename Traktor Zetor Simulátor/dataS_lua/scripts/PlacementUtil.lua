PlacementUtil = {}
PlacementUtil.testHeight = 50
PlacementUtil.testStepSize = 2
function PlacementUtil.getPlace(places, sizeX, sizeZ, offsetX, offsetZ, usage)
  for k, place in pairs(places) do
    local width = 0
    local placeUsage = usage[place]
    if placeUsage == nil then
      placeUsage = 0
    end
    local halfSizeX = sizeX * 0.5
    for width = placeUsage + halfSizeX, place.width - halfSizeX, PlacementUtil.testStepSize do
      local x = place.startX + width * place.dirX
      local y = place.startY + width * place.dirY
      local z = place.startZ + width * place.dirZ
      local terrainHeight = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, y, z)
      y = math.max(terrainHeight + 0.5, y)
      PlacementUtil.tempHasCollision = false
      overlapBox(x, y, z, place.rotX, place.rotY, place.rotZ, sizeX, PlacementUtil.testHeight, sizeZ, "PlacementUtil.collisionTestCallback")
      if not PlacementUtil.tempHasCollision then
        local vehicleX = x + offsetX * place.dirX - offsetZ * place.dirPerpX
        local vehicleY = y + offsetX * place.dirY - offsetZ * place.dirPerpY
        local vehicleZ = z + offsetX * place.dirZ - offsetZ * place.dirPerpZ
        local terrainHeight = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, y, z)
        y = math.max(terrainHeight + 1, y)
        return vehicleX, vehicleY, vehicleZ, place, width + halfSizeX, y - terrainHeight
      end
    end
  end
  return nil
end
function PlacementUtil.markPlaceUsed(usage, place, width)
  usage[place] = width
end
function PlacementUtil:collisionTestCallback(transformId)
  if g_currentMission.nodeToVehicle[transformId] ~= nil or transformId == Player.rootNode then
    PlacementUtil.tempHasCollision = true
  end
end
function PlacementUtil.createPlace(id)
  local place = {}
  place.startX, place.startY, place.startZ = getWorldTranslation(id)
  place.rotX, place.rotY, place.rotZ = getWorldRotation(id)
  place.dirX, place.dirY, place.dirZ = localDirectionToWorld(id, 1, 0, 0)
  place.dirPerpX, place.dirPerpY, place.dirPerpZ = localDirectionToWorld(id, 0, 0, 1)
  if 0 < getNumOfChildren(id) then
    local x, y, z = getTranslation(getChildAt(id, 0))
    place.width = math.abs(x)
    if x < 0 then
      place.dirX = -place.dirX
      place.dirY = -place.dirY
      place.dirZ = -place.dirZ
    end
  else
    place.width = 0.1
  end
  return place
end

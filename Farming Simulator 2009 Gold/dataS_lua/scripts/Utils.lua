Utils = {}
function Utils.checkChildIndex(node, index)
  if index >= getNumOfChildren(node) then
    print("Error: index out of range")
    printCallstack()
    return false
  end
  return true
end
function Utils.indexToObject(components, index)
  if index == nil then
    return nil
  end
  local curPos = 1
  local rootNode
  if type(components) == "table" then
    local componentIndex = 1
    local iStart, iEnd = string.find(index, ">", 1)
    if iStart ~= nil then
      componentIndex = tonumber(string.sub(index, 1, iStart - 1)) + 1
      curPos = iEnd + 1
      if iEnd == string.len(index) then
        return components[componentIndex].node
      end
    end
    rootNode = components[componentIndex].node
  else
    rootNode = components
  end
  local retVal = rootNode
  local iStart, iEnd = string.find(index, "|", curPos)
  while iStart ~= nil do
    local indexNumber = tonumber(string.sub(index, curPos, iStart - 1))
    if not Utils.checkChildIndex(retVal, indexNumber) then
      print("Index: " .. index)
      return nil
    end
    retVal = getChildAt(retVal, indexNumber)
    curPos = iEnd + 1
    iStart, iEnd = string.find(index, "|", curPos)
  end
  local indexNumber = tonumber(string.sub(index, curPos))
  if not Utils.checkChildIndex(retVal, indexNumber) then
    print("Index: " .. index)
    return nil
  end
  retVal = getChildAt(retVal, indexNumber)
  return retVal, rootNode
end
local UPDATE_INDEX = 0
local KEEP_INDEX = 1
local SET_INDEX_TO_ZERO = 2
local TYPE_COMPARE_EQUAL = 0
local TYPE_COMPARE_NONE = 1
local NUM_FRUIT_DENSITYMAP_CHANNELS = 8
function Utils.cutFruitArea(fruitId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
  local ids = g_currentMission.fruits[fruitId]
  if ids == nil or ids.id == 0 then
    return 0
  end
  local id = ids.id
  local value = 0
  local desc = FruitUtil.fruitIndexToDesc[fruitId]
  if not desc.needsSeeding then
    value = 1
  end
  setDensityReturnValueShift(id, -1)
  setDensityMaskParams(id, "greater", desc.minHarvestingGrowthState)
  local x, z, widthX, widthZ, heightX, heightZ = Utils.getXZWidthAndHeight(id, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
  local area = setDensityMaskedParallelogram(id, x, z, widthX, widthZ, heightX, heightZ, 0, 3, id, 0, 3, value)
  setDensityReturnValueShift(id, 0)
  setDensityMaskParams(id, "greater", 0)
  return area
end
function Utils.updateFruitCutShortArea(fruitId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, value)
  local ids = g_currentMission.fruits[fruitId]
  if ids == nil or ids.cutShortId == 0 then
    return 0
  end
  local desc = FruitUtil.fruitIndexToDesc[fruitId]
  local cutShortId = ids.cutShortId
  local maskId = ids.id
  local numMaskChannels = 3
  if value < 0.1 then
    maskId = cutShortId
    numMaskChannels = 1
  else
    if maskId == 0 then
      return 0
    end
    setDensityMaskParams(cutShortId, "greater", desc.minHarvestingGrowthState)
  end
  local x, z, widthX, widthZ, heightX, heightZ = Utils.getXZWidthAndHeight(cutShortId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
  setDensityMaskedParallelogram(cutShortId, x, z, widthX, widthZ, heightX, heightZ, 0, 1, maskId, 0, numMaskChannels, value)
  setDensityMaskParams(cutShortId, "greater", 0)
end
function Utils.updateFruitCutLongArea(fruitId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, value, force)
  local ids = g_currentMission.fruits[fruitId]
  if ids == nil or ids.cutLongId == 0 then
    return 0
  end
  local cutLongId = ids.cutLongId
  local maskId = ids.id
  local numMaskChannels = 3
  if value < 0.1 then
    maskId = cutLongId
    numMaskChannels = 2
  else
    if maskId == 0 and not force then
      return 0
    end
    setDensityMaskParams(cutLongId, "greater", 1)
  end
  local x, z, widthX, widthZ, heightX, heightZ = Utils.getXZWidthAndHeight(cutLongId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
  local ret = 0
  if force then
    if ids.id ~= 0 then
      setDensityParallelogram(ids.id, x, z, widthX, widthZ, heightX, heightZ, 0, 3, 0)
    end
    if ids.windrowId ~= 0 then
      setDensityParallelogram(ids.windrowId, x, z, widthX, widthZ, heightX, heightZ, 0, 2, 0)
    end
    ret = setDensityParallelogram(cutLongId, x, z, widthX, widthZ, heightX, heightZ, 0, 2, value)
  else
    ret = setDensityMaskedParallelogram(cutLongId, x, z, widthX, widthZ, heightX, heightZ, 0, 2, maskId, 0, numMaskChannels, value)
  end
  setDensityMaskParams(cutLongId, "greater", 0)
  return ret
end
function Utils.updateFruitWindrowArea(fruitId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, value, force)
  local ids = g_currentMission.fruits[fruitId]
  if ids == nil or ids.windrowId == 0 then
    return 0
  end
  local windrowId = ids.windrowId
  local maskId = ids.id
  local numMaskChannels = 3
  if value < 0.1 then
    maskId = windrowId
    numMaskChannels = 2
  else
    if maskId == 0 and not force then
      return 0
    end
    setDensityMaskParams(windrowId, "greater", 1)
  end
  local x, z, widthX, widthZ, heightX, heightZ = Utils.getXZWidthAndHeight(windrowId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
  local ret = 0
  if force then
    if ids.id ~= 0 then
      setDensityParallelogram(ids.id, x, z, widthX, widthZ, heightX, heightZ, 0, 3, 0)
    end
    if ids.cutLongId ~= 0 then
      setDensityParallelogram(ids.cutLongId, x, z, widthX, widthZ, heightX, heightZ, 0, 2, 0)
    end
    ret = setDensityParallelogram(windrowId, x, z, widthX, widthZ, heightX, heightZ, 0, 2, value)
  else
    ret = setDensityMaskedParallelogram(windrowId, x, z, widthX, widthZ, heightX, heightZ, 0, 2, maskId, 0, numMaskChannels, value)
  end
  setDensityMaskParams(windrowId, "greater", 0)
  return ret
end
function Utils.getFruitArea(fruitId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
  local ids = g_currentMission.fruits[fruitId]
  if ids == nil or ids.id == 0 then
    return 0, 0
  end
  local id = ids.id
  setDensityReturnValueShift(id, -1)
  local x, z, widthX, widthZ, heightX, heightZ = Utils.getXZWidthAndHeight(id, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
  local ret, total = getDensityParallelogram(id, x, z, widthX, widthZ, heightX, heightZ, 0, 3)
  setDensityReturnValueShift(id, 0)
  return ret, total
end
function Utils.getFruitCutLongArea(fruitId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
  local ids = g_currentMission.fruits[fruitId]
  if ids == nil or ids.cutLongId == 0 then
    return 0, 0
  end
  local id = ids.cutLongId
  local x, z, widthX, widthZ, heightX, heightZ = Utils.getXZWidthAndHeight(id, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
  local ret, total = getDensityParallelogram(id, x, z, widthX, widthZ, heightX, heightZ, 0, 2)
  return ret, total
end
function Utils.getFruitWindrowArea(fruitId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
  local ids = g_currentMission.fruits[fruitId]
  if ids == nil or ids.windrowId == 0 then
    return 0, 0
  end
  local id = ids.windrowId
  local x, z, widthX, widthZ, heightX, heightZ = Utils.getXZWidthAndHeight(id, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
  local ret, total = getDensityParallelogram(id, x, z, widthX, widthZ, heightX, heightZ, 0, 2)
  return ret, total
end
function Utils.updateWheatArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, value)
  return Utils.cutFruitArea(FruitUtil.FRUITTYPE_WHEAT, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, value)
end
function Utils.updateCuttedWheatArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
  Utils.updateFruitCutShortArea(FruitUtil.FRUITTYPE_WHEAT, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, 1)
end
function Utils.updateGrassAt(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, value)
  local grassId = g_currentMission.grassId
  return Utils.updateDensity(grassId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, 0, value)
end
function Utils.updateCultivatorArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
  local detailId = g_currentMission.terrainDetailId
  Utils.updateDestroyCommonArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
  return Utils.updateDensity(detailId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, g_currentMission.cultivatorChannel, 1, g_currentMission.ploughChannel, 0, g_currentMission.sowingChannel, 0, g_currentMission.sprayChannel, 0)
end
function Utils.updatePloughArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
  local detailId = g_currentMission.terrainDetailId
  Utils.updateDestroyCommonArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
  return Utils.updateDensity(detailId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, g_currentMission.ploughChannel, 1, g_currentMission.cultivatorChannel, 0, g_currentMission.sowingChannel, 0, g_currentMission.sprayChannel, 0)
end
function Utils.updateDestroyCommonArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
  for index, entry in pairs(g_currentMission.fruits) do
    local x, z, widthX, widthZ, heightX, heightZ = Utils.getXZWidthAndHeight(entry.id, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
    setDensityNewTypeIndexMode(entry.id, SET_INDEX_TO_ZERO)
    setDensityTypeIndexCompareMode(entry.id, TYPE_COMPARE_NONE)
    setDensityParallelogram(entry.id, x, z, widthX, widthZ, heightX, heightZ, 0, NUM_FRUIT_DENSITYMAP_CHANNELS, 0)
    setDensityNewTypeIndexMode(entry.id, UPDATE_INDEX)
    setDensityTypeIndexCompareMode(entry.id, TYPE_COMPARE_EQUAL)
    break
  end
  local grassId = g_currentMission.grassId
  Utils.updateDensity(grassId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, 0, 0)
end
function Utils.updateSprayArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
  local cultivatorId = g_currentMission.terrainDetailId
  local x, z, widthX, widthZ, heightX, heightZ = Utils.getXZWidthAndHeight(cultivatorId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
  setDensityMaskedParallelogram(cultivatorId, x, z, widthX, widthZ, heightX, heightZ, 3, 1, cultivatorId, 0, 1, 1)
  setDensityMaskedParallelogram(cultivatorId, x, z, widthX, widthZ, heightX, heightZ, 3, 1, cultivatorId, 1, 1, 1)
  setDensityMaskedParallelogram(cultivatorId, x, z, widthX, widthZ, heightX, heightZ, 3, 1, cultivatorId, 2, 1, 1)
end
function Utils.updateSowingArea(fruitId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
  local ids = g_currentMission.fruits[fruitId]
  if ids == nil or ids.id == 0 then
    return 0
  end
  local cultivatorId = g_currentMission.terrainDetailId
  local sowingChannel = g_currentMission.sowingChannel
  local cultivatorChannel = g_currentMission.cultivatorChannel
  local ploughChannel = g_currentMission.ploughChannel
  local x, z, widthX, widthZ, heightX, heightZ = Utils.getXZWidthAndHeight(ids.id, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
  setDensityMaskedParallelogram(ids.id, x, z, widthX, widthZ, heightX, heightZ, 0, 3, cultivatorId, cultivatorChannel, 1, 1)
  setDensityMaskedParallelogram(ids.id, x, z, widthX, widthZ, heightX, heightZ, 0, 3, cultivatorId, ploughChannel, 1, 1)
  local x, z, widthX, widthZ, heightX, heightZ = Utils.getXZWidthAndHeight(cultivatorId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
  local area1, numPixels1 = setDensityMaskedParallelogram(cultivatorId, x, z, widthX, widthZ, heightX, heightZ, sowingChannel, 1, cultivatorId, cultivatorChannel, 1, 1)
  local area2, numPixels2 = setDensityMaskedParallelogram(cultivatorId, x, z, widthX, widthZ, heightX, heightZ, sowingChannel, 1, cultivatorId, ploughChannel, 1, 1)
  setDensityParallelogram(cultivatorId, x, z, widthX, widthZ, heightX, heightZ, cultivatorChannel, 1, 0)
  setDensityParallelogram(cultivatorId, x, z, widthX, widthZ, heightX, heightZ, ploughChannel, 1, 0)
  return numPixels1 + numPixels2
end
function Utils.updateMeadowArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
  Utils.updateFruitCutLongArea(FruitUtil.FRUITTYPE_GRASS, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, 1)
  return Utils.cutFruitArea(FruitUtil.FRUITTYPE_GRASS, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, 0)
end
function Utils.updateCuttedMeadowArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
  local area = Utils.updateFruitCutLongArea(FruitUtil.FRUITTYPE_DRYGRASS, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, 0)
  area = area + g_currentMission.windrowCutLongRatio * Utils.updateFruitWindrowArea(FruitUtil.FRUITTYPE_DRYGRASS, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, 0)
  area = area + Utils.updateFruitCutLongArea(FruitUtil.FRUITTYPE_GRASS, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, 0)
  return area + g_currentMission.windrowCutLongRatio * Utils.updateFruitWindrowArea(FruitUtil.FRUITTYPE_GRASS, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, 0)
end
function Utils.updateDensity(id, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, channel, value, channel2, value2, channel3, value3, channel4, value4)
  local x, z, widthX, widthZ, heightX, heightZ = Utils.getXZWidthAndHeight(id, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
  local returnValues = {}
  if channel2 ~= nil and value2 ~= nil then
    returnValues[2] = setDensityParallelogram(id, x, z, widthX, widthZ, heightX, heightZ, channel2, 1, value2)
    if channel3 ~= nil and value3 ~= nil then
      returnValues[3] = setDensityParallelogram(id, x, z, widthX, widthZ, heightX, heightZ, channel3, 1, value3)
      if channel4 ~= nil and value4 ~= nil then
        returnValues[4] = setDensityParallelogram(id, x, z, widthX, widthZ, heightX, heightZ, channel4, 1, value4)
      end
    end
  end
  returnValues[1] = setDensityParallelogram(id, x, z, widthX, widthZ, heightX, heightZ, channel, 1, value)
  return unpack(returnValues)
end
function Utils.getDensity(id, channel, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
  local x, z, widthX, widthZ, heightX, heightZ = Utils.getXZWidthAndHeight(id, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
  return getDensityParallelogram(id, x, z, widthX, widthZ, heightX, heightZ, channel, 1)
end
function Utils.getXZWidthAndHeight(id, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
  return startWorldX, startWorldZ, widthWorldX - startWorldX, widthWorldZ - startWorldZ, heightWorldX - startWorldX, heightWorldZ - startWorldZ
end
function Utils.vector2Length(x, y)
  return math.sqrt(x * x + y * y)
end
function Utils.vector3Length(x, y, z)
  return math.sqrt(x * x + y * y + z * z)
end
function Utils.dotProduct(ax, ay, az, bx, by, bz)
  return ax * bx + ay * by + az * bz
end
function Utils.crossProduct(ax, ay, az, bx, by, bz)
  return ay * bz - az * by, az * bx - ax * bz, ax * by - ay * bx
end
function Utils.projectOnLine(px, pz, lineX, lineZ, lineDirX, lineDirZ)
  local dx, dz = px - lineX, pz - lineZ
  local dot = dx * lineDirX + dz * lineDirZ
  return lineX + lineDirX * dot, lineZ + lineDirZ * dot
end
function Utils.getYRotationFromDirection(dx, dz)
  return math.atan2(dx, dz)
end
function Utils.clamp(value, minVal, maxVal)
  return math.min(math.max(value, minVal), maxVal)
end
function Utils.degToRad(deg)
  if deg ~= nil then
    return math.rad(deg)
  else
    return 0
  end
end
function Utils.getNoNil(value, setTo)
  if value == nil then
    return setTo
  end
  return value
end
function Utils.getVectorFromString(input)
  if input == nil then
    return nil
  end
  local strings = Utils.splitString(" ", input)
  local results = {}
  for i = 1, table.getn(strings) do
    table.insert(results, tonumber(strings[i]))
  end
  return unpack(results)
end
function Utils.getVectorNFromString(input, num)
  if input == nil then
    return nil
  end
  local strings = Utils.splitString(" ", input)
  if num > table.getn(strings) then
    return nil
  end
  local results = {}
  for i = 1, num do
    table.insert(results, tonumber(strings[i]))
  end
  return results
end
function Utils.getRadiansFromString(input, num)
  if input == nil then
    return nil
  end
  local strings = Utils.splitString(" ", input)
  if num > table.getn(strings) then
    return nil
  end
  local results = {}
  for i = 1, num do
    table.insert(results, math.rad(tonumber(strings[i])))
  end
  return results
end
function Utils.splitString(splitPattern, text)
  local results = {}
  local start = 1
  local splitStart, splitEnd = string.find(text, splitPattern, start)
  while splitStart ~= nil do
    table.insert(results, string.sub(text, start, splitStart - 1))
    start = splitEnd + 1
    splitStart, splitEnd = string.find(text, splitPattern, start)
  end
  table.insert(results, string.sub(text, start))
  return results
end
function Utils.sign(x)
  if 0 < x then
    return 1
  elseif x < 0 then
    return -1
  end
  return 0
end
function Utils.getMovedLimitedValues(currentValues, maxValues, minValues, numValues, speed, dt, inverted)
  local ret = {}
  for i = 1, numValues do
    local limitF = math.min
    local limitF2 = math.max
    local maxVal = maxValues[i]
    local minVal = minValues[i]
    if inverted then
      maxVal = minVal
      minVal = maxValues[i]
    end
    if maxVal < minVal then
      limitF = math.max
      limitF2 = math.min
    end
    ret[i] = limitF2(limitF(currentValues[i] + (maxVal - minVal) / speed * dt, maxVal), minVal)
  end
  return ret
end
function Utils.loadParticleSystem(xmlFile, particleSystems, baseString, linkNodes, defaultEmittingState, defaultPsFile, baseDir)
  local defaultLinkNode = linkNodes
  if type(linkNodes) == "table" then
    defaultLinkNode = linkNodes[1].node
  end
  local linkNode = Utils.getNoNil(Utils.indexToObject(linkNodes, getXMLString(xmlFile, baseString .. "#node")), defaultLinkNode)
  local psFile = getXMLString(xmlFile, baseString .. "#file")
  if psFile == nil then
    psFile = defaultPsFile
  end
  if psFile == nil then
    return
  end
  psFile = Utils.getFilename(psFile, baseDir)
  local rootNode = loadI3DFile(psFile)
  if rootNode == 0 then
    print("Error: failed to load particle system " .. psFile)
    return
  end
  link(linkNode, rootNode)
  local posX, posY, posZ = Utils.getVectorFromString(getXMLString(xmlFile, baseString .. "#position"))
  if posX ~= nil and posY ~= nil and posZ ~= nil then
    setTranslation(rootNode, posX, posY, posZ)
  end
  local rotX, rotY, rotZ = Utils.getVectorFromString(getXMLString(xmlFile, baseString .. "#rotation"))
  if rotX ~= nil and rotY ~= nil and rotZ ~= nil then
    rotX = Utils.degToRad(rotX)
    rotY = Utils.degToRad(rotY)
    rotZ = Utils.degToRad(rotZ)
    setRotation(rootNode, rotX, rotY, rotZ)
  end
  for i = getNumOfChildren(rootNode) - 1, 0, -1 do
    local child = getChildAt(rootNode, i)
    if getClassName(child) == "Shape" then
      local geometry = getGeometry(child)
      if geometry ~= 0 and getClassName(geometry) == "ParticleSystem" then
        local emitterShape = getEmitterShape(geometry)
        local emitterParent = getParent(shape)
        if getParent(emitterShape) == child then
          setTranslation(emitterShape, getTranslation(child))
          setRotation(emitterShape, getRotation(child))
          link(rootNode, emitterShape)
        end
        link(getRootNode(), child)
        setTranslation(child, 0, 0, 0)
        setRotation(child, 0, 0, 0)
        table.insert(particleSystems, {geometry = geometry, shape = child})
        if defaultEmittingState ~= nil then
          setEmittingState(geometry, defaultEmittingState)
        end
      end
    end
  end
  return rootNode
end
function Utils.deleteParticleSystem(particleSystems)
  for k, v in pairs(particleSystems) do
    delete(v.shape)
  end
end
function Utils.setEmittingState(particleSystems, state)
  if particleSystems ~= nil then
    for k, v in pairs(particleSystems) do
      setEmittingState(v.geometry, state)
    end
  end
end
Utils.sharedI3DFiles = {}
function Utils.loadSharedI3DFile(filename, baseDir)
  local filename = Utils.getFilename(filename, baseDir)
  local sharedI3D = Utils.sharedI3DFiles[filename]
  if sharedI3D == nil then
    sharedI3D = loadI3DFile(filename, false)
    Utils.sharedI3DFiles[filename] = sharedI3D
  end
  return clone(sharedI3D, false)
end
function Utils.deleteSharedI3DFiles()
  for i = 1, table.getn(Utils.sharedI3DFiles) do
    delete(Utils.sharedI3DFiles[i])
  end
  Utils.sharedI3DFiles = {}
end
function Utils.getMSAAIndex(msaa)
  local currentMSAAIndex = 1
  if msaa == 2 then
    currentMSAAIndex = 2
  end
  if msaa == 4 then
    currentMSAAIndex = 3
  end
  if msaa == 8 then
    currentMSAAIndex = 4
  end
  return currentMSAAIndex
end
function Utils.getAnsioIndex(ansio)
  local currentAnisoIndex = 1
  if ansio == 2 then
    currentAnisoIndex = 2
  end
  if ansio == 4 then
    currentAnisoIndex = 3
  end
  if ansio == 8 then
    currentAnisoIndex = 4
  end
  return currentAnisoIndex
end
function Utils.getProfileClassIndex(profileClass)
  local currentProfileIndex = 1
  if profileClass == "low" then
    currentProfileIndex = 2
  end
  if profileClass == "medium" then
    currentProfileIndex = 3
  end
  if profileClass == "high" then
    currentProfileIndex = 4
  end
  if profileClass == "very high" then
    currentProfileIndex = 5
  end
  return currentProfileIndex
end
function Utils.getProfileClassId()
  local index = Utils.getProfileClassIndex(getGPUPerformanceClass():lower())
  if index == 1 then
    index = Utils.getProfileClassIndex(getAutoGPUPerformanceClass():lower())
  end
  return index - 1
end
function Utils.getTimeScaleIndex(timeScale)
  local timeScaleIndex = 1
  if timeScale == 4 then
    timeScaleIndex = 2
  end
  if timeScale == 16 then
    timeScaleIndex = 3
  end
  if timeScale == 32 then
    timeScaleIndex = 4
  end
  if timeScale == 60 then
    timeScaleIndex = 5
  end
  return timeScaleIndex
end
function Utils.getLineLineIntersection2D(x1, z1, dirX1, dirZ1, x2, z2, dirX2, dirZ2)
  local div = dirX1 * dirZ2 - dirX2 * dirZ1
  if math.abs(div) < 1.0E-5 then
    return false
  end
  local t1 = (dirX2 * (z1 - z2) - dirZ2 * (x1 - x2)) / div
  local t2 = (dirX1 * (z1 - z2) - dirZ1 * (x1 - x2)) / div
  return true, t1, t2
end
function Utils.getFilename(filename, baseDir)
  if filename:sub(1, 1) == "$" then
    return filename:sub(2), false
  elseif baseDir == nil then
    return filename, false
  end
  return baseDir .. filename, true
end
function Utils.setWorldTranslation(node, x, y, z)
  local parent = getParent(node)
  if parent ~= 0 then
    x, y, z = worldToLocal(parent, x, y, z)
  end
  setTranslation(node, x, y, z)
end
function Utils.setWorldDirection(node, dirX, dirY, dirZ, upX, upY, upZ)
  local parent = getParent(node)
  if parent ~= 0 then
    dirX, dirY, dirZ = worldDirectionToLocal(parent, dirX, dirY, dirZ)
    upX, upY, upZ = worldDirectionToLocal(parent, upX, upY, upZ)
  end
  setDirection(node, dirX, dirY, dirZ, upX, upY, upZ)
end
function Utils.getXMLI18N(xmlFile, baseKey, defaultValue)
  local val = getXMLString(xmlFile, baseKey .. "." .. g_languageShort)
  if val == nil then
    local s = getXMLString(xmlFile, baseKey)
    if s ~= nil and s:sub(1, 6) == "$i10n_" then
      val = g_i18n:getText(s:sub(7))
    end
  end
  if val == nil then
    val = defaultValue
  end
  return val
end
Utils.encodeEntities = {
  ["<"] = "&lt;",
  [">"] = "&gt;",
  ä = "&auml;",
  à = "&agrave;",
  â = "&acirc;",
  é = "&eacute;",
  è = "&egrave;",
  ê = "&ecirc;",
  ë = "&euml;",
  î = "&icirc;",
  ï = "&iuml;",
  ô = "&ocirc;",
  ö = "&ouml;",
  ù = "&ugrave;",
  û = "&ucirc;",
  ü = "&uuml;",
  ÿ = "&yuml;",
  À = "&Agrave;",
  Â = "&Acirc;",
  É = "&Eacute;",
  È = "&Egrave;",
  Ê = "&Ecirc;",
  Ë = "&Euml;",
  Î = "&Icirc;",
  Ï = "&Iuml;",
  Ô = "&Ocirc;",
  Ö = "&Ouml;",
  Ù = "&Ugrave;",
  Û = "&Ucirc;",
  ç = "&ccedil;",
  Ç = "&Ccedil;",
  ["\159"] = "&Yuml;",
  ["\171"] = "&laquo;",
  ["\187"] = "&raquo;",
  ["\169"] = "&copy;",
  ["\174"] = "&reg;",
  æ = "&aelig;",
  Æ = "&AElig;",
  ["\140"] = "&OElig;",
  ["\156"] = "&oelig;"
}
function Utils.encodeToHTML(str)
  local encodedString = str
  encodedString = string.gsub(encodedString, "&", "&amp;")
  return encodedString
end
Utils.decodeEntities = {
  amp = "&",
  auml = "\228",
  agrave = "\224",
  acirc = "\226",
  eacute = "\233",
  egrave = "\232",
  ecirc = "\234",
  euml = "\235",
  icirc = "\238",
  iuml = "\239",
  ocirc = "\244",
  ouml = "\246",
  ugrave = "\249",
  ucirc = "\251",
  uuml = "\252",
  yuml = "\255",
  Agrave = "\192",
  Acirc = "\194",
  Eacute = "\201",
  Egrave = "\200",
  Ecirc = "\202",
  Euml = "\203",
  Icirc = "\206",
  Iuml = "\207",
  Ocirc = "\212",
  Ouml = "\214",
  Ugrave = "\217",
  Ucirc = "\219",
  ccedil = "\231",
  Ccedil = "\199",
  Yuml = "\159",
  laquo = "\171",
  raquo = "\187",
  copy = "\169",
  reg = "\174",
  aelig = "\230",
  AElig = "\198",
  OElig = "\140",
  oelig = "\156"
}
function Utils.decodeFromHTML(str)
  local ReplaceEntity = function(entity)
    return Utils.decodeEntities[string.sub(entity, 2, -2)] or entity
  end
  return string.gsub(str, "&%a+;", ReplaceEntity)
end

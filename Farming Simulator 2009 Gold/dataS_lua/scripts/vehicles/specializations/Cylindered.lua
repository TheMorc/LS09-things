Cylindered = {}
function Cylindered.prerequisitesPresent(specializations)
  return true
end
function Cylindered:load(xmlFile)
  self.setMovingToolDirty = SpecializationUtil.callSpecializationsFunction("setMovingToolDirty")
  local referenceNodes = {}
  self.movingParts = {}
  local i = 0
  while true do
    local baseName = string.format("vehicle.movingParts.movingPart(%d)", i)
    if not hasXMLProperty(xmlFile, baseName) then
      break
    end
    local referencePoint = Utils.indexToObject(self.components, getXMLString(xmlFile, baseName .. "#referencePoint"))
    local node = Utils.indexToObject(self.components, getXMLString(xmlFile, baseName .. "#index"))
    local referenceFrame = Utils.indexToObject(self.components, getXMLString(xmlFile, baseName .. "#referenceFrame"))
    if referencePoint ~= nil and node ~= nil and referenceFrame ~= nil then
      local entry = {}
      entry.referencePoint = referencePoint
      entry.node = node
      entry.referenceFrame = referenceFrame
      entry.invertZ = Utils.getNoNil(getXMLBool(xmlFile, baseName .. "#invertZ"), false)
      local localReferencePoint = Utils.indexToObject(self.components, getXMLString(xmlFile, baseName .. "#localReferencePoint"))
      local refX, refY, refZ = worldToLocal(node, getWorldTranslation(entry.referencePoint))
      if localReferencePoint ~= nil then
        local x, y, z = worldToLocal(node, getWorldTranslation(localReferencePoint))
        entry.referenceDistance = Utils.vector3Length(refX - x, refY - y, refZ - z)
        entry.localReferencePoint = {
          x,
          y,
          z
        }
      else
        entry.referenceDistance = 0
        entry.localReferencePoint = {
          refX,
          refY,
          refZ
        }
      end
      local refLen = Utils.vector3Length(unpack(entry.localReferencePoint))
      entry.dirCorrection = {
        entry.localReferencePoint[1] / refLen,
        entry.localReferencePoint[2] / refLen,
        entry.localReferencePoint[3] / refLen - 1
      }
      entry.localReferenceDistance = Utils.vector2Length(entry.localReferencePoint[2], entry.localReferencePoint[3])
      entry.isDirty = false
      Cylindered.loadTranslatingParts(self, xmlFile, baseName, entry)
      if referenceNodes[referencePoint] == nil then
        referenceNodes[referencePoint] = {}
      end
      table.insert(referenceNodes[referencePoint], entry)
      if referenceNodes[node] == nil then
        referenceNodes[node] = {}
      end
      table.insert(referenceNodes[node], entry)
      Cylindered.loadDependentParts(self, xmlFile, baseName, entry)
      table.insert(self.movingParts, entry)
    end
    i = i + 1
  end
  for _, part in pairs(self.movingParts) do
    part.dependentParts = {}
    for _, ref in pairs(part.dependentPartNodes) do
      if referenceNodes[ref] ~= nil then
        for _, p in pairs(referenceNodes[ref]) do
          part.dependentParts[p] = p
        end
      end
    end
  end
  function hasDependentPart(w1, w2)
    if w1.dependentParts[w2] ~= nil then
      return true
    else
      for _, v in pairs(w1.dependentParts) do
        if hasDependentPart(v, w2) then
          return true
        end
      end
    end
    return false
  end
  function movingPartsSort(w1, w2)
    if hasDependentPart(w1, w2) then
      return true
    end
  end
  table.sort(self.movingParts, movingPartsSort)
  self.nodesToMovingTools = {}
  self.movingTools = {}
  local i = 0
  while true do
    local baseName = string.format("vehicle.movingTools.movingTool(%d)", i)
    if not hasXMLProperty(xmlFile, baseName) then
      break
    end
    local node = Utils.indexToObject(self.components, getXMLString(xmlFile, baseName .. "#index"))
    if node ~= nil then
      local entry = {}
      entry.node = node
      local rotSpeed = getXMLFloat(xmlFile, baseName .. "#rotSpeed")
      if rotSpeed ~= nil then
        entry.rotSpeed = math.rad(rotSpeed) / 1000
      end
      local rotMax = getXMLFloat(xmlFile, baseName .. "#rotMax")
      if rotMax ~= nil then
        entry.rotMax = math.rad(rotMax)
      end
      local rotMin = getXMLFloat(xmlFile, baseName .. "#rotMin")
      if rotMin ~= nil then
        entry.rotMin = math.rad(rotMin)
      end
      entry.axis = getXMLString(xmlFile, baseName .. "#axis")
      entry.invertAxis = Utils.getNoNil(getXMLBool(xmlFile, baseName .. "#invertAxis"), false)
      entry.isDirty = false
      entry.rotationAxis = Utils.getNoNil(getXMLInt(xmlFile, baseName .. "#rotationAxis"), 1)
      local x, y, z = getRotation(node)
      entry.curRot = {
        x,
        y,
        z
      }
      if referenceNodes[node] == nil then
        referenceNodes[node] = {}
      end
      table.insert(referenceNodes[node], entry)
      Cylindered.loadDependentParts(self, xmlFile, baseName, entry)
      local index = getXMLInt(xmlFile, baseName .. "#componentJointIndex")
      if index ~= nil then
        local componentJoint = self.componentJoints[index + 1]
        if componentJoint ~= nil then
          entry.componentJoint = componentJoint
        end
      end
      entry.anchorActor = Utils.getNoNil(getXMLInt(xmlFile, baseName .. "#anchorActor"), 0)
      table.insert(self.movingTools, entry)
      self.nodesToMovingTools[node] = entry
    end
    i = i + 1
  end
  for _, part in pairs(self.movingTools) do
    part.dependentParts = {}
    for _, ref in pairs(part.dependentPartNodes) do
      if referenceNodes[ref] ~= nil then
        for _, p in pairs(referenceNodes[ref]) do
          part.dependentParts[p] = p
        end
      end
    end
  end
end
function Cylindered:loadDependentParts(xmlFile, baseName, entry)
  entry.dependentPartNodes = {}
  local j = 0
  while true do
    local refBaseName = baseName .. string.format(".dependentPart(%d)", j)
    if not hasXMLProperty(xmlFile, refBaseName) then
      break
    end
    local node = Utils.indexToObject(self.components, getXMLString(xmlFile, refBaseName .. "#index"))
    if node ~= nil then
      table.insert(entry.dependentPartNodes, node)
    end
    j = j + 1
  end
end
function Cylindered:loadTranslatingParts(xmlFile, baseName, entry)
  entry.translatingParts = {}
  local j = 0
  while true do
    local refBaseName = baseName .. string.format(".translatingPart(%d)", j)
    if not hasXMLProperty(xmlFile, refBaseName) then
      break
    end
    local node = Utils.indexToObject(self.components, getXMLString(xmlFile, refBaseName .. "#index"))
    if node ~= nil then
      local transEntry = {}
      transEntry.node = node
      local x, y, z = getTranslation(node)
      transEntry.startPos = {
        x,
        y,
        z
      }
      local x, y, z = worldToLocal(entry.node, getWorldTranslation(entry.referencePoint))
      transEntry.length = z
      table.insert(entry.translatingParts, transEntry)
    end
    j = j + 1
  end
end
function Cylindered:delete()
end
function Cylindered:loadFromAttributesAndNodes(xmlFile, key, resetVehicles)
  return BaseMission.VEHICLE_LOAD_OK
end
function Cylindered:getSaveAttributesAndNodes(nodeIdent)
end
function Cylindered:mouseEvent(posX, posY, isDown, isUp, button)
end
function Cylindered:keyEvent(unicode, sym, modifier, isDown)
end
function Cylindered:update(dt)
  if self:getIsActive() and self:getIsActiveForInput() then
    for i = 1, table.getn(self.movingTools) do
      local tool = self.movingTools[i]
      if tool.axis ~= nil and tool.rotSpeed ~= nil then
        local move = InputBinding.getAnalogInputAxis(InputBinding[tool.axis])
        if InputBinding.isAxisZero(move) then
          move = InputBinding.getDigitalInputAxis(InputBinding[tool.axis])
        end
        if tool.invertAxis then
          move = -move
        end
        if not InputBinding.isAxisZero(move) then
          local newRot = tool.curRot[tool.rotationAxis] + move * tool.rotSpeed * dt
          if tool.rotMax ~= nil then
            newRot = math.min(newRot, tool.rotMax)
          elseif newRot > 2 * math.pi then
            newRot = newRot - 2 * math.pi
          end
          if tool.rotMin ~= nil then
            newRot = math.max(newRot, tool.rotMin)
          elseif newRot < 0 then
            newRot = newRot + 2 * math.pi
          end
          if math.abs(newRot - tool.curRot[tool.rotationAxis]) > 1.0E-4 then
            tool.curRot[tool.rotationAxis] = newRot
            setRotation(tool.node, unpack(tool.curRot))
            Cylindered.setDirty(tool)
          end
        end
      end
    end
  end
  for _, tool in pairs(self.movingTools) do
    if tool.isDirty then
      tool.isDirty = false
      if tool.componentJoint ~= nil then
        setJointFrame(tool.componentJoint.jointIndex, tool.anchorActor, tool.componentJoint.jointNode)
      end
    end
  end
  for i, part in ipairs(self.movingParts) do
    if part.isDirty then
      Cylindered.updateMovingPart(self, part)
    end
  end
end
function Cylindered:draw()
end
function Cylindered:setMovingToolDirty(node)
  local tool = self.nodesToMovingTools[node]
  if tool ~= nil then
    Cylindered.setDirty(tool)
  end
end
function Cylindered.setDirty(part)
  if not part.isDirty then
    part.isDirty = true
    for _, v in pairs(part.dependentParts) do
      Cylindered.setDirty(v)
    end
  end
end
function Cylindered:updateMovingPart(part)
  local refX, refY, refZ = getWorldTranslation(part.referencePoint)
  local dirX, dirY, dirZ = 0, 0, 0
  if part.referenceDistance == 0 then
    local x, y, z = getWorldTranslation(part.node)
    dirX, dirY, dirZ = refX - x, refY - y, refZ - z
  else
    local r1 = part.localReferenceDistance
    local r2 = part.referenceDistance
    local lx, ly, lz = worldToLocal(part.node, refX, refY, refZ)
    local ix, iy, i2x, i2y = Utils.getCircleCircleIntersection(0, 0, r1, ly, lz, r2)
    if ix ~= nil then
      if i2x ~= nil and math.abs(i2y) > math.abs(iy) then
        iy = i2y
        ix = i2x
      end
      dirX, dirY, dirZ = localDirectionToWorld(part.node, 0, ix, iy)
    end
  end
  if dirX ~= 0 or dirY ~= 0 or dirZ ~= 0 then
    local len = Utils.vector3Length(dirX, dirY, dirZ)
    local upX, upY, upZ = localDirectionToWorld(part.referenceFrame, 0, 1, 0)
    if part.invertZ then
      dirX = -dirX
      dirY = -dirY
      dirZ = -dirZ
    end
    Utils.setWorldDirection(part.node, dirX / len, dirY / len, dirZ / len, upX, upY, upZ)
  end
  if part.translatingParts[1] ~= nil then
    local translatingPart = part.translatingParts[1]
    local lx, ly, dist = worldToLocal(part.node, refX, refY, refZ)
    local newZ = dist - translatingPart.length + translatingPart.startPos[3]
    setTranslation(part.translatingParts[1].node, translatingPart.startPos[1], translatingPart.startPos[2], newZ)
  end
  part.isDirty = false
end

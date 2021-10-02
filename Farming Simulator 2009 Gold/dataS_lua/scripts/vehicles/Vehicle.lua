Vehicle = {}
Vehicle.springScale = 10
Vehicle.NUM_JOINTTYPES = 0
Vehicle.jointTypeNameToInt = {}
Vehicle.defaultWidth = 8
Vehicle.defaultLength = 8
function Vehicle.registerJointType(name)
  local key = "JOINTTYPE_" .. string.upper(name)
  if Vehicle[key] == nil then
    Vehicle.NUM_JOINTTYPES = Vehicle.NUM_JOINTTYPES + 1
    Vehicle[key] = Vehicle.NUM_JOINTTYPES
    Vehicle.jointTypeNameToInt[name] = Vehicle.NUM_JOINTTYPES
  end
end
Vehicle.registerJointType("implement")
Vehicle.registerJointType("trailer")
Vehicle.registerJointType("trailerLow")
function Vehicle:new(configFile, baseDirectory, positionX, offsetY, positionZ, yRot, specializations, customMt)
  if Vehicle_mt == nil then
    Vehicle_mt = Class(Vehicle)
  end
  local instance = {}
  if customMt ~= nil then
    setmetatable(instance, customMt)
  else
    setmetatable(instance, Vehicle_mt)
  end
  instance.configFileName = configFile
  instance.baseDirectory = baseDirectory
  local xmlFile = loadXMLFile("TempConfig", configFile)
  local i3dNode = Utils.loadSharedI3DFile(getXMLString(xmlFile, "vehicle.filename"), baseDirectory)
  instance.rootNode = getChildAt(i3dNode, 0)
  local tempRootNode = createTransformGroup("tempRootNode")
  instance.components = {}
  local numComponents = Utils.getNoNil(getXMLInt(xmlFile, "vehicle.components#count"), 1)
  local rootX, rootY, rootZ
  for i = 1, numComponents do
    table.insert(instance.components, {
      node = getChildAt(i3dNode, 0)
    })
    link(tempRootNode, instance.components[i].node)
    if i == 1 then
      rootX, rootY, rootZ = getTranslation(instance.components[i].node)
    end
    translate(instance.components[i].node, -rootX, -rootY, -rootZ)
    instance.components[i].originalTranslation = {
      getTranslation(instance.components[i].node)
    }
    instance.components[i].originalRotation = {
      getRotation(instance.components[i].node)
    }
  end
  delete(i3dNode)
  local terrainHeight = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, positionX, 300, positionZ)
  setTranslation(tempRootNode, positionX, terrainHeight + offsetY, positionZ)
  setRotation(tempRootNode, 0, yRot, 0)
  for i = 1, numComponents do
    local x, y, z = getWorldTranslation(instance.components[i].node)
    local rx, ry, rz = getWorldRotation(instance.components[i].node)
    setTranslation(instance.components[i].node, x, y, z)
    setRotation(instance.components[i].node, rx, ry, rz)
    link(getRootNode(), instance.components[i].node)
  end
  delete(tempRootNode)
  instance.maxRotTime = 0
  instance.minRotTime = 0
  instance.autoRotateBackSpeed = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.wheels#autoRotateBackSpeed"), 1)
  instance.wheels = {}
  local i = 0
  while true do
    local wheelnamei = string.format("vehicle.wheels.wheel(%d)", i)
    local wheel = {}
    local reprStr = getXMLString(xmlFile, wheelnamei .. "#repr")
    if reprStr == nil then
      break
    end
    wheel.repr = Utils.indexToObject(instance.components, reprStr)
    if wheel.repr == nil then
      print("Error: invalid wheel repr " .. reprStr)
    else
      wheel.rotSpeed = Utils.degToRad(getXMLFloat(xmlFile, wheelnamei .. "#rotSpeed"))
      wheel.rotMax = Utils.degToRad(getXMLFloat(xmlFile, wheelnamei .. "#rotMax"))
      wheel.rotMin = Utils.degToRad(getXMLFloat(xmlFile, wheelnamei .. "#rotMin"))
      wheel.driveMode = Utils.getNoNil(getXMLInt(xmlFile, wheelnamei .. "#driveMode"), 0)
      wheel.driveNode = Utils.indexToObject(instance.components, getXMLString(xmlFile, wheelnamei .. "#driveNode"))
      if wheel.driveNode == nil then
        wheel.driveNode = wheel.repr
      end
      local radius = Utils.getNoNil(getXMLFloat(xmlFile, wheelnamei .. "#radius"), 1)
      local positionX, positionY, positionZ = getTranslation(wheel.repr)
      wheel.deltaY = Utils.getNoNil(getXMLFloat(xmlFile, wheelnamei .. "#deltaY"), 0)
      positionY = positionY + wheel.deltaY
      local suspTravel = Utils.getNoNil(getXMLFloat(xmlFile, wheelnamei .. "#suspTravel"), 0)
      local spring = Utils.getNoNil(getXMLFloat(xmlFile, wheelnamei .. "#spring"), 0) * Vehicle.springScale
      local damper = Utils.getNoNil(getXMLFloat(xmlFile, wheelnamei .. "#damper"), 0)
      local mass = Utils.getNoNil(getXMLFloat(xmlFile, wheelnamei .. "#mass"), 0.01)
      wheel.steeringAxleScale = Utils.getNoNil(getXMLFloat(xmlFile, wheelnamei .. "#steeringAxleScale"), 0)
      wheel.steeringAxleRotMax = Utils.degToRad(Utils.getNoNil(getXMLFloat(xmlFile, wheelnamei .. "#steeringAxleRotMax"), 20))
      wheel.steeringAxleRotMin = Utils.degToRad(Utils.getNoNil(getXMLFloat(xmlFile, wheelnamei .. "#steeringAxleRotMin"), -20))
      wheel.lateralStiffness = Utils.getNoNil(getXMLFloat(xmlFile, wheelnamei .. "#lateralStiffness"), 22)
      wheel.longitudalStiffness = Utils.getNoNil(getXMLFloat(xmlFile, wheelnamei .. "#longitudalStiffness"), 1)
      wheel.steeringAngle = 0
      wheel.hasGroundContact = false
      wheel.axleSpeed = 0
      wheel.hasHandbrake = true
      wheel.node = getParent(wheel.repr)
      wheel.wheelShape = createWheelShape(wheel.node, positionX, positionY, positionZ, radius, suspTravel, spring, damper, mass)
      setWheelShapeTireFunction(wheel.node, wheel.wheelShape, false, 1000000 * wheel.lateralStiffness)
      setWheelShapeTireFunction(wheel.node, wheel.wheelShape, true, 1000000 * wheel.longitudalStiffness)
      local maxRotTime = wheel.rotMax / wheel.rotSpeed
      local minRotTime = wheel.rotMin / wheel.rotSpeed
      if maxRotTime < minRotTime then
        local temp = minRotTime
        minRotTime = maxRotTime
        maxRotTime = temp
      end
      if maxRotTime > instance.maxRotTime then
        instance.maxRotTime = maxRotTime
      end
      if minRotTime < instance.minRotTime then
        instance.minRotTime = minRotTime
      end
      table.insert(instance.wheels, wheel)
    end
    i = i + 1
  end
  instance.lastWheelRpm = 0
  instance.movingDirection = 0
  instance.steeringAxleNode = Utils.indexToObject(instance.components, getXMLString(xmlFile, "vehicle.steeringAxleNode#index"))
  if instance.steeringAxleNode == nil then
    instance.steeringAxleNode = instance.components[1].node
  end
  instance.downForce = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.downForce"), 0)
  instance.sizeWidth = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.size#width"), Vehicle.defaultWidth)
  instance.sizeLength = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.size#length"), Vehicle.defaultLength)
  instance.widthOffset = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.size#widthOffset"), 0)
  instance.lengthOffset = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.size#lengthOffset"), 0)
  instance.typeDesc = Utils.getXMLI18N(xmlFile, "vehicle.typeDesc", "TypeDescription")
  local numLights = Utils.getNoNil(getXMLInt(xmlFile, "vehicle.lights#count"), 0)
  instance.lights = {}
  for i = 1, numLights do
    local lightnamei = string.format("vehicle.lights.light%d", i)
    instance.lights[i] = Utils.indexToObject(instance.components, getXMLString(xmlFile, lightnamei .. "#index"))
    setVisibility(instance.lights[i], false)
  end
  local numCuttingAreas = Utils.getNoNil(getXMLInt(xmlFile, "vehicle.cuttingAreas#count"), 0)
  instance.cuttingAreas = {}
  for i = 1, numCuttingAreas do
    instance.cuttingAreas[i] = {}
    local areanamei = string.format("vehicle.cuttingAreas.cuttingArea%d", i)
    instance.cuttingAreas[i].start = Utils.indexToObject(instance.components, getXMLString(xmlFile, areanamei .. "#startIndex"))
    instance.cuttingAreas[i].width = Utils.indexToObject(instance.components, getXMLString(xmlFile, areanamei .. "#widthIndex"))
    instance.cuttingAreas[i].height = Utils.indexToObject(instance.components, getXMLString(xmlFile, areanamei .. "#heightIndex"))
  end
  local attachSound = getXMLString(xmlFile, "vehicle.attachSound#file")
  if attachSound ~= nil and attachSound ~= "" then
    attachSound = Utils.getFilename(attachSound, self.baseDirectory)
    instance.attachSound = createSample("attachSound")
    loadSample(instance.attachSound, attachSound, false)
    instance.attachSoundPitchOffset = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.attachSound#pitchOffset"), 0)
  end
  local x = getXMLFloat(xmlFile, "vehicle.centerOfMass#x")
  local y = getXMLFloat(xmlFile, "vehicle.centerOfMass#y")
  local z = getXMLFloat(xmlFile, "vehicle.centerOfMass#z")
  if x ~= nil and y ~= nil and z ~= nil then
    print("Warning: vehicle.centerOfMass is deprecated, please update to vehicle.components.componenti.centerOfMass")
    setCenterOfMass(instance.components[1].node, x, y, z)
    instance.components[1].centerOfMass = {
      x,
      y,
      z
    }
  end
  for i = 1, numComponents do
    local namei = string.format("vehicle.components.component%d", i)
    local x, y, z = Utils.getVectorFromString(getXMLString(xmlFile, namei .. "#centerOfMass"))
    if x ~= nil and y ~= nil and z ~= nil then
      setCenterOfMass(instance.components[i].node, x, y, z)
      instance.components[i].centerOfMass = {
        x,
        y,
        z
      }
    end
    local count = getXMLInt(xmlFile, namei .. "#solverIterationCount")
    if count ~= nil then
      setSolverIterationCount(instance.components[i].node, count)
      instance.components[i].solverIterationCount = count
    end
  end
  instance.componentJoints = {}
  local componentJointI = 0
  while true do
    local key = string.format("vehicle.components.joint(%d)", componentJointI)
    local index1 = getXMLInt(xmlFile, key .. "#component1")
    local index2 = getXMLInt(xmlFile, key .. "#component2")
    local jointIndexStr = getXMLString(xmlFile, key .. "#index")
    if index1 == nil or index2 == nil or jointIndexStr == nil then
      break
    end
    local jointNode = Utils.indexToObject(instance.components, jointIndexStr)
    if jointNode ~= nil and jointNode ~= 0 then
      local constr = JointConstructor:new()
      constr:setActors(instance.components[index1 + 1].node, instance.components[index2 + 1].node)
      constr:setJointTransforms(jointNode, jointNode)
      local x, y, z = Utils.getVectorFromString(getXMLString(xmlFile, key .. "#rotLimit"))
      local rotLimits = {}
      rotLimits[1] = math.rad(Utils.getNoNil(x, 0))
      rotLimits[2] = math.rad(Utils.getNoNil(y, 0))
      rotLimits[3] = math.rad(Utils.getNoNil(z, 0))
      local x, y, z = Utils.getVectorFromString(getXMLString(xmlFile, key .. "#transLimit"))
      local transLimits = {}
      transLimits[1] = Utils.getNoNil(x, 0)
      transLimits[2] = Utils.getNoNil(y, 0)
      transLimits[3] = Utils.getNoNil(z, 0)
      for i = 1, 3 do
        local rotLimit = rotLimits[i]
        if 0 <= rotLimit then
          constr:setRotationLimit(i - 1, -rotLimit, rotLimit)
        end
        local transLimit = transLimits[i]
        if 0 <= transLimit then
          constr:setTranslationLimit(i - 1, true, -transLimit, transLimit)
        else
          constr:setTranslationLimit(i - 1, false, 0, 0)
        end
      end
      local jointDesc = {}
      jointDesc.componentIndices = {
        index1 + 1,
        index2 + 1
      }
      jointDesc.jointNode = jointNode
      jointDesc.jointIndex = constr:finalize()
      table.insert(instance.componentJoints, jointDesc)
    end
    componentJointI = componentJointI + 1
  end
  instance.attacherJoints = {}
  local i = 0
  while true do
    local baseName = string.format("vehicle.attacherJoints.attacherJoint(%d)", i)
    local index = getXMLString(xmlFile, baseName .. "#index")
    if index == nil then
      break
    end
    local object = Utils.indexToObject(instance.components, index)
    if object ~= nil then
      local entry = {}
      entry.jointTransform = object
      local jointTypeStr = getXMLString(xmlFile, baseName .. "#jointType")
      local jointType
      if jointTypeStr ~= nil then
        jointType = Vehicle.jointTypeNameToInt[jointTypeStr]
        if jointType == nil then
          print("Warning: invalid jointType " .. jointTypeStr)
        end
      end
      if jointType == nil then
        jointType = Vehicle.JOINTTYPE_IMPLEMENT
      end
      entry.jointType = jointType
      entry.allowsJointLimitMovement = Utils.getNoNil(getXMLBool(xmlFile, baseName .. "#allowsJointLimitMovement"), true)
      entry.allowsLowering = Utils.getNoNil(getXMLBool(xmlFile, baseName .. "#allowsLowering"), true)
      local x, y, z
      local rotationNode = Utils.indexToObject(instance.components, getXMLString(xmlFile, baseName .. "#rotationNode"))
      if rotationNode ~= nil then
        entry.rotationNode = rotationNode
        x, y, z = Utils.getVectorFromString(getXMLString(xmlFile, baseName .. "#maxRot"))
        entry.maxRot = {}
        entry.maxRot[1] = math.rad(Utils.getNoNil(x, 0))
        entry.maxRot[2] = math.rad(Utils.getNoNil(y, 0))
        entry.maxRot[3] = math.rad(Utils.getNoNil(z, 0))
        x, y, z = getRotation(rotationNode)
        entry.minRot = {
          x,
          y,
          z
        }
      end
      local rotationNode2 = Utils.indexToObject(instance.components, getXMLString(xmlFile, baseName .. "#rotationNode2"))
      if rotationNode2 ~= nil then
        entry.rotationNode2 = rotationNode2
        x, y, z = Utils.getVectorFromString(getXMLString(xmlFile, baseName .. "#maxRot2"))
        entry.maxRot2 = {}
        entry.maxRot2[1] = math.rad(Utils.getNoNil(x, 0))
        entry.maxRot2[2] = math.rad(Utils.getNoNil(y, 0))
        entry.maxRot2[3] = math.rad(Utils.getNoNil(z, 0))
        x, y, z = getRotation(rotationNode2)
        entry.minRot2 = {
          x,
          y,
          z
        }
      end
      x, y, z = Utils.getVectorFromString(getXMLString(xmlFile, baseName .. "#maxRotLimit"))
      entry.maxRotLimit = {}
      entry.maxRotLimit[1] = math.rad(math.abs(Utils.getNoNil(x, 0)))
      entry.maxRotLimit[2] = math.rad(math.abs(Utils.getNoNil(y, 0)))
      entry.maxRotLimit[3] = math.rad(math.abs(Utils.getNoNil(z, 0)))
      x, y, z = Utils.getVectorFromString(getXMLString(xmlFile, baseName .. "#maxTransLimit"))
      entry.maxTransLimit = {}
      entry.maxTransLimit[1] = math.abs(Utils.getNoNil(x, 0))
      entry.maxTransLimit[2] = math.abs(Utils.getNoNil(y, 0))
      entry.maxTransLimit[3] = math.abs(Utils.getNoNil(z, 0))
      entry.moveTime = Utils.getNoNil(getXMLFloat(xmlFile, baseName .. "#moveTime"), 0.5) * 1000
      local rotationNode = Utils.indexToObject(instance.components, getXMLString(xmlFile, baseName .. ".topArm#rotationNode"))
      local translationNode = Utils.indexToObject(instance.components, getXMLString(xmlFile, baseName .. ".topArm#translationNode"))
      local referenceNode = Utils.indexToObject(instance.components, getXMLString(xmlFile, baseName .. ".topArm#referenceNode"))
      if rotationNode ~= nil then
        local topArm = {}
        topArm.rotationNode = rotationNode
        topArm.rotX, topArm.rotY, topArm.rotZ = getRotation(rotationNode)
        if translationNode ~= nil and referenceNode ~= nil then
          topArm.translationNode = translationNode
          local ax, ay, az = getWorldTranslation(referenceNode)
          local bx, by, bz = getWorldTranslation(translationNode)
          topArm.referenceDistance = Utils.vector3Length(ax - bx, ay - by, az - bz)
        end
        topArm.zScale = Utils.sign(Utils.getNoNil(getXMLFloat(xmlFile, baseName .. ".topArm#zScale"), 1))
        entry.topArm = topArm
      end
      local rotationNode = Utils.indexToObject(instance.components, getXMLString(xmlFile, baseName .. ".bottomArm#rotationNode"))
      local translationNode = Utils.indexToObject(instance.components, getXMLString(xmlFile, baseName .. ".bottomArm#translationNode"))
      local referenceNode = Utils.indexToObject(instance.components, getXMLString(xmlFile, baseName .. ".bottomArm#referenceNode"))
      if rotationNode ~= nil then
        local bottomArm = {}
        bottomArm.rotationNode = rotationNode
        bottomArm.rotX, bottomArm.rotY, bottomArm.rotZ = getRotation(rotationNode)
        if translationNode ~= nil and referenceNode ~= nil then
          bottomArm.translationNode = translationNode
          local ax, ay, az = getWorldTranslation(referenceNode)
          local bx, by, bz = getWorldTranslation(translationNode)
          bottomArm.referenceDistance = Utils.vector3Length(ax - bx, ay - by, az - bz)
        end
        bottomArm.zScale = Utils.sign(Utils.getNoNil(getXMLFloat(xmlFile, baseName .. ".bottomArm#zScale"), 1))
        entry.bottomArm = bottomArm
      end
      entry.rootNode = Utils.getNoNil(Utils.indexToObject(instance.components, getXMLString(xmlFile, baseName .. "#rootNode")), instance.components[1].node)
      entry.jointIndex = 0
      table.insert(instance.attacherJoints, entry)
    end
    i = i + 1
  end
  local i = 0
  while true do
    local baseName = string.format("vehicle.trailerAttacherJoints.trailerAttacherJoint(%d)", i)
    local index = getXMLString(xmlFile, baseName .. "#index")
    if index == nil then
      break
    end
    local object = Utils.indexToObject(instance.components, index)
    if object ~= nil then
      local entry = {}
      entry.jointTransform = object
      entry.jointIndex = 0
      local isLow = Utils.getNoNil(getXMLBool(xmlFile, baseName .. "#low"), false)
      if isLow then
        entry.jointType = Vehicle.JOINTTYPE_TRAILERLOW
      else
        entry.jointType = Vehicle.JOINTTYPE_TRAILER
      end
      entry.allowsJointLimitMovement = Utils.getNoNil(getXMLBool(xmlFile, baseName .. "#allowsJointLimitMovement"), false)
      entry.allowsLowering = false
      local x, y, z = Utils.getVectorFromString(getXMLString(xmlFile, baseName .. "#maxRotLimit"))
      entry.maxRotLimit = {}
      entry.maxRotLimit[1] = Utils.degToRad(math.abs(Utils.getNoNil(x, 10)))
      entry.maxRotLimit[2] = Utils.degToRad(math.abs(Utils.getNoNil(y, 50)))
      entry.maxRotLimit[3] = Utils.degToRad(math.abs(Utils.getNoNil(z, 50)))
      x, y, z = Utils.getVectorFromString(getXMLString(xmlFile, baseName .. "#maxTransLimit"))
      entry.maxTransLimit = {}
      entry.maxTransLimit[1] = math.abs(Utils.getNoNil(x, 0))
      entry.maxTransLimit[2] = math.abs(Utils.getNoNil(y, 0))
      entry.maxTransLimit[3] = math.abs(Utils.getNoNil(z, 0))
      entry.rootNode = Utils.getNoNil(Utils.indexToObject(instance.components, getXMLString(xmlFile, baseName .. "#rootNode")), instance.components[1].node)
      table.insert(instance.attacherJoints, entry)
    end
    i = i + 1
  end
  instance.attachedImplements = {}
  instance.selectedImplement = 0
  instance.requiredDriveMode = 1
  instance.steeringAxleAngle = 0
  instance.rotatedTime = 0
  instance.firstTimeRun = false
  instance.lightsActive = false
  instance.lastPosition = nil
  instance.lastSpeed = 0
  instance.lastSpeedReal = 0
  instance.lastMovedDistance = 0
  instance.speedDisplayDt = 0
  instance.speedDisplayScale = 1
  instance.isBroken = false
  instance.checkSpeedLimit = true
  instance.lastSoundSpeed = 0
  instance.time = 0
  instance.forceIsActive = false
  instance.specializations = specializations
  for i = 1, table.getn(instance.specializations) do
    instance.specializations[i].load(instance, xmlFile)
  end
  delete(xmlFile)
  return instance
end
function Vehicle:delete()
  for i = table.getn(self.attachedImplements), 1, -1 do
    self:detachImplement(1)
  end
  for k, v in pairs(self.specializations) do
    v.delete(self)
  end
  if self.attachSound ~= nil then
    delete(self.attachSound)
  end
  for k, v in pairs(self.componentJoints) do
    removeJoint(v.jointIndex)
  end
  for k, v in pairs(self.components) do
    delete(v.node)
  end
end
function Vehicle:loadFromAttributesAndNodes(xmlFile, key, resetVehicles)
  local findPlace = resetVehicles
  if not findPlace then
    local isAbsolute = Utils.getNoNil(getXMLBool(xmlFile, key .. "#isAbsolute"), false)
    if isAbsolute then
      local pos = {}
      for i = 1, table.getn(self.components) do
        local componentKey = key .. ".component" .. i
        local x, y, z = Utils.getVectorFromString(getXMLString(xmlFile, componentKey .. "#position"))
        local xRot, yRot, zRot = Utils.getVectorFromString(getXMLString(xmlFile, componentKey .. "#rotation"))
        if x == nil or y == nil or z == nil or xRot == nil or yRot == nil or zRot == nil then
          findPlace = true
          break
        end
        pos[i] = {
          x = x,
          y = y,
          z = z,
          xRot = xRot,
          yRot = yRot,
          zRot = zRot
        }
      end
      if not findPlace then
        for i = 1, table.getn(self.components) do
          local p = pos[i]
          self:setWorldPosition(p.x, p.y, p.z, p.xRot, p.yRot, p.zRot, i)
        end
      end
    else
      local yOffset = getXMLFloat(xmlFile, key .. "#yOffset")
      local xPosition = getXMLFloat(xmlFile, key .. "#xPosition")
      local zPosition = getXMLFloat(xmlFile, key .. "#zPosition")
      local yRotation = getXMLFloat(xmlFile, key .. "#yRotation")
      if yOffset == nil or xPosition == nil or zPosition == nil or yRotation == nil then
        findPlace = true
      else
        self:setRelativePosition(xPosition, yOffset, zPosition, math.rad(yRotation))
      end
    end
  end
  if findPlace then
    if resetVehicles then
      local x, y, z, place, width, offset = PlacementUtil.getPlace(g_currentMission.loadSpawnPlaces, self.sizeWidth, self.sizeLength, self.widthOffset, self.lengthOffset, g_currentMission.usedLoadPlaces)
      if x ~= nil then
        local yRot = Utils.getYRotationFromDirection(place.dirPerpX, place.dirPerpZ)
        PlacementUtil.markPlaceUsed(g_currentMission.usedLoadPlaces, place, width)
        self:setRelativePosition(x, offset, z, yRot)
      else
        return BaseMission.VEHICLE_LOAD_ERROR
      end
    else
      return BaseMission.VEHICLE_LOAD_DELAYED
    end
  end
  for k, v in pairs(self.specializations) do
    if v.loadFromAttributesAndNodes ~= nil then
      local r = v.loadFromAttributesAndNodes(self, xmlFile, key, resetVehicles)
      if r ~= BaseMission.VEHICLE_LOAD_OK then
        return r
      end
    end
  end
  return BaseMission.VEHICLE_LOAD_OK
end
function Vehicle:getSaveAttributesAndNodes(nodeIdent)
  local attributes = "isAbsolute=\"true\""
  local nodes = ""
  if not self.isBroken then
    for i = 1, table.getn(self.components) do
      if 1 < i then
        nodes = nodes .. "\n"
      end
      local node = self.components[i].node
      local x, y, z = getTranslation(node)
      local xRot, yRot, zRot = getRotation(node)
      nodes = nodes .. nodeIdent .. "<component" .. i .. " position=\"" .. x .. " " .. y .. " " .. z .. "\" rotation=\"" .. xRot .. " " .. yRot .. " " .. zRot .. "\" />"
    end
  end
  for k, v in pairs(self.specializations) do
    if v.getSaveAttributesAndNodes ~= nil then
      local specAttributes, specNodes = v.getSaveAttributesAndNodes(self, nodeIdent)
      if specAttributes ~= nil and specAttributes ~= "" then
        attributes = attributes .. " " .. specAttributes
      end
      if specNodes ~= nil and specNodes ~= "" then
        nodes = nodes .. "\n" .. specNodes
      end
    end
  end
  return attributes, nodes
end
function Vehicle:setRelativePosition(positionX, offsetY, positionZ, yRot)
  local tempRootNode = createTransformGroup("tempRootNode")
  local numComponents = table.getn(self.components)
  for i = 1, numComponents do
    link(tempRootNode, self.components[i].node)
    setTranslation(self.components[i].node, unpack(self.components[i].originalTranslation))
    setRotation(self.components[i].node, unpack(self.components[i].originalRotation))
  end
  local terrainHeight = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, positionX, 300, positionZ)
  setTranslation(tempRootNode, positionX, terrainHeight + offsetY, positionZ)
  setRotation(tempRootNode, 0, yRot, 0)
  for i = 1, numComponents do
    local x, y, z = getWorldTranslation(self.components[i].node)
    local rx, ry, rz = getWorldRotation(self.components[i].node)
    setTranslation(self.components[i].node, x, y, z)
    setRotation(self.components[i].node, rx, ry, rz)
    link(getRootNode(), self.components[i].node)
  end
  delete(tempRootNode)
  for k, v in pairs(self.specializations) do
    if v.setRelativePosition ~= nil then
      v.setRelativePosition(self, positionX, offsetY, positionZ, yRot)
    end
  end
end
function Vehicle:setWorldPosition(x, y, z, xRot, yRot, zRot, i)
  setTranslation(self.components[i].node, x, y, z)
  setRotation(self.components[i].node, xRot, yRot, zRot)
end
function Vehicle:mouseEvent(posX, posY, isDown, isUp, button)
  for k, v in pairs(self.specializations) do
    v.mouseEvent(self, posX, posY, isDown, isUp, button)
  end
  if self.selectedImplement ~= 0 then
    self.attachedImplements[self.selectedImplement].object:mouseEvent(posX, posY, isDown, isUp, button)
  end
end
function Vehicle:keyEvent(unicode, sym, modifier, isDown)
  for k, v in pairs(self.specializations) do
    v.keyEvent(self, unicode, sym, modifier, isDown)
  end
  if self.selectedImplement ~= 0 then
    self.attachedImplements[self.selectedImplement].object:keyEvent(unicode, sym, modifier, isDown)
  end
end
function Vehicle:update(dt, isActive)
  self.time = self.time + dt
  self.isActive = self:getIsActive()
  self.speedDisplayDt = self.speedDisplayDt + dt
  if self.speedDisplayDt > 100 then
    local newX, newY, newZ = getWorldTranslation(self.components[1].node)
    if self.lastPosition == nil then
      self.lastPosition = {
        newX,
        newY,
        newZ
      }
    end
    local dx, dy, dz = worldDirectionToLocal(self.components[1].node, newX - self.lastPosition[1], newY - self.lastPosition[2], newZ - self.lastPosition[3])
    if 0.01 < dz then
      self.movingDirection = 1
    elseif dz < -0.01 then
      self.movingDirection = -1
    else
      self.movingDirection = 0
    end
    self.lastMovedDistance = Utils.vector3Length(dx, dy, dz)
    self.lastSpeedReal = self.lastMovedDistance / self.speedDisplayDt
    self.lastSpeed = self.lastSpeed * 0.85 + self.lastSpeedReal * 0.15
    self.lastPosition = {
      newX,
      newY,
      newZ
    }
    self.speedDisplayDt = self.speedDisplayDt - 100
  end
  if self.downForce ~= 0 then
    local worldX, worldY, worldZ = localDirectionToWorld(self.components[1].node, 0, -self.downForce * dt / 1000, 0)
    addForce(self.components[1].node, worldX, worldY, worldZ, 0, 0, 0, true)
  end
  if self.isActive then
    for k, implement in pairs(self.attachedImplements) do
      local jointDesc = self.attacherJoints[implement.jointDescIndex]
      local attacherJoint = implement.object.attacherJoint
      if jointDesc.topArm ~= nil and attacherJoint.topReferenceNode ~= nil then
        local ax, ay, az = getWorldTranslation(jointDesc.topArm.rotationNode)
        local bx, by, bz = getWorldTranslation(attacherJoint.topReferenceNode)
        if bx == nil then
          print("error: ", getName(self.components[1].node))
          printCallstack()
        end
        local x, y, z = worldDirectionToLocal(getParent(jointDesc.topArm.rotationNode), bx - ax, by - ay, bz - az)
        setDirection(jointDesc.topArm.rotationNode, x * jointDesc.topArm.zScale, y * jointDesc.topArm.zScale, z * jointDesc.topArm.zScale, 0, 1, 0)
        if jointDesc.topArm.translationNode ~= nil then
          local distance = Utils.vector3Length(ax - bx, ay - by, az - bz)
          setTranslation(jointDesc.topArm.translationNode, 0, 0, (distance - jointDesc.topArm.referenceDistance) * jointDesc.topArm.zScale)
        end
      end
      if jointDesc.bottomArm ~= nil then
        local ax, ay, az = getWorldTranslation(jointDesc.bottomArm.rotationNode)
        local bx, by, bz = getWorldTranslation(attacherJoint.node)
        local x, y, z = worldDirectionToLocal(getParent(jointDesc.bottomArm.rotationNode), bx - ax, by - ay, bz - az)
        setDirection(jointDesc.bottomArm.rotationNode, x * jointDesc.bottomArm.zScale, y * jointDesc.bottomArm.zScale, z * jointDesc.bottomArm.zScale, 0, 1, 0)
        if jointDesc.bottomArm.translationNode ~= nil then
          local distance = Utils.vector3Length(ax - bx, ay - by, az - bz)
          setTranslation(jointDesc.bottomArm.translationNode, 0, 0, (distance - jointDesc.bottomArm.referenceDistance) * jointDesc.bottomArm.zScale)
        end
      end
    end
    for k, implement in pairs(self.attachedImplements) do
      local jointDesc = self.attacherJoints[implement.jointDescIndex]
      local jointFrameInvalid = false
      if jointDesc.rotationNode ~= nil then
        local x, y, z = getRotation(jointDesc.rotationNode)
        local rot = {
          x,
          y,
          z
        }
        local newRot = Utils.getMovedLimitedValues(rot, jointDesc.maxRot, jointDesc.minRot, 3, jointDesc.moveTime, dt, not jointDesc.moveDown)
        setRotation(jointDesc.rotationNode, unpack(newRot))
        for i = 1, 3 do
          if math.abs(newRot[i] - rot[i]) > 0.001 then
            jointFrameInvalid = true
          end
        end
      end
      if jointDesc.rotationNode2 ~= nil then
        local x, y, z = getRotation(jointDesc.rotationNode2)
        local rot = {
          x,
          y,
          z
        }
        local newRot = Utils.getMovedLimitedValues(rot, jointDesc.maxRot2, jointDesc.minRot2, 3, jointDesc.moveTime, dt, not jointDesc.moveDown)
        setRotation(jointDesc.rotationNode2, unpack(newRot))
        for i = 1, 3 do
          if math.abs(newRot[i] - rot[i]) > 0.001 then
            jointFrameInvalid = true
          end
        end
      end
      for k, v in pairs(self.specializations) do
        if v.validateAttacherJoint ~= nil and not jointFrameInvalid then
          jointFrameInvalid = v.validateAttacherJoint(self, implement, jointDesc, dt)
        end
      end
      if jointFrameInvalid then
        setJointFrame(jointDesc.jointIndex, 0, jointDesc.jointTransform)
      end
      if jointDesc.allowsJointLimitMovement then
        local attacherJoint = implement.object.attacherJoint
        if attacherJoint.allowsJointRotLimitMovement then
          local newRotLimit = Utils.getMovedLimitedValues(implement.jointRotLimit, implement.maxRotLimit, {
            0,
            0,
            0
          }, 3, jointDesc.moveTime, dt, not jointDesc.moveDown)
          for i = 1, 3 do
            if 0.001 < math.abs(newRotLimit[i] - implement.jointRotLimit[i]) then
              setJointRotationLimit(jointDesc.jointIndex, i - 1, true, -newRotLimit[i], newRotLimit[i])
            end
          end
          implement.jointRotLimit = newRotLimit
        end
        if attacherJoint.allowsJointTransLimitMovement then
          local newTransLimit = Utils.getMovedLimitedValues(implement.jointTransLimit, implement.maxTransLimit, {
            0,
            0,
            0
          }, 3, jointDesc.moveTime, dt, not jointDesc.moveDown)
          for i = 1, 3 do
            if 0.001 < math.abs(newTransLimit[i] - implement.jointTransLimit[i]) then
              setJointTranslationLimit(jointDesc.jointIndex, i - 1, true, -newTransLimit[i], newTransLimit[i])
            end
          end
          implement.jointTransLimit = newTransLimit
        end
      end
    end
  end
  if self.firstTimeRun then
    WheelsUtil.updateWheelsGraphics(self, dt)
  end
  for k, v in pairs(self.specializations) do
    v.update(self, dt)
  end
  self.firstTimeRun = true
end
function Vehicle:getAttachedTrailersFillLevelAndCapacity()
  local fillLevel = 0
  local capacity = 0
  local hasTrailer = false
  for k, implement in pairs(self.attachedImplements) do
    local object = implement.object
    if object.fillLevel ~= nil and object.capacity ~= nil then
      fillLevel = fillLevel + object.fillLevel
      capacity = capacity + object.capacity
      hasTrailer = true
    end
    local f, c = implement.object:getAttachedTrailersFillLevelAndCapacity()
    if f ~= nil and c ~= nil then
      fillLevel = fillLevel + f
      capacity = capacity + c
      hasTrailer = true
    end
  end
  if hasTrailer then
    return fillLevel, capacity
  end
  return nil
end
function Vehicle:draw()
  for k, v in pairs(self.specializations) do
    v.draw(self)
  end
  if self.selectedImplement ~= 0 then
    self.attachedImplements[self.selectedImplement].object:draw()
  end
end
function Vehicle:attachImplement(object, jointIndex)
  local jointDesc = self.attacherJoints[jointIndex]
  local implement = {}
  implement.object = object
  implement.object:onAttach(self)
  implement.jointDescIndex = jointIndex
  local constr = JointConstructor:new()
  constr:setActors(jointDesc.rootNode, implement.object.attacherJoint.rootNode)
  constr:setJointTransforms(jointDesc.jointTransform, implement.object.attacherJoint.node)
  implement.jointRotLimit = {}
  implement.jointTransLimit = {}
  implement.maxRotLimit = {}
  implement.maxTransLimit = {}
  for i = 1, 3 do
    local rotLimit = jointDesc.maxRotLimit[i] * implement.object.attacherJoint.rotLimitScale[i]
    if implement.object.attacherJoint.fixedRotation then
      rotLimit = 0
    end
    local transLimit = jointDesc.maxTransLimit[i] * implement.object.attacherJoint.transLimitScale[i]
    implement.maxRotLimit[i] = rotLimit
    implement.maxTransLimit[i] = transLimit
    constr:setRotationLimit(i - 1, -rotLimit, rotLimit)
    implement.jointRotLimit[i] = rotLimit
    constr:setTranslationLimit(i - 1, true, -transLimit, transLimit)
    implement.jointTransLimit[i] = transLimit
  end
  if jointDesc.rotationNode ~= nil then
    setRotation(jointDesc.rotationNode, unpack(jointDesc.maxRot))
  end
  if jointDesc.rotationNode2 ~= nil then
    setRotation(jointDesc.rotationNode2, unpack(jointDesc.maxRot2))
  end
  jointDesc.jointIndex = constr:finalize()
  jointDesc.moveDown = implement.object.isDefaultLowered
  table.insert(self.attachedImplements, implement)
  if self.selectedImplement == 0 then
    self.selectedImplement = 1
    implement.object:onSelect()
  end
  for k, v in pairs(self.specializations) do
    if v.attachImplement ~= nil then
      v.attachImplement(self, implement)
    end
  end
end
function Vehicle:detachImplement(implementIndex)
  for k, v in pairs(self.specializations) do
    if v.detachImplement ~= nil then
      v.detachImplement(self, implementIndex)
    end
  end
  local implement = self.attachedImplements[implementIndex]
  local jointDesc = self.attacherJoints[implement.jointDescIndex]
  removeJoint(jointDesc.jointIndex)
  jointDesc.jointIndex = 0
  if implementIndex == self.selectedImplement then
    implement.object:onDeselect()
  end
  implement.object:onDetach()
  implement.object = nil
  if jointDesc.topArm ~= nil then
    setRotation(jointDesc.topArm.rotationNode, jointDesc.topArm.rotX, jointDesc.topArm.rotY, jointDesc.topArm.rotZ)
    if jointDesc.topArm.translationNode ~= nil then
      setTranslation(jointDesc.topArm.translationNode, 0, 0, 0)
    end
  end
  if jointDesc.bottomArm ~= nil then
    setRotation(jointDesc.bottomArm.rotationNode, jointDesc.bottomArm.rotX, jointDesc.bottomArm.rotY, jointDesc.bottomArm.rotZ)
    if jointDesc.bottomArm.translationNode ~= nil then
      setTranslation(jointDesc.bottomArm.translationNode, 0, 0, 0)
    end
  end
  if jointDesc.rotationNode ~= nil then
    setRotation(jointDesc.rotationNode, unpack(jointDesc.minRot))
  end
  table.remove(self.attachedImplements, implementIndex)
  self.selectedImplement = math.min(self.selectedImplement, table.getn(self.attachedImplements))
  if self.selectedImplement ~= 0 then
    self.attachedImplements[self.selectedImplement].object:onSelect()
  end
end
function Vehicle:detachImplementByObject(object)
  for i = 1, table.getn(self.attachedImplements) do
    if self.attachedImplements[i].object == object then
      self:detachImplement(i)
      break
    end
  end
end
function Vehicle:getImplementByObject(object)
  for i = 1, table.getn(self.attachedImplements) do
    if self.attachedImplements[i].object == object then
      return self.attachedImplements[i]
    end
  end
  return nil
end
function Vehicle:setSelectedImplement(selected)
  if self.selectedImplement ~= 0 then
    self.attachedImplements[self.selectedImplement].object:onDeselect()
  end
  self.selectedImplement = selected
  self.attachedImplements[selected].object:onSelect()
end
function Vehicle:playAttachSound()
  if self.attachSound ~= nil then
    setSamplePitch(self.attachSound, self.attachSoundPitchOffset)
    playSample(self.attachSound, 1, 1, 0)
  end
end
function Vehicle:playDetachSound()
  if self.attachSound ~= nil then
    setSamplePitch(self.attachSound, self.attachSoundPitchOffset)
    playSample(self.attachSound, 1, 1, 0)
  end
end
function Vehicle:handleAttachEvent()
  if self == g_currentMission.currentVehicle and g_currentMission.trailerInTipRange ~= nil then
    if g_currentMission.currentTipTrigger ~= nil and (g_currentMission.trailerInTipRange.currentFillType == FruitUtil.FRUITTYPE_UNKNOWN or g_currentMission.currentTipTrigger.acceptedFruitTypes[g_currentMission.trailerInTipRange.currentFillType]) then
      g_currentMission.trailerInTipRange:toggleTipState(g_currentMission.currentTipTrigger)
    end
  elseif self:handleAttachAttachableEvent() then
    self:playAttachSound()
  elseif self:handleDetachAttachableEvent() then
    self:playDetachSound()
  end
end
function Vehicle:handleAttachAttachableEvent()
  if g_currentMission.attachableInMountRange ~= nil then
    if g_currentMission.attachableInMountRangeVehicle == self then
      if self.attacherJoints[g_currentMission.attachableInMountRangeIndex].jointIndex == 0 then
        self:attachImplement(g_currentMission.attachableInMountRange, g_currentMission.attachableInMountRangeIndex)
        return true
      end
    else
      for i = 1, table.getn(self.attachedImplements) do
        if self.attachedImplements[i].object:handleAttachAttachableEvent() then
          return true
        end
      end
    end
  end
  return false
end
function Vehicle:handleDetachAttachableEvent()
  if self.selectedImplement ~= 0 then
    local attachable = self.attachedImplements[self.selectedImplement].object
    local detach = true
    if not Input.isKeyPressed(Input.KEY_shift) and attachable:handleDetachAttachableEvent() then
      detach = false
    end
    if detach then
      self:detachImplement(self.selectedImplement)
    end
    return true
  end
  return false
end
function Vehicle:handleLowerImplementEvent()
  if self.selectedImplement ~= 0 then
    local implement = self.attachedImplements[self.selectedImplement]
    if implement.object.allowsLowering then
      local jointDesc = self.attacherJoints[implement.jointDescIndex]
      if jointDesc.allowsLowering then
        jointDesc.moveDown = not jointDesc.moveDown
      end
    end
  end
end
function Vehicle:getAttachedIndexFromJointDescIndex(jointDescIndex)
  for i = 1, table.getn(self.attachedImplements) do
    if self.attachedImplements[i].jointDescIndex == jointDescIndex then
      return i
    end
  end
  return nil
end
function Vehicle:setLightsVisibility(visibility)
  self.lightsActive = visibility
  for k, light in pairs(self.lights) do
    setVisibility(light, visibility)
  end
  for k, v in pairs(self.attachedImplements) do
    v.object:setLightsVisibility(visibility)
  end
  for k, v in pairs(self.specializations) do
    if v.setLightsVisibility ~= nil then
      v.setLightsVisibility(self, visibility)
    end
  end
end
function Vehicle:getIsActiveForInput()
  if self.isEntered then
    return true
  end
  if self.attacherVehicle ~= nil then
    return self.isSelected and self.attacherVehicle:getIsActiveForInput()
  end
  return false
end
function Vehicle:getIsActiveForSound()
  if self.isEntered then
    return true
  end
  if self.attacherVehicle ~= nil then
    return self.attacherVehicle:getIsActiveForSound()
  end
  return false
end
function Vehicle:getIsActive()
  if self.isBroken then
    return false
  end
  if self.isEntered then
    return true
  end
  if self.attacherVehicle ~= nil then
    return self.attacherVehicle:getIsActive()
  end
  if self.forceIsActive then
    return true
  end
  return false
end
function Vehicle:onDeactivateAttachements()
  for k, v in pairs(self.attachedImplements) do
    v.object:onDeactivate()
  end
end
function Vehicle:onActivateAttachements()
  for k, v in pairs(self.attachedImplements) do
    v.object:onActivate()
  end
end
function Vehicle:onDeactivateAttachementsSounds()
  for k, v in pairs(self.attachedImplements) do
    v.object:onDeactivateSounds()
  end
end
function Vehicle:onDeactivateAttachementsLights()
  for k, v in pairs(self.attachedImplements) do
    v.object:onDeactivateLights()
  end
end
function Vehicle:onActivate()
  self:onActivateAttachements()
  for k, v in pairs(self.specializations) do
    if v.onActivate ~= nil then
      v.onActivate(self)
    end
  end
end
function Vehicle:onDeactivate()
  self:onDeactivateAttachements()
  for k, v in pairs(self.specializations) do
    if v.onDeactivate ~= nil then
      v.onDeactivate(self)
    end
  end
end
function Vehicle:onDeactivateSounds()
  self:onDeactivateAttachementsSounds()
  for k, v in pairs(self.specializations) do
    if v.onDeactivateSounds ~= nil then
      v.onDeactivateSounds(self)
    end
  end
end
function Vehicle:onDeactivateLights()
  self:onDeactivateAttachementsLights()
  for k, v in pairs(self.specializations) do
    if v.onDeactivateLights ~= nil then
      v.onDeactivateLights(self)
    end
  end
end
function Vehicle:doCheckSpeedLimit()
  if self.attacherVehicle ~= nil then
    return self.checkSpeedLimit and self.attacherVehicle:doCheckSpeedLimit()
  end
  return self.checkSpeedLimit
end
function Vehicle:isLowered(default)
  if self.attacherVehicle ~= nil then
    local implement = self.attacherVehicle:getImplementByObject(self)
    if implement ~= nil then
      local jointDesc = self.attacherVehicle.attacherJoints[implement.jointDescIndex]
      if jointDesc.allowsLowering then
        return jointDesc.moveDown or self.attacherVehicle:isLowered(default)
      end
    end
  end
  return default
end

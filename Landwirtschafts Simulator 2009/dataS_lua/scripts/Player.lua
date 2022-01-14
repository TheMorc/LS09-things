Player = {}
Player.walkingSpeed = 0.005
Player.gravity = -0.1
Player.runningFactor = 1
Player.mouseXLast = nil
Player.mouseYLast = nil
Player.rotX = 0
Player.rotY = 0
Player.height = 1.8
Player.lastCamera = ""
Player.camera = 0
Player.time = 0
Player.walkStepSolidGround = {}
Player.numWalkStepSolidGround = 0
Player.currentWalkStep = 0
Player.walkStepSolidGroundDuration = {}
Player.walkStepSolidGroundTimestamp = 0
Player.lastXPos = 0
Player.lastZPos = 0
Player.lastYPos = 0
Player.walkStepDistance = 0
Player.lightNode = 0
Player.kinematicCollisionMask = 2148532230
Player.movementCollisionMask = 2148532255
Player.triggeredPickupTrigger = nil
Player.pickedPickup = nil
Player.pickedPickupTrigger = nil
function Player.create(posX, yOffset, posZ, rotX, rotY)
  Player.rootNode = loadI3DFile("data/templates/player.i3d")
  link(getRootNode(), Player.rootNode)
  if posX ~= nil and yOffset ~= nil and posZ ~= nil then
    Player.moveTo(posX, yOffset, posZ)
  else
    setTranslation(Player.rootNode, 270, 118, 46)
  end
  Player.camera = getChild(getChildAt(Player.rootNode, 0), "playerCamera")
  if Player.camera == 0 then
    print("Error: invalid player camera")
  end
  if 0 < getNumOfChildren(Player.camera) then
    Player.lightNode = getChildAt(Player.camera, 0)
    setVisibility(Player.lightNode, false)
  end
  Player.camX, Player.camY, Player.camZ = getTranslation(Player.camera)
  if rotX ~= nil and rotY ~= nil then
    Player.rotX = rotX
    Player.rotY = rotY
  else
    Player.rotX = 0
    Player.rotY = 0
  end
  Player.swimPos = 0
  Player.walkStepSolidGround[0] = createSample("walkStepSolidGround01")
  loadSample(Player.walkStepSolidGround[0], "data/maps/sounds/walkStepSolidGround01.wav", false)
  Player.walkStepSolidGroundDuration[0] = getSampleDuration(Player.walkStepSolidGround[0])
  Player.walkStepSolidGround[1] = createSample("walkStepSolidGround02")
  loadSample(Player.walkStepSolidGround[1], "data/maps/sounds/walkStepSolidGround02.wav", false)
  Player.walkStepSolidGroundDuration[1] = getSampleDuration(Player.walkStepSolidGround[1])
  Player.walkStepSolidGround[2] = createSample("walkStepSolidGround03")
  loadSample(Player.walkStepSolidGround[2], "data/maps/sounds/walkStepSolidGround03.wav", false)
  Player.walkStepSolidGroundDuration[2] = getSampleDuration(Player.walkStepSolidGround[2])
  Player.walkStepSolidGround[3] = createSample("walkStepSolidGround04")
  loadSample(Player.walkStepSolidGround[3], "data/maps/sounds/walkStepSolidGround04.wav", false)
  Player.walkStepSolidGroundDuration[3] = getSampleDuration(Player.walkStepSolidGround[3])
  Player.numWalkStepSolidGround = 4
  Player.oceanWavesSample = createSample("oceanWaves")
  loadSample(Player.oceanWavesSample, "data/maps/sounds/oceanWaves.wav", false)
  Player.oceanWavesSamplePlaying = false
  Player.controllerIndex = createCCT(Player.rootNode, 0.3, Player.height - 0.6, 0.6, 45, 0.1, Player.kinematicCollisionMask, 60)
  Player.onEnter()
end
function Player.destroy()
  removeCCT(Player.controllerIndex)
  delete(Player.rootNode)
  Player.rootNode = ""
  delete(Player.walkStepSolidGround[0])
  delete(Player.walkStepSolidGround[1])
  delete(Player.walkStepSolidGround[2])
  delete(Player.walkStepSolidGround[3])
  delete(Player.oceanWavesSample)
  Player.mouseXLast = nil
  Player.mouseYLast = nil
  Player.lightNode = 0
  Player.triggeredPickupTrigger = nil
  Player.pickedPickup = nil
  Player.pickedPickupTrigger = nil
end
function Player.mouseEvent(posX, posY, isDown, isUp, button)
  if Player.mouseXLast ~= nil and Player.mouseYLast ~= nil then
    Player.rotX = Player.rotX - (Player.mouseYLast - posY)
    Player.rotY = Player.rotY - (posX - Player.mouseXLast)
    Player.mouseXLast = posX
    Player.mouseYLast = posY
  end
end
function Player.update(dt)
  Player.time = Player.time + dt
  local inputZ = InputBinding.getAnalogInputAxis(InputBinding.AXIS_SIDE2)
  local inputW = InputBinding.getAnalogInputAxis(InputBinding.AXIS_FORWARD2)
  if InputBinding.isAxisZero(inputZ) then
    inputZ = InputBinding.getDigitalInputAxis(InputBinding.AXIS_SIDE2)
  end
  if InputBinding.isAxisZero(inputW) then
    inputW = InputBinding.getDigitalInputAxis(InputBinding.AXIS_FORWARD2)
  end
  local rotSpeed = 0.001 * dt
  Player.rotX = Player.rotX - rotSpeed * inputW
  Player.rotY = Player.rotY - rotSpeed * inputZ
  local movementX = 0
  local movementY = Player.gravity * 0.25 * dt
  local movementZ = 0
  local inputX = InputBinding.getAnalogInputAxis(InputBinding.AXIS_SIDE)
  local inputY = InputBinding.getAnalogInputAxis(InputBinding.AXIS_FORWARD)
  if InputBinding.isAxisZero(inputX) then
    inputX = InputBinding.getDigitalInputAxis(InputBinding.AXIS_SIDE)
  end
  if InputBinding.isAxisZero(inputY) then
    inputY = InputBinding.getDigitalInputAxis(InputBinding.AXIS_FORWARD)
  end
  local len = Utils.vector2Length(inputX, inputY)
  if 1 < len then
    inputX = inputX / len
    inputY = inputY / len
  end
  local dz = inputY * Player.walkingSpeed * dt * Player.runningFactor
  local dx = inputX * Player.walkingSpeed * dt * Player.runningFactor
  movementX = math.sin(Player.rotY) * dz + math.cos(-Player.rotY) * dx
  movementZ = math.cos(-Player.rotY) * dz - math.sin(Player.rotY) * dx
  local xt, yt, zt = getTranslation(Player.rootNode)
  local swimYoffset = 0
  local waterY = g_currentMission.waterY
  local deltaWater = yt - waterY
  local wavesMax = 2
  local wavesMin = -4
  if deltaWater < wavesMax then
    if not Player.oceanWavesSamplePlaying then
      playSample(Player.oceanWavesSample, 0, 0, 0)
      Player.oceanWavesSamplePlaying = true
    end
    local volume = 0.5
    if 0 < deltaWater then
      volume = (wavesMax - deltaWater) / wavesMax * 0.5
    else
      local height = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, Player.lastXPos, 0, Player.lastZPos) - waterY
      if wavesMin > height then
        volume = 0
      else
        volume = (wavesMin - height) / wavesMin
      end
    end
    setSampleVolume(Player.oceanWavesSample, volume)
  elseif Player.oceanWavesSamplePlaying then
    stopSample(Player.oceanWavesSample)
    Player.oceanWavesSamplePlaying = false
  end
  if deltaWater < 0 then
    if deltaWater < -0.6 then
      deltaWater = -0.6
      setTranslation(Player.rootNode, xt, waterY + deltaWater, zt)
    end
    movementY = 0
    Player.swimPos = Player.swimPos + Utils.vector2Length(dx, dz)
    swimYoffset = math.sin(Player.swimPos) * 0.27 + math.sin(Player.time * 0.003) * 0.06
    if deltaWater < -0.1 then
      movementY = -Player.gravity * 0.08 * dt * deltaWater * deltaWater
    end
  end
  local dist = 0.5
  if deltaWater < dist and 0 <= deltaWater then
    swimYoffset = swimYoffset * ((dist - deltaWater) / dist)
  end
  setTranslation(Player.camera, Player.camX, Player.camY + swimYoffset, Player.camZ)
  moveCCT(Player.controllerIndex, movementX, movementY, movementZ, Player.movementCollisionMask, 0.4)
  Player.rotX = math.min(1.2, math.max(-1.5, Player.rotX))
  setRotation(Player.camera, Player.rotX, Player.rotY, 0)
  wrapMousePosition(0.5, 0.5)
  Player.mouseXLast = 0.5
  Player.mouseYLast = 0.5
  Player.walkStepDistance = Player.walkStepDistance + Utils.vector2Length(Player.lastXPos - xt, Player.lastZPos - zt)
  local walkStepVolume = 0.35
  if 0 <= deltaWater and 2 < Player.walkStepDistance and Player.walkStepSolidGroundTimestamp < Player.time then
    local pitch = math.random(0.8, 1.1)
    local volume = math.random(0.75, 1)
    local delay = math.random(0, 30)
    setSamplePitch(Player.walkStepSolidGround[Player.currentWalkStep], pitch)
    playSample(Player.walkStepSolidGround[Player.currentWalkStep], 1, volume * walkStepVolume, delay)
    Player.walkStepDistance = 0
    Player.walkStepSolidGroundTimestamp = Player.time + Player.walkStepSolidGroundDuration[Player.currentWalkStep] * pitch + delay
    local last = Player.currentWalkStep
    while last == Player.currentWalkStep do
      Player.currentWalkStep = math.floor(math.random(0, Player.numWalkStepSolidGround - 1.00001))
    end
  end
  if Player.lightNode ~= 0 and InputBinding.hasEvent(InputBinding.TOGGLE_LIGHTS) then
    setVisibility(Player.lightNode, not getVisibility(Player.lightNode))
  end
  if Player.pickedPickup ~= nil then
    if InputBinding.hasEvent(InputBinding.IMPLEMENT_EXTRA) then
      Player.pickedPickupTrigger:resetPickup(Player.pickedPickup)
      Player.pickedPickup = nil
      Player.pickedPickupTrigger = nil
    end
  elseif Player.triggeredPickupTrigger ~= nil and InputBinding.hasEvent(InputBinding.IMPLEMENT_EXTRA) then
    local pickup = getChildAt(Player.triggeredPickupTrigger.triggerId, 0)
    link(Player.camera, pickup)
    setTranslation(pickup, 0.02649, -0.3187, -0.54542)
    setRotation(pickup, math.rad(-6.98214), 0, math.rad(-6.31934))
    Player.pickedPickup = pickup
    Player.pickedPickupTrigger = Player.triggeredPickupTrigger
    Player.triggeredPickupTrigger = nil
  end
  Player.lastXPos = xt
  Player.lastZPos = zt
end
function Player.moveTo(x, yOffset, z)
  local terrainHeight = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, 300, z)
  local y = terrainHeight + yOffset + Player.height
  setTranslation(Player.rootNode, x, y, z)
  Player.lastXPos = x
  Player.lastYPos = y
  Player.lastYPos = z
end
function Player.moveToAbsolute(x, y, z)
  setTranslation(Player.rootNode, x, y + Player.height, z)
  Player.lastXPos = x
  Player.lastYPos = y + Player.height
  Player.lastZPos = z
end
function Player.draw()
end
function Player.onEnter()
  setCamera(Player.camera)
end
function Player.onLeave()
  if Player.lightNode ~= 0 then
    setVisibility(Player.lightNode, false)
  end
  Player.moveToAbsolute(0, -200, 0)
  if Player.oceanWavesSamplePlaying then
    stopSample(Player.oceanWavesSample)
    Player.oceanWavesSamplePlaying = false
  end
end

VehicleCamera = {}
local VehicleCamera_mt = Class(VehicleCamera)
function VehicleCamera:new(cameraNode, isRotatable, rotateNode, limit, rotMinX, rotMaxX, transMin, transMax, customMt)
  local instance = {}
  if customMt ~= nil then
    setmetatable(instance, customMt)
  else
    setmetatable(instance, VehicleCamera_mt)
  end
  if rotateNode == nil then
    rotateNode = cameraNode
  end
  instance.cameraNode = cameraNode
  instance.isRotatable = isRotatable
  instance.isActivated = false
  instance.origRotX, instance.origRotY, instance.origRotZ = getRotation(rotateNode)
  instance.rotX = instance.origRotX
  instance.rotY = instance.origRotY
  instance.rotZ = instance.origRotZ
  instance.rotateNode = rotateNode
  instance.origTransX, instance.origTransY, instance.origTransZ = getTranslation(cameraNode)
  instance.transX = instance.origTransX
  instance.transY = instance.origTransY
  instance.transZ = instance.origTransZ
  local trans1OverLength = 1 / Utils.vector3Length(instance.origTransX, instance.origTransY, instance.origTransZ)
  instance.transDirX = trans1OverLength * instance.origTransX
  instance.transDirY = trans1OverLength * instance.origTransY
  instance.transDirZ = trans1OverLength * instance.origTransZ
  instance.allowTranslation = instance.rotateNode ~= instance.cameraNode
  instance.limit = limit
  instance.rotMinX = rotMinX
  instance.rotMaxX = rotMaxX
  instance.transMin = transMin
  instance.transMax = transMax
  return instance
end
function VehicleCamera:delete()
end
function VehicleCamera:zoom(offset)
  self.transX = self.transX + self.transDirX * offset
  self.transY = self.transY + self.transDirY * offset
  self.transZ = self.transZ + self.transDirZ * offset
end
function VehicleCamera:mouseEvent(posX, posY, isDown, isUp, button)
  if self.isActivated then
    if self.posXLast == -1 or self.posYLast == -1 then
      self.posXLast = posX
      self.posYLast = posY
    end
    local translateMode = Input.isMouseButtonPressed(Input.MOUSE_BUTTON_LEFT) or Input.isMouseButtonPressed(Input.MOUSE_BUTTON_RIGHT)
    if self.isRotatable and not translateMode then
      self.rotX = self.rotX - (self.posYLast - posY)
      self.rotY = self.rotY - (posX - self.posXLast)
    end
    if self.allowTranslation then
      if translateMode then
        local zoomSpeedScale = 20
        self.zoom(self, (self.posYLast - posY) * zoomSpeedScale)
      end
      if Input.isMouseButtonPressed(Input.MOUSE_BUTTON_WHEEL_UP) then
        self.zoom(self, -0.75)
      elseif Input.isMouseButtonPressed(Input.MOUSE_BUTTON_WHEEL_DOWN) then
        self.zoom(self, 0.75)
      end
    end
    self.posXLast = posX
    self.posYLast = posY
  end
end
function VehicleCamera:keyEvent(unicode, sym, modifier, isDown)
end
function VehicleCamera:update(dt)
  if self.isActivated and self.isRotatable then
    local rotSpeed = 0.001 * dt
    local inputW = InputBinding.getAnalogInputAxis(InputBinding.AXIS_FORWARD2)
    local inputZ = InputBinding.getAnalogInputAxis(InputBinding.AXIS_SIDE2)
    if InputBinding.isAxisZero(inputW) then
      inputW = InputBinding.getDigitalInputAxis(InputBinding.AXIS_FORWARD2)
    end
    if InputBinding.isAxisZero(inputZ) then
      inputZ = InputBinding.getDigitalInputAxis(InputBinding.AXIS_SIDE2)
    end
    self.rotX = self.rotX + rotSpeed * inputW
    self.rotY = self.rotY + rotSpeed * inputZ
  end
  if self.limit then
    self.rotX = math.min(self.rotMaxX, math.max(self.rotMinX, self.rotX))
    local len = Utils.vector3Length(self.transX, self.transY, self.transZ)
    len = math.min(self.transMax, math.max(self.transMin, len))
    self.transX, self.transY, self.transZ = self.transDirX * len, self.transDirY * len, self.transDirZ * len
  end
  setRotation(self.rotateNode, self.rotX, self.rotY, self.rotZ)
  setTranslation(self.cameraNode, self.transX, self.transY, self.transZ)
  if self.isActivated then
    wrapMousePosition(0.5, 0.5)
    self.posXLast = 0.5
    self.posYLast = 0.5
  end
end
function VehicleCamera:onActivate()
  self.isActivated = true
  self:resetCamera()
  setCamera(self.cameraNode)
end
function VehicleCamera:onDeactivate()
  self:resetCamera()
  self.isActivated = false
end
function VehicleCamera:resetCamera()
  self.rotX = self.origRotX
  self.rotY = self.origRotY
  self.rotZ = self.origRotZ
  self.posXLast = -1
  self.posYLast = -1
  self.transX = self.origTransX
  self.transY = self.origTransY
  self.transZ = self.origTransZ
  setRotation(self.rotateNode, self.rotX, self.rotY, self.rotZ)
  setTranslation(self.cameraNode, self.transX, self.transY, self.transZ)
end

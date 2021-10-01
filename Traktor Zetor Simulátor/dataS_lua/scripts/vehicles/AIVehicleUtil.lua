AIVehicleUtil = {}
function AIVehicleUtil:driveInDirection(dt, steeringAngleLimit, acceleration, slowAcceleration, slowAngleLimit, allowedToDrive, moveForwards, lx, lz, speedLevel, slowMaxRpmFactor)
  local dot = lz
  local angle = math.deg(math.acos(dot))
  if angle < 0 then
    angle = angle + 180
  end
  local turnLeft = 1.0E-5 < lx
  if not moveForwards then
    turnLeft = not turnLeft
  end
  if turnLeft then
    self.rotatedTime = self.maxRotTime * math.min(angle / steeringAngleLimit, 1)
  else
    self.rotatedTime = self.minRotTime * math.min(angle / steeringAngleLimit, 1)
  end
  if self.firstTimeRun then
    local acc = acceleration
    if speedLevel ~= nil and speedLevel ~= 0 then
      acc = 1
      self.motor:setSpeedLevel(speedLevel, true)
      if slowAngleLimit <= math.abs(angle) then
        self.motor.maxRpmOverride = self.motor.maxRpm[speedLevel] * slowMaxRpmFactor
      else
        self.motor.maxRpmOverride = nil
      end
    elseif slowAngleLimit <= math.abs(angle) then
      acc = slowAcceleration
    end
    if not allowedToDrive then
      acc = 0
    end
    if not moveForwards then
      acc = -acc
    end
    WheelsUtil.updateWheelsPhysics(self, dt, self.lastSpeed, acc, false, self.requiredDriveMode)
  end
end
function AIVehicleUtil.getDriveDirection(refNode, x, y, z)
  local lx, ly, lz = worldToLocal(refNode, x, y, z)
  local length = Utils.vector2Length(lx, lz)
  if 1.0E-5 < length then
    length = 1 / length
    lx = lx * length
    lz = lz * length
  end
  return lx, lz
end
function AIVehicleUtil.setCollisionDirection(node, col, colDirX, colDirZ)
  local parent = getParent(col)
  local colDirY = 0
  if parent ~= node then
    colDirX, colDirY, colDirZ = worldDirectionToLocal(parent, localDirectionToWorld(node, colDirX, 0, colDirZ))
  end
  setDirection(col, colDirX, colDirY, colDirZ, 0, 1, 0)
end

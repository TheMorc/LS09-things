Hirable = {}
function Hirable.prerequisitesPresent(specializations)
  return true
end
function Hirable:load(xmlFile)
  self.hire = SpecializationUtil.callSpecializationsFunction("hire")
  self.dismiss = SpecializationUtil.callSpecializationsFunction("dismiss")
  self.pricePerMS = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.pricePerHour"), 500) / 60 / 60 / 1000
  self.isHired = false
end
function Hirable:delete()
end
function Hirable:mouseEvent(posX, posY, isDown, isUp, button)
end
function Hirable:keyEvent(unicode, sym, modifier, isDown)
end
function Hirable:update(dt)
  if self.isHired then
    self.forceIsActive = true
    self.stopMotorOnLeave = false
    self.steeringEnabled = false
    self.deactivateOnLeave = false
    g_currentMission.missionStats.money = g_currentMission.missionStats.money - dt * self.pricePerMS
  end
end
function Hirable:draw()
end
function Hirable:hire()
  self.isHired = true
  self.forceIsActive = true
  self.stopMotorOnLeave = false
  self.steeringEnabled = false
  self.deactivateOnLeave = false
  self.disableCharacterOnLeave = false
end
function Hirable:dismiss()
  self.isHired = false
  self.forceIsActive = false
  self.stopMotorOnLeave = true
  self.steeringEnabled = true
  self.deactivateOnLeave = true
  self.disableCharacterOnLeave = true
  if not self.isEntered and self.characterNode ~= nil then
    setVisibility(self.characterNode, false)
  end
end

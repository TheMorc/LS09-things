WarningLight = {}
function WarningLight.prerequisitesPresent(specializations)
  return true
end
function WarningLight:load(xmlFile)
  self.rundumleuchtenAnz = Utils.getNoNil(getXMLInt(xmlFile, "vehicle.rundumleuchten#count"), 0)
  self.rundumleuchtenAn = false
  self.rundumleuchten = {}
  for i = 1, self.rundumleuchtenAnz do
    local objname = string.format("vehicle.rundumleuchten.light" .. "%d", i)
    self.rundumleuchten[i] = {}
    self.rundumleuchten[i].rotNode = Utils.indexToObject(self.rootNode, getXMLString(xmlFile, objname .. "#rotNode"))
    self.rundumleuchten[i].light = Utils.indexToObject(self.rootNode, getXMLString(xmlFile, objname .. "#light"))
    self.rundumleuchten[i].source = Utils.indexToObject(self.rootNode, getXMLString(xmlFile, objname .. "#lightsource"))
    self.rundumleuchten[i].speed = Utils.getNoNil(getXMLInt(xmlFile, objname .. "#rotSpeed"), 1) / 1000
    self.rundumleuchten[i].emit = Utils.getNoNil(getXMLBool(xmlFile, objname .. "#emitLight"), true)
    if not self.rundumleuchten[i].emit and self.rundumleuchten[i].source ~= nil then
      setVisibility(self.rundumleuchten[i].source, false)
    end
  end
end
function WarningLight:delete()
end
function WarningLight:mouseEvent(posX, posY, isDown, isUp, button)
end
function WarningLight:keyEvent(unicode, sym, modifier, isDown)
end
function WarningLight:update(dt)
  if self.rundumleuchtenAn then
    for i = 1, self.rundumleuchtenAnz do
      rotate(self.rundumleuchten[i].rotNode, 0, dt * self.rundumleuchten[i].speed, 0)
    end
  end
  if self:getIsActiveForInput() and InputBinding.hasEvent(InputBinding.TOGGLE_WARNING_LIGHTS) then
    if self.rundumleuchtenAn then
      self.rundumleuchtenAn = not self.rundumleuchtenAn
      for i = 1, self.rundumleuchtenAnz do
        setVisibility(self.rundumleuchten[i].light, self.rundumleuchtenAn)
      end
    else
      self.rundumleuchtenAn = not self.rundumleuchtenAn
      for i = 1, self.rundumleuchtenAnz do
        setVisibility(self.rundumleuchten[i].light, self.rundumleuchtenAn)
      end
    end
  end
end
function WarningLight:draw()
  if table.getn(self.rundumleuchten) > 0 then
    if self.rundumleuchtenAn then
      g_currentMission:addHelpButtonText(g_i18n:getText("Turn_off_warning_lights"), InputBinding.TOGGLE_WARNING_LIGHTS)
    else
      g_currentMission:addHelpButtonText(g_i18n:getText("Turn_on_warning_lights"), InputBinding.TOGGLE_WARNING_LIGHTS)
    end
  end
end
function WarningLight:onLeave()
  self.rundumleuchtenAn = false
end
function WarningLight:onDeactivate()
end

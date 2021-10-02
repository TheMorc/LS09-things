MedalsDisplay = {}
local MedalsDisplay_mt = Class(MedalsDisplay)
function MedalsDisplay:new()
  local instance = {}
  setmetatable(instance, MedalsDisplay_mt)
  instance.items = {}
  instance.bronzeTime = 0
  instance.silverTime = 0
  instance.goldTime = 0
  instance.posX = 0.06
  instance.posY = 0.105
  instance.height = 0.155
  instance.medalsHeight = instance.height * 0.8
  instance.medalsSpacingY = (instance.height - instance.medalsHeight) / 2
  instance.medalsSpacingX = 0.3
  instance.medalsPosY = instance.posY + instance.medalsSpacingY
  instance.textHeight = instance.height * 0.25
  instance.textSpacingY = (instance.height - instance.textHeight) / 2
  instance.textPosY = instance.posY + instance.textSpacingY - 0.007
  instance.textSpacingX = instance.medalsHeight * 0.75 + 0.0075
  instance:addItem(Overlay:new("backgroundOverlay", "dataS/missions/medals_background.png", 0.05, instance.posY, 0.9, instance.height))
  instance:addItem(Overlay:new("bronzeMedalOverlay", "dataS/missions/bronze_medal.png", instance.posX + instance.medalsSpacingX * 2, instance.medalsPosY, instance.medalsHeight * 0.75, instance.medalsHeight))
  instance:addItem(Overlay:new("silverMedalOverlay", "dataS/missions/silver_medal.png", instance.posX + instance.medalsSpacingX * 1, instance.medalsPosY, instance.medalsHeight * 0.75, instance.medalsHeight))
  instance:addItem(Overlay:new("goldMedalOverlay", "dataS/missions/gold_medal.png", instance.posX + instance.medalsSpacingX * 0, instance.medalsPosY, instance.medalsHeight * 0.75, instance.medalsHeight))
  return instance
end
function MedalsDisplay:delete()
  for i = 1, table.getn(self.items) do
    self.items[i]:delete()
  end
end
function MedalsDisplay:addItem(item)
  table.insert(self.items, item)
end
function MedalsDisplay:renderText(time, x, y, fs)
  if self.missionType == "time" then
    local timeHoursF = time / 60000 + 1.0E-4
    local timeHours = math.floor(timeHoursF)
    local timeMinutes = math.floor((timeHoursF - timeHours) * 60)
    renderText(x, y, fs, string.format("%02d:%02d " .. g_i18n:getText("minutes"), timeHours, timeMinutes))
  end
  if self.missionType == "stacking" then
    renderText(x, y, fs, string.format("%d " .. g_i18n:getText("pallets"), time))
  end
  if self.missionType == "strawElevatoring" then
    renderText(x, y, fs, string.format("%d " .. g_i18n:getText("bales"), time))
  end
end
function MedalsDisplay:render()
  for i = 1, table.getn(self.items) do
    self.items[i]:render()
  end
  setTextColor(1, 1, 1, 1)
  setTextBold(false)
  self:renderText(self.bronzeTime, self.posX + self.textSpacingX + self.medalsSpacingX * 2, self.textPosY, self.textHeight)
  self:renderText(self.silverTime, self.posX + self.textSpacingX + self.medalsSpacingX * 1, self.textPosY, self.textHeight)
  self:renderText(self.goldTime, self.posX + self.textSpacingX + self.medalsSpacingX * 0, self.textPosY, self.textHeight)
end
function MedalsDisplay:setTimes(bronzeTime, silverTime, goldTime, missionType)
  self.bronzeTime = bronzeTime
  self.silverTime = silverTime
  self.goldTime = goldTime
  self.missionType = missionType
end

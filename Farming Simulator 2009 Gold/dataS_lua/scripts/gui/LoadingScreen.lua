LoadingScreen = {}
local LoadingScreen_mt = Class(LoadingScreen)
function LoadingScreen:new(loadFunction)
  local instance = {}
  setmetatable(instance, LoadingScreen_mt)
  instance.items = {}
  instance.count = 0
  instance.loadFunction = loadFunction
  instance.missionId = 0
  instance.scriptClass = "dummy"
  instance.isLoaded = false
  instance.pleaseWaitBgOverlay = Overlay:new("background01", "dataS/missions/please_wait_background.png", 0.05, 0.021, 0.9, 0.065)
  return instance
end
function LoadingScreen:delete()
  delete(self.buttonOverlay.overlayId)
  delete(self.pleaseWaitBgOverlay.overlayId)
end
function LoadingScreen:addItem(item)
  table.insert(self.items, item)
end
function LoadingScreen:mouseEvent(posX, posY, isDown, isUp, button)
  for i = 1, table.getn(self.items) do
    self.items[i]:mouseEvent(posX, posY, isDown, isUp, button)
  end
end
function LoadingScreen:keyEvent(unicode, sym, modifier, isDown)
end
function LoadingScreen:update(dt)
  self.count = self.count + 1
  if self.count == 2 then
    self.loadFunction(self.scriptFilename, self.scriptClass, self.missionId, self.bronzeTime, self.silverTime, self.goldTime)
    self.isLoaded = true
    self.buttonOverlay = Overlay:new("play_button", "dataS/menu/ingame_play_button" .. g_languageSuffix .. ".png", 0.415, 0.02, 0.17, 0.06)
    self:addItem(OverlayButton:new(self.buttonOverlay, OnLoadingScreenFinish))
  end
end
function LoadingScreen:render()
  for i = 1, table.getn(self.items) do
    self.items[i]:render()
  end
  if self.missionId ~= 0 then
    gameMenuSystem.medalsDisplay:render()
  end
  if not self.isLoaded then
    self.pleaseWaitBgOverlay:render()
    setTextBold(true)
    local str = g_i18n:getText("Mission_is_loading_please_wait")
    local offset = 0
    if self.missionId == 0 then
      str = g_i18n:getText("Game_is_loading_please_wait")
      offset = 0.01
    end
    setTextAlignment(RenderText.ALIGN_CENTER)
    renderText(0.5, 0.0275, 0.05, str)
    setTextAlignment(RenderText.ALIGN_LEFT)
    setTextColor(1, 1, 1, 1)
  end
end
function LoadingScreen:setScriptInfo(scriptFilename, scriptClass)
  self.scriptFilename = scriptFilename
  self.scriptClass = scriptClass
end
function LoadingScreen:setMissionInfo(missionId, bronzeTime, silverTime, goldTime, missionType)
  self.missionId = missionId
  self.bronzeTime = bronzeTime
  self.silverTime = silverTime
  self.goldTime = goldTime
  self.missionType = missionType
end

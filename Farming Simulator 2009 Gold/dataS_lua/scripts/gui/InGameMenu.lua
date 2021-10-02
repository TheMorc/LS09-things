InGameMenu = {}
local InGameMenu_mt = Class(InGameMenu)
function InGameMenu:new()
  local instance = {}
  setmetatable(instance, InGameMenu_mt)
  instance.items = {}
  instance.backgroundOverlay = backgroundOverlay
  instance.missions = {}
  instance.extraOverlay = nil
  instance.missionId = 0
  instance.doSaveGame = false
  instance.doSaveGamePart2 = false
  instance.dialogOverlays = {}
  instance.dialogOverlayButtons = {}
  local ingame_menu_sizeX = 0.34
  local ingame_menu_spaceX = 0
  local ingame_menu_sizeY = 0.06
  local ingame_menu_posX = -0.01
  local ingame_menu_posY = 0.02
  local buttonWidth = 0.17
  local buttonHeight = 0.06
  self.inGameMenu = OverlayMenu:new()
  instance.overlay_restart = Overlay:new("ingame_menu_button", "dataS/menu/ingame_menu_restart" .. g_languageSuffix .. ".png", ingame_menu_posX + ingame_menu_spaceX * 0 + ingame_menu_sizeX * 0, ingame_menu_posY, ingame_menu_sizeX, ingame_menu_sizeY)
  instance.overlay_save = Overlay:new("ingame_menu_button", "dataS/menu/ingame_menu_save" .. g_languageSuffix .. ".png", ingame_menu_posX + ingame_menu_spaceX * 0 + ingame_menu_sizeX * 0, ingame_menu_posY, ingame_menu_sizeX, ingame_menu_sizeY)
  instance.overlay2 = Overlay:new("ingame_menu_button", "dataS/menu/ingame_menu_cancel" .. g_languageSuffix .. ".png", ingame_menu_posX + ingame_menu_spaceX * 1 + ingame_menu_sizeX * 1, ingame_menu_posY, ingame_menu_sizeX, ingame_menu_sizeY)
  instance.overlay3 = Overlay:new("ingame_play_button", "dataS/menu/ingame_menu_continue" .. g_languageSuffix .. ".png", ingame_menu_posX + ingame_menu_spaceX * 2 + ingame_menu_sizeX * 2, ingame_menu_posY, ingame_menu_sizeX, ingame_menu_sizeY)
  instance.savingOverlay = Overlay:new("ingame_saving", "dataS/menu/ingame_menu_saving" .. g_languageSuffix .. ".png", ingame_menu_posX + ingame_menu_spaceX * 0 + ingame_menu_sizeX * 0, ingame_menu_posY + 0.07, ingame_menu_sizeX, ingame_menu_sizeY)
  instance.dialogGUIActive = false
  instance.playerAlreadySaved = false
  table.insert(instance.dialogOverlays, Overlay:new("dialog_overlay", "dataS/menu/dialog_bg.png", 0.3, 0.5, 0.4, 0.26666666666666666))
  instance:addDialogButton(OverlayButton:new(Overlay:new("no_button", "dataS/menu/no_button" .. g_languageSuffix .. ".png", 0.5 - 0.5 * buttonWidth + 0.095, 0.53, buttonWidth, buttonHeight), OnBackToInGameMenu))
  instance:addDialogButton(OverlayButton:new(Overlay:new("yes_button", "dataS/menu/yes_button" .. g_languageSuffix .. ".png", 0.5 - 0.5 * buttonWidth - 0.095, 0.53, buttonWidth, buttonHeight), OnInGameMenuMenu))
  return instance
end
function InGameMenu:delete()
  delete(self.overlay_restart.overlayId)
  delete(self.overlay_save.overlayId)
  delete(self.overlay2.overlayId)
  delete(self.overlay3.overlayId)
  delete(self.savingOverlay.overlayId)
end
function InGameMenu:setExtraOverlays(extraOverlay)
  self.extraOverlay = extraOverlay
end
function InGameMenu:setMissionId(id)
  self.missionId = id
  self.items = {}
  if id == 0 then
    self:addItem(OverlayButton:new(self.overlay_save, OnInGameMenuSave))
  else
    self:addItem(OverlayButton:new(self.overlay_restart, OnInGameMenuRestart))
  end
  self:addItem(OverlayButton:new(self.overlay2, OnInGameMenuAreYouSure))
  self:addItem(OverlayButton:new(self.overlay3, OnInGameMenuPlay))
end
function InGameMenu:mouseEvent(posX, posY, isDown, isUp, button)
  if self.dialogGUIActive then
    for i = 1, table.getn(self.dialogOverlayButtons) do
      self.dialogOverlayButtons[i]:mouseEvent(posX, posY, isDown, isUp, button)
    end
  else
    for i = 1, table.getn(self.items) do
      self.items[i]:mouseEvent(posX, posY, isDown, isUp, button)
    end
  end
end
function InGameMenu:addItem(item)
  table.insert(self.items, item)
end
function InGameMenu:addDialogButton(overlayButton)
  table.insert(self.dialogOverlays, overlayButton.overlay)
  table.insert(self.dialogOverlayButtons, overlayButton)
end
function InGameMenu:keyEvent(unicode, sym, modifier, isDown)
end
function InGameMenu:update(dt)
end
function InGameMenu:render()
  if self.dialogGUIActive then
    for i = 1, table.getn(self.dialogOverlays) do
      self.dialogOverlays[i]:render()
    end
    setTextAlignment(RenderText.ALIGN_CENTER)
    setTextBold(true)
    setTextColor(1, 1, 1, 1)
    if self.missionId == 0 then
      renderText(0.496, 0.7, 0.038, g_i18n:getText("DontForgetToSave"))
    else
      renderText(0.496, 0.7, 0.038, g_i18n:getText("MissionWantToEnd"))
    end
    setTextBold(false)
    setTextAlignment(RenderText.ALIGN_LEFT)
  else
    if self.extraOverlay ~= nil then
      self.extraOverlay:render()
    end
    for i = 1, table.getn(self.items) do
      self.items[i]:render()
    end
    if self.missionId ~= 0 then
      gameMenuSystem.medalsDisplay:render()
    end
    if self.doSaveGame then
      self.doSaveGame = false
      self.doSaveGamePart2 = true
      self.savingOverlay:render()
    elseif self.doSaveGamePart2 then
      gameMenuSystem.quickPlayMenu:saveSelectedGame()
      self.doSaveGamePart2 = false
    end
  end
end
function InGameMenu:reset()
  for i = 1, table.getn(self.items) do
    self.items[i]:reset()
  end
  for i = 1, table.getn(self.dialogOverlayButtons) do
    self.dialogOverlayButtons[i]:reset()
  end
  self.dialogGUIActive = false
  self.playerAlreadySaved = false
end
function InGameMenu:exitAreYouSureDialog()
  if not self.playerAlreadySaved or self.missionId ~= 0 then
    self.dialogGUIActive = true
  else
    OnInGameMenuMenu()
  end
end
function InGameMenu:backToInGameMenu()
  self.dialogGUIActive = false
end

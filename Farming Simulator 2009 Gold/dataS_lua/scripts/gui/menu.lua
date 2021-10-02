GameMenuSystem = {}
local GameMenuSystem_mt = Class(GameMenuSystem)
function GameMenuSystem:new()
  return setmetatable({}, GameMenuSystem_mt)
end
function GameMenuSystem:init()
  local bgOverlay = Overlay:new("background01", "dataS/menu/background01" .. g_languageSuffix .. ".png", 0, 0, 1, 1)
  local logoOverlay = Overlay:new("main_logo", "dataS/menu/main_logo" .. g_languageSuffix .. ".png", 0.16, 0.5, 0.7, 0.4666666666666666)
  local main_menu_posX = 0.05
  local main_menu_posY = 0.5
  local main_menu_sizeX = 0.17
  local main_menu_spaceY = 0.08
  local main_menu_sizeY = 0.06
  self.mainMenu = OverlayMenu:new()
  self.mainMenu:addItem(bgOverlay)
  self.mainMenu:addItem(logoOverlay)
  self.mainMenu:addItem(OverlayButton:new(Overlay:new("main_quickplay_button", "dataS/menu/main_quickplay_button" .. g_languageSuffix .. ".png", main_menu_posX, main_menu_posY - main_menu_spaceY * 0, main_menu_sizeX, main_menu_sizeY), OnMainMenuQuickPlay))
  self.mainMenu:addItem(OverlayButton:new(Overlay:new("main_mission_button", "dataS/menu/main_mission_button" .. g_languageSuffix .. ".png", main_menu_posX, main_menu_posY - main_menu_spaceY * 1, main_menu_sizeX, main_menu_sizeY), OnMainMenuMission))
  self.mainMenu:addItem(OverlayButton:new(Overlay:new("main_settings_button", "dataS/menu/main_settings_button" .. g_languageSuffix .. ".png", main_menu_posX, main_menu_posY - main_menu_spaceY * 2, main_menu_sizeX, main_menu_sizeY), OnMainMenuSettings))
  self.mainMenu:addItem(OverlayButton:new(Overlay:new("main_credits_button", "dataS/menu/main_credits_button" .. g_languageSuffix .. ".png", main_menu_posX, main_menu_posY - main_menu_spaceY * 3, main_menu_sizeX, main_menu_sizeY), OnMainMenuCredits))
  self.mainMenu:addItem(OverlayButton:new(Overlay:new("main_quit_button", "dataS/menu/main_quit_button" .. g_languageSuffix .. ".png", main_menu_posX, main_menu_posY - main_menu_spaceY * 4, main_menu_sizeX, main_menu_sizeY), OnMainMenuQuit))
  self.missionMenu = MissionMenu:new(bgOverlay)
  self.quickPlayMenu = QuickPlayMenu:new(bgOverlay)
  local settings_menu_posX = 0.05
  local settings_menu_posY = 0.5
  local settings_menu_sizeX = 0.17
  local settings_menu_spaceY = 0.08
  local settings_menu_sizeY = 0.06
  self.settingsMenu = OverlayMenu:new()
  self.settingsMenu:addItem(bgOverlay)
  self.settingsMenu:addItem(logoOverlay)
  self.settingsMenu:addItem(OverlayButton:new(Overlay:new("settings_save_button", "dataS/menu/save_button" .. g_languageSuffix .. ".png", settings_menu_posX, settings_menu_posY - settings_menu_spaceY * 1, settings_menu_sizeX, settings_menu_sizeY), OnSettingsMenuSave))
  self.settingsMenu:addItem(OverlayButton:new(Overlay:new("settings_back_button", "dataS/menu/back_button" .. g_languageSuffix .. ".png", settings_menu_posX, settings_menu_posY - settings_menu_spaceY * 2, settings_menu_sizeX, settings_menu_sizeY), OnSettingsMenuBack))
  self.settingsMenu:addItem(OverlayButton:new(Overlay:new("settings_controls_button", "dataS/menu/controls_button" .. g_languageSuffix .. ".png", settings_menu_posX, settings_menu_posY - settings_menu_spaceY * 0, settings_menu_sizeX, settings_menu_sizeY), OnSettingsMenuControls))
  local settings_posX = 0.25
  local settings_posY = 0.5
  local settings_spaceY = 0.07
  local settings_small_button_size = 0.06
  local settings_text_label_sizeX = 0.48
  local settings_text_label_sizeY = 0.06
  local settings_sizeX = 0.7
  local settings_menu_border = 0.01
  local settings_sizeY = settings_spaceY * 7 + settings_menu_border * 2
  local settings_textX = settings_posX + 0.375 + 0.05
  local settings_offsetY = -0.01
  self.settingsMenu:addItem(Overlay:new("settings_background", "dataS/menu/settings_background.png", settings_posX, settings_posY - settings_sizeY + settings_spaceY - 0.01, settings_sizeX, settings_sizeY + 0.01))
  local resTable = {}
  local numR = getNumOfScreenModes()
  for i = 0, numR - 1 do
    local x, y = getScreenModeInfo(numR - i - 1)
    aspect = x / y
    if aspect == 1.25 then
      aspectStr = "(5:4)"
    elseif aspect > 1.3 and aspect < 1.4 then
      aspectStr = "(4:3)"
    elseif aspect > 1.7 and aspect < 1.8 then
      aspectStr = "(16:9)"
    else
      aspectStr = string.format("(%1.1f:1)", aspect)
    end
    table.insert(resTable, string.format("%dx%d %s", x, y, aspectStr))
  end
  g_settingsDisplayResolution = getScreenMode()
  local down = OverlayButton:new(Overlay:new("settings_resolution_down", "dataS/menu/small_button_left.png", settings_posX + 0.375, settings_posY - settings_spaceY * 0 - settings_menu_border, settings_small_button_size * 0.75, settings_small_button_size), OnSettingsMenuResolutionDown)
  local up = OverlayButton:new(Overlay:new("settings_resolution_up", "dataS/menu/small_button_right.png", settings_posX + 0.63, settings_posY - settings_spaceY * 0 - settings_menu_border, settings_small_button_size * 0.75, settings_small_button_size), OnSettingsMenuResolutionUp)
  self.settingsMenu.resTextOp = OverlayMultiTextOption:new(resTable, down, up, settings_textX + 0.095, settings_posY - settings_spaceY * 0 - settings_menu_border - settings_offsetY + 0.005, 0.033, numR - g_settingsDisplayResolution, OnSettingsMenuDisplayResolution)
  self.settingsMenu:addItem(self.settingsMenu.resTextOp)
  local msaaTable = {}
  table.insert(msaaTable, "Off")
  table.insert(msaaTable, "2")
  table.insert(msaaTable, "4")
  table.insert(msaaTable, "8")
  g_settingsMSAA = getMSAA()
  local down = OverlayButton:new(Overlay:new("settings_resolution_down", "dataS/menu/small_button_left.png", settings_posX + 0.375, settings_posY - settings_spaceY * 1 - settings_menu_border, settings_small_button_size * 0.75, settings_small_button_size), OnSettingsMenuResolutionDown)
  local up = OverlayButton:new(Overlay:new("settings_resolution_up", "dataS/menu/small_button_right.png", settings_posX + 0.63, settings_posY - settings_spaceY * 1 - settings_menu_border, settings_small_button_size * 0.75, settings_small_button_size), OnSettingsMenuResolutionUp)
  self.settingsMenu.msaaTextOp = OverlayMultiTextOption:new(msaaTable, down, up, settings_textX + 0.095, settings_posY - settings_spaceY * 1 - settings_menu_border - settings_offsetY, 0.045, Utils.getMSAAIndex(g_settingsMSAA), OnSettingsMenuMSAA)
  self.settingsMenu:addItem(self.settingsMenu.msaaTextOp)
  local anisoTable = {}
  table.insert(anisoTable, "Off")
  table.insert(anisoTable, "2")
  table.insert(anisoTable, "4")
  table.insert(anisoTable, "8")
  g_settingsAnsio = getFilterAnisotropy()
  local down = OverlayButton:new(Overlay:new("settings_resolution_down", "dataS/menu/small_button_left.png", settings_posX + 0.375, settings_posY - settings_spaceY * 2 - settings_menu_border, settings_small_button_size * 0.75, settings_small_button_size), OnSettingsMenuResolutionDown)
  local up = OverlayButton:new(Overlay:new("settings_resolution_up", "dataS/menu/small_button_right.png", settings_posX + 0.63, settings_posY - settings_spaceY * 2 - settings_menu_border, settings_small_button_size * 0.75, settings_small_button_size), OnSettingsMenuResolutionUp)
  self.settingsMenu.ansioTextOp = OverlayMultiTextOption:new(anisoTable, down, up, settings_textX + 0.095, settings_posY - settings_spaceY * 2 - settings_menu_border - settings_offsetY, 0.045, Utils.getAnsioIndex(g_settingsAnsio), OnSettingsMenuAniso)
  self.settingsMenu:addItem(self.settingsMenu.ansioTextOp)
  local radioOffLabel = Overlay:new("settings_radio1", "dataS/menu/radio_button_off.png", settings_posX + 0.375, settings_posY - settings_spaceY * 3 - settings_menu_border, settings_small_button_size * 0.75, settings_small_button_size)
  local radioOnLabel = Overlay:new("settings_radio2", "dataS/menu/radio_button_on.png", settings_posX + 0.375, settings_posY - settings_spaceY * 3 - settings_menu_border, settings_small_button_size * 0.75, settings_small_button_size)
  self.settingsMenu.joystickRadio = OverlayCheckbox:new(radioOnLabel, radioOffLabel, g_settingsJoystickEnabled, OnSettingsMenuJoystickEnabled)
  self.settingsMenu:addItem(self.settingsMenu.joystickRadio)
  local profileTable = {}
  table.insert(profileTable, string.format("Auto (%s)", getAutoGPUPerformanceClass()))
  table.insert(profileTable, "Low")
  table.insert(profileTable, "Medium")
  table.insert(profileTable, "High")
  table.insert(profileTable, "Very High")
  g_settingsDisplayProfile = getGPUPerformanceClass()
  local down = OverlayButton:new(Overlay:new("settings_resolution_down", "dataS/menu/small_button_left.png", settings_posX + 0.375, settings_posY - settings_spaceY * 4 - settings_menu_border, settings_small_button_size * 0.75, settings_small_button_size), OnSettingsMenuResolutionDown)
  local up = OverlayButton:new(Overlay:new("settings_resolution_up", "dataS/menu/small_button_right.png", settings_posX + 0.63, settings_posY - settings_spaceY * 4 - settings_menu_border, settings_small_button_size * 0.75, settings_small_button_size), OnSettingsMenuResolutionUp)
  self.settingsMenu.profileTextOp = OverlayMultiTextOption:new(profileTable, down, up, settings_textX + 0.095, settings_posY - settings_spaceY * 4 - settings_menu_border - settings_offsetY, 0.033, Utils.getProfileClassIndex(g_settingsDisplayProfile), OnSettingsMenuGPUProfile)
  self.settingsMenu:addItem(self.settingsMenu.profileTextOp)
  local timeScaleTable = {}
  table.insert(timeScaleTable, "Real-Time")
  table.insert(timeScaleTable, "4x")
  table.insert(timeScaleTable, "16x")
  table.insert(timeScaleTable, "32x")
  table.insert(timeScaleTable, "60x")
  local down = OverlayButton:new(Overlay:new("settings_resolution_down", "dataS/menu/small_button_left.png", settings_posX + 0.375, settings_posY - settings_spaceY * 5 - settings_menu_border, settings_small_button_size * 0.75, settings_small_button_size), OnSettingsMenuResolutionDown)
  local up = OverlayButton:new(Overlay:new("settings_resolution_up", "dataS/menu/small_button_right.png", settings_posX + 0.63, settings_posY - settings_spaceY * 5 - settings_menu_border, settings_small_button_size * 0.75, settings_small_button_size), OnSettingsMenuResolutionUp)
  self.settingsMenu.timeScaleTextOp = OverlayMultiTextOption:new(timeScaleTable, down, up, settings_textX + 0.095, settings_posY - settings_spaceY * 5 - settings_menu_border - settings_offsetY, 0.045, Utils.getTimeScaleIndex(g_settingsTimeScale), OnSettingsMenuTimeScale)
  self.settingsMenu:addItem(self.settingsMenu.timeScaleTextOp)
  local radioOffLabel = Overlay:new("settings_radio1", "dataS/menu/radio_button_off.png", settings_posX + 0.375, settings_posY - settings_spaceY * 6 - settings_menu_border, settings_small_button_size * 0.75, settings_small_button_size)
  local radioOnLabel = Overlay:new("settings_radio2", "dataS/menu/radio_button_on.png", settings_posX + 0.375, settings_posY - settings_spaceY * 6 - settings_menu_border, settings_small_button_size * 0.75, settings_small_button_size)
  self.settingsMenu.helpRadio = OverlayCheckbox:new(radioOnLabel, radioOffLabel, g_settingsHelpText, OnSettingsMenuHelpRadio)
  self.settingsMenu:addItem(self.settingsMenu.helpRadio)
  self.controlsScreen = GUIControlsScreen:new(0.025, 0.025, 0.95, 0.95)
  self.controlsScreen:disable()
  self.creditsScreen = CreditsScreen:new(bgOverlay)
  if g_isDemo then
    self.demoEndMenu = DemoEndScreen:new()
    self.demoEndMenu:addItem(Overlay:new("demoEndScreenOverlay", "dataS/menu/demo_end_screen" .. g_languageSuffix .. ".png", 0, 0, 1, 1))
  end
  self.inGameMenu = InGameMenu:new()
  self.medalsDisplay = MedalsDisplay:new()
  self.storeMenu = StoreMenu:new(bgOverlay)
  self.currentMenu = self.mainMenu
end
function GameMenuSystem:loadingScreenMode()
  self.loadScreen = LoadingScreen:new(OnLoadingScreen)
  self.loadScreen:setScriptInfo(g_missionLoaderDesc.scriptFilename, g_missionLoaderDesc.scriptClass)
  self.loadScreen:setMissionInfo(g_missionLoaderDesc.id, g_missionLoaderDesc.bronze, g_missionLoaderDesc.silver, g_missionLoaderDesc.gold, g_missionLoaderDesc.missionType)
  self.loadScreen:addItem(g_missionLoaderDesc.backgroundOverlay)
  self.loadScreen:addItem(g_missionLoaderDesc.overlayBriefing)
  self.inGameMenu:setExtraOverlays(g_missionLoaderDesc.overlayBriefing)
  self.inGameMenu:setMissionId(g_missionLoaderDesc.id)
  self.currentMenu = self.loadScreen
end
function GameMenuSystem:quickPlayMode()
  self.quickPlayMenu:reset()
  self.currentMenu = self.quickPlayMenu
end
function GameMenuSystem:missionMode()
  self.missionMenu:reset()
  self.currentMenu = self.missionMenu
end
function GameMenuSystem:playMode()
  g_currentMission:unpauseGame()
  self.currentMenu = nil
end
function GameMenuSystem:settingsMode()
  self.settingsMenu.resTextOp.state = getNumOfScreenModes() - getScreenMode()
  self.settingsMenu.msaaTextOp.state = Utils.getMSAAIndex(getMSAA())
  self.settingsMenu.ansioTextOp.state = Utils.getAnsioIndex(getFilterAnisotropy())
  self.settingsMenu.profileTextOp.state = Utils.getProfileClassIndex(getGPUPerformanceClass())
  self.settingsMenu.joystickRadio:setState(g_settingsJoystickEnabled)
  self.settingsMenu.timeScaleTextOp.state = Utils.getTimeScaleIndex(g_settingsTimeScale)
  self.settingsMenu.helpRadio:setState(g_settingsHelpText)
  self.settingsMenu:reset()
  self.currentMenu = self.settingsMenu
end
function GameMenuSystem:creditsMode()
  self.creditsScreen:reset()
  self.currentMenu = self.creditsScreen
end
function GameMenuSystem:inGameMenuMode()
  self.inGameMenu:reset()
  g_currentMission:pauseGame()
  self.currentMenu = self.inGameMenu
end
function GameMenuSystem:mainMenuMode()
  self.mainMenu:reset()
  self.currentMenu = self.mainMenu
end
function GameMenuSystem:demoEndMode()
  self.currentMenu = self.demoEndMenu
end
function GameMenuSystem:storeMode()
  self.storeMenu:reset()
  if g_currentMission.inGameMessage ~= nil then
    g_currentMission.inGameMessage.visible = false
  end
  g_currentMission:pauseGame()
  g_currentMission.storeIsActive = true
  self.currentMenu = self.storeMenu
end
function GameMenuSystem:isMenuActive()
  return self.currentMenu ~= nil
end
function GameMenuSystem:mouseEvent(posX, posY, isDown, isUp, button)
  if self.currentMenu ~= nil then
    self.currentMenu:mouseEvent(posX, posY, isDown, isUp, button)
  end
end
function GameMenuSystem:keyEvent(unicode, sym, modifier, isDown)
  if self.currentMenu ~= nil then
    if isDown and sym == Input.KEY_esc and self.currentMenu == self.inGameMenu then
      OnInGameMenuPlay()
    else
      self.currentMenu:keyEvent(unicode, sym, modifier, isDown)
    end
  elseif isDown and sym == Input.KEY_esc then
    OnInGameMenu()
  end
end
g_hudOverlay = nil
g_hudOverlay1 = nil
g_hudOverlay2 = nil
g_hudOverlay3 = nil
function GameMenuSystem:update(dt)
  if self.currentMenu ~= nil then
    self.currentMenu:update(dt)
  elseif InputBinding.hasEvent(InputBinding.TOGGLE_STORE) then
    OnMenuStore()
  end
end
function GameMenuSystem:render()
  if self.currentMenu ~= nil then
    self.currentMenu:render()
    if self.currentMenu == self.settingsMenu then
      setTextColor(1, 1, 1, 1)
      setTextBold(true)
      setTextAlignment(RenderText.ALIGN_RIGHT)
      renderText(0.61, 0.5, 0.03, g_i18n:getText("Resolution"))
      renderText(0.61, 0.43, 0.03, g_i18n:getText("MSAA"))
      renderText(0.61, 0.36, 0.03, g_i18n:getText("AnisotropicFiltering"))
      renderText(0.61, 0.29, 0.03, g_i18n:getText("JoystickGamepad"))
      renderText(0.61, 0.22, 0.03, g_i18n:getText("HardwareProfile"))
      renderText(0.61, 0.15, 0.03, g_i18n:getText("TimeScale"))
      renderText(0.61, 0.08, 0.03, g_i18n:getText("AutomaticHelp"))
      setTextBold(false)
      setTextAlignment(RenderText.ALIGN_LEFT)
    end
  end
end

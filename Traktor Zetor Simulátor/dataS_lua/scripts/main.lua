source("shared/scripts/common/class.lua")
source("dataS/scripts/I18N.lua")
source("dataS/scripts/gui/base_gui.lua")
source("dataS/scripts/InputBinding.lua")
source("dataS/scripts/MissionStats.lua")
source("dataS/scripts/BaseMission.lua")
source("dataS/scripts/RaceMission.lua")
source("dataS/scripts/HotspotMission.lua")
source("dataS/scripts/StationFillMission.lua")
source("dataS/scripts/FieldMission.lua")
source("dataS/scripts/Files.lua")
source("dataS/scripts/SpecializationUtil.lua")
source("dataS/scripts/VehicleTypeUtil.lua")
source("dataS/scripts/RoadUtil.lua")
source("dataS/scripts/TrafficVehicleUtil.lua")
source("dataS/scripts/FruitUtil.lua")
source("dataS/scripts/StoreItemsUtil.lua")
source("dataS/scripts/PlacementUtil.lua")
source("dataS/scripts/gui/LoadingScreen.lua")
source("dataS/scripts/gui/MissionMenu.lua")
source("dataS/scripts/gui/QuickPlayMenu.lua")
source("dataS/scripts/gui/MedalsDisplay.lua")
source("dataS/scripts/gui/InGameMenu.lua")
source("dataS/scripts/gui/menu.lua")
source("dataS/scripts/gui/DemoEndScreen.lua")
source("dataS/scripts/gui/StoreMenu.lua")
source("dataS/scripts/gui/CreditsScreen.lua")
source("dataS/scripts/gui/InGameMessage.lua")
source("dataS/scripts/gui/InGameIcon.lua")
source("dataS/scripts/environment/Environment.lua")
source("dataS/scripts/Player.lua")
source("dataS/scripts/Utils.lua")
source("dataS/scripts/AnimCurve.lua")
source("dataS/scripts/events.lua")
source("dataS/scripts/objects/Windmill.lua")
source("dataS/scripts/objects/BuildingSign.lua")
source("dataS/scripts/objects/Ship.lua")
source("dataS/scripts/objects/Nightlight.lua")
source("dataS/scripts/objects/HouseLight.lua")
source("dataS/scripts/objects/LighthouseBeam.lua")
source("dataS/scripts/objects/ChurchClock.lua")
source("dataS/scripts/objects/Fountain.lua")
source("dataS/scripts/objects/Saucer.lua")
source("dataS/scripts/vehicles/AIVehicleUtil.lua")
source("dataS/scripts/vehicles/WheelsUtil.lua")
source("dataS/scripts/vehicles/VehicleMotor.lua")
source("dataS/scripts/vehicles/VehiclePlacementCallback.lua")
source("dataS/scripts/vehicles/VehicleCamera.lua")
source("dataS/scripts/triggers/SiloTrigger.lua")
source("dataS/scripts/triggers/TipTrigger.lua")
source("dataS/scripts/triggers/GasStationTrigger.lua")
source("dataS/scripts/triggers/BarrierTrigger.lua")
source("dataS/scripts/triggers/VisualPlayerTrigger.lua")
source("dataS/scripts/triggers/HotspotTrigger.lua")
source("dataS/scripts/triggers/InfospotTrigger.lua")
source("dataS/scripts/triggers/PlayerPickupTrigger.lua")
source("dataS/scripts/sounds/RandomSound.lua")
source("dataS/scripts/sounds/DailySound.lua")
source("dataS/scripts/triggers/BarnMoverTrigger.lua")
source("dataS/scripts/triggers/PalletTrigger.lua")
gameMenuSystem = {}
g_languageSuffix = "_de"
g_languageShort = "de"
g_isDemo = false
g_settingsJoystickEnabled = false
g_settingsJoystickEnabledMenu = false
g_settingsHelpText = true
g_settingsHelpTextMenu = true
g_settingsTimeScale = 16
g_settingsTimeScaleMenu = 16
g_settingsMSAA = 0
g_settingsAnsio = 0
g_settingsDisplayResolution = 0
g_settingsDisplayProfile = 0
g_savegameRevision = 5
g_finishedMissions = {}
g_finishedMissionsRecord = {}
g_missionLoaderDesc = {}
g_menuMusic = nil
g_fuelPricePerLiter = 0.7
g_startPrices = {}
g_startPriceSum = 0
g_modEventListeners = {}
function init()
  InputBinding.load()
  local xmlFile = loadXMLFile("LanguageFile", "dataS/language.xml")
  g_languageShort = Utils.getNoNil(getXMLString(xmlFile, "language#short"), "de")
  g_languageSuffix = Utils.getNoNil(getXMLString(xmlFile, "language#suffix"), "_de")
  delete(xmlFile)
  g_settingsJoystickEnabled = getJoystickEnabled()
  g_settingsJoystickEnabledMenu = g_settingsJoystickEnabled
  g_i18n = I18N:new()
  local savegamePathTemplate = getAppBasePath() .. "data/savegamesTemplate.xml"
  g_savegamePath = getUserProfileAppPath() .. "savegames.xml"
  copyFile(savegamePathTemplate, g_savegamePath, false)
  g_savegameXML = loadXMLFile("savegameXML", g_savegamePath)
  local revision = getXMLInt(g_savegameXML, "savegames#revision")
  if revision == nil or revision ~= g_savegameRevision then
    copyFile(savegamePathTemplate, g_savegamePath, true)
    delete(g_savegameXML)
    g_savegameXML = loadXMLFile("savegameXML", g_savegamePath)
  end
  g_settingsHelpText = getXMLBool(g_savegameXML, "savegames.settings.autohelp")
  g_settingsHelpTextMenu = g_settingsHelpText
  g_settingsTimeScale = getXMLFloat(g_savegameXML, "savegames.settings#timescale")
  if g_settingsTimeScale == nil or g_settingsTimeScale == 0 then
    g_settingsTimeScale = 16
  end
  g_settingsTimeScaleMenu = g_settingsTimeScale
  g_foliageViewDistanceCoeff = 1
  local profileId = Utils.getProfileClassId()
  if 4 <= profileId then
    g_foliageViewDistanceCoeff = 1.6
  elseif profileId == 3 then
    g_foliageViewDistanceCoeff = 1.4
  elseif profileId <= 1 then
    g_foliageViewDistanceCoeff = 0.9
  end
  setFoliageViewDistanceCoeff(g_foliageViewDistanceCoeff)
  math.randomseed(os.time())
  math.random()
  math.random()
  math.random()
  SpecializationUtil.registerSpecialization("motorized", "Motorized", "dataS/scripts/vehicles/specializations/Motorized.lua")
  SpecializationUtil.registerSpecialization("steerable", "Steerable", "dataS/scripts/vehicles/specializations/Steerable.lua")
  SpecializationUtil.registerSpecialization("combine", "Combine", "dataS/scripts/vehicles/specializations/Combine.lua")
  SpecializationUtil.registerSpecialization("attachable", "Attachable", "dataS/scripts/vehicles/specializations/Attachable.lua")
  SpecializationUtil.registerSpecialization("plough", "Plough", "dataS/scripts/vehicles/specializations/Plough.lua")
  SpecializationUtil.registerSpecialization("trailer", "Trailer", "dataS/scripts/vehicles/specializations/Trailer.lua")
  SpecializationUtil.registerSpecialization("cutter", "Cutter", "dataS/scripts/vehicles/specializations/Cutter.lua")
  SpecializationUtil.registerSpecialization("baler", "Baler", "dataS/scripts/vehicles/specializations/Baler.lua")
  SpecializationUtil.registerSpecialization("forageWagon", "ForageWagon", "dataS/scripts/vehicles/specializations/ForageWagon.lua")
  SpecializationUtil.registerSpecialization("cultivator", "Cultivator", "dataS/scripts/vehicles/specializations/Cultivator.lua")
  SpecializationUtil.registerSpecialization("mower", "Mower", "dataS/scripts/vehicles/specializations/Mower.lua")
  SpecializationUtil.registerSpecialization("sowingMachine", "SowingMachine", "dataS/scripts/vehicles/specializations/SowingMachine.lua")
  SpecializationUtil.registerSpecialization("sprayer", "Sprayer", "dataS/scripts/vehicles/specializations/Sprayer.lua")
  SpecializationUtil.registerSpecialization("pathVehicle", "PathVehicle", "dataS/scripts/vehicles/specializations/PathVehicle.lua")
  SpecializationUtil.registerSpecialization("trafficVehicle", "TrafficVehicle", "dataS/scripts/vehicles/specializations/TrafficVehicle.lua")
  SpecializationUtil.registerSpecialization("frontloader", "Frontloader", "dataS/scripts/vehicles/specializations/Frontloader.lua")
  SpecializationUtil.registerSpecialization("foldable", "Foldable", "dataS/scripts/vehicles/specializations/Foldable.lua")
  SpecializationUtil.registerSpecialization("hirable", "Hirable", "dataS/scripts/vehicles/specializations/Hirable.lua")
  SpecializationUtil.registerSpecialization("aiCombine", "AICombine", "dataS/scripts/vehicles/specializations/AICombine.lua")
  SpecializationUtil.registerSpecialization("aiTractor", "AITractor", "dataS/scripts/vehicles/specializations/AITractor.lua")
  SpecializationUtil.registerSpecialization("windrower", "Windrower", "dataS/scripts/vehicles/specializations/Windrower.lua")
  SpecializationUtil.registerSpecialization("tedder", "Tedder", "dataS/scripts/vehicles/specializations/Tedder.lua")
  SpecializationUtil.registerSpecialization("warningLight", "WarningLight", "dataS/scripts/vehicles/specializations/WarningLight.lua")
  TrafficVehicleUtil.registerTrafficVehicle("data/vehicles/cars/sportsCar.xml", 33)
  TrafficVehicleUtil.registerTrafficVehicle("data/vehicles/cars/familyCar.xml", 33)
  TrafficVehicleUtil.registerTrafficVehicle("data/vehicles/cars/compactCar.xml", 33)
  VehicleTypeUtil.loadVehicleTypes()
  FruitUtil.registerFruitType("wheat", true, true, true, 3, 0.4, 1.3, 0.01, 0.5, "dataS/missions/hud_fruit_wheat.png")
  FruitUtil.registerFruitType("barley", true, true, true, 3, 0.41, 1.3, 0.01, 0.5, "dataS/missions/hud_fruit_barley.png")
  FruitUtil.registerFruitType("rape", true, true, false, 4, 0.5, 0.8, 0.01, 0.5, "dataS/missions/hud_fruit_rape.png")
  FruitUtil.registerFruitType("maize", true, true, false, 4, 0.42, 2, 0.01, 0.5, "dataS/missions/hud_fruit_maize.png")
  FruitUtil.registerFruitType("grass", true, true, true, 3, 0.33, 3, 0.01, 0.5, "dataS/missions/hud_fruit_grass.png")
  FruitUtil.registerFruitType("dryGrass", false, false, true, 0, 0.37, 2, 0.01, 0.5, "dataS/missions/hud_fruit_grass.png")
  loadMods()
  StoreItemsUtil.loadStoreItems()
  simulatePhysics(false)
  gameMenuSystem = GameMenuSystem:new()
  gameMenuSystem:init()
  setShowMouseCursor(true)
  g_defaultCamera = getCamera()
  g_menuMusic = createStreamedSample("menuMusic")
  loadStreamedSample(g_menuMusic, "dataS/menu/menu.ogg")
  playStreamedSample(g_menuMusic, 0)
  if not g_isDemo then
    local startOptionsXML = loadXMLFile("xml", "data/startOptions.xml")
    local startSavegameActive = Utils.getNoNil(getXMLBool(startOptionsXML, "startOptions.careerStart#active"), false)
    local index = getXMLInt(startOptionsXML, "startOptions.careerStart#savegame")
    delete(startOptionsXML)
    if startSavegameActive and index ~= nil then
      OnMainMenuQuickPlay()
      gameMenuSystem.quickPlayMenu.selectedIndex = Utils.clamp(index, 1, table.getn(gameMenuSystem.quickPlayMenu.savegames))
      gameMenuSystem.quickPlayMenu:checkForDifficulty()
    end
  end
  return true
end
function mouseEvent(posX, posY, isDown, isUp, button)
  Input.updateMouseButtonState(button, isDown)
  gameMenuSystem:mouseEvent(posX, posY, isDown, isUp, button)
  if g_currentMission ~= nil and not gameMenuSystem:isMenuActive() then
    g_currentMission:mouseEvent(posX, posY, isDown, isUp, button)
  end
end
function keyEvent(unicode, sym, modifier, isDown)
  InputBinding.keyEvent(unicode, sym, modifier, isDown)
  Input.updateKeyState(sym, isDown)
  gameMenuSystem:keyEvent(unicode, sym, modifier, isDown)
  if g_currentMission ~= nil and not gameMenuSystem:isMenuActive() then
    g_currentMission:keyEvent(unicode, sym, modifier, isDown)
  end
end
function update(dt)
  InputBinding.update(dt)
  gameMenuSystem:update(dt)
  if g_currentMission ~= nil and not gameMenuSystem:isMenuActive() then
    g_currentMission:update(dt)
  end
end
function draw()
  gameMenuSystem:render()
  if g_currentMission ~= nil then
    g_currentMission:draw()
  end
end
function doExit()
  delete(g_savegameXML)
  Utils.deleteSharedI3DFiles()
  requestExit()
end
function loadMods()
  local loadedMods = {}
  local modsDir = getUserProfileAppPath() .. "mods"
  g_modsDirectory = modsDir
  if g_isDemo then
    return
  end
  createFolder(modsDir)
  print("Mods are located at: ", g_modsDirectory)
  local files = Files:new(modsDir)
  for k, v in pairs(files.files) do
    local modDir
    if v.isDirectory then
      modDir = v.filename
    else
      local len = v.filename:len()
      if 4 < len then
        local ext = v.filename:sub(len - 3)
        if ext == ".zip" or ext == ".gar" then
          modDir = v.filename:sub(1, len - 4)
        end
      end
    end
    if modDir ~= nil then
      local absModDir = modsDir .. "/" .. modDir .. "/"
      local modFile = absModDir .. "modDesc.xml"
      if loadedMods[modFile] == nil then
        loadMod(modDir, absModDir, modFile)
        loadedMods[modFile] = true
      end
    end
  end
end
function loadMod(modName, modDir, modFile)
  local xmlFile = loadXMLFile("ModFile", modFile)
  local modDescVersion = getXMLInt(xmlFile, "modDesc#descVersion")
  if modDescVersion == nil then
    print("Error: missing descVersion attribute in mod " .. modName)
    return
  end
  if modDescVersion ~= 1 then
    print("Error: unsupported mod description version in mod " .. modName)
    return
  end
  g_currentModDirectory = modDir
  g_currentModName = modName
  local i = 0
  while true do
    local baseName = string.format("modDesc.l10n.text(%d)", i)
    local name = getXMLString(xmlFile, baseName .. "#name")
    if name == nil then
      break
    end
    local text = getXMLString(xmlFile, baseName .. "." .. g_languageShort)
    if text == nil then
      text = getXMLString(xmlFile, baseName .. ".en")
      if text == nil then
        text = getXMLString(xmlFile, baseName .. ".de")
      end
    end
    if text == nil then
      print("Warning: no l10n text found for entry '" .. name .. "' in mod '" .. modName .. "'")
    elseif g_i18n:hasText(name) then
      print("Warning: duplicate l10n entry '" .. name .. "' in mod '" .. modName .. "'. Ignoring this defintion.")
    else
      g_i18n:setText(name, text)
    end
    i = i + 1
  end
  local i = 0
  while true do
    local baseName = string.format("modDesc.extraSourceFiles.sourceFile(%d)", i)
    local filename = getXMLString(xmlFile, baseName .. "#filename")
    if filename == nil then
      break
    end
    source(modDir .. filename, modName)
    i = i + 1
  end
  local i = 0
  while true do
    local baseName = string.format("modDesc.specializations.specialization(%d)", i)
    local specName = getXMLString(xmlFile, baseName .. "#name")
    if specName == nil then
      break
    end
    local className = getXMLString(xmlFile, baseName .. "#className")
    local filename = getXMLString(xmlFile, baseName .. "#filename")
    if className ~= nil and filename ~= nil then
      filename = modDir .. filename
      className = modName .. "." .. className
      specName = modName .. "." .. specName
      SpecializationUtil.registerSpecialization(specName, className, filename, modName)
    end
    i = i + 1
  end
  local i = 0
  while true do
    local baseName = string.format("modDesc.vehicleTypes.type(%d)", i)
    local typeName = getXMLString(xmlFile, baseName .. "#name")
    if typeName == nil then
      break
    end
    local className = getXMLString(xmlFile, baseName .. "#className")
    local filename = getXMLString(xmlFile, baseName .. "#filename")
    if className ~= nil and filename ~= nil then
      local customEnvironment = ""
      local useModDirectory = true
      filename, useModDirectory = Utils.getFilename(filename, modDir)
      if useModDirectory then
        customEnvironment = modName
        className = modName .. "." .. className
      end
      local specializationNames = {}
      local j = 0
      while true do
        local baseSpecName = baseName .. string.format(".specialization(%d)", j)
        local specName = getXMLString(xmlFile, baseSpecName .. "#name")
        if specName == nil then
          break
        end
        local entry = SpecializationUtil.specializations[specName]
        if entry == nil then
          specName = modName .. "." .. specName
        end
        table.insert(specializationNames, specName)
        j = j + 1
      end
      VehicleTypeUtil.registerVehicleType(typeName, className, filename, specializationNames, customEnvironment)
    end
    i = i + 1
  end
  local i = 0
  while true do
    local baseName = string.format("modDesc.inputBindings.input(%d)", i)
    local inputName = getXMLString(xmlFile, baseName .. "#name")
    if inputName == nil then
      break
    end
    local inputKey = getXMLString(xmlFile, baseName .. "#key")
    local inputButton = getXMLString(xmlFile, baseName .. "#button")
    if inputKey == nil or inputButton == nil then
      print("Error: no button or key specified for mod input event '" .. inputName .. "' in mod '" .. modName .. "'")
      break
    end
    local inputButtonNumber = -1
    if inputButton ~= "" then
      if Input[inputButton] == nil then
        print("Error: invalid button '" .. inputButton .. "'  for mod input event '" .. inputName .. "' in mod '" .. modName .. "'")
        break
      else
        inputButtonNumber = Input[inputButton]
      end
    end
    if Input[inputKey] == nil then
      print("Error: invalid key '" .. inputKey .. "'  for mod input event '" .. inputName .. "' in mod '" .. modName .. "'")
      break
    end
    if InputBinding[inputName] == nil then
      local buttonIndex = InputBinding.NUM_BUTTONS + 1
      InputBinding[inputName] = buttonIndex
      InputBinding.buttons[buttonIndex] = inputButtonNumber
      InputBinding.buttonKeys[buttonIndex] = Input[inputKey]
      g_inputButtonEvent[buttonIndex] = false
      g_inputButtonLast[buttonIndex] = false
      InputBinding.NUM_BUTTONS = InputBinding.NUM_BUTTONS + 1
    end
    i = i + 1
  end
  local i = 0
  while true do
    local baseName = string.format("modDesc.storeItems.storeItem(%d)", i)
    if not StoreItemsUtil.loadStoreItem(xmlFile, baseName, modDir, true) then
      break
    end
    i = i + 1
  end
  delete(xmlFile)
  g_currentModDirectory = nil
  g_currentModName = nil
end
function addModEventListener(listener)
  table.insert(g_modEventListeners, listener)
end

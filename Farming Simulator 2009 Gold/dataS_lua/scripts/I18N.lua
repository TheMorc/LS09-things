I18N = {}
local I18N_mt = Class(I18N)
function I18N:new(doLoad)
  local instance = {}
  setmetatable(instance, I18N_mt)
  instance.texts = {}
  instance.currencyFactor = 1
  instance.speedFactor = 1
  if doLoad == nil or doLoad == true then
    instance:load()
  end
  return instance
end
function I18N:load()
  self.texts = {}
  local xmlFile = loadXMLFile("TempConfig", "dataS/l10n" .. g_languageSuffix .. ".xml")
  local textI = 0
  while true do
    local key = string.format("i10n.texts.text(%d)", textI)
    local name = getXMLString(xmlFile, key .. "#name")
    local text = getXMLString(xmlFile, key .. "#text")
    if name == nil or text == nil then
      break
    end
    if self.texts[name] ~= nil then
      print("Warning: duplicate text in l10n" .. g_languageSuffix .. ".xml. Ignoring previous defintion.")
    end
    self.texts[name] = text
    textI = textI + 1
  end
  self.currencyFactor = Utils.getNoNil(getXMLFloat(xmlFile, "i10n.currency#factor"), 1)
  self.speedFactor = Utils.getNoNil(getXMLFloat(xmlFile, "i10n.speed#factor"), 1)
  delete(xmlFile)
end
function I18N:getText(name)
  local ret = self.texts[name]
  if ret == nil then
    ret = "Missing " .. name .. " in l10n" .. g_languageSuffix .. ".xml"
  end
  return ret
end
function I18N:hasText(name)
  if self.texts[name] == nil then
    return false
  end
  return true
end
function I18N:setText(name, value)
  self.texts[name] = value
end
function I18N:getCurrency(currency)
  return currency * self.currencyFactor
end
function I18N:getSpeed(speed)
  return speed * self.speedFactor
end
function I18N.initModI18N(globalI18N, modName, modI18N)
  modI18N.modName = modName
  modI18N.globalI18N = globalI18N
  function modI18N:getText(name)
    local ret = self.texts[name]
    if ret == nil then
      ret = self.globalI18N:getText(name)
    end
    return ret
  end
  function modI18N:hasText(name)
    if self.texts[name] == nil then
      return self.globalI18N:hasText(name)
    end
    return true
  end
  function modI18N:hasModText(name)
    if self.texts[name] == nil then
      return false
    end
    return true
  end
  function modI18N:setText(name, value)
    self.texts[name] = value
  end
  function modI18N:getCurrency(currency)
    return self.globalI18N:getCurrency(currency)
  end
  function modI18N:getSpeed(speed)
    return self.globalI18N:getSpeed(speed)
  end
end

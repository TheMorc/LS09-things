I18N = {}
local I18N_mt = Class(I18N)
function I18N:new()
  local instance = {}
  setmetatable(instance, I18N_mt)
  instance:load()
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

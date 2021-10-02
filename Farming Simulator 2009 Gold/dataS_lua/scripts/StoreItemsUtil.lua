StoreItemsUtil = {}
StoreItemsUtil.storeItems = {}
function StoreItemsUtil.addStoreItem(name, description, imageActive, price, xmlFilename, rotation)
  local item = {}
  item.id = table.getn(StoreItemsUtil.storeItems) + 1
  item.name = name
  item.description = description
  item.imageActive = imageActive
  item.price = price
  item.xmlFilename = xmlFilename
  item.rotation = rotation
  table.insert(StoreItemsUtil.storeItems, item)
end
function StoreItemsUtil.loadStoreItems()
  local xmlFile = loadXMLFile("storeItemsXML", "data/storeItems.xml")
  local eof = false
  local i = 0
  repeat
    local baseXMLName = string.format("storeItems.storeItem(%d)", i)
    if not StoreItemsUtil.loadStoreItem(xmlFile, baseXMLName, "", false) then
      eof = true
    end
    i = i + 1
  until eof
  delete(xmlFile)
end
function StoreItemsUtil.loadStoreItem(xmlFile, baseXMLName, baseDir)
  local lang = "." .. g_languageShort
  if not hasXMLProperty(xmlFile, baseXMLName) then
    return false
  end
  local name = StoreItemsUtil.loadLangString(xmlFile, baseXMLName, getXMLString, "name")
  local desc = StoreItemsUtil.loadLangString(xmlFile, baseXMLName, getXMLString, "description")
  local imageActive = StoreItemsUtil.loadLangString(xmlFile, baseXMLName, getXMLString, "image#active")
  local price = StoreItemsUtil.loadLangString(xmlFile, baseXMLName, getXMLFloat, "price")
  local xmlFilename = StoreItemsUtil.loadLangString(xmlFile, baseXMLName, getXMLString, "xmlFilename")
  local rotation = StoreItemsUtil.loadLangString(xmlFile, baseXMLName, getXMLFloat, "rotation", 0)
  if name ~= nil and desc ~= nil and imageActive ~= nil and price ~= nil and xmlFilename ~= nil and rotation ~= nil then
    StoreItemsUtil.addStoreItem(name, desc, baseDir .. imageActive, price, baseDir .. xmlFilename, rotation)
  end
  return true
end
function StoreItemsUtil.loadLangString(xmlFile, baseXMLName, func, name, default)
  local defaultVal = func(xmlFile, baseXMLName .. ".en." .. name)
  if defaultVal == nil then
    defaultVal = func(xmlFile, baseXMLName .. ".de." .. name)
    if defaultVal == nil then
      defaultVal = func(xmlFile, baseXMLName .. "." .. name)
      if defaultVal == nil then
        defaultVal = default
      end
    end
  end
  if defaultVal == nil then
    print("Error: loading store item, missing 'en' or global value of attribute '" .. name .. "', " .. baseXMLName)
    return nil
  end
  local lang = "." .. g_languageShort
  local val = func(xmlFile, baseXMLName .. lang .. "." .. name)
  if val == nil then
    val = defaultVal
  end
  return val
end

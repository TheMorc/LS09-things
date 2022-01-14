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
    if not StoreItemsUtil.loadStoreItem(xmlFile, baseXMLName, "") then
      eof = true
    end
    i = i + 1
  until eof
  delete(xmlFile)
end
function StoreItemsUtil.loadStoreItem(xmlFile, baseXMLName, baseDir)
  local lang = "." .. g_languageShort
  local name = getXMLString(xmlFile, baseXMLName .. lang .. ".name")
  if name == nil then
    name = getXMLString(xmlFile, baseXMLName .. ".name")
  end
  local desc = getXMLString(xmlFile, baseXMLName .. lang .. ".description")
  if desc == nil then
    desc = getXMLString(xmlFile, baseXMLName .. ".description")
  end
  local imageActive = getXMLString(xmlFile, baseXMLName .. lang .. ".image#active")
  if imageActive == nil then
    imageActive = getXMLString(xmlFile, baseXMLName .. ".image#active")
  end
  local price = getXMLFloat(xmlFile, baseXMLName .. lang .. ".price")
  if price == nil then
    price = getXMLFloat(xmlFile, baseXMLName .. ".price")
  end
  local xmlFilename = getXMLString(xmlFile, baseXMLName .. lang .. ".xmlFilename")
  if xmlFilename == nil then
    xmlFilename = getXMLString(xmlFile, baseXMLName .. ".xmlFilename")
  end
  local rotation = getXMLString(xmlFile, baseXMLName .. lang .. ".rotation")
  if rotation == nil then
    rotation = getXMLString(xmlFile, baseXMLName .. ".rotation")
    if rotation == nil then
      rotation = 0
    end
  end
  if name ~= nil and desc ~= nil and imageActive ~= nil and price ~= nil and xmlFilename ~= nil and rotation ~= nil then
    StoreItemsUtil.addStoreItem(name, desc, baseDir .. imageActive, price, baseDir .. xmlFilename, rotation)
    return true
  end
  return false
end

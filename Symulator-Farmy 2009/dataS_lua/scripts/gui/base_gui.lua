function checkOverlayOverlap(posX, posY, overlay)
  return posX >= overlay.x and posX <= overlay.x + overlay.width and posY >= overlay.y and posY <= overlay.y + overlay.height
end
OverlayMenu = {}
local OverlayMenu_mt = Class(OverlayMenu)
function OverlayMenu:new()
  return setmetatable({
    items = {}
  }, OverlayMenu_mt)
end
function OverlayMenu:delete()
  for k, v in pairs(self.items) do
    v:delete()
  end
end
function OverlayMenu:addItem(item)
  table.insert(self.items, item)
end
function OverlayMenu:mouseEvent(posX, posY, isDown, isUp, button)
  for i = 1, table.getn(self.items) do
    self.items[i]:mouseEvent(posX, posY, isDown, isUp, button)
  end
end
function OverlayMenu:reset()
  for i = 1, table.getn(self.items) do
    self.items[i]:reset()
  end
end
function OverlayMenu:keyEvent(unicode, sym, modifier, isDown)
end
function OverlayMenu:update(dt)
end
function OverlayMenu:render()
  for i = 1, table.getn(self.items) do
    self.items[i]:render()
  end
end
Overlay = {}
local Overlay_mt = Class(Overlay)
function Overlay:new(name, overlayFilename, x, y, width, height)
  if overlayFilename ~= nil then
    tempOverlayId = createOverlay(name, overlayFilename)
  end
  return setmetatable({
    overlayId = tempOverlayId,
    x = x,
    y = y,
    width = width,
    height = height,
    visible = true,
    r = 1,
    g = 1,
    b = 1,
    a = 1
  }, Overlay_mt)
end
function Overlay:delete()
  if self.overlayId ~= nil then
    delete(self.overlayId)
  end
end
function Overlay:setColor(r, g, b, a)
  self.r, self.g, self.b, self.a = r, g, b, a
end
function Overlay:setPosition(x, y)
  self.x = x
  self.y = y
end
function Overlay:setDimension(width, height)
  self.width = width
  self.height = height
end
function Overlay:mouseEvent(posX, posY, isDown, isUp, button)
end
function Overlay:render()
  if self.visible then
    setOverlayColor(self.overlayId, self.r, self.g, self.b, self.a)
    renderOverlay(self.overlayId, self.x, self.y, self.width, self.height)
  end
end
function Overlay:reset()
end
function Overlay:setIsVisible(visible)
  self.visible = visible
end
OverlayButton = {}
local OverlayButton_mt = Class(OverlayButton)
function OverlayButton:new(overlay, onClick, target)
  return setmetatable({
    overlay = overlay,
    onClick = onClick,
    target = target
  }, OverlayButton_mt)
end
function OverlayButton:delete()
  self.overlay:delete()
end
function OverlayButton:mouseEvent(posX, posY, isDown, isUp, button)
  if checkOverlayOverlap(posX, posY, self.overlay) then
    self.overlay:setColor(1, 1, 1, 1)
    if isDown and button == Input.MOUSE_BUTTON_LEFT and self.onClick ~= nil then
      if self.target ~= nil then
        self.onClick(self.target)
      else
        self.onClick()
      end
    end
  else
    self:reset()
  end
end
function OverlayButton:render()
  self.overlay:render()
end
function OverlayButton:reset()
  self.overlay:setColor(1, 1, 1, 0.8)
end
OverlayNumberedButton = {}
local OverlayNumberedButton_mt = Class(OverlayNumberedButton)
function OverlayNumberedButton:new(overlay, number, onClick, target, disabledColor)
  local disabledColor = disabledColor
  if disabledColor == nil then
    disabledColor = {
      0.8,
      0.8,
      0.8,
      0.4
    }
  end
  return setmetatable({
    overlay = overlay,
    number = number,
    onClick = onClick,
    target = target,
    isDisabled = false,
    disabledColor = disabledColor
  }, OverlayNumberedButton_mt)
end
function OverlayNumberedButton:delete()
  self.overlay:delete()
end
function OverlayNumberedButton:mouseEvent(posX, posY, isDown, isUp, button)
  if not self.isDisabled and checkOverlayOverlap(posX, posY, self.overlay) then
    self.overlay:setColor(1, 1, 1, 1)
    if isDown and button == Input.MOUSE_BUTTON_LEFT and self.onClick ~= nil then
      if self.target ~= nil then
        self.onClick(self.target, self.number)
      else
        self.onClick(self.number)
      end
    end
  else
    self:reset()
  end
end
function OverlayNumberedButton:render()
  self.overlay:render()
end
function OverlayNumberedButton:setIsDisabled(isDisabled)
  if self.isDisabled ~= isDisabled then
    self.isDisabled = isDisabled
    self:reset()
  end
end
function OverlayNumberedButton:reset()
  if self.isDisabled then
    self.overlay:setColor(unpack(self.disabledColor))
  else
    self.overlay:setColor(1, 1, 1, 0.8)
  end
end
OverlayCheckbox = {}
local OverlayCheckbox_mt = Class(OverlayCheckbox)
function OverlayCheckbox:new(overlayOn, overlayOff, state, onClick, target)
  overlayOn:setIsVisible(state)
  overlayOff:setIsVisible(not state)
  return setmetatable({
    overlayOn = overlayOn,
    overlayOff = overlayOff,
    state = state,
    onClick = onClick,
    target = target
  }, OverlayCheckbox_mt)
end
function OverlayCheckbox:mouseEvent(posX, posY, isDown, isUp, button)
  if checkOverlayOverlap(posX, posY, self.overlayOn) or checkOverlayOverlap(posX, posY, self.overlayOff) then
    self.overlayOn:setColor(1, 1, 1, 1)
    self.overlayOff:setColor(1, 1, 1, 1)
    if isDown and button == Input.MOUSE_BUTTON_LEFT then
      self.state = not self.state
      if self.target ~= nil then
        self.onClick(self.target, self.state)
      else
        self.onClick(self.state)
      end
      if self.state then
        self.overlayOn:setIsVisible(true)
        self.overlayOff:setIsVisible(false)
      else
        self.overlayOn:setIsVisible(false)
        self.overlayOff:setIsVisible(true)
      end
    end
  else
    self:reset()
  end
end
function OverlayCheckbox:render()
  self.overlayOn:render()
  self.overlayOff:render()
end
function OverlayCheckbox:reset()
  self.overlayOn:setColor(1, 1, 1, 0.8)
  self.overlayOff:setColor(1, 1, 1, 0.8)
end
function OverlayCheckbox:setState(state)
  self.state = state
  self.overlayOn:setIsVisible(state)
  self.overlayOff:setIsVisible(not state)
end
OverlayMultiTextOption = {}
local OverlayMultiTextOption_mt = Class(OverlayMultiTextOption)
function OverlayMultiTextOption:new(overlayMultiText, buttonDown, buttonUp, x, y, s, state, onClick, target)
  return setmetatable({
    overlayMultiText = overlayMultiText,
    buttonDown = buttonDown,
    buttonUp = buttonUp,
    x = x,
    y = y,
    s = s,
    state = state,
    onClick = onClick,
    target = target
  }, OverlayMultiTextOption_mt)
end
function OverlayMultiTextOption:mouseEvent(posX, posY, isDown, isUp, button)
  self.buttonDown:mouseEvent(posX, posY, isDown, isUp, button)
  self.buttonUp:mouseEvent(posX, posY, isDown, isUp, button)
  if isDown and button == Input.MOUSE_BUTTON_LEFT then
    local oldState = self.state
    if checkOverlayOverlap(posX, posY, self.buttonDown.overlay) then
      self.state = self.state - 1
      if self.state <= 0 then
        self.state = 1
      end
    end
    if checkOverlayOverlap(posX, posY, self.buttonUp.overlay) then
      self.state = self.state + 1
      if self.state > table.getn(self.overlayMultiText) then
        self.state = table.getn(self.overlayMultiText)
      end
    end
    if self.onClick ~= nil and oldState ~= self.state then
      if self.target ~= nil then
        self.onClick(self.target, self.state)
      else
        self.onClick(self.state)
      end
    end
  end
end
function OverlayMultiTextOption:render()
  self.buttonDown:render()
  self.buttonUp:render()
  setTextBold(true)
  setTextAlignment(RenderText.ALIGN_CENTER)
  renderText(self.x, self.y, self.s, self.overlayMultiText[self.state])
  setTextBold(false)
  setTextAlignment(RenderText.ALIGN_LEFT)
end
function OverlayMultiTextOption:reset()
  self.buttonDown:reset()
  self.buttonUp:reset()
end

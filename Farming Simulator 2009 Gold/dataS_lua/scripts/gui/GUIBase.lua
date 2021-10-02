function checkOverlayOverlap(posX, posY, overlay)
  return posX >= overlay.x and posX <= overlay.x + overlay.width and posY >= overlay.y and posY <= overlay.y + overlay.height
end
Overlay = {}
local Overlay_mt = Class(Overlay)
function Overlay:new(name, overlayFilename, x, y, width, height)
  if overlayFilename ~= nil then
    tempOverlayId = createImageOverlay(overlayFilename)
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
GUIScreen = {}
local GUIScreen_mt = Class(GUIScreen)
function GUIScreen:new(bgOverlay, customMt)
  if customMt == nil then
    customMt = GUIScreen_mt
  end
  return setmetatable({
    bgOverlay = bgOverlay,
    components = {},
    screenBelow = nil,
    isVisible = true,
    isActive = true
  }, customMt)
end
function GUIScreen:addComponent(component)
  table.insert(self.components, component)
  component.parentComponent = self
end
function GUIScreen:setScreenBelow(screen)
  self.screenBelow = screen
end
function GUIScreen:getScreenBelow()
  return self.screenBelow
end
function GUIScreen:mouseEvent(posX, posY, isDown, isUp, button)
  if self.isActive then
    for _, component in pairs(self.components) do
      component:mouseEvent(posX, posY, isDown, isUp, button)
    end
  end
end
function GUIScreen:keyEvent(unicode, sym, modifier, isDown)
  for _, component in pairs(self.components) do
    component:keyEvent(unicode, sym, modifier, isDown)
  end
end
function GUIScreen:update(dt)
  for _, component in pairs(self.components) do
    if component.update ~= nil then
      component:update(dt)
    end
  end
end
function GUIScreen:delete()
  if self.bgOverlay ~= nil then
    self.bgOverlay:delete()
  end
  for _, component in pairs(self.components) do
    component:delete()
  end
end
function GUIScreen:render()
  if self.isVisible then
    if self.bgOverlay ~= nil then
      self.bgOverlay:render()
    end
    for _, component in pairs(self.components) do
      component:render()
    end
  end
end
function GUIScreen:reset()
  for _, component in pairs(self.components) do
    component:reset()
  end
end
function GUIScreen:enable(chained)
  self.isActive = true
  self.isVisible = true
  if chained then
    self.screenBelow:disable()
  end
end
function GUIScreen:disable(chained)
  self.isActive = false
  self.isVisible = false
  if chained then
    self.screenBelow:enable()
  end
end
VideoScreen = {}
local VideoScreen_mt = Class(VideoScreen)
function VideoScreen:new(videoOverlay, customMt)
  if customMt == nil then
    customMt = VideoScreen_mt
  end
  return setmetatable({
    videoOverlay = videoOverlay,
    isVisible = true,
    isActive = true
  }, customMt)
end
function VideoScreen:mouseEvent(posX, posY, isDown, isUp, button)
  if isDown and isVideoOverlayPlaying(self.videoOverlay) then
    stopVideoOverlay(self.videoOverlay)
    delete(self.videoOverlay)
    if self.onEndVideo ~= nil then
      self.onEndVideo()
    end
  end
end
function VideoScreen:keyEvent(unicode, sym, modifier, isDown)
  if isDown and isVideoOverlayPlaying(self.videoOverlay) then
    stopVideoOverlay(self.videoOverlay)
    delete(self.videoOverlay)
    if self.onEndVideo ~= nil then
      self.onEndVideo()
    end
  end
end
function VideoScreen:update(dt)
  if self.videoOverlay ~= nil and isVideoOverlayPlaying(self.videoOverlay) then
    updateVideoOverlay(self.videoOverlay)
  elseif self.onEndVideo ~= nil then
    self.onEndVideo()
  end
end
function VideoScreen:delete()
  if self.videoOverlay ~= nil then
    delete(self.videoOverlay)
  end
end
function VideoScreen:render()
  if self.isVisible and isVideoOverlayPlaying(self.videoOverlay) then
    renderOverlay(self.videoOverlay, 0.25, 0.2, 0.5, 0.6666666666666666)
  end
end
function VideoScreen:reset()
end
GUIComponent = {}
local GUIComponent_mt = Class(GUIComponent)
function GUIComponent:new(bgOverlay, xPos, yPos, width, height, customMt)
  if customMt == nil then
    customMt = GUIComponent_mt
  end
  if bgOverlay ~= nil then
    if xPos ~= nil and yPos ~= nil then
      bgOverlay.x = xPos
      bgOverlay.y = yPos
    else
      xPos = bgOverlay.x
      yPos = bgOverlay.y
    end
    if width ~= nil and height ~= nil then
      bgOverlay.width = width
      bgOverlay.height = height
    else
      width = bgOverlay.width
      height = bgOverlay.height
    end
  else
    if xPos == nil or yPos == nil then
      xPos = 0
      yPos = 0
    end
    if width == nil or height == nil then
      width = 0
      height = 0
    end
  end
  return setmetatable({
    bgOverlay = bgOverlay,
    xPos = xPos,
    yPos = yPos,
    height = height,
    width = width,
    components = {},
    parentComponent = nil
  }, customMt)
end
function GUIComponent:addComponent(component, isRelative)
  table.insert(self.components, component)
  component.parentComponent = self
  if isRelative and component.xPos ~= nil then
    local newXPos = self.xPos + component.xPos
    local newYPos = self.yPos + component.yPos
    component:setPosition(newXPos, newYPos)
  end
end
function GUIComponent:mouseEvent(posX, posY, isDown, isUp, button)
  for _, component in pairs(self.components) do
    component:mouseEvent(posX, posY, isDown, isUp, button)
  end
end
function GUIComponent:keyEvent(unicode, sym, modifier, isDown)
  for _, component in pairs(self.components) do
    component:keyEvent(unicode, sym, modifier, isDown)
  end
end
function GUIComponent:update(dt)
  for _, component in pairs(self.components) do
    if component.update ~= nil then
      component:update(dt)
    end
  end
end
function GUIComponent:delete()
  if self.bgOverlay ~= nil then
    self.bgOverlay:delete()
  end
  for _, component in pairs(self.components) do
    component:delete()
  end
end
function GUIComponent:render()
  if self.bgOverlay ~= nil then
    self.bgOverlay:render()
  end
  for _, component in pairs(self.components) do
    component:render()
  end
end
function GUIComponent:reset()
  for _, component in pairs(self.components) do
    component:reset()
  end
end
function GUIComponent:setPosition(x, y)
  local xDelta = x - self.xPos
  local yDelta = y - self.yPos
  if self.bgOverlay ~= nil then
    self.bgOverlay.x = x
    self.bgOverlay.y = y
  end
  self.xPos = x
  self.yPos = y
  for _, component in pairs(self.components) do
    component:setPosition(component.xPos + xDelta, component.yPos + yDelta)
  end
end
function GUIComponent:setDimensions(width, height)
  if self.bgOverlay ~= nil then
    self.bgOverlay.width = width
    self.bgOverlay.height = height
  end
  self.width = width
  self.height = height
  for _, component in pairs(self.components) do
    component:setDimensions(self.width * component.width, self.height * component.height)
  end
end
GUIButton = {}
local GUIButton_mt = Class(GUIButton, GUIComponent)
GUIButton.STATE_NORMAL = 1
GUIButton.STATE_PRESSED = 2
GUIButton.STATE_FOCUSED = 3
GUIButton.STATE_DISABLED = 4
GUIButton.STATE_HIDDEN = 5
GUIButton.STATE_CHECKED_NORMAL = 6
GUIButton.STATE_CHECKED_PRESSED = 7
GUIButton.STATE_CHECKED_FOCUSED = 8
GUIButton.STATE_CHECKED_DISABLED = 9
GUIButton.STATE_UNCHECKED_NORMAL = 10
GUIButton.STATE_UNCHECKED_PRESSED = 11
GUIButton.STATE_UNCHECKED_FOCUSED = 12
GUIButton.STATE_UNCHECKED_DISABLED = 13
GUIButton.widthNormal = 0.23
GUIButton.heightNormal = GUIButton.widthNormal / 4 * 1.3333333333333333
GUIButton.widthLong = 0.37375
GUIButton.heightLong = GUIButton.heightNormal
GUIButton.widthShort = 0.17
GUIButton.heightShort = GUIButton.heightNormal
function GUIButton:new(overlays, text, xPos, yPos, width, height, onClick, target, customMt)
  if customMt == nil then
    customMt = GUIButton_mt
  end
  local instance = GUIButton:superClass():new(nil, xPos, yPos, width, height, customMt)
  if xPos ~= nil and yPos ~= nil then
    for _, overlay in pairs(overlays) do
      overlay.x = xPos
      overlay.y = yPos
      overlay.width = width
      overlay.height = height
    end
  end
  instance.overlays = overlays
  instance.text = text
  instance.onClick = onClick
  instance.target = target
  instance.state = GUIButton.STATE_NORMAL
  instance.renderState = GUIButton.STATE_NORMAL
  instance.isActive = true
  instance.xPos = xPos
  instance.yPos = yPos
  instance.width = width
  instance.height = height
  instance.mouseDown = false
  instance.mouseEntered = false
  instance.textOffsetY = 0.0135
  instance.textSize = 0.0345
  return instance
end
function GUIButton:delete()
  for _, overlay in pairs(self.overlays) do
    overlay:delete()
  end
end
function GUIButton:mouseEvent(posX, posY, isDown, isUp, button)
  if self.isActive then
    if self.overlays[self.renderState] ~= nil then
      if checkOverlayOverlap(posX, posY, self.overlays[self.renderState]) then
        self.state = GUIButton.STATE_FOCUSED
        self.renderState = GUIButton.STATE_FOCUSED
        if self.onHover ~= nil then
          self.mouseEntered = true
          self.onHover()
        end
        if isDown and button == Input.MOUSE_BUTTON_LEFT then
          self.mouseDown = true
        end
        if isUp and button == Input.MOUSE_BUTTON_LEFT and self.mouseDown then
          self.mouseDown = false
          if self.onClick ~= nil then
            if self.target ~= nil then
              self.onClick(self.target)
            else
              self.onClick()
            end
          end
        end
        if self.mouseDown then
          self.state = GUIButton.STATE_PRESSED
          self.renderState = GUIButton.STATE_PRESSED
        end
      else
        if self.onLeave ~= nil and self.mouseEntered then
          self.mouseEntered = false
          self.onLeave()
        end
        self.mouseDown = false
        self:reset()
      end
    else
      self.mouseDown = false
      self:reset()
    end
  end
end
function GUIButton:render()
  if self.state ~= GUIButton.STATE_HIDDEN then
    self.renderState = self.state
    if self.overlays[self.state] == nil then
      if self.state == GUIButton.STATE_PRESSED and self.overlays[GUIButton.STATE_FOCUSED] ~= nil then
        self.renderState = GUIButton.STATE_FOCUSED
      elseif self.state == GUIButton.STATE_FOCUSED and self.overlays[GUIButton.STATE_PRESSED] ~= nil then
        self.renderState = GUIButton.STATE_PRESSED
      else
        self.renderState = GUIButton.STATE_NORMAL
      end
    end
    self.overlays[self.renderState]:render()
    if self.text ~= nil and self.text ~= "" then
      setTextAlignment(RenderText.ALIGN_CENTER)
      setTextBold(true)
      if self.state ~= GUIButton.STATE_DISABLED then
        setTextColor(0, 0, 0, 0.75)
        renderText(self.xPos + self.width / 2 * 0.96, self.yPos + self.textOffsetY - 0.003, self.textSize, self.text)
        setTextColor(1, 1, 1, 1)
      else
        setTextColor(1, 1, 1, 0.5)
      end
      renderText(self.xPos + self.width / 2 * 0.96, self.yPos + self.textOffsetY, self.textSize, self.text)
      setTextBold(false)
      setTextAlignment(RenderText.ALIGN_LEFT)
      setTextColor(1, 1, 1, 1)
    end
  end
end
function GUIButton:reset()
  self.state = GUIButton.STATE_NORMAL
end
function GUIButton:setActive(isActive)
  self.isActive = isActive
  if self.isActive then
    self.state = GUIButton.STATE_NORMAL
  else
    self.state = GUIButton.STATE_DISABLED
  end
end
function GUIButton:setPosition(x, y)
  self.xPos = x
  self.yPos = y
  for _, overlay in pairs(self.overlays) do
    overlay.x = self.xPos
    overlay.y = self.yPos
  end
end
function GUIButton:setSize(width, height)
  self.width = width
  self.height = height
  for _, overlay in pairs(self.overlays) do
    overlay.width = width
    overlay.height = height
  end
end
GUIToggleButton = {}
local GUIToggleButton_mt = Class(GUIToggleButton, GUIButton)
function GUIToggleButton:new(overlays, text, xPos, yPos, width, height, isChecked, onClick, target)
  local instance = GUIToggleButton:superClass():new(overlays, text, xPos, yPos, width, height, onClick, target, GUIToggleButton_mt)
  instance.isChecked = isChecked
  if isChecked then
    instance.state = GUIButton.STATE_CHECKED_NORMAL
  else
    instance.state = GUIButton.STATE_UNCHECKED_NORMAL
  end
  instance.label = ""
  instance.labelXOffset = -0.015
  instance.labelYOffset = 0.02
  instance.labelSize = 0.033
  return instance
end
function GUIToggleButton:mouseEvent(posX, posY, isDown, isUp, button)
  if self.isActive then
    if self.overlays[self.state] ~= nil and checkOverlayOverlap(posX, posY, self.overlays[self.state]) then
      if isDown and button == Input.MOUSE_BUTTON_LEFT then
        self.mouseDown = true
      end
      if self.mouseDown and isUp and button == Input.MOUSE_BUTTON_LEFT then
        self.mouseDown = false
        self.isChecked = not self.isChecked
        if self.onClick ~= nil then
          if self.target ~= nil then
            self.onClick(self.isChecked, self.target)
          else
            self.onClick(self.isChecked)
          end
        end
      end
      if self.mouseDown then
        if self.isChecked then
          self.state = GUIButton.STATE_CHECKED_PRESSED
        else
          self.state = GUIButton.STATE_UNCHECKED_PRESSED
        end
      elseif self.isChecked then
        self.state = GUIButton.STATE_CHECKED_FOCUSED
      else
        self.state = GUIButton.STATE_UNCHECKED_FOCUSED
      end
    else
      self.mouseDown = false
      self:reset()
    end
  end
end
function GUIToggleButton:render()
  if self.state ~= GUIButton.STATE_HIDDEN then
    if self.overlays[self.state] == nil then
      if self.isChecked then
        self.state = GUIButton.STATE_CHECKED_NORMAL
      else
        self.state = GUIButton.STATE_UNCHECKED_NORMAL
      end
    end
    if self.label ~= "" then
      setTextColor(0, 0, 0, 1)
      setTextBold(true)
      setTextAlignment(RenderText.ALIGN_RIGHT)
      renderText(self.xPos + self.labelXOffset, self.yPos + self.labelYOffset - 0.002, self.labelSize, self.label)
      setTextColor(1, 1, 1, 1)
      renderText(self.xPos + self.labelXOffset, self.yPos + self.labelYOffset, self.labelSize, self.label)
      setTextAlignment(RenderText.ALIGN_LEFT)
      setTextBold(false)
    end
    self.overlays[self.state]:render()
  end
end
function GUIToggleButton:reset()
  if self.isChecked then
    self.state = GUIButton.STATE_CHECKED_NORMAL
  else
    self.state = GUIButton.STATE_UNCHECKED_NORMAL
  end
end
function GUIToggleButton:setActive(isActive)
  self.isActive = isActive
  if self.isActive then
    if self.isChecked then
      self.state = GUIButton.STATE_CHECKED_NORMAL
    else
      self.state = GUIButton.STATE_UNCHECKED_NORMAL
    end
  elseif self.isChecked then
    self.state = GUIButton.STATE_CHECKED_DISABLED
  else
    self.state = GUIButton.STATE_UNCHECKED_DISABLED
  end
end
GUISlider = {}
local GUISlider_mt = Class(GUISlider, GUIComponent)
function GUISlider:new(sliderBaseOverlay, sliderOverlay, valueTexts, xPos, yPos, width, height, onClick, target)
  local instance = GUISlider:superClass():new(nil, xPos, yPos, width, height, GUISlider_mt)
  if xPos ~= nil and yPos ~= nil then
    sliderBaseOverlay.x = xPos
    sliderBaseOverlay.y = yPos
    sliderBaseOverlay.width = width
    sliderBaseOverlay.height = height
  end
  instance.sliderBaseOverlay = sliderBaseOverlay
  instance.sliderOverlay = sliderOverlay
  instance.valueTexts = valueTexts
  instance.onClick = onClick
  instance.target = target
  instance.isActive = true
  instance.xPos = xPos
  instance.yPos = yPos
  instance.width = width
  instance.height = height
  instance.minValue = 0
  instance.maxValue = 100
  instance.currentValue = 0
  instance.minXPos = 0.08
  instance.maxXPos = 0.92
  instance.stepSize = 1
  instance.minAbsXPos = instance.sliderBaseOverlay.x + instance.sliderBaseOverlay.width * instance.minXPos
  instance.maxAbsXPos = instance.sliderBaseOverlay.x + instance.sliderBaseOverlay.width * instance.maxXPos
  instance.mouseDown = false
  instance.showValue = true
  instance.textOffset = 0.008
  instance.textSize = 0.033
  instance.label = ""
  instance.labelXOffset = -0.015
  instance.labelYOffset = 0.008
  instance.labelSize = 0.033
  instance.sliderHandleYOffset = -0.012
  instance:updateSliderPosition()
  return instance
end
function GUISlider:delete()
  self.sliderBaseOverlay:delete()
  self.sliderOverlay:delete()
end
function GUISlider:mouseEvent(posX, posY, isDown, isUp, button)
  if self.isActive then
    if self.mouseDown and isUp and button == Input.MOUSE_BUTTON_LEFT then
      self.mouseDown = false
      if self.onClick ~= nil then
        if self.target ~= nil then
          self.onClick(self.currentValue, self.target)
        else
          self.onClick(self.currentValue)
        end
      end
    end
    if checkOverlayOverlap(posX, posY, self.sliderBaseOverlay) or checkOverlayOverlap(posX, posY, self.sliderOverlay) then
      if Input.isMouseButtonPressed(Input.MOUSE_BUTTON_WHEEL_UP) then
        self.currentValue = math.min(self.currentValue + self.stepSize, self.maxValue)
        self:updateSliderPosition()
      end
      if Input.isMouseButtonPressed(Input.MOUSE_BUTTON_WHEEL_DOWN) then
        self.currentValue = math.max(self.currentValue - self.stepSize, self.minValue)
        self:updateSliderPosition()
      end
      if isDown and button == Input.MOUSE_BUTTON_LEFT then
        self.mouseDown = true
      end
    end
    if self.mouseDown then
      self.currentValue = self.minValue + (posX - self.minAbsXPos) / (self.maxAbsXPos - self.minAbsXPos) * (self.maxValue - self.minValue)
      local valueFloor = self.currentValue - self.currentValue % self.stepSize
      local valueCeil = self.currentValue + self.stepSize - self.currentValue % self.stepSize
      if self.currentValue - valueFloor < valueCeil - self.currentValue then
        self.currentValue = valueFloor
      else
        self.currentValue = valueCeil
      end
      self.currentValue = math.min(self.currentValue, self.maxValue)
      self.currentValue = math.max(self.currentValue, self.minValue)
      self.currentValue = math.floor(self.currentValue + 0.01)
      self:updateSliderPosition()
    end
  end
end
function GUISlider:render()
  self.sliderBaseOverlay:render()
  self.sliderOverlay:render()
  local text = tostring(self.currentValue)
  if self.valueTexts ~= nil then
    text = self.valueTexts[self.currentValue]
    if text == nil then
      text = tostring(self.currentValue)
    end
  end
  if self.showValue then
    setTextColor(0, 0, 0, 1)
    setTextBold(true)
    renderText(self.xPos + self.width + 0.005, self.yPos + self.textOffset - 0.002, self.textSize, text)
    setTextColor(1, 1, 1, 1)
    renderText(self.xPos + self.width + 0.005, self.yPos + self.textOffset, self.textSize, text)
    setTextBold(false)
  end
  if self.label ~= "" then
    setTextColor(0, 0, 0, 1)
    setTextBold(true)
    setTextAlignment(RenderText.ALIGN_RIGHT)
    renderText(self.xPos + self.labelXOffset, self.yPos + self.labelYOffset - 0.002, self.labelSize, self.label)
    setTextColor(1, 1, 1, 1)
    renderText(self.xPos + self.labelXOffset, self.yPos + self.labelYOffset, self.labelSize, self.label)
    setTextAlignment(RenderText.ALIGN_LEFT)
    setTextBold(false)
  end
end
function GUISlider:reset()
end
function GUISlider:updateSliderPosition()
  self.sliderOverlay.y = self.sliderBaseOverlay.y + self.sliderHandleYOffset
  self.sliderOverlay.x = self.minAbsXPos + (self.maxAbsXPos - self.minAbsXPos) * ((self.currentValue - self.minValue) / (self.maxValue - self.minValue)) - self.sliderOverlay.width / 2
end
function GUISlider:setPosition(x, y)
  self.xPos = x
  self.yPos = y
  self.sliderBaseOverlay.x = x
  self.sliderBaseOverlay.y = y
  self.minAbsXPos = self.sliderBaseOverlay.x + self.sliderBaseOverlay.width * self.minXPos
  self.maxAbsXPos = self.sliderBaseOverlay.x + self.sliderBaseOverlay.width * self.maxXPos
  self:updateSliderPosition()
end
function GUISlider:setCurrentValue(currentValue)
  self.currentValue = currentValue
  self:updateSliderPosition()
end
GUIEditor = {}
local GUIEditor_mt = Class(GUIEditor, GUIComponent)
GUIEditor.ACCEPTED_KEYS = {
  "64-90",
  "97-122",
  "48-57",
  "45",
  "32",
  "39",
  "46",
  "228",
  "246",
  "252",
  "196",
  "214",
  "220",
  "233",
  "232"
}
function GUIEditor:new(overlays, xPos, yPos, width, height, onClick, target)
  local instance = GUIEditor:superClass():new(nil, xPos, yPos, width, height, GUIEditor_mt)
  if xPos ~= nil and yPos ~= nil then
    for _, overlay in pairs(overlays) do
      overlay.x = xPos
      overlay.y = yPos
      overlay.width = width
      overlay.height = height
    end
  end
  instance.overlays = overlays
  instance.text = text
  instance.onClick = onClick
  instance.target = target
  instance.state = GUIButton.STATE_NORMAL
  instance.isActive = true
  instance.xPos = xPos
  instance.yPos = yPos
  instance.width = width
  instance.height = height
  instance.mouseDown = false
  instance.textLine = ""
  instance.oldTextLine = ""
  instance.maxTextLength = 32
  instance.cursorBlinkingInterval = 50
  instance.currentCursorTime = 0
  instance.cursorChar = "|"
  instance.keyboardActive = false
  return instance
end
function GUIEditor:mouseEvent(posX, posY, isDown, isUp, button)
  if self.isActive then
    if self.overlays[self.state] ~= nil and checkOverlayOverlap(posX, posY, self.overlays[self.state]) then
      self.state = GUIButton.STATE_FOCUSED
      if isDown and button == Input.MOUSE_BUTTON_LEFT then
        self.mouseDown = true
      end
      if isUp and button == Input.MOUSE_BUTTON_LEFT and self.mouseDown then
        self.mouseDown = false
        self.keyboardActive = true
        g_mouse:showMouse(false)
        g_mouse:enableMouse(false)
        self.oldTextLine = self.textLine
      end
    else
      self.mouseDown = false
      self:reset()
    end
  end
end
function GUIEditor:keyEvent(unicode, sym, modifier, isDown)
  if self.keyboardActive and isDown then
    if unicode == 8 then
      if string.len(self.textLine) > 0 then
        self.textLine = string.sub(self.textLine, 1, string.len(self.textLine) - 1)
        self.cursorChar = "|"
        self.currentCursorTime = 0
      end
    elseif unicode == 13 or unicode == 27 then
      self.keyboardActive = false
      g_mouse:enableMouse(true)
      g_mouse:showMouse(true)
      if unicode == 27 then
        self.textLine = self.oldTextLine
      elseif self.onClick ~= nil then
        if self.target ~= nil then
          self.onClick(self.textLine, self.target)
        else
          self.onClick(self.textLine)
        end
      end
    elseif string.len(self.textLine) < self.maxTextLength then
      keyAccepted = false
      for _, number in pairs(GUIEditor.ACCEPTED_KEYS) do
        if unicode == tonumber(number) then
          keyAccepted = true
        end
        for k, v in string.gmatch(number, "(%w+)-(%w+)") do
          if unicode >= tonumber(k) and unicode <= tonumber(v) then
            keyAccepted = true
          end
        end
        if keyAccepted then
          break
        end
      end
      if keyAccepted then
        local char = string.char(unicode)
        self.textLine = self.textLine .. char
        self.cursorChar = "|"
        self.currentCursorTime = 0
      end
    end
  end
end
function GUIEditor:render()
  if self.state ~= GUIButton.STATE_HIDDEN then
    if self.keyboardActive then
      self.currentCursorTime = self.currentCursorTime + 1
      if self.currentCursorTime >= self.cursorBlinkingInterval then
        self.currentCursorTime = 0
        if self.cursorChar == "" then
          self.cursorChar = "|"
        else
          self.cursorChar = ""
        end
      end
    end
    if self.overlays[self.state] ~= nil then
      self.overlays[self.state]:render()
    elseif self.overlays[GUIButton.STATE_NORMAL] ~= nil then
      self.overlays[GUIButton.STATE_NORMAL]:render()
    end
    if self.keyboardActive then
      setTextColor(0, 0, 0, 1)
      renderText(self.xPos + 0.005, self.yPos + 0.009, 0.035, self.textLine .. self.cursorChar)
      setTextColor(1, 1, 1, 1)
      renderText(self.xPos + 0.005, self.yPos + 0.012, 0.035, self.textLine .. self.cursorChar)
    elseif self.textLine ~= "" then
      setTextColor(0, 0, 0, 1)
      renderText(self.xPos + 0.005, self.yPos + 0.009, 0.035, self.textLine)
      setTextColor(1, 1, 1, 1)
      renderText(self.xPos + 0.005, self.yPos + 0.012, 0.035, self.textLine)
    end
  end
end
function GUIEditor:delete()
  for _, overlay in pairs(self.overlays) do
    overlay:delete()
  end
end
function GUIEditor:reset()
  self.state = GUIButton.STATE_NORMAL
end
function GUIEditor:setPosition(x, y)
  self.xPos = x
  self.yPos = y
  for _, overlay in pairs(self.overlays) do
    overlay.x = self.xPos
    overlay.y = self.yPos
  end
end
GUIDialogBox = {}
local GUIDialogBox_mt = Class(GUIDialogBox, GUIScreen)
function GUIDialogBox:new(dialogOverlay, titleText, dialogText, button1Text, button2Text, xPos, yPos, width, height, onClick, target)
  local instance = GUIDialogBox:superClass():new(nil, GUIDialogBox_mt)
  instance.titleText = titleText
  instance.dialogText = dialogText
  instance.button1Text = button1Text
  instance.button2Text = button2Text
  instance.xPos = xPos
  instance.yPos = yPos
  instance.width = width
  instance.height = height
  instance.onClick = onClick
  instance.target = target
  instance.isDraggable = true
  instance.isDragging = false
  instance.dragOffsetX = 0
  instance.dragOffsetY = 0
  dialogOverlay.width = width
  dialogOverlay.height = height
  dialogOverlay.x = xPos
  dialogOverlay.y = yPos
  instance.dialogBackground = GUIComponent:new(dialogOverlay)
  instance.dialogBackground.width = instance.width
  instance.dialogBackground.height = instance.height
  instance:addComponent(instance.dialogBackground)
  local nbOfButtons = 2
  local buttonWidth = 0.17
  local buttonHeight = 0.06
  local buttonPosX = {}
  if button2Text == nil or button2Text == "" then
    nbOfButtons = 1
  end
  if nbOfButtons == 1 then
    buttonPosX[1] = instance.xPos + instance.width / 2 - buttonWidth / 2
  end
  if nbOfButtons == 2 then
    buttonPosX[1] = instance.xPos + instance.width / 4 - buttonWidth / 2
    buttonPosX[2] = instance.xPos + 3 * (instance.width / 4) - buttonWidth / 2
  end
  local overlays = {}
  local buttonFilenames = {
    [GUIButton.STATE_NORMAL] = "button_normal",
    [GUIButton.STATE_FOCUSED] = "button_focused",
    [GUIButton.STATE_PRESSED] = "button_pressed"
  }
  for state, filename in pairs(buttonFilenames) do
    overlays[state] = Overlay:new(filename, "data/menu/" .. filename .. ".png")
  end
  local button1 = GUIButton:new(overlays, button1Text, buttonPosX[1], instance.yPos + 0.025, buttonWidth, buttonHeight)
  overlays = {}
  for state, filename in pairs(buttonFilenames) do
    overlays[state] = Overlay:new(filename, "data/menu/" .. filename .. ".png")
  end
  instance:addComponent(button1)
  function button1.onClick()
    instance:onDialogClick(1)
  end
  if 1 < nbOfButtons then
    local button2 = GUIButton:new(overlays, button2Text, buttonPosX[2], instance.yPos + 0.025, buttonWidth, buttonHeight)
    instance:addComponent(button2)
    function button2.onClick()
      instance:onDialogClick(2)
    end
  end
  return instance
end
function GUIDialogBox:mouseEvent(posX, posY, isDown, isUp, button)
  if self.isActive then
    for _, component in pairs(self.components) do
      component:mouseEvent(posX, posY, isDown, isUp, button)
    end
    if self.isDraggable then
      if isDown and g_mouse:checkRectangle(self.xPos, self.yPos + self.height * 4 / 5, self.width, self.height / 5) then
        self.isDragging = true
        self.dragOffsetX = self.xPos - posX
        self.dragOffsetY = self.yPos - posY
      end
      if isUp and self.isDragging then
        self.isDragging = false
        local xPosFinal = self.xPos
        local yPosFinal = self.yPos
        if self.xPos < 0 then
          xPosFinal = 0
        elseif self.xPos > 1 - self.width then
          xPosFinal = 1 - self.width
        end
        if self.yPos < 0 then
          yPosFinal = 0
        elseif self.yPos > 1 - self.height then
          yPosFinal = 1 - self.height
        end
        self:setPosition(xPosFinal, yPosFinal)
      end
      if self.isDragging then
        self:setPosition(posX + self.dragOffsetX, posY + self.dragOffsetY)
      end
    end
  end
end
function GUIDialogBox:render()
  if self.isVisible then
    GUIDialogBox:superClass().render(self)
    setTextColor(0, 0, 0, 0.75)
    setTextBold(true)
    renderText(self.xPos + self.width * 0.017, self.yPos + self.height - 0.051, 0.035, self.titleText)
    renderText(self.xPos + self.width * 0.017, self.yPos + self.height - 0.095, 0.035, self.dialogText)
    setTextColor(0.5, 0.8, 1, 1)
    renderText(self.xPos + self.width * 0.017, self.yPos + self.height - 0.048, 0.035, self.titleText)
    setTextColor(1, 1, 1, 1)
    renderText(self.xPos + self.width * 0.017, self.yPos + self.height - 0.092, 0.035, self.dialogText)
    setTextBold(false)
  end
end
function GUIDialogBox:delete()
  if self.bgOverlay ~= nil then
    self.bgOverlay:delete()
  end
end
function GUIDialogBox:reset()
end
function GUIDialogBox:onDialogClick(buttonNb)
  self.isVisible = false
  self.isActive = false
  if self.screenBelow ~= nil then
    self.screenBelow.isActive = true
    self.screenBelow.isVisible = true
  end
  self.onClick(buttonNb, self)
end
function GUIDialogBox:setPosition(x, y)
  local xDelta = x - self.xPos
  local yDelta = y - self.yPos
  self.xPos = x
  self.yPos = y
  for _, component in pairs(self.components) do
    component:setPosition(component.xPos + xDelta, component.yPos + yDelta)
  end
end
GUIControlsScreen = {}
local GUIControlsScreen_mt = Class(GUIControlsScreen, GUIScreen)
function GUIControlsScreen:new(xPos, yPos, width, height, onClick, target)
  local bgOverlay = Overlay:new("bgOverlay", "dataS/menu/background01" .. g_languageSuffix .. ".png", 0, 0, 1, 1)
  local instance = GUIControlsScreen:superClass():new(bgOverlay, GUIControlsScreen_mt)
  instance.xPos = xPos
  instance.yPos = yPos
  instance.width = width
  instance.height = height
  local controlsBGOverlay = Overlay:new("controlsBGOverlay", "data/menu/controlpanel.png")
  instance.controlsBackground = GUIComponent:new(controlsBGOverlay, xPos, yPos, width, height)
  instance:addComponent(instance.controlsBackground)
  instance.userMadeChanges = false
  instance.list = GUIList:new(nil, 0.04 + xPos, 0.25 + yPos, width, 0.6 * height)
  instance.controlsBackground:addComponent(instance.list)
  instance.controlsMessage1 = g_i18n:getText("SelectActionToRemap")
  instance.controlsMessage2 = ""
  instance.controlsMessageStandardColor = {
    0.8,
    0.8,
    1,
    1
  }
  instance.controlsMessageWarningColor = {
    1,
    0.3,
    0.3,
    1
  }
  instance.controlsMessageColor = instance.controlsMessageStandardColor
  instance.titleText = g_i18n:getText("ButtonControls")
  local buttonWidth = 0.18
  local buttonHeight = buttonWidth / 4 * 1.3333333333333333
  local overlays = {}
  local buttonFilenames = {
    [GUIButton.STATE_NORMAL] = "button_normal",
    [GUIButton.STATE_FOCUSED] = "button_focused",
    [GUIButton.STATE_PRESSED] = "button_pressed"
  }
  for state, filename in pairs(buttonFilenames) do
    overlays[state] = Overlay:new(filename, "data/menu/" .. filename .. ".png")
  end
  instance.buttonDefaults = GUIButton:new(overlays, g_i18n:getText("ButtonDefaults"), instance.xPos + 0.04, instance.yPos + 0.06, buttonWidth, buttonHeight)
  instance.controlsBackground:addComponent(instance.buttonDefaults)
  function instance.buttonDefaults.onClick()
    instance.userMadeChanges = true
    instance:loadBindings("data/inputBindingDefault.xml")
  end
  overlays = {}
  for state, filename in pairs(buttonFilenames) do
    overlays[state] = Overlay:new(filename, "data/menu/" .. filename .. ".png")
  end
  instance.buttonSave = GUIButton:new(overlays, g_i18n:getText("ButtonSave"), instance.xPos + 0.55 * instance.width, instance.yPos + 0.06, buttonWidth, buttonHeight)
  instance.controlsBackground:addComponent(instance.buttonSave)
  function instance.buttonSave.onClick()
    instance:saveBindings(g_inputBindingPath)
    InputBinding:load()
    instance.userMadeChanges = false
    instance:disable(false)
    gameMenuSystem.currentMenu = gameMenuSystem.settingsMenu
  end
  overlays = {}
  for state, filename in pairs(buttonFilenames) do
    overlays[state] = Overlay:new(filename, "data/menu/" .. filename .. ".png")
  end
  instance.buttonCancel = GUIButton:new(overlays, g_i18n:getText("ButtonCancel"), instance.xPos + 0.76 * instance.width, instance.yPos + 0.06, buttonWidth, buttonHeight)
  instance.controlsBackground:addComponent(instance.buttonCancel)
  function instance.buttonCancel.onClick()
    if instance.userMadeChanges then
      instance.dialogBoxScreen.isActive = true
      instance.dialogBoxScreen.isVisible = true
      instance.isActive = false
    else
      instance:disable(false)
      gameMenuSystem.currentMenu = gameMenuSystem.settingsMenu
    end
  end
  instance.dialogBoxScreen = GUIScreen:new(bgOverlay)
  local dialogOverlay = Overlay:new("dialogOverlay", "dataS/menu/dialog_bg.png", 0.3, 0.5, 0.4, 0.26666666666666666)
  instance.dialogBox = GUIDialogBox:new(dialogOverlay, g_i18n:getText("LoseChangesTitle"), g_i18n:getText("LoseChangesText"), g_i18n:getText("DialogYes"), g_i18n:getText("DialogNo"), 0.3, 0.5, 0.4, 0.26666666666666666)
  instance.dialogBoxScreen:addComponent(instance.dialogBox)
  instance.dialogBoxScreen.isActive = false
  instance.dialogBoxScreen.isVisible = false
  function instance.dialogBox.onClick(buttonNb)
    instance.dialogBoxScreen.isActive = false
    instance.dialogBoxScreen.isVisible = false
    instance.dialogBox.isActive = true
    instance.dialogBox.isVisible = true
    instance.isActive = true
    if buttonNb == 1 then
      instance.userMadeChanges = false
      instance:disable(false)
      gameMenuSystem.currentMenu = gameMenuSystem.settingsMenu
    end
  end
  function instance.list.onClick(rowNumber, columnNumber)
    instance.list.clickedItem = instance.list.firstVisibleItem + rowNumber - 1
    instance.list.clickedColumn = columnNumber
    if instance.list.listItems[instance.list.clickedItem][instance.list.listColumnNames[columnNumber]] == "--" then
      if instance.list.listColumnNames[columnNumber] == "mouse" then
        instance.controlsMessage1 = g_i18n:getText("CannotMapMouseHere")
      elseif string.sub(instance.list.listColumnNames[columnNumber], 1, 3) == "key" then
        instance.controlsMessage1 = g_i18n:getText("CannotMapKeyHere")
      else
        instance.controlsMessage1 = g_i18n:getText("CannotMapGamepadHere")
      end
      instance.controlsMessage2 = ""
      instance.controlsMessageColor = instance.controlsMessageWarningColor
      return false
    else
      instance.buttonDefaults:setActive(false)
      instance.buttonSave:setActive(false)
      instance.buttonCancel:setActive(false)
      if string.sub(instance.list.listColumnNames[columnNumber], 1, 3) == "key" then
        instance.controlsMessage1 = string.format(g_i18n:getText("PressKeyToMap"), instance.list.listItems[instance.list.clickedItem].action)
      end
      if instance.list.listColumnNames[columnNumber] == "mouse" then
        instance.controlsMessage1 = string.format(g_i18n:getText("PressMouseButtonToMap"), instance.list.listItems[instance.list.clickedItem].action)
      end
      if instance.list.listColumnNames[columnNumber] == "gamepad" then
        instance.controlsMessage1 = string.format(g_i18n:getText("PressGamepadButtonToMap"), instance.list.listItems[instance.list.clickedItem].action)
      end
      instance.controlsMessage2 = g_i18n:getText("PressESCToCancel")
      instance.controlsMessageColor = instance.controlsMessageStandardColor
      instance.waitForInput = true
      return true
    end
  end
  instance:loadBindings(g_inputBindingPath)
  return instance
end
function GUIControlsScreen:loadBindings(xmlFileName)
  self.list.listItems = {}
  local xmlFile = loadXMLFile("InputBindings", xmlFileName)
  local i = 0
  while true do
    local baseName = string.format("inputBinding.axis(%d)", i)
    local inputName = getXMLString(xmlFile, baseName .. "#name")
    if inputName == nil then
      break
    end
    local inputAxis = Utils.getNoNil(getXMLString(xmlFile, baseName .. "#axis"), "")
    local inputInvert = getXMLString(xmlFile, baseName .. "#invert")
    local inputKey = {}
    local key = {}
    for i = 1, 4 do
      inputKey[i] = Utils.getNoNil(getXMLString(xmlFile, baseName .. "#key" .. i), "")
      key[i] = ""
      if inputKey[i] ~= "" then
        for _, specialKey in pairs(Input.SpecialKeys) do
          if inputKey[i] == specialKey.input then
            key[i] = specialKey.name
            break
          end
        end
        if key[i] == "" then
          key[i] = string.char(Input[inputKey[i]])
        end
      end
    end
    local inputAxisName = ""
    for _, axesMapping in pairs(Input.AxesMapping) do
      if axesMapping.input == inputAxis then
        inputAxisName = axesMapping.name
        break
      end
    end
    table.insert(self.list.listItems, {
      action = g_i18n:getText(inputName .. "_1"),
      key1 = key[2],
      key2 = key[4],
      mouse = "--",
      gamepad = inputAxisName,
      inputKey1 = inputKey[2],
      inputKey2 = inputKey[4],
      inputButton = "",
      inputMouseButton = "",
      inputName = inputName,
      inputAxis = inputAxis,
      inputInvert = inputInvert
    })
    table.insert(self.list.listItems, {
      action = g_i18n:getText(inputName .. "_2"),
      key1 = key[1],
      key2 = key[3],
      mouse = "--",
      gamepad = inputAxisName,
      inputKey1 = inputKey[1],
      inputKey2 = inputKey[3],
      inputButton = "",
      inputMouseButton = "",
      inputName = inputName,
      inputAxis = inputAxis,
      inputInvert = inputInvert
    })
    i = i + 1
  end
  i = 0
  while true do
    local baseName = string.format("inputBinding.input(%d)", i)
    local inputName = getXMLString(xmlFile, baseName .. "#name")
    if inputName == nil then
      break
    end
    local inputKey1 = Utils.getNoNil(getXMLString(xmlFile, baseName .. "#key1"), "")
    local inputKey2 = Utils.getNoNil(getXMLString(xmlFile, baseName .. "#key2"), "")
    local inputButton = Utils.getNoNil(getXMLString(xmlFile, baseName .. "#button"), "")
    local inputMouseButton = Utils.getNoNil(getXMLString(xmlFile, baseName .. "#mouse"), "")
    if inputKey1 == "" and inputKey2 == "" then
      local inputKeyOld = Utils.getNoNil(getXMLString(xmlFile, baseName .. "#key"), "")
      if inputKeyOld ~= "" then
        inputKey1 = inputKeyOld
      end
    end
    if inputKey1 == nil and inputKey2 == nil and inputButton == nil and inputMouseButton == nil then
      print("GUIBase Error: no button or key specified for input event '" .. inputName .. "'")
      break
    end
    local key1 = ""
    if inputKey1 ~= "" then
      for _, specialKey in pairs(Input.SpecialKeys) do
        if inputKey1 == specialKey.input then
          key1 = specialKey.name
          break
        end
      end
      if key1 == "" then
        key1 = string.char(Input[inputKey1])
      end
    end
    local key2 = ""
    if inputKey2 ~= "" then
      for _, specialKey in pairs(Input.SpecialKeys) do
        if inputKey2 == specialKey.input then
          key2 = specialKey.name
          break
        end
      end
      if key2 == "" then
        key2 = string.char(Input[inputKey2])
      end
    end
    local gamepad = ""
    if inputButton ~= "" then
      gamepad = "Button " .. Input[inputButton] + 1
    end
    local mouse = ""
    if inputMouseButton ~= "" then
      for _, specialKey in pairs(Input.SpecialKeys) do
        if inputMouseButton == specialKey.input then
          mouse = specialKey.name
          break
        end
      end
      if inputMouseButton == "--" then
        mouse = "--"
        inputMouseButton = ""
      end
    end
    table.insert(self.list.listItems, {
      action = g_i18n:getText(inputName),
      key1 = key1,
      key2 = key2,
      mouse = mouse,
      gamepad = gamepad,
      inputKey1 = inputKey1,
      inputKey2 = inputKey2,
      inputButton = inputButton,
      inputMouseButton = inputMouseButton,
      inputName = inputName
    })
    i = i + 1
  end
  if #self.list.listItems <= self.list.visibleItems then
    self.list.listSlider:setPosition(0.836, self.list.listSlider.highestPos)
    self.list.listSlider.isActive = false
  else
    self.list.listSlider.isActive = true
  end
  delete(xmlFile)
end
function GUIControlsScreen:saveBindings(xmlFile)
  local bindingsFile, errorMsg = io.open(xmlFile, "w")
  if bindingsFile ~= nil then
    bindingsFile:write([[
<?xml version="1.0" encoding="utf-8" standalone="no" ?>
<inputBinding version="]] .. string.format("%1.1f", InputBinding.version) .. "\">\n")
    axisPair = false
    tempListItem = nil
    for _, listItem in pairs(self.list.listItems) do
      if string.sub(listItem.inputName, 1, 4) == "AXIS" then
        if not axisPair then
          tempListItem = listItem
          axisPair = true
        else
          bindingsFile:write("    <axis name=\"" .. listItem.inputName .. "\" key1=\"" .. listItem.inputKey1 .. "\" key2=\"" .. tempListItem.inputKey1 .. "\" key3=\"" .. listItem.inputKey2 .. "\" key4=\"" .. tempListItem.inputKey2 .. "\" axis=\"" .. listItem.inputAxis .. "\" invert=\"" .. listItem.inputInvert .. "\"/>\n")
          axisPair = false
        end
      elseif listItem.mouse == "--" then
        bindingsFile:write("    <input name=\"" .. listItem.inputName .. "\" key1=\"" .. listItem.inputKey1 .. "\" key2=\"" .. listItem.inputKey2 .. "\" button=\"" .. listItem.inputButton .. "\" mouse=\"" .. listItem.mouse .. "\"/>\n")
      else
        bindingsFile:write("    <input name=\"" .. listItem.inputName .. "\" key1=\"" .. listItem.inputKey1 .. "\" key2=\"" .. listItem.inputKey2 .. "\" button=\"" .. listItem.inputButton .. "\" mouse=\"" .. listItem.inputMouseButton .. "\"/>\n")
      end
    end
    bindingsFile:write("</inputBinding>")
    bindingsFile:close()
  else
    print(errorMsg)
  end
end
function GUIControlsScreen:mouseEvent(posX, posY, isDown, isUp, button)
  if self.isActive then
    if self.waitForInput and self.list.listColumnNames[self.list.clickedColumn] == "mouse" then
      if isUp then
        for _, specialKey in pairs(Input.SpecialKeys) do
          if button == specialKey.mouseButton then
            self.controlsMessage2 = ""
            for _, listItem in pairs(self.list.listItems) do
              if listItem.mouse == specialKey.name and listItem.action ~= self.list.listItems[self.list.clickedItem].action then
                self.controlsMessage2 = g_i18n:getText("MouseAlreadyMapped")
                break
              end
            end
            self.userMadeChanges = true
            self.list.listItems[self.list.clickedItem].mouse = specialKey.name
            self.list.listItems[self.list.clickedItem].inputMouseButton = specialKey.input
            self.controlsMessage1 = string.format(g_i18n:getText("ActionRemapped"), self.list.listItems[self.list.clickedItem].action, specialKey.name)
            self:endWaitForInput()
          end
        end
      end
    else
      for _, component in pairs(self.components) do
        component:mouseEvent(posX, posY, isDown, isUp, button)
      end
    end
  elseif self.dialogBoxScreen.isActive then
    for _, component in pairs(self.dialogBoxScreen.components) do
      component:mouseEvent(posX, posY, isDown, isUp, button)
    end
  end
end
function GUIControlsScreen:keyEvent(unicode, sym, modifier, isDown)
  if self.isActive and self.waitForInput and isDown then
    if unicode == 27 then
      self.controlsMessage1 = g_i18n:getText("SelectActionToRemap")
      self.controlsMessage2 = ""
      self.controlsMessageColor = self.controlsMessageStandardColor
      self:endWaitForInput()
    elseif unicode == 8 then
      if string.sub(self.list.listColumnNames[self.list.clickedColumn], 1, 3) == "key" then
        if self.list.listColumnNames[self.list.clickedColumn] == "key1" then
          self.list.listItems[self.list.clickedItem].key1 = ""
          self.list.listItems[self.list.clickedItem].inputKey1 = ""
        elseif self.list.listColumnNames[self.list.clickedColumn] == "key2" then
          self.list.listItems[self.list.clickedItem].key2 = ""
          self.list.listItems[self.list.clickedItem].inputKey2 = ""
        end
      elseif self.list.listColumnNames[self.list.clickedColumn] == "mouse" then
        self.list.listItems[self.list.clickedItem].mouse = ""
        self.list.listItems[self.list.clickedItem].inputMouseButton = ""
      elseif self.list.listColumnNames[self.list.clickedColumn] == "gamepad" then
        self.list.listItems[self.list.clickedItem].gamepad = ""
        self.list.listItems[self.list.clickedItem].inputButton = ""
        self.list.listItems[self.list.clickedItem].inputAxis = ""
      end
      self.userMadeChanges = true
      self.controlsMessage1 = g_i18n:getText("SelectActionToRemap")
      self.controlsMessage2 = ""
      self.controlsMessageColor = self.controlsMessageStandardColor
      self:endWaitForInput()
    elseif string.sub(self.list.listColumnNames[self.list.clickedColumn], 1, 3) == "key" then
      local validKey = false
      for _, specialKey in pairs(Input.SpecialKeys) do
        if unicode == specialKey.unicode and (sym == specialKey.sym or specialKey.sym == 0) then
          self.controlsMessage2 = ""
          for _, listItem in pairs(self.list.listItems) do
            if listItem.key1 == specialKey.name and listItem.action ~= self.list.listItems[self.list.clickedItem].action then
              self.controlsMessage2 = g_i18n:getText("KeyAlreadyMapped")
              break
            end
          end
          self.userMadeChanges = true
          if self.list.listColumnNames[self.list.clickedColumn] == "key1" then
            self.list.listItems[self.list.clickedItem].key1 = specialKey.name
            self.list.listItems[self.list.clickedItem].inputKey1 = specialKey.input
          elseif self.list.listColumnNames[self.list.clickedColumn] == "key2" then
            self.list.listItems[self.list.clickedItem].key2 = specialKey.name
            self.list.listItems[self.list.clickedItem].inputKey2 = specialKey.input
          end
          self.controlsMessage1 = string.format(g_i18n:getText("ActionRemapped"), self.list.listItems[self.list.clickedItem].action, specialKey.name)
          validKey = true
          break
        end
      end
      if unicode ~= 0 and not validKey then
        local listItems = self.list.listItems
        if Input["KEY_" .. string.char(unicode)] ~= nil then
          self.controlsMessage2 = ""
          for k, listItem in pairs(listItems) do
            if listItem.key1 == string.char(unicode) and listItem.action ~= self.list.listItems[self.list.clickedItem].action then
              self.controlsMessage2 = g_i18n:getText("KeyAlreadyMapped")
              break
            end
          end
          self.userMadeChanges = true
          if self.list.listColumnNames[self.list.clickedColumn] == "key1" then
            self.list.listItems[self.list.clickedItem].key1 = string.char(unicode)
            self.list.listItems[self.list.clickedItem].inputKey1 = "KEY_" .. string.char(unicode)
          elseif self.list.listColumnNames[self.list.clickedColumn] == "key2" then
            self.list.listItems[self.list.clickedItem].key2 = string.char(unicode)
            self.list.listItems[self.list.clickedItem].inputKey2 = "KEY_" .. string.char(unicode)
          end
          self.controlsMessage1 = string.format(g_i18n:getText("ActionRemapped"), self.list.listItems[self.list.clickedItem].action, string.char(unicode))
          validKey = true
        else
          self.controlsMessage1 = g_i18n:getText("KeyCannotBeMapped")
          self.controlsMessage2 = ""
          self.controlsMessageColor = instance.controlsMessageWarningColor
        end
      end
      if validKey then
        self:endWaitForInput()
      end
    end
  end
end
function GUIControlsScreen:update(dt)
  if self.isActive and self.waitForInput and self.list.listColumnNames[self.list.clickedColumn] == "gamepad" then
    for k, v in pairs(InputBinding.analogAxes) do
      if math.abs(v) > 0.5 then
        for _, axesMapping in pairs(Input.AxesMapping) do
          if axesMapping.input == InputBinding.axes[k].axisName then
            self.list.listItems[self.list.clickedItem].gamepad = axesMapping.name
            self.list.listItems[self.list.clickedItem].inputAxis = axesMapping.input
            self.userMadeChanges = true
            self:endWaitForInput()
            break
          end
        end
      end
    end
    for i = 1, 16 do
      local isDown = getInputButton(i - 1) > 0 or 0 < InputBinding.externalInputButtons[i]
      if isDown then
        for _, listItem in pairs(self.list.listItems) do
          if listItem.gamepad == "Button " .. i and listItem.action ~= self.list.listItems[self.list.clickedItem].action then
            self.controlsMessage2 = g_i18n:getText("ButtonAlreadyMapped")
            break
          end
        end
        self.list.listItems[self.list.clickedItem].gamepad = "Button " .. i
        self.list.listItems[self.list.clickedItem].inputButton = "BUTTON_" .. i
        self.controlsMessage1 = string.format(g_i18n:getText("ActionRemapped"), self.list.listItems[self.list.clickedItem].action, "Button " .. i)
        self.userMadeChanges = true
        self:endWaitForInput()
      end
    end
  end
end
function GUIControlsScreen:reset()
end
function GUIControlsScreen:endWaitForInput()
  self.list.clickedItem = 0
  self.buttonDefaults:setActive(true)
  self.buttonSave:setActive(true)
  self.buttonCancel:setActive(true)
  self.waitForInput = false
end
function GUIControlsScreen:render()
  if self.isVisible then
    if self.dialogBoxScreen.isVisible then
      GUIControlsScreen:superClass().render(self.dialogBoxScreen)
    else
      GUIControlsScreen:superClass().render(self)
      setTextColor(0, 0, 0, 0.75)
      setTextBold(true)
      renderText(self.xPos + 0.046, self.yPos + 0.931 * self.height - 0.003, 0.04, self.titleText)
      renderText(self.xPos + 0.055, self.yPos + 0.19 * self.height - 0.003, 0.027, self.controlsMessage1)
      renderText(self.xPos + 0.055, self.yPos + 0.19 * self.height - 0.03 - 0.003, 0.027, self.controlsMessage2)
      setTextColor(0.8, 0.8, 1, 1)
      renderText(self.xPos + 0.046, self.yPos + 0.931 * self.height, 0.04, self.titleText)
      setTextColor(self.controlsMessageColor[1], self.controlsMessageColor[2], self.controlsMessageColor[3], self.controlsMessageColor[4])
      renderText(self.xPos + 0.055, self.yPos + 0.19 * self.height, 0.027, self.controlsMessage1)
      renderText(self.xPos + 0.055, self.yPos + 0.19 * self.height - 0.03, 0.027, self.controlsMessage2)
      setTextBold(false)
    end
  end
end
function GUIControlsScreen:enable(chained)
  self:loadBindings(g_inputBindingPath)
  GUIControlsScreen:superClass().enable(self, chained)
end
GUIList = {}
local GUIList_mt = Class(GUIList, GUIComponent)
function GUIList:new(bgOverlay, xPos, yPos, width, height, onClick, target)
  local instance = GUIList:superClass():new(bgOverlay, xPos, yPos, width, height, GUIList_mt)
  instance.onClick = onClick
  instance.target = target
  instance.isActive = true
  instance.isVisible = true
  instance.xPos = xPos
  instance.yPos = yPos
  instance.width = width
  instance.height = height
  instance.textSize = 0.027
  instance.mouseDown = false
  instance.listItems = {}
  instance.listColumnNames = {}
  instance.visibleItems = 21
  instance.firstVisibleItem = 1
  instance.clickedItem = 0
  instance.waitForInput = false
  instance.listColumnNames = {
    "action",
    "key1",
    "key2",
    "mouse",
    "gamepad"
  }
  instance.listColumnPositions = {
    0.01,
    0.31,
    0.46,
    0.6,
    0.76
  }
  local buttonWidth = 0.037500000000000006
  local buttonHeight = 0.05
  local sliderXPos = 0.89
  local sliderOverlay = Overlay:new("list_slider_n", "data/menu/list_slider_n.png")
  instance.listSlider = GUIListSlider:new(sliderOverlay, sliderXPos, 0.686, buttonWidth, buttonWidth * 2.5)
  instance.listSlider.highestPos = 0.686
  instance.listSlider.lowestPos = 0.31
  instance:addComponent(instance.listSlider)
  instance.listSlider:updateListPosition()
  instance.listSelectionOverlay = Overlay:new("list_selection", "data/menu/list_selection.png", instance.xPos + 0.005, 0, 0.1682, instance.textSize)
  local overlays = {}
  local buttonFilenames = {
    [GUIButton.STATE_NORMAL] = "list_button_up_n",
    [GUIButton.STATE_FOCUSED] = "list_button_up_f"
  }
  for state, filename in pairs(buttonFilenames) do
    overlays[state] = Overlay:new(filename, "data/menu/" .. filename .. ".png")
  end
  local buttonUp = GUIButton:new(overlays, "", sliderXPos, 0.78, buttonWidth, buttonHeight)
  function buttonUp.onClick()
    instance.firstVisibleItem = math.max(instance.firstVisibleItem - 1, 1)
    instance.listSlider:updateSliderPosition()
  end
  instance:addComponent(buttonUp)
  overlays = {}
  buttonFilenames = {
    [GUIButton.STATE_NORMAL] = "list_button_down_n",
    [GUIButton.STATE_FOCUSED] = "list_button_down_f"
  }
  for state, filename in pairs(buttonFilenames) do
    overlays[state] = Overlay:new(filename, "data/menu/" .. filename .. ".png")
  end
  local buttonDown = GUIButton:new(overlays, "", sliderXPos, 0.26, buttonWidth, buttonHeight)
  function buttonDown.onClick()
    instance.firstVisibleItem = math.min(instance.firstVisibleItem + 1, #instance.listItems - instance.visibleItems + 1)
    instance.listSlider:updateSliderPosition()
  end
  instance:addComponent(buttonDown)
  return instance
end
function GUIList:mouseEvent(posX, posY, isDown, isUp, button)
  if self.isActive then
    for _, component in pairs(self.components) do
      component:mouseEvent(posX, posY, isDown, isUp, button)
    end
    self.listSelectionOverlay.visible = false
    local rowNumber = 0
    local columnNumber = 0
    if g_mouse:checkRectangle(self.xPos, self.yPos, self.width * 0.86, self.height) then
      for i = 1, self.visibleItems do
        if posY > self.yPos + 0.977 * self.height - i * self.textSize and posY < self.yPos + 0.977 * self.height - (i - 1) * self.textSize then
          rowNumber = i
        end
      end
      for i = 2, table.getn(self.listColumnPositions) do
        if i == table.getn(self.listColumnPositions) then
          if g_mouse:checkRectangle(self.xPos + self.listColumnPositions[i] * self.width, self.yPos, self.width * 0.86 - self.listColumnPositions[i] * self.width, self.height) then
            columnNumber = i
            self.listSelectionOverlay.width = self.width * 0.86 - self.listColumnPositions[i] * self.width
          end
        elseif g_mouse:checkRectangle(self.xPos + self.listColumnPositions[i] * self.width, self.yPos, self.xPos + self.listColumnPositions[i + 1] * self.width, self.height) then
          columnNumber = i
          self.listSelectionOverlay.width = self.listColumnPositions[i + 1] * self.width - self.listColumnPositions[i] * self.width
        end
      end
      if isDown then
        if button == Input.MOUSE_BUTTON_LEFT then
          self.mouseDown = true
        end
        if Input.isMouseButtonPressed(Input.MOUSE_BUTTON_WHEEL_UP) then
          self.firstVisibleItem = math.max(self.firstVisibleItem - 1, 1)
          self.listSlider:updateSliderPosition()
        elseif Input.isMouseButtonPressed(Input.MOUSE_BUTTON_WHEEL_DOWN) then
          self.firstVisibleItem = math.min(self.firstVisibleItem + 1, #self.listItems - self.visibleItems + 1)
          self.listSlider:updateSliderPosition()
        end
      end
      if isUp and button == Input.MOUSE_BUTTON_LEFT and self.mouseDown then
        self.mouseDown = false
        if self.onClick ~= nil and rowNumber ~= 0 and 1 < columnNumber and not self.onClick(rowNumber, columnNumber) then
          self.clickedItem = 0
        end
      end
    end
    if self.clickedItem ~= 0 then
      rowNumber = self.clickedItem - self.firstVisibleItem + 1
    end
    if rowNumber ~= 0 and columnNumber ~= 0 then
      if not waitForInput then
        self.listSelectionOverlay.y = self.yPos + 0.977 * self.height - rowNumber * self.textSize
        self.listSelectionOverlay.x = self.xPos + self.listColumnPositions[columnNumber] * self.width
      end
      self.listSelectionOverlay.visible = true
    end
  end
end
function GUIList:render()
  if self.isVisible then
    GUIList:superClass().render(self)
    self.listSelectionOverlay:render()
    local xSpacing = 0.94 * self.width / #self.listColumnNames
    for i, columnName in pairs(self.listColumnNames) do
      setTextColor(0, 0, 0, 0.75)
      setTextBold(true)
      renderText(self.xPos + self.listColumnPositions[i] * self.width, self.yPos + 0.005 + 0.995 * self.height, self.textSize, g_i18n:getText(columnName))
      setTextColor(0.8, 0.8, 1, 1)
      renderText(self.xPos + self.listColumnPositions[i] * self.width, self.yPos + 0.005 + self.height, self.textSize, g_i18n:getText(columnName))
      setTextColor(1, 1, 1, 1)
      setTextBold(false)
    end
    for i, listItem in pairs(self.listItems) do
      for j, columnName in pairs(self.listColumnNames) do
        if i >= self.firstVisibleItem and i <= self.firstVisibleItem + self.visibleItems - 1 then
          if 0 < self.clickedItem then
            if i ~= self.clickedItem then
              setTextColor(1, 1, 1, 0.25)
              setTextBold(true)
              renderText(self.xPos + self.listColumnPositions[j] * self.width, self.yPos + 0.977 * self.height - (i - self.firstVisibleItem + 1) * self.textSize, self.textSize, listItem[columnName])
              setTextColor(1, 1, 1, 1)
              setTextBold(false)
            else
              setTextColor(0, 0, 0, 0.75)
              setTextBold(true)
              renderText(self.xPos + self.listColumnPositions[j] * self.width, self.yPos + 0.97 * self.height - (i - self.firstVisibleItem + 1) * self.textSize, self.textSize, listItem[columnName])
              setTextColor(1, 1, 1, 1)
              renderText(self.xPos + self.listColumnPositions[j] * self.width, self.yPos + 0.977 * self.height - (i - self.firstVisibleItem + 1) * self.textSize, self.textSize, listItem[columnName])
              setTextColor(1, 1, 1, 1)
              setTextBold(false)
            end
          else
            setTextColor(0, 0, 0, 0.75)
            setTextBold(true)
            renderText(self.xPos + self.listColumnPositions[j] * self.width, self.yPos + 0.97 * self.height - (i - self.firstVisibleItem + 1) * self.textSize, self.textSize, tostring(listItem[columnName]))
            setTextColor(1, 1, 1, 1)
            renderText(self.xPos + self.listColumnPositions[j] * self.width, self.yPos + 0.977 * self.height - (i - self.firstVisibleItem + 1) * self.textSize, self.textSize, tostring(listItem[columnName]))
            setTextColor(1, 1, 1, 1)
            setTextBold(false)
          end
        end
      end
    end
  end
end
function GUIList:reset()
end
GUIListSlider = {}
local GUIListSlider_mt = Class(GUIListSlider, GUIComponent)
function GUIListSlider:new(sliderOverlay, xPos, yPos, width, height, onClick, target)
  local instance = GUIListSlider:superClass():new(sliderOverlay, xPos, yPos, width, height, GUIListSlider_mt)
  instance.highestPos = 1
  instance.lowestPos = 0
  instance.dragOffsetY = 0
  instance.isActive = true
  return instance
end
function GUIListSlider:mouseEvent(posX, posY, isDown, isUp, button)
  if self.isActive then
    if self.bgOverlay ~= nil and checkOverlayOverlap(posX, posY, self.bgOverlay) and isDown and button == Input.MOUSE_BUTTON_LEFT then
      self.mouseDown = true
      self.dragOffsetY = self.yPos - posY
    end
    if isUp and button == Input.MOUSE_BUTTON_LEFT then
      self.mouseDown = false
    end
    if self.mouseDown then
      self.yPos = posY + self.dragOffsetY
      self.yPos = math.min(self.yPos, self.highestPos)
      self.yPos = math.max(self.yPos, self.lowestPos)
      self.bgOverlay.y = posY + self.dragOffsetY
      self.bgOverlay.y = math.min(self.bgOverlay.y, self.highestPos)
      self.bgOverlay.y = math.max(self.bgOverlay.y, self.lowestPos)
      self:updateListPosition()
    end
  end
end
function GUIListSlider:updateListPosition()
  self.parentComponent.firstVisibleItem = math.floor((1 - (self.yPos - self.lowestPos) / (self.highestPos - self.lowestPos)) * (#self.parentComponent.listItems - self.parentComponent.visibleItems)) + 1
end
function GUIListSlider:updateSliderPosition()
  self.yPos = (1 - (self.parentComponent.firstVisibleItem - 1) / (#self.parentComponent.listItems - self.parentComponent.visibleItems)) * (self.highestPos - self.lowestPos) + self.lowestPos
  self:setPosition(self.xPos, self.yPos)
end
function GUIListSlider:setPosition(x, y)
  self.xPos = x
  self.yPos = y
  self.bgOverlay.x = x
  self.bgOverlay.y = y
end
function GUIListSlider:reset()
end

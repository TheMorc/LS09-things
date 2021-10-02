Mouse = {}
local Mouse_mt = Class(Mouse)
Mouse.NORMAL = 1
Mouse.HAND = 2
Mouse.WAIT = 3
function Mouse:new(cursorOverlays, posX, posY, useOverlay)
  if posX == nil or posY == nil then
    posX = 0
    posY = 0
  end
  setShowMouseCursor(not useOverlay)
  return setmetatable({
    cursorOverlays = cursorOverlays,
    posX = posX,
    posY = posY,
    isVisible = true,
    offsetX = 0,
    offsetY = 0,
    cursorState = Mouse.NORMAL,
    isVisible = true,
    isEnabled = true,
    useOverlay = useOverlay
  }, Mouse_mt)
end
function Mouse:mouseEvent(posX, posY, isDown, isUp, button)
  self.posX = posX - self.offsetX
  self.posY = posY - self.offsetY
  if self.useOverlay then
    for _, overlay in pairs(self.cursorOverlays) do
      overlay.x = posX
      overlay.y = posY - overlay.height
    end
  end
end
function Mouse:render()
  if self.isVisible and self.useOverlay then
    if self.cursorOverlays[self.cursorState] ~= nil then
      self.cursorOverlays[self.cursorState]:render()
    elseif self.cursorOverlays[Mouse.NORMAL] ~= nil then
      self.cursorOverlays[Mouse.NORMAL]:render()
    end
  end
end
function Mouse:showMouse(visible)
  self.isVisible = visible
  if not self.useOverlay then
    setShowMouseCursor(visible)
  end
end
function Mouse:enableMouse(enabled)
  self.isEnabled = enabled
end
function Mouse:checkRectangle(x, y, width, height)
  if x <= self.posX and self.posX <= x + width and y <= self.posY and self.posY <= y + height then
    return true
  end
  return false
end

DemoEndScreen = {}
local DemoEndScreen_mt = Class(DemoEndScreen)
function DemoEndScreen:new()
  local instance = {}
  setmetatable(instance, DemoEndScreen_mt)
  instance.items = {}
  instance.countdown = 3000
  instance.countdown2 = 10000
  return instance
end
function DemoEndScreen:delete()
  for i = 1, table.getn(self.items) do
    self.items[i]:delete()
  end
end
function DemoEndScreen:addItem(item)
  table.insert(self.items, item)
end
function DemoEndScreen:mouseEvent(posX, posY, isDown, isUp, button)
  if self.countdown <= 0 and isDown then
    doExit()
  end
end
function DemoEndScreen:keyEvent(unicode, sym, modifier, isDown)
  if self.countdown <= 0 and isDown then
    doExit()
  end
end
function DemoEndScreen:update(dt)
  self.countdown = self.countdown - dt
  self.countdown2 = self.countdown2 - dt
  if self.countdown2 <= 0 then
    doExit()
  end
end
function DemoEndScreen:render()
  for i = 1, table.getn(self.items) do
    self.items[i]:render()
  end
end

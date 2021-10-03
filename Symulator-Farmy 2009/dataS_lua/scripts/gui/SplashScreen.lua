SplashScreen = {}
local SplashScreen_mt = Class(SplashScreen)
function SplashScreen:new(onEndFunc, onEndTarget)
  local instance = {}
  setmetatable(instance, SplashScreen_mt)
  instance.screens = {}
  instance.countdownTime = 2000
  instance.countdown = instance.countdownTime
  instance.currentScreen = 1
  instance.onEndFunc = onEndFunc
  instance.onEndTarget = onEndTarget
  return instance
end
function SplashScreen:delete()
  for k, v in ipairs(self.screens) do
    v:delete()
  end
end
function SplashScreen:addScreen(screen)
  table.insert(self.screens, screen)
end
function SplashScreen:mouseEvent(posX, posY, isDown, isUp, button)
  if isDown then
    self:proceed()
  end
end
function SplashScreen:keyEvent(unicode, sym, modifier, isDown)
  if isDown then
    self:proceed()
  end
end
function SplashScreen:update(dt)
  self.countdown = self.countdown - dt
  if self.countdown <= 0 then
    self:proceed()
  end
end
function SplashScreen:render()
  if self.currentScreen <= table.getn(self.screens) then
    self.screens[self.currentScreen]:render()
  end
end
function SplashScreen:proceed()
  self.currentScreen = self.currentScreen + 1
  self.countdown = self.countdownTime
  if self.currentScreen > table.getn(self.screens) and self.onEndFunc ~= nil then
    if self.onEndTarget ~= nil then
      self.onEndFunc(self.onEndTarget)
    else
      self.onEndFunc()
    end
  end
end

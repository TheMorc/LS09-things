CreditsScreen = {}
local CreditsScreen_mt = Class(CreditsScreen)
function CreditsScreen:new(backgroundOverlay)
  local instance = {}
  setmetatable(instance, CreditsScreen_mt)
  instance.overlays = {}
  instance.overlayButtons = {}
  instance.creditsLines = {}
  instance.backgroundOverlay = backgroundOverlay
  table.insert(instance.overlays, backgroundOverlay)
  instance:addButton(OverlayButton:new(Overlay:new("credits_back_button", "dataS/menu/back_button" .. g_languageSuffix .. ".png", 0.415, 0.03, 0.17, 0.06), OnCreditsMenuBack))
  instance.creditsTexts = {}
  table.insert(instance.creditsTexts, "Developed by")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "GIANTS Software GmbH")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "Executive Producer")
  table.insert(instance.creditsTexts, "Christian Ammann")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "Lead Programmer")
  table.insert(instance.creditsTexts, "Stefan Geiger")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "Lead Artist")
  table.insert(instance.creditsTexts, "Thomas Frey")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "Lead Designer")
  table.insert(instance.creditsTexts, "Renzo Th\246nen")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "Artists")
  table.insert(instance.creditsTexts, "Branislav Florian")
  table.insert(instance.creditsTexts, "Andrej Svoboda")
  table.insert(instance.creditsTexts, "Dody Saputra")
  table.insert(instance.creditsTexts, "Sebastian Licht")
  table.insert(instance.creditsTexts, "Roland Zeller")
  table.insert(instance.creditsTexts, "Guido Lein")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "Programmers")
  table.insert(instance.creditsTexts, "Thomas Brunner")
  table.insert(instance.creditsTexts, "Melanie Imhof")
  table.insert(instance.creditsTexts, "Jonathan Sieber")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "Sound Designer")
  table.insert(instance.creditsTexts, "Tobias Reuber")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "Music Composer")
  table.insert(instance.creditsTexts, "Randy Jones")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "QA Lead")
  table.insert(instance.creditsTexts, "Martin B\228rwolf")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "QA Testers")
  table.insert(instance.creditsTexts, "Manuel Leithner")
  table.insert(instance.creditsTexts, "Chris Zoltan")
  table.insert(instance.creditsTexts, "Felix Sorge")
  table.insert(instance.creditsTexts, "Chris Wachter")
  table.insert(instance.creditsTexts, "Stefan Seidel")
  table.insert(instance.creditsTexts, "Ronny Gohr")
  table.insert(instance.creditsTexts, "Horst G\246tzl")
  table.insert(instance.creditsTexts, "Sven Br\228utigam")
  table.insert(instance.creditsTexts, "Tobias Kachler")
  table.insert(instance.creditsTexts, "Hans-Peter Imhof")
  table.insert(instance.creditsTexts, "Mark Hartman")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "Localization")
  table.insert(instance.creditsTexts, "Ruth Koch")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "Uses PhysX by NVIDIA")
  table.insert(instance.creditsTexts, "Copyright (C) 2008, NVIDIA Corporation")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "Uses LUA")
  table.insert(instance.creditsTexts, "Copyright (C) 1994-2008 Lua.org, PUC-Rio")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "Uses Ogg Vorbis")
  table.insert(instance.creditsTexts, "Copyright (C) 1994-2007 Xiph.Org Foundation")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "Uses Zlib")
  table.insert(instance.creditsTexts, "Copyright (C) 1995-2004 Jean-loup Gailly and Mark Adler")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "this software is based in part on")
  table.insert(instance.creditsTexts, "the work of the Independent JPEG Group")
  table.insert(instance.creditsTexts, "Copyright (C) 1991-1998 Independent JPEG Group")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "Fendt (www.fendt.com)")
  table.insert(instance.creditsTexts, "Copyright (C) AGCO Corporation")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "P\246ttinger (www.poettinger.at)")
  table.insert(instance.creditsTexts, "Copyright (C) Alois P\246ttinger Maschinenfabrik Ges.m.b.H.")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "Publisher")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "Senior Product Manager")
  table.insert(instance.creditsTexts, "Dirk Ohler")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "Product Managers")
  table.insert(instance.creditsTexts, "Jens Brauckhoff")
  table.insert(instance.creditsTexts, "Marcel Aldrup")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "Thanks for playing!")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "You can stop reading now.")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "Seriously, that's all.")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "")
  table.insert(instance.creditsTexts, "")
  instance.currentTopLine = 1
  instance.creditsStartY = 0.1
  instance.creditsFontSize = 0.05
  instance.time = 0
  instance.creditsLinesFrequency = 750
  return instance
end
function CreditsScreen:delete()
  for i = 1, table.getn(self.items) do
    self.items[i]:delete()
  end
end
function CreditsScreen:addButton(overlayButton)
  table.insert(self.overlays, overlayButton.overlay)
  table.insert(self.overlayButtons, overlayButton)
end
function CreditsScreen:mouseEvent(posX, posY, isDown, isUp, button)
  for i = 1, table.getn(self.overlayButtons) do
    self.overlayButtons[i]:mouseEvent(posX, posY, isDown, isUp, button)
  end
end
function CreditsScreen:keyEvent(unicode, sym, modifier, isDown)
end
function CreditsScreen:update(dt)
  self.time = self.time + dt
  if self.time >= self.creditsLinesFrequency then
    self.time = 0
    self.currentTopLine = self.currentTopLine + 1
    if self.currentTopLine > table.getn(self.creditsTexts) then
      self.currentTopLine = 1
    end
    table.insert(self.creditsLines, CreditsLine:new(self.creditsTexts[self.currentTopLine], self.creditsFontSize, self.creditsStartY))
  end
  for i = 1, table.getn(self.creditsLines) do
    self.creditsLines[i]:update(dt)
  end
end
function CreditsScreen:render()
  for i = 1, table.getn(self.overlays) do
    self.overlays[i]:render()
  end
  for i = 1, table.getn(self.creditsLines) do
    self.creditsLines[i]:render()
  end
end
function CreditsScreen:reset()
  for i = 1, table.getn(self.overlayButtons) do
    self.overlayButtons[i]:reset()
  end
  self.creditsLines = {}
  table.insert(self.creditsLines, CreditsLine:new(self.creditsTexts[1], self.creditsFontSize, self.creditsStartY))
  self.currentTopLine = 1
end
CreditsLine = {}
local CreditsLine_mt = Class(CreditsLine)
function CreditsLine:new(textLine, textSize, yPos)
  return setmetatable({
    textLine = textLine,
    textSize = textSize,
    yPos = yPos,
    fadedInPos = yPos + 0.1,
    fadeOutPos = 0.8,
    alpha = 1,
    visible = true
  }, CreditsLine_mt)
end
function CreditsLine:render()
  if self.visible then
    self.alpha = 1
    if self.yPos < self.fadedInPos then
      self.alpha = (0.1 - (self.fadedInPos - self.yPos)) / 0.1
    end
    if self.yPos > self.fadeOutPos then
      self.alpha = (0.1 - (self.yPos - self.fadeOutPos)) / 0.1
    end
    setTextBold(true)
    setTextAlignment(RenderText.ALIGN_CENTER)
    setTextColor(0.05, 0.05, 0.1, self.alpha)
    renderText(0.5, self.yPos - 0.002, self.textSize, self.textLine)
    setTextColor(1, 1, 1, self.alpha)
    renderText(0.5, self.yPos, self.textSize, self.textLine)
    setTextAlignment(RenderText.ALIGN_LEFT)
    setTextBold(false)
  end
end
function CreditsLine:update(dt)
  if self.visible then
    self.yPos = self.yPos + 7.0E-5 * dt
    if self.yPos > 0.9 then
      self.visible = false
    end
  end
end

-- guiWidescreenFix.lua
-- @author  Richard Gráčik @ 370network (mailto:morc@370.network)
-- @author  LS Mods Community (https://komeo.xyz/ls2009mods)
-- @date  27.1.2025 - 28.1.2025

--workaround for resolution fetching
local gameXml = loadXMLFile("guiWidescreenFix_gameXml", getUserProfileAppPath() .. "game.xml")
local guiWF_resX = getXMLInt(gameXml, "game.graphic.display.width")
local guiWF_resY = getXMLInt(gameXml, "game.graphic.display.height")
print("[guiWidescreenFix] Current resolution: " .. guiWF_resX .. "x" .. guiWF_resY)

local guiWF_scaleRatio = (4/3) / (guiWF_resX / guiWF_resY)
local guiWF_guiOffset = (1 - guiWF_scaleRatio) / 2
print("[guiWidescreenFix] New ratio: " .. guiWF_scaleRatio .. " | New GUI offset: " .. guiWF_guiOffset);

function guiWF_recalc(x, width)
  local guiWF_x, guiWF_width
  if x == 0 then
     guiWF_x = 0;
  elseif x ~= nil then
     guiWF_x = (x*guiWF_scaleRatio)+guiWF_guiOffset;
  end
  if width == 1 then
     guiWF_width = 1;
  else
     guiWF_width = (width*guiWF_scaleRatio);
  end
  return guiWF_x, guiWF_width
end

guiWF_renderTextOriginal = _G.renderText
function guiWF_renderText(x, y, size, text)
	x = guiWF_recalc(x, 0)
	guiWF_renderTextOriginal(x, y, size, text)
end
_G.renderText = guiWF_renderText
print("[guiWidescreenFix] Patched renderText")

local Overlay_mt = Class(Overlay)
function Overlay:new(name, overlayFilename, x, y, width, height)
  if overlayFilename ~= nil then
    tempOverlayId = createOverlay(name, overlayFilename)
  end

  local guiWF_x, guiWF_width = guiWF_recalc(x, width)
  print("[guiWidescreenFix] Patched overlay " .. name)
  return setmetatable({overlayId = tempOverlayId,x = guiWF_x,y = y,width = guiWF_width,height = height,visible = true,r = 1,g = 1,b = 1,a = 1}, Overlay_mt)	
end

function Overlay:setPosition(x, y)
  local xT, wT = guiWF_recalc(x, self.width)
  self.x = xT
  self.y = y
end
function Overlay:setDimension(width, height)
  local xT, wT = guiWF_recalc(self.x, width)
  self.width = wT
  self.height = height
end

modClassEventListener = {};

function modClassEventListener:loadMap(name)
	g_currentMission.missionStats.pdaMapArrowXPos = g_currentMission.missionStats.pdaMapWidth / 2 - g_currentMission.missionStats.pdaMapArrowSize + guiWF_guiOffset
	g_currentMission.missionStats.pdaMapPosX = guiWF_guiOffset
	print("[guiWidescreenFix] Patched PDA")
end;

function modClassEventListener:deleteMap()
end;

function modClassEventListener:mouseEvent(posX, posY, isDown, isUp, button)
end;

function modClassEventListener:keyEvent(unicode, sym, modifier, isDown)
end;

function modClassEventListener:update(dt)
end;

function modClassEventListener:draw()
end;

addModEventListener(modClassEventListener);

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

--aux calc function
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

guiWF_renderOverlayOriginal = _G.renderOverlay
function guiWF_renderOverlay(overlayId, x, y, width, height)
	x, width = guiWF_recalc(x, width)
	guiWF_renderOverlayOriginal(overlayId, x, y, width, height)
end
_G.renderOverlay = guiWF_renderOverlay
print("[guiWidescreenFix] Patched renderOverlay")

local Overlay_mt = Class(Overlay)
function guiWF_checkOverlayOverlap(posX, posY, overlay)
  guiWF_x, guiWF_width = guiWF_recalc(overlay.x, overlay.width)
  return posX >= guiWF_x and posX <= guiWF_x + guiWF_width and posY >= overlay.y and posY <= overlay.y + overlay.height
end
_G.checkOverlayOverlap = guiWF_checkOverlayOverlap
print("[guiWidescreenFix] Patched Overlay.checkOverlayOverlap")
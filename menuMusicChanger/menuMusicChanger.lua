-- menuMusicChanger.lua
-- @author  Richard Gráčik (mailto:r.gracik@gmail.com)
-- @date  8.8.2024

print("[musicMenuChanger] Saving and patching original menuMusic functions")
originalLoadStreamedSample = loadStreamedSample

function patchedLoadStreamedSample()
	originalLoadStreamedSample(g_menuMusic, g_modsDirectory .. "/menuMusicChanger/menu.ogg")
end

_G.loadStreamedSample = patchedLoadStreamedSample

modClassEventListener = {};

function modClassEventListener:loadMap(name)
	
	print("[musicMenuChanger] Reverting back to the original menuMusic function")
	_G.loadStreamedSample = originalLoadStreamedSample

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
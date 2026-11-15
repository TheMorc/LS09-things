-- menuMusicChanger.lua
-- @author  Richard Gráčik (mailto:morc@370.network)
-- @date  8.8.2024; 15.11.2026
-- edited to pick random music from the songs folder

print("[musicMenuChanger] Saving and patching original menuMusic functions")
originalLoadStreamedSample = loadStreamedSample

function patchedLoadStreamedSample()
	local musicFiles = Files:new(g_modsDirectory .. "/menuMusicChanger/songs/")
	originalLoadStreamedSample(g_menuMusic, g_modsDirectory .. "/menuMusicChanger/songs/" .. musicFiles.files[math.random(#musicFiles.files)].filename)
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
-- HideHUD Mod - hidehud.lua
-- possibly the only file needed for it all
-- @author  Richard Gráčik (mailto:r.gracik@gmail.com)
-- @date  13.10.2021 - 14.10.2021

HideHUDenabled=false

--draw function that does exactly nothing
function HideHUDdraw()
end

--since gameMenuSystem from main.lua has a higher priority than modClassEventListener's keyEvent then we need a workaround
function HideHUDkeyEvent(unicode, sym, modifier, isDown)	

	original.keyEvent(unicode, sym, modifier, isDown)
	
	if gameMenuSystem.currentMenu ~= nil and HideHUDenabled then
		_G.draw = original.draw
		print("[HideHUD Mod] disabling HideHUD - in game menu open")
		HideHUDenabled = false
	end
	
end

modClassEventListener = {};


function modClassEventListener:loadMap(name)
	
	print("[HideHUD Mod] saving original draw and keyEvent functions")
	original = { 
		 draw = draw,
		 keyEvent = keyEvent
	}
	
	print("[HideHUD Mod] overriding the keyEvent function")
	_G.keyEvent = HideHUDkeyEvent
	
end;

function modClassEventListener:deleteMap()

end;

function modClassEventListener:mouseEvent(posX, posY, isDown, isUp, button)

end;

function modClassEventListener:keyEvent(unicode, sym, modifier, isDown)
	
	if isDown and sym == 291 then
		HideHUDenabled = not HideHUDenabled
		
		if HideHUDenabled then
			_G.draw = HideHUDdraw
			print("[HideHUD Mod] enabling HideHUD - F10 key")
		else
			_G.draw = original.draw
			print("[HideHUD Mod] disabling HideHUD - F10 key")
		end
	end
	
end;

function modClassEventListener:update(dt)
end;

function modClassEventListener:draw()

end;

addModEventListener(modClassEventListener);
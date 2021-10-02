-- LS2009Chat Mod - chat.lua
-- possibly the only file needed for it all
-- beware!, this is just as messy as LS2008chat is, it may work but i just don't recommend even trying to touch it
-- it may break suddenly
-- @author  Richard Gráčik (mailto:r.gracik@gmail.com)
-- @date  1.10.2021 - 2.10.2021

print("[LS2009Chat Mod] chat.lua loading")
chatModFolder = g_currentModDirectory
chatSocket = require("socket")
chatUDP = socket.udp()
chatUDP:settimeout(0)
package.path = package.path..";"..chatModFolder.."?.lua"
require("settings")

chatVersion = 0.01

chatRunning = false

chatView = false
chatText = ""
chatHistory = {"","","","","","","","","",""}

chatRenderHistory = true;
chatRenderHistoryCounterStart = os.time()
chatRenderHistoryCounterEnd = chatRenderHistoryCounterStart+20

chatLayer = Overlay:new("chatLayer", "dataS/missions/medals_background.png")
chatOverlay = Overlay:new("chatOverlay", chatModFolder.."chat_overlay_old.png")
chatFarmNow = Overlay:new("chatFarmNow", chatModFolder.."chat_farmnow_old.png")
chatSend = Overlay:new("chatSend", chatModFolder.."chat_send_old.png")

print("[LS2009Chat Mod] saving original functions")
original = { 
	 draw = draw,
	 update = update,
	 keyEvent = keyEvent
}

function chatupdate(dt)
	chatHeartbeat()

	original.update(dt)
end



function chatdraw()
	original.draw()
	if gameMenuSystem:isMenuActive() then
		setTextBold(true);
		renderText(0.0, 0.98, 0.02, "LS2009Chat Mod v" .. chatVersion .. " - " .. chatPlayerName);
		setTextBold(false);
	end
	
	if chatView then
		renderOverlay(chatLayer.overlayId, 0.19, 0.445, 0.69, 0.425)
		renderOverlay(chatOverlay.overlayId, 0.19, 0.315, 0.69, 0.56)
		renderOverlay(chatFarmNow.overlayId, 0.205, 0.324, 0.17, 0.06)
		renderOverlay(chatSend.overlayId, 0.695, 0.324, 0.17, 0.06)
		setTextBold(true);
		renderText(0.197, 0.4, 0.04, chatText);
		setTextBold(false)
	end
	
	if chatRenderHistory then
 		for i=1, 10 do
				setTextBold(true);
 				renderText(0.197, 0.425+(i*0.04), 0.04, chatHistory[#chatHistory + 1 - i])
				setTextBold(false);
 		end	
 		if not chatView then
 			if os.time() >= chatRenderHistoryCounterEnd then
 				chatRenderHistory = false
 			end
 		end
 	end
end

function chatkeyEvent(unicode, sym, modifier, isDown)	

	if not chatView then
		original.keyEvent(unicode, sym, modifier, isDown)
	end
	
	if isDown and chatView and chatRunning then
		if sym == Input.KEY_esc then
			chatView = false
			print("[LS2009Chat] closing chat in-game chat")
			chatText = ""
			return
		elseif sym == Input.KEY_return then
			print("[LS2009Chat] sending a chat message "..chatText)
			printChat(chatPlayerName..": " .. chatText)
			chatUDP:send("chat;"..chatPlayerName..": "..chatText)
			chatView = false
			chatText = ""
		elseif 31 < unicode and unicode < 127 then 
			chatText = chatText..string.char(unicode)
		end
		if sym == 8 then
			if chatText:len() >= 1 then
				chatText = chatText:sub(1,chatText:len() - 1)
			end
		end
	end
	
	if sym == Input.KEY_t and isDown and chatRunning then
		chatRenderHistory = true
		chatView = true
		print("LS2009Chat opening in-game chat")
		return
	end;
	
end

function chatHeartbeat()
	if not chatRunning then
		chatRunning = true
		print("[LS2009Chat] starting client - connecting to " .. chatIP .. ":" .. chatPort)
		chatUDP:setpeername(chatIP, chatPort)
		chatUDP:send("dummytext;ignore;thanks")
		chatUDP:send("login;"..chatPlayerName)
	end

	data = chatUDP:receive()
	if data then
		handleUDPmessage(data, "Server", 2008)
	end
		
end

function handleUDPmessage(msg, msgIP, msgPort)
	local p = split(msg, ';')
	if p[1] == "chat" then
		printChat(p[2])
	elseif p[1] == "login" then
		printChat(p[2] .. " joined the chat.")
  	else
 		print("LS2009Chat undefined UDP message received from " .. msgIP .. ":" .. msgPort ..  ": " .. msg)
 	end
end

function printChat(chatText)
	
	local s = {}
    for i=1, #chatText, 38 do
        s[#s+1] = chatText:sub(i,i+38 - 1)
    end
	
	for i,separatedLine in ipairs(s) do
		table.insert(chatHistory, separatedLine)	
	end

 	chatRenderHistoryCounterStart = os.time()
 	chatRenderHistoryCounterEnd = chatRenderHistoryCounterStart+20
 	chatRenderHistory = true
 end

function split(s, delimiter)
	result = {}
	for match in (s..delimiter):gmatch("(.-)"..delimiter) do
		table.insert(result, match)
	end
	return result
end

print("[LS2009Chat Mod] adding modified functions")
_G.update = chatupdate
_G.draw = chatdraw
_G.keyEvent = chatkeyEvent

--usual LS2009 mod class stuff, interestingly that it's not used at all lol
modClassEventListener = {};

function modClassEventListener:loadMap(name)

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
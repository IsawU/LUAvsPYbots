local params={...}


	http=require("socket.http")
	
	print("hello actionThread")
	
	--actionChannel=love.thread.getChannel("actionChannel")
	--local addr=actionChannel:pop()
	--local arg=actionChannel:pop()
	local address=params[1]
	local argument=params[2]
	
	--print(address)
	--print(argument)
	
	local res,sc,data=http.request(address,argument)
	
	--print(res)
	
	if string.find(res,[["state": "game_won"]]) then
	
		victoryChannel=love.thread.getChannel("victoryChannel")
		victoryChannel:clear()
		victoryChannel:push("WON")
		
	elseif string.find(res,[["state": "unknown_bot"]]) then
	
		victoryChannel=love.thread.getChannel("victoryChannel")
		victoryChannel:clear()
		victoryChannel:push("LOST")
		
	end
	
	--actionChannel:clear()
	
	--actionChannel:push(res)
	--actionChannel:push(sc)
	--actionChannel:push(data)


	http=require("socket.http")
	
	print("hello actionThread")
	
	actionChannel=love.thread.getChannel("actionChannel")
	local addr=actionChannel:pop()
	local arg=actionChannel:pop()
	
	
	local res,sc,data=http.request(addr,arg)
	
	
	actionChannel:clear()
	
	actionChannel:push(res)
	actionChannel:push(sc)
	actionChannel:push(data)

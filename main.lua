function love.load()
	http=require("socket.http")
	serverAddr="http://hroch.spseol.cz:44822"
	
	--screen
	fullscreen=false
	width=love.graphics.getWidth()
	height=love.graphics.getHeight()
	
	tileSize=80
	
	--love.window.setTitle("LUA vs PYbots")
	scale=1
	
	--assets
	local BAP="/assets/bot/"  --bot assets path
	myrobots={}	--my robots
	myrobots[0]=love.graphics.newImage(BAP .. "botuh0.png")
	myrobots[1]=love.graphics.newImage(BAP .. "botuh1.png")
	myrobots[2]=love.graphics.newImage(BAP .. "botuh2.png")
	myrobots[3]=love.graphics.newImage(BAP .. "botuh3.png")
	
	urrobots={}	--your robots
	urrobots[0]=love.graphics.newImage(BAP .. "both0.png")
	urrobots[1]=love.graphics.newImage(BAP .. "both1.png")
	urrobots[2]=love.graphics.newImage(BAP .. "both2.png")
	urrobots[3]=love.graphics.newImage(BAP .. "both3.png")
	
	local TAP="/assets/tiles/"  --tiles assets path
	tiles={}	--tiles
	tiles[0]=love.graphics.newImage(TAP .. "floor.png")		--empty
	tiles[1]=love.graphics.newImage(TAP .. "treasure.png")	--treasure
	tiles[2]=love.graphics.newImage(TAP .. "floor.png")		--bot
	tiles[3]=love.graphics.newImage(TAP .. "wall.png")		--block
	tiles[4]=love.graphics.newImage(TAP .. "floor.png")		--baterry_bot ???
	
	
	actionThread=love.thread.newThread("action.lua")
	actionChannel=love.thread.getChannel("actionChannel")
	
	decoderThread=love.thread.newThread("decode.lua")
	decoderChannel=love.thread.getChannel("decoderChannel")
		
	fonts={}
	fonts["DEBUG"]=love.graphics.newFont(20)
	fonts["HELP"]=love.graphics.newFont(20)
	colors={}
	colors["DEFAULT"]={255,255,255,255}
	colors["DEBUG"]={255,0,0,255}
	colors["HELP"]={0,0,0,255}
	colors["UNDERLAY"]={255,255,255,128}
	
	--vars
	won=nil
	tim=0
	updateTim=1
	
	printx=0
	printy=0
	addx=0
	addy=0
	oaddx=0
	oaddy=0
	
	updateCounter=0
	smoothTime=STmax
	
	debug=true
	--debug=false
	debugStuff=""
	
	help=false
	drag=false
	
	control=true
	centerOnBot=true
	
	smoothMoving=false
	smoothTurning=0
	
	smoothBotRot=0
	robotsmoothx=0
	robotsmoothy=0
	
	
	smoothTime=1
	
	--defaults
	OLDsize={}
	OLDsize["W"]=10
	OLDsize["H"]=10
	robot={}
	robot["X"]=0
	robot["Y"]=0
	robot["HDG"]=0
	robot["NAME"]="failure"
	robot["BAT"]=0
	robots={}
	map={}
	for x=1,OLDsize["W"] do
		map[x]={}
		for y=1,OLDsize["H"] do
			map[x][y]=0
		end
	end
	info={}
	info["BAT"]=false
	info["LASER"]=false
	info["TURNS"]=false
	
	
	--print("YEAH")
	
	decoderChannel:clear()
	decoderChannel:push(serverAddr .. "/init")
	decoderThread:start()
	decoderThread:wait()
	res=decoderChannel:pop()
	
	
	botID=res
	--print("ID: " .. botID)
	--botID="149294806402758316987601636401142037943"
	--botID="160766468451547732226603809402618484943"
	
	
	decoderChannel:clear()
	decoderChannel:push(serverAddr .. "/game/" .. botID)	
	decoderThread:start()
	decoderThread:wait()
	
	update()
		
end

----------------------PROGS--------------------------------

function fullscreenSwitch()
	
	fullscreen=not fullscreen
	love.window.setFullscreen(fullscreen,"desktop")
	width=love.graphics.getWidth()
	height=love.graphics.getHeight()
	
end

function debugStuffADD(addstr)
	
	debugStuff=debugStuff .. "\n" .. addstr
	
end



function FWD()
	--SEND "STEP"
	--local res,sc,data=http.request(serverAddr .. "/action","bot_id=" .. botID .. "&action=step")
	if robot["HDG"]==0 then
		local target=map[ robot["X"] ][ robot["Y"]-1 ]
		if target==2 or target==3 or target==4 then
			return "cannot move"
		end
		--robot["Y"]=robot["Y"]-1
	elseif robot["HDG"]==1 then
		local target=map[ robot["X"]+1 ][ robot["Y"] ]
		if target==2 or target==3 or target==4 then
			return "cannot move"
		end
		--robot["X"]=robot["X"]+1
	elseif robot["HDG"]==2 then
		local target=map[ robot["X"] ][ robot["Y"]+1 ]
		if target==2 or target==3 or target==4 then
			return "cannot move"
		end
		--robot["Y"]=robot["Y"]+1
	elseif robot["HDG"]==3 then
		local target=map[ robot["X"]-1 ][ robot["Y"] ]
		if target==2 or target==3 or target==4 then
			return "cannot move"
		end
		--robot["X"]=robot["X"]-1
	end
	
		updateCounter=2
		
		actionChannel:clear()
		actionChannel:push(serverAddr .. "/action")
		actionChannel:push("bot_id=" .. botID .. "&action=step")
		actionThread:start()
		
		smoothMoving=true
		--smoothTime=STmax
	--rememberres=res
end

function LEFT()
	--SEND "TURN_LEFT"
	--local res,sc,data=http.request(serverAddr .. "/action","bot_id=" .. botID .. "&action=turn_left")
	
		updateCounter=2
		
	actionChannel:clear()
	actionChannel:push(serverAddr .. "/action")
	actionChannel:push("bot_id=" .. botID .. "&action=turn_left")
	actionThread:start()
	
	smoothTurning=-1
		--smoothTime=STmax
end

function RIGHT()
	--SEND "TURN_RIGHT"
	--local res,sc,data=http.request(serverAddr .. "/action","bot_id=" .. botID .. "&action=turn_right")
		
		updateCounter=2
		
	actionChannel:clear()
	actionChannel:push(serverAddr .. "/action")
	actionChannel:push("bot_id=" .. botID .. "&action=turn_right")
	actionThread:start()
	
	smoothTurning=1

		--smoothTime=STmax
end

function LASER()
	--SEND "LASER_BEAM"
	--local res,sc,data=http.request(serverAddr .. "/action","bot_id=" .. botID .. "&action=laser_beam")
	if info["LASER"] then
			
		actionChannel:clear()
		actionChannel:push(serverAddr .. "/action")
		actionChannel:push("bot_id=" .. botID .. "&action=laser_beam")
		actionThread:start()
		
	end

end

function WAIT()
	--SEND "WAIT"
	--local res,sc,data=http.request(serverAddr .. "/action","bot_id=" .. botID .. "&action=wait")
	
	actionChannel:clear()
	actionChannel:push(serverAddr .. "/action")
	actionChannel:push("bot_id=" .. botID .. "&action=wait")
	actionThread:start()

end



function update()

	if not decoderThread:isRunning() then
		--read
		if updateCounter>0 then updateCounter=updateCounter-1 end
		
		size=decoderChannel:pop()
		
		if size~=nil then
			if size["W"]~=nil and size["H"]~=nil then
				OLDsize=size
				map={}
				for x=1,size["W"]+0 do
					map[x]=decoderChannel:pop()
				end
				
				local OLDrobot=robot
				robot=decoderChannel:pop()
				--print(robot)
				
				--print("name: " .. robot["NAME"],"HDG: " .. robot["HDG"],"X,Y: " .. robot["X"],robot["Y"])
				
				local robotsn=decoderChannel:pop()
				robots={}
				for i=1,robotsn do
					table.insert(robots,decoderChannel:pop())
				end
				
				info=decoderChannel:pop()

				decoderChannel:clear()
				decoderChannel:push(serverAddr .. "/game/" .. botID)	
				decoderThread:start()
				
				--print(robot)
				if OLDrobot["X"]~=robot["X"] or OLDrobot["Y"]~=robot["Y"] then
					
					robotsmoothx=0
					robotsmoothy=0
					
					smoothMoving=false
				end
				if OLDrobot["HDG"]~=robot["HDG"] then
					
					smoothBotRot=0
					
					smoothTurning=0
				end
			else
				size=OLDsize
			end
		else
				size=OLDsize
		end
		
	end

end

function drawMap()

	for x=1,size["W"] do
		for y=1,size["H"] do
			if not centerOnBot then
				--printx=0-((((tileSize*botLOC[1]-addx))*2*scale-width-tileSize*scale)/2)
				--printy=0-((((tileSize*botLOC[2]-addy))*2*scale-height-tileSize*scale)/2)
				printx=0-((((oaddx-addx))*2*scale-width-tileSize*scale)/2)+((x-1)*tileSize)*scale
				printy=0-((((oaddy-addy))*2*scale-height-tileSize*scale)/2)+((y-1)*tileSize)*scale
				printxr=printx+robotsmoothx*scale
				printyr=printy+robotsmoothy*scale
			else
				printx=0-((tileSize*robot["X"]*2*scale-width-tileSize*scale)/2)+((x-1)*tileSize)*scale
				printy=0-((tileSize*robot["Y"]*2*scale-height-tileSize*scale)/2)+((y-1)*tileSize)*scale
				printxr=printx
				printyr=printy
				printx=printx-robotsmoothx*scale
				printy=printy-robotsmoothy*scale
			end
		
			love.graphics.draw(tiles[map[x][y]],printx,printy,0,scale,scale)
			
			--if robot["X"]==x and robot["Y"]==y then
			--	love.graphics.draw(myrobots[robot["HDG"]],printxr,printyr,0,scale,scale)
			--end
		end
	end
	
	

end

function drawRobots()

	for x=1,size["W"] do
		for y=1,size["H"] do
			if not centerOnBot then
				--printx=0-((((tileSize*botLOC[1]-addx))*2*scale-width-tileSize*scale)/2)
				--printy=0-((((tileSize*botLOC[2]-addy))*2*scale-height-tileSize*scale)/2)
				printx=0-((((oaddx-addx))*2*scale-width-tileSize*scale)/2)+((x-1)*tileSize)*scale
				printy=0-((((oaddy-addy))*2*scale-height-tileSize*scale)/2)+((y-1)*tileSize)*scale
				printxr=printx+robotsmoothx*scale
				printyr=printy+robotsmoothy*scale
			else
				printx=0-((tileSize*robot["X"]*2*scale-width-tileSize*scale)/2)+((x-1)*tileSize)*scale
				printy=0-((tileSize*robot["Y"]*2*scale-height-tileSize*scale)/2)+((y-1)*tileSize)*scale
				printxr=printx
				printyr=printy
				printx=printx-robotsmoothx*scale
				printy=printy-robotsmoothy*scale
			end
		
			for i=1,#robots do
				if x==robots[i]["X"]+0 and y==robots[i]["Y"]+0 then
					love.graphics.draw(urrobots[robots[i]["HDG"]],printx,printy,0,scale,scale)
				end
			end
			
			if robot["X"]==x and robot["Y"]==y then
				
				love.graphics.translate(printxr+((tileSize*scale)/2),printyr+((tileSize*scale)/2))
				
				love.graphics.rotate(math.rad(smoothBotRot))
				
				love.graphics.draw(myrobots[robot["HDG"]],-((tileSize*scale)/2),-((tileSize*scale)/2),0,scale,scale)
				
				--love.graphics.rotate(math.rad(-smoothBotRot))
				love.graphics.origin()
			end
		end
	end
	
end

----------------------UPDATE--------------------------------

function love.update(dt)
	
	tim=tim+dt
	if drag then
		addx=(love.mouse.getX()-dragx)/scale
		addy=(love.mouse.getY()-dragy)/scale
	end
	
	if smoothMoving then
		if robot["HDG"]==0 then
			robotsmoothy=robotsmoothy-((dt/smoothTime)*tileSize)
			robotsmoothx=0
		elseif robot["HDG"]==1 then
			robotsmoothx=robotsmoothx+((dt/smoothTime)*tileSize)
			robotsmoothy=0
		elseif robot["HDG"]==2 then
			robotsmoothy=robotsmoothy+((dt/smoothTime)*tileSize)
			robotsmoothx=0
		elseif robot["HDG"]==3 then
			robotsmoothx=robotsmoothx-((dt/smoothTime)*tileSize)
			robotsmoothy=0
		end
		
		if robotsmoothx>tileSize then
			robotsmoothx=tileSize
		end
		
		if robotsmoothy>tileSize then
			robotsmoothy=tileSize
		end
		
		if robotsmoothx<-tileSize then
			robotsmoothx=-tileSize
		end
		
		if robotsmoothy<-tileSize then
			robotsmoothy=-tileSize
		end
	end
	
	if smoothTurning==1 then
		smoothBotRot=smoothBotRot+(dt/smoothTime)*90
		if smoothBotRot>90 then smoothBotRot=90 end
	elseif smoothTurning==-1 then
		smoothBotRot=smoothBotRot-(dt/smoothTime)*90
		if smoothBotRot<-90 then smoothBotRot=-90 end
	end
	
	update()
	
end

------------------------INPUT-------------------

function love.keypressed(key)

	if key=="escape" then
		love.event.quit()
	elseif key=="tab" then
		control=not control
	elseif key=="f1" then
		help=not help
	elseif key=="f5" then
		centerOnBot=true
	elseif key=="f6" then
		oaddx=tileSize*robot["X"]
		oaddy=tileSize*robot["Y"]
		addx=0
		addy=0
		centerOnBot=false
	elseif key=="f3" then
		debug=not debug
	elseif key=="f11" then
		fullscreenSwitch()
	end
		
	if updateCounter==0 then
	
		if key=="up" then
			FWD()
		elseif key=="left" then
			LEFT() 
		elseif key=="right" then
			RIGHT()
		elseif key=="space" then
			LASER()
		elseif key=="return" then
			WAIT()
		end
		
	end

end

function love.keyreleased(key)

end

function love.mousepressed(x,y,mb)
	if mb==1 then
		dragx=x
		dragy=y
		drag=true
	end
end

function love.mousereleased(x,y,mb)
	if mb==1 then
		oaddx=oaddx-addx
		oaddy=oaddy-addy
		addx=0
		addy=0
		drag=false
	end
end

function love.wheelmoved(x,y)
	if y>0 then
		scale=scale-(scale/10)*(-y)
		if scale>1 then scale=1 end
	elseif y<0 then
		scale=scale+(scale/10)*(y)
	end
end

----------------------DRAW----------------------

function love.draw()
	
	
	drawMap()
	drawRobots()
	
	
	
	
	if help then
		love.graphics.setColor(colors["UNDERLAY"])
		
		love.graphics.rectangle("fill",0,0,width,height)
		
		love.graphics.setFont(fonts["HELP"])
		love.graphics.setColor(colors["HELP"])
		
		love.graphics.print("F1 - show/hide this help screen\nF3 - show/hide debug screen\nF5 - center view on bot\nF6 - in this mode map can me moved (left mouse button+drag)\nF11 - toggle fullscreen\nmouse wheel - scroll in/out\n\narrow up - step\narrow left - turn_left\narrow right - turn_right\nspace - laser_beam (not tested)\nreturn - wait (not tested)",10,10)
		
		debugStuff=""
	end
	
	if debug then
		love.graphics.setColor(colors["UNDERLAY"])
		
		love.graphics.rectangle("fill",0,0,width,height)
		
		love.graphics.setFont(fonts["DEBUG"])
		love.graphics.setColor(colors["DEBUG"])
	
		--table.insert(debugStuff,string.format("control: %s",control))
		--table.insert(debugStuff,string.format("centerOnBot: %s",centerOnBot))
		--table.insert(debugStuff,string.format("res: %s",res))
		--table.insert(debugStuff,string.format("botID: %s",botID))
		
		debugStuffADD(string.format("control: %s",control))
		debugStuffADD(string.format("centerOnBot: %s",centerOnBot))
		
		
		debugStuffADD(string.format("FPS: %s",love.timer.getFPS()))
		
		
		debugStuffADD(string.format("X: %s Y: %s",robot["X"],robot["Y"]))
		debugStuffADD(string.format("HDG: %s",robot["HDG"]))
		debugStuffADD(string.format("updatecounter: %s",updateCounter))
		debugStuffADD(string.format("SBR: %s",smoothBotRot))
		
		
		love.graphics.print(debugStuff,10,-20)
		
		debugStuff=""
	end
	
	love.graphics.setColor(colors["DEFAULT"])

end

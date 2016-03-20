function love.load()
	http=require("socket.http")
	
	--screen
	fullscreen=false
	width=love.graphics.getWidth()
	height=love.graphics.getHeight()
	
	tileSize=80
	
	love.window.setTitle("LUA vs PYbots")
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
	
	
	debugFont=love.graphics.newFont(20)
	colorWhite={255,255,255,255}
	colorDebug={255,0,0,255}
	
	--vars
	WON=nil
	tim=0
	updateTim=1
	debug=true
	--debug=false
	debugStuff=""
	
	drag=false
	
	control=true
	centerOnBot=true
	
	res,sc,data=http.request("http://hroch.spseol.cz:44822/init")	--result, state code, content
	res=decode(res)
	
	botID=res["bot_id"]
	--botID="149294806402758316987601636401142037943"
	
	
	res,sc,data=http.request("http://hroch.spseol.cz:44822/game/" .. botID)	--result, state code, content
	oldRes=res		--old data (form of original JSON)
	AD=decode(res)	--actualData
	
	batON=true
	if AD["game_info"]["battery_game"]=="false" then
		batON=false
	end
	
	laserON=true
	if AD["game_info"]["laser_game"]=="false" then
		batON=false
	end
	
	gameHeight=AD["game_info"]["map_resolutions"]["height"]+0
	gameWidth=AD["game_info"]["map_resolutions"]["width"]+0
	
	mapCanvas=love.graphics.newCanvas(80*gameWidth,80*gameHeight)
	
	botLOC={0,0}	--bot location
	botHDG=0
	
	for y=1,gameHeight do
		
		for x=1,gameWidth do
		
			if AD["map"][y][x]["your_bot"]=="true" then
				botLOC={x,y}
				--botHDG=AD["map"][y][x]["orientation"]+0
				botNAME=AD["map"][y][x]["name"]
			end
		
		end
		
	end
	
	--gameMap={}
	--for x=1,gameWidth do
	--	gameMap[x]={}
	--end
	
	update()
	drawMap()
	
	printx=0
	printy=0
	addx=0
	addy=0
	oaddx=0
	oaddy=0
		
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


	-------------------JSONtoolkit------------------ (call decode)
	function removeBorders(str)

		return string.sub(str,2,string.len(str)-1)

	end

	function decode(str)	--pilot function for decode

		str=removeBorders(str)
		local DecodeTab={}
		--print("1",DecodeTab)
		decod2(str,DecodeTab)
		--print("2",DecodeTab)
		return DecodeTab

	end

	function decod2(str,target)

		--print(target)

		local ss=nil
		local se=nil
		
		local name=nil
		
		local len=string.len(str)+1
		local char=nil
		local number=false
		
		local i=1	
		--for i=1,len do
		while i<len do
		
			char=string.sub(str,i,i)
			--print("char=" .. char,"\ti=" .. i)
			
			
			
			if number and (not string.find(char,"%d")) then
				number=false
				se=i
			end
			
			
			
			
			if ss and se then	--zacatek i konec retezce
				--print("\tSS SE")
				--print(string.sub(str,1,i),i)
				if char==":" then
					--print("\t!name")
					name=string.sub(str,ss+1,se-1)
					--print("\t\tname<" .. name)
					
				else
					if not name then --name is nil
						--print("\t!data w/o name")
						--print("\t\tdata<" .. string.sub(str,ss+1,se-1))
						table.insert(target,string.sub(str,ss+1,se-1))
					else
						--print("\t!data w/ name")
						target[name]=string.sub(str,ss+1,se-1)
						--print("\t\t@" .. name .. "<" .. string.sub(str,ss+1,se-1))
					end
					name=nil
				end
				ss=nil
				se=nil
			else				
				--print("\tELSE")
				if char==[["]] then
					if ss then
						se=i
					else
						ss=i
					end
				elseif string.find(char,"%d") and not ss then
					number=true
					--print("number")
					if not ss then
						ss=i-1
					end
				elseif char=="f" and not ss then
					if string.sub(str,i,i+4)=="false" then
						ss=i-1
						se=i+5
					end
				elseif char=="t" and not ss then
					if string.sub(str,i,i+3)=="true" then
						ss=i-1
						se=i+4
					end
				elseif char=="{" or char=="[" then
					--print(name==nil)
					if not name then
						local tlen=#target+1
						--target[tlen]=decode(string.sub(str,i+1))
						target[tlen]={}
						--print("\ttarget<" .. "NONAME")
						i=i+decod2(string.sub(str,i+1),target[tlen])
					else
						--target[name]=decode(string.sub(str,i+1))
						target[name]={}
						--print("\ttarget<" .. name)
						i=i+decod2(string.sub(str,i+1),target[name])
					end
					name=nil
				elseif char=="}" or char=="]" then
					--print("i " .. unpack(i))
					return i
				end
			end
			--print("\ti> " .. i)
			i=i+1
		end
		
		--print()
		--print(target)
		--return {unpack(target)}
		--return target
		return i

	end

	-----------------------------------------------------------


function FWD()
	--SEND "STEP"
	res,sc,data=http.request("http://hroch.spseol.cz:44822/action","bot_id=" .. botID .. "&action=step")
	--rememberres=res
	if res=="game_won" then
		WON=true
	elseif res=="game_lost" then
		WON=false
	else
		update()
	end
end

function LEFT()
	--SEND "TURN_LEFT"
	res,sc,data=http.request("http://hroch.spseol.cz:44822/action","bot_id=" .. botID .. "&action=turn_left")
	update()
end

function RIGHT()
	--SEND "TURN_RIGHT"
	res,sc,data=http.request("http://hroch.spseol.cz:44822/action","bot_id=" .. botID .. "&action=turn_right")
	update()
end

function LASER()
	--SEND "LASER_BEAM"
	res,sc,data=http.request("http://hroch.spseol.cz:44822/action","bot_id=" .. botID .. "&action=laser_beam")
	update()
end

function WAIT()
	--SEND "WAIT"
	res,sc,data=http.request("http://hroch.spseol.cz:44822/action","bot_id=" .. botID .. "&action=wait")
	update()
end


function update()

	res,sc,data=http.request("http://hroch.spseol.cz:44822/game/" .. botID)	--result, state code, content
	AD=decode(res)	--actualData
	drawMap()

end

function drawMap()
	--if gameMap then
	love.graphics.setCanvas(mapCanvas)
	love.graphics.clear(0,0,0,0)
		for x=1,gameWidth do
			
			for y=1,gameHeight do
			
				love.graphics.draw(tiles[AD["map"][y][x]["field"]+0],       80*x-80,80*y-80         )
				if AD["map"][y][x]["field"]+0==2 then
					if AD["map"][y][x]["your_bot"]=="true" then	--is normal game
						love.graphics.draw(myrobots[AD["map"][y][x]["orientation"]+0],       80*x-80,80*y-80         )
						botLOC={x,y}
					else
						love.graphics.draw(urrobots[AD["map"][y][x]["orientation"]+0],       80*x-80,80*y-80         )
					end
				elseif AD["map"][y][x]["field"]+0==4 then			--iz batterry game
					if AD["map"][y][x]["your_bot"]=="true" then
						love.graphics.draw(myrobots[AD["map"][y][x]["orientation"]+0],       80*x-80,80*y-80         )
						botLOC={x,y}
					else
						love.graphics.draw(urrobots[AD["map"][y][x]["orientation"]+0],       80*x-80,80*y-80         )
					end
				end
			
			end
			
		end
	love.graphics.setCanvas()
	--end
end

function check()

	res,sc,data=http.request("http://hroch.spseol.cz:44822/game/" .. botID)	--result, state code, content
	local lenres=string.len(res)
	if lenres==string.len(oldRes) then
	
		for i=1,lenres do
			if string.sub(res,i,i)~=string.sub(oldRes,i,i) then
				oldRes=res
				AD=decode(res)
				--drawMap()
				updating=true
				break
			end
			--love.draw()
		end
	
	else
	
		oldRes=res
		AD=decode(res)
		--drawMap()
		updating=true
		
	end

end

----------------------UPDATE--------------------------------

function love.update(dt)
	
	tim=tim+dt
	if drag then
		--if oaddx or oaddy then
		--	dragx=(dragx-oaddx*scale)
		--	dragy=(dragy-oaddy*scale)
		--	oaddx=0
		--	oaddy=0
		--end
		addx=(love.mouse.getX()-dragx)/scale
		addy=(love.mouse.getY()-dragy)/scale
	end
	
	--if tim>updateTim then
	--	updateTim=tim+1
	--	check()
	--	update()
	--	drawMap()
	--end

end

------------------------INPUT-------------------

function love.keypressed(key)

	if key=="escape" then
		love.event.quit()
	elseif key=="tab" then
		control=not control
	elseif key=="f1" then
		centerOnBot=true
	elseif key=="f2" then
		oaddx=tileSize*botLOC[1]
		oaddy=tileSize*botLOC[2]
		addx=0
		addy=0
		centerOnBot=false
	elseif key=="f11" then
		fullscreenSwitch()
	elseif key=="up" then
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

function love.keyreleased(key)

end

function love.mousepressed( x, y, mb )
   if mb == "wd" then
      scale=scale-scale/10
   elseif mb == "wu" then
      scale=scale+scale/10
      if scale>1 then scale=1 end
   elseif mb=="l" then
	dragx=x
	dragy=y
	drag=true
   end
end

function love.mousereleased( x, y, mb )
	if mb=="l" then
		oaddx=oaddx-addx
		oaddy=oaddy-addy
		addx=0
		addy=0
		drag=false
	end
end

----------------------DRAW----------------------

function love.draw()
	
	if won==nil then
		
		
		if not centerOnBot then
			--printx=0-((((tileSize*botLOC[1]-addx))*2*scale-width-tileSize*scale)/2)
			--printy=0-((((tileSize*botLOC[2]-addy))*2*scale-height-tileSize*scale)/2)
			printx=0-((((oaddx-addx))*2*scale-width-tileSize*scale)/2)
			printy=0-((((oaddy-addy))*2*scale-height-tileSize*scale)/2)
		else
			printx=0-((tileSize*botLOC[1]*2*scale-width-tileSize*scale)/2)
			printy=0-((tileSize*botLOC[2]*2*scale-height-tileSize*scale)/2)
		end
		
		love.graphics.draw(mapCanvas,printx,printy,0,scale,scale)
	
	elseif won then
		love.graphics.print("you have won",50,50)
	else
		love.graphics.print("you have lost",50,50)
	end
	
	if debug then
		love.graphics.setFont(debugFont)
		love.graphics.setColor(colorDebug)
	
		--table.insert(debugStuff,string.format("control: %s",control))
		--table.insert(debugStuff,string.format("centerOnBot: %s",centerOnBot))
		--table.insert(debugStuff,string.format("res: %s",res))
		--table.insert(debugStuff,string.format("botID: %s",botID))
		
		debugStuffADD(string.format("control: %s",control))
		debugStuffADD(string.format("centerOnBot: %s",centerOnBot))
		debugStuffADD(string.format("botID: %s",botID))
		debugStuffADD(string.format("batON: %s",batON))
		debugStuffADD(string.format("gameHeight: %s",gameHeight))
		debugStuffADD(string.format("gameWidth: %s",gameWidth))
		
		debugStuffADD(string.format("botLOC: %d, %d",botLOC[1],botLOC[2]))
		debugStuffADD(string.format("botHDG: %d",botHDG))
		debugStuffADD(string.format("botNAME: %s",botNAME))
		
		debugStuffADD(string.format("FPS: %s",love.timer.getFPS()))
		
		love.graphics.print(debugStuff,10,-20)
		
		debugStuff=""
		love.graphics.setColor(colorWhite)
	end

end

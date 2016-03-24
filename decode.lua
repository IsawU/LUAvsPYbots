
	http=require("socket.http")
	--serverAddr="http://hroch.spseol.cz:44822"

------------------JSONtoolkit------------------ (call decode)
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




	print("hello decoderThread")

	decoderChannel=love.thread.getChannel("decoderChannel")

	local address=decoderChannel:pop()
	decoderChannel:clear()
	
	--botID="160766468451547732226603809402618484943"
	
	value=http.request(address)
	
	local avalue=decode(value)
	

	
	if avalue["bot_id"] then
		--print("thread IF")
		--print(avalue["bot_id"])
		decoderChannel:push(avalue["bot_id"])
	else
		--print("thread ELSE")
		--decode to my format
		
		--push bot info
		
		--push map
		
		local gameSetup={}
			gameSetup["BAT"]=false
			if avalue["game_info"]["battery_game"]=="true" then
				gameSetup["BAT"]=true
			end
			
			gameSetup["LASER"]=false
			if avalue["game_info"]["laser_game"]=="true" then
				gameSetup["LASER"]=true
			end
			
			gameSetup["TURNS"]=false
			if avalue["rounded_game"]=="true" then
				gameSetup["TURNS"]=true
			end
		
			--print("turns" .. string.format("%s",gameSetup["TURNS"]))
		
		local gameSize={}
			gameSize["W"]=avalue["game_info"]["map_resolutions"]["width"]+0
			gameSize["H"]=avalue["game_info"]["map_resolutions"]["height"]+0
			
			--print("size" .. string.format("%s",gameSize["H"])  )
			
		local map={}
		
		local robots={}
		
		local robot={}
		
			local len=avalue["game_info"]["map_resolutions"]["height"]+0
			local len2=avalue["game_info"]["map_resolutions"]["width"]+0
	
			for x=1,len2 do
				map[x]={}
				for y=1,len do
					map[x][y]=avalue["map"][y][x]["field"]+0
					
					if avalue["map"][y][x]["field"]=="2" then
						if avalue["map"][y][x]["your_bot"]=="true" then
							robot["X"]=x
							robot["Y"]=y
							robot["NAME"]=avalue["map"][y][x]["name"]
							robot["HDG"]=avalue["map"][y][x]["orientation"]+0
						else
							local bot={}
							bot["X"]=x
							bot["Y"]=y
							bot["NAME"]=avalue["map"][y][x]["name"]
							bot["HDG"]=avalue["map"][y][x]["orientation"]+0
								
							table.insert(robots,bot)
						end
					elseif avalue["map"][y][x]["field"]=="4" then
						if avalue["map"][y][x]["your_bot"]=="true" then
							robot["X"]=x
							robot["Y"]=y
							robot["NAME"]=avalue["map"][y][x]["name"]
							robot["HDG"]=avalue["map"][y][x]["orientation"]+0
							robot["BAT"]=avalue["map"][y][x]["battery_level"]+0
						else
							local bot={}
							bot["X"]=x
							bot["Y"]=y
							bot["NAME"]=avalue["map"][y][x]["name"]
							bot["HDG"]=avalue["map"][y][x]["orientation"]+0
							bot["BAT"]=avalue["map"][y][x]["battery_level"]+0
								
							table.insert(robots,bot)
						end
					end
				end
			end
			
				
		
		--push gameSize
		decoderChannel:push(gameSize)
		--push map
		for i=1,#map do
			decoderChannel:push(map[i])
		end
		--push robot
		decoderChannel:push(robot)
		--pushrobots number
		decoderChannel:push(#robots)
		--push robots
		for i=1,#robots do
			decoderChannel:push(robots[i])
		end		
		--push game setup
		decoderChannel:push(gameSetup)
		
		
		
		--print("thread ELSE end")
	end
	



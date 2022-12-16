functor
import
	GUI
	Input
	PlayerManager
	System
	OS
define
	DoListPlayer
	InitThreadForAll
	PlayersPorts
	SendToAll
	SimulatedThinking
	Main
	WindowPort
	CheckMove
	ChangeState

	proc {DrawFlags Flags Port}
		case Flags of nil then skip 
		[] Flag|T then
			{Send Port putFlag(Flag)}
			{DrawFlags T Port}
		end
	end
in
    fun {DoListPlayer Players Colors ID}
		case Players#Colors
		of nil#nil then nil
		[] (Player|NextPlayers)#(Color|NextColors) then
			player(ID {PlayerManager.playerGenerator Player Color ID})|
			{DoListPlayer NextPlayers NextColors ID+1}
		end
	end

	SimulatedThinking = proc{$} {Delay ({OS.rand} mod (Input.thinkMax - Input.thinkMin) + Input.thinkMin)} end

	proc {Main Port ID State}
		% {System.show startOfLoop(ID)}

		Dead
		Position
		ValidMove
		NewMines
		NewFlags
		NewMap
		NewPlayer
	in
		{Send Port isDead(Dead)}
		if Dead == true then 
			{Delay respawnDelay}
			{Send Port respawn()}
		else
			{Send Port move(ID Position)}
			{CheckMove State.map Position ValidMove}
			if ValidMove then
				if (State.player.x - Position.x) < -1 or (State.player.x - Position.x) > 1 or (State.player.y - Position.y) < -1 or (State.player.y - Position.y) > 1 then
					{SendToAll SayMoved(ID Position)}
					{Send WindowPort moveSoldier(ID Position)}
				end
			end
		end


		
		% {System.show endOfLoop(ID)}
		{SimulatedThinking}
		{Main Port ID state(mines:NewMines flags:NewFlags map:NewMap player:NewPlayer)}
	end

	proc {CheckMove Map Position ?Valid}
		fun {CheckRow Row Index}
			case Row of nil then -1
			[] H|T then
				if Index == 0 then
					H
				end
			end
		end
	in
		case Map of nil then -1
		[] H|T then
			if Position.x == 0 then
				Valid = {CheckRow H Position.y} == 0
			end
		end
	end

	proc {SendToAll Msg}
		{ForAll PlayersPorts proc {$ P} {Send P Msg} end}
	end

	proc {InitThreadForAll Players}
		case Players
		of nil then
			{Send WindowPort initSoldier(null pt(x:0 y:0))}
			{DrawFlags Input.flags WindowPort}
		[] player(_ Port)|Next then ID Position in
			{Send Port initPosition(ID Position)}
			{Send WindowPort initSoldier(ID Position)}
			{Send WindowPort lifeUpdate(ID Input.startHealth)}
			thread
			 	{Main Port ID state(mines:nil flags:Input.flags map:Input.Map player:Position)}
			end
			{InitThreadForAll Next}
		end
	end

    thread
		% Create port for window
		WindowPort = {GUI.portWindow}

		% Open window
		{Send WindowPort buildWindow}
		{System.show buildWindow}

        % Create port for players
		PlayersPorts = {DoListPlayer Input.players Input.colors 1}

		{InitThreadForAll PlayersPorts}
	end
end

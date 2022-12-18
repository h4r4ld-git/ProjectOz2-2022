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
	GetPoint
	StatePortObject
	ControllerMemory

	proc {DrawFlags Flags Port}
		case Flags of nil then skip 
		[] Flag|T then
			{Send Port putFlag(Flag)}
			{DrawFlags T Port}
		end
	end
in

	fun {StatePortObject F Init}
		P S O 
	in
		thread {NewPort S P} {FoldL S F Init O} end
		proc {$ X} {Send P X} end
	end

	ControllerMemory = {StatePortObject 
		fun {$ States Msg}
			fun {UpdateState States ID NewState}
				case States of nil then
					[player(id:ID state:NewState)]
				[] H|T then
					if H.id == ID then
						player(id:ID state:NewState)|T
					else
						H|{UpdateState T ID NewState}
					end
				end
			end

			fun {GetID States ID}
				case States of nil then nil
				[] H|T then
					if H.id == ID then
						H.state
					else
						{GetID T ID}
					end
				end
			end

			fun {IsValid States Position}
				case States of nil then true
				[] H|T then
					if H.state.player.x == Position.x andthen H.state.player.y == Position.y then
						false
					else
						{IsValid T Position}
					end
				end
			end
		in
			case Msg of get(Mem) then
				Mem = States
				States
			[] getIDState(State ID) then
				State = {GetID States ID.id}
				States
			[] update(State ID) then
				{UpdateState States ID.id State}
			[] isDead(Dead ID) then
				Dead = {GetID States ID.id}.hp == 0
				States
			[] validMove(Valid Position) then
				Valid = {IsValid States Position}
				States
			end
		end
		nil}

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
		NewPlayer
		NewValue
		NewHp
		BaseValue
		PlayersState
		NoPlayer
	in
		{ControllerMemory isDead(Dead ID)}
		if Dead == true then 
			{Delay respawnDelay}
			NewHp = Input.startHealth
			{ControllerMemory update(state(mines:State.mines flags:State.flags map:State.map player:State.player hp:NewHp basePosition:State.basePosition) ID)}
			{Send Port respawn}
		end

		{Send Port move(ID Position)}
		{ControllerMemory validMove(NoPlayer Position)}
		if NoPlayer then
			BaseValue = {GetPoint State.map State.basePosition.x State.basePosition.y} 
			NewValue = {GetPoint State.map Position.x Position.y}
			ValidMove = (NewValue == 0 orelse NewValue == BaseValue) andthen (((State.player.x - Position.x) < ~1) orelse ((State.player.x - Position.x) > 1) orelse ((State.player.y - Position.y) < ~1) orelse ((State.player.y - Position.y) > 1))
			if ValidMove then
				{SendToAll sayMoved(ID Position)}
				{Send WindowPort moveSoldier(ID Position)}
				NewPlayer = Position
				{ControllerMemory update(state(mines:State.mines flags:State.flags map:State.map player:NewPlayer hp:State.hp basePosition:State.basePosition) ID)}
			else
				NewPlayer = State.player
			end
		else
			NewPlayer = State.player
		end
		

		NewMines = State.mines
		NewFlags = State.flags

		% {System.show endOfLoop(ID)}
		{SimulatedThinking}
		{Main Port ID state(mines:NewMines flags:NewFlags map:State.map player:NewPlayer hp:State.hp basePosition:State.basePosition)}
	end

	fun {GetPoint Map X Y}
		fun {CheckRow Row Index}
			case Row of nil then ~1
			[] H|T then
				if Index == 0 then
					H
				else
					{CheckRow T Index-1}
				end
			end
		end
	in
		case Map of nil then false
		[] H|T then
			if X == 0 then
				{CheckRow H Y}
			else
				{GetPoint T X-1 Y}
			end
		end
	end

	proc {SendToAll Msg}
		{ForAll PlayersPorts proc {$ P} {Send P.2 Msg} end}
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
				State = state(mines:nil flags:Input.flags map:Input.map player:Position hp:Input.startHealth basePosition:Position)
			in
				{ControllerMemory update(State ID)}
			 	{Main Port ID State}
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

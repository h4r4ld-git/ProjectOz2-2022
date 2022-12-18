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

			fun {MinesContaines Mines Position}
				case Mines of nil then false
				[] H|T then
					if H.pos.x == Position.x andthen H.pos.y == Position.y then
						true
					else
						{MinesContaines T Position}
					end
				end
			end

			fun {OnMine States Position}
				case States of nil then false
				[] H|T then
					if {MinesContaines H.state.mines Position} then
						true
					else
						{OnMine T Position}
					end
				end
			end

			fun {MineExploded CurrStates Position ID}
				case CurrStates of nil then nil
				[] H|T then
					if (H.id > ID orelse H.id < ID) andthen ((H.state.player.x - Position.x) == ~1 orelse (H.state.player.x - Position.x) == 1) andthen ((H.state.player.y - Position.y) == ~1 orelse (H.state.player.y - Position.y) == 1) then
						H|{MineExploded T Position ID}
					else
						{MineExploded T Position ID}
					end
				end
			end

			fun {UpdateForAllMines States Players}
				fun {IsTouched CurrPlayers Player}
					case CurrPlayers of nil then false
					[] H|T then
						if H.id == Player.id then
							true
						else
							{IsTouched T Player}
						end
					end
				end
			in
				case States of nil then nil
				[] H|T then
					if {IsTouched Players H} then
						player(id:H.id state:state(mines:H.state.mines flags:H.state.flags map:H.state.map player:H.state.player hp:H.state.hp-1 basePosition:H.state.basePosition mineCharge:H.state.mineCharge gunCharge:H.state.gunCharge))|{UpdateForAllMines T Players}
					else
						H|{UpdateForAllMines T Players}
					end
				end
			end

			fun {UpdateMines States Position}
				fun {NewMines Mines Position}
					case Mines of nil then nil
					[] H|T then
						if H.pos.x == Position.x andthen H.pos.y == Position.y then
							{NewMines T Position}
						else
							H|{NewMines T Position}
						end
					end
				end
			in
				case States of nil then nil
				[] H|T then
					player(id:H.id state:state(mines:{NewMines H.state.mines Position} flags:H.state.flags map:H.state.map player:H.state.player hp:H.state.hp basePosition:H.state.basePosition mineCharge:H.state.mineCharge gunCharge:H.state.gunCharge))|{UpdateMines T Position}
				end
			end

			fun {ShootPlayer States Position}
				case States of nil then nil
				[] H|T then
					if H.state.player.x == Position.x andthen H.state.player.y == Position.y then
						H
					else
						{ShootPlayer T Position}
					end
				end
			end

			fun {Shoot States Pos}
				case States of nil then none
				[] H|T then
					if {MinesContaines H.state.mines Pos} then
						mine
					elseif H.state.player.x == Pos.x andthen H.state.player.y == Pos.y then
						player
					else
						{Shoot T Pos}
					end
				end
			end

			fun {PlaceMine States ID Pos}
				
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
				Dead = {GetID States ID.id}.hp < 1
				States
			[] validMove(Valid Position) then
				Valid = {IsValid States Position}
				States
			[] isOnMine(IsOnMine Position) then
				IsOnMine = {OnMine States Position}
				States
			[] mineExploded(Touched Position ID) then
				Touched = {MineExploded States Position ID.id}
				{UpdateMines {UpdateForAllMines States Touched} Position}
			[] shootPlayer(TouchedPlayer Pos) then
				TouchedPlayer = {ShootPlayer States Pos}
				{UpdateState States TouchedPlayer.id state(mines:TouchedPlayer.state.mines flags:TouchedPlayer.state.flags map:TouchedPlayer.state.map player:TouchedPlayer.state.player hp:TouchedPlayer.state.hp basePosition:TouchedPlayer.state.basePosition mineCharge:TouchedPlayer.state.mineCharge gunCharge:TouchedPlayer.state.gunCharge)}
			[] shoot(Touched Pos) then
				Touched = {Shoot States Pos}
				States
			[] placeMine(ID Pos) then
				{UpdateState States ID.id {PlaceMine States ID Pos}}
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
		RespawnHp
		NewHp
		BaseValue
		PlayersState
		NoPlayer
		IsOnMine
		NewState
		Touched
		DeadOnMine
	in
		{ControllerMemory isDead(Dead ID)}
		if Dead == true then 
			{Delay respawnDelay}
			RespawnHp = Input.startHealth
			{ControllerMemory update(state(mines:State.mines flags:State.flags map:State.map player:State.player hp:RespawnHp basePosition:State.basePosition mineCharge:State.mineCharge gunCharge:State.gunCharge) ID)}
			{Send WindowPort lifeUpdate(ID Input.startHealth)}
			{Send Port respawn}
		end

		{Send Port move(ID Position)}
		{ControllerMemory validMove(NoPlayer Position)}
		if NoPlayer then
			BaseValue = {GetPoint State.map State.basePosition.x-1 State.basePosition.y-1} 
			NewValue = {GetPoint State.map Position.x-1 Position.y-1}
			ValidMove = (NewValue == 0 orelse NewValue == BaseValue) andthen (((State.player.x - Position.x) > ~2) andthen ((State.player.x - Position.x) < 2) andthen ((State.player.y - Position.y) > ~2) andthen ((State.player.y - Position.y) < 2))
			if ValidMove then
				{SendToAll sayMoved(ID Position)}
				{Send WindowPort moveSoldier(ID Position)}
				NewPlayer = Position
				{ControllerMemory update(state(mines:State.mines flags:State.flags map:State.map player:NewPlayer hp:State.hp basePosition:State.basePosition mineCharge:State.mineCharge gunCharge:State.gunCharge) ID)}
			else
				NewPlayer = State.player
			end
		else
			NewPlayer = State.player
		end
		
		{ControllerMemory isOnMine(IsOnMine Position)}
		if IsOnMine then
			NewHp = State.hp - 2
			{ControllerMemory update(state(mines:State.mines flags:State.flags map:State.map player:State.player hp:NewHp basePosition:State.basePosition mineCharge:State.mineCharge gunCharge:State.gunCharge) ID)}
			{ControllerMemory mineExploded(Touched Position ID)}
			{SendToAll sayDamageTaken(ID 2 NewHp)}
			{SendToAll sayMineExplode(mine(pos:Position))}
			{ForAll Touched proc {$ T} {SendToAll sayDamageTaken(T.id 1 T.state.hp)} end}
			DeadOnMine = NewHp == 0
		else
			DeadOnMine = false
		end
		
		if DeadOnMine then
			{SendToAll sayDeath(ID)}
		else
			ID
			ItemKind
			FireItem
			FireID
			NewMineCharge
			NewGunCharge
		in
			{Send Port chargeItem(ID ItemKind)}
			if ItemKind == gun then
				NewGunCharge = State.gunCharge - 1
				NewMineCharge = State.mineCharge
				{ControllerMemory update(state(mines:State.mines flags:State.flags map:State.map player:State.player hp:State.hp basePosition:State.basePosition mineCharge:State.mineCharge gunCharge:State.gunCharge-1) ID)}
			elseif ItemKind == mine then
				NewGunCharge = State.gunCharge
				NewMineCharge = State.mineCharge - 1
				{ControllerMemory update(state(mines:State.mines flags:State.flags map:State.map player:State.player hp:State.hp basePosition:State.basePosition mineCharge:State.mineCharge-1 gunCharge:State.gunCharge) ID)}
			end
			{SendToAll sayCharge(ID ItemKind)}

			{Send Port fireItem(FireID FireItem)}
			case FireItem of null then skip
			[] gun(pos:Pos) then
				if NewGunCharge == 0 then
					Touched
				in
					{SendToAll sayShoot(ID Pos)}
					{ControllerMemory update(state(mines:State.mines flags:State.flags map:State.map player:State.player hp:State.hp basePosition:State.basePosition mineCharge:State.mineCharge gunCharge:Input.gunCharge) ID)}
					{ControllerMemory shoot(Touched Pos)}
					case Touched of none then skip
					[] player then
						TouchedPlayer
					in
						{ControllerMemory shootPlayer(TouchedPlayer Pos)}
						{SendToAll sayDamageTaken(TouchedPlayer.id 1 TouchedPlayer.state.hp)}
					[] mine then
						TouchedPlayers
					in
						{ControllerMemory mineExploded(TouchedPlayers Pos ID)}
						{SendToAll sayMineExplode(mine(pos:Pos))}
						{ForAll TouchedPlayers proc {$ T} {SendToAll sayDamageTaken(T.id 1 T.state.hp)} end}
					end
				end
			[] mine(pos:Pos) then
				if NewMineCharge == 0 andthen NewPlayer.x == Pos.x andthen NewPlayer.y == Pos.y then
					{ControllerMemory update(state(mines:State.mines flags:State.flags map:State.map player:State.player hp:State.hp basePosition:State.basePosition mineCharge:Input.mineCharge gunCharge:State.gunCharge) ID)}
					{SendToAll sayMinePlaced(ID mine(pos:Pos))}
					{ControllerMemory placeMine(ID Pos)}
				end
			end


		end

		NewMines = State.mines
		NewFlags = State.flags

		% {System.show endOfLoop(ID)}
		{SimulatedThinking}
		{ControllerMemory getIDState(NewState ID)}
		{Main Port ID NewState}
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
				State = state(mines:nil flags:Input.flags map:Input.map player:Position hp:Input.startHealth basePosition:Position mineCharge:Input.mineCharge gunCharge:Input.gunCharge)
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

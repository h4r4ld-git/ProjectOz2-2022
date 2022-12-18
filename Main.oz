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
	WinControl
	SpawnFood
	RandomInRange = fun {$ Min Max} Min+({OS.rand}mod(Max-Min+1)) end

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

	WinControl = {StatePortObject 
		fun {$ State Msg}
			case Msg of getWin(?B) then
				B = State
				State
			[] setWin then
				true
			end
		end
		false}

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
						player(id:H.id state:state(mines:H.state.mines flags:H.state.flags map:H.state.map player:H.state.player hp:H.state.hp-1 basePosition:H.state.basePosition mineCharge:H.state.mineCharge gunCharge:H.state.gunCharge hasFlag:H.state.hasFlag foods:H.state.foods))|{UpdateForAllMines T Players}
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
					player(id:H.id state:state(mines:{NewMines H.state.mines Position} flags:H.state.flags map:H.state.map player:H.state.player hp:H.state.hp basePosition:H.state.basePosition mineCharge:H.state.mineCharge gunCharge:H.state.gunCharge hasFlag:H.state.hasFlag foods:H.state.foods))|{UpdateMines T Position}
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
				case States of nil then nil
				[] H|T then
					if ID == H.id then
						state(mines:mine(pos:Pos)|H.state.mines flags:H.state.flags map:H.state.map player:H.state.player hp:H.state.hp basePosition:H.state.basePosition mineCharge:H.state.mineCharge gunCharge:H.state.gunCharge hasFlag:H.state.hasFlag foods:H.state.foods)
					else
						{PlaceMine T ID Pos}
					end
				end
			end

			fun {ChangeFlags States NewFlags}
				case States of nil then nil
				[] H|T then
					player(id:H.id state:state(mines:H.state.mines flags:NewFlags map:H.state.map player:H.state.player hp:H.state.hp basePosition:H.state.basePosition mineCharge:H.state.mineCharge gunCharge:H.state.gunCharge hasFlag:H.state.hasFlag foods:H.state.foods))|{ChangeFlags T NewFlags}
				end
			end

			fun {AddFood States I J}
				case States of nil then nil
				[] H|T then
					player(id:H.id state:state(mines:H.state.mines flags:H.state.mines map:H.state.map player:H.state.player hp:H.state.hp basePosition:H.state.basePosition mineCharge:H.state.mineCharge gunCharge:H.state.gunCharge hasFlag:H.state.hasFlag foods:food(pos:pt(x:I y:J))|H.state.foods))|{AddFood T I J}
				end
			end

			fun {RemoveFood States Food}
				fun {UnFood Foods Food}
					case Foods of nil then nil
					[] H|T then
						if H.pos.x == Food.pos.x andthen H.pos.y == Food.pos.y then
							{UnFood T Food} 
						else
							H|{UnFood T Food}
						end
					end
				end
			in
				case States of nil then nil
				[] H|T then
					player(id:H.id state:state(mines:H.state.mines flags:H.state.mines map:H.state.map player:H.state.player hp:H.state.hp basePosition:H.state.basePosition mineCharge:H.state.mineCharge gunCharge:H.state.gunCharge hasFlag:H.state.hasFlag foods:{UnFood H.state.foods Food}))|{RemoveFood T Food}
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
				{UpdateState States TouchedPlayer.id state(mines:TouchedPlayer.state.mines flags:TouchedPlayer.state.flags map:TouchedPlayer.state.map player:TouchedPlayer.state.player hp:TouchedPlayer.state.hp basePosition:TouchedPlayer.state.basePosition mineCharge:TouchedPlayer.state.mineCharge gunCharge:TouchedPlayer.state.gunCharge hasFlag:TouchedPlayer.state.hasFlag foods:TouchedPlayer.state.foods)}
			[] shoot(Touched Pos) then
				Touched = {Shoot States Pos}
				States
			[] placeMine(ID Pos) then
				{UpdateState States ID.id {PlaceMine States ID Pos}}
			[] changeFlags(NewFlags) then
				{ChangeFlags States NewFlags}
			[] addFood(I J) then
				{AddFood States I J}
			[] removeFood(Food) then
				{RemoveFood States Food}
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

		fun {RemoveMine Mines Pos}
			case Mines of nil then nil
			[] H|T then
				if H.pos.x == Pos.x andthen H.pos.y == Pos.y then
					{Send WindowPort removeMine(H)}
					{RemoveMine T Pos}
				else
					H|{RemoveMine T Pos}
				end
			end
		end

		fun {RemoveFood Foods Pos}
			case Foods of nil then nil
			[] H|T then
				if H.pos.x == Pos.x andthen H.pos.y == Pos.y then
					{Send WindowPort removeFood(H)}
					{RemoveFood T Pos}
				else
					H|{RemoveFood T Pos}
				end
			end
		end

		Dead
		FirstHp
		AfterFoodHp
		Position
		HasFlag
		NoPlayer
		ValidMove
		NewValue
		BaseValue
		NewPlayerPos
		NewMines
		NewFlags
		NewFoods
		SecondHp
		PlayersState
		IsOnMine
		NewState
		Touched
		DeadOnMine
		ActualValue = {GetPoint State.map State.player.x-1 State.player.y-1}
		BaseValue = {GetPoint State.map State.basePosition.x-1 State.basePosition.y-1}
		Win
	in
		{ControllerMemory isDead(Dead ID)}
		if Dead == true then 
			{Send WindowPort removeSoldier(ID State.player)}
			{SendToAll sayDeath(ID)}
			{Delay respawnDelay}
			{Send WindowPort initSoldier(ID State.player)}
			FirstHp = Input.startHealth
			if State.hasFlag then
				{SendToAll sayFlagDropped(ID flag(pos:State.player color:ID.color))}
			end
			{ControllerMemory update(state(mines:State.mines flags:State.flags map:State.map player:State.player hp:FirstHp basePosition:State.basePosition mineCharge:State.mineCharge gunCharge:State.gunCharge hasFlag:false foods:State.foods) ID)}
			{Send WindowPort lifeUpdate(ID Input.startHealth)}
			{Send Port respawn}
			HasFlag = false
		else
			FirstHp = State.hp
			HasFlag = State.hasFlag
		end

		{Send Port move(ID Position)}
		{ControllerMemory validMove(NoPlayer Position)}
		if NoPlayer then
			fun {NewFlagPos Flags Pos NewPos}
				case Flags of nil then nil
				[] H|T then
					if H.pos.x == Pos.x andthen H.pos.y == Pos.y then
						{Send WindowPort removeFlag(H)}
						{Send WindowPort putFlag(flag(pos:NewPos color:H.color))}
						flag(pos:NewPos color:H.color)|T
					else
						H|{NewFlagPos T Pos NewPos}
					end
				end
			end

			fun {OnFood Foods Pos}
				case Foods of nil then false
				[] H|T then
					if H.pos.x == Pos.x andthen H.pos.y == Pos.y then
						true
					else
						{OnFood T Pos}
					end
				end
			end
		in
			NewValue = {GetPoint State.map Position.x-1 Position.y-1}
			ValidMove = (NewValue == 0 orelse NewValue == BaseValue) andthen (((State.player.x - Position.x) > ~2) andthen ((State.player.x - Position.x) < 2) andthen ((State.player.y - Position.y) > ~2) andthen ((State.player.y - Position.y) < 2))
			if ValidMove then
				{SendToAll sayMoved(ID Position)}
				{Send WindowPort moveSoldier(ID Position)}
				NewPlayerPos = Position
				if HasFlag then
					NewFlags = {NewFlagPos State.flags State.player NewPlayerPos}
					{ControllerMemory changeFlags(NewFlags)}
				else
					NewFlags = State.flags
				end
				if {OnFood State.foods Position} then
					AfterFoodHp = FirstHp + 1
					{Send WindowPort lifeUpdate(ID AfterFoodHp)}
					{ControllerMemory removeFood(food(pos:Position))}
					{SendToAll sayFoodEaten(ID food(pos:Position))}
					{Send WindowPort removeFood(food(pos:Position))}
					NewFoods = {RemoveFood State.foods Position}
				else
					AfterFoodHp = FirstHp
					NewFoods = State.foods
				end
				{ControllerMemory update(state(mines:State.mines flags:NewFlags map:State.map player:NewPlayerPos hp:AfterFoodHp basePosition:State.basePosition mineCharge:State.mineCharge gunCharge:State.gunCharge hasFlag:HasFlag foods:NewFoods) ID)}
			else
				NewPlayerPos = State.player
				NewFlags = State.flags
			end
		else
			NewPlayerPos = State.player
			NewFlags = State.flags
		end
		{ControllerMemory isOnMine(IsOnMine NewPlayerPos)}
		if IsOnMine then
			NewMines = {RemoveMine State.mines NewPlayerPos}
			SecondHp = AfterFoodHp - 2
			{ControllerMemory update(state(mines:NewMines flags:NewFlags map:State.map player:NewPlayerPos hp:SecondHp basePosition:State.basePosition mineCharge:State.mineCharge gunCharge:State.gunCharge hasFlag:HasFlag foods:NewFoods) ID)}
			{ControllerMemory mineExploded(Touched NewPlayerPos ID)}
			{SendToAll sayDamageTaken(ID 2 SecondHp)}
			{SendToAll sayMineExplode(mine(pos:NewPlayerPos))}
			{ForAll Touched proc {$ T} {SendToAll sayDamageTaken(T.id 1 T.state.hp)} end}
			DeadOnMine = SecondHp == 0
		else
			SecondHp = AfterFoodHp
			NewMines = State.mines
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
			New2MineCharge
			New2GunCharge
			PID Flag
			PID1 Flag1
			NewHasFlag
			NewHasFlag1
			New1Mines
			fun {IsOnFlag Flags Pos ID}
				case Flags of nil then false
				[] H|T then
					if H.color == ID.color then
						{IsOnFlag T Pos ID}
					elseif H.pos.x == Pos.x andthen H.pos.y == Pos.y then
						true
					else
						{IsOnFlag T Pos ID}
					end
				end
			end
		in
			{Send Port chargeItem(ID ItemKind)}
			if ItemKind == gun then
				NewGunCharge = State.gunCharge - 1
				NewMineCharge = State.mineCharge
				{ControllerMemory update(state(mines:NewMines flags:NewFlags map:State.map player:NewPlayerPos hp:SecondHp basePosition:State.basePosition mineCharge:NewMineCharge gunCharge:NewGunCharge hasFlag:HasFlag foods:NewFoods) ID)}
			elseif ItemKind == mine then
				NewGunCharge = State.gunCharge
				NewMineCharge = State.mineCharge - 1
				{ControllerMemory update(state(mines:NewMines flags:NewFlags map:State.map player:NewPlayerPos hp:SecondHp basePosition:State.basePosition mineCharge:NewMineCharge gunCharge:NewGunCharge hasFlag:HasFlag foods:NewFoods) ID)}
			else
				NewGunCharge = State.gunCharge
				NewMineCharge = State.mineCharge
			end
			{SendToAll sayCharge(ID ItemKind)}
			
			{Send Port fireItem(FireID FireItem)}
			case FireItem of null then skip
			[] gun(pos:Pos) then
				New1Mines = NewMines
				if NewGunCharge == 0 then
					Touched
				in
					{SendToAll sayShoot(ID Pos)}
					New2GunCharge = Input.gunCharge
					New2MineCharge = NewMineCharge
					{ControllerMemory update(state(mines:New1Mines flags:NewFlags map:State.map player:NewPlayerPos hp:SecondHp basePosition:State.basePosition mineCharge:New2MineCharge gunCharge:New2GunCharge hasFlag:HasFlag foods:NewFoods) ID)}
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
						{Send WindowPort removeMine(mine(pos:Pos))}
						{ControllerMemory mineExploded(TouchedPlayers Pos ID)}
						{SendToAll sayMineExplode(mine(pos:Pos))}
						{ForAll TouchedPlayers proc {$ T} {SendToAll sayDamageTaken(T.id 1 T.state.hp)} end}
					end
				end
			[] mine(pos:Pos) then
				if NewMineCharge == 0 andthen NewPlayerPos.x == Pos.x andthen NewPlayerPos.y == Pos.y then
					New1Mines = mine(pos:Pos)|NewMines
					New2GunCharge = NewGunCharge
					New2MineCharge = Input.mineCharge
					{ControllerMemory update(state(mines:New1Mines flags:NewFlags map:State.map player:NewPlayerPos hp:SecondHp basePosition:State.basePosition mineCharge:New2MineCharge gunCharge:New2GunCharge hasFlag:HasFlag foods:NewFoods) ID)}
					{SendToAll sayMinePlaced(ID mine(pos:Pos))}
					{ControllerMemory placeMine(ID Pos)}
				end
			else
				New2GunCharge = NewGunCharge
				New2MineCharge = NewMineCharge
			end
			if HasFlag == false andthen {IsOnFlag NewFlags NewPlayerPos ID} then
				{Send Port takeFlag(PID Flag)}
				case Flag of flag(pos:Pos color:Color) then
					if (Pos.x == NewPlayerPos.x andthen Pos.y == NewPlayerPos.y) then
						NewHasFlag = true
						{ControllerMemory update(state(mines:New1Mines flags:NewFlags map:State.map player:NewPlayerPos hp:SecondHp basePosition:State.basePosition mineCharge:New2MineCharge gunCharge:New2GunCharge hasFlag:NewHasFlag foods:NewFoods) ID)}
						{Send WindowPort removeFlag(flag(pos:Pos color:Color))}
						{SendToAll sayFlagTaken(PID Flag)}
					else
						NewHasFlag = HasFlag
					end
				else
					NewHasFlag = HasFlag
				end
			else
				NewHasFlag = HasFlag
			end

			if ActualValue == BaseValue andthen NewHasFlag == true then
				{Send Port dropFlag(PID1 Flag1)}
				case Flag1 of flag(pos:Pos color:Color) then
					{Send WindowPort putFlag(flag(pos:Pos color:Color))}
					{WinControl setWin}
				end
			end
		end
		
		% {System.show endOfLoop(ID)}
		{WinControl getWin(Win)}
		if Win == false then
			{SimulatedThinking}
			{ControllerMemory getIDState(NewState ID)}
			{Main Port ID NewState}
		end
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

	proc {SpawnFood Map}
		proc {GeneratePos}
			I = {RandomInRange 0 Input.nRow}
			J = {RandomInRange 0 Input.nColumn}
		in
			if {GetPoint Map I J} == 0 then
				{ControllerMemory addFood(I+1 J+1)}
				{Send WindowPort putFood(food(pos:pt(x:I+1 y:J+1)))}
				{SendToAll sayFoodAppeared(food(pos:pt(x:I+1 y:J+1)))}
			else
				{GeneratePos}
			end
		end
	in
		{Delay {RandomInRange Input.foodDelayMin Input.foodDelayMax}}
		{GeneratePos}
		{SpawnFood Map}
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
				{SpawnFood Input.map}
			end
			thread
				State = state(mines:nil flags:Input.flags map:Input.map player:Position hp:Input.startHealth basePosition:Position mineCharge:Input.mineCharge gunCharge:Input.gunCharge hasFlag:false foods:nil)
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

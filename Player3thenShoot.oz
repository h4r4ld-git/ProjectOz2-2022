functor
import
	Input
	OS
	System
export
	portPlayer:StartPlayer
define
	% Vars
	MapWidth = {List.length Input.map}
    MapHeight = {List.length Input.map.1}

	% Functions
	StartPlayer
	TreatStream
	MatchHead

	% Message functions
	InitPosition
	NewTurn
	Move
	IsDead
	AskHealth
	SayMoved
	SayMineExplode
	SayDeath
	SayDamageTaken
	SayFoodAppeared
	SayFoodEaten
	SayFlagTaken
	SayFlagDropped
	ChargeItem
	SayCharge
	FireItem
	SayMinePlaced
	SayShoot
	TakeFlag
	DropFlag

	% Helper functions
	StateUpdate
	MapCheck
	ListUpdate
	MapUpdate
	Abs
	ManhattanDistance
	RandChoice
    IsAlly
    MapUpdate
    ListUpdate
    NearbyGun
	RandomInRange = fun {$ Min Max} Min+({OS.rand}mod(Max-Min+1)) end
in
	fun {StartPlayer Color ID}
		Stream
		Port
	in
		{NewPort Stream Port}
		thread
			{TreatStream
			 	Stream
				state(
					id:id(name:basic color:Color id:ID)
					position:{List.nth Input.spawnPoints ID}
					map:Input.map
					hp:Input.startHealth
					flag:null
					mineReloads:0
					gunReloads:0
					startPosition:{List.nth Input.spawnPoints ID}
					% TODO You can add more elements if you need it
                    counter: 0
				)
			}
		end
		Port
	end

    proc{TreatStream Stream State}
        case Stream
            of H|T then {TreatStream T {MatchHead H State}}
        end
    end

	fun {MatchHead Head State}
        case Head 
            of initPosition(?ID ?Position) then {InitPosition State ID Position}
            [] move(?ID ?Position) then {Move State ID Position}
            [] sayMoved(ID Position) then {SayMoved State ID Position}
            [] sayMineExplode(Mine) then {SayMineExplode State Mine}
			[] sayFoodAppeared(Food) then {SayFoodAppeared State Food}
			[] sayFoodEaten(ID Food) then {SayFoodEaten State ID Food}
			[] chargeItem(?ID ?Kind) then {ChargeItem State ID Kind}
			[] sayCharge(ID Kind) then {SayCharge State ID Kind}
			[] fireItem(?ID ?Kind) then {FireItem State ID Kind}
			[] sayMinePlaced(ID Mine) then {SayMinePlaced State ID Mine}
			[] sayShoot(ID Position) then {SayShoot State ID Position}
            [] sayDeath(ID) then {SayDeath State ID}
            [] sayDamageTaken(ID Damage LifeLeft) then {SayDamageTaken State ID Damage LifeLeft}
			[] takeFlag(?ID ?Flag) then {TakeFlag State ID Flag}
			[] dropFlag(?ID ?Flag) then {DropFlag State ID Flag}
			[] sayFlagTaken(ID Flag) then {SayFlagTaken State ID Flag}
			[] sayFlagDropped(ID Flag) then {SayFlagDropped State ID flag}
			[] isDead(?Dead) then {IsDead Dead State}
			end
    end

	%%%% TODO Message functions
    %%% This player can only use weapon if his counter has a charge of 3, and the it reset.

	fun {IsDead ?Dead State}
		Dead = State.hp == 0
		State
	end
	
	fun {InitPosition State ?ID ?Position}
		ID = State.id
		Position = State.startPosition
		State
	end

	fun{StateUpdate Id Position Map Hp Flag MineReloads GunReloads StartPosition Counter}
		state(
			id:Id
			position:Position
			map:Map
			hp:Hp
			flag:Flag
			mineReloads:MineReloads
			gunReloads:GunReloads
			startPosition:StartPosition
            counter:Counter
		)
 	end

	fun {Move State ?ID ?Position}
		ID = State.id
		case State.position
		of pt(x:X y:Y)	then
			M HasMoved in
			M = {RandomInRange 0 3}
			case M
			of 3 then
				if Y+1 =< Input.nRow  
					then 
					Position = pt(x:X y:Y+1)

				elseif Y-1 > 0  
					then 
					Position = pt(x:X y:Y-1)

				elseif X-1 > 0  
					then 
					Position = pt(x:X-1 y:Y)

				elseif X+1 =< Input.nColumn  
					then 
					Position = pt(x:X+1 y:Y)
				else Position = State.position
				end

			[] 2 then 
				if Y-1 > 0  
					then 
					Position = pt(x:X y:Y-1)

				elseif X-1 > 0  
					then 
					Position = pt(x:X-1 y:Y)

				elseif X+1 =< Input.nColumn  
					then 
					Position = pt(x:X+1 y:Y)

				elseif Y+1 =< Input.nRow  
					then 
					Position = pt(x:X y:Y+1)
				else Position = State.position
				end

			[] 1 then
				if X-1 > 0  
					then 
					Position = pt(x:X-1 y:Y)

				elseif X+1 =< Input.nColumn  
					then 
					Position = pt(x:X+1 y:Y)

				elseif Y+1 =< Input.nRow  
					then 
					Position = pt(x:X y:Y+1)

				elseif Y-1 > 0  
					then 
					Position = pt(x:X y:Y-1)
				else Position = State.position
				end

			[] 0 then
				if X+1 =< Input.nColumn  
					then 
					Position = pt(x:X+1 y:Y)

				elseif Y+1 =< Input.nRow  
					then 
					Position = pt(x:X y:Y+1)

				elseif Y-1 > 0  
					then 
					Position = pt(x:X y:Y-1)

				elseif X-1 > 0  
					then 
					Position = pt(x:X-1 y:Y)
				else Position = State.position
				end

			end
		end
		State
	end

    fun {IsAlly Id MyId}
        if Id mod 2 == MyId mod 2 then true
        else false
        end
    end

    %when move, mark the old place by e if ennemy or a if ally
	fun {SayMoved State ID Position}
		if ID == State.id then
		{StateUpdate State.id Position State.map State.hp State.flag State.mineReloads State.gunReloads State.startPosition State.counter}
		else 
            if {IsAlly ID State.id} == true then
                {StateUpdate State.id State.position {MapUpdate State.map Position.x Position.y a nil} State.hp State.flag State.mineReloads State.gunReloads State.startPosition State.counter}
            end
            {StateUpdate State.id State.position {MapUpdate State.map Position.x Position.y e nil} State.hp State.flag State.mineReloads State.gunReloads State.startPosition State.counter}
		end
	end

	fun {SayMineExplode State Mine}
		if State.position.x == Mine.x andthen State.position.y == Mine.y then
			{StateUpdate State.id State.position State.map State.hp-2 State.flag State.mineReloads State.gunReloads State.startPosition State.counter}
		end
		State
	end

	fun {SayFoodAppeared State Food}
		if State.position.x == Food.x andthen State.position.y == Food.y then
			{StateUpdate State.id State.position {MapUpdate State.map Food.x Food.y f nil} State.hp State.flag State.mineReloads State.gunReloads State.startPosition State.counter}
		end
		State
	end

	fun {SayFoodEaten State ID Food}
		if State.position.x == Food.x andthen State.position.y == Food.y then
			{StateUpdate State.id State.position State.map State.hp+1 State.flag State.mineReloads State.gunReloads State.startPosition State.counter}
		end
		State
	end

	fun {ChargeItem State ?ID ?Kind} 
		ID = State.id
		Kind = null
		State
	end

	fun {SayCharge State ID Kind}
		if State.id == ID then
			case Kind
			of mine(x:X1 y:Y1) then
				{StateUpdate State.id State.position State.map State.hp State.flag State.mineReloads+1 State.gunReloads State.startPosition State.counter}
			[] gun(x:X2 y:Y2) then
				{StateUpdate State.id State.position State.map State.hp State.flag State.mineReloads State.gunReloads+1 State.startPosition State.counter}
			end
		end
		State
	end

	fun {Abs X}
		if X < 0 then ~x
		else X
		end
	end

	fun{ManhattanDistance Pos1 Pos2}
    	{Abs Pos1.x - Pos2.x} + {Abs Pos1.y - Pos2.y}
  	end

	fun {RandChoice Lst Len}
		M in
		M = {RandomInRange 1 Len}
		{List.nth Lst M}
	end

	fun {ListUpdate Lst Idx Val Acc}
		case Lst
		of nil then Acc
		[] H|T then
			if Idx == 0 then {ListUpdate nil Idx-1 Val {List.append {List.reverse Val|Acc} T}}
			elseif Idx > 0 then {ListUpdate T Idx-1 Val H|Acc}
			end
		end
	end

	fun {MapUpdate Map X Y Type Acc}
		A B C in
		A = {List.nth Map Y}
		B = {ListUpdate A X+1 Type nil}
		C = {ListUpdate Map Y+1 B nil}
		C
	end

	%fun {NearbyGun Pos Map}
	%	for X in [pt(x: Pos.x+1 y: Pos.y) pt(x: Pos.x-1 y: Pos.y) pt(x: Pos.x y: Pos.y+1) pt(x: Pos.x y: Pos.y-1) pt(x: Pos.x y: Pos.y-2) pt(x: Pos.x y: Pos.y+2) pt(x: Pos.x+2 y: Pos.y) pt(x: Pos.x-2 y: Pos.y)] do
	%		if {List.nth {List.nth Map X.y} X.x} == e then
	%			if X.x =< nColumn andthen X.y =< nRow  andthen X.x>0 andthen X.y>0 then
	%				X
	%			end
	%		end
	%	end
	%	0
	%end

	%Shoot If someone is nearby
	fun {FireItem State ?ID ?Kind}
	%	ID = State.id
    %   if State.counter == 3 then
    %        if State.gunReloads > 0 then
    %           C in
    %            C = {NearbyGun State.position State.map}
    %           if C \= 0 then
    %                Kind = gun(C)
    %            end
    %        elseif State.mineReloads > 0 then
    %            Kind = mine(State.position)
    %        end
    %        {StateUpdate State.id State.position State.map State.hp State.flag State.mineReloads State.gunReloads State.startPosition 0}
    %    end
		State
	end

	fun {SayMinePlaced State ID Mine}
		if State.position.x == Mine.x andthen State.position.y == Mine.y then
			{StateUpdate State.id State.position {MapUpdate State.map Mine.x Mine.y m nil} State.hp State.flag State.mineReloads State.gunReloads State.startPosition State.counter}
		end
		State
	end

	fun {SayShoot State ID Position}
		if State.position.x == Position.x andthen State.position.y == Position.y then
			{StateUpdate State.id State.position State.map State.hp-1 State.flag State.mineReloads State.gunReloads State.startPosition State.counter}
		end
		State
	end

	fun {SayDeath State ID}
		State
	end

	fun {SayDamageTaken State ID Damage LifeLeft}
		if State.id ==ID then
			{StateUpdate State.id State.position State.map State.hp-Damage State.flag State.mineReloads State.gunReloads State.startPosition State.counter}
		end
		State
    end

	%always take the flag
	fun {TakeFlag State ?ID ?Flag}
		ID = State.id
		Flag = flag(pos:State.position color:State.id.color)
		State
	end
			
	%drop when at his spawnpoint
	fun {DropFlag State ?ID ?Flag}
		ID = State.id
		if State.position == {List.nth Input.spawnPoints ID} then
			Flag = null
		end
		State
	end

	fun {SayFlagTaken State ID Flag}
		if State.id == ID then {StateUpdate State.id State.position State.map State.hp Flag State.mineReloads State.gunReloads State.startPosition State.counter}
		else State
		end
	end

	fun {SayFlagDropped State ID Flag}
		if State.id == ID then {StateUpdate State.id State.position State.map State.hp Flag State.mineReloads State.gunReloads State.startPosition State.counter}
		else State
		end	
	end
end

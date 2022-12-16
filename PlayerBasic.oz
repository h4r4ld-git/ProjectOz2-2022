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
			[] takeFlag(?ID ?Flag Color) then {TakeFlag State ID Flag Color}
			[] dropFlag(?ID ?Flag) then {DropFlag State ID Flag}
			[] sayFlagTaken(ID Flag) then {SayFlagTaken State ID Flag}
			[] sayFlagDropped(ID Flag) then {SayFlagDropped State ID flag}
			[] isDead(?Dead) then {IsDead Dead State}
			end
    end

	%%%% TODO Message functions

	fun {IsDead ?Dead State}
		if State.hp == 0 then
			Dead = true
		else
			Dead = false
		end
		State
	end
	
	fun {InitPosition State ?ID ?Position}
		ID = State.id
		Position = State.startPosition
		State
	end

	fun{StateUpdate Id Position Map Hp Flag MineReloads GunReloads StartPosition}
		state(
			id:Id
			position:Position
			map:Map
			hp:Hp
			flag:Flag
			mineReloads:MineReloads
			gunReloads:GunReloads
			startPosition:StartPosition
		)
 	end

	%%% Pour controller
	fun {MapCheck State Pos}
		case Pos
		of pt(x:X y:Y) then
			if {List.nth {List.nth State.map Y} X} == 0 then true
			else falSse
			end
		end
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
		B = {ListUpdate A X+1 1 nil}
		C = {ListUpdate Map Y+1 B nil}
		C
	end
	%%%

	fun {Move State ?ID ?Position}
		ID = State.id
		%first up if not, right if not, down, if not left
		%SpawnPoints = [pt(x:1 y:1) pt(x:12 y:10) pt(x:1 y:2) pt(x:12 y:11) pt(x:1 y:3) pt(x:12 y:12)]
		case State.position
		of pt(x:X y:Y)	then
			M HasMoved in
			M = {OS.rand} mod 4
			case M
			of 3 then
				if Y+1 < Input.nRow andthen 
					{MapCheck State pt(x:X y:Y+1)} == true
					then 
					Position = pt(x:X y:Y+1)

				elseif Y-1 > 0 andthen 
					{MapCheck State pt(x:X y:Y-1)} == true
					then 
					Position = pt(x:X y:Y-1)

				elseif X-1 > 0 andthen 
					{MapCheck State pt(x:X-1 y:Y)} == true
					then 
					Position = pt(x:X-1 y:Y)

				elseif X+1 < Input.nColumn andthen 
					{MapCheck State pt(x:X+1 y:Y)} == true
					then 
					Position = pt(x:X+1 y:Y)
				else Position = State.position
				end

			[] 2 then 
				if Y-1 > 0 andthen 
					{MapCheck State pt(x:X y:Y-1)} == true
					then 
					Position = pt(x:X y:Y-1)

				elseif X-1 > 0 andthen 
					{MapCheck State pt(x:X-1 y:Y)} == true
					then 
					Position = pt(x:X-1 y:Y)

				elseif X+1 < Input.nColumn andthen 
					{MapCheck State pt(x:X+1 y:Y)} == true
					then 
					Position = pt(x:X+1 y:Y)

				elseif Y+1 < Input.nRow andthen 
					{MapCheck State pt(x:X y:Y+1)} == true
					then 
					Position = pt(x:X y:Y+1)
				else Position = State.position
				end

			[] 1 then
				if X-1 > 0 andthen 
					{MapCheck State pt(x:X-1 y:Y)} == true
					then 
					Position = pt(x:X-1 y:Y)

				elseif X+1 < Input.nColumn andthen 
					{MapCheck State pt(x:X+1 y:Y)} == true
					then 
					Position = pt(x:X+1 y:Y)

				elseif Y+1 < Input.nRow andthen 
					{MapCheck State pt(x:X y:Y+1)} == true
					then 
					Position = pt(x:X y:Y+1)

				elseif Y-1 > 0 andthen 
					{MapCheck State pt(x:X y:Y-1)} == true
					then 
					Position = pt(x:X y:Y-1)
				else Position = State.position
				end

			[] 0 then
				if X+1 < Input.nColumn andthen 
					{MapCheck State pt(x:X+1 y:Y)} == true
					then 
					Position = pt(x:X+1 y:Y)

				elseif Y+1 < Input.nRow andthen 
					{MapCheck State pt(x:X y:Y+1)} == true
					then 
					Position = pt(x:X y:Y+1)

				elseif Y-1 > 0 andthen 
					{MapCheck State pt(x:X y:Y-1)} == true
					then 
					Position = pt(x:X y:Y-1)

				elseif X-1 > 0 andthen 
					{MapCheck State pt(x:X-1 y:Y)} == true
					then 
					Position = pt(x:X-1 y:Y)
				else Position = State.position
				end

			end
		end

		{StateUpdate State.id Position State.map State.hp State.flag State.mineReloads State.gunReloads State.startPosition}

	end

	fun {SayMoved State ID Position}
		if ID == State.id then
		{StateUpdate State.id Position State.map State.hp State.flag State.mineReloads State.gunReloads State.startPosition}
		end
	end

	fun {SayMineExplode State Mine}
		State
	end

	fun {SayFoodAppeared State Food}
		State
	end

	fun {SayFoodEaten State ID Food}
		State
	end

	fun {ChargeItem State ?ID ?Kind} 
		ID = State.id
		Kind = null
		State
	end

	fun {SayCharge State ID Kind}
		State
	end

	%Shoot as soon the player have ammo, if not then mine if not then nothing
	fun {FireItem State ?ID ?Kind}
		ID = State.id
		Kind = null
		if State.gunReloads > 0 then
			Kind = gun
		elseif State.mineReloads > 0 then
			Kind = mine
		end
		State
	end

	fun {SayMinePlaced State ID Mine}
		State
	end

	fun {SayShoot State ID Position}
		State
	end

	fun {SayDeath State ID}
		State
	end

	fun {SayDamageTaken State ID Damage LifeLeft}
		State
    end

		%always take the flag
	fun {TakeFlag State ?ID ?Flag Color}
		ID = State.id
		Flag = flag(pos:State.position color:Color)
		{StateUpdate State.id State.position State.map State.hp Flag State.mineReloads State.gunReloads State.startPosition}

	end
			
	%drop when at his spawnpoint
	fun {DropFlag State ?ID ?Flag}
		ID = State.id
		if State.position == {List.nth Input.spawnPoints ID} then
			Flag = null
		end
		{StateUpdate State.id State.position State.map State.hp Flag State.mineReloads State.gunReloads State.startPosition}
	end

	fun {SayFlagTaken State ID Flag}
		State
	end

	fun {SayFlagDropped State ID Flag}
		State
	end
end

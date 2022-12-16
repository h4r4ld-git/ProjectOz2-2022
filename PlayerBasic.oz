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
			[] takeFlag(?ID ?Flag) then {TakeFlag State ID Flag}
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
	
	fun {Move State ?ID ?Position}
		ID = State.id
		%first up if not, right if not, down, if not left
		%SpawnPoints = [pt(x:1 y:1) pt(x:12 y:10) pt(x:1 y:2) pt(x:12 y:11) pt(x:1 y:3) pt(x:12 y:12)]
		case State.position
		of pt(x:X y:Y)then 
				if Y+1 < 13 then Position = pt(x:X y:Y+1)
				elseif X-1 > 0 then Position = pt(x:X-1 y:Y)
				elseif Y-1 > 0 then Position = pt(x:X y:Y-1)
				elseif X+1 < 13 then Position = pt(x:X+1 y:Y)

				end
		end
		
		{StateUpdate State.id Position State.map State.hp State.flag State.mineReloads State.gunReloads State.startPosition}
	end

	fun {SayMoved State ID Position}
		State
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

	fun {FireItem State ?ID ?Kind}
		ID = State.id
		Kind = null
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

	fun {TakeFlag State ?ID ?Flag}
		ID = State.id
		Flag = null
		State
	end
			
	fun {DropFlag State ?ID ?Flag}
		ID = State.id
		Flag = null
		State
	end

	fun {SayFlagTaken State ID Flag}
		State
	end

	fun {SayFlagDropped State ID Flag}
		State
	end
end

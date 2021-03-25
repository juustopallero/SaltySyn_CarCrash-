-- this script is presented by https://forum.cfx.re/u/saltygrandpa/summary all core functions were created by aswell; for the free use of the CFX community. 
-- edits and polish made by Entarukun for vehicle effects and limited function trigger parameters. 
-- duely dubbed SaltySyn_Carcrash
-- No need to modify any of this, but I tried to document what it's doing
local isBlackedOut = false
local isLimp = false
local isConcussed = false
--[[ local careffects = false ]]
local oldBodyDamage = 0
local oldSpeed = 0


local tireBurstMaxNumber = Config.randomTireBurstInterval * 1200; 												-- the tire burst lottery runs roughly 1200 times per minute
if Config.randomTireBurstInterval ~= 0 then tireBurstLuckyNumber = math.random(tireBurstMaxNumber) end		



local function blackout()
	-- Only blackout once to prevent an extended blackout if both speed and damage thresholds were met
	if not isBlackedOut then
		isBlackedOut = true
		-- This thread will black out the user's screen for the specified time
		Citizen.CreateThread(function()
			DoScreenFadeOut(250)
			while not IsScreenFadedOut() do
				Citizen.Wait(0)
			end
			Citizen.Wait(Config.BlackoutTime)
			DoScreenFadeIn(250)
			isBlackedOut = false
		
		end)
	else 

		--[[ print("alreadyblacketout") ]]
	end
end
local function concussed()
	-- Only blackout once to prevent an extended blackout if both speed and damage thresholds were met
	if not isconcussed then
		isconcussed = true
		-- This thread will black out the user's screen for the specified time
		Citizen.CreateThread(function()
			PlaySoundFrontend(-1, "SCREEN_FLASH", "CELEBRATION_SOUNDSET", 1)  -- check natives for alternate sound bites, additionally other effects can be triggered here
			--[[ SetCamEffect(2) ]]
			--[[ SetPedMovementClipset(PlayerPedId(),"move_injured_generic",1.0)  ]]
			Citizen.Wait(1)
			--[[ SetCamEffect(0) ]]
			isconcussed = false
			
		end)
	end
end

local function CarEffects()
	-- Only blackout once to prevent an extended blackout if both speed and damage thresholds were met
	if isBlackedOut and Config.EnableVehicleCrashEffects then

		if not careffects then
			careffects = true
			-- Borrowed controls from https://github.com/Sighmir/FiveM-Scripts/blob/master/vrp/vrp_hotkeys/client.lua
			--[[ DisableControlAction(0,71,true) -- veh forward
			DisableControlAction(0,72,true) -- veh backwards
			DisableControlAction(0,63,true) -- veh turn left
			DisableControlAction(0,64,true) -- veh turn right
			DisableControlAction(0,75,true) -- disable exit vehicle ]]
			Citizen.CreateThread(function()
			local vehicle = GetVehiclePedIsIn(PlayerPedId(-1), false)
			local tyre = math.random(0, 20) -- created ranom chance for tires to pop, it is not 1-20, tires pop on individual triggers ,0,1,2,3,4,5,6 etc depending on model vehicle. 
			local tankdamage = (math.random(100, 200)  + (oldSpeed * 1.5))-- applies damage to gas tank on crash, leaking tank will eventually run out of fuel. 
			local enginedamage = (math.random(150, 300) + (oldSpeed * 2)) 
			local vehiclebodydamage = math.random(150, 300)
			
			--[[ local tempincrease = math.random(10, 50) 
			local oillevel = math.random(20,40)  ]]
			--[[ local oilmax = GetVehicleOilLevel(vehicle) unbracket to print oil level 
			local temp = GetVehicleEngineTemperature(vehicle) unbracket to engine temp ]]
			--[[ SetVehiclePetrolTankHealth(vehicle, -300) ]] -- -400 is max
			SetVehiclePetrolTankHealth(vehicle,GetVehiclePetrolTankHealth(vehicle) - tankdamage )
			SetVehicleTyreBurst(vehicle,tyre, 0 , 80.0)
			SetVehicleEngineHealth(vehicle ,GetVehicleEngineHealth(vehicle) - enginedamage)
			SetVehicleBodyHealth(vehicle, GetVehicleBodyHealth(vehicle) - vehiclebodydamage) 
			SetVehicleOilLevel(vehicle, GetVehicleOilLevel(vehicle) + 5.0 ) -- max is 15?
			SetVehicleEngineTemperature(vehicle, GetVehicleEngineTemperature(vehicle) + 25.0 ) -- between 1-100
			SetVehicleDirtLevel(vehicle, GetVehicleDirtLevel(vehicle) + 5.0  ) -- no value greater than 15.0 
			--[[ print(temp)
			print(oilmax)
			print("veheffect") ]]
			
			Citizen.Wait(3000) 
			careffects = false
			end)
		end 
	end
end





local function tireBurstLottery()
	local tireBurstNumber = math.random(tireBurstMaxNumber)
	if tireBurstNumber == tireBurstLuckyNumber then
		-- We won the lottery, lets burst a tire.
		if GetVehicleTyresCanBurst(vehicle) == false then return end
		local numWheels = GetVehicleNumberOfWheels(vehicle)
		local affectedTire
		if numWheels == 2 then
			affectedTire = (math.random(2)-1)*4		-- wheel 0 or 4
		elseif numWheels == 4 then
			affectedTire = (math.random(4)-1)
			if affectedTire > 1 then affectedTire = affectedTire + 2 end	-- 0, 1, 4, 5
		elseif numWheels == 6 then
			affectedTire = (math.random(6)-1)
		else
			affectedTire = 0
		end
		SetVehicleTyreBurst(vehicle, affectedTire, false, 1000.0)
		tireBurstLuckyNumber = math.random(tireBurstMaxNumber)			-- Select a new number to hit, just in case some numbers occur more often than others
	print("tireloteryworking")
	end
end


local function isPedDrivingAVehicle()
	local ped = GetPlayerPed(-1)
	vehicle = GetVehiclePedIsIn(ped, false)
	if IsPedInAnyVehicle(ped, false) then
		-- Check if ped is in driver seat
		if GetPedInVehicleSeat(vehicle, -1) == ped then
			local class = GetVehicleClass(vehicle)
			-- We don't want planes, helicopters, bicycles and trains
			if class ~= 15 and class ~= 16 and class ~=21 and class ~=13 then
				return true
			end
		end
	end
	return false
end



Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)
		-- Get the vehicle the player is in, and continue if it exists
		local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
		if DoesEntityExist(vehicle) then
			-- Check if damage blackout is enabled
			if Config.BlackoutFromDamage then
				local currentDamage = GetVehicleBodyHealth(vehicle)
				-- If the damage changed, see if it went over the threshold and blackout if necesary
				if currentDamage ~= oldBodyDamage then
					if not isBlackedOut and (currentDamage < oldBodyDamage) and ((oldBodyDamage - currentDamage) >= Config.BlackoutDamageRequired) then
					
					if HasEntityBeenDamagedByWeapon(vehicle, 0, 2) then -- prevents blackout from damage triggering on bullet damage or while on fire.
							--[[ print("bulletdamage") ]]
					elseif IsEntityOnFire(vehicle) then 
							--[[ print("caronfire")  ]]
						else 

						blackout()
						concussed()
						CarEffects()
							if Config.DamagePedOnCrash then
							local ped = GetPlayerPed(-1)
							ApplyDamageToPed(ped, Config.PedCrashDamage, true) 
							--[[ print("pedamagesbydamage")  ]]
							end 
						end 
					end
					oldBodyDamage = currentDamage
				end
			end
			
			-- Check if speed blackout is enabled
			if Config.BlackoutFromSpeed then
				local currentSpeed = GetEntitySpeed(vehicle) * 2.23
				-- If the speed changed, see if it went over the threshold and blackout if necesary
				if currentSpeed ~= oldSpeed then
					if not isBlackedOut and (currentSpeed < oldSpeed) and ((oldSpeed - currentSpeed) >= Config.BlackoutSpeedRequired) then
						blackout()
						concussed()
						CarEffects()
						if Config.DamagePedOnCrash then
						local ped = GetPlayerPed(-1)
						ApplyDamageToPed(ped, Config.PedCrashDamage, true) 
						--[[ print("pedamagesbyispeed")   ]]
						end 
					end
					oldSpeed = currentSpeed
				end
			end
		else
			oldBodyDamage = 0
			oldSpeed = 0
		end
	end
end)



Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)
		-- stop car from exploding 50 percent of the time is onfire
		local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
		if DoesEntityExist(vehicle) then
			-- Check if damage blackout is enabled
			local cancelfire = math.random(0, 20) 

			if IsEntityOnFire(vehicle) then 
				--[[ Citizen.Wait(1500) ]]
				if cancelfire < 11 then 
					SetDisableVehiclePetrolTankFires(vehicle, false )
					--[[ SetDisableVehicleEngineFires(vehicle, false ) ]]
					print("canfire")
				else 
					Wait(3000)
					SetDisableVehiclePetrolTankFires(vehicle, true )
					StopEntityFire(vehicle)
					print("cantfire")
				end 
				Citizen.Wait(15000)

			else 
		
			end 
		else
			
		end
	end
end)



Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)
		-- stop car from exploding 50 percent of the time is onfire
		local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
		if isPedDrivingAVehicle() then
			if Config.randomTireBurstInterval ~= 0 and GetEntitySpeed(vehicle) > 10 then 
				tireBurstLottery() 
			end -- added from realistic failure
		end 
			


	end
end)

		

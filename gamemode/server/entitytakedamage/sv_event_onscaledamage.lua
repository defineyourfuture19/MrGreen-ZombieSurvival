-- � Limetric Studios ( www.limetricstudios.com ) -- All rights reserved.
-- See LICENSE.txt for license information

BONUS_RESISTANCE = false

-- Scales player damage (called before others)
local function ScalePlayerDamage(pl, attacker, inflictor, dmginfo )
	--Player not ready

	
	if not pl.Ready then
		dmginfo:SetDamage(0)
		return true
	--Check for friendly fire
	elseif dmginfo:IsPlayerFriendlyFire(pl) then
		dmginfo:SetDamage(0)
		return true	
	--Scale drown damage
	elseif dmginfo:IsDrownDamage() then
		pl.dmgNextDrown = pl.dmgNextDrown or 0

		if pl.dmgNextDrown > CurTime() then 
			dmginfo:SetDamage( 0 )
		else
			--10 damage per second
			dmginfo:SetDamage(pl:GetMaximumHealth() * 0.05)
			pl.dmgNextDrown = CurTime() + 0.5
		end

		return true
	end
	--Physbox team-damage bug
	if dmginfo:IsAttackerPhysbox() then
		local mPhysAttacker = dmginfo:GetAttacker():GetPhysicsAttacker()
		if IsEntityValid(mPhysAttacker) and mPhysAttacker:IsPlayer() then
			-- Set attacker
			dmginfo:SetAttacker(mPhysAttacker)
			attacker = mPhysAttacker
		end
	end

	--Make humans invulnerable for AR2 grenades (used by the grenade launcher)
	if ((attacker:GetClass() == "grenade_ar2" or attacker:GetClass() == "weapon_zs_grenadelauncher") and pl:IsHuman()) then
		dmginfo:SetDamage(0)
		return true
	--Scale down own AR2 grenades (grenade launcher) shots
	elseif (attacker:GetClass() == "player" and pl:IsHuman() and attacker:IsHuman()) then
		if pl:GetPerk("_blast") then
			dmginfo:ScaleDamage(0.2)	
		else
			dmginfo:ScaleDamage(0.9)
		end
	--Scale down explosion damage if it's the owner
	elseif (attacker:GetClass() == "env_explosion" and pl:IsHuman() and pl == attacker:GetOwner()) then
		if pl:GetPerk("engineer_blastproof") then
			dmginfo:ScaleDamage(0.2)	
		else
			dmginfo:ScaleDamage(0.9)
		end
	--Turret damage
	elseif attacker:GetClass() == "zs_turret" then
		if pl:IsHuman() then
			if pl == attacker:GetTurretOwner() then
				dmginfo:SetDamage(attacker.Damage/2)
			else
				dmginfo:SetDamage(0)
			end
		elseif pl:IsZombie() then
			dmginfo:SetDamage(attacker.Damage)
		end

		return true
	elseif attacker:GetClass() == "zs_miniturret" then
		if pl:IsHuman() then
			dmginfo:SetDamage(0)
		elseif pl:IsZombie() then
			dmginfo:SetDamage(attacker.Damage)
		end

		return true
	end
	
	--Self-inflicted phys damage
	if dmginfo:IsPhysHurtingSelf(pl) then
		dmginfo:SetDamage(0)
		return true
	end

	--remove unnesessary damage
	if dmginfo:IsPhysDamage() and not dmginfo:IsAttackerPlayer() and not dmginfo:IsInflictorPlayer() and dmginfo:GetAttacker().IsObjEntity then
		dmginfo:SetDamage(0)
		return true
	end

	-- No phys damage between humans and zombies
	if dmginfo:IsAttackerHuman() and pl:IsZombie() and dmginfo:IsPhysDamage() then
		dmginfo:SetDamage(0)
		return true
	end
	
	--Check for explosion damage immunity
	if dmginfo:IsExplosionDamage() and pl.NoExplosiveDamage and pl.NoExplosiveDamage >= CurTime() then
		dmginfo:ScaleDamage(0.5)
	end
		
	--[[	
	--Zombies with howler protection
	if dmginfo:IsAttackerHuman() and pl:IsZombie() and dmginfo:IsBulletDamage() and pl:HasHowlerProtection() then
		if math.random(3) == 3 then
			--Play metal sound
			sound.Play("physics/metal/metal_box_impact_bullet".. math.random(1, 3) ..".wav", pl:GetPos() + Vector(0, 0, 30), 80, math.random(90, 110))
				
			--Show spark effect
			local Spark = EffectData()
			Spark:SetOrigin(dmginfo:GetDamagePosition())
			Spark:SetMagnitude(50)
			Spark:SetNormal(-1 * ( dmginfo:GetDamagePosition() - dmginfo:GetAttacker():GetPos() ):GetNormal())
			util.Effect("MetalSpark", Spark, nil, true)
		end
			
		dmginfo:SetDamage(0)
		return true
	end

	]]--
	
	if pl:IsZombie() then
		--Scale any damage
		dmginfo:ScaleDamage(GAMEMODE:GetUndeadDamageMultiplier())
		--Scale headshot damage
		if (dmginfo:IsBulletDamage() or dmginfo:IsMeleeDamage()) and pl:GetAttachment(1) then 
			if (dmginfo:GetDamagePosition():Distance(pl:GetAttachment(1).Pos)) < 16 then
				if (math.random(1,3) == 1) then
					pl:EmitSound(Sound("player/headshot".. math.random(1, 2) ..".wav"),60,math.random(90,110))
				end			
				if dmginfo:IsBulletDamage() and attacker:GetPerk ("Sharpshooter") then
					if attacker:GetPerk("sharpshooter_friction") and math.random(1,4) == 1 then
						pl:TakeDamageOverTime(7, 1, 4, attacker, inflictor )
						pl:Ignite(4,0)			
					end
					if attacker.DataTable["ShopItems"][69] then
						dmginfo:SetDamage((dmginfo:GetDamage() * (1.13 + (1*attacker:GetRank())/100)))				
					else
						dmginfo:SetDamage((dmginfo:GetDamage() * (1.08 + (1*attacker:GetRank())/100)))
					end
				elseif dmginfo:IsMeleeDamage() and attacker:GetPerk("berserker_headhunter") then
					pl:Daze(1)
					dmginfo:SetDamage(dmginfo:GetDamage() * 1.40)						
				elseif dmginfo:IsMeleeDamage() then
					dmginfo:SetDamage(dmginfo:GetDamage() * 1.15)			
				end
			end
		end
		


		--35% damage for zombine (armor)
		if pl:IsZombine() and pl:Health() <= 175 and pl:Health() ~= 0 and pl.bCanSprint == false then
			pl.bCanSprint = true
			pl:SendLua("WraithScream()")
			pl:EmitSound(Sound("npc/zombine/zombine_charge"..math.random ( 1,2 )..".wav"))
		end


		--One boss
		--[[if dmginfo:IsBulletDamage() and (pl:GetZombieClass() == 11 or pl:GetZombieClass() == 18) and (dmginfo:GetDamagePosition():Distance( pl:GetAttachment(pl:LookupAttachment("head")).Pos )) > 6.5 and math.random(5) == 5 then
			sound.Play( "weapons/fx/rics/ric"..math.random(1,5)..".wav", pl:GetPos() + Vector( 0,0,30 ), 80, math.random( 90, 110 ) )

			local Spark = EffectData()
			Spark:SetOrigin( dmginfo:GetDamagePosition() )
			Spark:SetMagnitude( 50 )
			Spark:SetNormal( -1 * ( dmginfo:GetDamagePosition() - dmginfo:GetAttacker():GetPos() ):GetNormal()  )
			util.Effect( "MetalSpark", Spark, true, true )

			dmginfo:ScaleDamage(0.07)
		end]]
	end
	
	
	

	-- Clamp phys damage
	if pl:IsPlayer() and dmginfo:GetAttacker():IsPlayer() and pl:Team() ~= dmginfo:GetAttacker():Team() then
		local Inflictor = dmginfo:GetInflictor()
		if Inflictor:GetClass() == "prop_physics" or Inflictor:GetClass() == "prop_physics_multiplayer" or Inflictor:GetClass() == "func_physbox" or Inflictor:GetClass() == "func_physbox_multiplayer" then-- if string.find ( Inflictor:GetClass(), "prop_physics" ) or string.find ( Inflictor:GetClass(), "physbox" ) then
			local MaximumVictimHealth = pl:GetMaximumHealth()
			local InitialDamage, NewDamage, Percentage = dmginfo:GetDamage(), dmginfo:GetDamage(), 0.35
			-- Phys damage cooldown -- so we don't hit it with great damage 2 times in one frame
			if pl.PhysCooldownDamage == nil then
				pl.PhysCooldownDamage = 0 
			end

			if pl.PhysCooldownDamage > CurTime() then
				return 0
			end
				
			if InitialDamage >= MaximumVictimHealth * Percentage then
				NewDamage = MaximumVictimHealth * Percentage
			end
				
			if InitialDamage < MaximumVictimHealth * Percentage then
				NewDamage = MaximumVictimHealth * Percentage
			end
				
			-- Next damage in the next frame
			pl.PhysCooldownDamage = CurTime() + 0.05
					
			-- Apply damage
			if (pl:GetPerk("medic_battlemedic")) then
				NewDamage = NewDamage * 0.7
			end
			
			local vel = pl:GetPos()
			vel.z = vel.z + 32
			util.Blood(vel, math.Rand(NewDamage * 0.1, NewDamage * 0.2), vel:GetNormal(), math.Rand(NewDamage * 0.4, NewDamage), true)

			dmginfo:SetDamage(NewDamage)
				
			local phys = Inflictor:GetPhysicsObject()

			--[[if phys:IsValid() and pl:Alive() and phys:GetVelocity():Length() > 180 then
						if pl:GetPerk("_falldown") then
					return
				else
				pl:GiveStatus("knockdown",1)
				end]]--
			--end
		end
	end
	
	--Zombies with howler prot have reduced damage by 80%
	
	--[[
	if dmginfo:IsAttackerZombie() and pl:IsHuman() then
		if dmginfo:GetAttacker():HasHowlerProtection() then
			dmginfo:SetDamage( dmginfo:GetDamage() * 0.2 )
		end

		local effectdata = EffectData()
		effectdata:SetEntity(pl)
		effectdata:SetOrigin(dmginfo:GetDamagePosition())
		effectdata:SetMagnitude(5)
		effectdata:SetScale(0)
		util.Effect("bloodstream", effectdata, nil, true)
	end
	]]--
	
	--Normal enraged zombies
	--[[
	if dmginfo:IsAttackerHuman() and pl:IsZombie() and pl:IsZombieInRage() and dmginfo:IsBulletDamage() then
		-- Sometimes play metal sound, sometimes flesh ...
		local iRandom, fSound = math.random( 1, 2 ), "physics/flesh/flesh_impact_bullet"..math.random(1, 4)..".wav"
			
		-- Metal sound
		if iRandom == 1 then
			fSound = "physics/metal/metal_box_impact_bullet"..math.random(1, 3)..".wav"
			sound.Play(fSound, pl:GetPos() + Vector( 0,0,30 ), 80, math.random(90, 110))
		end
			
		-- Show spark effect
		if iRandom == 1 then
			local Spark = EffectData()
			Spark:SetOrigin( dmginfo:GetDamagePosition() )
			Spark:SetMagnitude( 50 )
			Spark:SetNormal( -1 * ( dmginfo:GetDamagePosition() - dmginfo:GetAttacker():GetPos() ):GetNormal()  )
			util.Effect( "MetalSpark", Spark, nil, true )
		end
			
		-- Reduce damage by 100% on random chance, else only 50%
		if iRandom == 1 then
			dmginfo:SetDamage(0)
			return true
		else
			dmginfo:SetDamage(dmginfo:GetDamage() * 0.5)
		end
	end
	]]--

	--Reduce damage when SkillShop is open
	if pl:IsHuman() and pl.IsSkillShopOpen then
		dmginfo:SetDamage(dmginfo:GetDamage() * 0.1)
	end
	
	--Identify our last attacker and inflictor
	pl:InsertLastDamage(dmginfo:GetPlayerAttacker(), dmginfo:GetInflictor())
end

hook.Add("ScalePlayersDamage", "ScalePlayersDamage", ScalePlayerDamage)
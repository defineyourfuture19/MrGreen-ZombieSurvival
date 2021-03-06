AddCSLuaFile()

ENT.Type 			= "anim"
ENT.PrintName		= ""
ENT.Author			= "NECROSSIN"
ENT.Purpose			= ""
ENT.AmmoDelay = 90
ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

util.PrecacheSound("items/ammo_pickup.wav")

function ENT:SetupDataTables()
	self:NetworkVar("Entity", 0, "Placer")
	self:NetworkVar("Bool", 0, "Claimed")
end

util.PrecacheModel("models/items/ammocrate_smg1.mdl")
function ENT:Initialize()
	if SERVER then	
		self:DrawShadow(false)
		self.Entity:SetModel("models/items/ammocrate_smg1.mdl")
		self.Entity:PhysicsInit(SOLID_VPHYSICS)
		self.Entity:SetMoveType(MOVETYPE_VPHYSICS)
		self.Entity:SetSolid(SOLID_VPHYSICS)	
		self.Entity:SetCollisionGroup(SOLID_VPHYSICS)

		local phys = self.Entity:GetPhysicsObject()
		if IsValid(phys) then
			phys:Wake()
			phys:EnableMotion(false) 
		end
	
		self.CrateHealth = 200
		self.CrateMaxHealth = 200
	end
	
	if self:GetPlacer() != nil and self:GetPlacer():GetPerk("support_medical") then	
		self.Entity:SetColor( Color( 0, 200, 200, 255 ) )
	end
			

	--Unclaimed by default
	self:SetClaimed(false)

	if CLIENT then
		hook.Add("PreDrawHalos", "CustDrawHalosAmmo".. tostring(self), function()
			if not util.tobool(GetConVarNumber("zs_drawcrateoutline")) then
				return
			end
			
			if not IsValid(MySelf) or MySelf:Team() ~= TEAM_HUMAN or not MySelf:Alive() then
				return
			end
			
			halo.Add({self}, self.LineColor, 1, 1, 1, true, false)
		end)
	end
end

function ENT:Think()
	--TODO: Rework this code to make it unneeded
	local ct = CurTime()
	
	local humans = team.GetPlayers(TEAM_HUMAN)
	
	--Loop though all players
	for _, pl in ipairs(humans) do
		-- check if player got ammo
		if pl.GotMobileSupplies == nil then -- whatever
			pl.GotMobileSupplies = false
			pl.MobileSupplyTime = ct + 0 -- make a timer for him
			pl.MobileSupplyTimerActive = true
		end

		if pl.MobileSupplyTimerActive == true then
			if pl.MobileSupplyTime <= ct then
				pl.MobileSupplyTimerActive = false
				pl.GotMobileSupplies = false
			end
		end		
	end

	self:NextThink(ct+1)
	if CLIENT then
		self:SetNextClientThink(ct+1)
	end
	return true
end

if SERVER then
	function ENT:OnTakeDamage( dmginfo )
		if dmginfo:GetAttacker():IsPlayer() and dmginfo:GetAttacker():IsZombie() then
			self.CrateHealth = self.CrateHealth - dmginfo:GetDamage()
		
		
		
				local brit = math.Clamp(self.CrateHealth / self.CrateMaxHealth, 0, 1)
		local col = self:GetColor()
		col.r = 255
		col.g = 255 * brit
		col.b = 255 * brit
		if self:GetPlacer():GetPerk("_supply") then
			col.r = 0
			col.g = 200 * brit
			col.b = 200 * brit		
		end

		self:SetColor(col)		
		
			if self.CrateHealth <= 0 then
				self:Explode()
			end
			
			
		end
	end

	function ENT:Explode()
		local trace = {}
		trace.start = self:GetPos() + Vector(0,0,5)
		trace.filter = self.Entity
		trace.endpos = trace.start - Vector(0,0,50)
		local traceground = util.TraceLine(trace)
		
		util.Decal("Scorch",traceground.HitPos - traceground.HitNormal,traceground.HitPos + traceground.HitNormal)

		local Effect = EffectData()
		Effect:SetOrigin(self:GetPos())
		Effect:SetStart(self:GetPos())
		Effect:SetMagnitude(300)
		util.Effect("Explosion", Effect)

		self.Entity:Remove()
	end


	function ENT:Use(activator, caller)
		if not IsValid(activator) then
			return
		end
		
		if not activator:IsPlayer() or not activator:IsHuman() then
			return
		end
		
		activator.NextPop = activator.NextPop or 0
			
		if activator.NextPop > CurTime() then
			return
		end
		activator.NextPop = CurTime() + 1.5

		local gotSupplies = false
		
			if activator:IsPlayer() and activator:IsHuman() then
				ammoType = 	activator:GetActiveWeapon():GetPrimaryAmmoTypeString()
					
				if (ammoType == "none") then
					return 
				end
				
				if (ammoType == "SniperRound") then
					return
				end
			end		
			
		if activator.MobileSupplyTimerActive == false then
	
			if activator.GotMobileSupplies == false then
				activator.GotMobileSupplies = true
				activator.MobileSupplyTimerActive = true	
				activator:SendLua("MySelf.MobileSupplyTimerActive = true")
				activator:SendLua("MySelf.GotMobileSupplies = true")
				activator.MobileSupplyTime = CurTime() + self.AmmoDelay
				activator:SendLua("MySelf.MobileSupplyTime = CurTime() + "..self.AmmoDelay.."")
				
				activator:GiveAmmoPack()
				
				local Owner = self:GetPlacer()
				
				--Heal 
				if activator:Health() < activator:GetMaximumHealth() and Owner:GetPerk("support_medical") then
					activator:SetHealth(activator:Health() + 4)
					skillpoints.AddSkillPoints(Owner,1)			
				end

				--Give SP to crate owner		

				if activator ~= Owner and (IsValid(Owner) and Owner:Alive() and Owner:Team() == TEAM_HUMAN) then
					skillpoints.AddSkillPoints(Owner,4)
					self:FloatingTextEffect2(4, Owner)
					Owner:AddXP(10)
				end

				--Play sound
				activator:EmitSound(Sound("mrgreen/supplycrates/mobile_use.mp3"))

				--
				gotSupplies = true
				
			end
		end

		--Show notice when not being able to use it
		if not gotSupplies then

			--Check if activator is owner, so we can pick it up
			local owner = self:GetPlacer()
			local validOwner = (IsValid(owner) and owner:Alive() and owner:Team() == TEAM_HUMAN)
			if validOwner and activator == owner and not self:GetClaimed() then
				local placeWeapon = "weapon_zs_tools_supplies"
				activator:Give(placeWeapon)
				activator:SelectWeapon(placeWeapon)
				--if SERVER then
					--activator.Weight = activator.Weight + activator:GetActiveWeapon().Weight	
					--print(activator:GetActiveWeapon().Weight	)
				--end

				self:Remove()
			--Check for claiming
			elseif not validOwner then
				--Claim crate
				self:SetClaimed(true)

				--Update owner
				self:SetPlacer(activator)

				--Inform new owner
				activator:Message("You claimed this Mobile Supplies crate",1,"white")
			--Nope. Nothing
			else
				activator:Message("You can't get Supplies at this moment",1,"white")
			end
		end
	end
end
	
if CLIENT then
	ENT.LineColor = Color(210, 0, 0, 100)
	function ENT:Draw()
			
	    self:DrawModel()		
		
	    if not IsValid(MySelf) or MySelf:Team() ~= TEAM_HUMAN then
	        return
	    end

		if MySelf.MobileSupplyTimerActive == false then
	    	self.LineColor = Color(0, math.abs(200 * math.sin(CurTime() * 3)), 0, 100)
	    elseif self.LineColor ~= Color(210, 0, 0, 100) then
	    	self.LineColor = Color(210, 0, 0, 100)
	    end

	    --Draw some stuff
	    local pos = self:GetPos() + Vector(0,0,30)

	    --Check for distance with local player
	    if pos:Distance(MySelf:GetPos()) > 360 then
	        return
	    end
	          
	    local angle = (MySelf:GetPos() - pos):Angle()
	    angle.p = 0
	    angle.y = angle.y + 90
	    angle.r = angle.r + 90

	    cam.Start3D2D(pos,angle,0.26)

		local owner = self:GetPlacer()
		local validOwner = (IsValid(owner) and owner:Alive() and owner:Team() == TEAM_HUMAN)
	
		if !validOwner then
			--draw.SimpleTextOutlined( owner:Name() .."'s Mobile Supplies", "ArialBoldFive", 0, 0, Color(255,255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER,1, Color(0,0,0,255))
			draw.SimpleTextOutlined( "Unclaimed Mobile Supplies", "Trebuchet18", 0, 0, Color(255,255,255,200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER,1, Color(0,0,0,200))
		end
				
		if MySelf.MobileSupplyTimerActive == true then
			local time = math.Round(MySelf.MobileSupplyTime - CurTime())
			draw.SimpleTextOutlined("Ammunition : "..ToMinutesSeconds(time + 1), "Trebuchet18", 0, 20, Color(255,255,255,200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0,0,0,200))

			--Check if placer is MySelf
			if validOwner and MySelf == owner and not self:GetClaimed() then
				draw.SimpleTextOutlined("USE to pickup", "Trebuchet18", 0, 40, Color(255,255,255,200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0,0,0,200))
			elseif not validOwner then
				draw.SimpleTextOutlined("USE to claim", "Trebuchet18", 0, 40, Color(255,255,255,200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0,0,0,200))
			end
		elseif MySelf.MobileSupplyTimerActive == false then
			draw.SimpleTextOutlined("USE for ammunition.", "Trebuchet18", 0, 20, Color(255,255,255,200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0,0,0,200))
		end
	    cam.End3D2D()
	end

	function ENT:OnRemove()
	    hook.Remove("PreDrawHalos", "CustDrawHalosAmmo".. tostring(self))
	end
end

--[[function ENT:ShouldCollide(Ent)
	if Ent:IsPlayer() then
		if Ent:GetPos():Distance(self:GetPos()) <= 30 then
			local dir = (Ent:GetPos() - self:GetPos()):GetNormal()

			--Push
			if Ent:GetVelocity():Length() > 0 then
				Ent:SetVelocity(dir * 66)  
			end
		end

		return false
	end
end]]
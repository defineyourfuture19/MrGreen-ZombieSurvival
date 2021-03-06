-- � Limetric Studios ( www.limetricstudios.com ) -- All rights reserved.
-- See LICENSE.txt for license information
 
AddCSLuaFile()
 
 
SWEP.UseHands = true
SWEP.WorldModel = Model("models/weapons/w_hammer.mdl")
SWEP.Base = "weapon_zs_melee_base"

-- Name, fov, etc
SWEP.PrintName = "Carpenter's Hammer"
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = false
SWEP.ViewModelFlip = false
SWEP.CSMuzzleFlashes = false
 
SWEP.Type = "Tool"
 
if CLIENT then
    SWEP.ShowViewModel = false
    SWEP.ShowWorldModel = true
    killicon.AddFont("weapon_zs_hammer", "ZSKillicons", "c", Color(255, 255, 255, 255))
     
    SWEP.VElements = {
        ["hammer"] = { type = "Model", model = "models/weapons/w_hammer.mdl", bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(3.023, 1.764, -1.575), angle = Angle(0, 0, 180), size = Vector(1, 1, 1), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
        ["nail"] = { type = "Model", model = "models/crossbow_bolt.mdl", bone = "ValveBiped.Bip01_L_Hand", rel = "", pos = Vector(0.989, 2.296, -3.958), angle = Angle(62.951, 0, 0), size = Vector(0.5, 0.5, 0.5), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} }
    }

    SWEP.ViewModelBoneMods = {
        ["ValveBiped.Bip01_L_UpperArm"] = { scale = Vector(1, 1, 1), pos = Vector(2.296, 1.378, -13.011), angle = Angle(0, -98.265, 8.265) },
        ["ValveBiped.Bip01_L_Finger01"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(0, 22.958, 0) },
        ["ValveBiped.Bip01_L_Finger02"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(0, -0.918, 0) },
        ["ValveBiped.Bip01_L_Finger12"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(-32.144, -52.348, 0) }
    }
end
 
SWEP.DamageType = DMG_CLUB
 
-- Slot pos.
SWEP.Slot = 0
SWEP.Weight = 1
 
--SWEP.Primary.ClipSize = 30
--SWEP.Primary.Damage = 25
--SWEP.Primary.DefaultClip = 30
--SWEP.Primary.Automatic = true

SWEP.Primary.Delay = 0.7

SWEP.Secondary.ClipSize = 30
SWEP.Secondary.DefaultClip = 30
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"
--SWEP.Secondary.Ammo = "gravity"
 

SWEP.HoldType = "melee"
 
SWEP.MeleeDamage = 40
SWEP.MeleeRange = 52
SWEP.MeleeSize = 1
SWEP.ToHeal = 5
SWEP.ToHealProp = 0
SWEP.UseMelee1 = true
 
SWEP.HitGesture = ACT_HL2MP_GESTURE_RANGE_ATTACK_MELEE
SWEP.MissGesture = SWEP.HitGesture
 
SWEP.SwingTime = 0.5
SWEP.SwingRotation = Angle(30, -30, -30)
SWEP.SwingOffset = Vector(0, -30, 0)
SWEP.SwingHoldType = "grenade"
 
SWEP.Mode = 1

SWEP.HumanClass = "support"


function SWEP:PlaySwingSound()
    self:EmitSound("weapons/iceaxe/iceaxe_swing1.wav", 75, math.random(65, 70))
end

function SWEP:PlayHitSound()
    self:EmitSound("weapons/melee/crowbar/crowbar_hit-"..math.random(1, 4)..".wav", 75, math.random(110, 115))
end
 
function SWEP:Initialize()
    self.BaseClass.Initialize(self)

    self:SetDeploySpeed(1.1)

    self.NextNail = 0
end
 
function SWEP:OnDeploy()
    self.Weapon:SendWeaponAnim(ACT_VM_DRAW)
	
	self.ToHeal = 8
	
    if SERVER then
        self.Owner._RepairScore = self.Owner._RepairScore or 0
    end
	
	if self.Owner:GetPerk("Support") then
	self.ToHeal = math.Round(self.ToHeal + (self.Owner:GetRank()*0.25))
	end
	
	if IsValid(self.Owner) and self.Owner.DataTable["ShopItems"][51] then
		self.ToHeal = self.ToHeal + 2
	end	
	
	if self.Owner:GetPerk("support_repairs") then
		self.ToHeal = self.ToHeal + 3
	end
	
	if self.Weapon.HadFirstDeploy then return end
	
	
    --if IsValid(self.Owner) and self.Owner:GetPerk("_extranails") then
    --    self.Weapon.HadFirstDeploy = true
    --   self:SetClip2(self:Clip2() * 2)
	--end
	
	if IsValid(self.Owner) and self.Owner:GetPerk("Support") then
		self.Weapon.HadFirstDeploy = true	
		self:SetClip2(self:Clip2()+ self.Owner:GetRank() * 2)
		
		if self.Owner:GetPerk("support_repairs") then
		self:SetClip2(self:Clip2() + 10)		
		end
	end
	
	
	if IsValid(self.Owner) and self.Owner.DataTable["ShopItems"][51] then
		self.Weapon.HadFirstDeploy = true	
		self:SetClip2(self:Clip2()+5)
	end		
end
 
SWEP.NextSwitch = 0
function SWEP:Reload()
    if self.Owner.KnockedDown or ARENA_MODE or CurTime() < self.NextNail then
        return
    end
	
    local tr = self.Owner:TraceLine(48, MASK_SHOT, player.GetAll())

    local trent = tr.Entity
    if not IsValid(trent) then
        return
    end
	
	if tr.Hit and not tr.HitWorld then
		if trent.Nails and #trent.Nails > 0 then
		
			self:PlaySwingSound();
			self:SendWeaponAnim(ACT_VM_HITCENTER)
			self.Alternate = not self.Alternate
			self:MeleeSwing()
			trent:RemoveNail(self.Owner)
            self.NextNail = CurTime() + 0.6
		end	
	end
end

function SWEP:CanPrimaryAttack()
    --if self.Weapon:Clip1() <= 0 then 
        --self.Weapon:SetNextPrimaryFire(CurTime() + 1)
        --return false
    --end
    return true
end

function SWEP:StopSwinging()
if SERVER then
        local tr = self.Owner:TraceLine(54, MASK_SHOT, team.GetPlayers(TEAM_HUMAN))

        local trent = tr.Entity
        --if not IsValid(trent) then
        --  return
        --end

        if tr.Hit and not tr.HitWorld then
        
                self:SendWeaponAnim(ACT_VM_HITCENTER)
                self.Alternate = not self.Alternate
                self.Owner:SetAnimation(PLAYER_ATTACK1)
                
            if trent.Nails and #trent.Nails > 0 then
				local count = 0;
                for i=1, #trent.Nails do
                    local nail = trent.Nails[i]
                       
                    if IsValid(nail) then
                        if nail:GetNailHealth() < nail:GetDTInt(1) then

							nail:SetNailHealth(math.Clamp(nail:GetNailHealth()+(self.ToHeal / # trent.Nails),1,nail:GetDTInt(1)))			
							
							if (count == 0) then
								local pos = tr.HitPos
								local norm = tr.HitNormal
								
			
								local eff = EffectData()
								eff:SetOrigin(pos)
								eff:SetNormal(norm)
								eff:SetScale( math.Rand(0.4,0.5) )
								eff:SetMagnitude( math.random(1,1.2) )
								util.Effect("StunstickImpact", eff, true, true)  

								if not trent._LastAttackerIsHuman then
									skillpoints.AddSkillPoints(self.Owner, 1)
									self.Owner:AddXP(self.ToHeal)
								end
			
								self.Owner:EmitSound("npc/dog/dog_servo"..math.random(7, 8)..".wav", 70, math.random(100, 105))							
							end 

							count = count + 1;
							
                        end
                    end
                end
            end
           
            --turret
            if trent:GetClass() == "zs_turret" then
                if trent:GetDTInt(1) < trent.MaxHealth then
   
                   -- self.Owner._RepairScore = self.Owner._RepairScore + 1
                                           
                   -- if self.Owner._RepairScore == 5 then
                        skillpoints.AddSkillPoints(self.Owner, 1)
                        self.Owner:AddXP(5)
                       -- self.Owner._RepairScore = 0
                   -- end
                    --self:TakePrimaryAmmo(1)
                    trent:SetDTInt(1,trent:GetDTInt(1)+10)
                   
                    local pos = tr.HitPos
                    local norm = tr.HitNormal-- (tr.HitPos - self.Owner:GetShootPos()):Normalize():Angle()
                                   
                    local eff = EffectData()
                    eff:SetOrigin(pos)
                    eff:SetNormal(norm)
                    eff:SetScale( math.Rand(0.4,0.5) )
                    eff:SetMagnitude( math.random(1,1.2) )
                    util.Effect("StunstickImpact", eff, true, true)
                                   
                    self.Owner:EmitSound("npc/dog/dog_servo"..math.random(7, 8)..".wav", 70, math.random(100, 105))
                end
            end
        end
    end
	self:SetSwingEnd(0)
end

function SWEP:PrimaryAttack()

    self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)

    if not self:CanPrimaryAttack() then
        return
    end

    if self.SwingTime == 0 then
        self:MeleeSwing()
    else
        self:StartSwinging()
    end
    -- do after delay the following


end
 
local NONAILS = {}
NONAILS[0] = "It's impossible to put nails here."
NONAILS[0] = "Computer says no. Btw check you're nail count."
NONAILS[MAT_GRATE] = "It's impossible to put nails here."
NONAILS[MAT_GRATE] = "You cannot nail objects here�!"
NONAILS[MAT_CLIP] = "It's impossible to put nails here."
NONAILS[MAT_GLASS] = "Trying to put nails in glass is a silly thing to do."

function SWEP:SecondaryAttack()
    if self.Owner.KnockedDown or ARENA_MODE or CurTime() < self.NextNail then
        return
    end

    if self:Clip2() <= 0 then
        --Remove nail in hand
        if CLIENT then
            self:ResetBonePositions()
        end

        --Notice, cuz we're nice folks explaining how this game works
       -- if SERVER then
       --     self.Owner:Message("No nails left. Buy nails at the Supply Crate.", 2)
        --end
            
        return
    end

    local tr = self.Owner:TraceLine(70, MASK_SHOT, player.GetAll())

    local trent = tr.Entity
    if not IsValid(trent) then
        return
    end
           
    --Get phys object
    local PhysEnt = trent:GetPhysicsObject()


    if SERVER then
        if not IsValid(PhysEnt) or (not PhysEnt:IsMoveable() and not trent.Nails) or trent.IsObjEntity then
            return
        end

        if NONAILS[tr.MatType or 0] then
            if SERVER then
                self.Owner:Message(NONAILS[tr.MatType], 2)
            end
            return
        end
    end

    local trtwo = util.TraceLine({start = tr.HitPos, endpos = tr.HitPos + self.Owner:GetAimVector() * 16, filter = {self.Owner, trent}})

    local ent = trtwo.Entity
    
    if trtwo.HitWorld or IsValid(ent) and string.find(ent:GetClass(), "prop_physics") and ent:GetPhysicsObject():IsValid() and (ent:GetPhysicsObject():IsMoveable() or not ent:GetPhysicsObject():IsMoveable() and ent.Nails ) or ent:IsValid() and ent:GetClass() == "func_physbox" and ent:GetMoveType() == MOVETYPE_VPHYSICS and ent:GetPhysicsObject():IsValid() and (ent:GetPhysicsObject():IsMoveable() or not ent:GetPhysicsObject():IsMoveable() and ent.Nails ) then
        if SERVER then
            if ent.IsObjEntity then
                return
            end
           
            if NONAILS[trtwo.MatType or 0] then
                self.Owner:PrintMessage(HUD_PRINTCENTER, NONAILS[trtwo.MatType])
                return
            end    

            --Ignore doors
            if string.find(trent:GetClass(), "door") then
                return
            end

            local cons = constraint.Weld(trent, ent, tr.PhysicsBone, trtwo.PhysicsBone, 0, true)

            -- New constraint
            if cons then
                self:SendWeaponAnim(ACT_VM_HITCENTER)
                self.Alternate = not self.Alternate
                self.Owner:SetAnimation(PLAYER_ATTACK1)

                self.NextNail = CurTime() + 0.6
                --self:TakePrimaryAmmo(1)
                --self:TakeSecondaryAmmo(1)
                self:TakeSecondaryAmmo(1)
                       
                local nail = ents.Create("nail")
                local aimvec = self.Owner:GetAimVector()
                nail:SetPos(tr.HitPos - aimvec * 8)
                nail:SetAngles(aimvec:Angle())
                nail:SetParentPhysNum(tr.PhysicsBone)
                nail:SetParent(trent)
                nail:SetOwner(self.Owner)
				nail:SetNailParent(tr.Entity)
                nail:Spawn()
                trent:EmitSound("weapons/melee/crowbar/crowbar_hit-".. math.random(1, 4) ..".wav")
                
                --Reward with SP and XP
                --skillpoints.AddSkillPoints(self.Owner, 16)
                --trent:FloatingTextEffect(16, self.Owner)
				--self.Owner:AddXP(10)

                --??
                trent:CollisionRulesChanged()
                       
                -- store entities
                nail.Ents = {}
                -- store 1st ent
                table.insert(nail.Ents, trent)
                       
                trent.Nails = trent.Nails or {}
                table.insert(trent.Nails, nail)
                       
                if not ent:IsWorld() then
                    -- store second one
                    table.insert(nail.Ents, ent)
                   
                    ent.Nails = ent.Nails or {}
                    table.insert(ent.Nails, nail)
                end
               
                if trtwo.HitWorld then
                    if trent:GetPhysicsObject():IsValid() and ent:IsWorld() then
                        local phys = trent:GetPhysicsObject()
                        phys:EnableMotion( false )
                        nail.toworld = true
                    end
                end

                nail.constraint = cons
                cons:DeleteOnRemove(nail)
            else -- Already constrained.
                if string.find(trent:GetClass(), "door") then
                    return
                end

                for _, oldcons in pairs(constraint.FindConstraints(trent, "Weld")) do
                    if oldcons.Ent1 == ent or oldcons.Ent2 == ent then
                        trent.Nails = trent.Nails or {}
                        if #trent.Nails < 5 then
                            self:SendWeaponAnim(ACT_VM_HITCENTER)
                            self.Alternate = not self.Alternate
                            self.Owner:SetAnimation(PLAYER_ATTACK1)

                            self.NextNail = CurTime() + 0.6
                            self:TakeSecondaryAmmo(1)
                           
                            --Reward with SP and XP
                            --skillpoints.AddSkillPoints(self.Owner, 16)
                           -- trent:FloatingTextEffect(16, self.Owner)
                            --self.Owner:AddXP(10)
                                   
                            local nail = ents.Create("nail")
                            local aimvec = self.Owner:GetAimVector()
                            nail:SetPos(tr.HitPos - aimvec * 8)
                            nail:SetAngles(aimvec:Angle())
                            nail:SetParentPhysNum(tr.PhysicsBone)
                            nail:SetParent(trent)
                            nail:SetOwner(self.Owner)
                            nail:Spawn()
                            trent:EmitSound("weapons/melee/crowbar/crowbar_hit-"..math.random(1,4)..".wav")
                            trent:CollisionRulesChanged()
                            --Store entities
                            nail.Ents = {}
                            --Store first ent
                            table.insert(nail.Ents, trent)
                           
                            table.insert(trent.Nails, nail)
                            --ent.Nails = ent.Nails or {}
                            --table.insert(ent.Nails, nail)
                                   
                            if not ent:IsWorld() then
                                -- store second one
                                table.insert(nail.Ents, ent)
                       
                                ent.Nails = ent.Nails or {}
                                table.insert(ent.Nails, nail)
                                ent:CollisionRulesChanged()
                            end
                                   
                            if trtwo.HitWorld then
                                if trent:GetPhysicsObject():IsValid() and ent:IsWorld() then
                                    local phys = trent:GetPhysicsObject()
                                    phys:EnableMotion(false)
                                    nail.toworld = true
                                end
                            end

                            nail.constraint = oldcons.Constraint
                            oldcons.Constraint:DeleteOnRemove(nail)
                        --else
                           -- if SERVER then
                                --self.Owner:Message("Only 3 nails can be placed here.", 2)
                           -- end
                        end
                    end
                end
            end
        end
    end
end

function SWEP:Equip(NewOwner)
    if CLIENT then
        return
    end
   

	
	if SERVER then
		self.Owner.Weight = self.Owner.Weight + self.Weight
		self.Owner:CheckSpeedChange()
		
		
		if self.Owner:HasWeapon("weapon_zs_fists2") then
			self.Owner:StripWeapon("weapon_zs_fists2")
			self.Owner:SelectWeapon("weapon_zs_hammer")
		end
	end   
   
    -- Update it just in case
    self.MaximumNails = self:Clip2()             
   
    -- Call this function to update weapon slot and others
    gamemode.Call("OnWeaponEquip", NewOwner, self)
end

function SWEP:Precache()
    util.PrecacheSound("weapons/melee/crowbar/crowbar_hit-1.wav")
    util.PrecacheSound("weapons/melee/crowbar/crowbar_hit-2.wav")
    util.PrecacheSound("weapons/melee/crowbar/crowbar_hit-3.wav")
    util.PrecacheSound("weapons/melee/crowbar/crowbar_hit-4.wav")
    util.PrecacheSound("weapons/crossbow/reload1.wav")
end
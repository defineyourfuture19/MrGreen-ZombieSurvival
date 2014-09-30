include("shared.lua")

SWEP.PrintName = "'Aegis' Barricade Kit"
SWEP.DrawAmmo = true
SWEP.DrawCrosshair = false
SWEP.ViewModelFOV = 60
SWEP.ViewModelFlip = false
SWEP.CSMuzzleFlashes = false

SWEP.Slot = 3
SWEP.SlotPos = 2

SWEP.Models = { "models/props_interiors/radiator01a.mdl", "models/props_junk/trashbin01a.mdl" }
SWEP.Inited = false

function SWEP:Initialize()
	self.Inited = true
end

function SWEP:SetModelToSpawn ( int ) 
	self.Weapon:SetNetworkedInt ( "ModelToSpawn", int )
end

function SWEP:GetModelToSpawn()
	return self.Models [self.Weapon:GetNetworkedInt ( "ModelToSpawn" )]
end

function SWEP:PrimaryAttack()
	if ValidEntity ( self.GhostEntity ) then
		self.GhostEntity:Remove()
	end
end

function SWEP:Holster()
	if ValidEntity ( self.GhostEntity ) then
		self.GhostEntity:Remove()
	end
end

function SWEP:CanSecondaryAttack()
	return false
end

function SWEP:DrawWeaponSelection( x, y, wide, tall, alpha )
end

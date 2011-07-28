--[[
	~ Hands Swep ~ Serverside ~
	~ Applejack ~
--]]
includecs("shared.lua");
AddCSLuaFile("cl_init.lua");

local stamina;
function SWEP:Initialize()
	self.Primary.NextSwitch = CurTime() 
	self:SetWeaponHoldType("normal");
	stamina = GM:GetPlugin("stamina");
end

function SWEP:PrimaryAttack()
    local ply = self.Owner;
    local keys = ply:KeyDown(IN_SPEED);
    if (not keys and ply:GetNWBool("Exhausted")) then
        return;
    end
   	-- Punch and woosh.
	self:EmitSound("npc/vort/claw_swing2.wav");
	self:SendWeaponAnim(ACT_VM_HITCENTER);
    -- Slow down the punches.
	self:SetNextPrimaryFire(CurTime() + self.Primary.Refire);
    -- Check if we're holding something, and throw it instead of doing the punching code if we are
    if (IsValid(self.HeldEnt)) then
		self:DropObject(self.Primary.ThrowAcceleration);
		return;
	end

    -- See where we're punching
    local tr = ply:GetEyeTraceNoCursor();
    if (not (tr.Hit or tr.HitWorld) or tr.StartPos:Distance(tr.HitPos) > 128) then
        return;
    end
    local ent = tr.Entity;

    -- Check for keys
    if (keys) then
        self:SetNextPrimaryFire(CurTime() + 0.75);
        self:SetNextSecondaryFire(CurTime() + 0.75);
        -- If we hit the world or 
        if (tr.HitWorld or not ent:IsOwnable() or ent._Jammed) then
            return;
        elseif (not ent:HasAccess(ply)) then
            ply:Notify("You do not have access to that lock!", 1);
            return;
        end
        -- Lock
        ent:Lock();
        ent:EmitSound("doors/door_latch3.wav");
        return;
    end
    -- Stamina
	if (stamina and not self:GetDTBool(1)) then
		self.Owner._Stamina = math.Clamp(self.Owner._Stamina - 20,0,100)
	end
    -- Smack
    self:EmitSound("weapons/crossbow/hitbod2.wav");
    -- Fire a bullet for impact effects
    local bullet = {
        Num = 1;
        Src = tr.StartPos;
        Dir = tr.Normal;
        Spread = Vector(0,0,0);
        Tracer = 0;
        Force = 0;
        Damage = 0;
    }
    -- Check if super punch mode is on
    if (not tr.HitWorld and self:GetDTBool(1)) then
        bullet.Callback = wtfboom;
    end
    ply:FireBullets(bullet);
    -- Check what we hit
    if (tr.HitWorld) then
        return;
    end
    -- We have hit an entity.
    -- Knockback
    --[[
    local phys = ent:GetPhysicsObject();
    if (IsValid(phys) and phys:IsMovable()) then
        phys:ApplyForceOffset(tr.Normal * self.Primary.PunchAcceleration * phys:GetMass(), tr.HitPos);
    end
    --]]
    -- Damage
    -- Don't let people punch each other to death
    if ((ent._Player or ent:IsPlayer()) and not self:GetDTBool(1) and ent:Health() <= 15) then
        -- Re stun (OH WAIT STUN ISN'T PROGRESSIVE EVEN THOUGH IT SHOULD BE >:c)
        local pl = ent;
        if (IsValid(ent._Player)) then
            pl = ent._Player;
        end
        pl._Stunned = true;
        if (not pl:KnockedOut()) then
            pl:KnockOut(GM.Config["Knock Out Time"] / 2);
            GM:Log(EVENT_EVENT, "%s knocked out %s with a punch.", ply:Name(), pl:Name());
        end
        return;
    end
    local dmg = DamageInfo();
    dmg:SetAttacker(ply);
    dmg:SetInflcitor(self);
    dmg:SetDamage(self.Primary.Damage);
    -- TODO: Is this adequate knockbock?
    dmg:SetDamageForce(tr.Normal * self.Primary.PunchAcceleration * phys:GetMass());
    dmg:SetDamagePosition(tr.HitPos);
    if (self:GetDTBool(1)) then -- super
        -- Wheeee :D
        dmg:SetDamageType(DMG_BLAST | DMG_SONIC);
    else
        dmg:SetDamageType(DMG_CLUB);
    end
    -- TAKE THAT!
    ent:TakeDamageInfo(dmg);
end

-- Called when the player attempts to secondary fire.
function SWEP:SecondaryAttack()
    if (IsValid(self.HeldEnt)) then
        self:DropObject();
        return;
    end
    local ply = self.Owner;
    local tr = ply:GetEyeTraceNoCursor();
    if (tr.HitWorld or not tr.Hit or tr.StartPos:Distance(tr.HitPos) > 128) then
        return;
    end
    -- Implicitly valid.
    local ent = tr.Entity;
    if (ent:IsDoor()) then
        -- Knock
        self:SendWeaponAnim(ACT_VM_HITCENTER);
        self:EmitSound("physics/wood/wood_crate_impact_hard2.wav")
        self:SetNextSecondaryFire(CurTime() + 0.25);
        -- Cheats!
        if (self:GetDTBool(1) and ply:IsSuperAdmin()) then
            GM:OpenDoor(ent, 0);
        end
    elseif (ply:KeyDown(IN_SPEED)) then
        -- Attempted to unlock
        self:SetNextPrimaryFire(CurTime() + 0.75);
        self:SetNextSecondaryFire(CurTime() + 0.75);
        self:SendWeaponAnim(ACT_VM_HITCENTER);
        if (tr.HitWorld or not ent:IsOwnable() or ent._Jammed) then
            return;
        elseif (not ent:HasAccess(ply)) then
            ply:Notify("You do not have access to that lock!", 1);
            return;
        end
        -- Lock
        ent:UnLock();
        ent:EmitSound("doors/door_latch3.wav");
    else
        self:Pickup(ent, tr);
    end
end






-- TODO: Make this use kuro's method.
function SWEP:Think()
	if (not self.HeldEnt) then
        return;
    end
    if (not IsValid(self.HeldEnt)) then
        self.HeldEnt = nil;
        self:SetDTBool(0, false);
    end
    --[[
	if !ValidEntity(self.HeldEnt) then
		if ValidEntity(self.EntWeld) then self.EntWeld:Remove() end
		self.Owner._HoldingEnt, self.HeldEnt.held, self.HeldEnt, self.EntWeld, self.EntAngles, self.OwnerAngles = nil
		self:Speed()
		return
	elseif !ValidEntity(self.EntWeld) then
		self.Owner._HoldingEnt, self.HeldEnt.held, self.HeldEnt, self.EntWeld, self.EntAngles, self.OwnerAngles = nil
		self:Speed()
		return
	end
	if !self.HeldEnt:IsInWorld() then
		self.HeldEnt:SetPos(self.Owner:GetShootPos())
		self:DropObject()
		return
	end
	if self.NoPos then return end
	local pos = self.Owner:GetShootPos()
	local ang = self.Owner:GetAimVector()
	self.HeldEnt:SetPos(pos+(ang*60))
	self.HeldEnt:SetAngles(Angle(self.EntAngles.p,(self.Owner:GetAngles().y-self.OwnerAngles.y)+self.EntAngles.y,self.EntAngles.r))
    --]]
end
--[[
function SWEP:Speed(down)
	if down then
		self.Owner:Incapacitate()
	else
		self.Owner:Recapacitate()
	end
end
--]]

function SWEP:Holster()
	self:DropObject()
	self.Primary.NextSwitch = CurTime() + 1
	return true
end

function SWEP:PickUp(ent, tr)
    if (ent.held) then
        return;
    end
    if (IsValid(self.HeldEnt)) then
        return;
    end
    if (not self.Owner:CanPickup(ent)) then
        return;
    end
    -- TODO: What happens if you pickup a ragdoll?
    --       If it doesn't work, then make a small prop, weld that to the physbone and then pickup that.
    self.Owner:PickupObject(ent);
end
--[[
	if ent.held then return end
	if (constraint.HasConstraints(ent) or ent:IsVehicle()) then
		return false
	end
	local pent = ent:GetPhysicsObject( )
	if !ValidEntity(pent) then return end
	if pent:GetMass() > 60 or not pent:IsMoveable() then
		return
	end
	if ent:GetClass() == "prop_ragdoll" then
		return false
	else
		ent:SetCollisionGroup( COLLISION_GROUP_WORLD )
		local EntWeld = {}
		EntWeld.ent = ent
		function EntWeld:IsValid() return ValidEntity(self.ent) end
		function EntWeld:Remove()
			if ValidEntity(self.ent) then self.ent:SetCollisionGroup( COLLISION_GROUP_NONE ) end
		end
		self.NoPos = false
		self.EntWeld = EntWeld
	end
	--print(self.EntWeld)
--	print("k, pickin up")
	self.Owner._HoldingEnt = true
	self.HeldEnt = ent
	self.HeldEnt.held = true
	self.EntAngles = ent:GetAngles()
	self.OwnerAngles = self.Owner:GetAngles()
	self:Speed(true)
end
--]]

function SWEP:DropObject(acceleration)
	acceleration = acceleration or 0.1;
    if (not IsValid(self.HeldEnt)) then
        return;
    end
    self.Owner:DropObject(self.HeldEnt);
    local phys = self.HeldEnt:GetPhysicsObject();
    if (IsValid(phys)) then
        phys:ApplyForceCenter(self.Owner:GetAimVector() * pent:GetMass() * acceleration);
    end
end


--[[
	acceleration = acceleration or 0.1
	if !ValidEntity(self.HeldEnt) then return true end
	if ValidEntity(self.EntWeld) then self.EntWeld:Remove() end
	local pent = self.HeldEnt:GetPhysicsObject( )
	if pent:IsValid() then
		pent:ApplyForceCenter(self.Owner:GetAimVector() * pent:GetMass() * acceleration)
		--print(pent:GetMass() , acceleration,pent:GetMass() * acceleration)
	end
	self.Owner._HoldingEnt, self.HeldEnt.held, self.HeldEnt, self.EntWeld, self.EntAngles, self.OwnerAngles = nil
	self:Speed()
end
--]]

function SWEP:OnRemove()
	self:DropObject()
	return true
end

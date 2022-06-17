AddCSLuaFile()
ENT.Base 	= "base_nextbot"
ENT.Spawnable = true
ENT.PrintName = "DR kleaner"
ENT.Category = "DR kleaner"
ENT.EstUnKleaner = true
ENT.traquedist = 6000

local vie = 550
local viemax = 500

local function DonneCouleurJoueur(ent, color)
	if not IsValid(ent) then return end
	function ent.GetPlayerColor() return color:ToVector() end
	if SERVER then
		net.Start("DonneCouleurJoueur")
		net.WriteEntity(ent)
		net.WriteColor(color)
		net.Broadcast()
	end
end
  
if SERVER then
	util.AddNetworkString("DonneCouleurJoueur")
else
	net.Receive("DonneCouleurJoueur", function()
		local ent = net.ReadEntity()
		local color = net.ReadColor()
		DonneCouleurJoueur(ent, color)
	end)
end

function ENT:Initialize()	
	self:SetModel( "models/player/kleiner.mdl" )   			
	if SERVER then		
		--self.CouleurDuTruc = Color( math.random(255), math.random(255), math.random(255))
		self.CouleurDuTruc = Color(0,0,0)
		self.loco:SetDesiredSpeed(300)
		self.loco:SetStepHeight( 20 )
		self.loco:SetJumpHeight(20)
		self:StartActivity(ACT_HL2MP_WALK)			
		self:SetHealth( vie )
		self:SetMaxHealth( viemax )
		self:SetBloodColor(3)	
		self:AddFlags(FL_OBJECT+FL_NPC)

		self:SetCollisionBounds( Vector(-10,-10,0) , Vector(10,10,72))
		self:SetCollisionGroup(COLLISION_GROUP_NPC)

		self:PhysicsInitShadow()
		
		
		
		self.nombrecoisser = 0
		self.durrebloquer = 0
		self.TempBloque = 0		
		self.delayRoute = 0
		self.delayc = 0
		self.EstFou = false

		self.VJ_AddEntityToSNPCAttackList = true
		DonneCouleurJoueur(self,self.CouleurDuTruc)		

		/*for _, kleaner in ipairs( ents.FindByClass( "dr_kleaner" ) ) do
			if kleaner == self then break end
			notouche = constraint.NoCollide(kleaner, self , 0 , 0)	
			constraint.AddConstraintTable(kleaner ,notouche )
			constraint.AddConstraintTable(self ,notouche )
		end*/
		
	end
end




function ENT:OnKilled(dmginfo)
	hook.Run("OnNPCKilled",self,dmginfo:GetAttacker(),dmginfo:GetInflictor() )	
	local corpsess = self:BecomeRagdoll(dmginfo)
	--print(corpsess)
	DonneCouleurJoueur(corpsess,self.CouleurDuTruc)	
end

function ENT:BodyUpdate()
	self:BodyMoveXY()
end

function ENT:RunBehaviour()
	
--	self.IsDrGNextbot = true

	--code vj enemie test
/*
	for _, npcc in ipairs( ents.GetAll() ) do
		if npcc:IsNPC() then
			print(npcc)
			--npcc:AddEntityRelationship(self, 2 , 99)
			npcc:vlt_SetRelationship(self , D_HT)	
		--	npcc:DrG_SetRelationship(self , D_HT)
		end	 		
	end 
*/	
	while (true) do
		local phyz = self:GetPhysicsObject()
		phyz:UpdateShadow( self:GetPos(),self:GetAngles(), 0 )
	
		if not GetConVar("ai_disabled"):GetBool() then			
			self:Comportement()			
		--	self:loco:Approach( self:GetPos()-self(GetPos()), 1 )
		end
		coroutine.yield()		
	end	
end

function ENT:Isberseque()
	return  self:Health() < self:GetMaxHealth() 
end

function ENT:TargetKleaning(ent) 	
	local diferancedistancemin = 150
	if ent:GetClass() == self:GetClass() then return false end
	if ent:GetPos():Distance(self:GetPos()) > self.traquedist then 		
		return false 
	end
	if IsValid(ent.KleanerCible) and ent.KleanerCible != self then 		
		if ent:GetPos():Distance(self:GetPos()) + diferancedistancemin < ent:GetPos():Distance(ent.KleanerCible:GetPos()) then
			if not self.EstFou then
				if ent:IsNPC() or ent:IsNextBot() or ent:IsPlayer() then return false end				
			end		
			--ent.KleanerCible.KleanerCorpse = nil 			
			if ent:IsPlayer() and not ent:Alive() then 
				ent.KleanerCible = nil
				return false 
			end						
			if ent:IsPlayer() and GetConVar("ai_ignoreplayers"):GetBool() then
				ent.KleanerCible = nil
				return false 
			end			
			return true	
		else 
			return false 
		end		
	end
	if ent:IsRagdoll() then return true end		
	if not self.EstFou then return false end
	if ent:IsPlayer() and not ent:Alive() then return false end
	if ent:IsPlayer() then return not GetConVar("ai_ignoreplayers"):GetBool() end
	return ent:IsNPC() or ent:IsNextBot()  
end

function ENT:GetClosestCorpse()
	local corpse, dist = nil, 0
	for i, ent in ipairs(ents.GetAll()) do
		if not self:TargetKleaning(ent) then continue end	
		if not corpse or self:GetRangeTo(ent) < dist then
			corpse = ent 
			dist = self:GetRangeTo(ent)		
		end		
	end
	return corpse
end

function ENT:EstCeQueJeTouche(ent)
	local angle = math.abs(math.AngleDifference(self:GetAngles().y, (ent:GetPos() - self:GetPos()):Angle().y))
--	return true
	return (angle < 60 and self:GetRangeTo(ent) < 80) or self:GetRangeTo(ent) < 20
end



function ENT:MoveToPosVlt( pos, options )
    local options = options or {}
	local distanceminreload = 10
	if IsValid(self) and self.delayRoute < CurTime() then   


		
	--	if  !IsValid(self.route) or pos:Distance(self.route:GetCurrentGoal().pos) < 5  then
			self.route  = Path( "Follow" )	
	  		self.route:SetMinLookAheadDistance( options.lookahead or 300 )
	  		self.route:SetGoalTolerance( options.tolerance or 20 )
			self.route:Compute( self, pos )
		--	print("recompute le chemin")
	--	end
		if ( !self.route:IsValid() ) then 
			self.delayRoute = CurTime() + 5 
			return "failed" 		
		end		
	
		distancepos = #self.route:GetAllSegments()
	--	print(distancepos)
		if distancepos < 5 then
			self.delayRoute =  CurTime() + 0.3
		elseif distancepos < 10 then
			self.delayRoute =  CurTime() + 3
		else
			self.delayRoute =  math.min( CurTime()+(distancepos*0.3),40)
		end
	end
	
    

    if ( self.route:IsValid() ) then 	

		local distancedebloquemin = 20
		local distancebloque = 100
		local rafraisdurrer = 4
		local rafraisbloque = 8

		if self.TempBloque < CurTime() then
			if self.durrebloquer > rafraisbloque then	
				self.nombrecoisser = math.min( self.nombrecoisser+1	, #self.route:GetAllSegments()) 
				while self:GetPos():Distance(self.route:GetAllSegments()[self.nombrecoisser].pos) < distancedebloquemin and self.nombrecoisser < #self.route:GetAllSegments() do
					self.nombrecoisser = math.min( self.nombrecoisser+1	, #self.route:GetAllSegments()) 
				end
		--		print(self.nombrecoisser)				
				self:SetPos(self.route:GetAllSegments()[self.nombrecoisser].pos )
				self.durrebloquer = 0
			end
			self.EstBloque = false
			if self.curentposcheck then 				
				if (self.curentposcheck:Distance(self:GetPos()) < distancebloque) then					
					self.EstBloque = true									
				end				
			end	
			self.curentposcheck = self:GetPos()	
			self.TempBloque = CurTime() + rafraisdurrer
			if (self.EstBloque)	then
				self.durrebloquer = self.durrebloquer+ rafraisdurrer
			else
				self.durrebloquer = 0
				self.nombrecoisser = 0
			end
		end
	--	print(#self.route:GetAllSegments())
	--	print(self.nombrecoisser)
	--	print( self.durrebloquer )	
	--	print(self.EstBloque)	
					
		
		local pointb , pointh = self:GetCollisionBounds()
		local cotacth = ((pointb)+(Vector(0,0,25)))	
	--	print(self:GetCollisionBounds()[1])	
	
		local CogneXp = util.TraceHull( {
			start = self:GetPos(),
			endpos = (self:GetPos())+(Vector(5,0,0)),
			maxs = pointh,
			mins = cotacth,
			filter = self			
		})
		local CogneXm = util.TraceHull(	{
			start = self:GetPos(),
			endpos = (self:GetPos()+Vector(-5,0,0)),
			maxs = pointh,
			mins = cotacth,
			filter = self		
		})
		local CogneYp = util.TraceHull(	{
			start = self:GetPos(),
			endpos = (self:GetPos()+Vector(0,5,0)),
			maxs = pointh,
			mins = cotacth,
			filter = self			
		})
		local CogneYm = util.TraceHull(	{
			start = self:GetPos(),
			endpos = (self:GetPos()+Vector(0,-5,0)),
			maxs = pointh,
			mins = cotacth,
			filter = self			
		})
		self.route:Update( self )

		if  (CogneXp.Hit) then 
			self.loco:Approach(self:GetPos()+Vector(-1,0,0),1)
			--print("aie x")
		elseif (CogneXm.Hit) then
			self.loco:Approach(self:GetPos()+Vector(1,0,0),1)
			--print("ouille x")
		elseif (CogneYp.Hit) then
			self.loco:Approach(self:GetPos()+Vector(0,-1,0),1)
			--print("aie y")
		elseif	(CogneYm.Hit) then
			self.loco:Approach(self:GetPos()+Vector(0,1,0),1)
		 --print("ouille y")
		else
		--	self.route:Update( self )
		--	print("go")
		end
       
        -- Draw the path (only visible on listen servers or single player)
        if ( options.draw ) then
            self.route:Draw()
        end
        -- If we're stuck then call the HandleStuck function and abandon


        if ( self.loco:IsStuck() ) then
            self:HandleStuck()
            return "stuck"
        end
		

        --
        -- If they set maxage on options then make sure the path is younger than it
        --
        if ( options.maxage ) then
            if ( self.route:GetAge() > options.maxage ) then return "timeout" end
        end
        --
        -- If they set repath then rebuild the path every x seconds
        --
        if ( options.repath ) then
            if ( self.route:GetAge() > options.repath ) then self.route:Compute( self, pos ) end
        end        
    end
    return "ok"
end

function ENT:Comportement()
--	
	if (self:Health() < self:GetMaxHealth()) and not self.EstFou then
		self.EstFou = true 	
		
		for _, npcc in ipairs( ents.GetAll() ) do
			if npcc:IsNPC() then
				--npcc:AddEntityRelationship(self, 2 , 99)				
				npcc:vlt_SetRelationship(self,D_FR)	
			end	 
		end 
		
		
		
	end
	local corpse = self.KleanerCorpse	
	if 	self.delayc < CurTime() then
		corpse = self:GetClosestCorpse()	
		self.delayc = CurTime()+1
	end

	if not IsValid(corpse) then 
		return 
	end	
	
	if self.KleanerCorpse != corpse and  IsValid(self.KleanerCorpse) then 
		self.KleanerCorpse.KleanerCible = nil 
	end

	self.KleanerCorpse = corpse
	corpse.KleanerCible = self

	
	if corpse:GetPos():Distance(self:GetPos()) > self.traquedist then
		self.KleanerCorpse.KleanerCible = nil 
		self.KleanerCorpse = nil 
		return
	end

	

	if self.KleanerCorpse:IsPlayer() and (GetConVar("ai_ignoreplayers"):GetBool() or !self.KleanerCorpse:Alive()) then
		self.KleanerCorpse.KleanerCible = nil 
		self.KleanerCorpse = nil
	end
	
	self:MoveToPosVlt(corpse:GetPos(),{
		maxage = 1		
	})

	if IsValid(corpse) and self:GetRangeTo(corpse) < 20 and self:EstCeQueJeTouche(corpse) then
		
		if corpse:IsPlayer() and GetConVar("ai_disabled"):GetBool() then
			self.KleanerCorpse.KleanerCible = nil 
			self.KleanerCorpse = nil
			return
		end
		if not corpse:IsRagdoll() then
			EmitSound(Sound("vo/ravenholm/pyre_anotherlife.wav"),self:GetPos(),self:EntIndex(), CHAN_VOICE, 1, 60, 0, 150)
		end		
		--cado:SetModelScale( 0, 20)
		--print(corpse:GetAngles())	
		timer.Simple(1, function() 			
			if IsValid(self) and IsValid(corpse) and self:EstCeQueJeTouche(corpse) then	
				
				local cado = ents.Create("prop_physics")
				cado:SetPos(corpse:GetPos())
				
			--	print(cado:GetAngles())
				cado:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
				cado:SetModelScale( 0.5 , 0)
				cado:SetModel("models/props/rpd/bodybag.mdl")
				cado:SetAngles(Angle(0,math.random(359),0))									
				
				cado:SetModelScale( 1 , 0.5)
				timer.Simple(80, function() 			
					if IsValid(cado)  then									
						cado:SetModelScale( 0 ,10)
					end		
				end)
				timer.Simple(90, function() 			
					if IsValid(cado)  then									
						cado:Remove()	
					end		
				end)				
				EmitSound(Sound("npc/barnacle/barnacle_tongue_pull2.wav"),cado:GetPos(),cado:EntIndex(), CHAN_AUTO, 1, 75, 0, 200)
					
				

				cado:Spawn()
				if corpse:IsNPC() or  corpse:IsNextBot() or (corpse:IsPlayer() and corpse:Alive() ) then
					hook.Run("OnNPCKilled",corpse,self,self)					
					EmitSound(Sound("ambient/voices/f_scream1.wav"),corpse:GetPos(),corpse:EntIndex(), CHAN_VOICE, 1, 75, 0, 100)
					cado:SetAngles(corpse:GetAngles()+Angle(90,0,0))
					cado:SetPos(corpse:GetPos()+Vector(0,0,30))		
					cado:GetPhysicsObject():SetAngleVelocity(Vector(0,-360,0))	
					cado:GetPhysicsObject():SetVelocity(Vector(0,0,50))	
					if 	(corpse:IsPlayer() and corpse:Alive() )  then
						EmitSound(Sound("ambient/voices/f_scream1.wav"),corpse:GetPos(),corpse:EntIndex(), CHAN_VOICE, 1, 75, 0, 100)
						corpse:KillSilent() 
						corpse.KleanerCible = nil 
						self.KleanerCorpse = nil
					end
				end					

					
				corpse:Remove()				
				
				--Dissolve(corpse)
				if self:GetMaxHealth() > self:Health() then self:SetHealth(self:Health()+20 ) end

			end		
		end)
	
	
			
		
		self:PlaySequenceAndWait("zombie_attack_special_original")
		coroutine.wait(0.5)		
		self:StartActivity(ACT_HL2MP_WALK)		
	end	
end

list.Set( "NPC", "dr_kleaner", {
	Name = "Dr Kleaner",
	Class = "dr_kleaner",
	Category = "Dr Kleaner"
})


if file.Exists("autorun/slvbase", "LUA") then
    function ENT:PercentageFrozen() return 0 end
end
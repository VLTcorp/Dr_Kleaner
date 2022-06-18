print("vltbase")


local clenerostil = CreateConVar("vlt_kl_hostil", "0" ,FCVAR_ARCHIVE)
concommand.Add( "vlt_kl_trigger", function()  
	for _, kleaner in ipairs( ents.FindByClass( "dr_kleaner" ) ) do
    if not kleaner.EstFou then
      kleaner:DevientHostil()
      kleaner.EstFou = true 
    end       
	end
end )
if SERVER then
	hook.Add("OnEntityCreated", "relationkleaner" , function (ent)        
    if ent:IsNPC() then
			for _, kleaner in ipairs( ents.FindByClass( "dr_kleaner" ) ) do
			--	print(ent)
				if kleaner.EstFou then
				--	ent:AddEntityRelationship(kleaner, 2 , 99)	
					timer.Simple(1, function()
						if IsValid(ent) and IsValid(kleaner) then
							ent:vlt_SetRelationship(kleaner , D_HT)			
						end
					end)	
				end
			end		
    elseif (ent:GetClass()=="dr_kleaner") then
      if clenerostil:GetBool() then   
        timer.Simple(0.1, function() 			
					if IsValid(ent)  then
						ent.EstFou = true 	            
            for _, npcc in ipairs( ents.GetAll() ) do
              if npcc:IsNPC() then                				
                npcc:vlt_SetRelationship(ent,D_HT)	
              end	 
            end 
					end		
				end)
      end 
    end 
  end)	

  hook.Add("PlayerSpawnedNPC", "donneNPC_creator", function(ply, ent)
    if not ent.EstUnKleaner then return end
    ent:SetCreator(ply)    
  end)



end




local npcMETA = FindMetaTable("NPC")
if SERVER then
  function npcMETA:vlt_SetRelationship(ent, disp)  
    if not IsValid(ent) then return end
    if self.CPTBase_NPC then
      self:AddEntityRelationship(ent, disp, 99)
    else
      self._DrGBaseRelPrios = self._DrGBaseRelPrios or {}
      if not self._DrGBaseRelPrios[ent] then self._DrGBaseRelPrios[ent] = 0 end
      self._DrGBaseRelPrios[ent] = self._DrGBaseRelPrios[ent]+1
      self:AddEntityRelationship(ent, disp, self._DrGBaseRelPrios[ent])
      if not self.IsVJBaseSNPC or not ent:IsNextBot() then return end
      if istable(self.CurrentPossibleEnemies) and
      not table.HasValue(self.CurrentPossibleEnemies, ent) then
        table.insert(self.CurrentPossibleEnemies, ent)
      end
      if istable(self.VJ_AddCertainEntityAsEnemy) then
        if (disp == D_HT or disp == D_FR) then
          if not table.HasValue(self.VJ_AddCertainEntityAsEnemy, ent) then
            table.insert(self.VJ_AddCertainEntityAsEnemy, ent)
          end
        else table.RemoveByValue(self.VJ_AddCertainEntityAsEnemy, ent) end
      end
      if istable(self.VJ_AddCertainEntityAsFriendly) then
        if disp == D_LI then
          if not table.HasValue(self.VJ_AddCertainEntityAsFriendly, ent) then
            table.insert(self.VJ_AddCertainEntityAsFriendly, ent)
          end
        else table.RemoveByValue(self.VJ_AddCertainEntityAsFriendly, ent) end
      end
    end
  end
end
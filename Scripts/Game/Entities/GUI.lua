GUI = {
	Properties =
	{
		ServerModel			= nil,
		objModel			= "objects/box.cgf",
		bRigidBody			= 1,
		bResting			= 1,
		bUsable				= 1,
		bPhysicalized		= 1,
		fMass				= 1,
	},

	Server = {
		OnHit = function(self, aHitInfo)
			GUI.OnHit(self, aHitInfo)
		end,
		OnContact = function(self, pContact)
			GUI.OnContact(self, pContact)
		end,
	},

	Client = {
		OnHit = function(self, aHitInfo)
		end
	},

	----------------------
	OnSpawn = function(self)
		self:OnReset()
	end,

	----------------------
	OnDestroy = function(self)
	end,

	----------------------
	OnReset = function(self)

		-- name = "xyz,Model={file.cfg}Physics={1},Mass={69},Rigid={1},Resting={0}"

		local sName = self:GetName()
		local function g(s,m,n)
			local x = string.match(sName, s .. "={(" .. (m or ".-") .. ")},?")
			if (n) then
				return tonumber(x)
			end
			return x
		end

		local sObj 		= (g("Model") or self.Properties.objModel)
		local iPhysics 	= (g("Physics", "%d+", 1) or self.Properties.bPhysicalized)
		local fMass 	= (g("Mass", "%d+", 1) or self.Properties.fMass)
		local fRigid 	= (g("Rigid", "%d", 1) or self.Properties.bRigidBody)
		local fResting 	= (g("Resting", "%d", 1) or self.Properties.bResting)
		local fUsable 	= (g("Use", "%d", 1) or 0)
		local fPickable	= (g("Pick", "%d", 1) or 0)
		local fScale	= (g("Scale", ".-", 1) or 0)
		local sEffect   = g("PProps" or "") -- client only
		local sSound	= g("Sound" or "") -- client only

		if (CryAction.IsClient()) then
			if (sSound) then
				local sndFlags = SOUND_DEFAULT_3D
				if (string.match(sSound, "&loop$")) then
					sndFlags = bor(sndFlags, SOUND_LOOP)
				end
				self.SndSlot = self:PlaySoundEvent(string.gsub(sSound, "&loop$", ""), g_Vectors.v000, g_Vectors.v010, sndFlags, SOUND_SEMANTIC_PLAYER_FOLEY)
			end

			if (sEffect) then
				if (g_Client) then
					g_Client:LoadEffectOnEntity(self, "generic0", {Effect = sEffect,CountScale=1,Scale=1}, true)
				end
			end
		end

		if (fUsable ~= 0) then MakeUsable(self) end
		if (fPickable ~= 0) then MakePickable(self) end
		if (fScale > 0) then self:SetScale(fScale) end

		self:Activate(1)
		self:SetUpdatePolicy(ENTITY_UPDATE_VISIBLE)

		if (self.Properties.ServerModel) then
			sObj = self.Properties.ServerModel
		end

		self:LoadObject(0, sObj)
		self:DrawSlot(0, 1)

		if (iPhysics ~= 0) then

			local iPhysType   = PE_STATIC
			local aPhysParams = { mass = fMass, }
			if (fRigid ~= 0) then iPhysType = PE_RIGID end

			self:Physicalize(0, iPhysType, aPhysParams)
			if (fResting ~= 0) then
				self:AwakePhysics(0)
			else
				self:AwakePhysics(1)
			end
		end

		--ServerLog("GUI Spawned. Name is %s", sName)
	end,

	----------------------
	OnPropertyChange = function(self)
		self:OnReset()
	end,

	----------------------
	OnHit = function(self, aHitInfo)
		ServerItemHandler:OnItemHit(self, aHitInfo)
	end,
}
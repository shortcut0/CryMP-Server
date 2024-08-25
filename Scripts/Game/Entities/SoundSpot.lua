SoundSpot = {

	type = "Sound",

	Properties = {
	},

	FlowEvents = {
	},

	Editor = {
	},

	Server = {

		OnInit = function (self)
			ServerLog("SoundSpot.Init()")
			self:SetScriptUpdateRate(1)
			self:NetPresent(0)
		end,

		OnShutDown = function (self) end,
		OnUpdate = function(self)
			SoundSpot.OnUpdate(self)
		end
	},

	Client = {
		OnInit = function(self) end,
		OnShutDown = function(self) end,
		OnSoundDone = function(self) end,
	},

	----------------------
	OnSpawn = function(self)

		self.UpdateTimer = timernew()
		self.SpawnTimer  = timernew()

		self:OnReset()
		self:SetFlags(ENTITY_FLAG_CLIENT_ONLY, 0)
	end,

	----------------------
	OnPropertyChange = function(self)
	end,

	----------------------
	OnUpdate = function(self)

		ServerLog("Updating sound spot... update rate should be 1s.. its %f", self.UpdateTimer.diff())
		if (self.Properties.RemovalTimer) then
			if (self.SpawnTimer.expired()) then
				System.RemoveEntity(self.id)
			end
		end
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

		local sFile 	= (g("File") or "")
		local iAttach 	= (g("Attach", "%d", 1) or 0)
		local sParent 	= (g("To", ".-") or "null")
		local fLifetime = (g("Timer", "%d+", 1) or -1)

		if (iAttach ~= 0) then
			local hParent = System.GetEntityByName(sParent)
			if (hParent) then
				hParent:AttachChild(self.id, 1)
			end
		end

		if (fLifetime > 0) then
			ServerLog("adding removal timer.")
			g_pGame:ScheduleEntityRemoval(self.id, fLifetime)
		end

		-- NOT used on Server!
		self.Properties.sndFile = sFile
	end,
}
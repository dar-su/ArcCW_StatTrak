if CLIENT then
    matproxy.Add({
        name = "StatTrakDigit",

        init = function(self, mat, values)
            self.Digit = values.displaydigit
            self.Number = values.resultvar
        end,
    
        bind = function(self, mat, ent)
            if !IsValid(ent) then return end
            mat:SetInt(self.Number, 0) -- resetting
            
            local wep = ent:GetTable().Weapon
            if !wep then return end

            local killcount = wep:GetNWInt("STKills", 0)
            
            if wep:CheckFlags(_, {"st_global"}) then
                killcount = wep:GetNWInt("STFileKills", 0)
            end

            mat:SetInt(self.Number, tonumber(string.Replace(string.format("%6d", killcount)[6 - self.Digit], " ", "10"))) --calling 10th frame for empty char (titanfall counters)
        end
    })

    net.Receive("arrcwstattracksave", function()
        local oldwep = net.ReadEntity()
        local wep = LocalPlayer():GetActiveWeapon()
        if oldwep and wep!=oldwep then return end

        if !IsValid(wep) or !wep.ArcCW then return end
            
        if file.Exists("arccw_stattrack.json", "DATA") then
		--print("We found a kills file, importing...")
		if !wep.FileKillsTable then
			wep.FileKillsTable = util.JSONToTable(file.Read("arccw_stattrack.json", "DATA") or "") or {}
			wep.FileKills = wep.FileKillsTable[wep:GetClass()] or 0
			wep:SetNWInt("STFileKills", wep.FileKills)
		end
			
		local filekills = net.ReadUInt(20)
		wep.FileKills = filekills
	end

        -- print(wep)
        local curtable = {[wep:GetClass()] = wep:GetNWInt("STFileKills", 0)}
        
        if table.IsEmpty(curtable) then return end

        local content = util.TableToJSON(table.Merge(wep.FileKillsTable or {}, curtable))
    
        -- print("saved to file kills - ", wep:GetNWInt("STFileKills"))
    
        file.Write("arccw_stattrack.json", content)

        timer.Remove(wep:EntIndex() .. "filesaving") -- to be sure
    end)

    concommand.Add("arccw_stattrack_reset", function(ply)
        file.Write("arccw_stattrack.json", "{}")
        print("Okay done")
        
        if IsValid(ply) then
            local wep = ply:GetActiveWeapon()
            if IsValid(wep) then
                wep.FileKills = 0
                net.Start("arrcwstattracksend")
                net.WriteUInt(0, 20)
                net.SendToServer()
            end
        end
    end)
else
    util.AddNetworkString("arrcwstattracksend")
    util.AddNetworkString("arrcwstattracksave")

    local nextfilesave = CurTime()

    local function stkill(attacker)
        if !IsValid(attacker) then return end
        if !attacker:IsPlayer() then return end
        
        local wep = attacker:GetActiveWeapon()
        if !IsValid(wep) then return end
        if !wep.ArcCW then return end
        if wep:CheckFlags(_, {"killcounter"}) then return end
        
        local stkills = wep:GetNWInt("STKills", 0)
        local stfilekills = wep:GetNWInt("STFileKills", wep.FileKills)
        
        wep:SetNWInt("STFileKills", stfilekills+1)
        wep:SetNWInt("STKills", stkills+1)

        timer.Create(wep:EntIndex().."filesaving", 3, 1, function()
            if !wep:IsValid() then return end

            net.Start("arrcwstattracksave")
            net.WriteEntity(wep)
            net.Send(wep:GetOwner())
        end)
    end

    hook.Add("OnNPCKilled", "ArcCWStattrack.KillNPC", function(npc, attacker, inflictor)
        stkill(attacker)
    end)

    hook.Add("PlayerDeath", "ArcCWStattrack.KillPlayer", function(victim, inflictor, attacker)
        stkill(attacker)
    end)

    net.Receive("arrcwstattracksend", function(len, ply)
        local filekills = net.ReadUInt(20)
        local wep = ply:GetActiveWeapon()
        wep.FileKills = filekills
        -- print("recieved some kill from file - ", filekills)
    end)
end

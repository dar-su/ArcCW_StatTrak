att.PrintName = "Pro Screen (Alt)"
att.AbbrevName = "Pro Screen (Alt)"
att.Icon = Material("entities/arccw_proscreen.png", "mips")
att.Description = "Adds a small screen (Pistol size) to the side of the weapon, showing how many player kills you have achieved with this weapon."
att.SortOrder = 1.05

att.Model = "models/weapons/attachments/pro_screen_2.mdl"
att.ModelScale = Vector(1, 1, 1)
att.ModelOffset  = Vector(0, 0, 0)
att.Slot = {"charm", "killcounter"}

att.ToggleLockDefault = true 
att.ToggleStats = {
    {
        PrintName = "Global weapon",
        AutoStatName = "Global weapon",
        GivesFlags = {"st_global"}
    },
    {
        PrintName = "Local weapon",
        AutoStatName = "Local",
        GivesFlags = {"st_local"}
    },
}


-- att.Ignore = true -- WIP

att.Hook_Think = function(wep) 
    -- why there s no hook for att equip?? if it ever going to happen copy function to it from deploy
    if SERVER or !wep:GetOwner():IsPlayer() then return end

    if !wep.FileKillsTable then -- same as below but here 
        wep.FileKillsTable = util.JSONToTable(file.Read("arccw_stattrack.json", "DATA") or "") or {}
        wep.FileKills = wep.FileKillsTable[wep:GetClass()] or 0

        wep:SetNWInt("STFileKills", wep.FileKills)

        net.Start("arrcwstattracksend")
        net.WriteUInt(wep.FileKills, 20)
        net.SendToServer()
    end
end

att.Hook_OnDeploy = function(wep) 
    if SERVER or !wep:GetOwner():IsPlayer() then return end
    -- load from file
    wep.FileKillsTable = util.JSONToTable(file.Read("arccw_stattrack.json", "DATA") or "") or {}
    wep.FileKills = wep.FileKillsTable[wep:GetClass()] or 0

    wep:SetNWInt("STFileKills", wep.FileKills)

    net.Start("arrcwstattracksend")
    net.WriteUInt(wep.FileKills, 20)
    net.SendToServer()

    -- wep:SetNWInt("STFileKills", wep.FileKills)
end

att.Hook_OnHolster = function(wep) 
    if CLIENT or !wep:GetOwner():IsPlayer() then return end
    -- save in file
    net.Start("arrcwstattracksave")
    net.WriteEntity(wep)
    net.Send(wep:GetOwner())
    

    -- local curtable = {[wep:GetClass()] = wep:GetNWInt("STFileKills") or 777}

    -- local content = util.TableToJSON(table.Merge(wep.FileKillsTable or {}, curtable))

    -- file.Write("arccw_stattrack.json", content)
    -- print("hi!!")
end
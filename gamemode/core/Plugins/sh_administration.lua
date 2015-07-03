if SERVER and UseAdministration then
	util.AddNetworkString( "Ball" )
	net.Receive( "Ball", function( len, ply )
		if !ply or !ply:IsAdmin() then return end
		local Command = net.ReadString()
		if !Command then return end
		if Command == "win" then
			local Team = net.ReadFloat()
			if !Team then return end
			if SERVER and GameStatus == 0 then team.SetScore( Team, ( WinningScore * (#player.GetAll() or 1)) ) end
		end
		if Command == "kick" then
			local ForRemoval = net.ReadEntity()
			local Reason = net.ReadString() or "Goodbye"
			if Reason == "" then Reason = "Goodbye" end
			if !ForRemoval then return end
			ForRemoval.Kicked = true
			if SERVER then ForRemoval:Kick( Reason or "Goodbye" ) end
		end
		if Command == "ban" then
			local ForRemoval = net.ReadEntity()
			local Time = net.ReadFloat() or 0
			if !ForRemoval then return end
			ForRemoval.Kicked = true
			if SERVER then if ForRemoval:IsBot() then ForRemoval:Kick( "Ban Test" ) else ForRemoval:Ban( Time or 0, true ) end end
		end
		if Command == "hurt" then
			local ForHurt = net.ReadEntity()
			if !ForHurt then return end
			if SERVER then
				local effect = EffectData()
				effect:SetStart(ForHurt:GetPos())
				effect:SetOrigin(ForHurt:GetPos())
				effect:SetScale(0.1)
				util.Effect("Explosion",effect)
				ForHurt:TakeDamage( 1000, ply, ply )
			end
		end
		if Command == "addbot" then
			if SERVER then
				if ( !game.SinglePlayer() ) then
					if Bot_UseNextBotSystem and Ai_Enabled then
						player.CreateNextBot( table.Random(Ai_Names) )
					else
						ply:ConCommand( "bot" )
					end
				else
					ply:ChatPrint( "Can't create a bot in single-player." )
				end
			end
		end 
	end )
end
if CLIENT then
	local function ShowAdminMenu()
		if LocalPlayer():IsAdmin() then
			local ContextMenu = DermaMenu()
			for t,_ in pairs(team.GetAllTeams()) do
				if Teams[t] then
					ContextMenu:AddOption("Force "..Teams[t].Name.." Win", function()
						net.Start("Ball")
								net.WriteString("win")
								net.WriteFloat(t)
						net.SendToServer()
					end ):SetIcon( "icon16/rosette.png" )
				end
			end
			ContextMenu:AddSpacer()
			if ( !game.SinglePlayer() ) then
				ContextMenu:AddOption("Add Bot", function()
					net.Start("Ball")
							net.WriteString("addbot")
					net.SendToServer()
				end ):SetIcon( "icon16/tux.png" )
				ContextMenu:AddSpacer()
			end
			local PlayersMenu
			if #player.GetAll() > 1 then PlayersMenu = ContextMenu:AddSubMenu( "Player Administration" ) end
			for k,v in pairs(player.GetAll()) do
				if PlayersMenu and v != LocalPlayer() then
					local PlayerMenu = PlayersMenu:AddSubMenu( v:Nick() )
					PlayerMenu:AddOption("Kick Player", function()
						Derma_StringRequest(
							"Kicking Player",
							"Reason?",
							"GoodBye",
							function( text )
								net.Start("Ball")
										net.WriteString("kick")
										net.WriteEntity(v)
										net.WriteString(text or "")
								net.SendToServer()
							end,
							function( text ) return end
						 )

					end ):SetIcon( "icon16/user_delete.png" )
					PlayerMenu:AddOption("Ban Player", function()
						Derma_StringRequest(
							"Banning Player",
							"Time to ban (minutes):",
							"60",
							function( text )
								net.Start("Ball")
										net.WriteString("ban")
										net.WriteEntity(v)
										net.WriteFloat(tonumber(text) or 0)
								net.SendToServer()
							end,
							function( text ) return end
						 )

					end ):SetIcon( "icon16/exclamation.png" )
					PlayerMenu:AddOption("Punish", function()
						net.Start("Ball")
							net.WriteString("hurt")
							net.WriteEntity(v)
						net.SendToServer()
					end ):SetIcon( "icon16/bomb.png" )
				end
			end
			ContextMenu:Open()
			ContextMenu:Open()
		end
	end
	concommand.Add( "admin", ShowAdminMenu)
end
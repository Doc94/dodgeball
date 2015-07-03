Game = {}
Game.FirstRound = true
Game.Status = function(self)
	return GameStatus
end
Game.Prepare = function(self)
	for t,_ in pairs(team.GetAllTeams()) do
		team.SetScore( t, 0 )
	end
	if SERVER then
		if UseAnnouncer then Announcer:Play("dodgeball/announcer/4sec.mp3") end
		for _,v in pairs(player.GetAll()) do
			if v:Team() and v:Team() != TEAM_SPECTATOR and v:Team() != TEAM_UNASSIGNED  and v:Team() != 0 then
				v:ChatPrint( "New Round Starting!" )
				v:Spawn()
				v:Freeze(true)
			end
		end
	end
end
Game.Start = function(self)
	Game.Timer = CurTime() + RoundTimer or 300
	GameStatus = 0
	if Game.FirstRound then Game.FirstRound = false end
	if SERVER then
		FirstBlood = false
		Announcer:Play("dodgeball/effects/horn.mp3")
		for _,v in pairs(player.GetAll()) do
			if v:Team() and v:Team() != TEAM_SPECTATOR and v:Team() != TEAM_UNASSIGNED  and v:Team() != 0 then
				v:ChatPrint( "Fight!" )
				v:Freeze(false)
			end
		end
	end
end
Game.New = function(self)
	if SERVER then
		if UseAnnouncer then Announcer:Play("dodgeball/announcer/10sec.mp3") end
		for _,v in pairs(player.GetAll()) do
			v:ChatPrint( "New round begins in 10 seconds." )
		end
	end
	timer.Simple( 10, function()
		Game:Prepare()
		timer.Simple( 4.5, function()
			Game:Start()
		end )
	end )
end
Game.Finish = function(self, winner)
	Game.Timer = 0
	if SERVER then
		if winner then
			for _,v in pairs(player.GetAll()) do
				if Teams[winner] then
					v:ChatPrint( "Team "..Teams[winner].Name.." Wins!" )
					if winner == v:Team() then
						if UseAnnouncer then Announcer:Play("dodgeball/music/win.mp3", v) end
						if UseAnnouncer then Announcer:Play("dodgeball/announcer/victory.mp3", v) end
					else
						if UseAnnouncer then Announcer:Play("dodgeball/music/loose.mp3", v) end
						if UseAnnouncer then Announcer:Play("dodgeball/announcer/defeat.mp3", v) end
					end
				end
			end
		else
			for _,v in pairs(player.GetAll()) do
				v:ChatPrint( "Draw!" )
			end
		end
		for _,v in pairs(player.GetAll()) do
			v:Freeze(true)
			v:StripWeapons()
			v:StripAmmo()
			timer.Simple( 5, function()
				if v and IsValid(v) then
					v:KillSilent()
					v:Spectate( OBS_MODE_ROAMING )
					v:Freeze(false)
				end
			end )
		end
	end
	if !Game.FirstRound and UseMapVote and MapList and #MapList > 1 then
		if SERVER then MapVote:Start() end
	else
		timer.Simple( AfterRoundWait or 20, function()
			Game:New()
		end )
	end
end

function GM:Think()
	if Game:Status() == 0 then
		local winner = false
		for t,_ in pairs(team.GetAllTeams()) do
			if team.GetScore( t ) >= ( WinningScore * (#player.GetAll() or 1)) then
				winner = t
				break
			end
		end
		if winner then
			GameStatus = 1
			Announcer:Play("dodgeball/effects/horn.mp3")
			timer.Simple( 1, function()
				Game:Finish(winner)
			end)
		elseif (CurTime()>=(Game.Timer or 0)) then
			if team.GetScore( 1 ) > team.GetScore( 2 ) then winner = 1 end
			if team.GetScore( 2 ) > team.GetScore( 1 ) then winner = 2 end
			GameStatus = 1
			Announcer:Play("dodgeball/effects/horn.mp3")
			timer.Simple( 1, function()
				Game:Finish(winner or false)
			end)
		end
	end
end
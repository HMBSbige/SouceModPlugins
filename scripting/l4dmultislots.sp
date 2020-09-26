/************************************************
* Plugin name:		[L4D(2)] MultiSlots
* Plugin author:	SwiftReal, Harry Potter
* 
* Based upon:
* - (L4D) Zombie Havoc by Bigbuck
* - (L4D2) Bebop by frool
************************************************/

#include <sourcemod>
#include <sdktools>
#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION 				"2.4"
#define CVAR_FLAGS					FCVAR_NOTIFY
#define DELAY_KICK_FAKECLIENT 		0.1
#define DELAY_KICK_NONEEDBOT 		5.0
#define DELAY_KICK_NONEEDBOT_SAFE   30.0
#define DELAY_CHANGETEAM_NEWPLAYER 	1.5
#define TEAM_SPECTATORS 			1
#define TEAM_SURVIVORS 				2
#define TEAM_INFECTED				3
#define DAMAGE_EVENTS_ONLY			1
#define	DAMAGE_YES					2

ConVar hMaxSurvivors;
ConVar hTime;
int iMaxSurvivors,iTime;
bool L4D2Version;
char gMapName[128];
static Handle hSetHumanSpec;
static Handle hTakeOver;
int g_iRoundStart,g_iPlayerSpawn ;
bool bKill, bLeftSafeRoom, bFinalHasStart;
Handle timer_SpecCheck = null;
Handle PlayerLeftStartTimer = null;

public Plugin myinfo = 
{
	name 			= "[L4D(2)] MultiSlots",
	author 			= "SwiftReal, MI 5, HarryPotter",
	description 	= "Allows additional survivor players in coop, versus, and survival",
	version 		= PLUGIN_VERSION,
	url 			= "https://steamcommunity.com/id/TIGER_x_DRAGON/"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) 
{
	EngineVersion test = GetEngineVersion();
	
	if( test == Engine_Left4Dead ) L4D2Version = false;
	else if( test == Engine_Left4Dead2 ) L4D2Version = true;
	else
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}
	
	return APLRes_Success; 
}

public void OnPluginStart()
{
	// Register commands
	RegAdminCmd("sm_addbot", AddBot, ADMFLAG_KICK, "Attempt to add a survivor bot");
	RegConsoleCmd("sm_join", JoinTeam, "Attempt to join Survivors");
	
	// Register cvars
	hMaxSurvivors	= CreateConVar("l4d_multislots_max_survivors", "4", "Kick Fake Survivor bots if numbers of survivors reach the certain value (does not kick real player)", CVAR_FLAGS, true, 0.0, true, 32.0);
	hTime = CreateConVar("l4d_multislots_time", "120", "Spawn a dead survivor bot after a certain time round starts [0: Disable]", CVAR_FLAGS, true, 0.0);
	
	GetCvars();
	hMaxSurvivors.AddChangeHook(ConVarChanged_Cvars);
	hTime.AddChangeHook(ConVarChanged_Cvars);
	
	// Hook events

	HookEvent("survivor_rescued", evtSurvivorRescued);
	HookEvent("player_activate", evtPlayerActivate);
	HookEvent("player_bot_replace", evtBotReplacedPlayer);
	HookEvent("player_team", evtPlayerTeam, EventHookMode_Pre);
	HookEvent("player_spawn", evtPlayerSpawn);
	HookEvent("player_death", evtPlayerDeath);
	HookEvent("round_start", 		Event_RoundStart);
	HookEvent("round_end",			Event_RoundEnd,		EventHookMode_PostNoCopy);
	HookEvent("map_transition", Event_RoundEnd);
	HookEvent("mission_lost", Event_RoundEnd);
	HookEvent("finale_vehicle_leaving", Event_RoundEnd);
	HookEvent("finale_vehicle_leaving", evtFinaleVehicleLeaving);
	HookEvent("finale_start", OnFinaleStart_Event, EventHookMode_PostNoCopy);

	// Create or execute plugin configuration file
	AutoExecConfig(true, "l4dmultislots");

	// ======================================
	// Prep SDK Calls
	// ======================================

	Handle hGameConf;	
	hGameConf = LoadGameConfigFile("l4dmultislots");
	if(hGameConf == null)
	{
		SetFailState("Gamedata l4dmultislots.txt not found");
		return;
	}
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "SetHumanSpec");
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	hSetHumanSpec = EndPrepSDKCall();
	if (hSetHumanSpec == null)
	{
		SetFailState("Cant initialize SetHumanSpec SDKCall");
		return;
	}
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "TakeOverBot");
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
	hTakeOver = EndPrepSDKCall();
	if( hTakeOver == null)
	{
		SetFailState("Could not prep the \"TakeOverBot\" function.");
		return;
	}
	delete hGameConf;
}

public void OnPluginEnd()
{
	ClearDefault();
	ResetTimer();
}

public void OnMapStart()
{
	GetCurrentMap(gMapName, sizeof(gMapName));
	TweakSettings();
}

public void OnMapEnd()
{
	ClearDefault();
	ResetTimer();
}

public void ConVarChanged_Cvars(Handle convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	iMaxSurvivors = hMaxSurvivors.IntValue;
	iTime = hTime.IntValue;
}

////////////////////////////////////
// Callbacks
////////////////////////////////////
public Action AddBot(int client, int args)
{
	if(client == 0)
		return Plugin_Continue;
	
	if(SpawnFakeClient())
		PrintToChat(client,"BOT 已生成");
	
	return Plugin_Handled;
}

public Action JoinTeam(int client,int args)
{
	if(!IsClientConnected(client) || !IsClientInGame(client))
		return Plugin_Handled;

	if(GetClientTeam(client) == TEAM_INFECTED)
	{
		ChangeClientTeam(client, TEAM_SPECTATORS);
		CreateTimer(1.0, Timer_AutoJoinTeam, GetClientUserId(client));	
		return Plugin_Handled;
	}

	if(GetClientTeam(client) == TEAM_SURVIVORS)
	{	
		if(DispatchKeyValue(client, "classname", "player") == true)
		{
			PrintHintText(client, "你已经是生还者！");
		}
		else if((DispatchKeyValue(client, "classname", "info_survivor_position") == true) && !IsAlive(client))
		{
			PrintHintText(client, "请等待救援或复活！");
		}
	}
	else if(IsClientIdle(client))
	{
		PrintHintText(client, "点击鼠标成为生还者");
	}
	else
	{			
		if(TotalAliveFreeBots() == 0)
		{
			if(bKill && iTime > 0) 
			{
				if(bFinalHasStart) //don't let player die in saferoom after final starts, this prevents some issue in final map
				{
					SpawnFakeClient();
					CreateTimer(0.5, Timer_TakeOverBotAndDie, GetClientUserId(client));
				}
				else
				{
					ChangeClientTeam(client, TEAM_SURVIVORS);
					CreateTimer(0.1, Timer_KillSurvivor, client);
				}
			}
			else 
			{
				SpawnFakeClient();
				CreateTimer(0.5, Timer_AutoJoinTeam, GetClientUserId(client))	;			
			}
		}
		else
		{
			TakeOverBot(client);
		}
	}
	return Plugin_Handled;
}
////////////////////////////////////
// Events
////////////////////////////////////
public void evtPlayerActivate(Event event, const char[] name, bool dontBroadcast) 
{
	int userid = event.GetInt("userid");
	int client = GetClientOfUserId(userid);
	if(client)
	{
		if((GetClientTeam(client) != TEAM_INFECTED) && (GetClientTeam(client) != TEAM_SURVIVORS) && !IsFakeClient(client) && !IsClientIdle(client))
			CreateTimer(DELAY_CHANGETEAM_NEWPLAYER, Timer_AutoJoinTeam, userid);
	}
}

public void evtPlayerTeam(Event event, const char[] name, bool dontBroadcast) 
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	int oldteam = event.GetInt("oldteam");
	
	if(oldteam == 1 || event.GetBool("disconnect"))
	{
		if(IsClientInGame(client) && !IsFakeClient(client) && GetClientTeam(client) == 1)
		{
			for(int i = 1; i <= MaxClients; i++)
			{
				if(IsClientConnected(i) && IsClientInGame(i) && IsFakeClient(i) && GetClientTeam(i) == TEAM_SURVIVORS && IsAlive(i))
				{
					if(HasEntProp(i, Prop_Send, "m_humanSpectatorUserID"))
					{
						if(GetClientOfUserId(GetEntProp(i, Prop_Send, "m_humanSpectatorUserID")) == client)
						{
							//LogMessage("afk player %N changes team or leaves the game, his bot is %N",client,i);
							if(!bLeftSafeRoom)
								CreateTimer(DELAY_KICK_NONEEDBOT_SAFE, Timer_KickNoNeededBot, GetClientUserId(i));
							else
								CreateTimer(DELAY_KICK_NONEEDBOT, Timer_KickNoNeededBot, GetClientUserId(i));
						}
					}
				}
			}
		}
	}
}

public void evtSurvivorRescued(Event event, const char[] name, bool dontBroadcast) 
{
	int client = GetClientOfUserId(event.GetInt("victim"));
	if(client)
	{	
		StripWeapons(client);
		//BypassAndExecuteCommand(client, "give", "pistol_magnum");
		GiveWeapon(client);
	}
}

public void evtFinaleVehicleLeaving(Event event, const char[] name, bool dontBroadcast) 
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsClientConnected(i) && IsClientInGame(i))
		{
			if((GetClientTeam(i) == TEAM_SURVIVORS) && IsAlive(i))
			{
				SetEntProp(i, Prop_Data, "m_takedamage", DAMAGE_EVENTS_ONLY, 1);
				float newOrigin[3] = { 0.0, 0.0, 0.0 };
				TeleportEntity(i, newOrigin, NULL_VECTOR, NULL_VECTOR);
				SetEntProp(i, Prop_Data, "m_takedamage", DAMAGE_YES, 1);
			}
		}
	}	
}

public void evtBotReplacedPlayer(Event event, const char[] name, bool dontBroadcast) 
{
	int fakebotid = event.GetInt("bot");
	int fakebot = GetClientOfUserId(fakebotid);
	if(fakebot && GetClientTeam(fakebot) == TEAM_SURVIVORS && IsFakeClient(fakebot))
	{
		if(!bLeftSafeRoom)
			CreateTimer(DELAY_KICK_NONEEDBOT_SAFE, Timer_KickNoNeededBot, fakebotid);
		else
			CreateTimer(DELAY_KICK_NONEEDBOT, Timer_KickNoNeededBot, fakebotid);
	}
}

public void evtPlayerSpawn(Event event, const char[] name, bool dontBroadcast) 
{
	int userid = event.GetInt("userid");
	int client = GetClientOfUserId(userid);
	if(client && GetClientTeam(client) == TEAM_SURVIVORS && IsFakeClient(client))
	{
		if(!bLeftSafeRoom)
			CreateTimer(DELAY_KICK_NONEEDBOT_SAFE, Timer_KickNoNeededBot, userid);
		else
			CreateTimer(DELAY_KICK_NONEEDBOT, Timer_KickNoNeededBot, userid);
	}

	if( g_iPlayerSpawn == 0 && g_iRoundStart == 1 )
		CreateTimer(0.5, PluginStart);
	g_iPlayerSpawn = 1;	
}

public void evtPlayerDeath(Event event, const char[] name, bool dontBroadcast) 
{
	int userid = event.GetInt("userid");
	int client = GetClientOfUserId(userid);
	if(client && GetClientTeam(client) == TEAM_SURVIVORS && IsFakeClient(client))
	{
		if(!bLeftSafeRoom)
			CreateTimer(DELAY_KICK_NONEEDBOT_SAFE, Timer_KickNoNeededBot, userid);
		else
			CreateTimer(DELAY_KICK_NONEEDBOT, Timer_KickNoNeededBot, userid);
	}	
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	ClearDefault();
	ResetTimer();
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	bFinalHasStart = false;
	if( g_iPlayerSpawn == 1 && g_iRoundStart == 0 )
		CreateTimer(0.5, PluginStart);
	g_iRoundStart = 1;
}

public Action OnFinaleStart_Event(Event event, const char[] name, bool dontBroadcast)
{
	bFinalHasStart = true;
}
////////////////////////////////////
// timers
////////////////////////////////////

int iCountDownTime;
public Action PluginStart(Handle timer)
{
	ClearDefault();
	iCountDownTime = iTime;
	if(iCountDownTime > 0) CreateTimer(1.0, CountDown,_,TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	if(PlayerLeftStartTimer == null) PlayerLeftStartTimer = CreateTimer(1.0, PlayerLeftStart, _, TIMER_REPEAT);
	if(timer_SpecCheck == null) timer_SpecCheck = CreateTimer(15.0, Timer_SpecCheck, _, TIMER_REPEAT)	;
}

public Action CountDown(Handle timer)
{
	if(iCountDownTime <= 0) 
	{
		bKill = true;
		return Plugin_Stop;
	}
	iCountDownTime--;
	return Plugin_Continue;
}

public Action Timer_SpecCheck(Handle timer)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsClientConnected(i) && IsClientInGame(i))
		{
			if((GetClientTeam(i) == TEAM_SPECTATORS) && !IsFakeClient(i))
			{
				if(!IsClientIdle(i))
				{
					char PlayerName[100];
					GetClientName(i, PlayerName, sizeof(PlayerName))		;
					PrintToChat(i, "\x01[\x04MultiSlots\x01] %s, 输入 \x03!join\x01 加入生还者", PlayerName);
				}
			}
		}
	}	
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsClientConnected(i) && IsClientInGame(i))		
		{
			if((GetClientTeam(i) == TEAM_SURVIVORS) && !IsFakeClient(i) && !IsAlive(i))
			{
				char PlayerName[100];
				GetClientName(i, PlayerName, sizeof(PlayerName));
				PrintToChat(i, "\x01[\x04MultiSlots\x01] %s, 请等待救援或复活", PlayerName);
			}
		}
	}	
	return Plugin_Continue;
}

public Action Timer_KillSurvivor(Handle timer, int client)
{
	if(client && IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client))
	{
		StripWeapons(client);
		ForcePlayerSuicide(client);
	}
}

public Action Timer_TakeOverBotAndDie(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if (!client || !IsClientInGame(client)) return;
	if (GetClientTeam(client) == TEAM_SURVIVORS) return;
	if (IsFakeClient(client)) return;

	int fakebot = FindBotToTakeOver(true);
	if (fakebot == 0)
	{
		PrintHintText(client, "无 BOT 可接管");
		return;
	}

	SDKCall(hSetHumanSpec, fakebot, client);
	SDKCall(hTakeOver, client, true);
	CreateTimer(0.1, Timer_KillSurvivor, client);
}

public Action Timer_AutoJoinTeam(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);

	if(!client || !IsClientConnected(client) || !IsClientInGame(client))
		return;
	
	if(GetClientTeam(client) == TEAM_SURVIVORS)
		return;
	
	if(IsClientIdle(client))
		return;
	
	JoinTeam(client, 0);
}

public Action Timer_KickNoNeededBot(Handle timer, int botid)
{
	int botclient = GetClientOfUserId(botid);

	if((TotalSurvivors() <= iMaxSurvivors))
		return Plugin_Handled;
	
	if(botclient && IsClientConnected(botclient) && IsClientInGame(botclient) && IsFakeClient(botclient))
	{
		if(GetClientTeam(botclient) != TEAM_SURVIVORS)
			return Plugin_Handled;
		
		char BotName[100];
		GetClientName(botclient, BotName, sizeof(BotName))	;			
		if(StrEqual(BotName, "FakeClient", true))
			return Plugin_Handled;
		
		if(!HasIdlePlayer(botclient))
		{
			//StripWeapons(botclient);
			KickClient(botclient, "踢出多余 BOT");
		}
	}	
	return Plugin_Handled;
}

public Action Timer_KickFakeBot(Handle timer, int fakeclient)
{
	if(IsClientConnected(fakeclient))
	{
		KickClient(fakeclient, "你可能是个 BOT")	;	
		return Plugin_Stop;
	}	
	return Plugin_Continue;
}
////////////////////////////////////
// stocks
////////////////////////////////////
void ClearDefault()
{
	g_iRoundStart = 0;
	g_iPlayerSpawn = 0;
	bKill = false;
	bLeftSafeRoom = false;
}


stock void TweakSettings()
{
	Handle hMaxSurvivorsLimitCvar = FindConVar("survivor_limit");
	SetConVarBounds(hMaxSurvivorsLimitCvar,  ConVarBound_Lower, true, 4.0);
	SetConVarBounds(hMaxSurvivorsLimitCvar, ConVarBound_Upper, true, 32.0);
	SetConVarInt(hMaxSurvivorsLimitCvar, iMaxSurvivors);
	
	SetConVarInt(FindConVar("z_spawn_flow_limit"), 50000) ;// allow spawning bots at any time
}

stock void TakeOverBot(int client)
{
	if (!IsClientInGame(client)) return;
	if (GetClientTeam(client) == TEAM_SURVIVORS) return;
	if (IsFakeClient(client)) return;

	int fakebot = FindBotToTakeOver(true);
	if (fakebot == 0)
	{
		PrintHintText(client, "无 BOT 可接管");
		return;
	}

	if(IsPlayerAlive(fakebot))
	{
		SDKCall(hSetHumanSpec, fakebot, client);
		SetEntProp(client, Prop_Send, "m_iObserverMode", 5);
	}

	return;
}

stock int FindBotToTakeOver(bool alive)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsClientConnected(i))
		{
			if(IsClientInGame(i))
			{
				if (IsFakeClient(i) && GetClientTeam(i)==TEAM_SURVIVORS && !HasIdlePlayer(i) && IsPlayerAlive(i) == alive)
					return i;
			}
		}
	}
	return 0;
}


stock void SetEntityTempHealth(int client, int hp)
{
	SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
	float newOverheal = hp * 1.0; // prevent tag mismatch
	SetEntPropFloat(client, Prop_Send, "m_healthBuffer", newOverheal);
}

stock void BypassAndExecuteCommand(int client, char[] strCommand, char[] strParam1)
{
	int flags = GetCommandFlags(strCommand);
	SetCommandFlags(strCommand, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", strCommand, strParam1);
	SetCommandFlags(strCommand, flags);
}

stock void StripWeapons(int client) // strip primary and second weapon from client
{
	int itemIdx;
	for (int x = 0; x <= 1; x++)
	{
		if((itemIdx = GetPlayerWeaponSlot(client, x)) != -1)
		{  
			RemovePlayerItem(client, itemIdx);
			AcceptEntityInput(itemIdx, "Kill");
		}
	}
}

stock void GiveWeapon(int client) // give client random weapon
{
	BypassAndExecuteCommand(client, "give", "pistol");
	int random;
	if(L4D2Version) random = GetRandomInt(1,4);
	else random = GetRandomInt(1,2);
	switch(random)
	{
		case 1: BypassAndExecuteCommand(client, "give", "smg");
		case 2: BypassAndExecuteCommand(client, "give", "pumpshotgun");
		case 3: BypassAndExecuteCommand(client, "give", "smg_silenced");
		case 4: BypassAndExecuteCommand(client, "give", "shotgun_chrome");
	}	
	BypassAndExecuteCommand(client, "give", "ammo");
}

stock void GiveMedkit(int client)
{
	int ent = GetPlayerWeaponSlot(client, 3);
	if(IsValidEdict(ent))
	{
		char sClass[128];
		GetEdictClassname(ent, sClass, sizeof(sClass));
		if(!StrEqual(sClass, "weapon_first_aid_kit", false))
		{
			RemovePlayerItem(client, ent);
			AcceptEntityInput(ent, "Kill");
			BypassAndExecuteCommand(client, "give", "first_aid_kit");
		}
	}
	else
	{
		BypassAndExecuteCommand(client, "give", "first_aid_kit");
	}
}

stock int TotalSurvivors() // total bots, including players
{
	int kk = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsClientConnected(i))
		{
			if(IsClientInGame(i) && (GetClientTeam(i) == TEAM_SURVIVORS))
				kk++;
		}
	}
	return kk;
}

stock int HumanConnected()
{
	int kk = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsClientConnected(i) && IsClientInGame(bot))
		{
			if(!IsFakeClient(i))
				kk++;
		}
	}
	return kk;
}

stock int TotalAliveFreeBots() // total bots (excl. IDLE players)
{
	int kk = 0;
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientConnected(i) && IsClientInGame(i))
		{
			if(IsFakeClient(i) && GetClientTeam(i)==TEAM_SURVIVORS && IsAlive(i))
			{
				if(!HasIdlePlayer(i))
					kk++;
			}
		}
	}
	return kk;
}

stock void ResetTimer()
{
	if(timer_SpecCheck != INVALID_HANDLE)
	{
		KillTimer(timer_SpecCheck);
		timer_SpecCheck = INVALID_HANDLE;
	}
	if(PlayerLeftStartTimer != null)
	{
		KillTimer(PlayerLeftStartTimer);
		PlayerLeftStartTimer = null;	
	}
}
////////////////////////////////////
// bools
////////////////////////////////////
bool SpawnFakeClient()
{
	bool fakeclientKicked = false;
	
	// create fakeclient
	int fakeclient = CreateFakeClient("FakeClient");
	
	// if entity is valid
	if(fakeclient != 0)
	{
		// move into survivor team
		ChangeClientTeam(fakeclient, TEAM_SURVIVORS);
		
		// check if entity classname is survivorbot
		if(DispatchKeyValue(fakeclient, "classname", "survivorbot") == true)
		{
			// spawn the client
			if(DispatchSpawn(fakeclient) == true)
			{
				// teleport client to the position of any active alive player
				for (int i = 1; i <= MaxClients; i++)
				{
					if(IsClientInGame(i) && (GetClientTeam(i) == TEAM_SURVIVORS) && IsAlive(i) && i != fakeclient)
					{						
						// get the position coordinates of any active alive player
						float teleportOrigin[3];
						GetClientAbsOrigin(i, teleportOrigin)	;			
						TeleportEntity(fakeclient, teleportOrigin, NULL_VECTOR, NULL_VECTOR);						
						break;
					}
				}
				
				StripWeapons(fakeclient);
				//BypassAndExecuteCommand(fakeclient, "give", "pistol_magnum");
				GiveWeapon(fakeclient);

				// kick the fake client to make the bot take over
				CreateTimer(DELAY_KICK_FAKECLIENT, Timer_KickFakeBot, fakeclient, TIMER_REPEAT);
				fakeclientKicked = true;
			}
		}	

		// if something went wrong, kick the created FakeClient
		if(fakeclientKicked == false)
			KickClient(fakeclient, "Kicking FakeClient");
	}	
	return fakeclientKicked;
}

bool HasIdlePlayer(int bot)
{
	if(IsClientConnected(bot) && IsClientInGame(bot) && IsFakeClient(bot) && GetClientTeam(bot) == 2 && IsAlive(bot))
	{
		if(HasEntProp(bot, Prop_Send, "m_humanSpectatorUserID"))
		{
			int client = GetClientOfUserId(GetEntProp(bot, Prop_Send, "m_humanSpectatorUserID"))	;		
			if(client > 0 && client <= MaxClients && IsClientInGame(client) && !IsFakeClient(client) && IsClientObserver(client))
			{
				return true;
			}
		}
	}
	return false;
}

bool IsClientIdle(int client)
{
	if(GetClientTeam(client) != 1)
		return false;
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientConnected(i) && IsClientInGame(i) && IsFakeClient(i) && GetClientTeam(i) == TEAM_SURVIVORS && IsAlive(i))
		{
			if(HasEntProp(i, Prop_Send, "m_humanSpectatorUserID"))
			{
				if(GetClientOfUserId(GetEntProp(i, Prop_Send, "m_humanSpectatorUserID")) == client)
						return true;
			}
		}
	}
	return false;
}

bool IsAlive(int client)
{
	if(!GetEntProp(client, Prop_Send, "m_lifeState"))
		return true;
	
	return false;
}

public Action PlayerLeftStart(Handle Timer)
{
	if (LeftStartArea() || bLeftSafeRoom)
	{	
		bLeftSafeRoom = true;
		PlayerLeftStartTimer = null;
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

bool LeftStartArea()
{
	int ent = -1, maxents = GetMaxEntities();
	for (int i = MaxClients+1; i <= maxents; i++)
	{
		if (IsValidEntity(i))
		{
			char netclass[64];
			GetEntityNetClass(i, netclass, sizeof(netclass));
			
			if (StrEqual(netclass, "CTerrorPlayerResource"))
			{
				ent = i;
				break;
			}
		}
	}
	
	if (ent > -1)
	{
		if (GetEntProp(ent, Prop_Send, "m_hasAnySurvivorLeftSafeArea"))
		{
			return true;
		}
	}
	return false;
}
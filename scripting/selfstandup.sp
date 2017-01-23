/*
v0.0.1	- small HP bug during trying to break free from SI.
v0.0.2	- fixed required item to break free is not working when message is turning off.
v0.0.3	- break free and get up message is separated.
		- added Special Infected dead check.
		- added pounce_end event check.
		- add check to prevent player to get up if close to tank.
		- add cvar on last life color.
		- add cvar update upon cvar changed.
		- code clean up.
*/

#define PLUGIN_VERSION	"0.0.3"
#include <sourcemod>
#include <sdktools>

public Plugin:myinfo = 
{
	name			= "[L4D, L4D2] Self Get Up",
	author			= " GsiX ",
	description		= "Self help from incap, ledge grabs, and break free from infected attacks",
	version			= PLUGIN_VERSION,
	url				= "https://forums.alliedmods.net/showthread.php?t=195623"	
}
#define	PLUGIN_FCVAR		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY
#define GAME_DATA			"l4d2_selfstandup"
#define SOUND_KILL1			"/weapons/knife/knife_hitwall1.wav"
#define SOUND_KILL2			"/weapons/knife/knife_deploy.wav"
#define SOUND_HEART_BEAT	"player/heartbeatloop.wav"
#define SOUND_GETUP			"ui/bigreward.wav"
#define SOUND_ERROR			"ui/beep_error01.wav"

#define INCAP				1
#define INCAP_LEDGE			2

#define STATE_NONE			0
#define STATE_SELFGETUP		1

#define NONE_F				0.0
#define NONE				0
#define SMOKER				1
#define HUNTER				3
#define JOCKEY				5
#define CHARGER				6
#define TANK				8

new Handle:selfstandup_enable				= INVALID_HANDLE;
new Handle:selfstandup_blackwhite			= INVALID_HANDLE;
new Handle:selfstandup_kill					= INVALID_HANDLE;
new Handle:selfstandup_health_incap			= INVALID_HANDLE;
new Handle:selfstandup_duration				= INVALID_HANDLE;
new Handle:selfstandup_crawl				= INVALID_HANDLE;
new Handle:selfstandup_crawl_speed			= INVALID_HANDLE;
new Handle:selfstandup_message				= INVALID_HANDLE;
new Handle:selfstandup_costly				= INVALID_HANDLE;
new Handle:selfstandup_costly_item			= INVALID_HANDLE;
new Handle:selfstandup_clearance			= INVALID_HANDLE;
new Handle:selfstandup_teamdistance			= INVALID_HANDLE;
new Handle:selfstandup_color				= INVALID_HANDLE;

new Handle:Timers[MAXPLAYERS+1]				= { INVALID_HANDLE, ... };
new Float:ReviveHealthBuff[MAXPLAYERS+1]	= { 0.0, ... };
new TeamHealth[MAXPLAYERS+1]				= { 0, ... };
new Float:TeamHealthBuff[MAXPLAYERS+1]		= { 0.0, ... };
new Float:StartTime[MAXPLAYERS+1]			= { 0.0, ... };
new Float:Duration[MAXPLAYERS+1]			= { 0.0, ... };
new bool:Restart[MAXPLAYERS+1]				= { false, ... };
new bool:Button[MAXPLAYERS+1]				= { false, ... };
new RevHelper[MAXPLAYERS+1]					= { 0, ... };
new Attacker[MAXPLAYERS+1]					= { 0, ... };
new HelpState[MAXPLAYERS+1]					= { 0, ... };
new ReviveHealth[MAXPLAYERS+1]				= { 0, ... };
new TargetTeam[MAXPLAYERS+1]				= { 0, ... };
new RevCount[MAXPLAYERS+1]					= { 0, ... };
new PlayerWeaponSlot[MAXPLAYERS+1]			= { -1, ... };
new String:Gauge1[2] = "-";
new String:Gauge3[2] = "#";

new bool:g_Pills					= false;
new bool:g_Adrenaline				= false;
new bool:g_Med_Kit					= false;
new bool:g_Defibrillator			= false;
new bool:g_Incendiary				= false;
new bool:g_Explosive				= false;

new g_enable						= 0;
new g_blackwhite					= 0;
new g_kill							= 0;
new Float:g_health_incap			= 0.0;
new Float:g_duration				= 0.0;
new g_message						= 0;
new g_costly						= 0;
new String:g_costly_item[256]		= " ";
new Float:g_clearance				= 0.0;
new Float:g_teamdistance			= 0.0;
new g_lastlifecolor					= 0;


public OnPluginStart()
{
	CreateConVar("selfstandup_version", PLUGIN_VERSION, " ", FCVAR_PLUGIN|FCVAR_DONTRECORD);
	selfstandup_enable			= CreateConVar("selfstandup_enable",			"1",		"0: off,  1: on,  Plugin On/Off", PLUGIN_FCVAR );
	selfstandup_blackwhite		= CreateConVar("selfstandup_max",				"2",		"value only 1 and above = max incap count to black n white (off function = 9999 or what ever)", PLUGIN_FCVAR );
	selfstandup_kill			= CreateConVar("selfstandup_kill",				"0",		"0: Do not kill special infected when breaking free; 1: Kill special infected when breaking free", PLUGIN_FCVAR );	
	selfstandup_health_incap	= CreateConVar("selfstandup_health_incap",		"40.0",		"How much health after reviving from incapacitation.", PLUGIN_FCVAR );
	selfstandup_duration		= CreateConVar("selfstandup_duration",			"5.0",		"Min:0, Max: 5.0, Self stand up Duration", PLUGIN_FCVAR );
	selfstandup_crawl			= CreateConVar("selfstandup_crawl",				"1",		"0: Off, 1:on,  Allow player crawling on incap)", PLUGIN_FCVAR );
	selfstandup_crawl_speed		= CreateConVar("selfstandup_crawl_speed",		"30",		"How fast player crawl when incap)", PLUGIN_FCVAR );
	selfstandup_message			= CreateConVar("selfstandup_message",			"1",		"0:No,   1:Yes, Enable chat notification.", PLUGIN_FCVAR );
	selfstandup_costly			= CreateConVar("selfstandup_costly",			"1",		"0:Off,   1:On, Function to turn on required item to break free from infected or self stand up", PLUGIN_FCVAR );
	selfstandup_costly_item		= CreateConVar("selfstandup_costly_item",		"med_kit, pills, adrenaline, defibrillator, incendiary, explosive",	"List of item allowed sparated by comma, 'selfstandup_costly' must on (med_kit, pills, adrenaline, defibrillator, incendiary, explosive)", PLUGIN_FCVAR );
	selfstandup_clearance		= CreateConVar("selfstandup_clearance",			"100.0",	"0: Off,   200.0: on, max radius scan range (only allow incap player to get up if player at this range from zombie and SI)", PLUGIN_FCVAR );
	selfstandup_teamdistance	= CreateConVar("selfstandup_teamdistance",		"100.0",	"0: Off,   200.0: on, max distance incap player allowed to revive incap team mate)", PLUGIN_FCVAR );
	selfstandup_color			= CreateConVar("selfstandup_color",				"1",		"0: Off,   1: on, set player color on last life", PLUGIN_FCVAR );
	
	AutoExecConfig( true, GAME_DATA );
	
	HookEvent( "lunge_pounce",					EVENT_LungePounce );
	HookEvent( "pounce_stopped",				EVENT_PounceStopped );
	HookEvent( "pounce_end",					EVENT_PounceStopped );
	//HookEvent( "tongue_grab",					EVENT_TongueGrab );
	HookEvent( "choke_start",					EVENT_TongueGrab );
	HookEvent( "tongue_release",				EVENT_TongueRelease );
	HookEvent( "jockey_ride",					EVENT_JockeyRide );
	HookEvent( "jockey_ride_end",				EVENT_JockeyRideEnd );
	HookEvent( "charger_pummel_start",			EVENT_ChargerPummelStart );
	HookEvent( "charger_pummel_end",			EVENT_ChargerPummelEnd );
	HookEvent( "player_hurt",					EVENT_PlayerHurt );
	HookEvent( "player_death",					EVENT_PlayerDeath );
	HookEvent( "heal_success",					EVENT_HealSuccess );
	HookEvent( "round_start",					EVENT_RoundStart );
	HookEvent( "player_spawn",					EVENT_PlayerSpawn );
	HookEvent( "survivor_rescued",				EVENT_PlayerSpawn );
	HookEvent( "player_incapacitated",			EVENT_PlayerIncapacitated );
	HookEvent( "player_ledge_grab",				EVENT_PlayerIncapacitated );
	HookEvent( "revive_begin",					EVENT_ReviveBegin );
	HookEvent( "revive_end",					EVENT_ReviveEnd );
	HookEvent( "revive_success",				EVENT_ReviveSuccess );
	HookEvent( "pills_used",					EVENT_PillsUsed );
	HookEvent( "adrenaline_used",				EVENT_PillsUsed );
	
	HookConVarChange( selfstandup_enable,		bw_CVARChanged );
	HookConVarChange( selfstandup_blackwhite,	bw_CVARChanged );
	HookConVarChange( selfstandup_kill,			bw_CVARChanged );
	HookConVarChange( selfstandup_health_incap,	bw_CVARChanged );
	HookConVarChange( selfstandup_health_incap,	bw_CVARChanged );
	HookConVarChange( selfstandup_duration,		bw_CVARChanged );
	HookConVarChange( selfstandup_message,		bw_CVARChanged );
	HookConVarChange( selfstandup_costly,		bw_CVARChanged );
	HookConVarChange( selfstandup_costly_item,	bw_CVARChanged );
	HookConVarChange( selfstandup_teamdistance,	bw_CVARChanged );
}

UdateCvarChange()
{
	g_enable			= GetConVarInt( selfstandup_enable );
	g_blackwhite		= GetConVarInt( selfstandup_blackwhite );
	g_kill				= GetConVarInt( selfstandup_kill );
	g_health_incap		= GetConVarFloat( selfstandup_health_incap );
	g_duration			= GetConVarFloat( selfstandup_duration );
	g_message			= GetConVarInt( selfstandup_message );
	g_costly			= GetConVarInt( selfstandup_costly );
	g_clearance			= GetConVarFloat( selfstandup_clearance	 );
	g_teamdistance		= GetConVarFloat( selfstandup_teamdistance );
	g_lastlifecolor		= GetConVarInt( selfstandup_color );
	
	if ( g_clearance > 200.0 )
	{
		g_clearance = 200.0
	}
	if ( g_teamdistance > 200.0 )
	{
		g_teamdistance = 200.0
	}
	GetConVarString( selfstandup_costly_item, g_costly_item, sizeof( g_costly_item ));
	
	SetConVarInt( FindConVar( "survivor_max_incapacitated_count" ), g_blackwhite );
	SetConVarFloat( FindConVar( "survivor_revive_health" ), g_health_incap );
	SetConVarInt( FindConVar( "survivor_allow_crawling" ), GetConVarInt( selfstandup_crawl ));
	SetConVarInt( FindConVar( "survivor_crawl_speed" ), GetConVarInt( selfstandup_crawl_speed ));
	SetConVarInt( FindConVar( "z_grab_ledges_solo" ), 1 );
	
	if ( g_duration > 0.0 )
	{
		SetConVarFloat( FindConVar( "survivor_revive_duration" ), g_duration );
	}
}

public OnMapStart()
{
	PrecacheSound( SOUND_KILL2, true );
	PrecacheSound( SOUND_HEART_BEAT, true );
	PrecacheSound( SOUND_GETUP, true );
	PrecacheSound( SOUND_ERROR, true );
	UdateCvarChange();
}

public OnClientDisconnect( client )
{
	if ( client > NONE && client <= MaxClients )
	{
		Restart[client] = true;
	}
}

public bw_CVARChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	UdateCvarChange();
}

public EVENT_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	for ( new i = 1; i <= MaxClients; i++ )
	{
		if ( IsValidSurvivor( i ))
		{
			Timers[i]			= INVALID_HANDLE;
			Attacker[i]			= NONE;
			HelpState[i]		= NONE;
			RevHelper[i]		= NONE;
			RevCount[i]			= NONE;
			TargetTeam[i]		= NONE;
			PlayerWeaponSlot[i]	= -1;
			Restart[i]			= false;
			Button[i]			= false;
		}
	}
	UdateCvarChange();
}

public EVENT_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	SetConVarInt( FindConVar( "survivor_allow_crawling" ), NONE );
	SetConVarInt( FindConVar( "survivor_crawl_speed" ), 15 );
}

public EVENT_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if ( g_enable == NONE ) return;
	new client = GetClientOfUserId( GetEventInt( event, "userid" ));
	if ( IsValidSurvivor( client ))
	{
		GetClientHP( client );
		Attacker[client]			= NONE;
		RevCount[client]			= NONE;
		RevHelper[client]			= NONE;
		TargetTeam[client]			= NONE;
		PlayerWeaponSlot[client]	= -1;
		TeamHealth[client]			= NONE;
		TeamHealthBuff[client]		= NONE_F;
		Restart[client]				= false;
		Button[client]				= false;
		
		CreateTimer( 30.0, Timer_Hint, client );
	}
}

public EVENT_TongueGrab (Handle:event, const String:name[], bool:dontBroadcast)
{
	if ( g_enable == NONE ) return;
	new victim		= GetClientOfUserId( GetEventInt( event, "victim" ));
	new attacker	= GetClientOfUserId( GetEventInt( event, "userid" ));
	if ( IsValidSurvivor( victim ))
	{
		Attacker[victim] = attacker;
		if( Timers[victim] != INVALID_HANDLE )
		{
			Restart[victim] = true;
		}
	}
}

public EVENT_TongueRelease (Handle:event, const String:name[], bool:dontBroadcast)
{
	if ( g_enable == NONE ) return;
	new victim		= GetClientOfUserId( GetEventInt( event, "victim" ));
	if ( victim > NONE && victim <= MaxClients )
	{
		Attacker[victim] = NONE;
	}
}

public EVENT_LungePounce ( Handle:event, const String:name[], bool:dontBroadcast )
{
	if ( g_enable == NONE ) return;
	new victim		= GetClientOfUserId( GetEventInt( event, "victim" ));
	new attacker	= GetClientOfUserId( GetEventInt( event, "userid" ));
	if ( IsValidSurvivor( victim ))
	{
		Attacker[victim] = attacker;
		if( Timers[victim] != INVALID_HANDLE )
		{
			Restart[victim] = true;
		}
	}
}

public EVENT_PounceStopped (Handle:event, const String:name[], bool:dontBroadcast)
{
	if ( g_enable == NONE ) return;
	new victim		= GetClientOfUserId( GetEventInt( event, "victim" ));
	if ( victim > NONE && victim <= MaxClients )
	{
		Attacker[victim] = NONE;
	}
}

public EVENT_JockeyRide (Handle:event, const String:name[], bool:dontBroadcast)
{
	if ( g_enable == NONE ) return;
	new victim		= GetClientOfUserId( GetEventInt( event, "victim" ));
	new attacker	= GetClientOfUserId( GetEventInt( event, "userid" ));
	if ( IsValidSurvivor( victim ))
	{
		Attacker[victim] = attacker;
		if( Timers[victim] != INVALID_HANDLE )
		{
			Restart[victim] = true;
		}
	}
}

public EVENT_JockeyRideEnd ( Handle:event, const String:name[], bool:dontBroadcast )
{
	if ( g_enable == NONE ) return;
	new victim		= GetClientOfUserId( GetEventInt( event, "victim" ));
	if ( victim > NONE && victim <= MaxClients )
	{
		Attacker[victim] = NONE;
	}
}

public EVENT_ChargerPummelStart ( Handle:event, const String:name[], bool:dontBroadcast )
{
	if ( g_enable == NONE ) return;
	new victim		= GetClientOfUserId( GetEventInt( event, "victim" ));
	new attacker	= GetClientOfUserId( GetEventInt( event, "userid" ));
	if ( IsValidSurvivor( victim ))
	{
		Attacker[victim] = attacker;
		if( Timers[victim] != INVALID_HANDLE )
		{
			Restart[victim] = true;
		}
	}
}

public EVENT_ChargerPummelEnd (Handle:event, const String:name[], bool:dontBroadcast)
{
	if ( g_enable == NONE ) return;
	new victim		= GetClientOfUserId( GetEventInt( event, "victim" ));
	if ( victim > NONE && victim <= MaxClients )
	{
		Attacker[victim] = NONE;
	}
}

public EVENT_PlayerIncapacitated(Handle:event, const String:name[], bool:dontBroadcast)
{
	if ( g_enable == NONE ) return;
	new victim = GetClientOfUserId( GetEventInt( event, "userid" ));
	if ( IsValidSurvivor( victim ))
	{
		if( Timers[victim] != INVALID_HANDLE )
		{
			Restart[victim] = true;
		}
	}
}

public EVENT_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	if ( g_enable == NONE ) return;
	new victim = GetClientOfUserId( GetEventInt( event, "userid" ));
	if ( IsValidSurvivor( victim ))
	{
		GetClientHP( victim );
		if ( GetEntProp( victim, Prop_Send, "m_bIsOnThirdStrike" ) < 1 )
		{
			StopSound( victim, SNDCHAN_AUTO, SOUND_HEART_BEAT );
			if ( g_lastlifecolor > NONE )
			{
				SetEntityRenderMode( victim, RENDER_TRANSCOLOR);
				SetEntityRenderColor( victim, 255, 255, 255, 255 );
			}
		}
	}
}

public EVENT_HealSuccess(Handle:event, const String:name[], bool:dontBroadcast)
{
	if ( g_enable == NONE ) return;
	new victim = GetClientOfUserId( GetEventInt( event, "subject" ));
	if ( IsValidSurvivor( victim ))
	{
		GetClientHP( victim );
		CreateTimer( 0.2, ResetReviveCount, victim );
		
		RevCount[victim] = GetEntProp( victim, Prop_Send, "m_currentReviveCount" );
		if ( !IsFakeClient( victim ) && g_message > NONE )
		{
			PrintToChat( victim, "\x04[\x05剩余次数\x04]\x05:  \x04%d \x05of \x04%d", RevCount[victim], g_blackwhite );
		}
	}
}

public EVENT_ReviveBegin(Handle:event, const String:name[], bool:dontBroadcast)
{
	if ( g_enable == NONE ) return;
	new victim		= GetClientOfUserId( GetEventInt( event, "subject" ));
	new helper		= GetClientOfUserId( GetEventInt( event, "userid" ));
	if ( IsValidSurvivor( victim ))
	{
		if ( helper != victim && ( !IsNo_Incap( victim ) || !IsNo_IncapLedge( victim )))
		{
			RevHelper[victim] = helper;
		}
	}
}

public EVENT_ReviveEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if ( g_enable == NONE ) return;
	new victim = GetClientOfUserId( GetEventInt( event, "subject" ));
	if ( victim > NONE && victim <= MaxClients )
	{
		RevHelper[victim] = NONE;
	}
}

public EVENT_ReviveSuccess( Handle:event, const String:name[], bool:dontBroadcast )
{
	if ( g_enable == NONE ) return;
	new victim = GetClientOfUserId( GetEventInt( event, "subject" ));
	new helper = GetClientOfUserId( GetEventInt( event, "userid" ));
	
	if ( IsValidSurvivor( victim ))
	{
		if ( RevHelper[victim] < 1 )
		{
			if ( GetEventBool( event, "ledge_hang" ) == false )
			{
				RevCount[victim]	+= 1;
			}
		}
		else
		{
			if ( GetEventBool( event, "ledge_hang" ) == false )
			{
				RevCount[victim]	= GetEntProp( victim, Prop_Send, "m_currentReviveCount" );
			}
			
			if ( GetEntProp( victim, Prop_Send, "m_bIsOnThirdStrike" ) > NONE )
			{
				if ( g_lastlifecolor > NONE )
				{
					SetEntityRenderMode( victim, RENDER_TRANSCOLOR );
					SetEntityRenderColor( victim, 128, 255, 128, 255 );
				}
				if ( g_message > NONE )
				{
					PrintToChatAll( "\x04%N \x05进入黑白状态!!", victim );
				}
			}
			else
			{
				if ( g_message > NONE )
				{
					PrintToChat( victim, "\x04%d \x05of \x04%d, \x05你被 \x04%N 所救", RevCount[victim], g_blackwhite, helper );
				}
			}
		}
	}
	
	RevHelper[victim] = NONE;
}

public EVENT_PillsUsed( Handle:event, const String:name[], bool:dontBroadcast )
{
	if ( g_enable == NONE ) return;
	new userid = GetClientOfUserId( GetEventInt( event, "userid" ));
	if ( IsValidSurvivor( userid ))
	{
		GetClientHP( userid );
	}
}

public EVENT_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if ( g_enable == NONE ) return;
	new victim = GetClientOfUserId( GetEventInt( event, "userid" ));
	if ( victim > NONE && victim <= MaxClients )
	{
		if ( IsClientConnected( victim ) && GetClientTeam( victim ) == 2 )
		{
			RevCount[victim] = NONE;
			SetEntProp( victim, Prop_Data, "m_MoveType", 2 );
			SetEntProp( victim, Prop_Data, "m_takedamage", 2, 1 );
			StopSound( victim, SNDCHAN_AUTO, SOUND_HEART_BEAT );
			if ( g_lastlifecolor > NONE )
			{
				SetEntityRenderMode( victim, RENDER_TRANSCOLOR);
				SetEntityRenderColor( victim, 255, 255, 255, 255 );
			}
		}
		
		for ( new i = 1; i <= MaxClients; i++ )
		{
			if ( RevHelper[i] == victim )
			{
				RevHelper[i] = NONE;
			}
			if ( Attacker[i] == victim )
			{
				Attacker[i] = NONE;
			}
			if ( TargetTeam[i] == victim )
			{
				TargetTeam[i] = NONE;
			}
			if ( TargetTeam[victim] == i )
			{
				TargetTeam[victim] = NONE;
			}
		}
	}
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if ( !Button[client] )
	{
		if ( client > NONE && ( buttons & IN_DUCK ))
		{
			new target = GetClientAimTarget( client, true );
			decl Float:TPos[3], Float:PPos[3];
			if ( target != -1 && IsValidSurvivor( target ) && g_teamdistance > NONE_F && ProgressionTeam( client, target ) == true )
			{
				GetEntPropVector( client, Prop_Send, "m_vecOrigin", PPos );
				GetEntPropVector( target, Prop_Send, "m_vecOrigin", TPos );
				
				if ( GetVectorDistance( TPos, PPos ) > g_teamdistance )
				{
					Button[client]		= true;
					CreateTimer( 2.0, Button_Restore, client );
					return Plugin_Continue;
				}
				
				GetDuration( client );
				Timers[client]			= CreateTimer( 0.1, Timer_TeamGetUP, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE );
				Button[client]			= true;
				Button[target]			= true;
				TargetTeam[client]		= target;
				PrintHintText( client, "你的目标是 %N", target );
				return Plugin_Continue;
			}
			
			if( Attacker[client] > NONE || !IsNo_Incap( client ) || !IsNo_IncapLedge( client ))
			{
				if ( g_costly > NONE && IsValidSlot( client ) == false )
				{
					if ( g_message > NONE )
					{
						if ( Attacker[client] > NONE )
						{
							PrintHintText( client, "需要物品挣脱" );
						}
						else if ( !IsNo_Incap( client ) || !IsNo_IncapLedge( client ) )
						{
							PrintHintText( client, "需要物品自救" );
						}
					}
					Button[client] = true;
					EmitSoundToClient( client, SOUND_ERROR );
					CreateTimer( 2.0, Button_Restore, client );
					return Plugin_Continue;
				}
				GetDuration( client );
				Timers[client] = CreateTimer( 0.1, Timer_SelfGetUP, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE );
				Button[client] = true;
			}
		}
	}
	return Plugin_Continue;
}

public Action:Timer_SelfGetUP( Handle:timer, any:victim )
{
	new Float:EngTime = GetEngineTime();
	if ( Progression( victim ) && ( GetClientButtons( victim ) & IN_DUCK ))
	{
		if ( HelpState[victim] == STATE_NONE )
		{
			StartTime[victim]		= EngTime;
			TeamHealth[victim]		= GetEntProp( victim, Prop_Data, "m_iHealth" );
			TeamHealthBuff[victim]	= GetEntPropFloat( victim, Prop_Send, "m_healthBuffer" );
			if (( !IsNo_Incap( victim ) || !IsNo_IncapLedge( victim )) && Attacker[victim] == NONE )
			{
				SetEntProp( victim, Prop_Data, "m_MoveType", NONE );
				SetEntPropEnt( victim, Prop_Send, "m_reviveOwner", victim );
			}
			ShowBar( victim, EngTime - StartTime[victim], Duration[victim] );
			LoadUnloadProgressBar( victim, Duration[victim] );
			HelpState[victim] = STATE_SELFGETUP;
			if ( Attacker[victim] < 1 )
			{
				Execute_EventReviveBegin( victim, victim );
			}
		}
		if ( HelpState[victim] == STATE_SELFGETUP )
		{
			if (( EngTime - StartTime[victim] ) <= Duration[victim] )
			{
				ShowBar( victim, EngTime - StartTime[victim], Duration[victim] );
				if (( !IsNo_Incap( victim ) || !IsNo_IncapLedge( victim )) && Attacker[victim] == NONE )
				{
					SetEntProp( victim, Prop_Data, "m_iHealth", TeamHealth[victim] );
					SetEntPropFloat( victim, Prop_Send, "m_healthBuffer", TeamHealthBuff[victim] );
				}
			}
			else if (( EngTime - StartTime[victim] ) > Duration[victim] )
			{
				HelpState[victim] = STATE_NONE;
				ShowBar( victim, -1.0, Duration[victim] );
				LoadUnloadProgressBar( victim, NONE_F );
				GetUp( victim );
			}
		}
		return Plugin_Continue;
	}
	
	// player dead, gone, get up or whatever so we terminate the timer.
	if ( IsInGame( victim ))
	{
		ShowBar( victim, -1.0, Duration[victim] );
		SetEntProp( victim, Prop_Data, "m_MoveType", 2 );
		
		if ( RevHelper[victim] < 1 )
		{
			LoadUnloadProgressBar( victim, NONE_F );
			if( !IsNo_Incap( victim ) || !IsNo_IncapLedge( victim ))
			{
				SetEntPropEnt( victim, Prop_Send, "m_reviveOwner", -1 );
				Execute_EventReviveEnd( victim, victim );
			}
		}
	}
	
	HelpState[victim]	= STATE_NONE;
	Restart[victim]		= false;
	Timers[victim]		= INVALID_HANDLE;
	CreateTimer( 0.5, Button_Restore, victim );
	return Plugin_Stop;
}

public Action:Timer_TeamGetUP( Handle:timer, any:helper )
{
	new target = TargetTeam[helper]
	new Float:EngTime = GetEngineTime();
	
	if ( ProgressionTeam( helper, target ) && ( GetClientButtons( helper ) & IN_DUCK ))
	{
		if ( HelpState[helper] == STATE_NONE )
		{
			StartTime[helper]			= EngTime;
			TeamHealth[helper]		= GetEntProp( helper, Prop_Data, "m_iHealth" );
			TeamHealthBuff[helper]	= GetEntPropFloat( helper, Prop_Send, "m_healthBuffer" );
			TeamHealth[target]		= GetEntProp( target, Prop_Data, "m_iHealth" );
			TeamHealthBuff[target]	= GetEntPropFloat( target, Prop_Send, "m_healthBuffer" );
			SetEntProp( helper, Prop_Data, "m_MoveType", NONE );
			SetEntProp( target, Prop_Data, "m_MoveType", NONE );
			SetEntPropEnt( target, Prop_Send, "m_reviveOwner", helper );
			SetEntPropEnt( helper, Prop_Send, "m_reviveTarget", target );
			
			ShowBar( helper, EngTime - StartTime[helper], Duration[helper] );
			ShowBar( target, EngTime - StartTime[helper], Duration[helper] );
			LoadUnloadProgressBar( helper, Duration[helper] );
			LoadUnloadProgressBar( target, Duration[helper] );
			Execute_EventReviveBegin( helper, target );
			HelpState[helper] = STATE_SELFGETUP;
		}
		if ( HelpState[helper] == STATE_SELFGETUP )
		{
			if ( RevHelper[target] != helper )
			{
				Restart[helper] = true;
			}
			if (( EngTime - StartTime[helper] ) <= Duration[helper] )
			{
				if (( !IsNo_Incap( helper ) || !IsNo_IncapLedge( helper )) && Attacker[helper] == NONE )
				{
				SetEntProp( helper, Prop_Data, "m_iHealth", TeamHealth[helper] );
				SetEntPropFloat( helper, Prop_Send, "m_healthBuffer", TeamHealthBuff[helper] );
				}
				if (( !IsNo_Incap( target ) || !IsNo_IncapLedge( target )) && Attacker[target] == NONE )
				{
				SetEntProp( helper, Prop_Data, "m_iHealth", TeamHealth[helper] );
				SetEntPropFloat( helper, Prop_Send, "m_healthBuffer", TeamHealthBuff[helper] );
				}
				ShowBar( helper, EngTime - StartTime[helper], Duration[helper] );
				ShowBar( target, EngTime - StartTime[helper], Duration[helper] );
			}
			if (( EngTime - StartTime[helper] ) > Duration[helper] )
			{
				ShowBar( helper, -1.0, Duration[helper] );
				ShowBar( target, -1.0, Duration[helper] );
				LoadUnloadProgressBar( helper, NONE_F );
				LoadUnloadProgressBar( target, NONE_F );
				RevHelper[target] = NONE;
				GetUpTeam( helper, target );
			}
		}
		return Plugin_Continue;
	}

	if ( IsValidSurvivor( helper ))
	{
		ShowBar( helper, -1.0, Duration[helper] );
		SetEntProp( helper, Prop_Data, "m_MoveType", 2 );
		SetEntPropEnt( helper, Prop_Send, "m_reviveTarget", -1 );
		if ( RevHelper[helper] < 1 )
		{
			LoadUnloadProgressBar( helper, NONE_F );
		}
	}
	if ( IsValidSurvivor( target ))
	{
		ShowBar( target, -1.0, Duration[helper] );
		SetEntProp( target, Prop_Data, "m_MoveType", 2 );
		if (( !IsNo_Incap( target ) || !IsNo_IncapLedge( target )) && RevHelper[target] == helper )
		{
			SetEntPropEnt( target, Prop_Send, "m_reviveOwner", -1 );
			LoadUnloadProgressBar( target, NONE_F );
			Execute_EventReviveEnd( helper, target );
		}
	}
	CreateTimer( 0.5, Button_Restore, helper );
	CreateTimer( 0.5, Button_Restore, target );
	
	HelpState[helper]		= STATE_NONE;
	Restart[helper]		= false;
	Restart[target]		= false;
	TargetTeam[helper]	= NONE;
	Timers[helper]			= INVALID_HANDLE;
	return Plugin_Stop;
}

public Action:Button_Restore( Handle:timer, any:attacker )
{
	Button[attacker] = false;
}

public Action:Timer_RestoreCollution( Handle:timer, any:attacker )
{
	if( IsValidSpecInfected( attacker ))
	{
		SetEntityMoveType( attacker, MOVETYPE_WALK );
	}
}

public Action:Timer_ThirdStrike( Handle:timer, any:victim )
{
	if ( IsValidSurvivor( victim ))
	{
		if ( GetEntProp( victim, Prop_Send, "m_bIsOnThirdStrike" ) < 1 )
		{
			EmitSoundToClient( victim, SOUND_HEART_BEAT );
			SetEntProp( victim, Prop_Send, "m_currentReviveCount", g_blackwhite );
			SetEntProp( victim, Prop_Send, "m_bIsOnThirdStrike", 1 );
			if ( g_lastlifecolor > NONE )
			{
				SetEntityRenderMode( victim, RENDER_TRANSCOLOR );
				SetEntityRenderColor( victim, 128, 255, 128, 255 );
			}
			if ( g_message > NONE )
			{
				PrintToChatAll( "\x04%N \x05进入黑白状态!!", victim );
			}
		}
	}
}

public Action:Timer_Hint( Handle:timer, any:playeR )
{
	if ( IsValidSurvivor( playeR ))
	{
		PrintHintText( playeR, "按住CTRL键来自救" );
	}
}

public Action:ResetReviveCount( Handle:timer, any:victim )
{
	RevCount[victim] = NONE;
	SetEntProp( victim, Prop_Send, "m_currentReviveCount", NONE );
	SetEntPropFloat( victim, Prop_Send, "m_healthBuffer", NONE_F );
	SetEntProp( victim, Prop_Send, "m_bIsOnThirdStrike", NONE );
	if ( g_lastlifecolor > NONE )
	{
		SetEntityRenderMode( victim, RENDER_TRANSCOLOR);
		SetEntityRenderColor( victim, 255, 255, 255, 255 );
	}
	if( IsValidSurvivor( victim ))
	{
		StopBeat( victim );
	}
}

KillAttacker( victim )
{
	new attacker = Attacker[victim];
	if ( IsValidSpecInfected( attacker ))
	{
		ForcePlayerSuicide( attacker );
		EmitSoundToAll( SOUND_KILL2, victim );
	}
	Attacker[victim] = NONE;
}

KnockAttacker( victim )
{
	new attacker = Attacker[victim];
	
	if ( IsValidSpecInfected( attacker ))
	{
		new class = GetEntProp( attacker, Prop_Send, "m_zombieClass" );
		
		if ( class == SMOKER )
		{
			SetEntityMoveType( attacker, MOVETYPE_NOCLIP );			// this trick trigger the event tongue_release
			CreateTimer( 0.1, Timer_RestoreCollution, attacker );
			CreatePointPush( attacker, 550.0 );
		}
		if ( class == JOCKEY )
		{
			CallOnJockeyRideEnd( attacker );						// this trick trigger the event jockey_ride_end
			CreatePointPush( attacker, 550.0 );
		}
		if ( class == HUNTER )
		{
			CallOnPounceEnd( victim, GAME_DATA );
			SetEntityMoveType( attacker, MOVETYPE_NOCLIP );
			CreateTimer( 0.1, Timer_RestoreCollution, attacker );
			CreatePointPush( attacker, 550.0 );
		}
		if ( class == CHARGER )
		{
			//KillAttacker( victim );
			CallOnPummelEnded( victim, GAME_DATA );
			CreatePointPush( attacker, 550.0 );
		}
	}
	Attacker[victim] = NONE;
}

GetUp( victim )
{
	if ( IsValidSurvivor( victim ))
	{
		if( Attacker[victim] > NONE )
		{
			if ( g_kill > NONE )
			{
				KillAttacker( victim );
			}
			else
			{
				KnockAttacker( victim );
			}
		}
		else
		{
			new bool:Incap = false;
			if ( !IsNo_Incap( victim ) && IsNo_IncapLedge( victim ))
			{
				Incap = true;
			}
			
			StopBeat( victim );
			HealthCheat( victim );
			
			if ( Incap == true )
			{
				SetEntProp( victim, Prop_Data, "m_iHealth", 1 );
				SetEntPropFloat( victim, Prop_Send, "m_healthBuffer", g_health_incap );
				if ( RevCount[victim] == g_blackwhite )
				{
					CreateTimer( 0.1, Timer_ThirdStrike, victim );
					if ( g_costly > NONE )
					{
						UsePack( victim, false );
					}
				}
				else
				{
					SetEntProp( victim, Prop_Send, "m_currentReviveCount", RevCount[victim] );
					if ( g_message > NONE )
					{
						if ( g_costly == NONE )
						{
							PrintToChat( victim, "\x04[\x05剩余次数\x04]\x05:  \x04%d \x05of \x04%d", RevCount[victim], g_blackwhite );
						}
						else
						{
							UsePack( victim, true );
						}
					}
					else
					{
						if ( g_costly > NONE )
						{
							UsePack( victim, false );
						}
					}
				}
			}
			else
			{
				SetEntProp( victim, Prop_Data, "m_iHealth", ReviveHealth[victim] );
				SetEntPropFloat( victim, Prop_Send, "m_healthBuffer", ReviveHealthBuff[victim]);
				if ( g_message > NONE )
				{
					if ( g_costly == NONE )
					{
						PrintToChat( victim, "\x04[\x05剩余次数\x04]\x05:  \x04%d \x05of \x04%d", RevCount[victim], g_blackwhite );
					}
					else
					{
						UsePack( victim, true );
					}
				}
				else
				{
					if ( g_costly > NONE )
					{
						UsePack( victim, false );
					}
				}
			}
			EmitSoundToClient( victim, SOUND_GETUP );
		}
	}
}

GetUpTeam( helper, victim )
{
	if ( IsValidSurvivor( victim ))
	{
		new bool:Incap = false;
		if ( !IsNo_Incap( victim ) && IsNo_IncapLedge( victim ))
		{
			Incap = true;
		}
			
		StopBeat( victim );
		HealthCheat( victim );
			
		if ( Incap == true )
		{
			SetEntProp( victim, Prop_Data, "m_iHealth", 1 );
			SetEntPropFloat( victim, Prop_Send, "m_healthBuffer", g_health_incap );
			if ( RevCount[victim] == g_blackwhite )
			{
				CreateTimer( 0.1, Timer_ThirdStrike, victim );
			}
			else
			{
				SetEntProp( victim, Prop_Send, "m_currentReviveCount", RevCount[victim] );
				if ( g_message > NONE )
				{
					PrintToChat( victim, "\x04%d \x05of \x04%d, \x05你被 \x04%N所救", RevCount[victim], g_blackwhite, helper );
					PrintToChat( helper, "成功救起 \x04%N", victim );
				}
			}
		}
		else
		{
			SetEntProp( victim, Prop_Data, "m_iHealth", ReviveHealth[victim] );
			SetEntPropFloat( victim, Prop_Send, "m_healthBuffer", ReviveHealthBuff[victim]);
			if ( g_message > NONE )
			{
				PrintToChat( victim, "\x05你被 \x04%N所救", helper );
				PrintToChat( helper, "成功救起 \x04%N", victim );
			}
		}
		EmitSoundToClient( victim, SOUND_GETUP );
		EmitSoundToClient( helper, SOUND_GETUP );
	}
}

ShowBar( victim, Float:pos, Float:max )	 
{
	if ( IsValidSurvivor( victim ))
	{
		if ( pos < NONE_F )
		{
			PrintCenterText( victim, "" );
			return;
		}
		
		new String:ChargeBar[100];
		new Float:GaugeNum = pos/max*100;
		Format( ChargeBar, sizeof( ChargeBar ), "" );
		
		if ( GaugeNum > 100.0 )	GaugeNum = 100.0;
		if ( GaugeNum < NONE_F ) GaugeNum = NONE_F;
		for ( new m = NONE; m < 100; m++ )
		{
			ChargeBar[m] = Gauge1[NONE];
		}
		new p = RoundFloat( GaugeNum );
		if ( p >= NONE && p < 100 ) ChargeBar[p] = Gauge3[NONE]; 
		PrintCenterText( victim, "                                << 正在自救 >> %3.0f %\n<<< %s >>>", GaugeNum, ChargeBar );
	}
}

GetClientHP( victim )
{
	if ( IsValidSurvivor( victim ))
	{
		if ( IsNo_Incap( victim ) && IsNo_IncapLedge( victim ))
		{
			ReviveHealth[victim]			= GetEntProp( victim, Prop_Data, "m_iHealth" );
			ReviveHealthBuff[victim]		= GetEntPropFloat( victim, Prop_Send, "m_healthBuffer" );
		}
	}
}

StopBeat( victim )
{
	if ( IsValidSurvivor( victim ))
	{
		StopSound( victim, SNDCHAN_AUTO, SOUND_HEART_BEAT );
	}
}

ScanEnemy( victim )
{
	new Enemy = -1;

	if( IsValidSurvivor( victim ))
	{
		decl String:InfName[64];
		decl Float:targetPos[3], Float:playerPos[3];
		GetEntPropVector( victim, Prop_Send, "m_vecOrigin", playerPos );
		
		new EntCount = GetEntityCount();
		for ( new i = 1; i <= EntCount; i++ )
		{
			if ( IsValidEntity( i ))
			{
				if ( IsValidSpecInfected( i ) || IsValidTank( i ))
				{
					GetEntPropVector( i, Prop_Send, "m_vecOrigin", targetPos );
					if ( GetVectorDistance( targetPos, playerPos ) <= g_clearance)
					{
						Enemy = i;
						if ( g_message > NONE )
						{
							PrintHintText( victim, "你离 %N 太近", i );
						}
						break;
					}
				}
				else
				{
					GetEntityClassname( i, InfName, sizeof( InfName ));
					if ( StrEqual( InfName, "infected", false ))
					{
						GetEntPropVector( i, Prop_Send, "m_vecOrigin", targetPos );
						if ( GetVectorDistance( targetPos, playerPos ) <= g_clearance)
						{
							Enemy = i;
							if ( g_message > NONE )
							{
								PrintHintText( victim, "你离 %s 太近", InfName );
							}
							break;
						}
					}
				}
			}
		}
	}
	return Enemy;
}

GetDuration( client )
{
	Duration[client] = g_duration;
	if ( !IsNo_IncapLedge( client )) Duration[client] = g_duration - 1.0 ;
	
	if ( Duration[client] > 5.0 )
	{
		Duration[client] = 5.0
	}
	else if ( Duration[client] < 1.0 )
	{
		Duration[client] = 1.0
	}
}

stock CallOnJockeyRideEnd( attacker )
{
	if ( IsValidSpecInfected( attacker ))
	{
		new flag =  GetCommandFlags( "dismount" );
		SetCommandFlags( "dismount", flag & ~FCVAR_CHEAT );
		FakeClientCommand( attacker, "dismount" );
		SetCommandFlags( "dismount", flag );
	}
}

stock CallOnPummelEnded( victim, String:GAMEDATA[] )
{
	static Handle:hOnPummelEnded = INVALID_HANDLE;
	new Handle:hConf = INVALID_HANDLE;
	if ( hOnPummelEnded == INVALID_HANDLE )
	{
		hConf = LoadGameConfigFile( GAMEDATA );
		StartPrepSDKCall( SDKCall_Player );
		PrepSDKCall_SetFromConf( hConf, SDKConf_Signature, "CTerrorPlayer::OnPummelEnded" );
		PrepSDKCall_AddParameter( SDKType_Bool,SDKPass_Plain );
		PrepSDKCall_AddParameter( SDKType_CBasePlayer, SDKPass_Pointer, VDECODE_FLAG_ALLOWNULL );
		hOnPummelEnded = EndPrepSDKCall();
		CloseHandle( hConf );
		if ( hOnPummelEnded == INVALID_HANDLE )
		{
			SetFailState( "Can't get CTerrorPlayer::OnPummelEnded SDKCall!" );
			return;
		}            
	}
		
	if ( hOnPummelEnded != INVALID_HANDLE )
	{
		SDKCall( hOnPummelEnded, victim, true, -1 );
	}
	else
	{
		PrintToServer( "[GETUP]: Can't get CTerrorPlayer::OnPounceEnd SDKCall!" );
	}
}

stock CallOnPounceEnd( victim, String:GAMEDATA[] )
{
	static Handle:hOnPounceEnd = INVALID_HANDLE;
	if ( hOnPounceEnd == INVALID_HANDLE )
	{
		new Handle:hConf = INVALID_HANDLE;
		hConf = LoadGameConfigFile( GAMEDATA );
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf( hConf, SDKConf_Signature, "CTerrorPlayer::OnPounceEnd" );
		hOnPounceEnd = EndPrepSDKCall();
		CloseHandle( hConf );
		if ( hOnPounceEnd == INVALID_HANDLE )
		{
			SetFailState( "Can't get CTerrorPlayer::OnPounceEnd SDKCall!" );
			return;
		}
	}
	if ( hOnPounceEnd != INVALID_HANDLE )
	{
		SDKCall( hOnPounceEnd, victim );
	}
	else
	{
		PrintToServer( "[GETUP]: Can't get CTerrorPlayer::OnPounceEnd SDKCall!" );
	}
}

stock HealthCheat( client )
{
	if ( IsValidSurvivor( client ))
	{
		new userflags = GetUserFlagBits( client );
		new cmdflags = GetCommandFlags( "give" );
		SetUserFlagBits( client, ADMFLAG_ROOT );
		SetCommandFlags( "give", cmdflags & ~FCVAR_CHEAT );
		FakeClientCommand( client,"give health" );
		SetCommandFlags( "give", cmdflags );
		SetUserFlagBits( client, userflags );
	}
}

bool:Progression( victim )
{
	if ( !IsValidSurvivor( victim )) return false;
	if ( Restart[victim] ) return false;
	if ( RevHelper[victim] != NONE ) return false;
	if ( IsNo_Incap( victim ) && IsNo_IncapLedge( victim ) && Attacker[victim] == NONE ) return false;
	
	if ( g_clearance > 1.0 && Attacker[victim] < 1 )
	{
		if ( ScanEnemy( victim ) > NONE ) return false;
	}
	
	return true;
}

bool:ProgressionTeam( helper, target )
{
	if ( !IsValidSurvivor( helper )) return false;
	if ( !IsValidSurvivor( target )) return false;
	if ( Restart[helper] ) return false;
	if ( Restart[target] ) return false;
	if ( Attacker[helper] > NONE ) return false;
	if ( Attacker[target] > NONE ) return false;
	if ( IsNo_Incap( helper ) && IsNo_IncapLedge( helper )) return false;
	if ( IsNo_Incap( target ) && IsNo_IncapLedge( target )) return false;
	return true;
}

stock Execute_EventReviveBegin( helper, victim )
{
	if ( helper > NONE && victim > NONE )
	{
		new Handle:event = CreateEvent( "revive_begin" );
		if ( event != INVALID_HANDLE )
		{
			SetEventInt( event, "userid", GetClientUserId( helper ));		// person doing the reviving
			SetEventInt( event, "subject", GetClientUserId( victim ));		// person being revive
			FireEvent( event );
		}
	}
}

stock Execute_EventReviveEnd( helper, victim )
{
	if ( helper > NONE && victim > NONE )
	{
		new Handle:event = CreateEvent( "revive_end" );
		if ( event != INVALID_HANDLE )
		{
			SetEventInt( event, "userid", GetClientUserId( helper ));		// person doing the reviving
			SetEventInt( event, "subject", GetClientUserId( victim ));		// person being revive
			if( !IsNo_IncapLedge( victim ))
			{
				SetEventBool( event, "ledge_hang", true );
			}
			else
			{
				SetEventBool( event, "ledge_hang", false );
			}
			FireEvent( event );
		}
	}
}

GetListOfMetrial()
{
	if ( StrContains( g_costly_item, "pills", false ) != -1 )
		g_Pills = true;
	else
		g_Pills = false;
	
	if ( StrContains( g_costly_item, "adrenaline", false ) != -1 )
		g_Adrenaline = true;
	else
		g_Adrenaline = false;
	
	if ( StrContains( g_costly_item, "med_kit", false ) != -1 )
		g_Med_Kit = true;
	else
		g_Med_Kit = false;
	
	if ( StrContains( g_costly_item, "defibrillator", false ) != -1 )
		g_Defibrillator = true;
	else
		g_Defibrillator = false;
	
	if ( StrContains( g_costly_item, "incendiary", false ) != -1 )
		g_Incendiary = true;
	else
		g_Incendiary = false;
	
	if ( StrContains( g_costly_item, "explosive", false ) != -1 )
		g_Explosive = true;
	else
		g_Explosive = false;
}

UsePack( client, bool:Msg )
{
	if ( PlayerWeaponSlot[client] != -1 && IsValidEntity( PlayerWeaponSlot[client] ))
	{
		decl String:slotName[64];
		GetEntityClassname( PlayerWeaponSlot[client], slotName, sizeof( slotName ));
		if ( StrEqual( slotName, "weapon_upgradepack_explosive", false ))
			Format(slotName, sizeof( slotName ), "Explosive Ammo");
				
		else if ( StrEqual( slotName, "weapon_upgradepack_incendiary", false ))
			Format( slotName, sizeof( slotName ), "Incendiary Ammo" );
		
		else if ( StrEqual( slotName, "weapon_first_aid_kit", false ))
			Format( slotName, sizeof( slotName ), "First Aid Kit" );
		
		else if ( StrEqual( slotName, "weapon_defibrillator", false ))
			Format( slotName, sizeof( slotName ), "Defibrillator" );
		
		else if ( StrEqual( slotName, "weapon_pain_pills", false ))
			Format( slotName, sizeof( slotName ), "Pain Pills" );
		
		else Format( slotName, sizeof( slotName ), "Adrenaline" );
		
		if ( Msg )
		{
			PrintToChat( client, "\x04%d \x05of \x04%d\x05,  消耗了  \x04%s", RevCount[client], g_blackwhite, slotName );
		}
		
		AcceptEntityInput( PlayerWeaponSlot[client], "kill" );
		PlayerWeaponSlot[client] = -1;
	}
}

stock bool:isSIowner( client )
{
	// smoker
	if ( GetEntProp( client, Prop_Send, "m_reachedTongueOwner" ) > NONE )	return true;
	if ( GetEntProp( client, Prop_Send, "m_tongueOwner" ) > NONE )			return true;
	if ( GetEntProp( client, Prop_Send, "m_isHangingFromTongue" ) > NONE )	return true;
	if ( GetEntProp( client, Prop_Send, "m_isProneTongueDrag"  ) > NONE )	return true;
	
	// hunter
	if ( GetEntPropEnt( client, Prop_Send, "m_pounceAttacker" ) > NONE )	return true;
	
	//charger
	if ( GetEntPropEnt( client, Prop_Send, "m_pummelAttacker" ) > NONE )	return true;
	if ( GetEntPropEnt( client, Prop_Send, "m_carryAttacker" ) > NONE )		return true;
	
	// jockey
	if ( GetEntPropEnt( client, Prop_Send, "m_jockeyAttacker" ) > NONE )	return true;
	
	return false;
}

bool:IsValidSlot( client )
{
	if ( IsValidSurvivor( client ))
	{
		GetListOfMetrial();
	
		new String:PlayerSlot[128];
		new PlayerSlot_3 = GetPlayerWeaponSlot( client, 3 );
		new PlayerSlot_4 = GetPlayerWeaponSlot( client, 4 );
	
		if ( PlayerSlot_4 != -1 && IsValidEdict( PlayerSlot_4 ) && ( g_Pills || g_Adrenaline ))
		{
			GetEntityClassname( PlayerSlot_4, PlayerSlot, sizeof( PlayerSlot ));
		
			if ( StrEqual( PlayerSlot, "weapon_pain_pills", false ) && g_Pills )
			{
				PlayerWeaponSlot[client] = PlayerSlot_4;
				return true;
			}
			if ( StrEqual( PlayerSlot, "weapon_adrenaline", false ) && g_Adrenaline )
			{
				PlayerWeaponSlot[client] = PlayerSlot_4;
				return true;
			}
		}
		if ( PlayerSlot_3 != -1 && IsValidEdict( PlayerSlot_3 ) && ( g_Med_Kit || g_Defibrillator || g_Incendiary || g_Explosive ))
		{
			GetEntityClassname( PlayerSlot_3, PlayerSlot, sizeof( PlayerSlot ));
		
			if ( StrEqual( PlayerSlot, "weapon_first_aid_kit", false ) && g_Med_Kit )
			{
				PlayerWeaponSlot[client] = PlayerSlot_3;
				return true;
			}
			if ( StrEqual( PlayerSlot, "weapon_defibrillator", false ) && g_Defibrillator )
			{
				PlayerWeaponSlot[client] = PlayerSlot_3;
				return true;
			}
			if ( StrEqual( PlayerSlot, "weapon_upgradepack_incendiary", false ) && g_Incendiary )
			{
				PlayerWeaponSlot[client] = PlayerSlot_3;
				return true;
			}
			if ( StrEqual( PlayerSlot, "weapon_upgradepack_explosive", false ) && g_Explosive )
			{
				PlayerWeaponSlot[client] = PlayerSlot_3;
				return true;
			}
		}
	}
	PlayerWeaponSlot[client] = -1;
	return false;
}

stock bool:IsNo_Incap( client )
{
	if ( IsValidSurvivor( client ))
	{
		// if survivor incaped return false, true otherwise.
		if ( GetEntProp( client, Prop_Send, "m_isIncapacitated" ) == 1 ) return false;
	}
	return true;
}

stock bool:IsNo_IncapLedge( client )
{
	if ( IsValidSurvivor( client ))
	{
		// if survivor ledge grab return false, true otherwise.
		if ( GetEntProp( client, Prop_Send, "m_isHangingFromLedge" ) == 1 ) return false;
	}
	return true;
}

stock bool:IsValidSurvivor( client )
{
	if ( client < 1 || client > MaxClients ) return false;
	if ( !IsClientConnected( client )) return false;
	if ( !IsClientInGame( client )) return false;
	if ( !IsPlayerAlive( client )) return false;
	if ( GetClientTeam( client ) != 2 ) return false;
	return true;
}

stock bool:IsValidSpecInfected( client )
{
	if ( client < 1 || client > MaxClients ) return false;
	if ( !IsClientConnected( client )) return false;
	if ( !IsClientInGame( client )) return false;
	if ( !IsPlayerAlive( client )) return false;
	if ( GetClientTeam( client ) != 3 ) return false;
	if ( GetEntProp( client, Prop_Send, "m_zombieClass" ) == TANK ) return false;
	return true;
}

stock bool:IsInGame( client )
{
	if ( client < 1 || client > MaxClients ) return false;
	if ( !IsClientConnected( client )) return false;
	if ( !IsClientInGame( client )) return false;
	return true;
}

stock bool:IsValidTank( client )
{
	if ( client < 1 || client > MaxClients ) return false;
	if ( !IsClientConnected( client )) return false;
	if ( !IsClientInGame( client )) return false;
	if ( !IsPlayerAlive( client )) return false;
	if ( GetClientTeam( client ) != 3 ) return false;
	if ( GetEntProp( client, Prop_Send, "m_zombieClass" ) != TANK ) return false;
	return true;
}

CreatePointPush( client, Float:Force )
{
	if ( IsValidSpecInfected( client ))
	{
		decl Float:vecAng[3];
		decl Float:vecVec[3];    
		GetEntPropVector( client, Prop_Data, "m_angRotation", vecAng );
		
		vecAng[0] -= 30.0;
		
		vecVec[0] = FloatMul( Cosine( DegToRad( vecAng[1] )), Force );
		vecVec[1] = FloatMul( Sine( DegToRad( vecAng[1] )), Force );
		vecVec[2] = FloatMul( Sine( DegToRad( vecAng[0] )), ( -Force ));
		
		TeleportEntity( client, NULL_VECTOR, NULL_VECTOR, vecVec );
	}
}

LoadUnloadProgressBar( client, Float:EngTime )
{
	if ( IsValidSurvivor( client ))
	{
		SetEntPropFloat( client, Prop_Send, "m_flProgressBarStartTime", GetGameTime());
		SetEntPropFloat( client, Prop_Send, "m_flProgressBarDuration", EngTime );
	}
}

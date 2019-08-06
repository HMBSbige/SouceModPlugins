#pragma semicolon 1
#include <sourcemod>

char sg_l4d2Map[48];
char sg_mode[24];
int ig_coop;
float tickrate;

public Plugin myinfo =
{
	name = "[L4D2] MapControl",
	author = "HMBSbige",
	description = "L4D2 Coop Map Control",
	version = "1.0",
	url = "https://github.com/HMBSbige/SouceModPlugins"
};

public void OnPluginStart()
{
	HookEvent("finale_win",  Event_FinalWin,   EventHookMode_PostNoCopy);
	RegConsoleCmd("sm_tickrate", Command_GetTickrate, "输出服务器tickrate");
}

public void OnMapStart()
{
	ig_coop = 0;
	GetCurrentMap(sg_l4d2Map, sizeof(sg_l4d2Map) - 1);
	GetConVarString(FindConVar("mp_gamemode"), sg_mode, sizeof(sg_mode)-1);

	if (!strcmp(sg_mode, "coop", true))
	{
		ig_coop = 1;
	}
	if (!strcmp(sg_mode, "realism", true))
	{
		ig_coop = 1;
	}
	
	CreateTimer(30.0, Outtickrate);
}

public Action Outtickrate(Handle timer)
{
	tickrate = 1.0 / GetTickInterval();
	PrintToChatAll("\x03[提示] \x01服务器 tickrate : \x04%d", RoundToZero(tickrate));
}

public Action:Command_GetTickrate(client, args)
{
	tickrate = 1.0 / GetTickInterval();
	PrintToChatAll("\x03[提示] \x01服务器 tickrate : \x04%d", RoundToZero(tickrate));
	return Plugin_Handled;
}

public Action HxTimerNextMap(Handle timer)
{
	if (StrContains(sg_l4d2Map, "c1m", true) != -1)
	{
		ServerCommand("changelevel c2m1_highway");
		return Plugin_Stop;
	}

	if (StrContains(sg_l4d2Map, "c2m", true) != -1)
	{
		ServerCommand("changelevel c3m1_plankcountry");
		return Plugin_Stop;
	}

	if (StrContains(sg_l4d2Map, "c3m", true) != -1)
	{
		ServerCommand("changelevel c4m1_milltown_a");
		return Plugin_Stop;
	}

	if (StrContains(sg_l4d2Map, "c4m", true) != -1)
	{
		ServerCommand("changelevel c5m1_waterfront");
		return Plugin_Stop;
	}

	if (StrContains(sg_l4d2Map, "c5m", true) != -1)
	{
		ServerCommand("changelevel c6m1_riverbank");
		return Plugin_Stop;
	}

	if (StrContains(sg_l4d2Map, "c6m", true) != -1)
	{
		ServerCommand("changelevel c7m1_docks");
		return Plugin_Stop;
	}

	if (StrContains(sg_l4d2Map, "c7m", true) != -1)
	{
		ServerCommand("changelevel c8m1_apartment");
		return Plugin_Stop;
	}

	if (StrContains(sg_l4d2Map, "c8m", true) != -1)
	{
		ServerCommand("changelevel c9m1_alleys");
		return Plugin_Stop;
	}

	if (StrContains(sg_l4d2Map, "c9m", true) != -1)
	{
		ServerCommand("changelevel c10m1_caves");
		return Plugin_Stop;
	}

	if (StrContains(sg_l4d2Map, "c10m", true) != -1)
	{
		ServerCommand("changelevel c11m1_greenhouse");
		return Plugin_Stop;
	}

	if (StrContains(sg_l4d2Map, "c11m", true) != -1)
	{
		ServerCommand("changelevel c12m1_hilltop");
		return Plugin_Stop;
	}

	if (StrContains(sg_l4d2Map, "c12m", true) != -1)
	{
		ServerCommand("changelevel c13m1_alpinecreek");
		return Plugin_Stop;
	}
	
	ServerCommand("changelevel c2m1_highway");
	return Plugin_Stop;
}

public void Event_FinalWin(Event event, const char [] name, bool dontBroadcast)
{
	if (ig_coop)
	{
		PrintToChatAll("\x03[提示]\x01 70 秒后换图...");
		CreateTimer(70.0, HxTimerNextMap, _, TIMER_FLAG_NO_MAPCHANGE);
	}
}
#pragma semicolon 1
#include <sourcemod>

char sg_l4d2Map[48];
char sg_mode[24];
int ig_coop;

public Plugin myinfo =
{
	name = "MapControl",
	author = "HMBSbige",
	description = "L4D2 Coop Map Control",
	version = "1.0",
	url = "https://github.com/HMBSbige/SouceModPlugins"
};

public void OnPluginStart()
{
	HookEvent("finale_win",  Event_FinalWin,   EventHookMode_PostNoCopy);
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
}

public Action HxTimerNextMap(Handle timer)
{
	if (StrContains(sg_l4d2Map, "c1m", true) != -1)
	{
		ServerCommand("changelevel c2m1_highway");
		return Plugin_Continue;
	}

	if (StrContains(sg_l4d2Map, "c2m", true) != -1)
	{
		ServerCommand("changelevel c3m1_plankcountry");
		return Plugin_Continue;
	}

	if (StrContains(sg_l4d2Map, "c3m", true) != -1)
	{
		ServerCommand("changelevel c4m1_milltown_a");
		return Plugin_Continue;
	}

	if (StrContains(sg_l4d2Map, "c4m", true) != -1)
	{
		ServerCommand("changelevel c5m1_waterfront");
		return Plugin_Continue;
	}

	if (StrContains(sg_l4d2Map, "c5m", true) != -1)
	{
		ServerCommand("changelevel c6m1_riverbank");
		return Plugin_Continue;
	}

	if (StrContains(sg_l4d2Map, "c6m", true) != -1)
	{
		ServerCommand("changelevel c7m1_docks");
		return Plugin_Continue;
	}

	if (StrContains(sg_l4d2Map, "c7m", true) != -1)
	{
		ServerCommand("changelevel c8m1_apartment");
		return Plugin_Continue;
	}

	if (StrContains(sg_l4d2Map, "c8m", true) != -1)
	{
		ServerCommand("changelevel c9m1_alleys");
		return Plugin_Continue;
	}

	if (StrContains(sg_l4d2Map, "c9m", true) != -1)
	{
		ServerCommand("changelevel c10m1_caves");
		return Plugin_Continue;
	}

	if (StrContains(sg_l4d2Map, "c10m", true) != -1)
	{
		ServerCommand("changelevel c11m1_greenhouse");
		return Plugin_Continue;
	}

	if (StrContains(sg_l4d2Map, "c11m", true) != -1)
	{
		ServerCommand("changelevel c12m1_hilltop");
		return Plugin_Continue;
	}

	if (StrContains(sg_l4d2Map, "c12m", true) != -1)
	{
		ServerCommand("changelevel c13m1_alpinecreek");
		return Plugin_Continue;
	}
	
	ServerCommand("changelevel c2m1_highway");
	return Plugin_Continue;
}

public void Event_FinalWin(Event event, const char [] name, bool dontBroadcast)
{
	if (ig_coop)
	{
		PrintToChatAll("\x03[提示]\x01 75 秒后换图...");
		CreateTimer(75.0, HxTimerNextMap, _, TIMER_FLAG_NO_MAPCHANGE);
	}
}
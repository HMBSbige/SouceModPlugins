#define TEAM_SPECTATOR		1
#define TEAM_SURVIVORS		2
#define TEAM_INFECTED		3

#define PLUGIN_VERSION		"1.0"

#include <sourcemod>
#include <sdkhooks>

public Plugin:myinfo = {
	name = "Friendly-Fire Toolkit Lite",
	author = "HMBSbige",
	description = "友伤控制插件",
	version = PLUGIN_VERSION,
	url = "https://github.com/HMBSbige"
}

new Handle:g_FriendlyFireBots;
new Handle:g_FriendlyFireAbsorb;
new Handle:g_FriendlyFireReflect;
new Handle:g_FriendlyFireKick;
new Handle:g_FriendlyFireIncap;
new friendlyFireAmount[MAXPLAYERS + 1];

public OnPluginStart()
{
	CreateConVar("fftlite_version", PLUGIN_VERSION, "插件版本");

	g_FriendlyFireAbsorb	= CreateConVar("fftlite_absorb","1","1=不会受到友军伤害");
	g_FriendlyFireReflect	= CreateConVar("fftlite_reflect","1","1=会受到对队友造成的伤害");
	g_FriendlyFireKick		= CreateConVar("fftlite_kick","0","0=OFF 对队友造成多少伤害会被踢");
	g_FriendlyFireIncap		= CreateConVar("fftlite_incap","0","1=被反射的伤害可以击杀自己");
	g_FriendlyFireBots		= CreateConVar("fftlite_bots","0","1=BOT有友伤");

	AutoExecConfig(true, "fftlite");
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if (IsClientActual(victim) && IsClientActual(attacker) && IsSameTeam(victim, attacker) && victim != attacker)
	{
		if (!IsFakeClient(attacker)) friendlyFireAmount[attacker] += RoundToFloor(damage);
		if (GetConVarInt(g_FriendlyFireReflect) == 1)
		{
			if (!IsFakeClient(attacker) || (IsFakeClient(attacker) && GetConVarInt(g_FriendlyFireBots) == 1))
			{
				if (GetClientHealth(attacker) - RoundToFloor(damage) < 1)
				{
					if (GetConVarInt(g_FriendlyFireIncap) == 0) SetEntityHealth(attacker, 1);
					else SetEntProp(attacker, Prop_Send, "m_isIncapacitated", true, 1);
				}
				else SetEntityHealth(attacker, GetClientHealth(attacker) - RoundToFloor(damage));
			}
		}
		if (GetConVarInt(g_FriendlyFireAbsorb) == 1) damage = 0.0;
		if (GetConVarInt(g_FriendlyFireKick) > 0 && friendlyFireAmount[attacker] > GetConVarInt(g_FriendlyFireKick)) KickClient(attacker);
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public OnConfigsExecuted()
{
	AutoExecConfig(true, "fftlite");
}

public bool:IsSameTeam(first, second)
{
	if (GetClientTeam(first) == GetClientTeam(second)) return true;
	return false;
}

public bool:IsClientActual(client)
{
	if (client < 1 || client > MaxClients || !IsClientInGame(client)) return false;
	return true;
}

public OnClientPostAdminCheck(client)
{
	if (IsClientActual(client))
	{
		SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
		friendlyFireAmount[client] = 0;
	}
}

public OnClientDisconnect(client)
{
	if (IsClientActual(client))
	{
		SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
		friendlyFireAmount[client] = 0;
	}
}
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0.5"
#define PLUGIN_NAME "L4D Survivor AI Pounced Fix"


public Plugin:myinfo = {
	name = PLUGIN_NAME,
	author = " AtomicStryker ",
	description = " Fixes Survivor Bots neglecting Teammates in need ",
	version = PLUGIN_VERSION,
	url = ""
};

static bool:IsL4D2 = false;


public OnPluginStart()
{
	HookEvent("player_hurt", Event_PlayerHurt);
	
	CreateConVar("l4d_survivoraipouncedfix_version", PLUGIN_VERSION, " Version of L4D Survivor AI Pounced Fix on this server ", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	CheckGame();
}

public Action:Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));

	if (!victim
	|| !attacker
	|| !IsClientInGame(attacker)
	|| GetClientTeam(attacker) == 2)
	{
		return;
	}

	if (NeedsTeammateHelp(victim))
	{
		decl Float:position[3];
		GetClientAbsOrigin(attacker, position);

		CallBots(position, attacker);
	}
}

static CallBots(Float:position[3], attacker)
{
	decl Float:targetPos[3];

	for (new target = 1; target <= MaxClients; target++)
	{
		if (IsClientInGame(target))
		{
			if (GetClientHealth(target) > 0
			&& GetClientTeam(target) == 2
			&& IsFakeClient(target)) // make sure target is a live Survivor Bot
			{
				GetClientAbsOrigin(target, targetPos);

				if (GetVectorDistance(targetPos, position) < 500)
				{
                     ScriptCommand(target, "script", 
                     "CommandABot({cmd=0,bot=GetPlayerFromUserID(%i),target=GetPlayerFromUserID(%i)})", 
                     GetClientUserId(target), 
                     GetClientUserId(attacker));
				}
			}
		}
	}
}

stock bool:NeedsTeammateHelp(client)
{
	if (HasValidEnt(client, "m_tongueOwner") // Smoked
	|| HasValidEnt(client, "m_pounceAttacker") // Huntered
	|| (IsL4D2
		&& HasValidEnt(client, "m_jockeyAttacker")) // Ridden
	|| (IsL4D2
		&& HasValidEnt(client, "m_pummelAttacker"))) // Charged
	{
		return true;
	}
	
	return false;
}

stock bool:HasValidEnt(client, const String:entprop[])
{
	new ent = GetEntPropEnt(client, Prop_Send, entprop);
	
	return (ent > 0
		&& IsClientInGame(ent));
}

stock ScriptCommand(client, const String:command[], const String:arguments[], any:...)
{
    new String:vscript[PLATFORM_MAX_PATH];
    VFormat(vscript, sizeof(vscript), arguments, 4);
    
    new flags = GetCommandFlags(command);
    SetCommandFlags(command, flags^FCVAR_CHEAT);
    FakeClientCommand(client, "%s %s", command, vscript);
    SetCommandFlags(command, flags | FCVAR_CHEAT);
}

static CheckGame()
{
	decl String:game[32];
	GetGameFolderName(game, sizeof(game));
	
	if (StrEqual(game, "left4dead", false))
		IsL4D2 = false;
		
	else if (StrEqual(game, "left4dead2", false))
		IsL4D2 = true;
		
	else
		SetFailState("Plugin is for Left For Dead 1/2 only");
}
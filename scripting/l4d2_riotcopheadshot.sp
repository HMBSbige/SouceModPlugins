#include <sourcemod>
#define PLUGIN_VERSION "1.3"
#define PLUGIN_NAME "L4D2 Riot Cop Head Shot"
#pragma semicolon 1
#include <sdkhooks>
#include <sdktools>

new Handle:g_cvarEnable;
new bool:g_bEnabled;
new Handle:g_cvarDebug;
new g_iDebug;
new Handle:g_cvarRiotCopHeadShotEnable;
new g_iRiotCopHeadShot_HeadEnable;
new Handle:g_cvarRiotCopBodyShotDivisor;
new Float:g_fRiotCopHeadShot_BodyDivisor;
new Handle:g_cvarFallenHeadShotMultiplier;
new Float:g_fFallenHeadMultiplier;
new Handle:g_cvarRiotPenetrationDamage;
new Float:g_fPenetrationDamage;

public Plugin:myinfo = 
{
	name = PLUGIN_NAME,
	author = "dcx2 | helped by Mr. Zero / McFlurry",
	description = "Kills riot cops instantly if you shoot them in the head, makes body shots hurt riot cops a little bit, multiplies damage to fallen and Jimmy Gibbs from head shots",
	version = PLUGIN_VERSION,
	url = "www.AlliedMods.net"
}

public OnPluginStart()
{
	// cache my convars
	g_cvarEnable = CreateConVar("sm_riotcopheadshot_enable", "1.0", "Enables this plugin.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_cvarRiotCopHeadShotEnable = CreateConVar("sm_riotcopheadshot_riotheadenable", "1.0", "0: disabled\n1: Head shots instantly kill riot cops\n2: Head shots do 1x damage", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_cvarRiotCopBodyShotDivisor = CreateConVar("sm_riotcopheadshot_riotbodydivisor", "40.0", "How much to divide body shot damage by (0 will disable)", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_cvarFallenHeadShotMultiplier = CreateConVar("sm_riotcopheadshot_fallenheadmultiplier", "12.0", "How much to multiply fallen head shots by (0 will disable)", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_cvarRiotPenetrationDamage = CreateConVar("sm_riotcopheadshot_bodypenetrationdamage", "13.0", "How much damage penetrating weapons should do to the body of riot cops", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_cvarDebug = CreateConVar("sm_riotcopheadshot_debug", "0.0", "Print debug output.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	CreateConVar("sm_riotcopheadshot_ver", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	AutoExecConfig(true, "L4D2RiotCopHeadShot");
	
	// be nice and listen for changes
	HookConVarChange(g_cvarEnable, OnRCHSEnableChanged);
	HookConVarChange(g_cvarRiotCopHeadShotEnable, OnRCHS_RCHeadChanged);
	HookConVarChange(g_cvarRiotCopBodyShotDivisor, OnRCHS_RCBodyChanged);
	HookConVarChange(g_cvarFallenHeadShotMultiplier, OnRCHS_FHeadChanged);
	HookConVarChange(g_cvarRiotPenetrationDamage, OnRCHS_RiotPenDamage);
	HookConVarChange(g_cvarDebug, OnRCHSDebugChanged);

	// get cvars after AutoExecConfig
	g_bEnabled = GetConVarBool(g_cvarEnable);
	g_iRiotCopHeadShot_HeadEnable = GetConVarInt(g_cvarRiotCopHeadShotEnable);
	g_fRiotCopHeadShot_BodyDivisor = GetConVarFloat(g_cvarRiotCopBodyShotDivisor);
	g_fFallenHeadMultiplier = GetConVarFloat(g_cvarFallenHeadShotMultiplier);
	g_fPenetrationDamage = GetConVarFloat(g_cvarRiotPenetrationDamage);
	g_iDebug = GetConVarInt(g_cvarDebug);
	
	if (g_iDebug)
	{
		HookEvent("infected_hurt", Event_InfectedHurt);
	}
}

public OnRCHSEnableChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	g_bEnabled = StringToInt(newVal) == 1;
}

public OnRCHSDebugChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	g_iDebug = StringToInt(newVal);
	new oldDebug = StringToInt(oldVal);
	if (g_iDebug && !oldDebug)
	{
		HookEvent("infected_hurt", Event_InfectedHurt);
	}
	else if (oldDebug && !g_iDebug)
	{
		UnhookEvent("infected_hurt", Event_InfectedHurt);
	}
}

public OnRCHS_RCHeadChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	g_iRiotCopHeadShot_HeadEnable = StringToInt(newVal);
}

public OnRCHS_RCBodyChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	g_fRiotCopHeadShot_BodyDivisor = StringToFloat(newVal);
}

public OnRCHS_FHeadChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	g_fFallenHeadMultiplier = StringToFloat(newVal);
}

public OnRCHS_RiotPenDamage(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	g_fPenetrationDamage = StringToFloat(newVal);
}

// Listen for when infected are created, then listen to them spawn
public OnEntityCreated(entity, const String:classname[])
{
	if (entity <= 0 || entity > 2048) return;

	if (StrEqual(classname, "infected") || StrEqual(classname, "witch"))
	{
		SDKHook(entity, SDKHook_SpawnPost, RiotCop_SpawnPost);
	}
}

// Model name does not exist until after the uncommon is spawned
public RiotCop_SpawnPost(entity)
{
	if (isRiotCop(entity))
	{
		SDKHook(entity, SDKHook_TraceAttack, RiotCop_TraceAttack);
		if (g_iDebug)	PrintToChatAll("Hooked riot cop for head shot");
	}
	else if (isFallenSurvivor(entity))
	{
		SDKHook(entity, SDKHook_TraceAttack, Fallen_TraceAttack);
		if (g_iDebug)	PrintToChatAll("Hooked fallen survivor for head shot");
	}
	else if (isJimmyGibbs(entity))
	{
		SDKHook(entity, SDKHook_TraceAttack, Fallen_TraceAttack);
		if (g_iDebug)	PrintToChatAll("Hooked Jimmy Gibbs for head shot");
	}
	
	if (g_iDebug)
	{
		// if debugging listen to OTD from all infected
		SDKHook(entity, SDKHook_OnTakeDamage, RiotCopOnTakeDamage);
		SDKHook(entity, SDKHook_TraceAttack, RiotCop_TraceAttack);
	}
}

// Based on code from Mr. Zero
// TODO: DealDamage instead of SDKHooks_TakeDamage?  TakeDamage seems unstable sometimes...
public Action:RiotCop_TraceAttack(victim, &attacker, &inflictor, &Float:damage, &damagetype, &ammotype, hitbox, hitgroup)
{
	if (g_iDebug) PrintToChatAll("RCTA: %d %d %d %f %x %x %d %d", victim, attacker, inflictor, damage, damagetype, ammotype, hitbox, hitgroup);

	if (!g_bEnabled || !IsValidEntity(victim) || !isValidSurvivor(attacker)) return Plugin_Continue;

	new Float:newDamage = 0.0;

	if (g_iRiotCopHeadShot_HeadEnable > 0 && hitgroup == 1) 
	{
		newDamage = damage;	// default head shot damage, some guns may require multiple shots
		if (g_iRiotCopHeadShot_HeadEnable < 2 && newDamage < 50.0)
		{
//			newDamage = 50.0;
			// It seems that sometimes SDKHooks_TakeDamage causes a crash if it kills a riot cop?  Switching to BecomeRagdoll...
			AcceptEntityInput(victim, "BecomeRagdoll");
			if (g_iDebug) PrintToChatAll("TA: Riot cop ragdolled (before %f, after %f) (%x %x %x)", damage, newDamage, damagetype, ammotype, hitbox);
			return Plugin_Continue;
		}
		if (g_iDebug) PrintToChatAll("TA: Riot cop head shot (before %f, after %f) (%x %x %x)", damage, newDamage, damagetype, ammotype, hitbox);
	}
	else if (g_fRiotCopHeadShot_BodyDivisor > 0.9)
	{
		if (ammotype == 2 || ammotype == 9 || ammotype == 10)
		{
			// Penetrating weapons should do more damage to the body
			newDamage = g_fPenetrationDamage;				
		}
		else
		{
			newDamage = damage / g_fRiotCopHeadShot_BodyDivisor;		
		}
		if (g_iDebug) PrintToChatAll("TA: Riot cop body shot (before %f, after %f) (%x %x %x)", damage, newDamage, damagetype, ammotype, hitbox);
	}
	
	// Do not return Plugin_Changed, because this would then affect body shots from the back
	// Instead just do TakeDamage
	
	if (newDamage > 0.0) SDKHooks_TakeDamage(victim, 0, attacker, newDamage);

	//PrintToServer("RCTA Post");
	return Plugin_Continue;
}  

public Action:Fallen_TraceAttack(victim, &attacker, &inflictor, &Float:damage, &damagetype, &ammotype, hitbox, hitgroup)
{
	// A multiplier of 1.0 will disable this feature
	if (g_bEnabled && isValidSurvivor(attacker) && IsValidEntity(victim) && hitgroup == 1 && g_fFallenHeadMultiplier > 1.0) 
	{
		new Float:newDamage = damage * g_fFallenHeadMultiplier;
		
		// Jimmy Gibbs has even more health, and penetrating bullets kill him in one shot to the body
		// So penetrating bullets to the head will also kill him in one shot
		if (isJimmyGibbs(victim) && (ammotype == 2 || ammotype == 9 || ammotype == 10) && newDamage < 3000.0)
		{
			newDamage = 3000.0;
		}
		
		if (g_iDebug)
		{
			if (isFallenSurvivor(victim))	PrintToChatAll("TA: Fallen head shot (before %f, after %f)", damage, newDamage);
			else if (isJimmyGibbs(victim))	PrintToChatAll("TA: Jimmy Gibbs head shot (before %f, after %f)", damage, newDamage);
		}
		
		damage = newDamage;
		return Plugin_Changed;
	}

	return Plugin_Continue;
}  

// If debugging,  listen to IH (it will hear witches, while OTD will not)
public Action:Event_InfectedHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (g_iDebug)
	{
		new entityid = GetEventInt(event, "entityid");
		if (isRiotCop(entityid)) PrintToChatAll("IH: Hit riot cop in the %d for %d damage (%d remaining)", GetEventInt(event, "hitgroup"), GetEventInt(event, "amount"), GetEntProp(entityid, Prop_Data, "m_iHealth"));
		else if (isFallenSurvivor(entityid)) PrintToChatAll("IH: Hit fallen survivor in the %d for %d damage (%d remaining)", GetEventInt(event, "hitgroup"), GetEventInt(event, "amount"), GetEntProp(entityid, Prop_Data, "m_iHealth"));
		else if (isJimmyGibbs(entityid)) PrintToChatAll("IH: Hit Jimmy Gibbs in the %d for %d damage (%d remaining)", GetEventInt(event, "hitgroup"), GetEventInt(event, "amount"), GetEntProp(entityid, Prop_Data, "m_iHealth"));
		else PrintToChatAll("IH: Hit infected in the %d for %d damage (%d remaining)", GetEventInt(event, "hitgroup"), GetEventInt(event, "amount"), GetEntProp(entityid, Prop_Data, "m_iHealth"));
	}
}

// OTD has access to different debugging data
public Action:RiotCopOnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3])
{
	if (g_iDebug)
	{
		decl String:victimName[MAX_TARGET_LENGTH] = "Unconnected";
		decl String:attackerName[MAX_TARGET_LENGTH] = "Unconnected";
		decl String:inflictorName[32] = "Invalid";
		decl String:weaponName[32] = "Invalid";
		
		if (victim > 0 && victim <= MaxClients)
		{
			if (IsClientConnected(victim))
			{
				GetClientName(victim, victimName, sizeof(victimName));
			}
		}
		else if (IsValidEntity(victim))
		{
			GetEntityClassname(victim, victimName, sizeof(victimName));
		}
		
		if (attacker > 0 && attacker <= MaxClients)
		{
			if (IsClientConnected(attacker))
			{
				GetClientName(attacker, attackerName, sizeof(attackerName));
			}
		}
		else if (IsValidEntity(attacker))
		{
			GetEntityClassname(attacker, attackerName, sizeof(attackerName));
		}
		
		if (inflictor > 0 && IsValidEntity(inflictor))
		{
			GetEntityClassname(inflictor, inflictorName, sizeof(inflictorName));
		}

		if (weapon > 0 && IsValidEntity(weapon))
		{
			GetEntityClassname(weapon, weaponName, sizeof(weaponName));
		}
		
		PrintToChatAll("OTD: %s hit %s with %s / %s / %x for %f", attackerName, victimName, weaponName, inflictorName, damagetype, damage);

	}
	return Plugin_Continue;
}

stock bool:isValidSurvivor(client)
{
	return !(client <= 0 || client > MaxClients || !IsClientConnected(client) || !IsClientInGame(client) || GetClientTeam(client) != 2 || !IsPlayerAlive(client));
}

stock bool:isRiotCop(entity)
{
	if (entity <= 0 || entity > 2048 || !IsValidEntity(entity)) return false;
	decl String:model[128];
	GetEntPropString(entity, Prop_Data, "m_ModelName", model, sizeof(model));
	return StrContains(model, "riot") != -1; // Common is a riot uncommon
}

stock bool:isFallenSurvivor(entity)
{
	if (entity <= 0 || entity > 2048 || !IsValidEntity(entity)) return false;
	decl String:model[128];
	GetEntPropString(entity, Prop_Data, "m_ModelName", model, sizeof(model));
	return StrContains(model, "fallen") != -1; // Common is a fallen uncommon
}

stock bool:isJimmyGibbs(entity)
{
	if (entity <= 0 || entity > 2048 || !IsValidEntity(entity)) return false;
	decl String:model[128];
	GetEntPropString(entity, Prop_Data, "m_ModelName", model, sizeof(model));
	return StrContains(model, "jimmy") != -1; // Common is a Jimmy Gibbs
}

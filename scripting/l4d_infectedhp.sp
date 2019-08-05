#pragma semicolon 1
#include <sourcemod>

#define PLUGIN_VERSION "1.0.2"
#define INFECTED_NAMES 6
#define WITCH_LEN 32
#define CVAR_FLAGS FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY

public Plugin:myinfo =
{
	name = "L4D Infected HP",
	author = "NiCo-op",
	description = "L4D Infected HP",
	version = PLUGIN_VERSION,
	url = "http://nico-op.forjp.net/"
};

new Handle:hPluginEnable = INVALID_HANDLE;
new Handle:hBarLEN = INVALID_HANDLE;
new witchCUR = 0;
new witchMAX[WITCH_LEN];
new witchHP[WITCH_LEN];
new witchID[WITCH_LEN];
new prevMAX[MAXPLAYERS+1];
new prevHP[MAXPLAYERS+1];
new nCharLength;
new String:sCharHealth[8] = "#";
new String:sCharDamage[8] = "=";
new Handle:hCharHealth;
new Handle:hCharDamage;
new Handle:hShowType;
new Handle:hShowNum;
new Handle:hTank;
new Handle:hWitch;
new Handle:hWitchHealth;
new Handle:hInfected[INFECTED_NAMES];
new nShowType;
new nShowNum;
new nShowTank;
new nShowWitch;
new nShowFlag[INFECTED_NAMES];
new String:sClassName[][] = {
	"boome",
	"hunter",
	"smoker",
	"jockey",
	"spitter",
	"charger"
};

public OnPluginStart(){
	hWitchHealth = FindConVar("z_witch_health");

	CreateConVar("l4d_infectedhp_version",
		PLUGIN_VERSION,
		"L4D Infected HP version",
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_DONTRECORD
	);

	hPluginEnable = CreateConVar(
		"l4d_infectedhp",
		"1",
		"plugin on/off (on:1 / off:0)",
		CVAR_FLAGS,
		true,
		0.0,
		true,
		1.0
	);

	hBarLEN = CreateConVar(
		"l4d_infectedhp_bar",
		"100",
		"length of health bar (def:100 / min:10 / max:200)",
		CVAR_FLAGS,
		true,
		10.0,
		true,
		200.0
	);

	hCharHealth = CreateConVar(
		"l4d_infectedhp_health",
		"#",
		"show health character",
		CVAR_FLAGS
	);

	hCharDamage = CreateConVar(
		"l4d_infectedhp_damage",
		"=",
		"show damage character",
		CVAR_FLAGS
	);

	hShowType = CreateConVar(
		"l4d_infectedhp_type",
		"0",
		"health bar type (def:0 / center text:0 / hint text:1)",
		CVAR_FLAGS,
		true,
		0.0,
		true,
		1.0
	);

	hShowNum = CreateConVar(
		"l4d_infectedhp_num",
		"0",
		"health value display (def:0 / hidden:0 / visible:1)",
		CVAR_FLAGS,
		true,
		0.0,
		true,
		1.0
	);

	hTank = CreateConVar(
		"l4d_infectedhp_tank",
		"1",
		"show health bar (def:1 / on:1 / off:0)",
		CVAR_FLAGS,
		true,
		0.0,
		true,
		1.0
	);

	hWitch = CreateConVar(
		"l4d_infectedhp_witch",
		"1",
		"show health bar (def:1 / on:1 / off:0)",
		CVAR_FLAGS,
		true,
		0.0,
		true,
		1.0
	);

	hInfected[0] = CreateConVar(
		"l4d_infectedhp_boomer",
		"1",
		"show health bar (def:1 / on:1 / off:0)",
		CVAR_FLAGS,
		true,
		0.0,
		true,
		1.0
	);

	decl String:buffers[64];
	for(new i=1; i<INFECTED_NAMES; i++){
		Format(buffers, sizeof(buffers), "l4d_infectedhp_%s", sClassName[i]);
		hInfected[i] = CreateConVar(
			buffers,
			"1",
			"show health bar (def:1 / on:1 / off:0)",
			CVAR_FLAGS,
			true,
			0.0,
			true,
			1.0
		);
	}

	HookEvent("round_start", OnRoundStart);
	HookEvent("player_hurt", OnPlayerHurt);
	HookEvent("witch_spawn", OnWitchSpawn);
	HookEvent("witch_killed", OnWitchKilled);
	HookEvent("infected_hurt", OnWitchHurt);
	HookEvent("player_spawn", OnInfectedSpawn);
	HookEvent("player_death", OnInfectedDeath, EventHookMode_Pre);
	// HookEvent("tank_spawn", OnInfectedSpawn);
	// HookEvent("tank_killed", OnInfectedDeath, EventHookMode_Pre);

	AutoExecConfig(true, "l4d_infectedhp");
}

GetConfig(){
	decl String:bufA[8];
	decl String:bufB[8];
	GetConVarString(hCharHealth, bufA, sizeof(bufA));
	GetConVarString(hCharDamage, bufB, sizeof(bufB));
	nCharLength = strlen(bufA);
	if(!nCharLength || nCharLength != strlen(bufB)){
		nCharLength = 1;
		sCharHealth[0] = '#';
		sCharHealth[1] = '\0';
		sCharDamage[0] = '=';
		sCharDamage[1] = '\0';
	}
	else{
		strcopy(sCharHealth, sizeof(sCharHealth), bufA);
		strcopy(sCharDamage, sizeof(sCharDamage), bufB);
	}

	nShowType = GetConVarBool(hShowType);
	nShowNum = GetConVarBool(hShowNum);
	nShowTank = GetConVarBool(hTank);
	nShowWitch = GetConVarBool(hWitch);
	for(new i=0; i<INFECTED_NAMES; i++){
		nShowFlag[i] = GetConVarBool(hInfected[i]);
	}
}

ShowHealthGauge(client, maxBAR, maxHP, nowHP, String:clName[]){
	new percent = RoundToCeil((float(nowHP) / float(maxHP)) * float(maxBAR));
	new i, length = maxBAR * nCharLength + 2;

	decl String:showBAR[length];
	showBAR[0] = '\0';
	for(i=0; i<percent&&i<maxBAR; i++){
		StrCat(showBAR, length, sCharHealth);
	}
	for(; i<maxBAR; i++){
		StrCat(showBAR, length, sCharDamage);
	}

	if(nShowType){
		if(!nShowNum){
			PrintHintText(client, "HP: |-%s-|  %s", showBAR, clName);
		}
		else{
			PrintHintText(client, "HP: |-%s-|  [%d / %d]  %s", showBAR, nowHP, maxHP, clName);
		}
	}
	else{
		if(!nShowNum){
			PrintCenterText(client, "HP: |-%s-|  %s", showBAR, clName);
		}
		else{
			PrintCenterText(client, "HP: |-%s-|  [%d / %d]  %s", showBAR, nowHP, maxHP, clName);
		}
	}
}

public Action:OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	nShowTank = 0;
	nShowWitch = 0;
	witchCUR = 0;
	for(new i=0; i<WITCH_LEN; i++){
		witchMAX[i] = -1;
		witchHP[i] = -1;
		witchID[i] = -1;

	}
	for(new i=0; i<MAXPLAYERS+1; i++){
		prevMAX[i] = -1;
		prevHP[i] = -1;
	}
	return Plugin_Continue;
}

public Action:TimerSpawn(Handle:timer, any:client)
{
	if(IsValidEntity(client)){
		new val = GetEntProp(client, Prop_Send, "m_iMaxHealth") & 0xffff;
		prevMAX[client] = (val <= 0) ? val : 1;
		prevHP[client] = 999999;
	}
	return Plugin_Stop;
}

public Action:OnInfectedSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	GetConfig();

	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if( client > 0
		&& IsClientConnected(client)
		&& IsClientInGame(client)
		&& GetClientTeam(client) == 3
	){
		TimerSpawn(INVALID_HANDLE, client);
		CreateTimer(0.5, TimerSpawn, client, TIMER_FLAG_NO_MAPCHANGE);
	}

	return Plugin_Continue;
}

public Action:OnInfectedDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!GetConVarBool(hPluginEnable)) return Plugin_Continue;

	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if( client > 0
		&& IsClientConnected(client)
		&& IsClientInGame(client)
		&& GetClientTeam(client) == 3
	){
		decl String:clName[MAX_NAME_LENGTH];
		GetClientName(client, clName, sizeof(clName));
		prevMAX[client] = -1;
		prevHP[client] = -1;
		if(nShowTank && StrContains(clName, "Tank", false) != -1){
			new max = GetMaxClients();
			for(new i=1; i<=max; i++){
				if(IsClientConnected(i)
				  && IsClientInGame(i)
				  && !IsFakeClient(i)
				  && GetClientTeam(i) == 2){
					PrintHintText(i, "++ %s 已经死亡 ++", clName);
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action:OnPlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!GetConVarBool(hPluginEnable)) return Plugin_Continue;

	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if(!attacker
	  || !IsClientConnected(attacker)
	  || !IsClientInGame(attacker)
	  || GetClientTeam(attacker) != 2){
		return Plugin_Continue;
	}
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!client
	  || !IsClientConnected(client)
	  || !IsClientInGame(client)
	  || !IsPlayerAlive(client)
	  || GetClientTeam(client) != 3){
		return Plugin_Continue;
	}

	decl String:class[128];
	GetClientModel(client, class, sizeof(class));
	new match = 0;
	for(new i=0; i<INFECTED_NAMES; i++){
		if(nShowFlag[i] && StrContains(class, sClassName[i], false) != -1){
			match = 1;
			break;
		}
	}
	if(!match && (!nShowTank || (nShowTank
	  && StrContains(class, "tank", false) == -1
	  && StrContains(class, "hulk", false) == -1))){
		return Plugin_Continue;
	}

	new maxBAR = GetConVarInt(hBarLEN);
	new nowHP = GetEventInt(event, "health") & 0xffff;
	new maxHP = GetEntProp(client, Prop_Send, "m_iMaxHealth") & 0xffff;

	if(nowHP <= 0 || prevMAX[client] < 0){
		nowHP = 0;
	}
	if(nowHP && nowHP > prevHP[client]){
		nowHP = prevHP[client];
	}
	else{
		prevHP[client] = nowHP;
	}
	if(maxHP < prevMAX[client]){
		maxHP = prevMAX[client];
	}
	if(maxHP < nowHP){
		maxHP = nowHP;
		prevMAX[client] = nowHP;
	}
	if(maxHP < 1){
		maxHP = 1;
	}
	decl String:clName[MAX_NAME_LENGTH];
	GetClientName(client, clName, sizeof(clName));
	ShowHealthGauge(attacker, maxBAR, maxHP, nowHP, clName);

	return Plugin_Continue;
}

public Action:OnWitchSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	GetConfig();

	new entity = GetEventInt(event, "witchid");
	witchID[witchCUR] = entity;

	new health = (hWitchHealth == INVALID_HANDLE) ? 0 : GetConVarInt(hWitchHealth);
	witchMAX[witchCUR] = health;
	witchHP[witchCUR] = health;
	witchCUR = (witchCUR + 1) % WITCH_LEN;

	return Plugin_Continue;
}

public Action:OnWitchKilled(Handle:event, const String:name[], bool:dontBroadcast)
{
	new entity = GetEventInt(event, "witchid");
	for(new i=0; i<WITCH_LEN; i++){
		if(witchID[i] == entity){
			witchMAX[i] = -1;
			witchHP[i] = -1;
			witchID[i] = -1;
			break;
		}
	}
	return Plugin_Continue;
}

public Action:OnWitchHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!nShowWitch || !GetConVarBool(hPluginEnable)) return Plugin_Continue;

	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if(!attacker
	  || !IsClientConnected(attacker)
	  || !IsClientInGame(attacker)
	  || GetClientTeam(attacker) != 2){
		return Plugin_Continue;
	}

	new entity = GetEventInt(event, "entityid");
	for(new i=0; i<WITCH_LEN; i++){
		if(witchID[i] == entity){
			new damage = GetEventInt(event, "amount");
			new maxBAR = GetConVarInt(hBarLEN);
			new nowHP = witchHP[i] - damage;
			new maxHP = witchMAX[i];

			if(nowHP <= 0 || witchMAX[i] < 0){
				nowHP = 0;
			}
			if(nowHP && nowHP > witchHP[i]){
				nowHP = witchHP[i];
			}
			else{
				witchHP[i] = nowHP;
			}
			if(maxHP < 1){
				maxHP = 1;
			}
			decl String:clName[64];
			if(i == 0){
				strcopy(clName, sizeof(clName), "Witch");
			}
			else{
				Format(clName, sizeof(clName), "(%d)Witch", i);
			}
			ShowHealthGauge(attacker, maxBAR, maxHP, nowHP, clName);
			return Plugin_Continue;
		}
	}

	return Plugin_Continue;
}

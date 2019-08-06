#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "0.8.1"
#define PISTOL 1
#define SMG 2
#define PUMPSHOTGUN 3
#define AUTOSHOTGUN 4
#define RIFLE 5
#define HUNTING_RIFLE 6
#define SMG_SILENCED 7
#define SHOTGUN_CHROME 8
#define RIFLE_DESERT 9
#define SNIPER_MILITARY 10
#define SHOTGUN_SPAS 11
#define MOLOTOV 13
#define PIPE_BOMB 14
#define VOMITJAR 25
#define RIFLE_AK47 26
#define PISTOL_MAGNUM 32
#define SMG_MP5 33
#define RIFLE_SG552 34
#define SNIPER_AWP 35
#define SNIPER_SCOUT 36

//Cvar handles.
new Handle:h_Enabled
new Handle:h_AWPEnabled
new Handle:h_MP5Enabled
new Handle:h_ScoutEnabled
new Handle:h_SG552Enabled
new Handle:h_ScoutBoost
new Handle:h_AWPBoost
new Handle:h_SG552Boost
new Handle:h_MP5Boost
//new Handle:h_BatterUp
//Used to store weapon spawns.
new WeaponSpawn_ID[64]
new WeaponSpawn_IDMod[64]
new Float:WeaponSpawn_X[64]
new Float:WeaponSpawn_Y[64]
new Float:WeaponSpawn_Z[64]
new String:Map[64]
new String:GameMode[16]
//Used to keep spawns the same for both teams on competitive modes.
new bool:g_bNewMap
new bool:g_bScavengeHalftime

public Plugin:myinfo =
{
	name = "[L4D2] Weapon Unlock",
	author = "Crimson_Fox",
	description = "Unlocks the hidden CSS weapons.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=1041458"
}

public OnPluginStart()
{
	//Look up what game we're running,
	decl String:game[16]
	GetGameFolderName(game, sizeof(game))
	//and don't load if it's not L4D2.
	if (!StrEqual(game, "left4dead2", false)) SetFailState("Plugin supports Left 4 Dead 2 only.")
	//Set up cvars and event hooks.
	CreateConVar("l4d2_WeaponUnlock", PLUGIN_VERSION, "Weapon Unlock version.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD)
	h_Enabled = CreateConVar("l4d2_wu_enable", "1", "Is Weapon Unlock plug-in enabled?", FCVAR_PLUGIN|FCVAR_DONTRECORD)
	h_AWPEnabled = CreateConVar("l4d2_wu_awp", "1", "Enable AWP sniper rifle?", FCVAR_PLUGIN)
	h_MP5Enabled = CreateConVar("l4d2_wu_mp5", "1", "Enable MP5 submachine gun?", FCVAR_PLUGIN)
	h_ScoutEnabled = CreateConVar("l4d2_wu_scout", "1", "Enable Scout sniper rifle?", FCVAR_PLUGIN)
	h_SG552Enabled = CreateConVar("l4d2_wu_sg552", "1", "Enable SG552 assault rifle?", FCVAR_PLUGIN)
	h_AWPBoost = CreateConVar("l4d2_wu_awpboost", "135", "Amount of damage added to AWP sniper rifle.", FCVAR_PLUGIN)
	h_ScoutBoost = CreateConVar("l4d2_wu_scoutboost", "110", "Amount of damage added to scout sniper rifle.", FCVAR_PLUGIN)
	h_SG552Boost = CreateConVar("l4d2_wu_sg552boost", "5", "Amount of damage added to SG552.", FCVAR_PLUGIN)
	h_MP5Boost = CreateConVar("l4d2_wu_mp5boost", "0", "Amount of damage added to MP5.", FCVAR_PLUGIN)
//	h_BatterUp = CreateConVar("l4d2_wu_bat", "0", "Spawn baseball bats for survivors?", FCVAR_PLUGIN)
	AutoExecConfig(true, "l4d2_WeaponUnlock")
	HookEvent("round_start", Event_RoundStart)
	HookEvent("scavenge_round_halftime", Event_ScavengeRoundHalftime)
	HookEvent("player_hurt", Event_PlayerHurt)
	HookConVarChange(h_Enabled, ConVarChange_Enabled)
	//Precache hidden weapon models and initialize them after one second.
	PrecacheWeaponModels()
	CreateTimer(1.0, InitHiddenWeaponsDelay)
}

PrecacheWeaponModels()
{
	//Precache weapon models if they're not loaded.
	if (!IsModelPrecached("models/w_models/weapons/w_rifle_sg552.mdl")) PrecacheModel("models/w_models/weapons/w_rifle_sg552.mdl")
	if (!IsModelPrecached("models/w_models/weapons/w_smg_mp5.mdl")) PrecacheModel("models/w_models/weapons/w_smg_mp5.mdl")
	if (!IsModelPrecached("models/w_models/weapons/w_sniper_awp.mdl")) PrecacheModel("models/w_models/weapons/w_sniper_awp.mdl")
	if (!IsModelPrecached("models/w_models/weapons/w_sniper_scout.mdl")) PrecacheModel("models/w_models/weapons/w_sniper_scout.mdl")
	if (!IsModelPrecached("models/w_models/weapons/w_eq_bile_flask.mld")) PrecacheModel("models/w_models/weapons/w_eq_bile_flask.mld")
	if (!IsModelPrecached("models/v_models/v_rif_sg552.mdl")) PrecacheModel("models/v_models/v_rif_sg552.mdl")
	if (!IsModelPrecached("models/v_models/v_smg_mp5.mdl")) PrecacheModel("models/v_models/v_smg_mp5.mdl")
	if (!IsModelPrecached("models/v_models/v_snip_awp.mdl")) PrecacheModel("models/v_models/v_snip_awp.mdl")
	if (!IsModelPrecached("models/v_models/v_snip_scout.mdl")) PrecacheModel("models/v_models/v_snip_scout.mdl")
}

public Action:InitHiddenWeaponsDelay(Handle:timer, any:client)
{
	//Spawn and delete the hidden weapons,
	new index = CreateEntityByName("weapon_rifle_sg552")
	DispatchSpawn(index)
	RemoveEdict(index)
	index = CreateEntityByName("weapon_smg_mp5")
	DispatchSpawn(index)
	RemoveEdict(index)
	index = CreateEntityByName("weapon_sniper_awp")
	DispatchSpawn(index)
	RemoveEdict(index)
	index = CreateEntityByName("weapon_sniper_scout")
	DispatchSpawn(index)
	RemoveEdict(index)
	GetCurrentMap(Map, sizeof(Map))
	ForceChangeLevel(Map, "Hidden weapon initialization.")
}

public ConVarChange_Enabled(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if ((StringToInt(oldValue) == 1) && (StringToInt(newValue) == 0)) RestoreWeaponSpawns()
	if ((StringToInt(oldValue) == 0) && (StringToInt(newValue) == 1)) CreateTimer(0.1, RoundStartDelay)
}

public OnMapStart()
{
	g_bNewMap = true
	g_bScavengeHalftime = false
	for (new i = 0; i < sizeof(WeaponSpawn_ID); i++) WeaponSpawn_ID[i] = -1
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(h_Enabled) == 0) return
	//Spawn baseball bats if the option is enabled.
//	if (GetConVarInt(h_BatterUp) != 0) CreateTimer(15.0, SpawnBatsDelay)
	//Need a delay here to let OnMapStart() run.
	CreateTimer(1.0, RoundStartDelay)
}

public Action:RoundStartDelay(Handle:timer)
{
	//Look up the map and type of game we're running.
	GetConVarString(FindConVar("mp_gamemode"), GameMode, sizeof(GameMode))
	if (StrEqual(GameMode, "survival")) return
	if (StrEqual(GameMode, "scavenge"))
	{
		if (g_bScavengeHalftime == true) g_bScavengeHalftime = false
		else GetWeaponSpawns()
		SetWeaponSpawns()
		return
	}
	if (StrEqual(GameMode, "versus"))
	{
		if (g_bNewMap == true)
		{
			GetWeaponSpawns()
			g_bNewMap = false
		}
		SetWeaponSpawns()
		return
	}
	GetCurrentMap(Map, sizeof(Map))
	//If we're in a coop mode and running c4m1-4, don't modify spawns as it causes crashes on transitions.
	if (
	(StrEqual(GameMode, "coop") ||
	StrEqual(GameMode, "realism")) &&
	(StrEqual(Map, "c4m1_milltown_a") ||
	StrEqual(Map, "c4m2_sugarmill_a") ||
	StrEqual(Map, "c4m3_sugarmill_b") ||
	StrEqual(Map, "c4m4_milltown_b")))
		return
	GetWeaponSpawns()
	SetWeaponSpawns()
}

public Action:Event_ScavengeRoundHalftime(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_bScavengeHalftime = true
}

/*
//Spawn bats at the survivors' position.
public Action:SpawnBatsDelay(Handle:timer)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if ((IsClientInGame(i)) && (GetClientTeam(i)==2))
		{
			new Float:Origin[3]
			new index = CreateEntityByName("weapon_melee")
			GetClientAbsOrigin(i, Origin)
			TeleportEntity(index, Origin, NULL_VECTOR, NULL_VECTOR)
			DispatchKeyValue(index, "melee_script_name", "baseball_bat")
			DispatchSpawn(index)
		}
	}
}
*/
public Action:Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new target = GetClientOfUserId(GetEventInt(event, "userid"))
	if (target == 0) return
	//If the player that was hurt was not infected, go back.
	if (GetClientTeam(target) != 3) return
	decl String:weapon[16]
	GetEventString(event, "weapon", weapon, sizeof(weapon))
	if (StrEqual(weapon, "sniper_awp"))
	{
		new health = GetClientHealth(target)
		new damage = GetConVarInt(h_AWPBoost)
		if (health-damage < 0) SetEntityHealth(target, 0)
		else SetEntityHealth(target, health-damage)
	}
	if (StrEqual(weapon, "sniper_scout"))
	{
		new health = GetClientHealth(target)
		new damage = GetConVarInt(h_ScoutBoost)
		if (health-damage < 0) SetEntityHealth(target, 0)
		else SetEntityHealth(target, health-damage)
	}
	if (StrEqual(weapon, "rifle_sg552"))
	{
		new health = GetClientHealth(target)
		new damage = GetConVarInt(h_SG552Boost)
		if (health-damage < 0) SetEntityHealth(target, 0)
		else SetEntityHealth(target, health-damage)
	}
	if (StrEqual(weapon, "smg_mp5"))
	{
		new health = GetClientHealth(target)
		new damage = GetConVarInt(h_MP5Boost)
		if (health-damage < 0) SetEntityHealth(target, 0)
		else SetEntityHealth(target, health-damage)
	}
}

GetWeaponSpawns()
{
	//Search for dynamic weapon spawns,
	decl String:EdictClassName[32]
	new count = 0
	for (new i = 0; i <= GetEntityCount(); i++)
	{
		if (IsValidEntity(i))
		{
			GetEdictClassname(i, EdictClassName, sizeof(EdictClassName))
			if (StrEqual(EdictClassName, "weapon_spawn"))
			{
				//and record their position.
				new Float:Location[3]
				GetEntPropVector(i, Prop_Send, "m_vecOrigin", Location)
				WeaponSpawn_ID[count] = GetEntProp(i, Prop_Send, "m_weaponID")
				WeaponSpawn_X[count] = Location[0]					
				WeaponSpawn_Y[count] = Location[1]
				WeaponSpawn_Z[count] = Location[2]
				count++
			}
		}
	}
	//If dynamic spawns were found, and we're not running scavenge, modify the stored spawns like this:
	if (count != 0 && !StrEqual(GameMode, "scavenge"))
	{
		for (new i = 0; i < sizeof(WeaponSpawn_ID); i++)
		{
			if (WeaponSpawn_ID[i] == -1) break
			WeaponSpawn_IDMod[i] = WeaponSpawn_ID[i]
			switch(WeaponSpawn_ID[i])
			{
				case RIFLE_AK47: if ((GetConVarInt(h_SG552Enabled) == 1) && (GetRandomInt(1, 4) == 1)) WeaponSpawn_IDMod[i] = RIFLE_SG552;
				case SNIPER_MILITARY: if ((GetConVarInt(h_AWPEnabled) == 1) && (GetRandomInt(1, 2) == 1)) WeaponSpawn_IDMod[i] = SNIPER_AWP;
				case RIFLE_DESERT: if ((GetConVarInt(h_SG552Enabled) == 1) && (GetRandomInt(1, 4) == 1)) WeaponSpawn_IDMod[i] = RIFLE_SG552;
				case SMG_SILENCED: if ((GetConVarInt(h_MP5Enabled) == 1) && (GetRandomInt(1, 3) == 1)) WeaponSpawn_IDMod[i] = SMG_MP5;
				case HUNTING_RIFLE: if ((GetConVarInt(h_ScoutEnabled) == 1) && (GetRandomInt(1, 2) == 1)) WeaponSpawn_IDMod[i] = SNIPER_SCOUT;
				case RIFLE: if ((GetConVarInt(h_SG552Enabled) == 1) && (GetRandomInt(1, 4) == 1)) WeaponSpawn_IDMod[i] = RIFLE_SG552;
				case SMG: if ((GetConVarInt(h_MP5Enabled) == 1) && (GetRandomInt(1, 3) == 1)) WeaponSpawn_IDMod[i] = SMG_MP5;
			}
		}
	}
	//Otherwise, search for static spawns,
	else
	{
		for (new i = 0; i <= GetEntityCount(); i++)
		{
			if (IsValidEntity(i))
			{
				GetEdictClassname(i, EdictClassName, sizeof(EdictClassName))
				if (
				StrEqual(EdictClassName, "weapon_autoshotgun_spawn") ||
				StrEqual(EdictClassName, "weapon_hunting_rifle_spawn") ||
				StrEqual(EdictClassName, "weapon_molotov_spawn") ||
				StrEqual(EdictClassName, "weapon_pipe_bomb_spawn") ||
				StrEqual(EdictClassName, "weapon_pistol_magnum_spawn") ||
				StrEqual(EdictClassName, "weapon_pistol_spawn") ||
				StrEqual(EdictClassName, "weapon_pumpshotgun_spawn") ||
				StrEqual(EdictClassName, "weapon_rifle_ak47_spawn") ||
				StrEqual(EdictClassName, "weapon_rifle_desert_spawn") ||
				StrEqual(EdictClassName, "weapon_rifle_spawn") ||
				StrEqual(EdictClassName, "weapon_shotgun_chrome_spawn") ||
				StrEqual(EdictClassName, "weapon_shotgun_spas_spawn") ||
				StrEqual(EdictClassName, "weapon_smg_spawn") ||
				StrEqual(EdictClassName, "weapon_smg_silenced_spawn") ||
				StrEqual(EdictClassName, "weapon_sniper_military_spawn") ||
				StrEqual(EdictClassName, "weapon_vomitjar_spawn"))
				{
					//record their position,
					new Float:Location[3]
					GetEntPropVector(i, Prop_Send, "m_vecOrigin", Location)
					WeaponSpawn_ID[count] = GetEntProp(i, Prop_Send, "m_weaponID")
					WeaponSpawn_X[count] = Location[0]					
					WeaponSpawn_Y[count] = Location[1]
					WeaponSpawn_Z[count] = Location[2]
					count++
				}
			}
		}
		//and modify them like this:
		for (new i = 0; i < sizeof(WeaponSpawn_ID); i++)
		{
			if (WeaponSpawn_ID[i] == -1) break
			WeaponSpawn_IDMod[i] = WeaponSpawn_ID[i]
			switch(WeaponSpawn_ID[i])
			{
				case PISTOL_MAGNUM: if (GetRandomInt(1, 2) == 1) WeaponSpawn_IDMod[i] = PISTOL;
				case RIFLE_AK47:
					if (GetConVarInt(h_SG552Enabled) == 1)
					{
						switch(GetRandomInt(1, 4))
						{
							case 3: WeaponSpawn_IDMod[i] = RIFLE;
							case 2: WeaponSpawn_IDMod[i] = RIFLE_DESERT;
							case 1: WeaponSpawn_IDMod[i] = RIFLE_SG552;
						}
					}
					else
					{
						switch(GetRandomInt(1, 3) == 1) 
						{
							case 2: WeaponSpawn_IDMod[i] = RIFLE;
							case 1: WeaponSpawn_IDMod[i] = RIFLE_DESERT;
						}
					}
				case VOMITJAR:
					switch(GetRandomInt(1, 3))
					{
						case 2: WeaponSpawn_IDMod[i] = PIPE_BOMB;
						case 1: WeaponSpawn_IDMod[i] = MOLOTOV;
					}
				case PIPE_BOMB:
					switch(GetRandomInt(1, 3))
					{
						case 2: WeaponSpawn_IDMod[i] = MOLOTOV;
						case 1: WeaponSpawn_IDMod[i] = VOMITJAR;
					}
				case MOLOTOV:
					switch(GetRandomInt(1, 3))
					{
						case 2: WeaponSpawn_IDMod[i] = VOMITJAR;
						case 1: WeaponSpawn_IDMod[i] = PIPE_BOMB;
					}
				case SHOTGUN_SPAS: if (GetRandomInt(1, 2) == 1) WeaponSpawn_IDMod[i] = AUTOSHOTGUN;
				case SNIPER_MILITARY: if ((GetConVarInt(h_AWPEnabled) == 1) && (GetRandomInt(1, 2) == 1)) WeaponSpawn_IDMod[i] = SNIPER_AWP;
				case RIFLE_DESERT:
					if (GetConVarInt(h_SG552Enabled) == 1)
					{
						switch(GetRandomInt(1, 4))
						{
							case 3: WeaponSpawn_IDMod[i] = RIFLE;
							case 2: WeaponSpawn_IDMod[i] = RIFLE_AK47;
							case 1: WeaponSpawn_IDMod[i] = RIFLE_SG552;
						}
					}
					else
					{
						switch(GetRandomInt(1, 3) == 1) 
						{
							case 2: WeaponSpawn_IDMod[i] = RIFLE;
							case 1: WeaponSpawn_IDMod[i] = RIFLE_AK47;
						}
					}
				case SHOTGUN_CHROME: if (GetRandomInt(1, 2) == 1) WeaponSpawn_IDMod[i] = PUMPSHOTGUN;
				case SMG_SILENCED:
					if (GetConVarInt(h_MP5Enabled) == 1)
					{
						switch(GetRandomInt(1, 3))
						{
							case 2: WeaponSpawn_IDMod[i] = SMG;
							case 1: WeaponSpawn_IDMod[i] = SMG_MP5;
						}
					}
					else if (GetRandomInt(1, 2) == 1) WeaponSpawn_IDMod[i] = SMG;
				//Since the hunting rifle is a T1 weapon in L4D2, we'll upgrade it to a T2 sniper rifle for L4D1 maps.
				case HUNTING_RIFLE:
					if (GetConVarInt(h_AWPEnabled) == 1)
					{
						switch(GetRandomInt(1, 2))
						{
							case 2: WeaponSpawn_IDMod[i] = SNIPER_MILITARY;
							case 1: WeaponSpawn_IDMod[i] = SNIPER_AWP;
						}
					}
					else WeaponSpawn_IDMod[i] = SNIPER_MILITARY;
				case RIFLE:
					if (GetConVarInt(h_SG552Enabled) == 1)
					{
						switch(GetRandomInt(1, 4))
						{
							case 3: WeaponSpawn_IDMod[i] = RIFLE_AK47;
							case 2: WeaponSpawn_IDMod[i] = RIFLE_DESERT;
							case 1: WeaponSpawn_IDMod[i] = RIFLE_SG552;
						}
					}
					else
					{
						switch(GetRandomInt(1, 3) == 1) 
						{
							case 2: WeaponSpawn_IDMod[i] = RIFLE_AK47;
							case 1: WeaponSpawn_IDMod[i] = RIFLE_DESERT;
						}
					}
				case AUTOSHOTGUN: if (GetRandomInt(1, 2) == 1) WeaponSpawn_IDMod[i] = SHOTGUN_SPAS;
				case PUMPSHOTGUN: if (GetRandomInt(1, 2) == 1) WeaponSpawn_IDMod[i] = SHOTGUN_CHROME;
				case SMG:
					if (GetConVarInt(h_MP5Enabled) == 1)
					{
						switch(GetRandomInt(1, 3))
						{
							case 2: WeaponSpawn_IDMod[i] = SMG_SILENCED;
							case 1: WeaponSpawn_IDMod[i] = SMG_MP5;
						}
					}
					else if (GetRandomInt(1, 2) == 1) WeaponSpawn_IDMod[i] = SMG_SILENCED;
				case PISTOL: if (GetRandomInt(1, 2) == 1) WeaponSpawn_IDMod[i] = PISTOL_MAGNUM;
			}
		}
	}
}

SetWeaponSpawns()
{
	PrecacheWeaponModels()
	decl String:EdictClassName[32]
	for (new i = 0; i <= GetEntityCount(); i++)
	{
		if (IsValidEntity(i))
		{
			GetEdictClassname(i, EdictClassName, sizeof(EdictClassName))
			if (
			StrEqual(EdictClassName, "weapon_spawn") ||
			StrEqual(EdictClassName, "weapon_autoshotgun_spawn") ||
			StrEqual(EdictClassName, "weapon_hunting_rifle_spawn") ||
			StrEqual(EdictClassName, "weapon_molotov_spawn") ||
			StrEqual(EdictClassName, "weapon_pipe_bomb_spawn") ||
			StrEqual(EdictClassName, "weapon_pistol_magnum_spawn") ||
			StrEqual(EdictClassName, "weapon_pistol_spawn") ||
			StrEqual(EdictClassName, "weapon_pumpshotgun_spawn") ||
			StrEqual(EdictClassName, "weapon_rifle_ak47_spawn") ||
			StrEqual(EdictClassName, "weapon_rifle_desert_spawn") ||
			StrEqual(EdictClassName, "weapon_rifle_spawn") ||
			StrEqual(EdictClassName, "weapon_shotgun_chrome_spawn") ||
			StrEqual(EdictClassName, "weapon_shotgun_spas_spawn") ||
			StrEqual(EdictClassName, "weapon_smg_spawn") ||
			StrEqual(EdictClassName, "weapon_smg_silenced_spawn") ||
			StrEqual(EdictClassName, "weapon_sniper_military_spawn") ||
			StrEqual(EdictClassName, "weapon_vomitjar_spawn"))
			{
				new Float:Location[3]
				GetEntPropVector(i, Prop_Send, "m_vecOrigin", Location)
				new weaponID = GetEntProp(i, Prop_Send, "m_weaponID")
				for (new x = 0; x < sizeof(WeaponSpawn_IDMod); x++)
				{
					if (WeaponSpawn_ID[x] == -1) break
					if (
					((FloatAbs(WeaponSpawn_X[x] - Location[0]) < 2) &&
					(FloatAbs(WeaponSpawn_Y[x] - Location[1]) < 2) &&
					(FloatAbs(WeaponSpawn_Z[x] - Location[2]) < 2)) &&
					(weaponID != WeaponSpawn_IDMod[x]))
					{
						ReplaceWeaponSpawn(i, x)
						break
					}
				}
			}
		}
	}
}

RestoreWeaponSpawns()
{
	decl String:EdictClassName[32]
	for (new i = 0; i <= GetEntityCount(); i++)
	{
		if (IsValidEntity(i))
		{
			GetEdictClassname(i, EdictClassName, sizeof(EdictClassName))
			if (StrEqual(EdictClassName, "weapon_spawn"))
			{
				new Float:Location[3]
				GetEntPropVector(i, Prop_Send, "m_vecOrigin", Location)
				new weaponID = GetEntProp(i, Prop_Send, "m_weaponID")
				for (new x = 0; x < sizeof(WeaponSpawn_ID); x++)
				{
					if (WeaponSpawn_ID[x] == -1) break
					if (
					((FloatAbs(WeaponSpawn_X[x] - Location[0]) < 2) &&
					(FloatAbs(WeaponSpawn_Y[x] - Location[1]) < 2) &&
					(FloatAbs(WeaponSpawn_Z[x] - Location[2]) < 2)) &&
					(weaponID != WeaponSpawn_ID[x]))
					{
						new Float:Angles[3]
						GetEntPropVector(i, Prop_Send, "m_angRotation", Angles)
						RemoveEdict(i)
						new index = CreateEntityByName("weapon_spawn")
						switch(WeaponSpawn_ID[x])
						{
							case PISTOL_MAGNUM: SetEntityModel(index, "models/w_models/weapons/w_desert_eagle.mdl");
							case RIFLE_AK47: SetEntityModel(index, "models/w_models/weapons/w_rifle_ak47.mdl");
							case VOMITJAR: SetEntityModel(index, "models/w_models/weapons/w_eq_bile_flask.mld");
							case PIPE_BOMB: SetEntityModel(index, "models/w_models/weapons/w_eq_pipebomb.mdl");
							case MOLOTOV: SetEntityModel(index, "models/w_models/weapons/w_eq_molotov.mdl");
							case SHOTGUN_SPAS: SetEntityModel(index, "models/w_models/weapons/w_shotgun_spas.mdl");
							case SNIPER_MILITARY: SetEntityModel(index, "models/w_models/weapons/w_sniper_military.mdl");
							case RIFLE_DESERT: SetEntityModel(index, "models/w_models/weapons/w_desert_rifle.mdl");
							case SHOTGUN_CHROME: SetEntityModel(index, "models/w_models/weapons/w_pumpshotgun_a.mdl");
							case SMG_SILENCED: SetEntityModel(index, "models/w_models/weapons/w_smg_a.mdl");
							case HUNTING_RIFLE: SetEntityModel(index, "models/w_models/weapons/w_sniper_mini14.mdl");
							case RIFLE: SetEntityModel(index, "models/w_models/weapons/w_rifle_m16a2.mdl");
							case AUTOSHOTGUN: SetEntityModel(index, "models/w_models/weapons/w_autoshot_m4super.mdl");
							case PUMPSHOTGUN: SetEntityModel(index, "models/w_models/weapons/w_shotgun.mdl");
							case SMG: SetEntityModel(index, "models/w_models/weapons/w_smg_uzi.mdl");
							case PISTOL: SetEntityModel(index, "models/w_models/weapons/w_pistol_a.mdl");
						}
						SetEntProp(index, Prop_Send, "m_weaponID", WeaponSpawn_ID[x])
						TeleportEntity(index, Location, Angles, NULL_VECTOR)
						if (
						WeaponSpawn_ID[x] == VOMITJAR ||
						WeaponSpawn_ID[x] == PIPE_BOMB ||
						WeaponSpawn_ID[x] == MOLOTOV)
							DispatchKeyValue(index, "count", "1")
						else DispatchKeyValue(index, "count", "4")
						DispatchSpawn(index)
					}
				}
			}
		}
	}
}

ReplaceWeaponSpawn(target, source)
{	
	new Float:Origin[3]
	Origin[0] = WeaponSpawn_X[source]
	Origin[1] = WeaponSpawn_Y[source]
	Origin[2] = WeaponSpawn_Z[source]
	new Float:Angles[3]
	GetEntPropVector(target, Prop_Send, "m_angRotation", Angles)
	RemoveEdict(target)
	new index = CreateEntityByName("weapon_spawn")
	switch(WeaponSpawn_IDMod[source])
	{
		case SNIPER_SCOUT: SetEntityModel(index, "models/w_models/weapons/w_sniper_scout.mdl");
		case SNIPER_AWP: SetEntityModel(index, "models/w_models/weapons/w_sniper_awp.mdl");
		case RIFLE_SG552: SetEntityModel(index, "models/w_models/weapons/w_rifle_sg552.mdl");
		case SMG_MP5: SetEntityModel(index, "models/w_models/weapons/w_smg_mp5.mdl");
		case PISTOL_MAGNUM: SetEntityModel(index, "models/w_models/weapons/w_desert_eagle.mdl");
		case RIFLE_AK47: SetEntityModel(index, "models/w_models/weapons/w_rifle_ak47.mdl");
		case VOMITJAR: SetEntityModel(index, "models/w_models/weapons/w_eq_bile_flask.mld");
		case PIPE_BOMB: SetEntityModel(index, "models/w_models/weapons/w_eq_pipebomb.mdl");
		case MOLOTOV: SetEntityModel(index, "models/w_models/weapons/w_eq_molotov.mdl");
		case SHOTGUN_SPAS: SetEntityModel(index, "models/w_models/weapons/w_shotgun_spas.mdl");
		case SNIPER_MILITARY: SetEntityModel(index, "models/w_models/weapons/w_sniper_military.mdl");
		case RIFLE_DESERT: SetEntityModel(index, "models/w_models/weapons/w_desert_rifle.mdl");
		case SHOTGUN_CHROME: SetEntityModel(index, "models/w_models/weapons/w_pumpshotgun_a.mdl");
		case SMG_SILENCED: SetEntityModel(index, "models/w_models/weapons/w_smg_a.mdl");
		case HUNTING_RIFLE: SetEntityModel(index, "models/w_models/weapons/w_sniper_mini14.mdl");
		case RIFLE: SetEntityModel(index, "models/w_models/weapons/w_rifle_m16a2.mdl");
		case AUTOSHOTGUN: SetEntityModel(index, "models/w_models/weapons/w_autoshot_m4super.mdl");
		case PUMPSHOTGUN: SetEntityModel(index, "models/w_models/weapons/w_shotgun.mdl");
		case SMG: SetEntityModel(index, "models/w_models/weapons/w_smg_uzi.mdl");
		case PISTOL: SetEntityModel(index, "models/w_models/weapons/w_pistol_a.mdl");
	}
	SetEntProp(index, Prop_Send, "m_weaponID", WeaponSpawn_IDMod[source])
	TeleportEntity(index, Origin, Angles, NULL_VECTOR)
	if (
	WeaponSpawn_IDMod[source] == VOMITJAR ||
	WeaponSpawn_IDMod[source] == PIPE_BOMB ||
	WeaponSpawn_IDMod[source] == MOLOTOV)
		DispatchKeyValue(index, "count", "1")
	else DispatchKeyValue(index, "count", "4")
	DispatchSpawn(index)
}

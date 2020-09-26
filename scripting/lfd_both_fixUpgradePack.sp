#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#pragma newdecls required

public Plugin myinfo =
{
	name = "Upgrade Pack Fixes",
	author = "bullet28, V10, Silvers",
	description = "Fixes upgrade packs pickup bug when using survivor model change",
	version = "1",
	url = ""
}

int g_UpgradePackCanUseCount;
Handle usedUpgrades[MAXPLAYERS+1];
float lastSoundTime[MAXPLAYERS+1];
bool bUsingExplosive[MAXPLAYERS+1];

ConVar cvarDeniedSound;
ConVar cvarBlockGlauncher;
ConVar cvarIncendiaryMulti;
ConVar cvarExplosiveMulti;

bool cvarDeniedSoundValue;
int cvarBlockGlauncherValue;
float cvarIncendiaryMultiValue;
float cvarExplosiveMultiValue;

public void OnPluginStart() {
	ResetAllUsedUpgrades();
	HookEvent("round_start", EventRoundStart);

	cvarDeniedSound = CreateConVar("upgrade_denied_sound", "1", "Play sound when ammo already used", FCVAR_NONE);
	cvarBlockGlauncher = CreateConVar("upgrade_block_glauncher", "1", "Block use of special ammo with grenade launcher (0 - Allow | 1 - Block any | 2 - Block incendiary | 3 - Block explosive)", FCVAR_NONE);
	cvarIncendiaryMulti = CreateConVar("upgrade_incendiary_multi", "1.0", "Incendiary ammo multiplier on pickup", FCVAR_NONE);
	cvarExplosiveMulti = CreateConVar("upgrade_explosive_multi", "1.0", "Explosive ammo multiplier on pickup", FCVAR_NONE);

	cvarDeniedSound.AddChangeHook(OnConVarChange);
	cvarBlockGlauncher.AddChangeHook(OnConVarChange);
	cvarIncendiaryMulti.AddChangeHook(OnConVarChange);
	cvarExplosiveMulti.AddChangeHook(OnConVarChange);
	OnConVarChange(null, "", "");

	Handle hGameData = LoadGameConfigFile("upgradepackfix");
	g_UpgradePackCanUseCount = GameConfGetOffset(hGameData, "m_iUpgradePackCanUseCount");
	delete hGameData;
}

public void OnAllPluginsLoaded() {
	char smxFileName1[] = "l4d2_upgradepackfix.smx";
	Handle hFoundPlugin1 = FindPluginByFile(smxFileName1);
	if (hFoundPlugin1) SetFailState("Please remove %s before using this plugin", smxFileName1);

	char smxFileName2[] = "l4d2_upgrade_block.smx";
	Handle hFoundPlugin2 = FindPluginByFile(smxFileName2);
	if (hFoundPlugin2) SetFailState("Please remove %s before using this plugin", smxFileName2);
}

public void OnConVarChange(ConVar convar, char[] oldValue, char[] newValue) {
	cvarDeniedSoundValue = cvarDeniedSound.BoolValue;
	cvarBlockGlauncherValue = cvarBlockGlauncher.IntValue;
	cvarIncendiaryMultiValue = cvarIncendiaryMulti.FloatValue;
	cvarExplosiveMultiValue = cvarExplosiveMulti.FloatValue;
}

public void OnClientPostAdminCheck(int client) {
	ResetUsedUpgrades(client);
}

public Action EventRoundStart(Event event, const char[] name, bool dontBroadcast) {
	ResetAllUsedUpgrades();
}

void ResetAllUsedUpgrades() {
	for (int client = 1; client <= MaxClients; client++) {
		ResetUsedUpgrades(client);
	}
}

void ResetUsedUpgrades(int client) {
	if (usedUpgrades[client] != INVALID_HANDLE)
		CloseHandle(usedUpgrades[client]);
	usedUpgrades[client] = CreateArray();
}

public void OnEntityCreated(int entity, const char[] classname) {
	if (StrEqual(classname, "upgrade_ammo_explosive") || StrEqual(classname, "upgrade_ammo_incendiary")) {
		SDKHook(entity, SDKHook_Use, OnUpgradeUse);
	}
}

public Action OnUpgradeUse(int entity, int activator, int caller, UseType type, float value) {
	if (!isValidEntity(entity)) return Plugin_Continue;

	char classname[32];
	GetEntityClassname(entity, classname, sizeof(classname));
	if (StrContains(classname, "upgrade_ammo_") == -1) return Plugin_Continue;

	SetEntData(entity, g_UpgradePackCanUseCount, 4, 1, true);

	int client = caller;
	if (!isPlayerRealSurvivor(client)) return Plugin_Continue;

	int primaryItem = GetPlayerWeaponSlot(client, 0);
	if (primaryItem == -1) return Plugin_Continue;

	bUsingExplosive[client] = StrEqual(classname, "upgrade_ammo_explosive");
	
	SetEntProp(entity, Prop_Send, "m_iUsedBySurvivorsMask", 0);
	
	bool bForceBlocked = ShouldBeForceBlocked(client, primaryItem);

	if (bForceBlocked || FindValueInArray(usedUpgrades[client], entity) != -1) {
		PlayDenySound(client);
		return Plugin_Handled;

	} else {
		//PrintToChatAll("%f: First use of %N", GetGameTime(), client);
		PushArrayCell(usedUpgrades[client], entity);
		lastSoundTime[client] = GetEngineTime();
		SetUsedBySurvivor(client, entity);

		if ((bUsingExplosive[client] && cvarExplosiveMultiValue > 1.0) || (!bUsingExplosive[client] && cvarIncendiaryMultiValue > 1.0)) {
			SDKHook(client, SDKHook_PostThink, PostThinkMultiply);
		}
	}

	return Plugin_Continue;
}

public Action PostThinkMultiply(int client) {
	SDKUnhook(client, SDKHook_PostThink, PostThinkMultiply);

	if (isPlayerAliveSurvivor(client)) {
		int primaryItem = GetPlayerWeaponSlot(client, 0);
		if (primaryItem != -1) {
			int currentUpgradedAmmo = GetEntProp(primaryItem, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded");
			int targetUpgradedAmmo = RoundToFloor(currentUpgradedAmmo * (bUsingExplosive[client] ? cvarExplosiveMultiValue : cvarIncendiaryMultiValue));
			if (targetUpgradedAmmo > currentUpgradedAmmo) {
				SetEntProp(primaryItem, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded", targetUpgradedAmmo);
			}
		}
	}
}

void SetUsedBySurvivor(int client, int entity) {
	int usedMask = GetEntProp(entity, Prop_Send, "m_iUsedBySurvivorsMask");
	bool bAlreadyUsed = !(usedMask & (1 << client - 1));
	if (bAlreadyUsed) return;

	int newMask = usedMask | (1 << client - 1);
	SetEntProp(entity, Prop_Send, "m_iUsedBySurvivorsMask", newMask);
}

void PlayDenySound(int client) {
	if (cvarDeniedSoundValue) {
		float currentTime = GetEngineTime();
		if (currentTime > lastSoundTime[client] + 2.0) {
			ClientCommand(client, "play buttons/button11.wav");
			lastSoundTime[client] = currentTime;
		}
	}
}

bool ShouldBeForceBlocked(int client, int primaryItem) {
	if (cvarBlockGlauncherValue == 1 || (cvarBlockGlauncherValue == 2 && !bUsingExplosive[client]) || (cvarBlockGlauncherValue == 3 && bUsingExplosive[client])) {
		char classname[32];
		GetEntityClassname(primaryItem, classname, sizeof classname);
		if (StrEqual(classname, "weapon_grenade_launcher")) {
			return true;
		}
	}

	return false;
}

/* */
bool isValidEntity(int entity) {
	return entity > 0 && entity <= 2048 && IsValidEdict(entity) && IsValidEntity(entity);
}

bool isPlayerValid(int client) {
	return client > 0 && client <= MaxClients && IsClientInGame(client);
}

bool isPlayerReal(int client) {
	return isPlayerValid(client) && !IsFakeClient(client);
}

bool isPlayerSurvivor(int client) {
	return isPlayerValid(client) && GetClientTeam(client) == 2;
}

bool isPlayerRealSurvivor(int client) {
	return isPlayerReal(client) && GetClientTeam(client) == 2;
}

bool isPlayerAliveSurvivor(int client) {
	return isPlayerSurvivor(client) && IsPlayerAlive(client);
}

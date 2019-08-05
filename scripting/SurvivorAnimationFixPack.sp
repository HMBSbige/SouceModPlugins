#include <sourcemod>
#include <dhooks>
#include <sdktools>

static bool:incapped[MAXPLAYERS + 1] = false;

static bool:IsIncapEnabled;
static bool:IsCoachEnabled;
static bool:IsMeleeEnabled;

new Handle:sdkDoAnim;
new Handle:hSequenceSet;
static clienthook[MAXPLAYERS + 1] = -1;

public Plugin:myinfo = 
{
	name = "[L4D2] Survivor Animation Fix Pack", 
	author = "DeathChaos25", 
	description = "A few quality of life animation fixes for the survivors", 
	version = "1.3", 
	url = ""
}

public OnPluginStart()
{
	HookEvent("player_incapacitated", Event_Incap);
	HookEvent("revive_end", Event_Interrupt);
	PrepSDKCall();
	
	new Handle:IncapAnims = CreateConVar("enable_l4d1_incap_anims_fix", "1", "Fix missing collapse_to_incap missing animation for Louis/Bill/Francis?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	HookConVarChange(IncapAnims, ConVarIncapAnims);
	IsIncapEnabled = GetConVarBool(IncapAnims);
	
	new Handle:CoachEnabled = CreateConVar("enable_coach_anim_fix", "1", "Fix Coach's Single Pistol/Magnum running animation?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	HookConVarChange(CoachEnabled, ConVarCoachEnabled);
	IsCoachEnabled = GetConVarBool(CoachEnabled);
	
	new Handle:MeleeEnabled = CreateConVar("enable_hurtidlemelee_anim_fix", "1", "Fix broken L4D1 survivors hurt_idle_melee animations?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	HookConVarChange(MeleeEnabled, ConVarMeleeEnabled);
	IsMeleeEnabled = GetConVarBool(MeleeEnabled);
	
	AutoExecConfig(true, "l4d2_animations_fix");
	LoadOffset();
}

public Action:Event_Incap(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsSurvivor(client) && !IsPlayerHeld(client))
	{
		incapped[client] = true;
		CreateTimer(0.2, SETFALSE, client);
	}
	else incapped[client] = false;
}

public Action:Event_Interrupt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "subject"));
	if (IsSurvivor(client) && !IsPlayerHeld(client))
	{
		incapped[client] = false;
		SDKCall(sdkDoAnim, client, 92, 0);
	}
}

public Action:SETFALSE(Handle:Timer, client)
{
	if (IsSurvivor(client))
	{
		incapped[client] = false;
		SDKCall(sdkDoAnim, client, 92, 0);
	}
}

public MRESReturn:OnSequenceSet(pThis, Handle:hReturn, Handle:hParams)
{
	new client = pThis;
	if (IsSurvivor(client) && IsPlayerAlive(client) && !IsPlayerHeld(client))
	{
		new sequence = DHookGetReturn(hReturn);
		//PrintToChat(client, "m_nSequence %i", sequence);
		if (IsIncapacitated(client) && IsIncapEnabled && incapped[client])
		{
			new incap = GetIncapSequence(client);
			if (incap != -1)
			{
				DHookSetReturn(hReturn, incap);
				return MRES_Override;
			}
		}
		else if (sequence == 581 && IsMeleeEnabled)
		{
			decl String:model[64];
			GetEntPropString(client, Prop_Data, "m_ModelName", model, sizeof(model));
			if (StrEqual(model, "models/survivors/survivor_teenangst.mdl", false))
			{
				DHookSetReturn(hReturn, 571);
				return MRES_Override;
			}
		}
		else if (!IsIncapacitated(client) && IsCoachEnabled)
		{
			decl String:model[64];
			GetEntPropString(client, Prop_Data, "m_ModelName", model, sizeof(model));
			if (StrContains(model, "coach", false) != -1)
			{
				if (sequence == 202 && IsCoachEnabled)
				{
					DHookSetReturn(hReturn, 227); //Run_SMG
					return MRES_Override;
				}
			}
		}
	}
	return MRES_Ignored;
}

bool:IsSurvivor(client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2);
}

LoadOffset()
{
	new Handle:temp = LoadGameConfigFile("l4d2_sequence");
	
	if (temp == INVALID_HANDLE)
	{
		SetFailState("Error: Gamedata not found");
	}
	
	new offset;
	offset = GameConfGetOffset(temp, "CTerrorPlayer::SelectWeightedSequence");
	if (offset == -1)
	{
		CloseHandle(temp);
		LogError("Unable to get offset for CTerrorPlayer::SelectWeightedSequence");
		return;
	}
	hSequenceSet = DHookCreate(offset, HookType_Entity, ReturnType_Int, ThisPointer_CBaseEntity, OnSequenceSet);
	DHookAddParam(hSequenceSet, HookParamType_Int);
}

stock bool:IsPlayerHeld(client)
{
	new jockey = GetEntPropEnt(client, Prop_Send, "m_jockeyAttacker");
	new charger = GetEntPropEnt(client, Prop_Send, "m_pummelAttacker");
	new hunter = GetEntPropEnt(client, Prop_Send, "m_pounceAttacker");
	new smoker = GetEntPropEnt(client, Prop_Send, "m_tongueOwner");
	if (jockey > 0 || charger > 0 || hunter > 0 || smoker > 0)
	{
		return true;
	}
	return false;
}
stock bool:IsIncapacitated(client)
{
	if (GetEntProp(client, Prop_Send, "m_isIncapacitated", 1) > 0)
		return true;
	return false;
}

public OnAllPluginsLoaded() //late loading
{
	for (new client = 1; client <= MaxClients; client++)
	{
		if (IsSurvivor(client))
		{
			clienthook[client] = DHookEntity(hSequenceSet, true, client);
		}
	}
}

public OnClientPutInServer(client)
{
	clienthook[client] = DHookEntity(hSequenceSet, true, client);
}

stock GetIncapSequence(client)
{
	if (IsSurvivor(client))
	{
		decl String:model[64];
		GetEntPropString(client, Prop_Data, "m_ModelName", model, sizeof(model));
		if (StrContains(model, "namvet", false) != -1)
		{
			return 518;
		}
		else if (StrContains(model, "biker", false) != -1)
		{
			return 521;
		}
		else if (StrContains(model, "manager", false) != -1)
		{
			return 518;
		}
	}
	return -1;
}

public ConVarIncapAnims(Handle:convar, const String:oldValue[], const String:newValue[])
{
	IsIncapEnabled = GetConVarBool(convar);
}

public ConVarCoachEnabled(Handle:convar, const String:oldValue[], const String:newValue[])
{
	IsCoachEnabled = GetConVarBool(convar);
}

public ConVarMeleeEnabled(Handle:convar, const String:oldValue[], const String:newValue[])
{
	IsMeleeEnabled = GetConVarBool(convar);
}

static PrepSDKCall()
{
	new Handle:config = LoadGameConfigFile("l4d2_sequence");
	
	if (config == INVALID_HANDLE)
	{
		SetFailState("Error: Why do you not have this extension's gamedata file?!");
	}
	
	StartPrepSDKCall(SDKCall_Player);
	
	if (!PrepSDKCall_SetFromConf(config, SDKConf_Virtual, "CTerrorPlayer::DoAnimationEvent"))
	{
		CloseHandle(config);
		SetFailState("Cant find CTerrorPlayer::DoAnimationEvent Signature in gamedata file");
	}
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	CloseHandle(config);
	sdkDoAnim = EndPrepSDKCall();
	if (sdkDoAnim == INVALID_HANDLE)
	{
		SetFailState("Cant initialize CTerrorPlayer::DoAnimationEvent SDKCall, Signature broken");
	}
} 
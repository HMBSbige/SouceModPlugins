#define PLUGIN_VERSION "1.5.0"
	
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
 
new MODEL_DEFIB;
new const String:WeaponNames[][] =
{
	"weapon_pumpshotgun",
	"weapon_autoshotgun",
	"weapon_rifle",
	"weapon_smg",
	"weapon_hunting_rifle",
	"weapon_sniper_scout",
	"weapon_sniper_military",
	"weapon_sniper_awp",
	"weapon_smg_silenced",
	"weapon_smg_mp5",
	"weapon_shotgun_spas",
	"weapon_shotgun_chrome",
	"weapon_rifle_sg552",
	"weapon_rifle_desert",
	"weapon_rifle_ak47",
	"weapon_grenade_launcher",
	"weapon_rifle_m60", //0-16
	"weapon_pistol",
	"weapon_pistol_magnum",
	"weapon_chainsaw",
	"weapon_melee", //17-20
	"weapon_pipe_bomb",
	"weapon_molotov",
	"weapon_vomitjar", //21-23
	"weapon_first_aid_kit",
	"weapon_defibrillator",
	"weapon_upgradepack_explosive",
	"weapon_upgradepack_incendiary", //24-27
	"weapon_pain_pills",
	"weapon_adrenaline", //28-29
	"weapon_gascan",
	"weapon_propanetank",
	"weapon_oxygentank",
	"weapon_gnome",
	"weapon_cola_bottles",
	"weapon_fireworkcrate" //30-35
}

public Plugin:myinfo =
{
	name = "[L4D2] Weapon Drop",
	author = "HMBSbige",
	description = "Allows players to drop the weapon they are holding",
	version = PLUGIN_VERSION,
	url = "https://github.com/HMBSbige"
};

public OnPluginStart()
{
	RegConsoleCmd("sm_drop", Command_Drop);
	CreateConVar("sm_drop_version", PLUGIN_VERSION, "[L4D2] Weapon Drop Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	LoadTranslations("common.phrases");
}
public OnMapStart()
{
	MODEL_DEFIB = PrecacheModel("models/w_models/weapons/w_eq_defibrillator.mdl", true);
}
public Action:Command_Drop(client, args)
{
	if (args == 1 || args > 2)
	{
		if (GetAdminFlag(GetUserAdmin(client), Admin_Root))
			ReplyToCommand(client, "[SM] Usage: sm_drop <#userid|name> <slot to drop>");
	}
	else if (args < 1)
	{
		new slot;
		decl String:weapon[32];
		GetClientWeapon(client, weapon, sizeof(weapon));
		for (new count=0; count<=35; count++)
		{
			switch(count)
			{
				case 17: slot = 1;
				case 21: slot = 2;
				case 24: slot = 3;
				case 28: slot = 4;
				case 30: slot = 5;
			}
			if (StrEqual(weapon, WeaponNames[count]))
			{
				DropSlot(client, slot);
			}
		}
	}
	else if (args == 2)
	{
		if (GetAdminFlag(GetUserAdmin(client), Admin_Root))
		{
			new String:target[MAX_TARGET_LENGTH], String:arg[8];
			GetCmdArg(1, target, sizeof(target));
			GetCmdArg(2, arg, sizeof(arg));
			new slot = StringToInt(arg);

			new targetid = StringToInt(target);
			if (targetid > 0 && IsClientInGame(targetid))
			{
				DropSlot(targetid, slot);
				return Plugin_Handled;
			}

			decl String:target_name[MAX_TARGET_LENGTH];
			decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	
			if ((target_count = ProcessTargetString(
				target,
				client,
				target_list,
				MAXPLAYERS,
				0,
				target_name,
				sizeof(target_name),
				tn_is_ml)) <= 0)
			{
				ReplyToTargetError(client, target_count);
				return Plugin_Handled;
			}
			for (new i=0; i<target_count; i++)
			{
				DropSlot(target_list[i], slot);
			}
		}
	}

	return Plugin_Handled;
}

public DropSlot(client, slot)
{
	if (client > 0 && IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == 2)
	{
		if (GetPlayerWeaponSlot(client, slot) > 0)
		{
			new weapon = GetPlayerWeaponSlot(client, slot);
			SDKCallWeaponDrop(client, weapon);
		}
	}
}

stock SDKCallWeaponDrop(client, weapon)
{
	decl String:classname[32], Float:vecAngles[3], Float:vecTarget[3], Float:vecVelocity[3];
	if (GetPlayerEye(client, vecTarget))
	{
		GetClientEyeAngles(client, vecAngles);
		GetAngleVectors(vecAngles, vecVelocity, NULL_VECTOR, NULL_VECTOR)
		vecVelocity[0] *= 300.0;
		vecVelocity[1] *= 300.0;
		vecVelocity[2] *= 300.0;

		SDKHooks_DropWeapon(client, weapon, NULL_VECTOR, NULL_VECTOR);

		TeleportEntity(weapon, NULL_VECTOR, NULL_VECTOR, vecVelocity)
		GetEdictClassname(weapon, classname, sizeof(classname));
		if (StrEqual(classname,"weapon_defibrillator"))
		{
			SetEntProp(weapon, Prop_Send, "m_iWorldModelIndex", MODEL_DEFIB);
		}
	}
}
stock bool:GetPlayerEye(client, Float:vecTarget[3]) 
{
	decl Float:Origin[3], Float:Angles[3];
	GetClientEyePosition(client, Origin);
	GetClientEyeAngles(client, Angles);

	new Handle:trace = TR_TraceRayFilterEx(Origin, Angles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);
	if (TR_DidHit(trace)) 
	{
		TR_GetEndPosition(vecTarget, trace);
		CloseHandle(trace);
		return true;
	}
	CloseHandle(trace);
	return false;
}

public bool:TraceEntityFilterPlayer(entity, contentsMask)
{
	return entity > GetMaxClients() || !entity;
}
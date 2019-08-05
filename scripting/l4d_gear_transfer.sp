#define PLUGIN_VERSION		"1.6.1.1"

/*=======================================================================================
	Plugin Info:

*	Name	:	[L4D & L4D2] Gear Transfer
*	Author	:	SilverShot
*	Descrp	:	Survivor bots can automatically pickup and give items. Players can switch, grab or give items.
*	Link	:	http://forums.alliedmods.net/showthread.php?t=137616
*	Plugins	:	http://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

1.6.1.1 (09-May-2019) (Dragokas)
	- Added detection of sex additionally by character (for custom models).

1.6.1 (14-Aug-2018)
	- Removed LogError "Tracer Bug".

1.6.0 (05-May-2018)
	- Converted plugin source to the latest syntax utilizing methodmaps. Requires SourceMod 1.8 or newer.
	- Changed cvar "l4d_gear_transfer_modes_tog" now supports L4D1.

1.5.12 (17-Jul-2017)
	- Fixed invalid entity error - Thanks to "Newbie_Sexy" for reporting and "Visual77" for some code.

1.5.11 (25-Jun-2017)
	- Fixed client not connected errors - Thanks to "Lux" for reporting.
	- Fixed depreciated FCVAR_PLUGIN flag.

1.5.10 (10-May-2012)
	- Added Traditional Chinese translations - Thanks to "bazrael".
	- Added cvar "l4d_gear_transfer_vocalize" to control transfer vocalizes - Thanks to "bazrael" for the request.

1.5.9 (31-Mar-2012)
	- Fixed the last update breaking auto give and auto grab.

1.5.8 (30-Mar-2012)
	- Added Russian translations - Thanks to "disawar1".
	- Added cvar "l4d_gear_transfer_modes_on" to control which game modes the plugin works in.
	- Added cvar "l4d_gear_transfer_modes_tog" same as above, but only works for L4D2.

1.5.7 (18-Oct-2011)
	- Fires the item_pickup and player_use events when bots auto grab. Required for Footlocker Spawner 1.2+.

1.5.6 (20-Apr-2011)
	- Added cvar 'l4d_gear_transfer_modes_off' to turn off the plugin on certain game modes.
	- Fixed deleting grenade spawns which give infinite items.

1.5.5 (30-Jan-2011)
	- Changed the bot allow cvars (as requested by "LTR.2") so you can specify which items bots auto give/grab.

1.5.4 (06-Jan-2011)
	- Another attempt to fix 'm_humanSpectatorUserID' errors.
	- Added chat notifications block from round start the same as vocalize block.

1.5.3 (04-Jan-2011)
	- Changed the previous check to make sure the netclass is 'SurvivorBot', should stop all related errors.

1.5.2 (02-Jan-2011)
	- Added check for 'bebop_bot_fakeclient' which caused errors.
	- Removed the -attack2 after shoves thanks to Valve patching some client commands.

1.5.1 (09-Dec-2010)
	- Added IsVisibleTo for player to player transfers (stops transfers through walls!).
	- Fixed auto give transferring directly after a player to player transfer.

1.5.0 (03-Dec-2010)
	- Optimized a lot code.
	- Fixed allow cvars not restricting their correct items.
	- Added cvar 'l4d_gear_transfer_modes' to disable auto give/grab in listed game modes.
	- Added cvar 'l4d_gear_transfer_timer_item' to specify how often the auto grab item list updates.
	- Added delay to auto give when switching items with bots.
	- Added vocalize block for 60 seconds from round start.
	- Added check for translation file.
	- Added finale_vehicle_leaving event to disable auto give/grab.
	- Added notifications for auto give/grab when 'l4d_gear_transfer_notify' is enabled.
	- Removed hint text when l4d_gear_transfer_notify set to 2. Now only shows chat notifications.

1.4.11 (27-Oct-2010)
	- Added ("-attack2") to stop shoving after successful transfer.
	- Added FCVAR_DONTRECORD flag to the version cvar.

1.4.10 (21-Oct-2010)
	- Fixed 'switch' translation being given the wrong weapon name.
	- Changed weapon name text color to yellow.

1.4.9 (19-Oct-2010)
	- Fixed player_shoved transfers not working because of a missing exclamation mark!

1.4.8 (16-Oct-2010)
	- Fixed Infected receiving items.

1.4.7 (16-Oct-2010)
	- Optimized auto give a little.

1.4.6 (16-Oct-2010)
	- Re-added FileExists check for scenes, now using Valve's Filesystem!
	- Small changes.

1.4.5 (14-Oct-2010)
	- Re-added player_shoved event to transfer items.
	- Removed FileExists check from scenes, now vocalizes L4D1 characters!

1.4.4 (12-Oct-2010)
	- Fixed creating dupe grenades when throwing.

1.4.3 (12-Oct-2010)
	- Fixed AutoTimer rubbish!
	- Stopped auto give/grab when survivor is incapped/reviving.

1.4.2 (10-Oct-2010)
	- Small fixes.

1.4.1 (07-Oct-2010)
	- Added diplaying transfers in chat messages with translations.
	- Changed some vocalize parts for The Sacrifice update.

1.4.0.1 (03-Oct-2010)
	- Fixed disabling shove transfers with first aid.

1.4.0 (03-Oct-2010)
	- Officially supports the first Left4Dead!
	- Added check so bots will not auto grab "projectile" grenades.
	- Added check so bots will not auto grab items who have owners.
	- Added cvars to allow/disallow bots to auto give/grab certain items.
	- Changed cvars to comply with releasing guidelines.
	- Idle players no longer treated as bots.

1.3.0 (01-Oct-2010)
	- Small changes to auto grab.

1.2.9 (29-Sep-2010)
	- Disabled transfers with incapacitated players.
	- Fixed disabling auto give/grab in versus.
	- Changed the fix for auto grab creating two grenades again.
	- Removed player_shoved event, reload+shove transfer from OnPlayerRunCmd.

1.2.8 (27-Sep-2010)
	- Changed the fix for auto grab creating two grenades.

1.2.7 (27-Sep-2010)
	- Fixed auto grab creating two grenades!
	- Delaying all bots for 3 seconds after they receive an item.

1.2.6 (26-Sep-2010)
	- Optimized code.
	- TraceFilter added on survivors so they don't block transfers.

1.2.5 (22-Sep-2010)
	- Delayed bots auto give for 3 seconds after they are given an item.

1.2.4 (21-Sep-2010)
	- Fixed auto give when sb_all_bot_team.

1.2.3 (21-Sep-2010)
	- Added weapon_given hook to stop pills/adrenaline being given back!

1.2.2 (21-Sep-2010)
	- Minor changes.

1.2.1 (21-Sep-2010)
	- Added adrenaline and pain pills to transfers. You can only use the reload key to switch.
	- Added cvars to allow/disallow the above transfers.
	- Added vocalize on first aid kit transfers.

1.2.0 (19-Sep-2010)
	- Renamed more appropriately to "Gear Transfer".
	- Added defibrillators, first aid kits, explosive and incendiary rounds to transfers.
	- Added cvars to allow/disallow the transfer of certain items.
	- Changed the transfer being triggered by the Use key to the Reload key.
	- Disabled auto give/grab in versus games (as they should be full with players!).

1.1.2 (15-Sep-2010)
	- Removed HookSingleEntityOutput, which was causing crashes.

1.1.1 (11-Sep-2010)
	- Some fixes.

1.1.0 (09-Sep-2010)
	- Added "AtomicStryker"'s Vocalize with scenes.

1.03.0 (08-Sep-2010)
	- Removed Vocalize stuff.

1.02.0 (08-Sep-2010)
	- Changed things "AtomicStryker" suggested.

1.0.1 (08-Sep-2010)
	- Fixed UnhookEvent error.
	- Added check in case of over 64 grenades.

1.0.0 (07-Sep-2010)
	- Initial release.

========================================================================================

	This plugin was made using source code from the following plugins.
	If I have used your code and not credited you, please let me know.

*	Thanks to "DJ_WEST" for "[L4D/L4D2] Grenade Transfer"
	http://forums.alliedmods.net/showthread.php?t=122293

*	Thanks to "AtomicStryker" for "[L4D & L4D2] Boomer Splash Damage"
	http://forums.alliedmods.net/showthread.php?t=98794

*	Thanks to "Crimson_Fox" for "[L4D2] Weapon Unlock"
	http://forums.alliedmods.net/showthread.php?t=114296

*	Thanks to "AtomicStryker" for "L4D2 Vocalize ANYTHING"
	http://forums.alliedmods.net/showthread.php?t=122270

======================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define CVAR_FLAGS				FCVAR_NOTIFY
#define MAX_ITEMS				64							// How many items we store

#define SOUND_BIGREWARD			"UI/BigReward.wav"			// Give
#define SOUND_LITTLEREWARD		"UI/LittleReward.wav"		// Receive


// Cvar handles
ConVar g_hCvarAllow, g_hCvarAllowAdr, g_hCvarAllowDef, g_hCvarAllowExp, g_hCvarAllowFir, g_hCvarAllowInc, g_hCvarAllowMol, g_hCvarAllowPil, g_hCvarAllowPip, g_hCvarAllowVom, g_hCvarAutoGive, g_hCvarAutoGrab, g_hCvarBotAdr, g_hCvarBotDef, g_hCvarBotExp, g_hCvarBotFir, g_hCvarBotInc, g_hCvarBotMol, g_hCvarBotPil, g_hCvarBotPip, g_hCvarBotVom, g_hCvarDistGive, g_hCvarDistGrab, g_hCvarMethod, g_hCvarModes, g_hCvarModesOff, g_hCvarModesOn, g_hCvarModesTog, g_hCvarNotify, g_hCvarSounds, g_hCvarTimerAuto, g_hCvarTimerItem, g_hCvarVocalize;

// Cvar variables
int g_iBotAdr, g_iBotDef, g_iBotExp, g_iBotFir, g_iBotInc, g_iBotMol, g_iBotPil, g_iBotPip, g_iBotVom, g_iCvarVocalize, g_iMethod;
bool g_bAllowAdr, g_bAllowDef, g_bAllowExp, g_bAllowFir, g_bAllowInc, g_bAllowMol, g_bAllowPil, g_bAllowPip, g_bAllowVom, g_bAutoGive, g_bAutoGrab, g_bCvarAllow, g_bNotify, g_bSounds;
float g_fDistGive, g_fDistGrab, g_fTimerAuto, g_fTimerItem;

// Game's convar ConVars
ConVar g_hCvarMPGameMode;

// Timer handles
Handle g_hTmrAutoGiveGrab, g_hTmrBlockVocalize, g_hTmrGetItemSpawn, g_hTmrGiveBlocked;

// Variables
bool g_bBlockVocalize, g_bGiveBlocked, g_bModeOffAuto, g_bRoundOver, g_bTranslation, g_bLeft4Dead2;

// Item variables
int g_iItemCount, g_iItemSpawnID[MAX_ITEMS];
bool g_bHasTransferred[64];
float g_fItemSpawn_XYZ[MAX_ITEMS][3];

// Items to transfer
static const char g_Pickups[9][] =
{
	"weapon_molotov", "weapon_pipe_bomb", "weapon_vomitjar", "weapon_first_aid_kit", "weapon_pain_pills", "weapon_adrenaline",
	"weapon_upgradepack_explosive", "weapon_upgradepack_incendiary", "weapon_defibrillator"
};

// Vocalize for Left 4 Dead 2
static const char g_Coach[8][] =
{
	"takepipebomb01", "takepipebomb02", "takepipebomb03", "takemolotov01", "takemolotov02", "takefirstaid01", "takefirstaid02", "takefirstaid03"
};
static const char g_Ellis[15][] =
{
	"takepipebomb01", "takepipebomb02", "takepipebomb03", "takemolotov01", "takemolotov02", "takemolotov03", "takemolotov04", "takemolotov05",
	"takemolotov06", "takemolotov07", "takemolotov08", "takefirstaid01", "takefirstaid02", "takefirstaid03", "takefirstaid04"
};
static const char g_Nick[9][] =
{
	"takepipebomb01", "takepipebomb02", "takemolotov01", "takemolotov02", "takefirstaid01", "takefirstaid02", "takefirstaid03", "takefirstaid04",
	"takefirstaid05"
};
static const char g_Rochelle[9][] =
{
	"takepipebomb01", "takepipebomb02", "takemolotov01", "takemolotov02", "takemolotov03", "takemolotov04", "takefirstaid01", "takefirstaid02",
	"takefirstaid03"
};

// Vocalize for Left 4 Dead
static const char g_Bill[10][] =
{
	"TakePipeBomb01", "TakePipeBomb02", "TakePipeBomb03", "TakePipeBomb04", "TakeMolotov01", "TakeMolotov02", "TakeMolotov03", "TakeFirstAid01",
	"TakeFirstAid02", "TakeFirstAid03"
};
static const char g_Francis[12][] =
{
	"TakePipeBomb01", "TakePipeBomb02", "TakePipeBomb03", "TakePipeBomb04", "TakePipeBomb05", "TakeMolotov01", "TakeMolotov02", "TakeMolotov03",
	"TakeFirstAid01", "TakeFirstAid02", "TakeFirstAid03", "TakeFirstAid04"
};
static const char g_Louis[10][] =
{
	"TakePipeBomb01", "TakePipeBomb02", "TakePipeBomb03", "takepipebomb05", "TakeMolotov01", "TakeMolotov02", "TakeMolotov03", "TakeFirstAid01",
	"TakeFirstAid02", "TakeFirstAid03"
};
static const char g_Zoey[10][] =
{
	"TakePipeBomb02", "takepipebomb04", "TakeMolotov02", "takemolotov04", "takemolotov05", "takemolotov07", "TakeFirstAid01", "TakeFirstAid02",
	"TakeFirstAid03", "takefirstaid05"
};



// ====================================================================================================
//					PLUGIN INFO / START / END
// ====================================================================================================
public Plugin myinfo =
{
	name = "[L4D & L4D2] Gear Transfer",
	author = "SilverShot",
	description = "Survivor bots can automatically pickup and give items. Players can switch, grab or give items.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=137616"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if( test == Engine_Left4Dead ) g_bLeft4Dead2 = false;
	else if( test == Engine_Left4Dead2 ) g_bLeft4Dead2 = true;
	else
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, PLATFORM_MAX_PATH, "%s", "translations/gear_transfer.phrases.txt");
	if( FileExists(sPath) )
	{
		LoadTranslations("gear_transfer.phrases");
		g_bTranslation = true;
	}
	else
	{
		g_bTranslation = false;
	}

	g_hCvarAllowAdr =		CreateConVar(	"l4d_gear_transfer_allow_adr",		"1",			"0=Off, 1=Enables the transfer of adrenaline.", CVAR_FLAGS);
	g_hCvarAllowDef =		CreateConVar(	"l4d_gear_transfer_allow_def",		"1",			"0=Off, 1=Enables the transfer of defibrillators.", CVAR_FLAGS);
	g_hCvarAllowExp =		CreateConVar(	"l4d_gear_transfer_allow_exp",		"1",			"0=Off, 1=Enables the transfer of explosive rounds.", CVAR_FLAGS);
	g_hCvarAllowFir =		CreateConVar(	"l4d_gear_transfer_allow_fir",		"1",			"0=Off, 1=Enables the transfer of first aid kits.", CVAR_FLAGS);
	g_hCvarAllowInc =		CreateConVar(	"l4d_gear_transfer_allow_inc",		"1",			"0=Off, 1=Enables the transfer of incendiary ammo.", CVAR_FLAGS);
	g_hCvarAllowMol =		CreateConVar(	"l4d_gear_transfer_allow_mol",		"1",			"0=Off, 1=Enables the transfer of molotovs.", CVAR_FLAGS);
	g_hCvarAllowPil =		CreateConVar(	"l4d_gear_transfer_allow_pil",		"1",			"0=Off, 1=Enables the transfer of pain pills.", CVAR_FLAGS);
	g_hCvarAllowPip =		CreateConVar(	"l4d_gear_transfer_allow_pip",		"1",			"0=Off, 1=Enables the transfer of pipe bombs.", CVAR_FLAGS);
	g_hCvarAllowVom =		CreateConVar(	"l4d_gear_transfer_allow_vom",		"1",			"0=Off, 1=Enables the transfer of vomit jars.", CVAR_FLAGS);
	g_hCvarAutoGive =		CreateConVar(	"l4d_gear_transfer_auto_give",		"1",			"0=Off, 1=Enables. Make bots give their items to players with none.", CVAR_FLAGS);
	g_hCvarAutoGrab =		CreateConVar(	"l4d_gear_transfer_auto_grab",		"1",			"0=Off, 1=Enables. Make bots automatically pick up nearby items.", CVAR_FLAGS);
	g_hCvarBotAdr =			CreateConVar(	"l4d_gear_transfer_bot_adr",		"1",			"0=Off, 1=Both, 2=Bots can give, 3=Bots can grab adrenaline.", CVAR_FLAGS);
	g_hCvarBotDef =			CreateConVar(	"l4d_gear_transfer_bot_def",		"1",			"0=Off, 1=Both, 2=Bots can give, 3=Bots can grab defibrillators.", CVAR_FLAGS);
	g_hCvarBotExp =			CreateConVar(	"l4d_gear_transfer_bot_exp",		"1",			"0=Off, 1=Both, 2=Bots can give, 3=Bots can grab explosive rounds.", CVAR_FLAGS);
	g_hCvarBotFir =			CreateConVar(	"l4d_gear_transfer_bot_fir",		"1",			"0=Off, 1=Both, 2=Bots can give, 3=Bots can grab first aid kits.", CVAR_FLAGS);
	g_hCvarBotInc =			CreateConVar(	"l4d_gear_transfer_bot_inc",		"1",			"0=Off, 1=Both, 2=Bots can give, 3=Bots can grab incendiary ammo.", CVAR_FLAGS);
	g_hCvarBotMol =			CreateConVar(	"l4d_gear_transfer_bot_mol",		"1",			"0=Off, 1=Both, 2=Bots can give, 3=Bots can grab molotovs.", CVAR_FLAGS);
	g_hCvarBotPil =			CreateConVar(	"l4d_gear_transfer_bot_pil",		"1",			"0=Off, 1=Both, 2=Bots can give, 3=Bots can grab pain pills.", CVAR_FLAGS);
	g_hCvarBotPip =			CreateConVar(	"l4d_gear_transfer_bot_pip",		"1",			"0=Off, 1=Both, 2=Bots can give, 3=Bots can grab pipe bombs.", CVAR_FLAGS);
	g_hCvarBotVom =			CreateConVar(	"l4d_gear_transfer_bot_vom",		"1",			"0=Off, 1=Both, 2=Bots can give, 3=Bots can grab vomit jars.", CVAR_FLAGS);
	g_hCvarDistGive =		CreateConVar(	"l4d_gear_transfer_dist_give",		"150.0",		"How close you have to be to transfer an item.", CVAR_FLAGS);
	g_hCvarDistGrab =		CreateConVar(	"l4d_gear_transfer_dist_grab",		"150.0",		"How close the bots need to be for them to pick up an item.", CVAR_FLAGS);
	g_hCvarAllow =			CreateConVar(	"l4d_gear_transfer_enabled",		"1",			"0=Plugin off, 1=Plugin On.", CVAR_FLAGS);
	g_hCvarMethod =			CreateConVar(	"l4d_gear_transfer_method",			"2",			"0=Shove only, 1=Reload key only, 2=Shove and Reload key to transfer items.", CVAR_FLAGS);
	g_hCvarModes =			CreateConVar(	"l4d_gear_transfer_modes",			"versus",		"Disallow bots from auto give/grab in these game modes.", CVAR_FLAGS);
	g_hCvarModesOff =		CreateConVar(	"l4d_gear_transfer_modes_off",		"",				"Turn off the plugin in these game modes, separate by commas (no spaces). (Empty = none).", CVAR_FLAGS );
	g_hCvarModesOn =		CreateConVar(	"l4d_gear_transfer_modes_on",		"",				"Turn on the plugin in these game modes, separate by commas (no spaces). (Empty = all).", CVAR_FLAGS );
	g_hCvarModesTog =		CreateConVar(	"l4d_gear_transfer_modes_tog",		"0",			"Turn on the plugin in these game modes. 0=All, 1=Coop, 2=Survival, 4=Versus, 8=Scavenge. Add numbers together.", CVAR_FLAGS );
	g_hCvarNotify =			CreateConVar(	"l4d_gear_transfer_notify",			"1",			"0=Off, 1=Display transfer info to everyone through chat messages.", CVAR_FLAGS);
	g_hCvarSounds =			CreateConVar(	"l4d_gear_transfer_sounds",			"1",			"0=Off, 1=Play a sound to the person giving/receiving an item.", CVAR_FLAGS);
	g_hCvarTimerAuto =		CreateConVar(	"l4d_gear_transfer_timer",			"1.0",			"How often to check the bot positions to survivors/items for auto give/grab.", CVAR_FLAGS, true, 0.5, true, 10.0);
	g_hCvarTimerItem =		CreateConVar(	"l4d_gear_transfer_timer_item",		"5.0",			"How often to update all the item positions for auto grab.", CVAR_FLAGS, true, 5.0, true, 30.0);
	g_hCvarVocalize =		CreateConVar(	"l4d_gear_transfer_vocalize",		"1",			"0=Off. 1=Players vocalize when transferring items.", CVAR_FLAGS);
	CreateConVar(							"l4d_gear_transfer_version",		PLUGIN_VERSION, "Gear Transfer plugin version.", CVAR_FLAGS|FCVAR_DONTRECORD);
	AutoExecConfig(true,					"l4d_gear_transfer");

	g_hCvarMPGameMode = FindConVar("mp_gamemode");
	g_hCvarMPGameMode.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesOff.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesOn.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesTog.AddChangeHook(ConVarChanged_Allow);
	g_hCvarAllow.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModes.AddChangeHook(ConVarChanged_AutoMode);
	g_hCvarAllowAdr.AddChangeHook(ConVarChanged_CvarAllow);
	g_hCvarAllowDef.AddChangeHook(ConVarChanged_CvarAllow);
	g_hCvarAllowExp.AddChangeHook(ConVarChanged_CvarAllow);
	g_hCvarAllowFir.AddChangeHook(ConVarChanged_CvarAllow);
	g_hCvarAllowMol.AddChangeHook(ConVarChanged_CvarAllow);
	g_hCvarAllowInc.AddChangeHook(ConVarChanged_CvarAllow);
	g_hCvarAllowPil.AddChangeHook(ConVarChanged_CvarAllow);
	g_hCvarAllowPip.AddChangeHook(ConVarChanged_CvarAllow);
	g_hCvarAllowVom.AddChangeHook(ConVarChanged_CvarAllow);
	g_hCvarAutoGive.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarAutoGrab.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarBotAdr.AddChangeHook(ConVarChanged_CvarBot);
	g_hCvarBotDef.AddChangeHook(ConVarChanged_CvarBot);
	g_hCvarBotExp.AddChangeHook(ConVarChanged_CvarBot);
	g_hCvarBotFir.AddChangeHook(ConVarChanged_CvarBot);
	g_hCvarBotMol.AddChangeHook(ConVarChanged_CvarBot);
	g_hCvarBotInc.AddChangeHook(ConVarChanged_CvarBot);
	g_hCvarBotPil.AddChangeHook(ConVarChanged_CvarBot);
	g_hCvarBotPip.AddChangeHook(ConVarChanged_CvarBot);
	g_hCvarBotVom.AddChangeHook(ConVarChanged_CvarBot);
	g_hCvarDistGive.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarDistGrab.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarMethod.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarNotify.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarSounds.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarTimerAuto.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarTimerItem.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarVocalize.AddChangeHook(ConVarChanged_Cvars);

	GetCvarsA();
	GetCvarsB();
	GetCvarsC();

	for( int i = 0; i < MAX_ITEMS; i++ )
		ResetItemArray(i);
}

public void OnMapStart()
{
	PrecacheSound(SOUND_LITTLEREWARD);
	PrecacheSound(SOUND_BIGREWARD);
}



// ====================================================================================================
//					CVARS
// ====================================================================================================
public void OnConfigsExecuted()
{
	GetCvarsA();
	GetCvarsB();
	GetCvarsC();
	IsAllowed();
}

public void ConVarChanged_Allow(Handle convar, const char[] oldValue, const char[] newValue)
{
	IsAllowed();
}

public void ConVarChanged_AutoMode(Handle convar, const char[] oldValue, const char[] newValue)
{
	char sGameModes[64], sGameMode[64];
	g_hCvarMPGameMode.GetString(sGameMode, sizeof(sGameMode));
	g_hCvarModes.GetString(sGameModes, sizeof(sGameModes));
	Format(sGameMode, sizeof(sGameMode), ",%s,", sGameMode);
	Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
	g_bModeOffAuto = (StrContains(sGameModes, sGameMode) != -1);
}

public void ConVarChanged_CvarAllow(Handle convar, const char[] oldValue, const char[] newValue)
{
	GetCvarsA();
}

public void ConVarChanged_CvarBot(Handle convar, const char[] oldValue, const char[] newValue)
{
	GetCvarsB();
}

public void ConVarChanged_Cvars(Handle convar, const char[] oldValue, const char[] newValue)
{
	GetCvarsC();
	MakeTimers();
}

void GetCvarsA()
{
	g_bAllowAdr = g_hCvarAllowAdr.BoolValue;
	g_bAllowDef = g_hCvarAllowDef.BoolValue;
	g_bAllowExp = g_hCvarAllowExp.BoolValue;
	g_bAllowFir = g_hCvarAllowFir.BoolValue;
	g_bAllowInc = g_hCvarAllowInc.BoolValue;
	g_bAllowMol = g_hCvarAllowMol.BoolValue;
	g_bAllowPil = g_hCvarAllowPil.BoolValue;
	g_bAllowPip = g_hCvarAllowPip.BoolValue;
	g_bAllowVom = g_hCvarAllowVom.BoolValue;
}

void GetCvarsB()
{
	g_iBotAdr = g_hCvarBotAdr.IntValue;
	g_iBotDef = g_hCvarBotDef.IntValue;
	g_iBotExp = g_hCvarBotExp.IntValue;
	g_iBotFir = g_hCvarBotFir.IntValue;
	g_iBotInc = g_hCvarBotInc.IntValue;
	g_iBotMol = g_hCvarBotMol.IntValue;
	g_iBotPil = g_hCvarBotPil.IntValue;
	g_iBotPip = g_hCvarBotPip.IntValue;
	g_iBotVom = g_hCvarBotVom.IntValue;
}

void GetCvarsC()
{
	g_bAutoGive = g_hCvarAutoGive.BoolValue;
	g_bAutoGrab = g_hCvarAutoGrab.BoolValue;
	g_fDistGive = g_hCvarDistGive.FloatValue;
	g_fDistGrab = g_hCvarDistGrab.FloatValue;
	g_iMethod = g_hCvarMethod.IntValue;
	g_bNotify = g_hCvarNotify.BoolValue;
	g_bSounds = g_hCvarSounds.BoolValue;
	g_fTimerAuto = g_hCvarTimerAuto.FloatValue;
	g_fTimerItem = g_hCvarTimerItem.FloatValue;
	g_iCvarVocalize = g_hCvarVocalize.IntValue;
}

void IsAllowed()
{
	bool bCvarAllow = g_hCvarAllow.BoolValue;
	bool bAllowMode = IsAllowedGameMode();

	if( g_bCvarAllow == false && bCvarAllow == true && bAllowMode == true )
	{
		for( int i = 0; i < MAX_ITEMS; i++ )
			ResetItemArray(i);
		g_bCvarAllow = true;
		MakeTimers();

		HookEvent("round_start",				Event_RoundStart,	EventHookMode_PostNoCopy);
		HookEvent("round_end",					Event_RoundEnd,		EventHookMode_PostNoCopy);
		HookEvent("finale_vehicle_leaving",		Event_RoundEnd,		EventHookMode_PostNoCopy);
		HookEvent("spawner_give_item",			Event_SpawnerGiveItem);
		HookEvent("weapon_fire",				Event_WeaponFire);
		HookEvent("weapon_given",				Event_WeaponGiven);
		HookEvent("player_shoved",				Event_PlayerShoved);
	}

	else if( g_bCvarAllow == true && (bCvarAllow == false || bAllowMode == false) )
	{
		g_bCvarAllow = false;

		UnhookEvent("round_start",				Event_RoundStart,	EventHookMode_PostNoCopy);
		UnhookEvent("round_end",				Event_RoundEnd,		EventHookMode_PostNoCopy);
		UnhookEvent("finale_vehicle_leaving",	Event_RoundEnd,		EventHookMode_PostNoCopy);
		UnhookEvent("spawner_give_item",		Event_SpawnerGiveItem);
		UnhookEvent("weapon_fire",				Event_WeaponFire);
		UnhookEvent("weapon_given",				Event_WeaponGiven);
		UnhookEvent("player_shoved",			Event_PlayerShoved);
	}
}

int g_iCurrentMode;
bool IsAllowedGameMode()
{
	if( g_hCvarMPGameMode == null )
		return false;

	int iCvarModesTog = g_hCvarModesTog.IntValue;
	if( iCvarModesTog != 0 )
	{
		g_iCurrentMode = 0;

		int entity = CreateEntityByName("info_gamemode");
		DispatchSpawn(entity);
		HookSingleEntityOutput(entity, "OnCoop", OnGamemode, true);
		HookSingleEntityOutput(entity, "OnSurvival", OnGamemode, true);
		HookSingleEntityOutput(entity, "OnVersus", OnGamemode, true);
		HookSingleEntityOutput(entity, "OnScavenge", OnGamemode, true);
		ActivateEntity(entity);
		AcceptEntityInput(entity, "PostSpawnActivate");
		AcceptEntityInput(entity, "Kill");

		if( g_iCurrentMode == 0 )
			return false;

		if( !(iCvarModesTog & g_iCurrentMode) )
			return false;
	}

	char sGameModes[64], sGameMode[64];
	g_hCvarMPGameMode.GetString(sGameMode, sizeof(sGameMode));
	Format(sGameMode, sizeof(sGameMode), ",%s,", sGameMode);

	g_hCvarModesOn.GetString(sGameModes, sizeof(sGameModes));
	if( strcmp(sGameModes, "") )
	{
		Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
		if( StrContains(sGameModes, sGameMode, false) == -1 )
			return false;
	}

	g_hCvarModesOff.GetString(sGameModes, sizeof(sGameModes));
	if( strcmp(sGameModes, "") )
	{
		Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
		if( StrContains(sGameModes, sGameMode, false) != -1 )
			return false;
	}

	return true;
}

public void OnGamemode(const char[] output, int caller, int activator, float delay)
{
	if( strcmp(output, "OnCoop") == 0 )
		g_iCurrentMode = 1;
	else if( strcmp(output, "OnSurvival") == 0 )
		g_iCurrentMode = 2;
	else if( strcmp(output, "OnVersus") == 0 )
		g_iCurrentMode = 4;
	else if( strcmp(output, "OnScavenge") == 0 )
		g_iCurrentMode = 8;
}



// ======================================================================================
//					EVENT - START / END
// ======================================================================================
public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	g_bRoundOver = false;

	// Vocalize block
	if( g_iCvarVocalize && (g_bAutoGive || g_bAutoGrab) )
	{
		if( g_hTmrBlockVocalize != null ) delete g_hTmrBlockVocalize;
		g_hTmrBlockVocalize = CreateTimer(60.0, tmrUnblockVocalize);
		g_bBlockVocalize = true;
	}

	for( int i = 0; i < MAX_ITEMS; i++ )
		ResetItemArray(i);

	MakeTimers();
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	g_bRoundOver = true;

	if( g_hTmrAutoGiveGrab != null ) delete g_hTmrAutoGiveGrab;
	if( g_hTmrGetItemSpawn != null ) delete g_hTmrGetItemSpawn;
}



// ======================================================================================
//					EVENT - SPAWNER GIVE ITEM
// ======================================================================================
public void Event_SpawnerGiveItem(Event event, const char[] name, bool dontBroadcast)
// Delete the last item picked up from a weapon_spawn to stop bots auto grabbing nothing!
{
	if( !g_bAutoGrab )					// Bug only with auto grab
		return;

	int ent = event.GetInt("spawner");
	if (ent <= MaxClients || ent > 2048 || !IsValidEdict(ent)) return;

	int flag = GetEntProp(ent, Prop_Data, "m_spawnflags");
	if( flag & (1<<3) ) return;	// Infinite ammo
	int value = GetEntProp(ent, Prop_Data, "m_itemCount");
	if( value > 1 )	return;		// We only need to delete if theres 1 item at the spawn

	char s_EdictClassName[32];
	GetEdictClassname(ent, s_EdictClassName, sizeof(s_EdictClassName));	// Item name

	for( int i = 0; i < 3; i++ )
	{
		if( StrContains(s_EdictClassName, g_Pickups[i], false) != -1 )			// Item must be a grenade
			AcceptEntityInput(ent, "kill");
	}
}



// ======================================================================================
//					EVENT - WEAPON  FIRE
// ======================================================================================
// This event stops duplicate grenades being created when someone throws and tries to transfer
public void Event_WeaponFire(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if( IsFakeClient(client) || GetClientTeam(client) != 2 )
		return;

	char sWeapon[10];
	event.GetString("weapon", sWeapon, 10);

	if( strcmp(sWeapon, "pipe_bomb") == 0 || strcmp(sWeapon, "molotov") == 0 || strcmp(sWeapon, "vomitjar") == 0 )
	{
		g_bHasTransferred[client] = true;
		CreateTimer(2.0, tmrResetTransfer, client);
	}
}



// ======================================================================================
//					EVENT - PILLS / ADREN GIVEN
// ======================================================================================
// This event stops pills/adren being auto grabbed by bots after you have given to them
public void Event_WeaponGiven(Event event, const char[] name, bool dontBroadcast)
{
	int i_Weapon = event.GetInt("weapon");

	if( i_Weapon == 15 || i_Weapon == 23 )
	{
		int i_UserID = GetClientOfUserId(event.GetInt("giver"));
		if( IsFakeClient(i_UserID) )
			return;

		if( g_bAutoGive )
		{
			g_bGiveBlocked = true;
			if( g_hTmrGiveBlocked != null )
				delete g_hTmrGiveBlocked;
			g_hTmrGiveBlocked = CreateTimer(5.0, tmrResetGive);
		}
	}
}



// ======================================================================================
//					EVENT - PLAYER SHOVED
// ======================================================================================
public void Event_PlayerShoved(Event event, const char[] name, bool dontBroadcast)
{
	if( g_iMethod == 1 ) // Reload key only
		return;

	int i_Victim = GetClientOfUserId(event.GetInt("userid"));
	if( GetClientTeam(i_Victim) != 2 || !IsPlayerAlive(i_Victim) )
		return;

	int i_Attacker = GetClientOfUserId(event.GetInt("attacker"));
	if( IsFakeClient(i_Attacker) || g_bHasTransferred[i_Attacker] ) // They just transferred
		return;

	TransferItem(i_Attacker, i_Victim, true);
}



// ======================================================================================
//					ON PLAYER RUN CMD
// ======================================================================================
public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if( !g_bCvarAllow || g_bRoundOver || !IsClientInGame(client) || IsFakeClient(client) || GetClientTeam(client) != 2 )
		return;

	bool b_FromShove;

	if( buttons & IN_RELOAD )
	{
		if( g_iMethod == 0 ) // 0 = Shove key only
			return;
	}
	if( buttons & IN_ATTACK2 )
	{
		if( g_iMethod == 1 ) // 1 = Reload key only
			return;

		b_FromShove = true;
	}

	if( buttons & IN_RELOAD || buttons & IN_ATTACK2 )
	{
		if( g_bHasTransferred[client] )						// They just transferred, return
			return;

		int target = GetClientAimTarget(client, true);		// They must be aiming at an alive survivor

		if( target < 1 || GetClientTeam(target) != 2 || !IsPlayerAlive(target) )
			return;

		float f_Client[3], f_Target[3], f_Distance;

		GetClientAbsOrigin(client, f_Client);			// Get attacker position
		GetClientAbsOrigin(target, f_Target);			// Get target position
		f_Distance = GetVectorDistance(f_Client, f_Target);

		if( f_Distance <= g_fDistGive && IsVisibleTo(f_Client, f_Target) )		// They are within range and visible
			TransferItem(client, target, b_FromShove);
	}
}



// ======================================================================================
//					TRANSFER ITEM
// ======================================================================================
void TransferItem(int i_Attacker, int i_Victim, bool b_FromShove)
{
	// Don't allow transfers while incapped
	if( IsReviving(i_Attacker) || IsIncapped(i_Attacker) || IsReviving(i_Victim) || IsIncapped(i_Victim) )
		return;

	// Declare variables
	int i;
	int i_Slot;
	bool HoldingGrenade;		// Attacker is holding a grenade
	bool HoldingMedSlot;		// Attacker is holding pain pills / adrenaline
	bool HoldingSpecial;		// Attacker is holding medkit; defib or upgrade ammo
	bool AttackerHolding;		// Attacker has item in hand
	bool AttackerGrenade;		// Attacker has a grenade
	bool AttackerSpecial;		// Attacker has first aid; defib or upgrade ammo
	bool AttackerMedSlot;		// Attacker has pain pills or adrenaline
	bool VictimGrenade;			// Bot has a grenade
	bool VictimSpecial;			// Bot has first aid; defib or upgrade ammo
	bool VictimMedSlot;			// Bot has pain plls or adrenaline
	bool VictimIsFake;
	char s_Weapon[40];	// Player weapon
	char s_BotsItem[40];		// Temp string
	char s_BotGrenade[40];	// Bot molotov/pipebomb/vomitjar
	char s_BotSpecial[40];	// Bot firstaidkit/defib/incendiary/explosive
	char s_BotMedSlot[40];	// Bot pain pills/adrenaline


	// Fill variables
	if( IsFakeClient(i_Victim) )
		VictimIsFake = true;

	GetClientWeapon(i_Attacker, s_Weapon, sizeof(s_Weapon));
	i = GetItemNumber(s_Weapon);

	if( i >= 0 && i <= 2 )
		HoldingGrenade = true;
	else if( i == 4 || i == 5 )
		HoldingMedSlot = true;
	else if( i == 3 || i >= 6 )
		HoldingSpecial = true;

	if( i != -1 )
		AttackerHolding = true;						// Switch, give

	if( b_FromShove && i == 3 )						// Don't allow medkits to be transferred from shoves, so they can heal others!
		return;

	i = GetPlayerWeaponSlot(i_Attacker, 2);			// Attacker has grenade
	if( i != -1 )
		AttackerGrenade = true;

	i = GetPlayerWeaponSlot(i_Attacker, 3);			// Attacker has special
	if( i != -1 )
		AttackerSpecial = true;

	i = GetPlayerWeaponSlot(i_Attacker, 4);			// Attacker has MedSlot
	if( i != -1 )
		AttackerMedSlot = true;

	i = GetPlayerWeaponSlot(i_Victim, 2);			// Victim grenade
	if( i != -1 )
	{
		GetEdictClassname(i, s_BotGrenade, sizeof(s_BotGrenade));
		VictimGrenade = true;
	}

	i = GetPlayerWeaponSlot(i_Victim, 3);			// Victim special
	if( i != -1 )
	{
		GetEdictClassname(i, s_BotSpecial, sizeof(s_BotSpecial));
		VictimSpecial = true;
	}

	i = GetPlayerWeaponSlot(i_Victim, 4);			// Victim MedSlot
	if( i != -1 )
	{
		GetEdictClassname(i, s_BotMedSlot, sizeof(s_BotMedSlot));
		VictimMedSlot = true;
	}


	// ########## GIVE ##########  -  If player with an item has shoved a survivor without an item, transfer
	if( AttackerHolding )
	{
		if( HoldingGrenade && AttackerGrenade && !VictimGrenade
		|| HoldingSpecial && AttackerSpecial && !VictimSpecial
		|| HoldingMedSlot && AttackerMedSlot && !VictimMedSlot )
		{
			// Don't allow humans to transfer after giving, and bots to transfer after receiving
			g_bHasTransferred[i_Attacker] = true;
			CreateTimer(1.0, tmrResetTransfer, i_Attacker);

			if( !AllowedToTransfer(s_Weapon) )
				return;

			if( HoldingMedSlot )
			{
				if( b_FromShove )	// Don't transfer pills/adren from shoves, the game already does this!
					return;
				i_Slot = 4;
			}
			else if( HoldingGrenade )
			{
				i_Slot = 2;
			}
			else
			{
				i_Slot = 3;
			}

			if( VictimIsFake && g_bAutoGive )
			{
				g_bGiveBlocked = true;
				if( g_hTmrGiveBlocked != null )
					delete g_hTmrGiveBlocked;
				g_hTmrGiveBlocked = CreateTimer(5.0, tmrResetGive);
			}

			if( g_bSounds )
			{
				PlaySound(i_Victim, SOUND_LITTLEREWARD);
				PlaySound(i_Attacker, SOUND_BIGREWARD);
			}

			StripWeapon(i_Attacker, i_Slot);
			GiveItem(i_Victim, s_Weapon);
			Vocalize(i_Victim, s_Weapon);

			if( g_bNotify && g_bTranslation && !g_bBlockVocalize )
				CPrintToChatAll("\x05%N \x01%t \x04%t \x01%t \x05%N", i_Attacker, "Gave", s_Weapon, "To", i_Victim);

			return;
		}
	}


	if( VictimIsFake && !HasSpectator(i_Victim) )
	{
		// ########## SWITCH ##########  -  If player with an item has shoved a bot also with an item, switch!
		if( AttackerHolding )
		{
			if( HoldingGrenade && AttackerGrenade && VictimGrenade
			|| HoldingSpecial && AttackerSpecial && VictimSpecial
			|| HoldingMedSlot && AttackerMedSlot && VictimMedSlot )
			{
				if( !AllowedToTransfer(s_Weapon) )		// Is the client allowed to switch this item
					return;

				g_bHasTransferred[i_Attacker] = true;
				CreateTimer(1.0, tmrResetTransfer, i_Attacker);

				if( HoldingMedSlot )
				{
					s_BotsItem = s_BotMedSlot;
					i_Slot = 4;
				}
				else if( HoldingGrenade && AttackerGrenade && VictimGrenade )
				{
					s_BotsItem = s_BotGrenade;
					i_Slot = 2;
				}
				else if( HoldingSpecial && AttackerSpecial && VictimSpecial )
				{
					s_BotsItem = s_BotSpecial;
					i_Slot = 3;
				}

				if( !AllowedToTransfer(s_BotsItem) )
					return;

				if( g_bAutoGive )
				{
					g_bGiveBlocked = true;
					if( g_hTmrGiveBlocked != null )
						delete g_hTmrGiveBlocked;
					g_hTmrGiveBlocked = CreateTimer(5.0, tmrResetGive);
				}

				StripWeapon(i_Attacker, i_Slot);
				StripWeapon(i_Victim, i_Slot);
				GiveItem(i_Attacker, s_BotsItem);
				GiveItem(i_Victim, s_Weapon);
				Vocalize(i_Attacker, s_BotsItem);

				// Switch to previous weapon to stop the bug where Molotovs appear with Pipe particles and vice versa.
				ClientCommand(i_Attacker, "lastinv");

				if( g_bSounds )
				{
					PlaySound(i_Victim, SOUND_LITTLEREWARD);
					PlaySound(i_Attacker, SOUND_BIGREWARD);
				}

				if( g_bNotify && g_bTranslation && !g_bBlockVocalize )
				{
					CPrintToChatAll("\x05%N \x01%t \x04%t \x01%t \x05%N", i_Attacker, "Switched", s_Weapon, "With", i_Victim);
					CPrintToChatAll("\x05%N \x01%t \x04%t \x01%t \x05%N", i_Victim, "Gave", s_BotsItem, "To", i_Attacker);
				}

				return;
			}
		}


		// ########## GRAB ##########  -  If player with no grenade has shoved a bot with a grenade, transfer
		if( !AttackerGrenade && VictimGrenade
		|| !AttackerSpecial && VictimSpecial
		|| !AttackerMedSlot && VictimMedSlot )
		{

			g_bHasTransferred[i_Attacker] = true;
			CreateTimer(1.0, tmrResetTransfer, i_Attacker);

			if( !AttackerMedSlot && VictimMedSlot )
			{
				s_BotsItem = s_BotMedSlot;
				i_Slot = 4;
			}
			else if( !AttackerGrenade && VictimGrenade )
			{
				s_BotsItem = s_BotGrenade;
				i_Slot = 2;
			}
			else if( !AttackerSpecial && VictimSpecial )
			{
				s_BotsItem = s_BotSpecial;
				i_Slot = 3;
			}

			if( !AllowedToTransfer(s_BotsItem) )
				return;

			if( g_bSounds )
				PlaySound(i_Attacker, SOUND_LITTLEREWARD); // Received item

			StripWeapon(i_Victim, i_Slot);
			GiveItem(i_Attacker, s_BotsItem);
			Vocalize(i_Attacker, s_BotsItem);

			if( g_bNotify && g_bTranslation && !g_bBlockVocalize )
				CPrintToChatAll("\x05%N \x01%t \x04%t \x01%t \x05%N", i_Attacker, "Grabbed", s_BotsItem, "From", i_Victim);

			return;
		}
	}
}



// ======================================================================================
//					ALLOWED TO TRANSFER
// ======================================================================================
stock bool HasSpectator(int client)
{
	char sNetClass[12];
	GetEntityNetClass(client, sNetClass, sizeof(sNetClass));

	if( strcmp(sNetClass, "SurvivorBot") == 0 )
	{
		if( !GetEntProp(client, Prop_Send, "m_humanSpectatorUserID") )
			return false;
	}
	return true;
}

stock bool IsReviving(int client)
{
	if( GetEntProp(client, Prop_Send, "m_reviveOwner", 1) > 0 )
		return true;
	return false;
}

stock bool IsIncapped(int client)
{
	if( GetEntProp(client, Prop_Send, "m_isIncapacitated", 1) > 0 )
		return true;
	return false;
}

int GetItemNumber(char s_Item[40])
{
	for( int i = 0; i < 9; i++ )
	{
		if( StrContains(s_Item, g_Pickups[i]) != -1 )
			return i;
	}

	return -1;
}

bool AllowedToTransfer(char s_Item[40])
{
	int i = GetItemNumber(s_Item);

	switch (i)
	{
		case -1: return false;
		case 0: if( g_bAllowMol ) return true;
		case 1: if( g_bAllowPip ) return true;
		case 2: if( g_bAllowVom ) return true;
		case 3: if( g_bAllowFir ) return true;
		case 4: if( g_bAllowPil ) return true;
		case 5: if( g_bAllowAdr ) return true;
		case 6: if( g_bAllowExp ) return true;
		case 7: if( g_bAllowInc ) return true;
		case 8: if( g_bAllowDef ) return true;
	}

	return false;
}

bool BotAllowedTransfer(char s_Item[40], bool bGive = false)
{
	int i = GetItemNumber(s_Item);

	switch (i)
	{
		case -1: return false;
		case 0: if( g_iBotMol == 1 || g_iBotMol == 2 && bGive || g_iBotMol == 3 && !bGive ) return true;
		case 1: if( g_iBotPip == 1 || g_iBotPip == 2 && bGive || g_iBotPip == 3 && !bGive ) return true;
		case 2: if( g_iBotVom == 1 || g_iBotVom == 2 && bGive || g_iBotVom == 3 && !bGive ) return true;
		case 3: if( g_iBotFir == 1 || g_iBotFir == 2 && bGive || g_iBotFir == 3 && !bGive ) return true;
		case 4: if( g_iBotPil == 1 || g_iBotPil == 2 && bGive || g_iBotPil == 3 && !bGive ) return true;
		case 5: if( g_iBotAdr == 1 || g_iBotAdr == 2 && bGive || g_iBotAdr == 3 && !bGive ) return true;
		case 6: if( g_iBotExp == 1 || g_iBotExp == 2 && bGive || g_iBotExp == 3 && !bGive ) return true;
		case 7: if( g_iBotInc == 1 || g_iBotInc == 2 && bGive || g_iBotInc == 3 && !bGive ) return true;
		case 8: if( g_iBotDef == 1 || g_iBotDef == 2 && bGive || g_iBotDef == 3 && !bGive ) return true;
	}

	return false;
}



// ======================================================================================
//					GIVE AN ITEM
// ======================================================================================
void GiveItem(int client, char s_Class[40])
{
	int i_Ent = CreateEntityByName(s_Class);

	if( i_Ent == -1 )
	{
		LogError("Failed to create entity '%s' for %N", s_Class, client);
	}
	else
	{
		if( !DispatchSpawn(i_Ent) )
			LogError("Failed to dispatch '%s' for %N", s_Class, client);
		else
			EquipPlayerWeapon(client, i_Ent);
	}
}

void StripWeapon(int client, int i_Slot)
{
	int i_Ent = GetPlayerWeaponSlot(client, i_Slot);

	if( i_Ent != -1 )
	{
		RemovePlayerItem(client, i_Ent);
		AcceptEntityInput(i_Ent, "kill");
	}
}



// ======================================================================================
//					RESET TIMERS
// ======================================================================================
public Action tmrResetTransfer(Handle timer, any client)
{
	g_bHasTransferred[client] = false;
}

public Action tmrResetGive(Handle timer, any client)
{
	g_hTmrGiveBlocked = null;
	g_bGiveBlocked = false;
}

public Action tmrUnblockVocalize(Handle timer)
{
	g_hTmrBlockVocalize = null;
	g_bBlockVocalize = false;
}

void ResetItemArray(int i)
{
	g_iItemSpawnID[i] = -1;
	g_fItemSpawn_XYZ[i] = view_as<float>({ 0.0, 0.0, 0.0 });
}



// ======================================================================================
//					VOCALIZE
// ======================================================================================
void Vocalize(int i_Client, char s_Class[40])
{
	// We don't need to vocalize vomitjars, defibs, explosive ammo or incendiary ammo.
	if( g_iCvarVocalize == 0 || g_bBlockVocalize )
		return;

	if( strcmp(s_Class,"weapon_pain_pills") == 0 ) return;
	else if( strcmp(s_Class,"weapon_adrenaline") == 0 ) return;
	else if( strcmp(s_Class,"weapon_defibrillator") == 0 ) return;
	else if( strcmp(s_Class,"weapon_upgradepack_explosive") == 0 ) return;
	else if( strcmp(s_Class,"weapon_upgradepack_incendiary") == 0 ) return;
	else if( strcmp(s_Class,"weapon_vomitjar") == 0 ) return;

	// Declare variables
	int i_Type, i_Rand, i_Min, i_Max, i_Character;
	char s_Model[64];

	// Get survivor model
	GetEntPropString(i_Client, Prop_Data, "m_ModelName", s_Model, 64);

	if( strcmp(s_Model, "models/survivors/survivor_coach.mdl") == 0 ) { Format(s_Model,9,"coach"); i_Type = 1; }
	else if( strcmp(s_Model, "models/survivors/survivor_gambler.mdl") == 0 ) { Format(s_Model,9,"gambler"); i_Type = 2; }
	else if( strcmp(s_Model, "models/survivors/survivor_mechanic.mdl") == 0 ) { Format(s_Model,9,"mechanic"); i_Type = 3; }
	else if( strcmp(s_Model, "models/survivors/survivor_producer.mdl") == 0 ) { Format(s_Model,9,"producer"); i_Type = 4; }
	else if( strcmp(s_Model, "models/survivors/survivor_namvet.mdl") == 0 ) { Format(s_Model,9,"NamVet"); i_Type = 5; }
	else if( strcmp(s_Model, "models/survivors/survivor_biker.mdl") == 0 ) { Format(s_Model,9,"Biker"); i_Type = 6; }
	else if( strcmp(s_Model, "models/survivors/survivor_manager.mdl") == 0 ) { Format(s_Model,9,"Manager"); i_Type = 7; }
	else if( strcmp(s_Model, "models/survivors/survivor_teenangst.mdl") == 0 ) { Format(s_Model,9,"TeenGirl"); i_Type = 8; }
	else {
		i_Character = GetEntProp(i_Client, Prop_Send, "m_survivorCharacter");
		if( g_bLeft4Dead2 ) {
			switch (i_Character) {
				case 0:	{ Format(s_Model,9,"gambler"); i_Type = 2; }	// Nick
				case 1:	{ Format(s_Model,9,"producer"); i_Type = 4; }	// Rochelle
				case 2:	{ Format(s_Model,9,"coach"); i_Type = 1; }		// Coach
				case 3:	{ Format(s_Model,9,"mechanic"); i_Type = 3; } 	// Ellis
				case 4:	{ Format(s_Model,9,"NamVet"); i_Type = 5; } 	// Bill
				case 5:	{ Format(s_Model,9,"TeenGirl"); i_Type = 8; } 	// Zoey
				case 6:	{ Format(s_Model,9,"Biker"); i_Type = 6; } 	// Francis
				case 7:	{ Format(s_Model,9,"Manager"); i_Type = 7; } 	// Louis
			}
		} else {
			switch (i_Character) {
				case 0:	{ Format(s_Model,9,"TeenGirl"); i_Type = 8; }	// Zoey
				case 1:	{ Format(s_Model,9,"NamVet"); i_Type = 5; }		// Bill
				case 2:	{ Format(s_Model,9,"Biker"); i_Type = 6; }		// Francis
				case 3:	{ Format(s_Model,9,"Manager"); i_Type = 7; } 	// Louis
			}
		}
		//LogError("failed to vocalize %s for %s", s_Class, s_Model); return;
	}

	// Pipe Bomb
	if( strcmp(s_Class,"weapon_pipe_bomb") == 0 )
	{
		switch (i_Type)
		{
			case 1: i_Max = 2;	// Coach
			case 2: i_Max = 1;	// Nick
			case 3: i_Max = 2;	// Ellis
			case 4: i_Max = 1;	// Rochelle
			case 5: i_Max = 3;	// Bill
			case 6: i_Max = 4;	// Francis
			case 7: i_Max = 3;	// Louis
			case 8: i_Max = 1;	// Zoey
		}
	}

	// Molotov
	else if( strcmp(s_Class,"weapon_molotov") == 0 )
	{
		switch (i_Type)
		{
			case 1: {i_Min = 3; i_Max = 4;}
			case 2: {i_Min = 2; i_Max = 3;}
			case 3: {i_Min = 3; i_Max = 10;}
			case 4: {i_Min = 2; i_Max = 5;}
			case 5: {i_Min = 5; i_Max = 6;}
			case 6: {i_Min = 5; i_Max = 7;}
			case 7: {i_Min = 4; i_Max = 6;}
			case 8: {i_Min = 2; i_Max = 5;}
		}
	}

	// First aid
	else if( strcmp(s_Class,"weapon_first_aid_kit") == 0 )
	{
		switch (i_Type)
		{
			case 1: {i_Min = 5; i_Max = 7;}
			case 2: {i_Min = 4; i_Max = 8;}
			case 3: {i_Min = 11; i_Max = 14;}
			case 4: {i_Min = 6; i_Max = 8;}
			case 5: {i_Min = 7; i_Max = 9;}
			case 6: {i_Min = 8; i_Max = 11;}
			case 7: {i_Min = 7; i_Max = 8;}
			case 8: {i_Min = 6; i_Max = 9;}
		}
	}
	else
	{
		return;
	}

	// Random number
	i_Rand = GetRandomInt(i_Min, i_Max);

	// Select random vocalize
	char s_Temp[40];
	switch (i_Type)
	{
		case 1: Format(s_Temp, sizeof(s_Temp),"%s", g_Coach[i_Rand]);
		case 2: Format(s_Temp, sizeof(s_Temp),"%s", g_Nick[i_Rand]);
		case 3: Format(s_Temp, sizeof(s_Temp),"%s", g_Ellis[i_Rand]);
		case 4: Format(s_Temp, sizeof(s_Temp),"%s", g_Rochelle[i_Rand]);
		case 5: Format(s_Temp, sizeof(s_Temp),"%s", g_Bill[i_Rand]);
		case 6: Format(s_Temp, sizeof(s_Temp),"%s", g_Francis[i_Rand]);
		case 7: Format(s_Temp, sizeof(s_Temp),"%s", g_Louis[i_Rand]);
		case 8: Format(s_Temp, sizeof(s_Temp),"%s", g_Zoey[i_Rand]);
	}

	// Create scene location and call
	char s_Scene[64];
	Format(s_Scene, sizeof(s_Scene), "scenes/%s/%s.vcd", s_Model, s_Temp);
	VocalizeScene(i_Client, s_Scene);
}



// Taken from:
// [Tech Demo] L4D2 Vocalize ANYTHING
// http://forums.alliedmods.net/showthread.php?t=122270
// author = "AtomicStryker"
// ======================================================================================
//					VOCALIZE SCENE
// ======================================================================================
void VocalizeScene(int client, char scenefile[64])
{
	int tempent = CreateEntityByName("instanced_scripted_scene");
	DispatchKeyValue(tempent, "SceneFile", scenefile);
	DispatchSpawn(tempent);
	SetEntPropEnt(tempent, Prop_Data, "m_hOwner", client);
	ActivateEntity(tempent);
	AcceptEntityInput(tempent, "Start", client, client);
}

void PlaySound(int client, const char s_Sound[32])
{
	EmitSoundToClient(client, s_Sound, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
}



// ======================================================================================
//					PRINT TO CHAT ALL
// ======================================================================================
// Taken from:
// http://docs.sourcemod.net/api/index.php?fastload=show&id=151&
void CPrintToChatAll(const char[] format, any ...)
{
	char buffer[192];

	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame(i) && !IsFakeClient(i) )
		{
			SetGlobalTransTarget(i);
			VFormat(buffer, sizeof(buffer), format, 2);
			PrintToChat(i, buffer);
		}
	}
}



// ======================================================================================
//					AUTO GIVE AND GRAB STUFF
// ======================================================================================

// ======================================================================================
//					AUTO GIVE / GRAB TIMERS
// ======================================================================================
void MakeTimers()
{
	if( !g_bCvarAllow || g_bModeOffAuto || g_bRoundOver )
		return;

	if( g_bAutoGive || g_bAutoGrab )
		MakeAutoTimer();

	if( g_bAutoGrab )
		MakeItemTimer();
}

// Auto give / auto grab timers
void MakeAutoTimer()
{
	if( g_hTmrAutoGiveGrab != null )
	{
		delete g_hTmrAutoGiveGrab;
	}

	// Allows the timer to have a dynamic time.
	g_hTmrAutoGiveGrab = CreateTimer(g_fTimerAuto, tmrAutoGiveGrab);
}

public Action tmrAutoGiveGrab(Handle timer)
{
	g_hTmrAutoGiveGrab = null;

	if( !g_bCvarAllow || g_bModeOffAuto || g_bRoundOver || (!g_bAutoGive && !g_bAutoGrab) )
		return;

	if( g_bAutoGive && !g_bGiveBlocked )
		CreateTimer(0.1, tmrAutoGive, _, TIMER_FLAG_NO_MAPCHANGE);

	if( g_bAutoGrab )
		CreateTimer(0.4, tmrAutoGrab, _, TIMER_FLAG_NO_MAPCHANGE);

	CreateTimer(0.1, tmrMakeAutoTmr, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action tmrMakeAutoTmr(Handle timer)
{
	MakeAutoTimer();
}

// Get item spawn locations timer
void MakeItemTimer()
{
	if( g_hTmrGetItemSpawn != null )
	{
		delete g_hTmrGetItemSpawn;
	}

	// Allows the timer to have a dynamic time.
	g_hTmrGetItemSpawn = CreateTimer(g_fTimerItem, tmrGetItemSpawn);
}

public Action tmrGetItemSpawn(Handle timer)
{
	g_hTmrGetItemSpawn = null;

	if( !g_bCvarAllow && g_bModeOffAuto || g_bRoundOver || !g_bAutoGrab )
		return;

	CreateTimer(0.1, tmrMakeItemTmr, _, TIMER_FLAG_NO_MAPCHANGE);
	GetItemSpawns();
}

public Action tmrMakeItemTmr(Handle timer)
{
	MakeItemTimer();
}



// ======================================================================================
//					GET GRENADE SPAWNS
// ======================================================================================
void GetItemSpawns()
{
	int i; int count; int ent = -1; float f_Location[3];
	char sTemp[40];

	// Search for dynamic weapon spawns
	for( i = 0; i < 18; i++ )
	{
		// We need to check for example: weapon_molotov_spawn and weapon_molotov (items at spawn and items dropped)
		if( i < 9 )
			Format(sTemp, sizeof(sTemp), "%s_spawn", g_Pickups[i]);
		else
			Format(sTemp, sizeof(sTemp), "%s", g_Pickups[i-9]);

		if( !BotAllowedTransfer(sTemp) )
			continue;

		// Find items
		while( (ent = FindEntityByClassname(ent, sTemp)) != -1 )
		{
			// Do not save non _spawn items which have owners.
			if( i > 8 && GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity") != -1 )
				continue;

			// Save entity ID and origin.
			GetEntPropVector(ent, Prop_Send, "m_vecOrigin", f_Location);
			g_iItemSpawnID[count] = EntIndexToEntRef(ent);
			g_fItemSpawn_XYZ[count] = f_Location;

			// Increment count but do not exceed MAX_ITEMS limit.
			count++;
			g_iItemCount = count;
			if( count == MAX_ITEMS )
				return;
		}
	}
	g_iItemCount = count;
}



// ======================================================================================
//					AUTO KILL - GRAB STUFF
// ======================================================================================
// ########## AUTO GIVE ########## - Loop through players and bots to check if they can receive/give items
public Action tmrAutoGive(Handle timer)
{
	if( g_bGiveBlocked )
		return;

	// Variables
	int i, i_Slot, client, player;
	bool b_ClientGrenade, b_ClientSpecial, b_ClientMedSlot;
	float f_ClientPos[3], f_PlayerPos[3], f_Distance;
	char s_EdictClassName[40];

	// Loop through bots
	for( client = 1; client <= MaxClients; client++ )
	{
		// Make sure client is team survivor and alive
		if( IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client) && IsFakeClient(client) )
		{
			// Make sure they are a bot and not an idle player. Don't allow transfers when incapped or being revived
			if( !HasSpectator(client) && !IsReviving(client) && !IsIncapped(client) )
			{
				if( GetPlayerWeaponSlot(client, 2) != -1 ) b_ClientGrenade = true; else b_ClientGrenade = false;
				if( GetPlayerWeaponSlot(client, 3) != -1 ) b_ClientSpecial = true; else b_ClientSpecial = false;
				if( GetPlayerWeaponSlot(client, 4) != -1 ) b_ClientMedSlot = true; else b_ClientMedSlot = false;

				if( b_ClientGrenade || b_ClientSpecial || b_ClientMedSlot )
				{
					GetClientEyePosition(client, f_ClientPos);				// Get bot position

					// Loop through the clients
					for( player = 1; player <= MaxClients; player++ )
					{

						// Player in game, human player, alive, team survivor
						if( client != player && IsClientInGame(player) && !IsFakeClient(player) && IsPlayerAlive(player) && GetClientTeam(player) == 2 &&
						// Don't allow transfers when incapped or being revived
						!IsReviving(player) && !IsIncapped(player) )
						{

							// player has no item and bot does
							i_Slot = -1;
							if( b_ClientGrenade && GetPlayerWeaponSlot(player, 2) == -1 ) i_Slot = 2;
							else if( b_ClientSpecial && GetPlayerWeaponSlot(player, 3) == -1 ) i_Slot = 3;
							else if( b_ClientMedSlot && GetPlayerWeaponSlot(player, 4) == -1 ) i_Slot = 4;
							else continue;

							i = GetPlayerWeaponSlot(client, i_Slot);	// Get bots item name
							GetEdictClassname(i, s_EdictClassName, sizeof(s_EdictClassName));

							// This item is allowed to be transferred
							if( BotAllowedTransfer(s_EdictClassName, true) )
							{
								GetClientEyePosition(player, f_PlayerPos);					// Position of player
								f_Distance = GetVectorDistance(f_ClientPos, f_PlayerPos);	// Distance between player and bot

								// We're close enough
								if( f_Distance <= g_fDistGive && IsVisibleTo(f_ClientPos, f_PlayerPos) )
								{
									if( g_bSounds ) PlaySound(player, SOUND_LITTLEREWARD);

									StripWeapon(client, i_Slot);
									GiveItem(player, s_EdictClassName);
									Vocalize(player, s_EdictClassName);

									g_bGiveBlocked = true;
									if( g_hTmrGiveBlocked != null )
										delete g_hTmrGiveBlocked;
									g_hTmrGiveBlocked = CreateTimer(1.5, tmrResetGive);

									if( g_bNotify && g_bTranslation && !g_bBlockVocalize )
										CPrintToChatAll("\x05%N \x01%t \x04%t \x01%t \x05%N", client, "Gave", s_EdictClassName, "To", player);
									return;
								}
							}
						}
					}
				}
			}
		}
	}
}

// ########## AUTO GRAB ########## - Loop through bot positions and check if they can grab items
public Action tmrAutoGrab(Handle timer)
{
	// Variables
	int count, client, ent, i;
	bool bContains, b_ClientGrenade, b_ClientSpecial, b_ClientMedSlot;
	float f_TargetPos[3], f_ClientPos[3], f_Distance;
	char s_EdictClassName[40];

	// Loop through the clients
	for( client = 1; client <= MaxClients; client++ )
	{
		// Client in game, alive and a bot on the survivor team. Don't allow transfers when incapped or being revived
		if( IsClientInGame(client) && IsPlayerAlive(client) && IsFakeClient(client) && GetClientTeam(client) == 2 &&
		!IsReviving(client) && !IsIncapped(client) )
		{

			if( GetPlayerWeaponSlot(client, 2) != -1 ) b_ClientGrenade = true; else b_ClientGrenade = false;		// Client has a grenade
			if( GetPlayerWeaponSlot(client, 3) != -1 ) b_ClientSpecial = true; else b_ClientSpecial = false;		// Client has first aid/defib/upgrade ammo
			if( GetPlayerWeaponSlot(client, 4) != -1 ) b_ClientMedSlot = true; else b_ClientMedSlot = false;		// Client has pills/adrenaline
			GetClientEyePosition(client, f_ClientPos);																// Get the bots eye origin

			// They must have an empty slot
			if( !b_ClientGrenade || !b_ClientSpecial || !b_ClientMedSlot )
			{

				// Loop through the known item entities
				for( count = 0; count < g_iItemCount; count++ )
				{

					// Item must be valid
					ent = g_iItemSpawnID[count];
					if( ent != -1 && ent != 0 && (ent = EntRefToEntIndex(ent)) != INVALID_ENT_REFERENCE )
					{

						GetEdictClassname(ent, s_EdictClassName, sizeof(s_EdictClassName));

						i = GetItemNumber(s_EdictClassName);
						if( i == -1 )
							continue;

						// Only pick up item if relative slot is empty
						if( !b_ClientGrenade && i <= 2 || !b_ClientSpecial && i == 3
						|| !b_ClientSpecial && i >= 6 || !b_ClientMedSlot && i >= 4 && i <= 5 )
						{
							bContains = false;
							// We must check non _spawn items do not have owners
							if( StrContains(s_EdictClassName, "_spawn") != -1 )
								bContains = true;
							if( !bContains && GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity") != -1 )
								continue;

							if( StrContains(s_EdictClassName, "projectile") == -1 )
							{
								// Item must be allowed.
								if( BotAllowedTransfer(s_EdictClassName) )
								{
									f_TargetPos = g_fItemSpawn_XYZ[count]; // Item spawn location.
									f_Distance = GetVectorDistance(f_ClientPos, f_TargetPos);

									if( f_Distance <= g_fDistGrab && IsVisibleTo(f_ClientPos, f_TargetPos) )
									{
										if( bContains )
										{
											ReplaceStringEx(s_EdictClassName, sizeof(s_EdictClassName), "_spawn", "");
											int flag = GetEntProp(ent, Prop_Data, "m_spawnflags");
											if( flag & (1<<3) )
											{
												// Unlimited ammo, do nothing.
											}
											else
											{
												int iCount = GetEntProp(ent, Prop_Data, "m_itemCount");
												if( iCount > 1 )
													SetEntProp(ent, Prop_Data, "m_itemCount", iCount -1);
												else
													AcceptEntityInput(ent, "kill");
											}
										}
										else
											AcceptEntityInput(ent, "kill");

										FireEventsFootlocker(client, ent, s_EdictClassName);

										ResetItemArray(count);
										GiveItem(client, s_EdictClassName);
										Vocalize(client, s_EdictClassName);

										if( g_bNotify && g_bTranslation && !g_bBlockVocalize )
											CPrintToChatAll("\x05%N \x01%t \x04%t", client, "Grabbed", s_EdictClassName);
										return;
									}
								}
							}
						}
					}
				}
			}
		}
	}
}



// ====================================================================================================
//					FIRE EVENTS
// ====================================================================================================
void FireEventsFootlocker(int client, int target, char sItem[40])
{
	Event hEvent = CreateEvent("item_pickup", true);
	if( hEvent != null )
	{
		hEvent.SetInt("userid", GetClientUserId(client));
		hEvent.SetString("item", sItem);
		hEvent.Fire();
	}

	hEvent = CreateEvent("player_use", true);
	if( hEvent != null )
	{
		hEvent.SetInt("userid", GetClientUserId(client));
		hEvent.SetInt("targetid", target);
		hEvent.Fire();
	}
}



/// ======================================================================================
//					TRACE RAY
// ======================================================================================
// Taken from:
// plugin = "L4D_Splash_Damage"
// author = "AtomicStryker"
bool IsVisibleTo(float position[3], float targetposition[3])
{
	float vAngles[3], vLookAt[3];

	MakeVectorFromPoints(position, targetposition, vLookAt); // compute vector from start to target
	GetVectorAngles(vLookAt, vAngles); // get angles from vector for trace

	// execute Trace
	Handle trace = TR_TraceRayFilterEx(position, vAngles, MASK_ALL, RayType_Infinite, _TraceFilter);

	bool isVisible = false;
	if( TR_DidHit(trace) )
	{
		float vStart[3];
		TR_GetEndPosition(vStart, trace); // retrieve our trace endpoint

		if( (GetVectorDistance(position, vStart, false) + 25.0 ) >= GetVectorDistance(position, targetposition))
		{
			isVisible = true; // if trace ray length plus tolerance equal or bigger absolute distance, you hit the target
		}
	}
	delete trace;

	return isVisible;
}

public bool _TraceFilter(int entity, int contentsMask)
{
	if( !entity || entity <= MaxClients || !IsValidEntity(entity) ) // dont let WORLD, or invalid entities be hit
	{
		return false;
	}
	return true;
}
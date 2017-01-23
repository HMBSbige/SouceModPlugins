/********************************************************************************************
* Plugin	: [L4D/L4D2] Character Select Menu
* Version	: 2.5a
* Game		: Left 4 Dead/Left 4 Dead 2
* Author	: MI 5
* Testers	: Myself
* Website	: N/A
* 
* Purpose	: Allows players to change their in game character or model!
* 
* Version 2.5a/2.5b
* 		- Fixed bug in finale with Bill where common infected spawned when the tank arrived
* 
* Version 2.4a/2.4b
* 		- May fix Bill from crashing, else try the b version
*
* Version 2.3b
* 		- Fixed bug with louis and francis on the CSM menu in a L4D1 campaign
* 
* Version 2.3a
* 		- Fixed bug with Jimmy Gibbs Jr. model
* 
* Version 2.3
* 		- Bill is now playable during a finale
* 		- Bill no longer crashes on Linux servers
* 		- Fixed bug where common infected would not come during a panic event if Bill is in the party (commons will come after a delayed period of time)
* 		- Fixed bug in versus where all survivor bots would become either Nick or Bill at the end of a round
* 		- Fixed crash where if a player is Bill and a map was voted, the server would crash
* 		- Fixed bug where if l4d_csm_survivor_model_access and l4d_csm_infected_model_access was 0 and l4d_csm_common_infected_model_access is 1, CSM could not be accessed  
* 		- Fixed bug where clients would have access to CSM even though the l4d_csm_admins_only cvar is set to 1
* 		- Changed the way the l4d_csm_l4d1_survivors cvar works. Set this to 1 if it's a L4D2 campaign, else if its a L4D1 Campaign, set this to 2 or glitches will occur
* 		- Changed cvars: l4d_csm_survivor_model_access and l4d_csm_infected_model_access into l4d_csm_survivor_access and l4d_csm_infected_access
* 
* Version 2.2
* 		- Removed bot spawning from the plugin
* 		- The plugin now sets precache_all_survivors to 1 (should prevent some crashes)
* 		- If the announcement cvar is set to 0, there won't be messages for clients when they first spawn
* 		- Fixed bug where very few zombies would spawn if Bill was in the game
*		- You cannot play as Bill in Finales, else zombies wouldn't spawn
* 
* Version 2.1
* 		- Fixed error occuring from Timer_RestoreVersusSurvivor
* 		- Fixed Bill crashing after a map ends
* 		- Added cvar l4d_csm_l4d1_bots which spawns the L4D1 Survivor bots in a L4D2 Campaign (or L4D2 Bots if its a L4D1 Campaign)
* 
* Version 2.0
* 		- Fixed errors related to "RemovePlayerItem"
* 		- Fixed a bug where people would play as Nick from the lobby no matter what character they selected before
* 
* Version 1.9
* 		- Bill is now playable in L4D2 campaigns
* 		- Fixed Versus scoring with the L4D1 Survivors in L4D2 campaigns
* 		- Should no longer cause crashes with models as it only loads the model when called upon
* 		- Added command "csc" that allows admins to change the characters or models of clients
* 		- Players will now remain as their character when the map changes
* 		- Fixed glitches with L4D1 survivors when playing on the first and last map of The Passing
* 		- L4D2 Survivors are only playable as models in the L4D1 Campaigns
* 		- Removed cvars l4d_csm_models_only, l4d_csm_infected_menu, l4d_csm_survivor_menu
* 		- Optimized the plugin taken from Dirka Dirka's lite version of the plugin (thank you Dirka Dirka)
* 
* Version 1.8
* 		- Fixed typo with game detection
* 		- Fixed typo selecting Francis in L4D 1
* 		- Added cvar l4d_admins_only (default 0)
* 		- Changed how l4d_csm_infected_menu and l4d_csm_survivor_menu worked, now it only applies to their respective teams
* 		- Admins no longer have access to characters with l4d_csm_models_only at 1
* 		- Added cvar l4d_csm_announce (default 1)
* 		- Added cvar l4d_csm_clients_infected (default 0 to prevent abuse)
* 		- Added cvar l4d_csm_survivor_models (default 1)
* 		- Added cvar l4d_csm_infected_models (default 1)
* 		- Added cvar l4d_csm_same_team_characters (default 0)
* 		- Added cvar l4d_csm_l4d1_survivors (default 0 to prevent glitches)
* 
* Version 1.7
* 		- Fixed a crash with the infected menu
* 		- Precached boomer and witch so that it doesn't crash when you select them
* 		- Fixed bug where survivors couldn't access the menu when they had 1 point of health left
* 		- Changed the description of the Infected Menu cvar
* 		- Added cvar: l4d_csm_models_only
* 
* Version 1.6
* 		- L4D1 Survivors can now be played on any campaign
* 
* Version 1.5
* 		- Original Survivors are now playable in L4D2 (except for Bill for obvious reasons)
* 
* Version 1.4
* 		- Optimized the plugin
* 		- Merged L4D version of plugin with L4D2 version
* 		- Survivors can now become fully Infected (admins only to prevent abuse)
* 		- Fixed server crashes with uncommon infected
*
* Version 1.3
* 		- Added a timer to the Gamemode ConVarHook to ensure compatitbilty with other gamemode changing plugins
* 		- Survivors can now become Infected and vice versa (Character or model) (L4D2 only)
* 		- Added Boomette (L4D2 only)
* 		- Added Uncommon infected (model only) (L4D2 only)
* 	    - Fixed bug where the survivor menu would appear even if its turned off
* 
* Version 1.2
* 		- Redone tank health fix
* 		- Few optimizations here and there
* 
* Version 1.1
* 		- Added cvars: l4d_csm_infected_menu, l4d_csm_survivor_menu and l4d_csm_change_limit
* 		- Fixed bug where clients can access restricted parts of the menu
* 
* Version 1.0
* 		- Initial release.
* 
* 
**********************************************************************************************/

// define
#define 	PLUGIN_VERSION "2.5a"
#define 	DEBUG 0
#pragma 	semicolon 1
#define 	TEAM_SURVIVORS 		2
#define 	TEAM_INFECTED 		3

#define		CSM_SURVIVOR_CHARACTER_ONLY				1
#define		CSM_SURVIVOR_MODEL_ONLY			2
#define		CSM_SURVIVOR_MODEL_AND_CHARACTER	3

#define		CSM_INFECTED_CHARACTER_ONLY			1
#define		CSM_INFECTED_MODEL_ONLY			2
#define		CSM_INFECTED_CHARACTER_AND_MODEL			3

#define 	ZOMBIE_TIME 1.5
#define 	BILL_TIME 3.0
#define 	L4D1_SURVIVOR_VERSUS_RESTORE 10.0

#define 	GAMEMODE_COOP 0
#define 	GAMEMODE_VERSUS 1
#define 	GAMEMODE_SURVIVAL 2

// This two definitions are for the L4D1 Survivors cvar

#define 	L4D2CAMPAIGN 1 
#define		L4D1CAMPAIGN 2

#define		CSM_CHANGE_MESSAGE			5		// when there are this many changes or less, alert the client

// includes
#include <sourcemod>
#include <sdktools>

// DONT CHANGE THESE VALUES - YOU WILL GET SCREWY RESULTS
#define		NICK		0
#define		ROCHELLE	1
#define		COACH		2
#define		ELLIS		3
#define		BILL		4
#define		ZOEY		5
#define		FRANCIS		6
#define		LOUIS		7
#define		NICK_MODEL		8
#define		ROCHELLE_MODEL	9
#define		COACH_MODEL	10
#define		ELLIS_MODEL	11
#define		BILL_MODEL		12
#define		ZOEY_MODEL		13
#define		FRANCIS_MODEL	14
#define		LOUIS_MODEL	15
#define		SMOKER		16
#define		BOOMER		17
#define		BOOMETTE		18
#define		HUNTER		19
#define		CHARGER		20
#define		JOCKEY		21
#define		SPITTER		22
#define		TANK		23
#define		SMOKER_MODEL		24
#define		BOOMER_MODEL		25
#define		BOOMETTE_MODEL		26
#define		HUNTER_MODEL		27
#define		CHARGER_MODEL		28
#define		JOCKEY_MODEL		29
#define		SPITTER_MODEL		30
#define		TANK_MODEL			31
#define		WITCH_MODEL			32
#define		CEDA_HAZMAT_MODEL	33
#define		CLOWN_MODEL			34
#define		MUD_MAN_MODEL		35
#define		CONSTRUCTION_WORKER_MODEL		36
#define		RIOT_OFFICER_MODEL		37
#define		FALLEN_SURVIVOR_MODEL		38
#define		JIMMY_GIBBS_JR_MODEL		39
#define		CUSTOM_SURVIVOR_1		40

#define GET_BILL_L4D1_NETPROP 		GetEntProp(client, Prop_Send, "m_survivorCharacter") == 0
#define GET_ZOEY_L4D1_NETPROP 		GetEntProp(client, Prop_Send, "m_survivorCharacter") == 1
#define GET_FRANCIS_L4D1_NETPROP 		GetEntProp(client, Prop_Send, "m_survivorCharacter") == 2
#define GET_LOUIS_L4D1_NETPROP 		GetEntProp(client, Prop_Send, "m_survivorCharacter") == 3

#define GET_NICK_NETPROP 		GetEntProp(client, Prop_Send, "m_survivorCharacter") == 0
#define GET_ROCHELLE_NETPROP 		GetEntProp(client, Prop_Send, "m_survivorCharacter") == 1
#define GET_COACH_NETPROP 		GetEntProp(client, Prop_Send, "m_survivorCharacter") == 2
#define GET_ELLIS_NETPROP 		GetEntProp(client, Prop_Send, "m_survivorCharacter") == 3

#define GET_BILL_NETPROP 		GetEntProp(client, Prop_Send, "m_survivorCharacter") == 4
#define GET_ZOEY_NETPROP 		GetEntProp(client, Prop_Send, "m_survivorCharacter") == 5
#define GET_FRANCIS_NETPROP 		GetEntProp(client, Prop_Send, "m_survivorCharacter") == 6
#define GET_LOUIS_NETPROP 		GetEntProp(client, Prop_Send, "m_survivorCharacter") == 7


#define SET_CHARACTER_BILL_L4D1			SetEntProp(client, Prop_Send, "m_survivorCharacter", 0);
#define SET_CHARACTER_ZOEY_L4D1 			SetEntProp(client, Prop_Send, "m_survivorCharacter", 1);
#define SET_CHARACTER_FRANCIS_L4D1		SetEntProp(client, Prop_Send, "m_survivorCharacter", 2);
#define SET_CHARACTER_LOUIS_L4D1			SetEntProp(client, Prop_Send, "m_survivorCharacter", 3);

#define SET_CHARACTER_NICK			SetEntProp(client, Prop_Send, "m_survivorCharacter", 0);
#define SET_CHARACTER_ROCHELLE 			SetEntProp(client, Prop_Send, "m_survivorCharacter", 1);
#define SET_CHARACTER_COACH		SetEntProp(client, Prop_Send, "m_survivorCharacter", 2);
#define SET_CHARACTER_ELLIS			SetEntProp(client, Prop_Send, "m_survivorCharacter", 3);

#define SET_CHARACTER_BILL			SetEntProp(client, Prop_Send, "m_survivorCharacter", 4);
#define SET_CHARACTER_ZOEY 			SetEntProp(client, Prop_Send, "m_survivorCharacter", 5);
#define SET_CHARACTER_FRANCIS		SetEntProp(client, Prop_Send, "m_survivorCharacter", 6);
#define SET_CHARACTER_LOUIS			SetEntProp(client, Prop_Send, "m_survivorCharacter", 7);

// WARNING: The generic/Bill alternative netprop values may crash the server. Some servers like the value of 11, others do not. The "a" version of CSM uses the value of "11", while the "b" version uses the value of "9"

#define GET_BILL_ALT_NETPROP 		GetEntProp(client, Prop_Send, "m_survivorCharacter") == 11
#define SET_CHARACTER_BILL_ALT			SetEntProp(client, Prop_Send, "m_survivorCharacter", 11);

#define GET_GENERIC_NETPROP		GetEntProp(client, Prop_Send, "m_survivorCharacter") == 11
#define SET_CHARACTER_GENERIC_SURVIVOR 		SetEntProp(client, Prop_Send, "m_survivorCharacter", 11);

#define MODEL_BILL "models/survivors/survivor_namvet.mdl"
#define MODEL_FRANCIS "models/survivors/survivor_biker.mdl"
#define MODEL_LOUIS "models/survivors/survivor_manager.mdl"
#define MODEL_ZOEY "models/survivors/survivor_teenangst.mdl"

#define MODEL_NICK "models/survivors/survivor_gambler.mdl"
#define MODEL_ROCHELLE "models/survivors/survivor_producer.mdl"
#define MODEL_COACH "models/survivors/survivor_coach.mdl"
#define MODEL_ELLIS "models/survivors/survivor_mechanic.mdl"


// DONT CHANGE THE ORDER OF THE FOLLOWING STRINGS - YOU CAN HOWEVER REWRITE THEM TO YOUR LANGUAGE

static	const	String:	g_sCharacters[][] = 
{
	"Nick",
	"Rochelle",
	"Coach",
	"Ellis",
	"Bill",
	"Zoey",
	"Francis",
	"Louis",
	"Nick (Model)",
	"Rochelle (Model)",
	"Coach (Model)",
	"Ellis (Model)",
	"Bill (Model)",
	"Zoey (Model)",
	"Francis (Model)",
	"Louis (Model)",
	"Smoker",
	"Boomer",
	"Boomette",
	"Hunter",
	"Charger",
	"Jockey",
	"Spitter",
	"Tank",
	"Smoker (Model)",
	"Boomer (Model)",
	"Boomette (Model)",
	"Hunter (Model)",
	"Charger (Model)",
	"Jockey (Model)",
	"Spitter (Model)",
	"Tank (Model)",
	"Witch (Model)",
	"CEDA Hazmat (Model)",
	"Clown (Model)",
	"Mud Man (Model)",
	"Construction Worker (Model)",
	"Riot Officer (Model)",
	"Fallen Survivor (Model)",
	"Jimmy Gibbs Jr. (Model)",
	"Custom Survivor"
};

// Variables
static g_iChangeLimit;			// max # of changes per life/map
static g_iClientChangeLimit[MAXPLAYERS+1];
static g_iSurvivorModels;		// used to determine if clients can change model &/or character
static g_iInfectedModels;
static g_iCommonLimit; // used to fix Bill as the common limit must be set to 0 if he is to work
static g_iSavedCharacter[MAXPLAYERS+1]; // used to prevent the character from reverting to their default character (usually a l4d2 survivor)
static g_iSavedModel[MAXPLAYERS+1]; // used to prevent the character from reverting to their default model (usually a l4d2 survivor)
static g_iGameMode;
static g_iVersusOldSurvivor[MAXPLAYERS+1]; // used to save the character the player chose during a round
static g_iVersusNewSurvivor[MAXPLAYERS+1]; // used to save the character the player started with at the beginning of a round
static g_iSelectedClient; // used to save the client number that was selected by an admin to change their character
static g_iL4D1Survivors;

// Bools
static bool:g_bEnabled;
static bool:g_bIsL4D2 = false;
static bool:g_bAnnounce;
static bool:g_bCommonModels;
static bool:g_bc6m3lock; // lock used to fix glitches on The passing's third map
static bool:g_bAdminsOnly;
static bool:g_bBillIsChanging; // used to fix bill
static bool:g_bRoundStarted;
static bool:g_bHasRoundEnded;
static bool:g_bWasBill[MAXPLAYERS+1];
static bool:g_bWasL4D1Survivor[MAXPLAYERS+1]; // used to fix the c6m1_riverbank glitch
static bool:g_bPlayerHasEnteredStart[MAXPLAYERS+1];
static bool:g_bInFinale;


static Handle:g_hBillTimer;
static Handle:g_hBillVersusTimer;
static Handle:g_hVersusSurvivorTimer;
static Handle:g_hGameMode;
//static Handle:g_hCustomSurvivor1;
//static String:g_sCustomSurvivor1[256] = "";

static bool:g_b_aOneToSpawn[MAXPLAYERS+1]; // Used to tell the plugin that this client will be the one to spawn and not place any spawn restrictions on that client


public Plugin:myinfo = 
{
	name = "[L4D/L4D2] Character Select Menu",
	author = "MI 5",
	description = "Allows players to change their in game character or model",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=107121"
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max) 
{
	// Checks to see if the game is a L4D game. If it is, check if its the sequel.
	decl String:GameName[12];
	GetGameFolderName(GameName, sizeof(GameName));
	if (StrContains(GameName, "left4dead", false) == -1)
		return APLRes_Failure;
	if (StrEqual(GameName, "left4dead2", false))
		g_bIsL4D2 = true;
	
	return APLRes_Success;
}

public OnPluginStart()
{	
	// Register the version cvar
	CreateConVar("l4d_csm_version", PLUGIN_VERSION, "Version of L4D Character Select Menu", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	// the commands
	RegConsoleCmd("sm_csm", ShowMenu, "Brings up a menu to select a different character");
	// This command is used to bring up a menu that allows admins to change characters of other players.
	RegAdminCmd("sm_csc", InitiateMenuAdmin, ADMFLAG_GENERIC, "Brings up a menu to select a client's character");
	
	
	
	
	//////////////////////////////////////////////
	//CONSOLE VARIABLES
	//////////////////////////////////////////////
	
	
	
	
	
	// Enable Cvar
	new Handle:Enabled = CreateConVar("l4d_csm_enable", "1", "Toggles the CSM plugin functionality", FCVAR_PLUGIN|FCVAR_SPONLY, true, 0.0, true, 1.0);
	g_bEnabled = GetConVarBool(Enabled);
	HookConVarChange(Enabled, _ConVarChange__Enable);
	
	// Admin cvar
	new Handle:AdminsOnly = CreateConVar("l4d_csm_admins_only", "0","Changes access to the sm_csm command. 1 = Admin access only.",FCVAR_PLUGIN|FCVAR_SPONLY,true, 0.0, true, 1.0);
	g_bAdminsOnly = GetConVarBool(AdminsOnly);
	HookConVarChange(AdminsOnly, _ConVarChange__AdminsOnly);
	
	// Announce cvar
	new Handle:Announce = CreateConVar("l4d_csm_announce", "1","Toggles the announcement of sm_csm command availability.",FCVAR_PLUGIN|FCVAR_SPONLY,true, 0.0, true, 1.0);
	g_bAnnounce = GetConVarBool(Announce);
	HookConVarChange(Announce, _ConVarChange__Announce);
	
	// Survivor cvar
	new Handle:SurvivorModels = CreateConVar("l4d_csm_survivor_access", "1","1 = change to character (you become a clone). 2 = change model (look like the new character, but still your original character). 3 = Allow both 1 and 2.",FCVAR_PLUGIN|FCVAR_SPONLY,true, 0.0, true, 3.0 );
	g_iSurvivorModels = GetConVarInt(SurvivorModels);
	HookConVarChange(SurvivorModels, _ConVarChange__SurvivorModels);
	
	// Infected cvar
	new Handle:InfectedModels = CreateConVar("l4d_csm_infected_access", "0", "1 = Can change character only. 2 = Change model only (look like the new character, but still your original character). 3 = Anybody can change character or model.", FCVAR_PLUGIN|FCVAR_SPONLY, true, 0.0, true, 3.0);
	g_iInfectedModels = GetConVarInt(InfectedModels);
	HookConVarChange(InfectedModels, _ConVarChange__InfectedModels);
	
	if (g_bIsL4D2)
	{
		// L4D1 Survivors cvar
		new Handle:L4D1Survivors = CreateConVar("l4d_csm_l4d1_survivors", "0","Toggles access to L4D1 Survivors in L4D2. Set this to 1 if it's a L4D2 campaign, else if its a L4D1 Campaign, set this to 2 or glitches will occur",FCVAR_PLUGIN|FCVAR_SPONLY,true, 0.0, true, 2.0);
		g_iL4D1Survivors = GetConVarInt(L4D1Survivors);
		HookConVarChange(L4D1Survivors, _ConVarChange__L4D1Survivors);
		
		// Common Infected cvar
		new Handle:CommonModels = CreateConVar("l4d_csm_common_infected_models_access", "0", "Toggles access to Common Infected models", FCVAR_PLUGIN|FCVAR_SPONLY, true, 0.0, true, 3.0);
		g_bCommonModels = GetConVarBool(InfectedModels);
		HookConVarChange(CommonModels, _ConVarChange__CommonModels);
	}
	
	// Change Limit Cvar
	new Handle:ChangeLimit = CreateConVar("l4d_csm_change_limit", "9999","Sets the number of times clients can change their character per life/map.",FCVAR_PLUGIN|FCVAR_SPONLY,true, 0.0);
	g_iChangeLimit = GetConVarInt(ChangeLimit);
	HookConVarChange(ChangeLimit, _ConVarChange__ChangeLimit);
	
	//g_hCustomSurvivor1 = CreateConVar("l4d_csm_custom_survivor_1", "","Put the path for the custom survivor model here (models/survivors/survivormodel.mdl). SETTING THIS INCORRECTLY COULD CRASH THE SERVER! The map must be restarted the first time the server goes up.",FCVAR_PLUGIN|FCVAR_SPONLY);
	//GetConVarString(g_hCustomSurvivor1, g_sCustomSurvivor1, sizeof(g_sCustomSurvivor1));
	
	new Handle:CommonLimit = FindConVar("z_common_limit");
	g_iCommonLimit = GetConVarInt(CommonLimit);
	HookConVarChange(CommonLimit, _ConVarChange__CommonLimit);
	
	// Hook Events
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("item_pickup", Event_RoundStart);
	HookEvent("map_transition", Event_GameEnded);
	HookEvent("player_first_spawn", Event_PlayerFirstSpawned);
	HookEvent("player_entered_start_area", Event_PlayerFirstSpawned);
	HookEvent("player_entered_checkpoint", Event_PlayerFirstSpawned);
	HookEvent("player_transitioned", Event_PlayerFirstSpawned);
	HookEvent("player_left_start_area", Event_PlayerFirstSpawned);
	HookEvent("player_left_checkpoint", Event_PlayerFirstSpawned);
	if (g_bIsL4D2)
	{
		HookEvent("finale_start", Event_FinaleStart);
		HookEvent("finale_start", Event_BillFinaleStart);
		HookEvent("panic_event_finished", Event_BillPanicEnd);
		HookEvent("mission_lost", Event_MissionLost);
		HookEvent("vote_cast_yes", Event_SomeoneIsVoting);
		HookEvent("vote_cast_no", Event_SomeoneIsVoting);
	}
	
	// Get Gamemode cvar
	g_hGameMode = FindConVar("mp_gamemode");
	HookConVarChange(g_hGameMode, _ConVarChange__GameMode);
	
	// config file
	AutoExecConfig(true, "l4dcsm");
}






//////////////////////////////////////////////
//CONVAR HOOKS
//////////////////////////////////////////////






public _ConVarChange__Enable(Handle:convar, const String:oldValue[], const String:newValue[]) 
{
	g_bEnabled = GetConVarBool(convar);
	
	new value = 0;
	if (g_bEnabled)
		value = g_iChangeLimit;
	
	for (new i=1; i<=MaxClients; i++)
		g_iClientChangeLimit[i] = value;
}

public _ConVarChange__SurvivorModels(Handle:convar, const String:oldValue[], const String:newValue[]) 
{
	g_iSurvivorModels = GetConVarInt(convar);
}

public _ConVarChange__InfectedModels(Handle:convar, const String:oldValue[], const String:newValue[]) 
{
	g_iInfectedModels = GetConVarInt(convar);
}

public _ConVarChange__CommonModels(Handle:convar, const String:oldValue[], const String:newValue[]) 
{
	g_bCommonModels = GetConVarBool(convar);
}

public _ConVarChange__AdminsOnly(Handle:convar, const String:oldValue[], const String:newValue[]) 
{
	g_bAdminsOnly = GetConVarBool(convar);
}

public _ConVarChange__L4D1Survivors(Handle:convar, const String:oldValue[], const String:newValue[]) 
{
	g_iL4D1Survivors = GetConVarInt(convar);
}

public _ConVarChange__Announce(Handle:convar, const String:oldValue[], const String:newValue[]) 
{
	g_bAnnounce = GetConVarBool(convar);
}

public _ConVarChange__CommonLimit(Handle:convar, const String:oldValue[], const String:newValue[]) 
{
	if (!g_bBillIsChanging)
		g_iCommonLimit = GetConVarInt(convar);
}

public _ConVarChange__GameMode(Handle:convar, const String:oldValue[], const String:newValue[]) 
{
	g_hGameMode = FindConVar("mp_gamemode");
	
	GameModeCheck();
	
	#if DEBUG
	PrintToChatAll("游戏模式改变");
	#endif
}

public _ConVarChange__ChangeLimit(Handle:convar, const String:oldValue[], const String:newValue[]) 
{
	g_iChangeLimit = GetConVarInt(convar);
	
	for (new i=1; i<=MaxClients; i++)  {
		if (g_iChangeLimit == 0) {						// basically disables csm
			g_iClientChangeLimit[i] = 0;
		} else {
			g_iClientChangeLimit[i] -= g_iChangeLimit - StringToInt(oldValue);
			if (g_iClientChangeLimit[i] < 1)			// give the player 1 change if he wouldn't have any left
				g_iClientChangeLimit[i] = 1;
		}
	}
}






//////////////////////////////////////////////
//PRECACHING
//////////////////////////////////////////////






public OnMapStart()
{
	GameModeCheck();
	
	//Precache models here so that the server doesn't crash, will not preload them on map start
	
	if (!IsModelPrecached("models/infected/witch.mdl")) PrecacheModel("models/infected/witch.mdl", false);
	
	//GetConVarString(g_hCustomSurvivor1, g_sCustomSurvivor1, sizeof(g_sCustomSurvivor1));
	//if (!IsModelPrecached(g_sCustomSurvivor1))		PrecacheModel(g_sCustomSurvivor1, false);
	
	if (g_bIsL4D2)
	{
		if (!IsModelPrecached("models/infected/boomette.mdl")) PrecacheModel("models/infected/boomette.mdl", false);
		
		if (!IsModelPrecached("models/infected/common_male_ceda.mdl"))	PrecacheModel("models/infected/common_male_ceda.mdl", false);
		if (!IsModelPrecached("models/infected/common_male_clown.mdl")) 	PrecacheModel("models/infected/common_male_clown.mdl", false);
		if (!IsModelPrecached("models/infected/common_male_mud.mdl")) 	PrecacheModel("models/infected/common_male_mud.mdl", false);
		if (!IsModelPrecached("models/infected/common_male_roadcrew.mdl")) 	PrecacheModel("models/infected/common_male_roadcrew.mdl", false);
		if (!IsModelPrecached("models/infected/common_male_riot.mdl")) 	PrecacheModel("models/infected/common_male_riot.mdl", false);
		if (!IsModelPrecached("models/infected/common_male_fallen_survivor.mdl")) 	PrecacheModel("models/infected/common_male_fallen_survivor.mdl", false);
		if (!IsModelPrecached("models/infected/common_male_jimmy.mdl.mdl")) 	PrecacheModel("models/infected/common_male_jimmy.mdl.mdl", false);
		
		SetConVarInt(FindConVar("precache_all_survivors"), 1);
		
		if (!IsModelPrecached("models/survivors/survivor_teenangst.mdl"))	PrecacheModel("models/survivors/survivor_teenangst.mdl", false);
		if (!IsModelPrecached("models/survivors/survivor_biker.mdl"))		PrecacheModel("models/survivors/survivor_biker.mdl", false);
		if (!IsModelPrecached("models/survivors/survivor_manager.mdl"))	PrecacheModel("models/survivors/survivor_manager.mdl", false);
		if (!IsModelPrecached("models/survivors/survivor_namvet.mdl"))		PrecacheModel("models/survivors/survivor_namvet.mdl", false);
		if (!IsModelPrecached("models/survivors/survivor_gambler.mdl"))	PrecacheModel("models/survivors/survivor_gambler.mdl", false);
		if (!IsModelPrecached("models/survivors/survivor_coach.mdl"))		PrecacheModel("models/survivors/survivor_coach.mdl", false);
		if (!IsModelPrecached("models/survivors/survivor_mechanic.mdl"))	PrecacheModel("models/survivors/survivor_mechanic.mdl", false);
		if (!IsModelPrecached("models/survivors/survivor_producer.mdl"))		PrecacheModel("models/survivors/survivor_producer.mdl", false);
		
		decl String:CurrentMap[100];
		GetCurrentMap(CurrentMap, sizeof(CurrentMap));
		
		// if its The Passing on the third map, actiavte the lock for the L4D1 Survivors
		
		if (g_iGameMode == GAMEMODE_COOP && StrEqual(CurrentMap, "c6m3_port") == true)
			g_bc6m3lock = true;
		else
		g_bc6m3lock = false;
	}
}






//////////////////////////////////////////////
//EVENTS
//////////////////////////////////////////////





public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast) 
{
	if (g_bRoundStarted)
		return;
	
	#if DEBUG
	PrintToChatAll("回合开始");
	#endif
	
	g_bRoundStarted = true;
	g_bHasRoundEnded = false;
	g_bInFinale = false;
}

public Action:Event_PlayerFirstSpawned(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (g_bHasRoundEnded)
		return;
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (!client)
		return;
	
	if (GetClientTeam(client) != TEAM_SURVIVORS)
		return;
	
	if (IsFakeClient(client))
		return;
	
	// If player has already entered the start area, don't go into this
	if (g_bPlayerHasEnteredStart[client])
		return;
	
	g_bPlayerHasEnteredStart[client] = true;
	
	#if DEBUG
	PrintToChatAll("Player first spawned");
	#endif
	
	decl String:Model[256];
	
	decl String:CurrentMap[100];
	GetCurrentMap(CurrentMap, sizeof(CurrentMap));
	
	// Save the character the player was when the game started in Versus.
	
	if (g_iGameMode == GAMEMODE_VERSUS)
		g_iVersusNewSurvivor[client] = GetEntProp(client, Prop_Send, "m_survivorCharacter");
	
	GetClientModel(client, Model, sizeof(Model));
	
	if (StrEqual(Model, MODEL_BILL, false))
		g_iSavedModel[client] = BILL;
	if (StrEqual(Model, MODEL_ZOEY, false))
		g_iSavedModel[client] = ZOEY;
	if (StrEqual(Model, MODEL_FRANCIS, false))
		g_iSavedModel[client] = FRANCIS;
	if (StrEqual(Model, MODEL_LOUIS, false))
		g_iSavedModel[client] = LOUIS;
	if (StrEqual(Model, MODEL_NICK, false))
		g_iSavedModel[client] = NICK;
	if (StrEqual(Model, MODEL_ROCHELLE, false))
		g_iSavedModel[client] = ROCHELLE;
	if (StrEqual(Model, MODEL_COACH, false))
		g_iSavedModel[client] = COACH;
	if (StrEqual(Model, MODEL_ELLIS, false))
		g_iSavedModel[client] = ELLIS;
	
	if (g_iGameMode == GAMEMODE_COOP && StrEqual(CurrentMap, "c6m2_bedlam", true) && (GET_ZOEY_NETPROP || GET_FRANCIS_NETPROP || GET_LOUIS_NETPROP))
		g_iSavedCharacter[client] = 9;
	else
	g_iSavedCharacter[client] = GetEntProp(client, Prop_Send, "m_survivorCharacter");
	
	// restore the player's character. If it was The Passing and there was a mission failure, restore the L4D1 survivors.
	
	if (!g_bWasBill[client] && !g_bWasL4D1Survivor[client])
	{
		SetUpSurvivorModel(client, g_iSavedModel[client]);
		SetEntProp(client, Prop_Send, "m_survivorCharacter", g_iSavedCharacter[client]);
	}
	else if (g_iGameMode == GAMEMODE_COOP && (g_bWasL4D1Survivor[client] || g_bWasBill[client]))
	{
		#if DEBUG
		PrintToChatAll("Was L4D1 Survivor, changing character");
		#endif
		g_bWasL4D1Survivor[client] = false;
		CreateTimer(1.0, Timer_RestoreL4D1Survivor, client);
	}
}

public Action:Event_GameEnded(Handle:event, const String:name[], bool:dontBroadcast)
{
	#if DEBUG
	PrintToChatAll("The Safe Room door is closed and all survivors are in.");
	#endif
	
	// This event kills all of Bill's timers, and saves the each player's character. It also changes all Bills to Nick in order to prevent a crash. Also prevents glitches on The Passing with the
	// L4D1 Survivors.
	
	decl String:Model[256];
	
	decl String:CurrentMap[100];
	GetCurrentMap(CurrentMap, sizeof(CurrentMap));
	
	if (g_hBillTimer != INVALID_HANDLE)
	{
		KillTimer(g_hBillTimer);
		g_hBillTimer = INVALID_HANDLE;
	}
	if (g_hBillVersusTimer != INVALID_HANDLE)
	{
		KillTimer(g_hBillVersusTimer);
		g_hBillVersusTimer = INVALID_HANDLE;
	}
	if (g_hVersusSurvivorTimer != INVALID_HANDLE)
	{
		KillTimer(g_hVersusSurvivorTimer);
		g_hVersusSurvivorTimer = INVALID_HANDLE;
	}
	
	for (new client=1;client<=MaxClients;client++)
	{
		if (IsClientInGame(client))
		{
			if (GetClientTeam(client) == TEAM_SURVIVORS)
			{
				if (!IsFakeClient(client))
				{
					GetClientModel(client, Model, sizeof(Model));
					
					if (StrEqual(Model, MODEL_BILL, false))
						g_iSavedModel[client] = BILL;
					if (StrEqual(Model, MODEL_ZOEY, false))
						g_iSavedModel[client] = ZOEY;
					if (StrEqual(Model, MODEL_FRANCIS, false))
						g_iSavedModel[client] = FRANCIS;
					if (StrEqual(Model, MODEL_LOUIS, false))
						g_iSavedModel[client] = LOUIS;
					if (StrEqual(Model, MODEL_NICK, false))
						g_iSavedModel[client] = NICK;
					if (StrEqual(Model, MODEL_ROCHELLE, false))
						g_iSavedModel[client] = ROCHELLE;
					if (StrEqual(Model, MODEL_COACH, false))
						g_iSavedModel[client] = COACH;
					if (StrEqual(Model, MODEL_ELLIS, false))
						g_iSavedModel[client] = ELLIS;
					
					if (g_iGameMode == GAMEMODE_COOP && StrEqual(CurrentMap, "c6m2_bedlam", true) && (GET_ZOEY_NETPROP || GET_FRANCIS_NETPROP || GET_LOUIS_NETPROP))
						g_iSavedCharacter[client] = 9;
					else
					g_iSavedCharacter[client] = GetEntProp(client, Prop_Send, "m_survivorCharacter");
					
					if (g_iGameMode == GAMEMODE_VERSUS)
						SetEntProp(client, Prop_Send, "m_survivorCharacter", g_iVersusNewSurvivor[client]);
					
					if (GET_BILL_NETPROP || GET_BILL_ALT_NETPROP)
					{
						
						SET_CHARACTER_NICK
						SetEntityModel(client, MODEL_NICK);
						g_bWasBill[client] = true;
					}
				}
			}
		}
	}
	
	for (new i = 1; i <= MaxClients; i++)
		g_bPlayerHasEnteredStart[i] = false;
	
	g_bRoundStarted = false;
	g_bHasRoundEnded = true;
	g_bInFinale = false;
}

public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast) 
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if ((client > 0) && (client <= MaxClients) && !IsFakeClient(client))
		g_iClientChangeLimit[client] = g_iChangeLimit;
}

public Action:Event_MissionLost(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!g_bIsL4D2 || g_iL4D1Survivors == L4D1CAMPAIGN)
		return;
	
	// This event is primairly used for The Passing and the L4D1 Survivors, and prevents Bill from crashing the server.
	
	decl String:CurrentMap[100];
	GetCurrentMap(CurrentMap, sizeof(CurrentMap));
	decl String:Model[256];
	
	for (new client=1;client<=MaxClients;client++)
	{
		if (!IsClientInGame(client)) continue;
		
		if (GetClientTeam(client) == TEAM_SURVIVORS)
		{
			if (g_iGameMode == GAMEMODE_COOP)
			{
				if (StrEqual(CurrentMap, "c6m1_riverbank", true) || StrEqual(CurrentMap, "c6m3_port", true))
				{
					if (GET_ZOEY_NETPROP || GET_FRANCIS_NETPROP || GET_LOUIS_NETPROP)
					{
						GetClientModel(client, Model, sizeof(Model));
						g_bWasL4D1Survivor[client] = true;
						if (StrEqual(Model, MODEL_ZOEY, false))
							g_iSavedModel[client] = ZOEY;
						if (StrEqual(Model, MODEL_FRANCIS, false))
							g_iSavedModel[client] = FRANCIS;
						if (StrEqual(Model, MODEL_LOUIS, false))
							g_iSavedModel[client] = LOUIS;
						g_iSavedCharacter[client] = GetEntProp(client, Prop_Send, "m_survivorCharacter");
						if (StrEqual(CurrentMap, "c6m1_riverbank", true))
							SET_CHARACTER_NICK
						else
							SET_CHARACTER_GENERIC_SURVIVOR
					}
				}
				if (StrEqual(CurrentMap, "c6m3_port") == true)
					g_bc6m3lock = true;
			}
			
			if (GET_BILL_NETPROP || GET_BILL_ALT_NETPROP)
			{
				SET_CHARACTER_NICK
				SetEntityModel(client, MODEL_NICK);
				g_bWasBill[client] = true;
			}
		}
	}
	
	g_bInFinale = false;
}

public Action:Event_BillFinaleStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	// This event allows the horde to come in finals with Bill involved. Bill does not need my workaround in finales.
	
	if (g_hBillTimer != INVALID_HANDLE)
	{
		KillTimer(g_hBillTimer);
		g_hBillTimer = INVALID_HANDLE;
	}
	
	g_bInFinale = true;
	
	for (new client=1;client<=MaxClients;client++)
	{
		if (IsClientInGame(client))
		{
			if (GetClientTeam(client) == TEAM_SURVIVORS)
			{
				if (GET_BILL_NETPROP || GET_BILL_ALT_NETPROP || g_iVersusOldSurvivor[client] == 4)
				{
					SET_CHARACTER_BILL
				}
			}
		}
	}
	
	SetConVarInt(FindConVar("z_common_limit"), g_iCommonLimit);
}

public Action:Event_BillPanicEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	// If it's the finale, don't fire
	if (g_bInFinale)
		return;
	
	// Since it's hard for a Panic Event to trigger when Bill is in the party, I've used this event to get around this. If a Panic Event was supposed to occur and it doesn't, this event still triggers,
	// yet the time between the panic event and the end panic event is much shorter than if it had triggered.
	
	if (g_hBillTimer != INVALID_HANDLE)
	{
		KillTimer(g_hBillTimer);
		g_hBillTimer = INVALID_HANDLE;
	}
	
	for (new client=1;client<=MaxClients;client++)
	{
		if (IsClientInGame(client))
		{
			if (GetClientTeam(client) == TEAM_SURVIVORS)
			{
				if (GET_BILL_NETPROP || GET_BILL_ALT_NETPROP || g_iVersusOldSurvivor[client] == 4)
				{
					SET_CHARACTER_BILL_ALT
					CreateTimer(1.0, Timer_EndPanicRestoreBill, client, TIMER_FLAG_NO_MAPCHANGE);
				}
			}
		}
	}
	
	SetConVarInt(FindConVar("z_common_limit"), g_iCommonLimit);
	CheatCommand(GetAnyValidClient(), "z_spawn", "mob auto");
	CheatCommand(GetAnyValidClient(), "z_spawn", "mob auto");
	CheatCommand(GetAnyValidClient(), "z_spawn", "mob auto");
	CheatCommand(GetAnyValidClient(), "z_spawn", "mob auto");
	
}

public Action:Event_FinaleStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Prevents a horrific glitch with the L4D1 Survivors on this map
	
	#if DEBUG
	PrintToChatAll("Finale Started.");
	#endif
	
	if (g_iGameMode != GAMEMODE_COOP)
		return;
	
	decl String:CurrentMap[100];
	
	GetCurrentMap(CurrentMap, sizeof(CurrentMap));
	
	if (!StrEqual(CurrentMap, "c6m3_port", true))
		return;
	
	g_bc6m3lock = false;
	decl String:Model[100];
	
	for (new client=1;client<=MaxClients;client++)
	{
		if (IsClientInGame(client))
		{
			if (GetClientTeam(client) == TEAM_SURVIVORS)
			{
				if (GET_GENERIC_NETPROP)
				{
					GetClientModel(client, Model, sizeof(Model));
					if (StrEqual(MODEL_ZOEY, Model, true))
						SetCharacter(client, ZOEY);
					if (StrEqual(MODEL_FRANCIS, Model, true))
						SetCharacter(client, FRANCIS);
					if (StrEqual(MODEL_LOUIS, Model, true))
						SetCharacter(client, LOUIS);
				}
			}
		}
	}
}

public Action:Event_SomeoneIsVoting(Handle:event, const String:name[], bool:dontBroadcast)
{
	// The reason this event is here, is because Bill will crash the server if someone calls a successful vote to change the map. I would use vote passed or vote started, but they simply don't work.
	
	if (g_hBillTimer != INVALID_HANDLE)
	{
		KillTimer(g_hBillTimer);
		g_hBillTimer = INVALID_HANDLE;
	}
	
	if (g_hBillVersusTimer != INVALID_HANDLE)
	{
		KillTimer(g_hBillVersusTimer);
		g_hBillVersusTimer = INVALID_HANDLE;
	}
	
	for (new client=1;client<=MaxClients;client++)
	{
		if (IsClientInGame(client))
		{
			if (GetClientTeam(client) == TEAM_SURVIVORS)
			{
				if (GET_BILL_NETPROP)
				{
					if (g_iGameMode != GAMEMODE_VERSUS)
						SetUpSurvivor(client, NICK);
					else
					SetEntProp(client, Prop_Send, "m_survivorCharacter", g_iVersusNewSurvivor[client]);
				}
			}
		}
	}
}

public Action:Timer_EndPanicRestoreBill(Handle:timer, any:client)
{
	if (IsClientInGame(client))
		SetUpSurvivor(client, BILL);
}

public Action:Timer_ChangeVersusSurvivor(Handle:timer)
{
	for (new client=1;client<=MaxClients;client++)
	{
		if (IsClientInGame(client))
		{
			if (GetClientTeam(client) == TEAM_SURVIVORS)
			{
				if (GET_ZOEY_NETPROP || GET_FRANCIS_NETPROP || GET_LOUIS_NETPROP)
				{
					g_iVersusOldSurvivor[client] = GetEntProp(client, Prop_Send, "m_survivorCharacter");
					if (g_iGameMode == GAMEMODE_VERSUS)
						SetEntProp(client, Prop_Send, "m_survivorCharacter", g_iVersusNewSurvivor[client]);
					
					// We need a timer to delay the change, else the points won't be given. 0.6 seconds was the shortest time I could get in restoring the points.
					CreateTimer(0.6, Timer_RestoreVersusSurvivor, client);
				}
			}
		}
	}
	g_hVersusSurvivorTimer = INVALID_HANDLE;
}

public Action:Timer_RestoreVersusSurvivor(Handle:timer, any:client)
{
	// The timer to restore the survivor is 10 seconds, but you may change it to whatever you wish.
	
	if (IsClientInGame(client))
	{
		SetEntProp(client, Prop_Send, "m_survivorCharacter", g_iVersusOldSurvivor[client]);
		if (g_hVersusSurvivorTimer == INVALID_HANDLE)
			g_hVersusSurvivorTimer = CreateTimer(L4D1_SURVIVOR_VERSUS_RESTORE, Timer_ChangeVersusSurvivor);
	}
}

public Action:Timer_RestoreL4D1Survivor(Handle:timer, any:client)
{
	decl String:CurrentMap[100];
	GetCurrentMap(CurrentMap, sizeof(CurrentMap));
	
	if (!StrEqual(CurrentMap, "c6m3_port", true))
	{
		SetUpSurvivorModel(client, g_iSavedModel[client]);
		SetEntProp(client, Prop_Send, "m_survivorCharacter", g_iSavedCharacter[client]);
	}
	
	if (g_bWasBill[client])
	{
		SetUpSurvivor(client, BILL);
		g_bWasBill[client] = false;	
	}
}

public OnClientPutInServer(client) 
{
	if (!g_bEnabled || (g_iChangeLimit == 0))
		return;
	
	if ((client > 0) && (client <= MaxClients) && !IsFakeClient(client)) 
	{
		g_iClientChangeLimit[client] = g_iChangeLimit;
		g_bPlayerHasEnteredStart[client] = false;
		if (g_bAnnounce)
			CreateTimer(30.0, AnnounceCharSelect, client);
	}
}

public OnMapEnd()
{
	// Kill all timers and restore a few variables.
	
	if (g_hBillTimer != INVALID_HANDLE)
	{
		KillTimer(g_hBillTimer);
		g_hBillTimer = INVALID_HANDLE;
	}
	if (g_hBillVersusTimer != INVALID_HANDLE)
	{
		KillTimer(g_hBillVersusTimer);
		g_hBillVersusTimer = INVALID_HANDLE;
	}
	if (g_hVersusSurvivorTimer != INVALID_HANDLE)
	{
		KillTimer(g_hVersusSurvivorTimer);
		g_hVersusSurvivorTimer = INVALID_HANDLE;
	}
	
	g_bc6m3lock = false;
	g_bRoundStarted = false;
	g_bHasRoundEnded = true;
	g_bBillIsChanging = false;
	g_bInFinale = false;
	
	SetConVarInt(FindConVar("z_common_limit"), g_iCommonLimit);
}

public Action:AnnounceCharSelect(Handle:timer, any:client) 
{
	if (IsClientInGame(client)) 
	{
		if (GetClientTeam(client) == TEAM_SURVIVORS && g_bAnnounce)
		{
			switch (g_iSurvivorModels) 
			{
				case CSM_SURVIVOR_MODEL_ONLY:
				PrintToChat(client, "\x03[BG]\x01 输入 \x05!csm\x01 改变外观.");
				case CSM_SURVIVOR_CHARACTER_ONLY:
				PrintToChat(client, "\x03[BG]\x01 输入 \x05!csm\x01 改变角色.");
				case CSM_SURVIVOR_MODEL_AND_CHARACTER:
				PrintToChat(client, "\x03[BG]\x01 输入 \x05!csm\x01 改变角色或外观.");
			}
			
			switch (g_iInfectedModels) 
			{
				case CSM_INFECTED_MODEL_ONLY:
				PrintToChat(client, "\x03[BG]\x01 Type \x05!csm\x01 in chat to change your model to an infected (outside apperance).");
				case CSM_INFECTED_CHARACTER_ONLY:
				PrintToChat(client, "\x03[BG]\x01 Type \x05!csm\x01 in chat to change your character to an infected (outside appearance, abilities and sounds).");
				case CSM_INFECTED_CHARACTER_AND_MODEL:
				PrintToChat(client, "\x03[BG]\x01 Type \x05!csm\x01 in chat to change your character (outside appearance, abilities and sounds) or model (outside apperance) to an infected.");
			}
		}
	}
}






//////////////////////////////////////////////
//ADMIN MENU
//////////////////////////////////////////////






public Action:InitiateMenuAdmin(client, args) 
{
	if (client == 0) 
	{
		ReplyToCommand(client, "[BG] Character Select Menu is in-game only.");
		return;
	}
	if ((g_iChangeLimit == 0) || !g_bEnabled) 
	{
		ReplyToCommand(client, "[BG] Character Select Menu is currently disabled.");
		return;
	}
	if (g_iSurvivorModels == 0 && g_iInfectedModels == 0 && !g_bCommonModels)
	{
		ReplyToCommand(client, "[BG] Character Select Menu has no options available.");
		return;
	}
	
	decl String:name[MAX_NAME_LENGTH], String:number[10];
	
	new Handle:menu = CreateMenu(ShowMenu2);
	SetMenuTitle(menu, "选择:");
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i)) continue;
		if (GetClientTeam(i) != TEAM_SURVIVORS) continue;
		if (i == client) continue;
		
		Format(name, sizeof(name), "%N", i);
		Format(number, sizeof(number), "%i", i);
		AddMenuItem(menu, number, name);
	}
	
	
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public ShowMenu2(Handle:menu, MenuAction:action, param1, param2) 
{
	switch (action) 
	{
		case MenuAction_Select: 
		{
			decl String:number[4];
			GetMenuItem(menu, param2, number, sizeof(number));
			
			g_iSelectedClient = StringToInt(number);
			
			new args;
			ShowMenuAdmin(param1, args);
		}
		case MenuAction_Cancel:
		{
			
		}
		case MenuAction_End: 
		{
			CloseHandle(menu);
		}
	}
}

public Action:ShowMenuAdmin(client, args) 
{
	decl String:sMenuEntry[8];
	
	new Handle:menu = CreateMenu(CharMenuAdmin);
	SetMenuTitle(menu, "选择一个角色:");
	
	if (g_iSurvivorModels != 0)
	{
		if (g_iSurvivorModels != CSM_SURVIVOR_MODEL_ONLY) 
		{
			if (g_bIsL4D2) 
			{
				if (g_iL4D1Survivors != L4D1CAMPAIGN)
				{
					IntToString(NICK, sMenuEntry, sizeof(sMenuEntry));
					AddMenuItem(menu, sMenuEntry, "Nick");
					IntToString(ROCHELLE, sMenuEntry, sizeof(sMenuEntry));
					AddMenuItem(menu, sMenuEntry, "Rochelle");
					IntToString(COACH, sMenuEntry, sizeof(sMenuEntry));
					AddMenuItem(menu, sMenuEntry, "Coach");
					IntToString(ELLIS, sMenuEntry, sizeof(sMenuEntry));
					AddMenuItem(menu, sMenuEntry, "Ellis");
				}
				if (g_iL4D1Survivors != 0) 
				{
					IntToString(BILL, sMenuEntry, sizeof(sMenuEntry));
					AddMenuItem(menu, sMenuEntry, "Bill");	
					IntToString(ZOEY, sMenuEntry, sizeof(sMenuEntry));
					AddMenuItem(menu, sMenuEntry, "Zoey");
					IntToString(FRANCIS, sMenuEntry, sizeof(sMenuEntry));
					AddMenuItem(menu, sMenuEntry, "Francis");
					IntToString(LOUIS, sMenuEntry, sizeof(sMenuEntry));
					AddMenuItem(menu, sMenuEntry, "Louis");
				}
			} 
			else 
			{
				IntToString(BILL, sMenuEntry, sizeof(sMenuEntry));
				AddMenuItem(menu, sMenuEntry, "Bill");
				IntToString(ZOEY, sMenuEntry, sizeof(sMenuEntry));
				AddMenuItem(menu, sMenuEntry, "Zoey");
				IntToString(FRANCIS, sMenuEntry, sizeof(sMenuEntry));
				AddMenuItem(menu, sMenuEntry, "Francis");
				IntToString(LOUIS, sMenuEntry, sizeof(sMenuEntry));
				AddMenuItem(menu, sMenuEntry, "Louis");
			}
			/*if (!StrEqual(g_sCustomSurvivor1, ""))
			{
			IntToString(CUSTOM_SURVIVOR_1, sMenuEntry, sizeof(sMenuEntry));
			AddMenuItem(menu, sMenuEntry, "Custom Survivor 1");
			}*/
		}
		
		if (g_iSurvivorModels != CSM_SURVIVOR_CHARACTER_ONLY) 
		{
			if (g_bIsL4D2) 
			{
				IntToString(NICK_MODEL, sMenuEntry, sizeof(sMenuEntry));
				AddMenuItem(menu, sMenuEntry, "Nick (Model)");
				IntToString(ROCHELLE_MODEL, sMenuEntry, sizeof(sMenuEntry));
				AddMenuItem(menu, sMenuEntry, "Rochelle (Model)");
				IntToString(COACH_MODEL, sMenuEntry, sizeof(sMenuEntry));
				AddMenuItem(menu, sMenuEntry, "Coach (Model)");
				IntToString(ELLIS_MODEL, sMenuEntry, sizeof(sMenuEntry));
				AddMenuItem(menu, sMenuEntry, "Ellis (Model)");
				if (g_iL4D1Survivors != 0) 
				{
					IntToString(BILL_MODEL, sMenuEntry, sizeof(sMenuEntry));
					AddMenuItem(menu, sMenuEntry, "Bill (Model)");
					IntToString(ZOEY_MODEL, sMenuEntry, sizeof(sMenuEntry));
					AddMenuItem(menu, sMenuEntry, "Zoey (Model)");
					IntToString(FRANCIS_MODEL, sMenuEntry, sizeof(sMenuEntry));
					AddMenuItem(menu, sMenuEntry, "Francis (Model)");
					IntToString(LOUIS_MODEL, sMenuEntry, sizeof(sMenuEntry));
					AddMenuItem(menu, sMenuEntry, "Louis (Model)");
				}
			} 
			else 
			{
				IntToString(BILL_MODEL, sMenuEntry, sizeof(sMenuEntry));
				AddMenuItem(menu, sMenuEntry, "Bill (Model)");
				IntToString(ZOEY_MODEL, sMenuEntry, sizeof(sMenuEntry));
				AddMenuItem(menu, sMenuEntry, "Zoey (Model)");
				IntToString(FRANCIS_MODEL, sMenuEntry, sizeof(sMenuEntry));
				AddMenuItem(menu, sMenuEntry, "Francis (Model)");
				IntToString(LOUIS_MODEL, sMenuEntry, sizeof(sMenuEntry));
				AddMenuItem(menu, sMenuEntry, "Louis (Model)");
			}
			/*if (!StrEqual(g_sCustomSurvivor1, ""))
			{
			IntToString(CUSTOM_SURVIVOR_1, sMenuEntry, sizeof(sMenuEntry));
			AddMenuItem(menu, sMenuEntry, "Custom Survivor 1 (Model)");
			}*/
		}
	}
	if (g_iInfectedModels != 0)
	{
		if (g_iInfectedModels != CSM_INFECTED_MODEL_ONLY)
		{
			IntToString(SMOKER, sMenuEntry, sizeof(sMenuEntry));
			AddMenuItem(menu, sMenuEntry, "Smoker");
			IntToString(BOOMER, sMenuEntry, sizeof(sMenuEntry));
			AddMenuItem(menu, sMenuEntry, "Boomer");
			IntToString(HUNTER, sMenuEntry, sizeof(sMenuEntry));
			AddMenuItem(menu, sMenuEntry, "Hunter");
			if (g_bIsL4D2)
			{
				
				IntToString(BOOMETTE, sMenuEntry, sizeof(sMenuEntry));
				AddMenuItem(menu, sMenuEntry, "Boomette");
				IntToString(CHARGER, sMenuEntry, sizeof(sMenuEntry));
				AddMenuItem(menu, sMenuEntry, "Charger");
				IntToString(JOCKEY, sMenuEntry, sizeof(sMenuEntry));
				AddMenuItem(menu, sMenuEntry, "Jockey");
				IntToString(SPITTER, sMenuEntry, sizeof(sMenuEntry));
				AddMenuItem(menu, sMenuEntry, "Spitter");
			}
			IntToString(TANK, sMenuEntry, sizeof(sMenuEntry));
			AddMenuItem(menu, sMenuEntry, "Tank");
		}
		
		if (g_iInfectedModels != CSM_INFECTED_CHARACTER_ONLY)
		{
			IntToString(SMOKER_MODEL, sMenuEntry, sizeof(sMenuEntry));
			AddMenuItem(menu, sMenuEntry, "Smoker (Model)");
			IntToString(BOOMER_MODEL, sMenuEntry, sizeof(sMenuEntry));
			AddMenuItem(menu, sMenuEntry, "Boomer (Model)");
			IntToString(HUNTER_MODEL, sMenuEntry, sizeof(sMenuEntry));
			AddMenuItem(menu, sMenuEntry, "Hunter (Model)");
			if (g_bIsL4D2)
			{
				IntToString(BOOMETTE_MODEL, sMenuEntry, sizeof(sMenuEntry));
				AddMenuItem(menu, sMenuEntry, "Boomette (Model)");
				IntToString(CHARGER_MODEL, sMenuEntry, sizeof(sMenuEntry));
				AddMenuItem(menu, sMenuEntry, "Charger (Model)");
				IntToString(JOCKEY_MODEL, sMenuEntry, sizeof(sMenuEntry));
				AddMenuItem(menu, sMenuEntry, "Jockey (Model)");
				IntToString(SPITTER_MODEL, sMenuEntry, sizeof(sMenuEntry));
				AddMenuItem(menu, sMenuEntry, "Spitter (Model)");
			}
			IntToString(TANK_MODEL, sMenuEntry, sizeof(sMenuEntry));
			AddMenuItem(menu, sMenuEntry, "Tank (Model)");
		}
	}
	
	if (g_bCommonModels)
	{
		IntToString(WITCH_MODEL, sMenuEntry, sizeof(sMenuEntry));
		AddMenuItem(menu, sMenuEntry, "Witch (Model)");
		if (g_bIsL4D2)
		{
			IntToString(CEDA_HAZMAT_MODEL, sMenuEntry, sizeof(sMenuEntry));
			AddMenuItem(menu, sMenuEntry, "CEDA Hazmat (Model)");
			IntToString(CLOWN_MODEL, sMenuEntry, sizeof(sMenuEntry));
			AddMenuItem(menu, sMenuEntry, "Clown (Model)");
			IntToString(MUD_MAN_MODEL, sMenuEntry, sizeof(sMenuEntry));
			AddMenuItem(menu, sMenuEntry, "Mud Man (Model)");
			IntToString(CONSTRUCTION_WORKER_MODEL, sMenuEntry, sizeof(sMenuEntry));
			AddMenuItem(menu, sMenuEntry, "Construction Worker (Model)");
			IntToString(RIOT_OFFICER_MODEL, sMenuEntry, sizeof(sMenuEntry));
			AddMenuItem(menu, sMenuEntry, "Riot Officer (Model)");
			IntToString(FALLEN_SURVIVOR_MODEL, sMenuEntry, sizeof(sMenuEntry));
			AddMenuItem(menu, sMenuEntry, "Fallen Survivor (Model)");
			IntToString(JIMMY_GIBBS_JR_MODEL, sMenuEntry, sizeof(sMenuEntry));
			AddMenuItem(menu, sMenuEntry, "Jimmy Gibbs Jr. (Model)");
		}
	}
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public CharMenuAdmin(Handle:menu, MenuAction:action, param1, param2) 
{
	switch (action) 
	{
		case MenuAction_Select: 
		{
			decl String:item[8];
			GetMenuItem(menu, param2, item, sizeof(item));
			
			switch(StringToInt(item)) 
			{
				case NICK:		{	SetUpSurvivor(g_iSelectedClient, NICK);		}
				case ROCHELLE:	{	SetUpSurvivor(g_iSelectedClient, ROCHELLE);	}
				case COACH:		{	SetUpSurvivor(g_iSelectedClient, COACH);		}
				case ELLIS:		{	SetUpSurvivor(g_iSelectedClient, ELLIS);		}
				case BILL:		{	SetUpSurvivor(g_iSelectedClient, BILL);		}
				case ZOEY:		{	SetUpSurvivor(g_iSelectedClient, ZOEY);		}
				case FRANCIS:	{	SetUpSurvivor(g_iSelectedClient, FRANCIS);	}
				case LOUIS:		{	SetUpSurvivor(g_iSelectedClient, LOUIS);		}
				
				case NICK_MODEL:		{	SetUpSurvivorModel(g_iSelectedClient, NICK);			}
				case ROCHELLE_MODEL:	{	SetUpSurvivorModel(g_iSelectedClient, ROCHELLE);	}
				case COACH_MODEL:		{	SetUpSurvivorModel(g_iSelectedClient, COACH);		}
				case ELLIS_MODEL:		{	SetUpSurvivorModel(g_iSelectedClient, ELLIS);		}
				case BILL_MODEL:		{	SetUpSurvivorModel(g_iSelectedClient, BILL);			}
				case ZOEY_MODEL:		{	SetUpSurvivorModel(g_iSelectedClient, ZOEY);			}
				case FRANCIS_MODEL:		{	SetUpSurvivorModel(g_iSelectedClient, FRANCIS);		}
				case LOUIS_MODEL:		{	SetUpSurvivorModel(g_iSelectedClient, LOUIS);		}
				case SMOKER:			{	SetUpInfected(g_iSelectedClient, SMOKER);		}
				case BOOMER:			{	SetUpInfected(g_iSelectedClient, BOOMER);		}
				case BOOMETTE:			{	SetUpInfected(g_iSelectedClient, BOOMETTE);	}
				case HUNTER:			{	SetUpInfected(g_iSelectedClient, HUNTER);		}
				case CHARGER:			{	SetUpInfected(g_iSelectedClient, CHARGER);		}
				case JOCKEY:			{	SetUpInfected(g_iSelectedClient, JOCKEY);		}
				case SPITTER:			{	SetUpInfected(g_iSelectedClient, SPITTER);		}
				case TANK:				{	SetUpInfected(g_iSelectedClient, TANK);		}
				case SMOKER_MODEL:			{	SetUpInfectedModel(g_iSelectedClient, SMOKER);		}
				case BOOMER_MODEL:			{	SetUpInfectedModel(g_iSelectedClient, BOOMER);		}
				case BOOMETTE_MODEL:			{	SetUpInfectedModel(g_iSelectedClient, BOOMETTE);		}
				case HUNTER_MODEL:			{	SetUpInfectedModel(g_iSelectedClient, HUNTER);		}
				case CHARGER_MODEL:			{	SetUpInfectedModel(g_iSelectedClient, CHARGER);		}
				case JOCKEY_MODEL:			{	SetUpInfectedModel(g_iSelectedClient, JOCKEY);		}
				case SPITTER_MODEL:			{	SetUpInfectedModel(g_iSelectedClient, SPITTER);		}
				case TANK_MODEL:			{	SetUpInfectedModel(g_iSelectedClient, TANK);		}
				case WITCH_MODEL:			{	SetUpCommonModel(g_iSelectedClient, WITCH_MODEL);		}
				case CEDA_HAZMAT_MODEL:			{	SetUpCommonModel(g_iSelectedClient, CEDA_HAZMAT_MODEL);		}
				case CLOWN_MODEL:			{	SetUpCommonModel(g_iSelectedClient, CLOWN_MODEL);		}
				case MUD_MAN_MODEL:			{	SetUpCommonModel(g_iSelectedClient, MUD_MAN_MODEL);		}
				case CONSTRUCTION_WORKER_MODEL:			{	SetUpCommonModel(g_iSelectedClient, CONSTRUCTION_WORKER_MODEL);		}
				case RIOT_OFFICER_MODEL:			{	SetUpCommonModel(g_iSelectedClient, RIOT_OFFICER_MODEL);		}
				case FALLEN_SURVIVOR_MODEL:			{	SetUpCommonModel(g_iSelectedClient, FALLEN_SURVIVOR_MODEL);		}
				case JIMMY_GIBBS_JR_MODEL:			{	SetUpCommonModel(g_iSelectedClient, JIMMY_GIBBS_JR_MODEL);		}
				//case CUSTOM_SURVIVOR_1:			{	SetUpSurvivor(g_iSelectedClient, CUSTOM_SURVIVOR_1);		}
			}
		}
		case MenuAction_Cancel:
		{
			
		}
		case MenuAction_End: 
		{
			CloseHandle(menu);
		}
	}
}








//////////////////////////////////////////////
//CLIENT MENU
//////////////////////////////////////////////







public Action:ShowMenu(client, args) 
{
	if (client == 0) 
	{
		ReplyToCommand(client, "[BG] Character Select Menu is in-game only.");
		return;
	}
	if ((g_iChangeLimit == 0) || !g_bEnabled) 
	{
		ReplyToCommand(client, "[BG] Character Select Menu is currently disabled.");
		return;
	}
	if (GetUserFlagBits(client) == 0 && g_bAdminsOnly)
	{
		ReplyToCommand(client, "[BG] Character Select Menu is only available to admins.");
		return;
	}
	if (GetClientTeam(client) != TEAM_SURVIVORS)
	{
		ReplyToCommand(client, "[BG] Character Select Menu is only available to survivors.");
		return;
	}
	if (g_iSurvivorModels == 0 && g_iInfectedModels == 0 && !g_bCommonModels)
	{
		ReplyToCommand(client, "[BG] Character Select Menu has no options available.");
		return;
	}
	if (!PlayerIsAlive(client)) 
	{
		ReplyToCommand(client, "[BG] You must be alive to use the Character Select Menu!");
		return;
	}
	if (g_iClientChangeLimit[client] < 1) 
	{
		ReplyToCommand(client, "[BG] You cannot change your character again until you respawn.");
		return;
	}
	
	decl String:sMenuEntry[8];
	
	new Handle:menu = CreateMenu(CharMenu);
	SetMenuTitle(menu, "选择一个角色:");
	
	if (g_iSurvivorModels != 0)
	{
		if (g_iSurvivorModels != CSM_SURVIVOR_MODEL_ONLY) 
		{
			if (g_bIsL4D2) 
			{
				if (g_iL4D1Survivors != L4D1CAMPAIGN)
				{
					IntToString(NICK, sMenuEntry, sizeof(sMenuEntry));
					AddMenuItem(menu, sMenuEntry, "Nick");
					IntToString(ROCHELLE, sMenuEntry, sizeof(sMenuEntry));
					AddMenuItem(menu, sMenuEntry, "Rochelle");
					IntToString(COACH, sMenuEntry, sizeof(sMenuEntry));
					AddMenuItem(menu, sMenuEntry, "Coach");
					IntToString(ELLIS, sMenuEntry, sizeof(sMenuEntry));
					AddMenuItem(menu, sMenuEntry, "Ellis");
				}
				if (g_iL4D1Survivors != 0) 
				{
					IntToString(BILL, sMenuEntry, sizeof(sMenuEntry));
					AddMenuItem(menu, sMenuEntry, "Bill");	
					IntToString(ZOEY, sMenuEntry, sizeof(sMenuEntry));
					AddMenuItem(menu, sMenuEntry, "Zoey");
					IntToString(FRANCIS, sMenuEntry, sizeof(sMenuEntry));
					AddMenuItem(menu, sMenuEntry, "Francis");
					IntToString(LOUIS, sMenuEntry, sizeof(sMenuEntry));
					AddMenuItem(menu, sMenuEntry, "Louis");
				}
			} 
			else 
			{
				IntToString(BILL, sMenuEntry, sizeof(sMenuEntry));
				AddMenuItem(menu, sMenuEntry, "Bill");
				IntToString(ZOEY, sMenuEntry, sizeof(sMenuEntry));
				AddMenuItem(menu, sMenuEntry, "Zoey");
				IntToString(FRANCIS, sMenuEntry, sizeof(sMenuEntry));
				AddMenuItem(menu, sMenuEntry, "Francis");
				IntToString(LOUIS, sMenuEntry, sizeof(sMenuEntry));
				AddMenuItem(menu, sMenuEntry, "Louis");
			}
			/*if (!StrEqual(g_sCustomSurvivor1, ""))
			{
			IntToString(CUSTOM_SURVIVOR_1, sMenuEntry, sizeof(sMenuEntry));
			AddMenuItem(menu, sMenuEntry, "Custom Survivor 1");
			}*/
		}
		
		if (g_iSurvivorModels != CSM_SURVIVOR_CHARACTER_ONLY) 
		{
			if (g_bIsL4D2) 
			{
				IntToString(NICK_MODEL, sMenuEntry, sizeof(sMenuEntry));
				AddMenuItem(menu, sMenuEntry, "Nick (Model)");
				IntToString(ROCHELLE_MODEL, sMenuEntry, sizeof(sMenuEntry));
				AddMenuItem(menu, sMenuEntry, "Rochelle (Model)");
				IntToString(COACH_MODEL, sMenuEntry, sizeof(sMenuEntry));
				AddMenuItem(menu, sMenuEntry, "Coach (Model)");
				IntToString(ELLIS_MODEL, sMenuEntry, sizeof(sMenuEntry));
				AddMenuItem(menu, sMenuEntry, "Ellis (Model)");
				if (g_iL4D1Survivors != 0) 
				{
					IntToString(BILL_MODEL, sMenuEntry, sizeof(sMenuEntry));
					AddMenuItem(menu, sMenuEntry, "Bill (Model)");
					IntToString(ZOEY_MODEL, sMenuEntry, sizeof(sMenuEntry));
					AddMenuItem(menu, sMenuEntry, "Zoey (Model)");
					IntToString(FRANCIS_MODEL, sMenuEntry, sizeof(sMenuEntry));
					AddMenuItem(menu, sMenuEntry, "Francis (Model)");
					IntToString(LOUIS_MODEL, sMenuEntry, sizeof(sMenuEntry));
					AddMenuItem(menu, sMenuEntry, "Louis (Model)");
				}
			} 
			else 
			{
				IntToString(BILL_MODEL, sMenuEntry, sizeof(sMenuEntry));
				AddMenuItem(menu, sMenuEntry, "Bill (Model)");
				IntToString(ZOEY_MODEL, sMenuEntry, sizeof(sMenuEntry));
				AddMenuItem(menu, sMenuEntry, "Zoey (Model)");
				IntToString(FRANCIS_MODEL, sMenuEntry, sizeof(sMenuEntry));
				AddMenuItem(menu, sMenuEntry, "Francis (Model)");
				IntToString(LOUIS_MODEL, sMenuEntry, sizeof(sMenuEntry));
				AddMenuItem(menu, sMenuEntry, "Louis (Model)");
			}
			/*if (!StrEqual(g_sCustomSurvivor1, ""))
			{
			IntToString(CUSTOM_SURVIVOR_1, sMenuEntry, sizeof(sMenuEntry));
			AddMenuItem(menu, sMenuEntry, "Custom Survivor 1 (Model)");
			}*/
		}
	}
	if (g_iInfectedModels != 0)
	{
		if (g_iInfectedModels != CSM_INFECTED_MODEL_ONLY)
		{
			IntToString(SMOKER, sMenuEntry, sizeof(sMenuEntry));
			AddMenuItem(menu, sMenuEntry, "Smoker");
			IntToString(BOOMER, sMenuEntry, sizeof(sMenuEntry));
			AddMenuItem(menu, sMenuEntry, "Boomer");
			IntToString(HUNTER, sMenuEntry, sizeof(sMenuEntry));
			AddMenuItem(menu, sMenuEntry, "Hunter");
			if (g_bIsL4D2)
			{
				
				IntToString(BOOMETTE, sMenuEntry, sizeof(sMenuEntry));
				AddMenuItem(menu, sMenuEntry, "Boomette");
				IntToString(CHARGER, sMenuEntry, sizeof(sMenuEntry));
				AddMenuItem(menu, sMenuEntry, "Charger");
				IntToString(JOCKEY, sMenuEntry, sizeof(sMenuEntry));
				AddMenuItem(menu, sMenuEntry, "Jockey");
				IntToString(SPITTER, sMenuEntry, sizeof(sMenuEntry));
				AddMenuItem(menu, sMenuEntry, "Spitter");
			}
			IntToString(TANK, sMenuEntry, sizeof(sMenuEntry));
			AddMenuItem(menu, sMenuEntry, "Tank");
		}
		
		if (g_iInfectedModels != CSM_INFECTED_CHARACTER_ONLY)
		{
			IntToString(SMOKER_MODEL, sMenuEntry, sizeof(sMenuEntry));
			AddMenuItem(menu, sMenuEntry, "Smoker (Model)");
			IntToString(BOOMER_MODEL, sMenuEntry, sizeof(sMenuEntry));
			AddMenuItem(menu, sMenuEntry, "Boomer (Model)");
			IntToString(HUNTER_MODEL, sMenuEntry, sizeof(sMenuEntry));
			AddMenuItem(menu, sMenuEntry, "Hunter (Model)");
			if (g_bIsL4D2)
			{
				IntToString(BOOMETTE_MODEL, sMenuEntry, sizeof(sMenuEntry));
				AddMenuItem(menu, sMenuEntry, "Boomette (Model)");
				IntToString(CHARGER_MODEL, sMenuEntry, sizeof(sMenuEntry));
				AddMenuItem(menu, sMenuEntry, "Charger (Model)");
				IntToString(JOCKEY_MODEL, sMenuEntry, sizeof(sMenuEntry));
				AddMenuItem(menu, sMenuEntry, "Jockey (Model)");
				IntToString(SPITTER_MODEL, sMenuEntry, sizeof(sMenuEntry));
				AddMenuItem(menu, sMenuEntry, "Spitter (Model)");
			}
			IntToString(TANK_MODEL, sMenuEntry, sizeof(sMenuEntry));
			AddMenuItem(menu, sMenuEntry, "Tank (Model)");
		}
	}
	
	if (g_bCommonModels)
	{
		IntToString(WITCH_MODEL, sMenuEntry, sizeof(sMenuEntry));
		AddMenuItem(menu, sMenuEntry, "Witch (Model)");
		if (g_bIsL4D2)
		{
			IntToString(CEDA_HAZMAT_MODEL, sMenuEntry, sizeof(sMenuEntry));
			AddMenuItem(menu, sMenuEntry, "CEDA Hazmat (Model)");
			IntToString(CLOWN_MODEL, sMenuEntry, sizeof(sMenuEntry));
			AddMenuItem(menu, sMenuEntry, "Clown (Model)");
			IntToString(MUD_MAN_MODEL, sMenuEntry, sizeof(sMenuEntry));
			AddMenuItem(menu, sMenuEntry, "Mud Man (Model)");
			IntToString(CONSTRUCTION_WORKER_MODEL, sMenuEntry, sizeof(sMenuEntry));
			AddMenuItem(menu, sMenuEntry, "Construction Worker (Model)");
			IntToString(RIOT_OFFICER_MODEL, sMenuEntry, sizeof(sMenuEntry));
			AddMenuItem(menu, sMenuEntry, "Riot Officer (Model)");
			IntToString(FALLEN_SURVIVOR_MODEL, sMenuEntry, sizeof(sMenuEntry));
			AddMenuItem(menu, sMenuEntry, "Fallen Survivor (Model)");
			IntToString(JIMMY_GIBBS_JR_MODEL, sMenuEntry, sizeof(sMenuEntry));
			AddMenuItem(menu, sMenuEntry, "Jimmy Gibbs Jr. (Model)");
		}
	}
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}


public CharMenu(Handle:menu, MenuAction:action, param1, param2) 
{
	switch (action) 
	{
		case MenuAction_Select: 
		{
			decl String:item[8];
			GetMenuItem(menu, param2, item, sizeof(item));
			
			switch(StringToInt(item)) 
			{
				case NICK:		{	SetUpSurvivor(param1, NICK);		}
				case ROCHELLE:	{	SetUpSurvivor(param1, ROCHELLE);	}
				case COACH:		{	SetUpSurvivor(param1, COACH);		}
				case ELLIS:		{	SetUpSurvivor(param1, ELLIS);		}
				case BILL:		{	SetUpSurvivor(param1, BILL);		}
				case ZOEY:		{	SetUpSurvivor(param1, ZOEY);		}
				case FRANCIS:	{	SetUpSurvivor(param1, FRANCIS);	}
				case LOUIS:		{	SetUpSurvivor(param1, LOUIS);		}
				
				case NICK_MODEL:		{	SetUpSurvivorModel(param1, NICK);			}
				case ROCHELLE_MODEL:	{	SetUpSurvivorModel(param1, ROCHELLE);	}
				case COACH_MODEL:		{	SetUpSurvivorModel(param1, COACH);		}
				case ELLIS_MODEL:		{	SetUpSurvivorModel(param1, ELLIS);		}
				case BILL_MODEL:		{	SetUpSurvivorModel(param1, BILL);			}
				case ZOEY_MODEL:		{	SetUpSurvivorModel(param1, ZOEY);			}
				case FRANCIS_MODEL:		{	SetUpSurvivorModel(param1, FRANCIS);		}
				case LOUIS_MODEL:		{	SetUpSurvivorModel(param1, LOUIS);		}
				case SMOKER:			{	SetUpInfected(param1, SMOKER);		}
				case BOOMER:			{	SetUpInfected(param1, BOOMER);		}
				case BOOMETTE:			{	SetUpInfected(param1, BOOMETTE);	}
				case HUNTER:			{	SetUpInfected(param1, HUNTER);		}
				case CHARGER:			{	SetUpInfected(param1, CHARGER);		}
				case JOCKEY:			{	SetUpInfected(param1, JOCKEY);		}
				case SPITTER:			{	SetUpInfected(param1, SPITTER);		}
				case TANK:				{	SetUpInfected(param1, TANK);		}
				case SMOKER_MODEL:			{	SetUpInfectedModel(param1, SMOKER);		}
				case BOOMER_MODEL:			{	SetUpInfectedModel(param1, BOOMER);		}
				case BOOMETTE_MODEL:			{	SetUpInfectedModel(param1, BOOMETTE);		}
				case HUNTER_MODEL:			{	SetUpInfectedModel(param1, HUNTER);		}
				case CHARGER_MODEL:			{	SetUpInfectedModel(param1, CHARGER);		}
				case JOCKEY_MODEL:			{	SetUpInfectedModel(param1, JOCKEY);		}
				case SPITTER_MODEL:			{	SetUpInfectedModel(param1, SPITTER);		}
				case TANK_MODEL:			{	SetUpInfectedModel(param1, TANK);		}
				case WITCH_MODEL:			{	SetUpCommonModel(param1, WITCH_MODEL);		}
				case CEDA_HAZMAT_MODEL:			{	SetUpCommonModel(param1, CEDA_HAZMAT_MODEL);		}
				case CLOWN_MODEL:			{	SetUpCommonModel(param1, CLOWN_MODEL);		}
				case MUD_MAN_MODEL:			{	SetUpCommonModel(param1, MUD_MAN_MODEL);		}
				case CONSTRUCTION_WORKER_MODEL:			{	SetUpCommonModel(param1, CONSTRUCTION_WORKER_MODEL);		}
				case RIOT_OFFICER_MODEL:			{	SetUpCommonModel(param1, RIOT_OFFICER_MODEL);		}
				case FALLEN_SURVIVOR_MODEL:			{	SetUpCommonModel(param1, FALLEN_SURVIVOR_MODEL);		}
				case JIMMY_GIBBS_JR_MODEL:			{	SetUpCommonModel(param1, JIMMY_GIBBS_JR_MODEL);		}
				//case CUSTOM_SURVIVOR_1:			{	SetUpSurvivor(param1, CUSTOM_SURVIVOR_1);		}
			}
		}
		case MenuAction_Cancel:
		{
			
		}
		case MenuAction_End: 
		{
			CloseHandle(menu);
		}
	}
}







//////////////////////////////////////////////
//SURVIVOR FUNCTIONS
//////////////////////////////////////////////






stock SetUpSurvivor(param1, Survivor) 
{	
	if (GetEntProp(param1, Prop_Send, "m_survivorCharacter") == 10)
	{
		new WeaponIndex;
		while ((WeaponIndex = GetPlayerWeaponSlot(param1, 0)) != -1)
		{
			RemovePlayerItem(param1, WeaponIndex);
			RemoveEdict(WeaponIndex);
		}
		CheatCommand(param1, "give", "pistol");
		SetEntProp(param1, Prop_Send, "m_customAbility", 0);
	}
	
	// The code above is for changing a "survivor infected" to a survivor
	
	// The code below lists the callbacks for each survivor. Louis and Francis are switched in L4D2, so I had to modify the callbacks appropriately.
	
	if (g_bIsL4D2 && g_iL4D1Survivors != L4D1CAMPAIGN) 
	{
		switch(Survivor) 
		{
			case NICK:		{	SetCharacter(param1, NICK);		}
			case ROCHELLE:	{	SetCharacter(param1, ROCHELLE);	}
			case COACH:		{	SetCharacter(param1, COACH);		}
			case ELLIS:		{	SetCharacter(param1, ELLIS);		}
			case BILL:		{	SetCharacter(param1, BILL);	}
			case ZOEY:		{	SetCharacter(param1, ZOEY);		}
			case FRANCIS:	{	SetCharacter(param1, FRANCIS);	}
			case LOUIS:		{	SetCharacter(param1, LOUIS);		}
		}
	}
	else if (g_bIsL4D2 && g_iL4D1Survivors == L4D1CAMPAIGN)
	{
		switch(Survivor) 
		{
			case BILL:		{	SetCharacter(param1, (BILL - 4));		}
			case ZOEY:		{	SetCharacter(param1, (ZOEY - 4));		}
			case FRANCIS:	{	SetCharacter(param1, (LOUIS - 4));	}
			case LOUIS:		{	SetCharacter(param1, (FRANCIS - 4));	}
		}
	}
	else
	{
		switch(Survivor) 
		{
			case BILL:		{	SetCharacter(param1, (BILL - 4));		}
			case ZOEY:		{	SetCharacter(param1, (ZOEY - 4));		}
			case FRANCIS:	{	SetCharacter(param1, (FRANCIS - 4));	}
			case LOUIS:		{	SetCharacter(param1, (LOUIS - 4));	}
		}
	}
	/*if (Survivor == CUSTOM_SURVIVOR_1)
	SetCharacter(param1, GENERIC_SURVIVOR);*/
	SetClientClassModel(param1, Survivor);
	g_iClientChangeLimit[param1]--;
	if (g_bAnnounce)
	{
		if (g_iClientChangeLimit[param1] <= CSM_CHANGE_MESSAGE) 
		{
			if (g_iClientChangeLimit[param1] == 0)
				PrintToChat(param1, "\x03[BG]\x01 现在你的角色是 \x04%s\x01! 下次重生前你不能更改.", g_sCharacters[Survivor]);
			else if (g_iClientChangeLimit[param1] == 1)
				PrintToChat(param1, "\x03[BG]\x01 现在你的角色是 \x04%s\x01! 你只能改变 \x051\x01 次.", g_sCharacters[Survivor]);
			else
			PrintToChat(param1, "\x03[BG]\x01 现在你的角色是 \x04%s\x01! 你还能改变 \x05%i\x01 次.", g_sCharacters[Survivor], g_iClientChangeLimit[param1]);
		} 
		else 
		{
			PrintToChat(param1, "\x03[BG]\x01 现在你的角色是 \x04%s\x01!", g_sCharacters[Survivor]);
		}
	}
}

stock SetUpSurvivorModel(param1, Survivor) 
{
	SetClientClassModel(param1, Survivor);
	g_iClientChangeLimit[param1]--;
	if (g_bAnnounce)
	{
		if (g_iClientChangeLimit[param1] <= CSM_CHANGE_MESSAGE)
			if (g_iClientChangeLimit[param1] == 0)
				PrintToChat(param1, "\x03[BG]\x01 现在你的角色是 \x04%s\x01! 下次重生前你不能更改.", g_sCharacters[Survivor+8]);
			else if (g_iClientChangeLimit[param1] == 1)
				PrintToChat(param1, "\x03[BG]\x01 现在你的角色是 \x04%s\x01! 你只能改变 \x051\x01 次.", g_sCharacters[Survivor+8]);
			else
		PrintToChat(param1, "\x03[BG]\x01 现在你的外观是 \x04%s\x01! 你还能改变 \x05%i\x01 次.", g_sCharacters[Survivor+8], g_iClientChangeLimit[param1]);
		else
		PrintToChat(param1, "\x03[BG]\x01 现在你的外观是 \x04%s\x01!", g_sCharacters[Survivor+8]);
	}
}

stock SetCharacter(client, character) 
{
	// The lock is to prevent a bad glitch on The Passing's third map with the L4D1 Survivors
	
	if (!g_bc6m3lock)
		SetEntProp(client, Prop_Send, "m_survivorCharacter", character);
	else if (g_bc6m3lock && character == ZOEY || g_bc6m3lock && character == FRANCIS || g_bc6m3lock && character == LOUIS)
		SET_CHARACTER_GENERIC_SURVIVOR
	else if (character != BILL)
		SetEntProp(client, Prop_Send, "m_survivorCharacter", character);
	
	// If its versus and the L4D1 survivors are picked, start this timer so that the player gets distance points.
	
	if (g_iGameMode == GAMEMODE_VERSUS && (character == ZOEY || character == FRANCIS || character == LOUIS))
	{
		if (g_hVersusSurvivorTimer == INVALID_HANDLE)
			g_hVersusSurvivorTimer = CreateTimer(0.1, Timer_ChangeVersusSurvivor);
	}
	
	// If Bill is not in a finale, start the workaround; if he is not in a finale, just set the player to Bill.
	
	if (character == BILL && !g_bInFinale)
		ChangeToBill(client);
	else if (character == BILL && g_bInFinale)
		SET_CHARACTER_BILL
}

stock SetClientClassModel(client, character) 
{
	switch(character) 
	{
		case NICK:		{	SetEntityModel(client, "models/survivors/survivor_gambler.mdl");		}
		case ROCHELLE:	{	SetEntityModel(client, "models/survivors/survivor_producer.mdl");		}
		case COACH:		{	SetEntityModel(client, "models/survivors/survivor_coach.mdl");		}
		case ELLIS:		{	SetEntityModel(client, "models/survivors/survivor_mechanic.mdl");		}
		case BILL:		{	SetEntityModel(client, "models/survivors/survivor_namvet.mdl");		}
		case ZOEY:		{	SetEntityModel(client, "models/survivors/survivor_teenangst.mdl");	}
		case FRANCIS:	{	SetEntityModel(client, "models/survivors/survivor_biker.mdl");		}
		case LOUIS:		{	SetEntityModel(client, "models/survivors/survivor_manager.mdl");		}
		case SMOKER:		{	SetEntityModel(client, "models/infected/smoker.mdl");		} 
		case BOOMER:		{	SetEntityModel(client, "models/infected/boomer.mdl");		} 
		case BOOMETTE:		{	SetEntityModel(client, "models/infected/boomette.mdl");		} 
		case HUNTER:		{	SetEntityModel(client, "models/infected/hunter.mdl");		} 
		case CHARGER:		{	SetEntityModel(client, "models/infected/charger.mdl");		} 
		case JOCKEY:		{	SetEntityModel(client, "models/infected/jockey.mdl");		} 
		case SPITTER:		{	SetEntityModel(client, "models/infected/spitter.mdl");		} 
		case TANK:			{	SetEntityModel(client, "models/infected/hulk.mdl");		} 
		case WITCH_MODEL:	{	SetEntityModel(client, "models/infected/witch.mdl");		}
		case CEDA_HAZMAT_MODEL:		{	SetEntityModel(client, "models/infected/common_male_ceda.mdl");		} 
		case CLOWN_MODEL:		{	SetEntityModel(client, "models/infected/common_male_clown.mdl");		} 
		case MUD_MAN_MODEL:		{	SetEntityModel(client, "models/infected/common_male_mud.mdl");		} 
		case CONSTRUCTION_WORKER_MODEL:		{	SetEntityModel(client, "models/infected/common_male_roadcrew.mdl");		} 
		case RIOT_OFFICER_MODEL:		{	SetEntityModel(client, "models/infected/common_male_riot.mdl");		} 
		case FALLEN_SURVIVOR_MODEL:		{	SetEntityModel(client, "models/infected/common_male_fallen_survivor.mdl");		} 
		case JIMMY_GIBBS_JR_MODEL:		{	SetEntityModel(client, "models/infected/common_male_jimmy.mdl");		}
		//case CUSTOM_SURVIVOR_1:		{	SetEntityModel(client, g_sCustomSurvivor1);		}
	}
}





//////////////////////////////////////////////
//BILL WORKAROUND
//////////////////////////////////////////////


// There are many fixes in the events, but this is the main Bill workaround.



stock ChangeToBill(client)
{
	if (g_hBillTimer == INVALID_HANDLE)
		g_hBillTimer = CreateTimer(BILL_TIME, Timer_SpawnZombies, TIMER_FLAG_NO_MAPCHANGE);
	
	// This is important as Bill will crash if z_common_limit is higher than 0.
	
	g_bBillIsChanging = true;
	SetConVarInt(FindConVar("z_common_limit"), 0);
	g_bBillIsChanging = false;
	SET_CHARACTER_BILL
}

public Action:Timer_SpawnZombies(Handle:Timer)
{
	// Invalidate the Bill timer
	g_hBillTimer = INVALID_HANDLE;
	
	new bool:billexists;
	
	for (new client=1;client<=MaxClients;client++)
	{
		if (!IsClientInGame(client)) continue;
		
		if (GetClientTeam(client) == TEAM_SURVIVORS)
		{
			if (GET_BILL_NETPROP || g_iVersusOldSurvivor[client] == 4)
			{
				billexists = true;
				SET_CHARACTER_BILL_ALT
			}
		}
	}
	
	// If Bill exists, Start the Bill Timer.
	
	if (billexists)
	{
		if (g_hBillTimer == INVALID_HANDLE)
			g_hBillTimer = CreateTimer(ZOMBIE_TIME, Timer_RestoreBill, TIMER_FLAG_NO_MAPCHANGE);
	}
	
	// Restore the z_common_limit cvar.
	
	g_bBillIsChanging = true;
	SetConVarInt(FindConVar("z_common_limit"), g_iCommonLimit);
	g_bBillIsChanging = false;
}

public Action:Timer_ChangeBillVersus(Handle:Timer)
{
	g_hBillVersusTimer = INVALID_HANDLE;
	
	new bool:billexists;
	
	for (new client=1;client<=MaxClients;client++)
	{
		if (!IsClientInGame(client)) continue;
		
		if (GetClientTeam(client) == TEAM_SURVIVORS)
		{
			if (GET_BILL_NETPROP || GET_BILL_ALT_NETPROP)
			{
				billexists = true;
				SetEntProp(client, Prop_Send, "m_survivorCharacter", g_iVersusNewSurvivor[client]);
			}
		}
	}
	
	if (billexists)
	{
		if (g_hBillTimer == INVALID_HANDLE)
			g_hBillTimer = CreateTimer(ZOMBIE_TIME, Timer_RestoreBill, TIMER_FLAG_NO_MAPCHANGE);
	}
	
	// Restore the z_common_limit cvar.
	
	g_bBillIsChanging = true;
	SetConVarInt(FindConVar("z_common_limit"), g_iCommonLimit);
	g_bBillIsChanging = false;
}

public Action:Timer_RestoreBill(Handle:Timer)
{
	g_hBillTimer = INVALID_HANDLE;
	
	new billexists;
	
	// Loop through all players and check to see if there is a Bill player with either with the Alternative value for the m_survivorCharacter netprop, or if its a L4D2 survivor changeout in Versus. 
	// If so, set z_common_limit to 0 and set the player to Bill.
	
	for (new client=1;client<=MaxClients;client++)
	{
		if (!IsClientInGame(client)) continue;
		
		if (GetClientTeam(client) == TEAM_SURVIVORS)
		{
			if (GET_BILL_ALT_NETPROP || g_iVersusOldSurvivor[client] == 4)
			{
				billexists = true;
				g_bBillIsChanging = true;
				SetConVarInt(FindConVar("z_common_limit"), 0);
				SET_CHARACTER_BILL
			}
		}
	}
	
	if (billexists)
	{
		if (g_iGameMode != GAMEMODE_VERSUS)
		{
			if (g_hBillTimer == INVALID_HANDLE)
				g_hBillTimer = CreateTimer(BILL_TIME, Timer_SpawnZombies, TIMER_FLAG_NO_MAPCHANGE);
		}
		else
		{
			if (g_hBillVersusTimer == INVALID_HANDLE)
				g_hBillVersusTimer = CreateTimer(10.0, Timer_ChangeBillVersus, TIMER_FLAG_NO_MAPCHANGE);
			if (g_hBillTimer == INVALID_HANDLE)
				g_hBillTimer = CreateTimer(BILL_TIME, Timer_SpawnZombies, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}







//////////////////////////////////////////////
//INFECTED FUNCTIONS
//////////////////////////////////////////////





stock SetUpInfected(param1, Infected)
{
	new survivorhealth = GetEntProp(param1, Prop_Send, "m_iHealth");
	
	SetEntProp(param1, Prop_Send, "m_iTeamNum" , 3);
	
	// Set the player as a ghost so that it can take the spawned infected
	SetGhostStatus(param1, true);
	
	// Set the player as the one to spawn so no spawn restrictions apply to that client
	g_b_aOneToSpawn[param1] = true;
	
	Spawn_Infected(Infected);
	
	// The client is no longer the one to spawn as the client has already spawned
	g_b_aOneToSpawn[param1] = false;
	
	// Set the client back to life
	SetGhostStatus(param1, false);
	
	// Change the model for the boomer or boomette
	if (Infected == BOOMER)
		SetEntityModel(param1, "models/infected/boomer.mdl");
	else if (Infected == BOOMETTE)
		SetEntityModel(param1, "models/infected/boomette.mdl");
	
	// Print to the player they changed into
	g_iClientChangeLimit[param1]--;
	if (g_bAnnounce)
	{
		if (g_iClientChangeLimit[param1] <= CSM_CHANGE_MESSAGE) 
		{
			if (g_iClientChangeLimit[param1] == 0)
				PrintToChat(param1, "\x03[BG]\x01 现在你的角色是 \x04%s\x01! 下次重生前你不能更改.", g_sCharacters[Infected]);
			else if (g_iClientChangeLimit[param1] == 1)
				PrintToChat(param1, "\x03[BG]\x01 现在你的角色是 \x04%s\x01! 你只能改变 \x051\x01 次.", g_sCharacters[Infected]);
			else
			PrintToChat(param1, "\x03[BG]\x01 现在你的角色是 \x04%s\x01! 你还能改变 \x05%i\x01 次.", g_sCharacters[Infected], g_iClientChangeLimit[param1]);
		} 
		else 
		{
			PrintToChat(param1, "\x03[BG]\x01 现在你的角色是 \x04%s\x01!", g_sCharacters[Infected]);
		}
	}
	
	// Set the infected as a survivor
	SetEntProp(param1, Prop_Send, "m_iTeamNum" , 2);
	SetEntProp(param1, Prop_Send, "m_survivorCharacter", 10);
	SetEntProp(param1, Prop_Send, "m_iHealth", survivorhealth);
	SetEntProp(param1, Prop_Send, "m_iMaxHealth", 100);
}

stock SetUpInfectedModel(param1, Infected)
{
	SetClientClassModel(param1, Infected);
	g_iClientChangeLimit[param1]--;
	if (g_bAnnounce)
	{
		if (g_iClientChangeLimit[param1] <= CSM_CHANGE_MESSAGE)
		{
			if (g_iClientChangeLimit[param1] == 0)
				PrintToChat(param1, "\x03[BG]\x01 现在你的角色是 \x04%s\x01! 下次重生前你不能更改.", g_sCharacters[Infected+8]);
			else if (g_iClientChangeLimit[param1] == 1)
				PrintToChat(param1, "\x03[BG]\x01 现在你的角色是 \x04%s\x01! 你只能改变 \x051\x01 次.", g_sCharacters[Infected+8]);
			else
			PrintToChat(param1, "\x03[BG]\x01 现在你的外观是 \x04%s\x01! 你还能改变 \x05%i\x01 次.", g_sCharacters[Infected+8], g_iClientChangeLimit[param1]);
		}
		else
		{
			PrintToChat(param1, "\x03[BG]\x01 现在你的外观是 \x04%s\x01!", g_sCharacters[Infected+8]);
		}
	}
}

stock SetUpCommonModel(param1, Infected)
{
	SetClientClassModel(param1, Infected);
	g_iClientChangeLimit[param1]--;
	if (g_bAnnounce)
	{
		if (g_iClientChangeLimit[param1] <= CSM_CHANGE_MESSAGE)
		{
			if (g_iClientChangeLimit[param1] == 0)
				PrintToChat(param1, "\x03[BG]\x01 现在你的角色是 \x04%s\x01! 下次重生前你不能更改.", g_sCharacters[Infected]);
			else if (g_iClientChangeLimit[param1] == 1)
				PrintToChat(param1, "\x03[BG]\x01 现在你的角色是 \x04%s\x01! 你只能改变 \x051\x01 次.", g_sCharacters[Infected]);
			else
			PrintToChat(param1, "\x03[BG]\x01 现在你的外观是 \x04%s\x01! 你还能改变 \x05%i\x01 次.", g_sCharacters[Infected], g_iClientChangeLimit[param1]);
		}
		else
		{
			PrintToChat(param1, "\x03[BG]\x01 现在你的外观是 \x04%s\x01!", g_sCharacters[Infected]);
		}
	}
}

stock Spawn_Infected(Infected)
{
	// Before spawning the bot, we determine if an real infected player is dead, since the new infected bot will be controlled by this player
	new bool:resetGhost[MAXPLAYERS+1];
	new bool:resetLife[MAXPLAYERS+1];
	
	for (new client=1;client<=MaxClients;client++)
	{
		if (IsClientInGame(client) && !IsFakeClient(client)) // player is connected and is not fake and it's in game ...
		{
			// If player is on infected's team and is dead ..
			if (GetClientTeam(client) == TEAM_INFECTED)
			{
				if (g_b_aOneToSpawn[client] == false)
				{
					// If player is a ghost ....
					if (IsPlayerGhost(client))
					{
						resetGhost[client] = true;
						SetGhostStatus(client, false);
						#if DEBUG
						LogMessage("Player is a ghost, taking preventive measures for spawning an infected bot");
						#endif
					}
					else if (!PlayerIsAlive(client))
					{
						resetLife[client] = true;
						SetLifeState(client, false);
						#if DEBUG
						LogMessage("Found a dead player, spawn time has not reached zero, delaying player to Spawn an infected bot");
						#endif
					}
				}
			}
		}
	}
	
	new anyclient = GetAnyValidClient();
	
	// We spawn the bot ...
	switch (Infected)
	{
		case SMOKER:
		{
			#if DEBUG
			LogMessage("Spawning Smoker");
			#endif
			CheatCommand(anyclient, "z_spawn", "smoker");
			
		}
		case BOOMER:
		{	
			#if DEBUG
			LogMessage("Spawning Boomer");
			#endif
			CheatCommand(anyclient, "z_spawn", "boomer");
		}
		case BOOMETTE:
		{
			#if DEBUG
			LogMessage("Spawning Boomette");
			#endif
			CheatCommand(anyclient, "z_spawn", "boomer");
		}
		case HUNTER:
		{
			#if DEBUG
			LogMessage("Spawning Hunter");
			#endif
			CheatCommand(anyclient, "z_spawn", "hunter");
			
		}
		case CHARGER:
		{
			#if DEBUG
			LogMessage("Spawning Charger");
			#endif
			CheatCommand(anyclient, "z_spawn", "charger");
		}
		case JOCKEY:
		{
			#if DEBUG
			LogMessage("Spawning Jockey");
			#endif
			CheatCommand(anyclient, "z_spawn", "jockey");
		}
		case SPITTER:
		{
			#if DEBUG
			LogMessage("Spawning Spitter");
			#endif
			CheatCommand(anyclient, "z_spawn", "spitter");
		}
		case TANK:
		{
			#if DEBUG
			LogMessage("Spawning Tank");
			#endif
			CheatCommand(anyclient, "z_spawn", "tank");
		}
	}
	
	// We restore the player's status
	for (new i=1;i<=MaxClients;i++)
	{
		if (resetGhost[i] == true)
			SetGhostStatus(i, true);
		if (resetLife[i] == true)
			SetLifeState(i, true);
	}
	
}

bool:IsPlayerGhost (client)
{
	if (GetEntProp(client, Prop_Send, "m_isGhost"))
		return true;
	return false;
}

// This bool is better at detecting if the player is alive than the native sourcemod one.

bool:PlayerIsAlive (client)
{
	if (!GetEntProp(client,Prop_Send, "m_lifeState"))
		return true;
	return false;
}

stock GetAnyValidClient() 
{ 
	for (new target = 1; target <= MaxClients; target++) 
	{ 
		if (IsClientInGame(target)) return target; 
	} 
	return -1; 
}

stock SetGhostStatus (client, bool:ghost)
{
	if (ghost)
		SetEntProp(client, Prop_Send, "m_isGhost", 1);
	else
	SetEntProp(client, Prop_Send, "m_isGhost", 0);
}

stock SetLifeState (client, bool:ready)
{
	if (ready)
		SetEntProp(client, Prop_Send, "m_lifeState", 1);
	else
	SetEntProp(client, Prop_Send, "m_lifeState", 0);
}

public Action:kickbot(Handle:timer, any:value)
{
	KickThis(value);
}

stock KickThis (client)
{
	
	if (!IsClientInKickQueue(client))
	{
		if (IsFakeClient(client)) KickClient(client,"Kick");
	}
}

stock TrueNumberOfSurvivors ()
{
	new TotalSurvivors;
	for (new client=1;client<=MaxClients;client++)
	{
		if (IsClientInGame(client))
			if (GetClientTeam(client) == TEAM_SURVIVORS)
				TotalSurvivors++;
		}
	return TotalSurvivors;
}

stock NumberOfSurvivorsExcludeDead ()
{
	new TotalSurvivors;
	for (new client=1;client<=MaxClients;client++)
	{
		if (IsClientInGame(client))
		{
			if (GetClientTeam(client) == TEAM_SURVIVORS)
			{
				if (!GetEntProp(client,Prop_Send, "m_lifeState"))
				{
					TotalSurvivors++;
				}
			}
		}
	}
	return TotalSurvivors;
}

stock GameModeCheck()
{
	#if DEBUG
	LogMessage("Checking Gamemode");
	#endif
	// We determine what the gamemode is
	decl String:GameName[32];
	GetConVarString(g_hGameMode, GameName, sizeof(GameName));
	if (StrEqual(GameName, "survival", false))
		g_iGameMode = GAMEMODE_SURVIVAL;
	else if (StrEqual(GameName, "versus", false) || StrEqual(GameName, "teamversus", false) || StrEqual(GameName, "scavenge", false) || StrEqual(GameName, "teamscavenge", false) || StrEqual(GameName, "mutation12", false) || StrEqual(GameName, "mutation13", false) || StrEqual(GameName, "mutation15", false) || StrEqual(GameName, "mutation11", false) || StrEqual(GameName, "mutation19", false))
		g_iGameMode = GAMEMODE_VERSUS;
	else if (StrEqual(GameName, "coop", false) || StrEqual(GameName, "realism", false) || StrEqual(GameName, "mutation3", false) || StrEqual(GameName, "mutation9", false) || StrEqual(GameName, "mutation1", false) || StrEqual(GameName, "mutation7", false) || StrEqual(GameName, "mutation10", false) || StrEqual(GameName, "mutation2", false) || StrEqual(GameName, "mutation4", false) || StrEqual(GameName, "mutation5", false) || StrEqual(GameName, "mutation8", false) || StrEqual(GameName, "mutation14", false) || StrEqual(GameName, "mutation16", false))
		g_iGameMode = GAMEMODE_COOP;
	else
	g_iGameMode = GAMEMODE_COOP;
	
}

stock CheatCommand(client, String:command[], String:arguments[] = "")
{
	new userFlags = GetUserFlagBits(client);
	SetUserFlagBits(client, ADMFLAG_ROOT);
	new flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", command, arguments);
	SetCommandFlags(command, flags);
	SetUserFlagBits(client, userFlags);
}

public OnPluginEnd()
{
	if (g_bIsL4D2)
		ResetConVar(FindConVar("precache_all_survivors"), true, true);
	ResetConVar(FindConVar("z_common_limit"), true, true);
}

////////////////

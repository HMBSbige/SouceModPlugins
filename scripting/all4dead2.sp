/*
This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.	If not, see <http://www.gnu.org/licenses/>.
*/

/*
All4Dead - A modification for the game Left4Dead
Copyright 2009 James Richardson
*/

#pragma semicolon 1
#pragma tabsize 2

// Define constants
#define PLUGIN_NAME					"All4Dead2 - 汉化修复 by鄙哥"
#define PLUGIN_TAG					"[BG] "
#define PLUGIN_VERSION			"2.0.0"
#define MENU_DISPLAY_TIME		15

// Include necessary files
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
// Make the admin menu optional
#undef REQUIRE_PLUGIN
#include <adminmenu>

// Create ConVar Handles
new Handle:notify_players = INVALID_HANDLE;
new Handle:automatic_placement	= INVALID_HANDLE;
new Handle:zombies_increment	= INVALID_HANDLE;
new Handle:always_force_bosses = INVALID_HANDLE;
new Handle:refresh_zombie_location = INVALID_HANDLE;

// Menu handlers
new Handle:top_menu;
new Handle:admin_menu;
new TopMenuObject:spawn_special_infected_menu;
new TopMenuObject:spawn_uncommon_infected_menu;
new TopMenuObject:spawn_weapons_menu;
new TopMenuObject:spawn_melee_weapons_menu;
new TopMenuObject:spawn_items_menu;
new TopMenuObject:director_menu;
new TopMenuObject:config_menu;

// Other stuff
new bool:currently_spawning = false;
new String:change_zombie_model_to[128] = "";
new Float:last_zombie_spawn_location[3];
new Handle:refresh_timer = INVALID_HANDLE;
new last_zombie_spawned = 0;

/// Metadata for the mod - used by SourceMod
public Plugin:myinfo = {
	name = PLUGIN_NAME,
	author = "James Richardson (grandwazir)",
	description = "Enables admins to have control over the AI Director",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?p=751952"
};
/// Create plugin Convars, register all our commands and hook any events we need. View the generated all4dead.cfg file for a list of generated Convars.
public OnPluginStart() {
	CreateConVar("a4d_version", PLUGIN_VERSION, "The version of All4Dead plugin.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	always_force_bosses = CreateConVar("a4d_always_force_bosses", "0", "Whether or not bosses will be forced to spawn all the time.", FCVAR_PLUGIN);
	automatic_placement = CreateConVar("a4d_automatic_placement", "1", "Whether or not we ask the director to place things we spawn.", FCVAR_PLUGIN);
	notify_players = CreateConVar("a4d_notify_players", "1", "Whether or not we announce changes in game.", FCVAR_PLUGIN);	
	zombies_increment = CreateConVar("a4d_zombies_to_add", "10", "The amount of zombies to add when an admin requests more zombies.", FCVAR_PLUGIN, true, 10.0, true, 100.0);
	refresh_zombie_location = CreateConVar("a4d_refresh_zombie_location", "20.0", "The amount of time in seconds between location refreshes. Used only for placing uncommon infected automatically.", FCVAR_PLUGIN, true, 5.0, true, 30.0);
	// Register all spawning commands
	RegAdminCmd("a4d_spawn_infected", Command_SpawnInfected, ADMFLAG_CHEATS);
	RegAdminCmd("a4d_spawn_uinfected", Command_SpawnUInfected, ADMFLAG_CHEATS);
	RegAdminCmd("a4d_spawn_item", Command_SpawnItem, ADMFLAG_CHEATS);
	RegAdminCmd("a4d_spawn_weapon", Command_SpawnItem, ADMFLAG_CHEATS);
	// Director commands
	RegAdminCmd("a4d_force_panic", Command_ForcePanic, ADMFLAG_CHEATS);
	RegAdminCmd("a4d_panic_forever", Command_PanicForever, ADMFLAG_CHEATS);	
	RegAdminCmd("a4d_force_tank", Command_ForceTank, ADMFLAG_CHEATS);
	RegAdminCmd("a4d_force_witch", Command_ForceWitch, ADMFLAG_CHEATS);
	RegAdminCmd("a4d_continuous_bosses", Command_AlwaysForceBosses, ADMFLAG_CHEATS);
	RegAdminCmd("a4d_add_zombies", Command_AddZombies, ADMFLAG_CHEATS);	
	// Config settings
	RegAdminCmd("a4d_enable_notifications", Command_EnableNotifications, ADMFLAG_CHEATS);
	RegAdminCmd("a4d_reset_to_defaults", Command_ResetToDefaults, ADMFLAG_CHEATS);
	// RegAdminCmd("a4d_debug_teleport", Command_TeleportToZombieSpawn, ADMFLAG_CHEATS);
	// Hook events
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("tank_spawn", Event_BossSpawn, EventHookMode_PostNoCopy);
	HookEvent("witch_spawn", Event_BossSpawn, EventHookMode_PostNoCopy);
	// Execute configuation file if it exists
	AutoExecConfig(true);
	// Create location refresh timer
	refresh_timer = CreateTimer(GetConVarFloat(refresh_zombie_location), Timer_RefreshLocation, _, TIMER_REPEAT);
	// If the Admin menu has been loaded start adding stuff to it
	if (LibraryExists("adminmenu") && ((top_menu = GetAdminTopMenu()) != INVALID_HANDLE))
		OnAdminMenuReady(top_menu);
}

public OnMapStart() {
	// Precache uncommon infected models
	PrecacheModel("models/infected/common_male_riot.mdl", true);
	PrecacheModel("models/infected/common_male_ceda.mdl", true);
	PrecacheModel("models/infected/common_male_clown.mdl", true);
	PrecacheModel("models/infected/common_male_mud.mdl", true);
	PrecacheModel("models/infected/common_male_roadcrew.mdl", true);
	PrecacheModel("models/infected/common_male_jimmy.mdl", true);
	PrecacheModel("models/infected/common_male_fallen_survivor.mdl", true);
}

public OnPluginEnd() {
	CloseHandle(refresh_timer);
}

/**
 * <summary>
 * 	Fired when a player is spawned and gives that player maximum health. This	
 * 	is to fix an issue where entities created through z_spawn have random amount 
 * 	of health
 * </summary>
 * <remarks>
 * 	This callback will only affect players on the infected team. It also only 
 * 	occurs when the global currently_spawning is true. It automatically resets
 * 	currently_spawning to false once the health has been given.
 * </remarks>
 * <seealso>
 * 	Command_SpawnInfected
 * </seealso>
*/
public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	/* If something spawns and we have just requested something to spawn - assume it is the same thing and make sure it has max health */
	if (GetClientTeam(client) == 3 && currently_spawning) {
		StripAndExecuteClientCommand(client, "give", "health");
		LogAction(0, -1, "[NOTICE] Given full health to client %L that (hopefully) was spawned by A4D.", client);
		// We have added health to the thing we have spawned so turn ourselves off
		currently_spawning = false;	
	}
}
/**
 * <summary>
 * 	Fired when a boss has been spawned (witch or tank) and sets director_force_tank/
 * 	director_force_witch to false if necessary.
 * </summary>
 * <remarks>
 * 	Forcing the director to spawn bosses is the most natural way for them to enter
 * 	the game. However the game does not toggle these ConVars off once a boss has 
 * 	been spawned. This leads to odd behavior such as four tanks on one map. This callback
 * 	ensures that if a4d_continuous_bosses is false we set the relevent director ConVar back
 * 	to false once the boss has been spawned.
 * </remarks>
 * <seealso>
 * 	Command_ForceTank
 * 	Command_ForceWitch
 * 	Command_SpawnBossesContinuously
 * </seealso>
*/
public Action:Event_BossSpawn(Handle:event, const String:name[], bool:dontBroadcast) {
	if (GetConVarBool(always_force_bosses) == false)
		if (StrEqual(name, "tank_spawn") && GetConVarBool(FindConVar("director_force_tank")))
			Do_ForceTank(0, false);
		else if (StrEqual(name, "witch_spawn") && GetConVarBool(FindConVar("director_force_witch")))
			Do_ForceWitch(0, false);
}

/// Register our menus with SourceMod
public OnAdminMenuReady(Handle:menu) {
	// Stop this method being called twice
	if (menu == admin_menu)
		return;
	admin_menu = menu;
	// Add a category to the SourceMod menu called "All4Dead Commands"
	AddToTopMenu(admin_menu, "权限", TopMenuObject_Category, Menu_CategoryHandler, INVALID_TOPMENUOBJECT);
	// Get a handle for the catagory we just added so we can add items to it
	new TopMenuObject:a4d_menu = FindTopMenuCategory(admin_menu, "权限");
	// Don't attempt to add items to the category if for some reason the catagory doesn't exist
	if (a4d_menu == INVALID_TOPMENUOBJECT) 
		return;
	// The order that items are added to menus has no relation to the order that they appear. Items are sorted alphabetically automatically.
	// Assign the menus to global values so we can easily check what a menu is when it is chosen.
	director_menu = AddToTopMenu(admin_menu, "a4d_director_menu", TopMenuObject_Item, Menu_TopItemHandler, a4d_menu, "a4d_director_menu", ADMFLAG_CHEATS);
	config_menu = AddToTopMenu(admin_menu, "a4d_config_menu", TopMenuObject_Item, Menu_TopItemHandler, a4d_menu, "a4d_config_menu", ADMFLAG_CHEATS);
	spawn_special_infected_menu = AddToTopMenu(admin_menu, "a4d_spawn_special_infected_menu", TopMenuObject_Item, Menu_TopItemHandler, a4d_menu, "a4d_spawn_special_infected_menu", ADMFLAG_CHEATS);
	spawn_melee_weapons_menu = AddToTopMenu(admin_menu, "a4d_spawn_melee_weapons_menu", TopMenuObject_Item, Menu_TopItemHandler, a4d_menu, "a4d_spawn_melee_weapons_menu", ADMFLAG_CHEATS);
	spawn_weapons_menu = AddToTopMenu(admin_menu, "a4d_spawn_weapons_menu", TopMenuObject_Item, Menu_TopItemHandler, a4d_menu, "a4d_spawn_weapons_menu", ADMFLAG_CHEATS);
	spawn_items_menu = AddToTopMenu(admin_menu, "a4d_spawn_items_menu", TopMenuObject_Item, Menu_TopItemHandler, a4d_menu, "a4d_spawn_items_menu", ADMFLAG_CHEATS);
	spawn_uncommon_infected_menu = AddToTopMenu(admin_menu, "a4d_spawn_uncommon_infected_menu", TopMenuObject_Item, Menu_TopItemHandler, a4d_menu, "a4d_spawn_uncommon_infected_menu", ADMFLAG_CHEATS);
}

public OnEntityCreated(entity, const String:classname[]) {
	// If the last thing that was spawned as a zombie then store that entity
	// for future use
	if (StrEqual(classname, "infected", false)) {
		last_zombie_spawned = entity;
		if (currently_spawning && !StrEqual(change_zombie_model_to, "")) {
			currently_spawning = false;
			SetEntityModel(entity, change_zombie_model_to);
			change_zombie_model_to = "";
		}
	}	
}

public Action:Timer_RefreshLocation(Handle:timer) {
	if (!IsValidEntity(last_zombie_spawned)) return Plugin_Continue;
	new String:class_name[128];
	GetEdictClassname(last_zombie_spawned, class_name, 128);
	if (!StrEqual(class_name, "infected")) return Plugin_Continue;
	GetEntityAbsOrigin(last_zombie_spawned, last_zombie_spawn_location);
	return Plugin_Continue;
}


public Action:Timer_TeleportZombie(Handle:timer, any:entity) {
	TeleportEntity(entity, last_zombie_spawn_location, NULL_VECTOR, NULL_VECTOR);
	// PrintToChatAll("Zombie being teleported to new location");
}

/// Handles the top level "All4Dead" category and how it is displayed on the core admin menu
public Menu_CategoryHandler(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, client, String:buffer[], maxlength) {
	if (action == TopMenuAction_DisplayTitle)
		Format(buffer, maxlength, "All4Dead 命令:");
	else if (action == TopMenuAction_DisplayOption)
		Format(buffer, maxlength, "All4Dead 命令");
}
/// Handles what happens someone opens the "All4Dead" category from the menu.
public Menu_TopItemHandler(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, client, String:buffer[], maxlength) {
/* When an item is displayed to a player tell the menu to Format the item */
	if (action == TopMenuAction_DisplayOption) {
		if (object_id == director_menu)
			Format(buffer, maxlength, "游戏控制命令");
		else if (object_id == spawn_special_infected_menu)
			Format(buffer, maxlength, "生成特感");
		else if (object_id == spawn_uncommon_infected_menu)
			Format(buffer, maxlength, "生成罕见感染者");
		else if (object_id == spawn_melee_weapons_menu)
			Format(buffer, maxlength, "生成近战");
		else if (object_id == spawn_weapons_menu)
			Format(buffer, maxlength, "生成武器");
		else if (object_id == spawn_items_menu)
			Format(buffer, maxlength, "生成物品");
		else if (object_id == config_menu)
			Format(buffer, maxlength, "配置选项");
	} else if (action == TopMenuAction_SelectOption) {
		if (object_id == director_menu)
			Menu_CreateDirectorMenu(client, false);
		else if (object_id == spawn_special_infected_menu)
			Menu_CreateSpecialInfectedMenu(client, false);
		else if (object_id == spawn_uncommon_infected_menu)
			Menu_CreateUInfectedMenu(client, false);
		else if (object_id == spawn_melee_weapons_menu)
			Menu_CreateMeleeWeaponMenu(client, false);
		else if (object_id == spawn_weapons_menu)
			Menu_CreateWeaponMenu(client, false);
		else if (object_id == spawn_items_menu)
			Menu_CreateItemMenu(client, false);
		else if (object_id == config_menu)
			Menu_CreateConfigMenu(client, false);
	}
}

// Infected spawning functions

/// Creates the infected spawning menu when it is selected from the top menu and displays it to the client.
public Action:Menu_CreateSpecialInfectedMenu(client, args) {
	new Handle:menu = CreateMenu(Menu_SpawnSInfectedHandler);
	SetMenuTitle(menu, "生成特感");
	SetMenuExitBackButton(menu, true);
	SetMenuExitButton(menu, true);
	if (GetConVarBool(automatic_placement))
		AddMenuItem(menu, "ap", "关闭自动放置");
	else 
		AddMenuItem(menu, "ap", "开启自动放置");
	AddMenuItem(menu, "st", "Tank");
	AddMenuItem(menu, "sw", "witch");
	AddMenuItem(menu, "sb", "boomer");
	AddMenuItem(menu, "sh", "hunter");
	AddMenuItem(menu, "ss", "smoker");
	AddMenuItem(menu, "sp", "spitter");
	AddMenuItem(menu, "sj", "jockey");
	AddMenuItem(menu, "sc", "charger");
	AddMenuItem(menu, "sb", "mob");
	DisplayMenu(menu, client, MENU_DISPLAY_TIME);
	return Plugin_Handled;
}
/// Handles callbacks from a client using the spawning menu.
public Menu_SpawnSInfectedHandler(Handle:menu, MenuAction:action, cindex, itempos) {
	// When a player selects an item do this.		
	if (action == MenuAction_Select) {
		switch (itempos) {
			case 0:
				if (GetConVarBool(automatic_placement)) 
					Do_EnableAutoPlacement(cindex, false); 
				else
					Do_EnableAutoPlacement(cindex, true);
			case 1:
				Do_SpawnInfected(cindex, "tank", false);
			case 2:
				Do_SpawnInfected(cindex, "witch", false);
			case 3:
				Do_SpawnInfected(cindex, "boomer", false);
			case 4:
				Do_SpawnInfected(cindex, "hunter", false);
			case 5:
				Do_SpawnInfected(cindex, "smoker", false);
			case 6:
				Do_SpawnInfected(cindex, "spitter", false);
			case 7:
				Do_SpawnInfected(cindex, "jockey", false);
			case 8:
				Do_SpawnInfected(cindex, "charger", false);
			case 9:
				Do_SpawnInfected(cindex, "mob", false);
		}
		// If none of the above matches show the menu again
		Menu_CreateSpecialInfectedMenu(cindex, false);
	// If someone closes the menu - close the menu
	} else if (action == MenuAction_End)
		CloseHandle(menu);
	// If someone presses 'back' (8), return to main All4Dead menu */
	else if (action == MenuAction_Cancel)
		if (itempos == MenuCancel_ExitBack && admin_menu != INVALID_HANDLE)
			DisplayTopMenu(admin_menu, cindex, TopMenuPosition_LastCategory);
}

/// Creates the infected spawning menu when it is selected from the top menu and displays it to the client.
public Action:Menu_CreateUInfectedMenu(client, args) {
	new Handle:menu = CreateMenu(Menu_SpawnUInfectedHandler);
	SetMenuTitle(menu, "生成罕见感染者");
	SetMenuExitBackButton(menu, true);
	SetMenuExitButton(menu, true);
	if (GetConVarBool(automatic_placement))
		AddMenuItem(menu, "ap", "关闭自动放置");
	else 
		AddMenuItem(menu, "ap", "开启自动放置");
	AddMenuItem(menu, "s1", "警察僵尸");
	AddMenuItem(menu, "s2", "CEDA僵尸");
	AddMenuItem(menu, "s3", "小丑僵尸");
	AddMenuItem(menu, "s4", "泥人僵尸");
	AddMenuItem(menu, "s5", "工人僵尸");
	AddMenuItem(menu, "s6", "吉姆·吉布斯僵尸");
	AddMenuItem(menu, "s7", "坠落幸存者僵尸");
	DisplayMenu(menu, client, MENU_DISPLAY_TIME);
	return Plugin_Handled;
}
/// Handles callbacks from a client using the spawning menu.
public Menu_SpawnUInfectedHandler(Handle:menu, MenuAction:action, cindex, itempos) {
	// When a player selects an item do this.		
	if (action == MenuAction_Select) {
		switch (itempos) {
			case 0:
				if (GetConVarBool(automatic_placement)) 
					Do_EnableAutoPlacement(cindex, false); 
				else
					Do_EnableAutoPlacement(cindex, true);
			case 1:
				Do_SpawnUncommonInfected(cindex, 0);
			case 2:
				Do_SpawnUncommonInfected(cindex, 1);
			case 3:
				Do_SpawnUncommonInfected(cindex, 2);
			case 4:
				Do_SpawnUncommonInfected(cindex, 3);
			case 5:
				Do_SpawnUncommonInfected(cindex, 4);
			case 6:
				Do_SpawnUncommonInfected(cindex, 5);
			case 7:
				Do_SpawnUncommonInfected(cindex, 6);
		}
		// If none of the above matches show the menu again
		Menu_CreateUInfectedMenu(cindex, false);
	// If someone closes the menu - close the menu
	} else if (action == MenuAction_End)
		CloseHandle(menu);
	// If someone presses 'back' (8), return to main All4Dead menu */
	else if (action == MenuAction_Cancel)
		if (itempos == MenuCancel_ExitBack && admin_menu != INVALID_HANDLE)
			DisplayTopMenu(admin_menu, cindex, TopMenuPosition_LastCategory);
}

/// Sourcemod Action for the SpawnInfected command.
public Action:Command_SpawnInfected(client, args) { 
	if (args < 1) {
		ReplyToCommand(client, "Usage: a4d_spawn_infected <infected_type> (does not work for uncommon infected, use a4d_spawn_uinfected instead)"); 
	} else {
		new String:type[16];
		GetCmdArg(1, type, sizeof(type));
		Do_SpawnInfected(client, type, false);
	}
	return Plugin_Handled;
}

/// Sourcemod Action for the SpawnUncommonInfected command.
public Action:Command_SpawnUInfected(client, args) { 
	if (args < 1) {
		ReplyToCommand(client, "Usage: a4d_spawn_uinfected <riot|ceda|clown|mud|roadcrew|jimmy>"); 
	} else {
		new String:type[32];
		GetCmdArg(1, type, sizeof(type));
		new number;
		if (StrEqual(type, "riot", false)) number = 0;
		else if (StrEqual(type, "ceda", false)) number = 1;
		else if (StrEqual(type, "clown", false)) number = 2;
		else if (StrEqual(type, "mud", false)) number = 3;
		else if (StrEqual(type, "roadcrew", false)) number = 4;
		else if (StrEqual(type, "jimmy", false)) number = 5;
		else if (StrEqual(type, "fallen", false)) number = 6;
		Do_SpawnUncommonInfected(client, number);
	}
	return Plugin_Handled;
}

/**
 * <summary>
 * 	Spawns one of the specified infected using the z_spawn command. 
 * </summary>
 * <param name="type">
 * 	The type of infected to spawn
 * </param>
 * <remarks>
 * 	The infected will spawn either at the crosshair of the spawning player
 * 	or at a location automatically decided by the AI Director if auto_placement
 * 	is true. Automatically falls back to a fake client if the client requesting
 * 	the action is the console.
 * </remarks>
*/
Do_SpawnInfected(client, const String:type[], bool:spawning_uncommon) {
	new String:arguments[16];
	new String:feedback[64];
	Format(feedback, sizeof(feedback), "%s已经生成", type);
	if (GetConVarBool(automatic_placement) == true && !spawning_uncommon)
		Format(arguments, sizeof(arguments), "%s %s", type, "auto");
	else
		Format(arguments, sizeof(arguments), "%s", type);
	// If we are spawning an uncommon
	if (spawning_uncommon)
		currently_spawning = true;
	// If we are spawning from the console make sure we force auto placement on	
	if (client == 0) {
		Format(arguments, sizeof(arguments), "%s %s", type, "auto");
		StripAndExecuteClientCommand(Misc_GetAnyClient(), "z_spawn", arguments);
	} else if (spawning_uncommon && GetConVarBool(automatic_placement) == true) {
		currently_spawning = false;
		new zombie = CreateEntityByName("infected");
		SetEntityModel(zombie, change_zombie_model_to);
		new ticktime = RoundToNearest( FloatDiv( GetGameTime() , GetTickInterval() ) ) + 5;
		SetEntProp(zombie, Prop_Data, "m_nNextThinkTick", ticktime);
		DispatchSpawn(zombie);
		ActivateEntity(zombie);
		TeleportEntity(zombie, last_zombie_spawn_location, NULL_VECTOR, NULL_VECTOR);
		NotifyPlayers(client, feedback);
		LogAction(client, -1, "[NOTICE]: (%L) has spawned a %s", client, type);
		return;
	} else {
		StripAndExecuteClientCommand(client, "z_spawn", arguments);
	}
	NotifyPlayers(client, feedback);
	LogAction(client, -1, "[NOTICE]: (%L) has spawned a %s", client, type);
	// PrintToChatAll("Spawned a %s with automatic placement %b and uncommon %b", type, GetConVarBool(automatic_placement), spawning_uncommon);
}

Do_SpawnUncommonInfected(client, type) {
	new String:model[128];
	switch (type) {
		case 0:
			Format(model, sizeof(model), "models/infected/common_male_riot.mdl");
		case 1:
			Format(model, sizeof(model), "models/infected/common_male_ceda.mdl");
		case 2:
			Format(model, sizeof(model), "models/infected/common_male_clown.mdl");
		case 3:
			Format(model, sizeof(model), "models/infected/common_male_mud.mdl");
		case 4:
			Format(model, sizeof(model), "models/infected/common_male_roadcrew.mdl");
		case 5:
			Format(model, sizeof(model), "models/infected/common_male_jimmy.mdl");
		case 6:
			Format(model, sizeof(model), "models/infected/common_male_fallen_survivor.mdl");
	}
	change_zombie_model_to = model;
	Do_SpawnInfected(client, "zombie", true);
}
/// Sourcemod Action for the Do_EnableAutoPlacement command.
public Action:Command_EnableAutoPlacement(client, args) {
	if (args < 1) {
		ReplyToCommand(client, "Usage: a4d_enable_auto_placement <0|1>");
		return Plugin_Handled;
	}
	new String:value[16];
	GetCmdArg(1, value, sizeof(value));
	if (StrEqual(value, "0"))
		Do_EnableAutoPlacement(client, false);		
	else
		Do_EnableAutoPlacement(client, true);
	return Plugin_Handled;
}
/**
 * <summary>
 * 	Allows (or disallows) the AI Director to place spawned infected automatically.
 * </summary>
 * <remarks>
 * 	If this is enabled the director will place mobs outside the players sight so 
 * 	it will not look like they are magically appearing. This only affects zombies
 * 	spawned through z_spawn.
 * </remarks>
*/
Do_EnableAutoPlacement(client, bool:value) {
	SetConVarBool(automatic_placement, value);
	if (value == true)
		NotifyPlayers(client, "自动放置已启用");
	else
		NotifyPlayers(client, "自动放置已禁用");
	LogAction(client, -1, "(%L) set %s to %i", client, "a4d_automatic_placement", value);	
}

// Item spawning functions

/// Creates the item spawning menu when it is selected from the top menu and displays it to the client */
public Action:Menu_CreateItemMenu(client, args) {
	new Handle:menu = CreateMenu(Menu_SpawnItemsHandler);
	SetMenuTitle(menu, "生成物品");
	SetMenuExitBackButton(menu, true);
	SetMenuExitButton(menu, true);
	AddMenuItem(menu, "sd", "电击器");
	AddMenuItem(menu, "sm", "急救包");
	AddMenuItem(menu, "sp", "止痛药");
	AddMenuItem(menu, "sa", "肾上腺素针");
	AddMenuItem(menu, "sv", "燃烧瓶");
	AddMenuItem(menu, "sb", "土制炸弹");
	AddMenuItem(menu, "sb", "胆汁");
	AddMenuItem(menu, "sg", "煤气罐");
	AddMenuItem(menu, "st", "丙烷罐");
	AddMenuItem(menu, "so", "氧气罐");
	AddMenuItem(menu, "sa", "弹药堆");
	AddMenuItem(menu, "si", "燃烧弹");
	AddMenuItem(menu, "se", "高爆弹");
	AddMenuItem(menu, "lp", "激光瞄准器");
	DisplayMenu(menu, client, MENU_DISPLAY_TIME);
	return Plugin_Handled;
}
/// Handles callbacks from a client using the spawn item menu.
public Menu_SpawnItemsHandler(Handle:menu, MenuAction:action, cindex, itempos) {
	if (action == MenuAction_Select) {
		switch (itempos) {
			case 0: {
				Do_SpawnItem(cindex, "defibrillator");
			} case 1: {
				Do_SpawnItem(cindex, "first_aid_kit");
			} case 2: {
				Do_SpawnItem(cindex, "pain_pills");
			} case 3: {
				Do_SpawnItem(cindex, "adrenaline");
			} case 4: {
				Do_SpawnItem(cindex, "molotov");
			} case 5: {
				Do_SpawnItem(cindex, "pipe_bomb");
			} case 6: {
				Do_SpawnItem(cindex, "vomitjar");
			} case 7: {
				Do_SpawnItem(cindex, "gascan");
			} case 8: {
				Do_SpawnItem(cindex, "propanetank");
			} case 9: {
				Do_SpawnItem(cindex, "oxygentank");
			} case 10: {
				new Float:location[3];
				if (!Misc_TraceClientViewToLocation(cindex, location)) {
					GetClientAbsOrigin(cindex, location);
				}
				Do_CreateEntity(cindex, "weapon_ammo_spawn", "models/props/terror/ammo_stack.mdl", location, false);
			} case 11: {
				Do_SpawnItem(cindex, "weapon_upgradepack_incendiary");
			} case 12: {
				Do_SpawnItem(cindex, "weapon_upgradepack_explosive");
			} case 13: {
				new Float:location[3];
				if (!Misc_TraceClientViewToLocation(cindex, location)) {
					GetClientAbsOrigin(cindex, location);
				}
				Do_CreateEntity(cindex, "upgrade_laser_sight", "PROVIDED", location, false);
			}
		}
		Menu_CreateItemMenu(cindex, false);
	} else if (action == MenuAction_End) {
		CloseHandle(menu);
	} else if (action == MenuAction_Cancel) {
		if (itempos == MenuCancel_ExitBack && admin_menu != INVALID_HANDLE)
			DisplayTopMenu(admin_menu, cindex, TopMenuPosition_LastCategory);
	}
}
/// Sourcemod Action for the Do_SpawnItem command.
public Action:Command_SpawnItem(client, args) { 
	if (args < 1) {
		ReplyToCommand(client, "Usage: a4d_spawn_item <item_type>");
	} else {
		new String:type[16];
		GetCmdArg(1, type, sizeof(type));
		Do_SpawnItem(client, type);
	}
	return Plugin_Handled;
}

/**
 * <summary>
 * 	Spawns one of the specified type of item using the give command. 
 * </summary>
 * <param name="type">
 * 	The type of item to spawn
 * </param>
 * <remarks>
 * 	The infected will spawn either at the crosshair of the spawning player
 * 	or at a location automatically decided by the AI Director if auto_placement
 * 	is true. Slightly misleadingly named this function is used for both items and weapons.
 * </remarks>
*/
Do_SpawnItem(client, const String:type[]) {
	new String:feedback[64];
	Format(feedback, sizeof(feedback), "%s已经生成", type);
	if (client == 0) {
		ReplyToCommand(client, "Can not use this command from the console."); 
	} else {
		StripAndExecuteClientCommand(client, "give", type);
		NotifyPlayers(client, feedback);
		LogAction(client, -1, "[NOTICE]: (%L) has spawned a %s", client, type);
	}
}

Do_CreateEntity(client, const String:name[], const String:model[], Float:location[3], const bool:zombie) {
	new entity = CreateEntityByName(name);
	if (StrEqual(model, "PROVIDED") == false)
		SetEntityModel(entity, model);
	DispatchSpawn(entity);
	if (zombie) {
		new ticktime = RoundToNearest( FloatDiv( GetGameTime() , GetTickInterval() ) ) + 5;
		SetEntProp(zombie, Prop_Data, "m_nNextThinkTick", ticktime);
		location[2] -= 25.0; // reduce the 'drop' effect
	}
	// Starts animation on whatever we spawned - necessary for mobs
	ActivateEntity(entity);
	// Teleport the entity to the client's crosshair
	TeleportEntity(entity, location, NULL_VECTOR, NULL_VECTOR);
	LogAction(client, -1, "[NOTICE]: (%L) has created a %s (%s)", client, name, model);
}

// Weapon Spawning functions

/// Creates the weapon spawning menu when it is selected from the top menu and displays it to the client.
public Action:Menu_CreateWeaponMenu(client, args) {
	new Handle:menu = CreateMenu(Menu_SpawnWeaponHandler);
	SetMenuTitle(menu, "Spawn Weapons");
	SetMenuExitBackButton(menu, true);
	SetMenuExitButton(menu, true);
	AddMenuItem(menu, "sp", "手枪");
	AddMenuItem(menu, "sg", "马格南");
	AddMenuItem(menu, "ss", "木喷M870");
	AddMenuItem(menu, "sa", "M1014");
	AddMenuItem(menu, "sm", "SMG");
	AddMenuItem(menu, "s3", "消音SMG");
	AddMenuItem(menu, "sr", "M16A2");
	AddMenuItem(menu, "s1", "AK47");
	AddMenuItem(menu, "s2", "SCAR-Light");
	AddMenuItem(menu, "sh", "猎枪");
	AddMenuItem(menu, "s4", "G3/SG1");
	AddMenuItem(menu, "s5", "榴弹发射器");
	DisplayMenu(menu, client, MENU_DISPLAY_TIME);
	return Plugin_Handled;
}
/// Handles callbacks from a client using the spawn weapon menu.
public Menu_SpawnWeaponHandler(Handle:menu, MenuAction:action, cindex, itempos) {
	if (action == MenuAction_Select) {
		switch (itempos) {
			case 0: {
				Do_SpawnItem(cindex, "pistol");
			} case 1: {
				Do_SpawnItem(cindex, "pistol_magnum");
			} case 2: {
				Do_SpawnItem(cindex, "pumpshotgun");
			} case 3: {
				Do_SpawnItem(cindex, "autoshotgun");
			} case 4: {
				Do_SpawnItem(cindex, "smg");
			} case 5: {
				Do_SpawnItem(cindex, "smg_silenced");
			} case 6: {
				Do_SpawnItem(cindex, "rifle");
			} case 7: {
				Do_SpawnItem(cindex, "rifle_ak47");
			} case 8: {
				Do_SpawnItem(cindex, "rifle_desert");
			} case 9: {
				Do_SpawnItem(cindex, "hunting_rifle");
			} case 10: {
				Do_SpawnItem(cindex, "sniper_military");
			} case 11: {
				Do_SpawnItem(cindex, "grenade_launcher");
			}
		}
		Menu_CreateWeaponMenu(cindex, false);
	} else if (action == MenuAction_End)
		CloseHandle(menu);
	/* If someone presses 'back' (8), return to main All4Dead menu */
	else if (action == MenuAction_Cancel)
		if (itempos == MenuCancel_ExitBack && admin_menu != INVALID_HANDLE)
			DisplayTopMenu(admin_menu, cindex, TopMenuPosition_LastCategory);
}

/// Creates the melee weapon spawning menu when it is selected from the top menu and displays it to the client.
public Action:Menu_CreateMeleeWeaponMenu(client, args) {
	new Handle:menu = CreateMenu(Menu_SpawnMeleeWeaponHandler);
	SetMenuTitle(menu, "生成近战");
	SetMenuExitBackButton(menu, true);
	SetMenuExitButton(menu, true);
	AddMenuItem(menu, "ma", "棒球棍");
	AddMenuItem(menu, "mb", "电锯");
	AddMenuItem(menu, "mc", "板球拍");
	AddMenuItem(menu, "md", "物理学圣剑");
	AddMenuItem(menu, "me", "电吉他");
	AddMenuItem(menu, "mf", "消防斧");
	AddMenuItem(menu, "mg", "平底锅");
	AddMenuItem(menu, "mh", "武士刀");
	AddMenuItem(menu, "mi", "砍刀");
	AddMenuItem(menu, "mj", "警棍");
	DisplayMenu(menu, client, MENU_DISPLAY_TIME);
	return Plugin_Handled;
}
/// Handles callbacks from a client using the spawn weapon menu.
public Menu_SpawnMeleeWeaponHandler(Handle:menu, MenuAction:action, cindex, itempos) {
	if (action == MenuAction_Select) {
		switch (itempos) {
			case 0: {
				Do_SpawnItem(cindex, "baseball_bat");
			} case 1: {
				Do_SpawnItem(cindex, "chainsaw");
			} case 2: {
				Do_SpawnItem(cindex, "cricket_bat");
			} case 3: {
				Do_SpawnItem(cindex, "crowbar");
			} case 4: {
				Do_SpawnItem(cindex, "electric_guitar");
			} case 5: {
				Do_SpawnItem(cindex, "fireaxe");
			} case 6: {
				Do_SpawnItem(cindex, "frying_pan");
			} case 7: {
				Do_SpawnItem(cindex, "katana");
			} case 8: {
				Do_SpawnItem(cindex, "machete");
			} case 9: {
				Do_SpawnItem(cindex, "tonfa");
			} 
		}
		Menu_CreateMeleeWeaponMenu(cindex, false);
	} else if (action == MenuAction_End)
		CloseHandle(menu);
	/* If someone presses 'back' (8), return to main All4Dead menu */
	else if (action == MenuAction_Cancel)
		if (itempos == MenuCancel_ExitBack && admin_menu != INVALID_HANDLE)
			DisplayTopMenu(admin_menu, cindex, TopMenuPosition_LastCategory);
}

// Additional director commands

/// Creates the director commands menu when it is selected from the top menu and displays it to the client.
public Action:Menu_CreateDirectorMenu(client, args) {
	new Handle:menu = CreateMenu(Menu_DirectorMenuHandler);
	SetMenuTitle(menu, "游戏控制命令");
	SetMenuExitBackButton(menu, true);
	SetMenuExitButton(menu, true);
	AddMenuItem(menu, "fp", "强制开始一波尸潮");
	if (GetConVarBool(FindConVar("director_panic_forever"))) { AddMenuItem(menu, "pf", "结束无尽尸潮"); } else { AddMenuItem(menu, "pf", "强制开启无尽尸潮"); }
	if (GetConVarBool(FindConVar("director_force_tank"))) { AddMenuItem(menu, "ft", "由地图控制这局的Tank生成"); } else { AddMenuItem(menu, "ft", "强制在这局生成Tank"); }
	if (GetConVarBool(FindConVar("director_force_witch"))) { AddMenuItem(menu, "fw", "由地图控制这局的Witch生成"); } else { AddMenuItem(menu, "fw", "强制在这局生成Witch"); }
	if (GetConVarBool(always_force_bosses)) { AddMenuItem(menu, "fd", "停止连续生成BOSS"); } else { AddMenuItem(menu, "fw", "强制连续生成BOSS"); }
	AddMenuItem(menu, "mz", "在生成点增加更多僵尸");	
	DisplayMenu(menu, client, MENU_DISPLAY_TIME);
	return Plugin_Handled;
}
/// Handles callbacks from a client using the director commands menu.
public Menu_DirectorMenuHandler(Handle:menu, MenuAction:action, cindex, itempos) {
	if (action == MenuAction_Select) {
		switch (itempos) {
			case 0: {
				Do_ForcePanic(cindex);
			} case 1: {
				if (GetConVarBool(FindConVar("director_panic_forever"))) 
					Do_PanicForever(cindex, false); 
				else
					Do_PanicForever(cindex, true);
			} case 2: {
				if (GetConVarBool(FindConVar("director_force_tank")))
					Do_ForceTank(cindex, false); 
				else
					Do_ForceTank(cindex, true);
			} case 3: {
				if (GetConVarBool(FindConVar("director_force_witch"))) 
					Do_ForceWitch(cindex, false);
				else
					Do_ForceWitch(cindex, true);
			}  case 4: {
				if (GetConVarBool(always_force_bosses))
					Do_AlwaysForceBosses(cindex, false); 
				else
					Do_AlwaysForceBosses(cindex, true);
			} case 5: {
				Do_AddZombies(cindex, GetConVarInt(zombies_increment));
			} 
		}
		Menu_CreateDirectorMenu(cindex, false);
	} else if (action == MenuAction_End) {
		CloseHandle(menu);
	} else if (action == MenuAction_Cancel) {
		if (itempos == MenuCancel_ExitBack && admin_menu != INVALID_HANDLE)
			DisplayTopMenu(admin_menu, cindex, TopMenuPosition_LastCategory);
	}
}

/// Sourcemod Action for the AlwaysForceBosses command.
public Action:Command_AlwaysForceBosses(client, args) {
	if (args < 1) { 
		ReplyToCommand(client, "Usage: a4d_always_force_bosses <0|1>"); 
		return Plugin_Handled;
	}
	new String:value[2];
	GetCmdArg(1, value, sizeof(value));
	if (StrEqual(value, "0"))
		Do_AlwaysForceBosses(client, false);		
	else
		Do_AlwaysForceBosses(client, true);
	return Plugin_Handled;
}
/**
 * <summary>
 * 	Do not revert director_force_tank and director_force_witch when a boss spawns.
 * </summary>
 * <remarks>
 * 	This has the effect of continously spawning bosses when either force_tank
 * 	or force_witch is enabled.
 * </remarks>
*/
Do_AlwaysForceBosses(client, bool:value) {
	SetConVarBool(always_force_bosses, value);
	if (value == true)
		NotifyPlayers(client, "现在BOSS将连续生成");
	else
		NotifyPlayers(client, "现在BOSS将不再连续生成");
}

/// Sourcemod Action for the Do_ForcePanic command.
public Action:Command_ForcePanic(client, args) { 
	Do_ForcePanic(client);
	return Plugin_Handled;
}
/**
 * <summary>
 * 	This command forces the AI director to start a panic event
 * </summary>
 * <remarks>
 * 	A panic event is the same as a cresendo event, like pushing a button which calls
 * 	the lift in No Mercy. The director will not start more than one panic event at once.
 * </remarks>
*/
Do_ForcePanic(client) {
	if (client == 0)
		StripAndExecuteClientCommand(Misc_GetAnyClient(), "director_force_panic_event", "");
	else
		StripAndExecuteClientCommand(client, "director_force_panic_event", "");
	NotifyPlayers(client, "僵尸来了!");	
	LogAction(client, -1, "[NOTICE]: (%L) executed %s", client, "a4d_force_panic");
}
/// Sourcemod Action for the Do_PanicForever command.
public Action:Command_PanicForever(client, args) {
	if (args < 1) { 
		ReplyToCommand(client, "Usage: a4d_panic_forever <0|1>"); 
		return Plugin_Handled;
	}
	new String:value[2];
	GetCmdArg(1, value, sizeof(value));
	if (StrEqual(value, "0"))
		Do_PanicForever(client, false);
	else
		Do_PanicForever(client, true);
	return Plugin_Handled;
}
/**
 * <summary>
 * 	This command forces the AI director to start a panic event endlessly, 
 * 	one after each other.
 * </summary>
 * <remarks>
 * 	This does not trigger a panic event. If you are intending for endless panic
 * 	events to start straight away use this and then Do_ForcePanic. 
 * </remarks>
 * <seealso>
 * 	Do_ForcePanic
 * </seealso>
*/
Do_PanicForever(client, bool:value) {
	StripAndChangeServerConVarBool(client, "director_panic_forever", value);
	if (value == true)
		NotifyPlayers(client, "无尽尸潮已经开启");
	else
		NotifyPlayers(client, "无尽尸潮已经结束");
}
/// Sourcemod Action for the Do_ForceTank command.
public Action:Command_ForceTank(client, args) {
	if (args < 1) { 
		ReplyToCommand(client, "Usage: a4d_force_tank <0|1>"); 
		return Plugin_Handled; 
	}
	
	new String:value[2];
	GetCmdArg(1, value, sizeof(value));

	if (StrEqual(value, "0"))
		Do_ForceTank(client, false);	
	else 
		Do_ForceTank(client, true);
	return Plugin_Handled;
}
/**
 * <summary>
 * 	Forces the AI Director to spawn tanks at the nearest available opportunity.
 * </summary>
 * <remarks>
 * 	If you are only intending this to ensure one tank is spawned make sure
 * 	spawn_bosses_continuously is false.
 * </remarks>
 * <seealso>
 * 	Do_SpawnBossesContinuously
 * 	Do_SpawnInfected
 * 	Event_BossSpawn
 * </seealso>
*/
Do_ForceTank(client, bool:value) {
	StripAndChangeServerConVarBool(client, "director_force_tank", value);
	if (value == true)
		NotifyPlayers(client, "Tank保证将在这局生成");
	else
		NotifyPlayers(client, "Tank生成将由地图控制");
}
/// Sourcemod Action for the Do_ForceWitch command.
public Action:Command_ForceWitch(client, args) {
	if (args < 1) { 
		ReplyToCommand(client, "Usage: a4d_force_witch <0|1>"); 
		return Plugin_Handled;
	}
	new String:value[2];
	GetCmdArg(1, value, sizeof(value));
	if (StrEqual(value, "0"))
		Do_ForceWitch(client, false);
	else 
		Do_ForceWitch(client, true);
	return Plugin_Handled;
}
/**
 * <summary>
 * 	Forces the AI Director to spawn witches at the nearest available opportunity.
 * </summary>
 * <remarks>
 * 	If you are only intending this to ensure one witch is spawned make sure
 * 	spawn_bosses_continuously is false.
 * </remarks>
 * <seealso>
 * 	Do_SpawnBossesContinuously
 * 	Do_SpawnInfected
 * 	Event_BossSpawn
 * </seealso>
*/
Do_ForceWitch(client, bool:value) {
	StripAndChangeServerConVarBool(client, "director_force_witch", value);
	if (value == true)
		NotifyPlayers(client, "Witch保证将在这局生成");	
	else 
		NotifyPlayers(client, "Witch生成将由地图控制");
}


/// Sourcemod Action for the AddZombies command.
public Action:Command_AddZombies(client, args) {
	if (args < 1) { 
		ReplyToCommand(client, "Usage: a4d_add_zombies <0..99>"); 
		return Plugin_Handled;
	}
	new String:value[4];
	GetCmdArg(1, value, sizeof(value));
	new zombies = StringToInt(value);
	Do_AddZombies(client, zombies);
	return Plugin_Handled;
}
/**
 * <summary>
 * 	The director will spawn more zombies in the mobs and mega mobs.
 * </summary>
 * <remarks>
 * 	Make sure to not put silly values in for this as it may cause severe performance problems.
 * 	You can reset all settings back to their defaults by calling a4d_reset_to_defaults.
 * </remarks>
*/
Do_AddZombies(client, zombies_to_add) {
	new new_zombie_total = zombies_to_add + GetConVarInt(FindConVar("z_mega_mob_size"));
	StripAndChangeServerConVarInt(client, "z_mega_mob_size", new_zombie_total);
	new_zombie_total = zombies_to_add + GetConVarInt(FindConVar("z_mob_spawn_max_size"));
	StripAndChangeServerConVarInt(client, "z_mob_spawn_max_size", new_zombie_total);
	new_zombie_total = zombies_to_add + GetConVarInt(FindConVar("z_mob_spawn_min_size"));
	StripAndChangeServerConVarInt(client, "z_mob_spawn_min_size", new_zombie_total);
	NotifyPlayers(client, "僵尸生成点将生成更多僵尸");
}

// Configuration commands

/// Creates the configuration commands menu when it is selected from the top menu and displays it to the client.
public Action:Menu_CreateConfigMenu(client, args) {
	new Handle:menu = CreateMenu(Menu_ConfigCommandsHandler);
	SetMenuTitle(menu, "配置命令");
	SetMenuExitBackButton(menu, true);
	SetMenuExitButton(menu, true);
	if (GetConVarBool(notify_players)) { AddMenuItem(menu, "pn", "关闭玩家通知"); } else { AddMenuItem(menu, "pn", "启用玩家通知"); }
	AddMenuItem(menu, "rs", "将所有设置恢复为游戏默认值");
	DisplayMenu(menu, client, MENU_DISPLAY_TIME);
	return Plugin_Handled;
}
/// Handles callbacks from a client using the configuration menu.
public Menu_ConfigCommandsHandler(Handle:menu, MenuAction:action, cindex, itempos) {
	
	if (action == MenuAction_Select) {
		switch (itempos) {
			case 0: {
				if (GetConVarBool(notify_players))
					Do_EnableNotifications(cindex, false); 
				else
					Do_EnableNotifications(cindex, true); 
			} case 1: {
				Do_ResetToDefaults(cindex);
			}
		}
		Menu_CreateConfigMenu(cindex, false);
	} else if (action == MenuAction_End) {
		CloseHandle(menu);
	} else if (action == MenuAction_Cancel) {
		if (itempos == MenuCancel_ExitBack && admin_menu != INVALID_HANDLE)
			DisplayTopMenu(admin_menu, cindex, TopMenuPosition_LastCategory);
	}
}

/// Sourcemod Action for the Do_EnableNotifications command.
public Action:Command_EnableNotifications(client, args) {
	if (args < 1) { 
		ReplyToCommand (client, "Usage: a4d_enable_notifications <0|1>"); 
		return Plugin_Handled;
	}
	new String:value[2];
	GetCmdArg(1, value, sizeof(value));
	if (StrEqual(value, "0")) 
		Do_EnableNotifications(client, false);		
	else
		Do_EnableNotifications(client, true);
	return Plugin_Handled;
}
/**
 * <summary>
 * 	Enable (or disable) in game notifications of all4dead actions.
 * </summary>
 * <remarks>
 * 	When enabled notifications honour sm_activity settings.
 * </remarks>
*/
Do_EnableNotifications(client, bool:value) {
	SetConVarBool(notify_players, value);
	NotifyPlayers(client, "玩家通知现在已启用");
	LogAction(client, -1, "(%L) set %s to %i", client, "a4d_notify_players", value);	
}
/// Sourcemod Action for the Do_ResetToDefaults command.
public Action:Command_ResetToDefaults(client, args) {
	Do_ResetToDefaults(client);
	return Plugin_Handled;
}
/// Resets all ConVars to their default settings.
Do_ResetToDefaults(client) {
	Do_ForceTank(client, false);
	Do_ForceWitch(client, false);
	Do_PanicForever(client, false);
	StripAndChangeServerConVarInt(client, "z_mega_mob_size", 50);
	StripAndChangeServerConVarInt(client, "z_mob_spawn_max_size", 30);
	StripAndChangeServerConVarInt(client, "z_mob_spawn_min_size", 10);
	NotifyPlayers(client, "已恢复默认设置");
	LogAction(client, -1, "(%L) executed %s", client, "a4d_reset_to_defaults");
}

/// Sourcemod Action for the Do_EnableAllBotTeam command.
public Action:Command_EnableAllBotTeams(client, args) {
	if (args < 1) { 
		ReplyToCommand(client, "Usage: a4d_enable_all_bot_teams <0|1>"); 
		return Plugin_Handled;
	}

	new String:value[2];
	GetCmdArg(1, value, sizeof(value));

	if (StrEqual(value, "0"))
		Do_EnableAllBotTeam(client, false);	
	else
		Do_EnableAllBotTeam(client, true);
	return Plugin_Handled;
}
/// Allow an all bot survivor team
Do_EnableAllBotTeam(client, bool:value) {
	StripAndChangeServerConVarBool(client, "sb_all_bot_team", value);
	if (value == true)
		NotifyPlayers(client, "允许一支队伍里全是BOT");	
	else
		NotifyPlayers(client, "在游戏开始前，需要至少一名玩家");
}

// Helper functions

/// Wrapper for ShowActivity2 in case we want to change how this works later on
NotifyPlayers(client, const String:message[]) {
	if (GetConVarBool(notify_players))
		ShowActivity2(client, PLUGIN_TAG, message);
}
/// Strip and change a ConVarBool to another value. This allows modification of otherwise cheat-protected ConVars.
StripAndChangeServerConVarBool(client, String:command[], bool:value) {
	new flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	SetConVarBool(FindConVar(command), value, false, false);
	SetCommandFlags(command, flags);
	LogAction(client, -1, "[NOTICE]: (%L) set %s to %i", client, command, value);	
}
/// Strip and execute a client command. This 'fakes' a client calling a specfied command. Can be used to call cheat-protected commands.
StripAndExecuteClientCommand(client, const String:command[], const String:arguments[]) {
	new flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", command, arguments);
	SetCommandFlags(command, flags);
}
/// Strip and change a ConVarInt to another value. This allows modification of otherwise cheat-protected ConVars.
StripAndChangeServerConVarInt(client, String:command[], value) {
	new flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	SetConVarInt(FindConVar(command), value, false, false);
	SetCommandFlags(command, flags);
	LogAction(client, -1, "[NOTICE]: (%L) set %s to %i", client, command, value);	
}
// Gets a client ID to allow various commands to be called as console
Misc_GetAnyClient() {
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			// PrintToChatAll("Using client %L for command", i);
			return i;
		}
	}
	return 0;
}



bool:Misc_TraceClientViewToLocation(client, Float:location[3]) {
		new Float:vAngles[3], Float:vOrigin[3];
		GetClientEyePosition(client,vOrigin);
		GetClientEyeAngles(client, vAngles);
		// PrintToChatAll("Running Code %f %f %f | %f %f %f", vOrigin[0], vOrigin[1], vOrigin[2], vAngles[0], vAngles[1], vAngles[2]);
		new Handle:trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_PLAYERSOLID, RayType_Infinite, TraceRayDontHitSelf, client);
		if(TR_DidHit(trace)) {
			TR_GetEndPosition(location, trace);
			CloseHandle(trace);
			// PrintToChatAll("Collision at %f %f %f", location[0], location[1], location[2]);
			return true;
		}
	CloseHandle(trace);
	return false;
}

public bool:TraceRayDontHitSelf(entity, mask, any:data) {
	if(entity == data) { // Check if the TraceRay hit the itself.
		return false; // Don't let the entity be hit
	}
	return true; // It didn't hit itself
}

public GetEntityAbsOrigin(entity,Float:origin[3]) {
	decl Float:mins[3], Float:maxs[3];
	GetEntPropVector(entity,Prop_Send,"m_vecOrigin",origin);
	GetEntPropVector(entity,Prop_Send,"m_vecMins",mins);
	GetEntPropVector(entity,Prop_Send,"m_vecMaxs",maxs);
	
	origin[0] += (mins[0] + maxs[0]) * 0.5;
	origin[1] += (mins[1] + maxs[1]) * 0.5;
	origin[2] += (mins[2] + maxs[2]) * 0.5;
}

/*

public Action:Command_TeleportToZombieSpawn(client, args) {
	TeleportEntity(client, last_zombie_spawn_location, NULL_VECTOR, NULL_VECTOR);
	return Plugin_Handled;
}

*/

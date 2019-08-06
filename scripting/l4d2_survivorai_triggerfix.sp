#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0.9"

new bool:MapTrigger;
new bool:WarpTrigger;
new bool:WarpTriggerTwo;
new TriggeringBot;

new bool:GameRunning;

new bool:FinaleHasStarted;

public Plugin:myinfo =
{
	name = "L4D2 Survivor AI Trigger Fix",
	author = " AtomicStryker",
	description = " Fixes Survivor Bots not calling Crescendos ",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=1004836"
};

public OnPluginStart()
{
	CreateConVar("l4d2_survivoraitriggerfix_version", PLUGIN_VERSION, " Version of L4D2 Survivor AI Trigger Fix on this server ", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	RegAdminCmd("sm_findentitybyclass", Cmd_FindEntityByClass, ADMFLAG_BAN, "sm_findentitybyclass <classname> <entid> - find an entity by classname and starting index.");
	RegAdminCmd("sm_findentitybyname", Cmd_FindEntityByName, ADMFLAG_BAN, "sm_findentitybyname <name> <entid> - find an entity by name and starting index.");
	RegAdminCmd("sm_listentities", Cmd_ListEntities, ADMFLAG_BAN, "sm_listentities - server console dump of all valid entities");
	RegAdminCmd("sm_findnearentities", Cmd_FindNearEntities, ADMFLAG_BAN, "sm_findnearentities <radius> - find all Entities in a radius around you.");
	RegAdminCmd("sm_sendentityinput", Cmd_SendEntityInput, ADMFLAG_BAN, "sm_entityinput <entity id> <input string> - sends an Input to said Entity.");
	RegAdminCmd("sm_findentprop", Cmd_FindEntPropVal, ADMFLAG_BAN, "sm_findentprop <property string> - returns an entity property value in yourself");
	RegAdminCmd("sm_findentmodel", Cmd_FindEntityModel, ADMFLAG_BAN, "sm_findentmodel <entity id> - returns an entities model");
	
	CreateTimer(3.0, CheckAroundTriggers, 0, TIMER_REPEAT);
	
	HookEvent("finale_start", FinaleBegins);
	HookEvent("round_end", GameEnds);
	HookEvent("map_transition", GameEnds);
	HookEvent("mission_lost", GameEnds);
	HookEvent("finale_win", GameEnds);
}

public OnMapStart()
{
	MapTrigger = false;
	WarpTrigger = false;
	WarpTriggerTwo = false;
	FinaleHasStarted = false;
}

public OnMapEnd()
{
	MapTrigger = false;
	WarpTrigger = false;
	WarpTriggerTwo = false;
}

public OnClientConnected(client)
{
	if (IsFakeClient(client)) return;
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			if (!IsFakeClient(i))
			{
				GameRunning = true;
				return;
			}
		}
	}
	
	GameRunning = false;
	SetConVarInt(FindConVar("sb_all_bot_game"), 0);
	SetConVarInt(FindConVar("allow_all_bot_survivor_team"), 0);
}

public OnClientPutInServer(client)
{
	if (!IsFakeClient(client))
	{
		SetConVarInt(FindConVar("sb_all_bot_game"), 1);
		SetConVarInt(FindConVar("allow_all_bot_survivor_team"), 1);
		GameRunning = true;
	}
}

public OnClientDisconnect_Post(client)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			if (!IsFakeClient(i))
			{
				GameRunning = true;
				return;
			}
		}
	}
	
	GameRunning = false;
	SetConVarInt(FindConVar("sb_all_bot_game"), 0);
}

public Action:GameEnds(Handle:event, const String:name[], bool:dontBroadcast)
{
	CreateTimer(7.0, DelayedBoolReset, 0);
	FinaleHasStarted = false;
}

public Action:FinaleBegins(Handle:event, const String:name[], bool:dontBroadcast)
{
	FinaleHasStarted = true;
}

public Action:DelayedBoolReset(Handle:Timer)
{
	MapTrigger = false; // to circumvent bugs with slow-ass l4d engine.
	WarpTrigger = false;
	WarpTriggerTwo = false;
}

public Action:CheckAroundTriggers(Handle:timer)
{
	if (!GameRunning) return Plugin_Continue;
	
	if (!IsCoop() && !IsVersus()) return Plugin_Continue;
	
	if (!AllBotTeam()) return Plugin_Continue;

	decl String:mapname[256];
	GetCurrentMap(mapname, sizeof(mapname));
	
	if (StrContains(mapname, "c1m1_hotel", false) != -1)
	{
		//stuck infront of fire 1722.6 6700.7 2510.4
		//past fire 1727.0 6479.6 2513.1 - but they move around eventually
		
		// Dead Center 01 - elevator button
		// position elevator: name elevator_up_game_event, class info_game_event_proxy
		
		new button = FindEntityByClassname(-1, "func_button");
		
		decl Float:pos1[3]; // elevator position, manually
		pos1[0] = 2165.7
		pos1[1] = 5790.0
		pos1[2] = 2470.0
		
		if (CheckforBots(pos1, 100.0))
		{
			PrintToChatAll("\x04[BOTFIX] \x01Bot found close to the Elevator Button, pushing...");
			AcceptEntityInput(button, "Press");
			
			if (!WarpTrigger && IsVersus())
			{
				PrintToChatAll("\x04[BOTFIX] \x01Versus Fix: Bots will be warped into the Elevator in 10 seconds");
				WarpTrigger = true;
				
				new Handle:posdata2 = CreateDataPack();
				WritePackFloat(posdata2, pos1[0]);
				WritePackFloat(posdata2, pos1[1]);
				WritePackFloat(posdata2, pos1[2]);
				CreateTimer(10.0, WarpAllBots, posdata2);
			}
		}
		
		// 2165 5812 1250 elevator down position
		pos1[2] = 1250.0;
		
		if (CheckforBots(pos1, 200.0) && !MapTrigger) // case: Survivors are where the elevator ends. They push the doors open themselves.
		{
			MapTrigger = true;
			WarpTrigger = false;
		}
	}
	
	if (StrContains(mapname, "c1m2_streets", false) != -1)
	{
		// Dead Center 02
		new button = FindEntityByClassname(-1, "func_button"); //gunshop button
		
		decl Float:pos1[3];
		if (!WarpTrigger)
		{
			pos1[0] = -2407.7  // on trashcan blockade
			pos1[1] = 2268.6
			pos1[2] = 115.1
			
			if (CheckforBots(pos1, 250.0))
			{
				WarpTrigger = true; // case: Bots reached trashcans
				
				if (IsVersus())
				{
					pos1[0] = -2569.1 // past trashcan nav block    
					pos1[1] = 2219.5
					pos1[2] = 62.0
					
					new Handle:posdata = CreateDataPack();
					WritePackFloat(posdata, pos1[0]);
					WritePackFloat(posdata, pos1[1]);
					WritePackFloat(posdata, pos1[2]);
					CreateTimer(3.0, WarpAllBots, posdata);
					
					PrintToChatAll("\x04[BOTFIX] \x01Versus Fix: Circumventing allmighty Trash Can Blockade");
				}
			}
		}
		
		if (WarpTrigger && !WarpTriggerTwo && !MapTrigger)
		{
			pos1[0] = -4365.6  // top of navbreaker bridge
			pos1[1] = 2234.4
			pos1[2] = 352.0
		
			if (CheckforBots(pos1, 250.0))
			{
				WarpTriggerTwo = true; // case: Bots reached top o bridge
				
				if (IsVersus())
				{
					pos1[0] = -4177.0 // warpto bridge   
					pos1[1] = 1823.6
					pos1[2] = 126.0
					
					new Handle:posdata = CreateDataPack();
					WritePackFloat(posdata, pos1[0]);
					WritePackFloat(posdata, pos1[1]);
					WritePackFloat(posdata, pos1[2]);
					CreateTimer(3.0, WarpAllBots, posdata);
					
					PrintToChatAll("\x04[BOTFIX] \x01Versus Fix: Circumventing impossible Bridge Obstacle");
				}
			}
		}
		
		if (!IsValidEntity(button) && !MapTrigger)
		{
			MapTrigger = true;
			WarpTrigger = false;
			WarpTriggerTwo = false;
		}
		else
		{
			pos1[0] = -4875.7 // at button - its unbelievable but the nav area actually ENDS before it
			pos1[1] = -1887.4
			pos1[2] = 455.0
			
			//GetEntityAbsOrigin(button, pos1);
			if (CheckforBots(pos1, 150.0) && !MapTrigger)
			{
				PrintToChatAll("\x04[BOTFIX] \x01Bot found close to the Gun Shop Button, pushing...");
				
				AcceptEntityInput(button, "press");
				//UnflagAndExecuteCommand(GetAnyValidClient(), "ent_fire", "gunshop_door_button", "press");
				
				/*
				new door = FindEntityByName("gunshop_door_01", -1);
				AcceptEntityInput(door, "unlock");
				AcceptEntityInput(door, "open");
				// using just the door doesnt send the bots moving
				*/
				MapTrigger = true;
				WarpTrigger = false;
				WarpTriggerTwo = false;
			}
		}
		
		decl Float:pos2[3];
		pos2[0] = -6870.3
		pos2[1] = -1057.2
		pos2[2] = 434.2
		
		// huddle spot before cola run -6870.3 -1057.2 434.2
		if (CheckforBots(pos2, 200.0) && !WarpTrigger)
		{
			PrintToChatAll("\x04[BOTFIX] \x01Bot found stuck near supermarket, initiating in 10 seconds");
			PrintToChatAll("\x04[BOTFIX] \x01Crescendo will end 90 seconds after that");
			
			// position cola: -7377.6 -1372.1 427.2
			new Handle:posdata = CreateDataPack();
			WritePackFloat(posdata, -7377.6);
			WritePackFloat(posdata, -1372.1);
			WritePackFloat(posdata, 427.2);
			CreateTimer(10.0, WarpAllBots, posdata);
			CreateTimer(10.0, CallSuperMarket);
			
			// position past tanker barricade: -7410.6 -692.1 460.4
			/*
			new Handle:posdata2 = CreateDataPack();
			WritePackFloat(posdata2, -7410.6);
			WritePackFloat(posdata2, -692.1);
			WritePackFloat(posdata2, 460.4);
			*/
			
			CreateTimer(95.0, WarpAllBots, posdata);
			CreateTimer(100.0, CallTankerBoom);
			
			WarpTrigger = true;
		}
	}
	
	if (StrContains(mapname, "c1m3_mall", false) != -1)
	{
		// Dead Center 03 - emergency door or windows
		// name door_hallway_lower4a, class prop_door_rotating, Input "Open"
		// they do the rest veeery slowly, but by themselves
		
		new door = FindEntityByName("door_hallway_lower4a", -1);
		
		decl Float:pos1[3];
		if (door > 0)
		{
			GetEntityAbsOrigin(door, pos1);
			if (CheckforBots(pos1, 200.0) && !MapTrigger)
			{
				PrintToChatAll("\x04[BOTFIX] \x01Bot found close to the Emergency Door, open sesame...");
				AcceptEntityInput(door, "Open");
				CreateTimer(180.0, ShutOffAlarmMall, TIMER_FLAG_NO_MAPCHANGE);
				MapTrigger = true;
			}
		}
		
		new glass = FindEntityByName("breakble_glass_minifinale", -1); //Valve typing error, lol
		if (glass > 0)
		{
			GetEntityAbsOrigin(glass, pos1);
			if (CheckforBots(pos1, 400.0) && !MapTrigger)
			{
				PrintToChatAll("\x04[BOTFIX] \x01Bot found close to the Alarmed Windows, open sesame...");
				AcceptEntityInput(glass, "Break");
				CreateTimer(120.0, ShutOffAlarmMall, TIMER_FLAG_NO_MAPCHANGE);
				MapTrigger = true;
			}
		}
		
		decl Float:posx[3];
		posx[0] = -900.7
		posx[1] = -4373.4
		posx[2] = 326.1
		// confusion spot -900.7 -4373.4 326.1, teleport them off
		// to: -760.4 -4627.7 578.1
		if (CheckforBots(posx, 200.0) && !WarpTrigger)
		{
			PrintToChatAll("\x04[BOTFIX] \x01Bot found at a stuck spot, warping them all ahead in 10 seconds");
			
			new Handle:posdata = CreateDataPack();
			WritePackFloat(posdata, -760.4);
			WritePackFloat(posdata, -4627.7);
			WritePackFloat(posdata, 578.1);
			CreateTimer(10.0, WarpAllBots, posdata);
			WarpTrigger = true;
		}
	}
	
	// No way there could be anything done about Dead Center 4 - this would require a Scavenge AI which simply doesnt exist
	
	
	// Dark Carnival 1 is fine in Coop
	
	if (StrContains(mapname, "c2m2_fairgrounds", false) != -1)
	{
		// Dark Carnival 02 - carusel buttons
		
		// Go: name carousel_gate_button, class func_button, Input "Press"
		// they do the rest veeery slowly, but by themselves
		
		new button = FindEntityByName("carousel_gate_button", -1);
		
		if (!IsValidEntity(button))
		{
			MapTrigger = true;
		}
		else
		{
			decl Float:pos1[3];
			GetEntityAbsOrigin(button, pos1);
			
			if (CheckforBots(pos1, 250.0) && !MapTrigger)
			{
				PrintToChatAll("\x04[BOTFIX] \x01Bot found close to the Carousel Button, pressing...");
				AcceptEntityInput(button, "Press");
				CreateTimer(60.0, ShutOffCarousel, TIMER_FLAG_NO_MAPCHANGE);
				MapTrigger = true;
			}
		}
	}
	
	if (StrContains(mapname, "c2m3_coaster", false) != -1)
	{
		// Dark Carnival 03 - coaster buttons
		
		// Go: name minifinale_button, class func_button, Input "Press"
		// they do the rest veeery slowly, but by themselves
		
		new button = FindEntityByName("minifinale_button", -1);
		
		if (!IsValidEntity(button))
		{
			MapTrigger = true;
		}
		else
		{
			decl Float:pos1[3];
			GetEntityAbsOrigin(button, pos1);
			
			if (CheckforBots(pos1, 250.0) && !MapTrigger)
			{
				PrintToChatAll("\x04[BOTFIX] \x01Bot found close to the Rollercoaster Button, pressing...");
				AcceptEntityInput(button, "Press");
				CreateTimer(150.0, ShutOffCoaster, TIMER_FLAG_NO_MAPCHANGE);
				MapTrigger = true;
			}
		}
	}
	
	if (StrContains(mapname, "c2m4_barns", false) != -1)
	{
		// Dark Carnival 04 - rolling crescendo
		
		// Go: name minifinale_gates_button;, class func_button, Input "Press"
		// they do the rest veeery slowly, but by themselves
		
		new button = FindEntityByName("minifinale_gates_button", -1);
		
		if (!IsValidEntity(button))
		{
			MapTrigger = true;
		}
		else
		{
			decl Float:pos1[3];
			GetEntityAbsOrigin(button, pos1);
			
			if (CheckforBots(pos1, 250.0) && !MapTrigger)
			{
				PrintToChatAll("\x04[BOTFIX] \x01Bot found close to the Gates Button, pressing...");
				AcceptEntityInput(button, "Press");
				MapTrigger = true;
				
				/*
				PrintToChatAll("\x04[BOTFIX] \x01Bots will be warped into the saferoom in 180 seconds");
				// position saferoom: -780.7 2295.7 -204.0
				new Handle:posdata = CreateDataPack();
				WritePackFloat(posdata, -780.7);
				WritePackFloat(posdata, 2295.7);
				WritePackFloat(posdata, -204.0);
				CreateTimer(180.0, WarpAllBots, posdata, TIMER_FLAG_NO_MAPCHANGE);
				*/
			}
		}
	}
	
	if (StrContains(mapname, "c2m5_concert", false) != -1)
	{
		if (MapTrigger) return Plugin_Continue;
		// map is Dark Carnival 5
		
		decl Float:pos1[3];
		// -1858.1 3369.9 -138.7 is where the bots camp out
		pos1[0] = -1858.1;
		pos1[1] = 3369.9;
		pos1[2] = -120.7;
		
		new lightsbutton = FindEntityByName("stage_lights_button", -1);
		
		if (!IsValidEntity(lightsbutton))
		{
			MapTrigger = true;
			CreateTimer(20.0, FinaleStart, 0);
			return Plugin_Continue;
		}
		
		if (CheckforBots(pos1, 100.0) && !MapTrigger)
		{
			PrintToChatAll("\x04[BOTFIX] \x01Bot found ready to rock. Getting it on...");
			AcceptEntityInput(lightsbutton, "Press");
			MapTrigger = true;
			
			CreateTimer(20.0, FinaleStart);
		}
	}
	
	if (StrContains(mapname, "c3m1_plankcountry", false) != -1)
	{
		// Swamp Fever 01 - classic crescendo
		// they freakin KILL THEMSELVES by teleporting into the river, yay
		// name: ferry_button, func_button
		
		new button = FindEntityByName("ferry_button", -1);
		
		if (!IsValidEntity(button))
		{
			MapTrigger = true;
		}
		else
		{
			decl Float:pos1[3];
			GetEntityAbsOrigin(button, pos1);
			
			if (CheckforBots(pos1, 250.0) && !MapTrigger)
			{
				PrintToChatAll("\x04[BOTFIX] \x01Bot found close to the Ferry Button, pressing...");
				AcceptEntityInput(button, "Press");
				MapTrigger = true;
				
				PrintToChatAll("\x04[BOTFIX] \x01Bots will be warped across the river in 80 seconds");
				// position: -4282.7 6065.7 77.5
				new Handle:posdata = CreateDataPack();
				WritePackFloat(posdata, -4282.7);
				WritePackFloat(posdata, 6065.7);
				WritePackFloat(posdata, 77.5);
				CreateTimer(80.0, WarpAllBots, posdata, TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	}
	
	if (StrContains(mapname, "c3m2_swamp", false) != -1)
	{
		// Swamp Fever 02 - Plane Hatch
		// Go: name cabin_door_button, class func_button, Input "Press"
		
		new button = FindEntityByName("cabin_door_button", -1);
		
		if (!IsValidEntity(button))
		{
			MapTrigger = true;
		}
		else
		{
			decl Float:pos1[3];
			GetEntityAbsOrigin(button, pos1);
			
			if (CheckforBots(pos1, 250.0) && !MapTrigger)
			{
				PrintToChatAll("\x04[BOTFIX] \x01Bot found close to the Plane Hatch, pressing...");
				AcceptEntityInput(button, "Press");
				MapTrigger = true;
			}
		}
	}
	
	if (StrContains(mapname, "c3m3_shantytown", false) != -1)
	{
		// Swamp Fever 03 - Bridge Button
		// Go: name bridge_button, class func_button, Input "Press"
		
		new button = FindEntityByName("bridge_button", -1);
		
		if (!IsValidEntity(button))
		{
			MapTrigger = true;
		}
		else
		{
			decl Float:pos1[3]; // they sometimes huddle at 259.2 -2804.7 24.3
			pos1[0] = 259.2;
			pos1[1] = -2804.7;
			pos1[2] = 24.3;
			
			if (CheckforBots(pos1, 250.0) && !MapTrigger)
			{
				PrintToChatAll("\x04[BOTFIX] \x01Bot found close to their Hidey Spot, lowering Bridge...");
				AcceptEntityInput(button, "Press");
				MapTrigger = true;
			}
			
			GetEntityAbsOrigin(button, pos1);
			
			if (CheckforBots(pos1, 250.0) && !MapTrigger)
			{
				PrintToChatAll("\x04[BOTFIX] \x01Bot found close to the Bridge Button, pressing...");
				AcceptEntityInput(button, "Press");
				MapTrigger = true;
			}
		}
	}
	
	if (StrContains(mapname, "c3m4_plantation", false) != -1)
	{
		if (MapTrigger) return Plugin_Continue;
		// map is Swamp Fever 4
		
		decl Float:pos1[3];
		// finale balcony coordinates 1675.9 439.9 448.8	
		pos1[0] = 1675.9;
		pos1[1] = 439.9;
		pos1[2] = 428.8;
		
		new button = FindEntityByName("escape_gate_button,", -1);
		
		if (CheckforBots(pos1, 400.0) && !MapTrigger && button)
		{
			PrintToChatAll("\x04[BOTFIX] \x01Bot found ready for Finale. Going on...");
			AcceptEntityInput(button, "Press");
			MapTrigger = true;
			
			//1556.0 1930.6 159.7 is infront of the radio
			decl Float:radiopos[3];
			radiopos[0] = 1556.0;
			radiopos[1] = 1930.6;
			radiopos[2] = 159.7;
			for (new target = 1; target <= MaxClients; target++)
			{
				if (IsClientInGame(target))
				{
					if (GetClientHealth(target) > 1 && GetClientTeam(target) == 2 && IsFakeClient(target)) // make sure target is a Survivor Bot
					{
						TeleportEntity(target, radiopos, NULL_VECTOR, NULL_VECTOR);
					}
				}
			}
			CreateTimer(20.0, FinaleStart);
		}
	}
	
	//c4m1_milltown_a - is fine in Coop
	
	//c4m2_sugarmill_a - name button_callelevator class func_button
	if (StrContains(mapname, "c4m2_sugarmill_a", false) != -1)
	{
		// Hard Rain 02
		new button = FindEntityByClassname(-1, "func_button"); //elevator button
		
		if (!IsValidEntity(button))
		{
			MapTrigger = true;
		}
		else
		{
			decl Float:pos1[3];
			GetEntityAbsOrigin(button, pos1);
			
			if (CheckforBots(pos1, 150.0) && !MapTrigger)
			{
				PrintToChatAll("\x04[BOTFIX] \x01Bot found close to the Elevator Button, pushing...");
				
				AcceptEntityInput(button, "press");
				MapTrigger = true;
				
				PrintToChatAll("\x04[BOTFIX] \x01Also warping the cheaterbots backwards.");
				
				pos1[0] = -824.7;
				pos1[1] = -8689.7;
				pos1[2] = 149.9;
				for (new target = 1; target <= MaxClients; target++)
				{
					if (IsClientInGame(target))
					{
						if (GetClientHealth(target) > 1 && GetClientTeam(target) == 2 && IsFakeClient(target)) // make sure target is a Survivor Bot
						{
							TeleportEntity(target, pos1, NULL_VECTOR, NULL_VECTOR);
						}
					}
				}
			}
		}
	}
	
	//c4m3_sugarmill_b - is fine in Coop
	
	//c4m4_milltown_b - is fine in Coop
	
	//c4m5_milltown_escape - is fine in Coop, astonishingly
	
	//c5m1_waterfront - is fine in Coop
	
	if (StrContains(mapname, "c5m2_park", false) != -1)
	{
		// c5m2_park - name finale_cleanse_entrance_door class prop_door_rotating "close"
		// huddle -9654.8 -5962.8 -166.8
		// name finale_cleanse_exit_door, class prop_door_rotating "open" - a few secs later
		
		decl Float:pos1[3];
		pos1[0] = -9654.8;
		pos1[1] = -5962.8;
		pos1[2] = -146.8;
		
		if (CheckforBots(pos1, 150.0) && !MapTrigger)
		{
			PrintToChatAll("\x04[BOTFIX] \x01Bot found inside the trailer. Starting Event in 10 seconds.");
			MapTrigger = true;
			
			CreateTimer(10.0, RunBusStationEvent);
			
			new Handle:posdata = CreateDataPack();
			WritePackFloat(posdata, pos1[0]);
			WritePackFloat(posdata, pos1[1]);
			WritePackFloat(posdata, pos1[2]);
			CreateTimer(9.5, WarpAllBots, posdata);
		}
	}
	
	//c5m3_cemetery - is fine in Coop
	
	if (StrContains(mapname, "c5m4_quarter", false) != -1)
	{
		//c5m4_quarter - huddle after crescendo -1487.0 684.0 109.0
		// teleport to -1864.4 474.3 286.9
		
		decl Float:pos1[3];
		pos1[0] = -1487.0;
		pos1[1] = 684.0;
		pos1[2] = 109.0;
		
		if (CheckforBots(pos1, 75.0) && !MapTrigger)
		{
			PrintToChatAll("\x04[BOTFIX] \x01Bot found where they camp out after the Crescendo. Teleporting them ahead in 20 seconds.");
			MapTrigger = true;
			
			new Handle:posdata = CreateDataPack();
			WritePackFloat(posdata, -1864.4);
			WritePackFloat(posdata, 474.3);
			WritePackFloat(posdata, 286.9);
			CreateTimer(40.0, WarpAllBots, posdata);
		}
	}
	
	if (StrContains(mapname, "c5m5_bridge", false) != -1)
	{
		// c5m5_bridge
		// name radio_fake_button, class func_button "Press"
		// a little later standard finale call
		
		new button = FindEntityByName("radio_fake_button", -1);
		
		if (!IsValidEntity(button) && !MapTrigger)
		{
			MapTrigger = true;
			CreateTimer(20.0, FinaleStart);
			
			if (IsVersus())
			{
				new Handle:posdata = CreateDataPack(); // infront of button
				WritePackFloat(posdata, -11529.7);
				WritePackFloat(posdata, 6117.1);
				WritePackFloat(posdata, 480.0);
				CreateTimer(40.0, WarpAllBots, posdata);
			}
		}
		else
		{
			decl Float:pos1[3];
			GetEntityAbsOrigin(button, pos1);
			
			if (CheckforBots(pos1, 300.0) && !MapTrigger)
			{
				PrintToChatAll("\x04[BOTFIX] \x01Bot found ready for Finale. Finale launches in 40 seconds...");
				AcceptEntityInput(button, "Press");
				
				CreateTimer(20.0, FinaleStart);
				if (IsVersus())
				{
					new Handle:posdata = CreateDataPack(); // infront of button
					WritePackFloat(posdata, -11529.7);
					WritePackFloat(posdata, 6117.1);
					WritePackFloat(posdata, 480.0);
					CreateTimer(40.0, WarpAllBots, posdata);
				}
			}
			
			//position inside heli:  7381.8 3802.7 266.5
			//infront of it SHITTY NAV  7537.1 3461.0 190.0
			pos1[0] = 7537.1;
			pos1[1] = 3461.0;
			pos1[2] = 190.0;
			
			// stuck position right side -7714.0 6084.7 532.0
		}
	}
	
	return Plugin_Continue;
}

public Action:WarpAllBots(Handle:Timer, Handle:posdata)
{
	ResetPack(posdata);
	decl Float:position[3];
	position[0] = ReadPackFloat(posdata);
	position[1] = ReadPackFloat(posdata);
	position[2] = ReadPackFloat(posdata);
	CloseHandle(posdata);
	
	PrintToChatAll("\x04[BOTFIX] \x01Warping Bots now.");
	
	for (new target = 1; target <= MaxClients; target++)
	{
		if (IsClientInGame(target))
		{
			if (IsPlayerAlive(target) && GetClientTeam(target) == 2 && IsFakeClient(target)) // make sure target is a Survivor Bot
			{
				TeleportEntity(target, position, NULL_VECTOR, NULL_VECTOR);
			}
		}
	}
}

public Action:CallSuperMarket(Handle:Timer)
{
	// name store_doors, class prop_door_rotating - input "Open"
	AcceptEntityInput(FindEntityByName("store_doors", -1), "Open");
}

public Action:CallTankerBoom(Handle:Timer)
{
	// ent_fire tanker_destroy_relay trigger
	UnflagAndExecuteCommand(TriggeringBot, "ent_fire", "tanker_destroy_relay", "trigger");
}

public Action:ShutOffAlarmMall(Handle:Timer)
{
	// class func_button - input "Press"
	AcceptEntityInput(FindEntityByClassname(-1, "func_button"), "Press");
	PrintToChatAll("\x04[BOTFIX] \x01Shutting off the alarm to relieve the bots.");
}

public Action:ShutOffCarousel(Handle:Timer)
{
	// Shutoff: name carousel_button, class func_button, Input "Press"
	AcceptEntityInput(FindEntityByName("carousel_button", -1), "Press");
	PrintToChatAll("\x04[BOTFIX] \x01Shutting off the carousel to relieve the bots.");
}

public Action:ShutOffCoaster(Handle:Timer)
{
	// name finale_alarm_stop_button, class func_button, Input "Press"
	AcceptEntityInput(FindEntityByName("finale_alarm_stop_button", -1), "Press");
	PrintToChatAll("\x04[BOTFIX] \x01Shutting off the rollercoaster to relieve the bots.");
}

public Action:RunBusStationEvent(Handle:Timer)
{
	AcceptEntityInput(FindEntityByName("finale_cleanse_entrance_door", -1), "Close");
	PrintToChatAll("\x04[BOTFIX] \x01Closing the Event Trailer door.");
	CreateTimer(10.0, RunBusStationEvent2);
}

public Action:RunBusStationEvent2(Handle:Timer)
{
	AcceptEntityInput(FindEntityByName("finale_cleanse_exit_door", -1), "Open");
	PrintToChatAll("\x04[BOTFIX] \x01Opening the alarmed door.");
}

public Action:FinaleStart(Handle:Timer)
{
	if (FinaleHasStarted) return Plugin_Continue;
	
	if (!TriggeringBot) TriggeringBot = GetAnyValidClient();
	else if (!IsClientInGame(TriggeringBot)) TriggeringBot = GetAnyValidClient();
	
	if (!TriggeringBot) return Plugin_Continue;
	UnflagAndExecuteCommand(TriggeringBot, "ent_fire", "trigger_finale", "");
	PrintToChatAll("\x04[BOTFIX] \x01Executing Finale Call.");
	return Plugin_Continue;
}

// this bool return true if a Bot was found in a radius around the given position, and sets TriggeringBot to it.
bool:CheckforBots(Float:position[3], Float:distancesetting)
{
	for (new target = 1; target <= MaxClients; target++)
	{
		if (IsClientInGame(target))
		{
			if (GetClientHealth(target)>1 && GetClientTeam(target) == 2 && IsFakeClient(target)) // make sure target is a Survivor Bot
			{
				if (IsPlayerIncapped(target)) // incapped doesnt count
					return false;
				
				decl Float:targetPos[3];
				GetClientAbsOrigin(target, targetPos);
				new Float:distance = GetVectorDistance(targetPos, position); // check Survivor Bot Distance from checking point
				
				if (distance < distancesetting)
				{
					TriggeringBot = target;
					return true;
				}
				else
				{
					continue;
				}
			}
		}
	}
	return false;
}

// this console command is for finding entities and their id
public Action:Cmd_FindEntityByClass(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_findentitybyclass <classname> <startindex> - find an entity class starting from index number");
		return Plugin_Handled;
	}
	
	decl String:name[64], String:startnum[12];
	GetCmdArg(1, name, 64);
	GetCmdArg(2, startnum, 12);
	new entid = FindEntityByClassname(StringToInt(startnum), name);
	if (entid == -1)
	{
		PrintToChat(client, "Found no Entity of that class.");
		return Plugin_Handled;
	}
	
	decl Float:clientpos[3], Float:entpos[3];
	GetClientAbsOrigin(client, clientpos);
	GetEntityAbsOrigin(entid, entpos);
	new Float:distance = GetVectorDistance(clientpos, entpos);
	
	GetEntPropString(entid, Prop_Data, "m_iName", name, sizeof(name));
	PrintToChat(client, "Found Entity Id %i, of name: %s; distance from you: %f", entid, name, distance);
	
	return Plugin_Handled;
}

public Action:Cmd_FindEntityByName(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_findentitybyname <name> <startindex> - find an entity by name starting from index number");
		return Plugin_Handled;
	}
	
	decl String:entname[64], String:number[12];
	GetCmdArg(1, entname, 64);
	GetCmdArg(2, number, 64);
	
	new foundid = FindEntityByName(entname, StringToInt(number));
	if (foundid == -1) PrintToChatAll("Nothing by that name found.");
	else PrintToChatAll("Found Entity: %i by name %s", foundid, entname);
	
	return Plugin_Handled;
}

public Action:Cmd_FindEntityModel(client, args)
{
	decl String:number[12];
	GetCmdArg(1, number, 64);
	
	decl String:m_ModelName[PLATFORM_MAX_PATH];
	GetEntPropString(StringToInt(number), Prop_Data, "m_ModelName", m_ModelName, sizeof(m_ModelName));
	
	PrintToChat(client, "Model: %s", m_ModelName);
	
	decl Float:EyePos[3], Float:AimOnEnt[3], Float:AimAngles[3], Float:entpos[3];
	GetClientEyePosition(client, EyePos);
	GetEntityAbsOrigin(StringToInt(number), entpos);
	MakeVectorFromPoints(EyePos, entpos, AimOnEnt);
	GetVectorAngles(AimOnEnt, AimAngles);
	TeleportEntity(client, NULL_VECTOR, AimAngles, NULL_VECTOR); // make the Survivor Bot aim on the Victim

	return Plugin_Handled;
}

//this sends Entity Inputs like "Kill" or "Activate"
public Action:Cmd_SendEntityInput(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_entityinput <entity id> <input string> - sends an Input to said Entity");
		return Plugin_Handled;
	}
	
	decl String:entid[64], String:input[12];
	GetCmdArg(1, entid, 64);
	GetCmdArg(2, input, 64);
	
	AcceptEntityInput(StringToInt(entid), input);
	
	return Plugin_Handled;
}

// this finds entites - who have a position - in a radius around you
public Action:Cmd_FindNearEntities(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_findnearentities <radius> - find all Entities with a position close to you");
		return Plugin_Handled;
	}
	decl String:value[64];
	GetCmdArg(1, value, 64);
	new Float:radius = StringToFloat(value);
	
	decl Float:entpos[3], Float:clientpos[3], String:name[128], String:classname[128];
	GetClientAbsOrigin(client, clientpos);
	new maxentities = GetMaxEntities();
	
	for (new i = 1; i <= maxentities; i++)
	{
		if (!IsValidEntity(i)) continue; // exclude invalid entities.
		
		GetEntPropString(i, Prop_Data, "m_iName", name, sizeof(name));
		GetEdictClassname(i, classname, 128)
		
		if (FindDataMapOffs(i, "m_iName") == -1) continue;
		
		GetEntityAbsOrigin(i, entpos);
		if (GetVectorDistance(entpos, clientpos) < radius)
		{
			PrintToChat(client, "Found: Entid %i, name %s, class %s", i, name, classname);
		}
	}
	return Plugin_Handled;
}

// dumps a list of all map entities into your servers console. if you localhost that is YOUR console ^^
public Action:Cmd_ListEntities(client, args)
{
	new maxentities = GetMaxEntities();
	decl String:name[128], String:classname[128];
	
	for (new i = 0; i <= maxentities; i++)
	{
		if (!IsValidEntity(i)) continue; // exclude invalid entities.
		
		GetEntPropString(i, Prop_Data, "m_iName", name, sizeof(name));
		GetEdictClassname(i, classname, 128)
		PrintToServer("%i: name %s, classname %s", i, name, classname);
		
	}
	return Plugin_Handled;
}

stock FindEntityByName(String:name[], any:startcount)
{
	decl String:classname[128];
	new maxentities = GetMaxEntities();
	
	for (new i = startcount; i <= maxentities; i++)
	{
		if (!IsValidEntity(i)) continue; // exclude invalid entities.
		
		GetEdictClassname(i, classname, 128);
		
		if (FindDataMapOffs(i, "m_iName") == -1) continue;
		
		decl String:iname[128];
		GetEntPropString(i, Prop_Data, "m_iName", iname, sizeof(iname));
		if (strcmp(name,iname,false) == 0) return i;
	}
	return -1;
}

public Action:Cmd_FindEntPropVal(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_findentprop <property string> - returns an entity property value in yourself");
		return Plugin_Handled;
	}
	
	decl String:prop[64];
	GetCmdArg(1, prop, sizeof(prop));
	
	new offset = FindSendPropInfo("CTerrorPlayer", prop);
	
	if (offset == -1)
	{
		PrintToChat(client, "No such property: %s", prop)
		return Plugin_Handled;
	}
	
	else if (offset == 0)
	{
		PrintToChat(client, "No offset found for: %s", prop)
		return Plugin_Handled;
	}
	
	PrintToChat(client, "Value of %s: %i", prop, GetEntData(client, offset));
	return Plugin_Handled;
}

stock bool:IsVersus()
{
	decl String:gamemode[56];
	GetConVarString(FindConVar("mp_gamemode"), gamemode, sizeof(gamemode));
	if (StrContains(gamemode, "versus", false) > -1)
		return true;
	return false;
}

stock bool:IsCoop()
{
	decl String:gamemode[56];
	GetConVarString(FindConVar("mp_gamemode"), gamemode, sizeof(gamemode));
	if (StrContains(gamemode, "coop", false) > -1)
		return true;
	return false;
}

stock UnflagAndExecuteCommand(client, String:command[], String:parameter1[]="", String:parameter2[]="")
{
	if (!client || !IsClientInGame(client)) client = GetAnyValidClient();
	if (!client || !IsClientInGame(client)) return;
	
	new userflags = GetUserFlagBits(client);
	SetUserFlagBits(client, ADMFLAG_ROOT);
	new flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s %s", command, parameter1, parameter2)
	SetCommandFlags(command, flags);
	SetUserFlagBits(client, userflags);
}

//entity abs origin code from here
//http://forums.alliedmods.net/showpost.php?s=e5dce96f11b8e938274902a8ad8e75e9&p=885168&postcount=3
stock GetEntityAbsOrigin(entity,Float:origin[3])
{
	if (entity > 0 && IsValidEntity(entity))
	{
		decl Float:mins[3], Float:maxs[3];
		GetEntPropVector(entity,Prop_Send,"m_vecOrigin",origin);
		GetEntPropVector(entity,Prop_Send,"m_vecMins",mins);
		GetEntPropVector(entity,Prop_Send,"m_vecMaxs",maxs);
		
		origin[0] += (mins[0] + maxs[0]) * 0.5;
		origin[1] += (mins[1] + maxs[1]) * 0.5;
		origin[2] += (mins[2] + maxs[2]) * 0.5;
	}
}

stock bool:AllBotTeam()
{
	for (new client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && GetClientHealth(client)>=1 && GetClientTeam(client) == 2)
		{
			if (!IsFakeClient(client)) return false;
		}
	}
	return true;
}

stock bool:IsPlayerIncapped(client)
{
	if (GetEntProp(client, Prop_Send, "m_isIncapacitated"))
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
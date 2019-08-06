#pragma semicolon 1
#include <sourcemod>
#include <clientprefs>

#define PLUGIN_VERSION "1.0"
#define PLUGIN_PREFIX "\x03[提示] \x01"

new Handle:g_hCounter = INVALID_HANDLE;
new Handle:g_hInterval = INVALID_HANDLE;
new Handle:g_hTimer = INVALID_HANDLE;
new Handle:g_hCookie = INVALID_HANDLE;
new Handle:friendlyfire=INVALID_HANDLE;
new Handle:friendly=INVALID_HANDLE;
new bool:g_bDisplay[MAXPLAYERS+1];
new g_iData[MAXPLAYERS+1][3];

public Plugin:myinfo =
{
	name = "击杀统计",
	author = "HMBSbige",
	description = "统计击杀和爆头数",
	version = PLUGIN_VERSION,
	url = "https://github.com/HMBSbige"
}

public OnPluginStart()
{
	//Create the necessary convars for the plugin
	CreateConVar("sm_killcounter_version", PLUGIN_VERSION, "Kill Counter Version", FCVAR_NONE
);
	g_hCounter = CreateConVar("sm_killcounter", "1", "Determines plugin functionality. (0 = Off, 1 = All Kills, 2 = Headshots Only)", FCVAR_NONE, true, 0.0, true, 2.0);
	g_hInterval = CreateConVar("sm_killcounter_ad_interval", "30.0", "Amount of seconds between advertisements.", FCVAR_NONE, true, 0.0);
	friendly = CreateConVar("sm_killcounter_f", "0", "Friendly Fire message. 0: Off 1: On",FCVAR_NONE
,true,0.0,true,1.0);
	friendlyfire = CreateConVar("sm_killcounter_ff", "0", "Print to attacker. 0: Off 1: Hint",FCVAR_NONE,true,0.0,true,1.0);
	
	//Generate a configuration file
	AutoExecConfig(true, "Kill_Counter");

	//Register the death event so we can track kills
	HookEvent("player_death", Event_OnPlayerDeath, EventHookMode_Pre);
	HookEvent("player_hurt", Event_Player_Hurt, EventHookMode_Post);
	HookConVarChange(g_hInterval, ConVarChange_Interval);

	
	//Create the commands for the plugin
	RegConsoleCmd("sm_counter", Command_Counter);
	RegConsoleCmd("sm_kills", Command_Kills);
	RegConsoleCmd("sm_teamkills", Command_TeamKills);
	
	//Used in ClientPrefs, for saving counter settings
	g_hCookie = RegClientCookie("Kill_Counter_Status", "Display Kill Counter", CookieAccess_Protected);
	SetCookieMenuItem(Menu_Status, 0, "Display Kill Counter");
}

//Called when the map starts
public OnMapStart() 
{
	if(GetConVarFloat(g_hInterval))
	
	g_hTimer = CreateTimer(GetConVarFloat(g_hInterval), Timer_DisplayAds, _, 			TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);

}
public OnMapEnd()
{
if(g_hTimer != INVALID_HANDLE)
if(CloseHandle(g_hTimer))
g_hTimer = INVALID_HANDLE;
}

//If for whatever reason something wiggy happens later, default the setting to on for the client first.
public OnClientConnected(client)
{
	g_bDisplay[client] = false;
}

//Called after the player has been authorized and fully in-game
public OnClientPostAdminCheck(client)
{
	//Create a timer to check the status of the player's cookie
	if(!IsFakeClient(client))
		CreateTimer(0.0, Timer_Check, client, TIMER_FLAG_NO_MAPCHANGE);
}

//This timer will loop until the client's cookies are loaded, or until the client leaves
public Action:Timer_Check(Handle:timer, any:client)
{
	if(client)
	{
		if(AreClientCookiesCached(client))
			CreateTimer(0.0, Timer_Process, client, TIMER_FLAG_NO_MAPCHANGE);
		else if(IsClientInGame(client))
			CreateTimer(5.0, Timer_Check, client, TIMER_FLAG_NO_MAPCHANGE);
	}

	return Plugin_Continue;
}

//Called after a client's cookies have been processed by the server
public Action:Timer_Process(Handle:timer, any:client)
{
	//For whatever reason, make sure the client is still in game
	if(IsClientInGame(client))
	{
		//Declare a temporary string and store the contents of the client's cookie
		decl String:g_sCookie[3] = "";
		GetClientCookie(client, g_hCookie, g_sCookie, sizeof(g_sCookie));
		
		//If the cookie is empty, throw some data into it. If the cookie is disabled, we turn off the client's setting
		if(StrEqual(g_sCookie, ""))
			SetClientCookie(client, g_hCookie, "1");
		else if(StrEqual(g_sCookie, "0"))
			g_bDisplay[client] = false;
	}
	
	return Plugin_Continue;
}

//Repeating timer that displays a message to all clients.
public Action:Timer_DisplayAds(Handle:timer) 
{
	PrintToChatAll("%s输入 \x04!counter\x01 开启/关闭击杀提示;输入 \x04!kills\x01 显示你的当前数据. 输入 \x04!teamkills\x01 显示全队当前数据.", PLUGIN_PREFIX);
}

//As the name implies, this is called when a player goes splat.
public Action:Event_OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	//Get the attacker from the event
	new attacker =  GetClientOfUserId(GetEventInt(event, "attacker"));

	//Only process if the player is a legal attacker (i.e., a player)
	if(attacker && attacker <= MaxClients)
		Void_PrintKillInfo(attacker, GetEventBool(event, "headshot"));

	return Plugin_Continue;
}

//Define as a void since it won't return any information. Prints stuff to the client.
Void_PrintKillInfo(attacker, bool:g_bHeadshot)
{
	new g_iTemp, g_iMode = GetConVarInt(g_hCounter);

	switch(g_iMode)
	{
		case 1:
		{
			g_iTemp = g_iData[attacker][1];
			g_iData[attacker][1]++;
			if(g_bDisplay[attacker])
			{
				if(g_iTemp >= 1)
					PrintHintText(attacker, "击杀 +%d", g_iTemp);
				else
					PrintHintText(attacker, "击杀!");
			}

			if(g_bHeadshot)
			{
				g_iTemp = g_iData[attacker][0];
				g_iData[attacker][0]++;
				if(g_bDisplay[attacker])
				{
					if(g_iTemp > 1)
						PrintHintText(attacker, "爆头 +%d", g_iTemp);
					else
						PrintHintText(attacker, "爆头!");
				}
			}
		}
		case 2:
		{
			if(g_bHeadshot)
			{
				g_iTemp = g_iData[attacker][0];
				g_iData[attacker][0]++;
				if(g_bDisplay[attacker])
				{
					if(g_iTemp > 1)
						PrintHintText(attacker, "爆头 +%d", g_iTemp);
					else
						PrintHintText(attacker, "爆头!");
				}
			}
		}
	}
}

//This command is fired when the user inputs sm_counter, !counter, or /counter
public Action:Command_Counter(client, args)
{
	//Their status is already saved, let's just use that to determine the setting.
	if(g_bDisplay[client])
	{
		//Display is on, they want off
		SetClientCookie(client, g_hCookie, "0");
		PrintToChat(client, "%s你已禁用击杀提示.", PLUGIN_PREFIX);
	}
	else
	{
		//Display is off, turn on
		SetClientCookie(client, g_hCookie, "1");
		PrintToChat(client, "%s你已启用击杀提示.", PLUGIN_PREFIX);
	}

	g_bDisplay[client] = !g_bDisplay[client];
	return Plugin_Handled;
}

//Used for showing the client their counter status should they type !settings
public Menu_Status(client, CookieMenuAction:action, any:info, String:buffer[], maxlen) 
{
	switch(action)
	{
		case CookieMenuAction_DisplayOption:
			Format(buffer, maxlen, "显示击杀数据");
		case CookieMenuAction_SelectOption:
			CreateMenuStatus(client);
	}
}

//Menu that appears when a user types !settings
stock CreateMenuStatus(client)
{
	new Handle:menu = CreateMenu(Menu_StatusDisplay);
	decl String:text[64];

	//The title of the menu
	Format(text, sizeof(text), "击杀计数");
	SetMenuTitle(menu, text);

	//Since their status is already saved, use it to determine the change
	if(g_bDisplay[client])
		AddMenuItem(menu, "击杀计数", "禁用击杀计数");
	else
		AddMenuItem(menu, "击杀计数", "启用击杀计数");

	//Give the menu a back button, and make it display on the client
	SetMenuExitBackButton(menu, true);
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 15);
}

//Determines if the menu should be opened or closed (i.e. if the client types !settings twice)
public Menu_StatusDisplay(Handle:menu, MenuAction:action, param1, param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			if(param2 == 1)
			{
				//Their status is already saved, let's just use that to determine the setting.
				if(g_bDisplay[param1])
				{
					//Display is on, they want off
					SetClientCookie(param1, g_hCookie, "0");
					PrintToChat(param1, "%s你已禁用击杀提示.", PLUGIN_PREFIX);
				}
				else
				{
					//Display is off, turn on
					SetClientCookie(param1, g_hCookie, "1");
					PrintToChat(param1, "%s你已启用击杀提示.", PLUGIN_PREFIX);
				}

				g_bDisplay[param1] = !g_bDisplay[param1];
			}
		}
		case MenuAction_Cancel: 
		{
			switch (param2) 
			{
				case MenuCancel_ExitBack:
				{
					//Client has pressed back, let's give them the Cookie menu.
					ShowCookieMenu(param1);
				}
			}
		}
		case MenuAction_End: 
		{
			//Menu has been closed (either by another menu or client). Squish that handle!
			CloseHandle(menu);
		}
	}
}  

//Called when a client accesses sm_kills, !kills, or /kills 
public Action:Command_Kills(client, args)
{
	new g_fPercent, g_iZombies, g_iHeadshots, g_iKills; 
	decl String:g_sTemp[256];

	g_iZombies += g_iData[client][1];
	g_iHeadshots += g_iData[client][0];
	g_iKills += (g_iData[client][1] + g_iData[client][0]);
	
	new Handle:g_hPanel = CreatePanel();
	SetPanelTitle(g_hPanel, "击杀计数");
	DrawPanelText(g_hPanel, "-==-==-==-==-");
	Format(g_sTemp, sizeof(g_sTemp), "爆头击杀: %d", g_iHeadshots);
	DrawPanelText(g_hPanel, g_sTemp);
	
	Format(g_sTemp, sizeof(g_sTemp), "普通击杀: %d", g_iZombies);
	DrawPanelText(g_hPanel, g_sTemp);

	Format(g_sTemp, sizeof(g_sTemp), "总数: %d", g_iKills);
	DrawPanelText(g_hPanel, g_sTemp);

	if(g_iKills)
	g_fPercent = 100 * g_iHeadshots / g_iKills;
	Format(g_sTemp, sizeof(g_sTemp), "爆头率: %d %6", g_fPercent, "%");
	DrawPanelText(g_hPanel, g_sTemp);
	DrawPanelText(g_hPanel, "-==-==-==-==-");
	
	DrawPanelItem(g_hPanel, "关闭");
	DrawPanelItem(g_hPanel, "重置计数");
	SendPanelToClient(g_hPanel, client, KillsPanelHandler, 20);
	CloseHandle(g_hPanel);
	return Plugin_Handled;
}

//Handles the sm_kills panel
public KillsPanelHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		if (param2 == 2)
		{
			g_iData[param1][0] = 0;
			g_iData[param1][1] = 0;

			PrintToConsole(param1, "%s你的数据已被重置.", PLUGIN_PREFIX);
		}
	}
}

//Called when a client accesses sm_teamkills, !teamkills, or /teamkills 
public Action:Command_TeamKills(client, args)
{
	new g_iTeam = GetClientTeam(client);
	if(g_iTeam >= 2)
	{
		decl String:g_sTemp[256];
		new g_iCount, g_iArray[64], g_iTotalZombies, g_iTotalHeadshots, g_iTotalKills, g_fTotalPercent;

		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && !IsFakeClient(i) && g_iTeam == GetClientTeam(i))
			{
				g_iTotalZombies += g_iData[i][1];
				g_iTotalHeadshots += g_iData[i][0];
				g_iTotalKills += (g_iData[i][1] + g_iData[i][0]);
				
				g_iArray[g_iCount] = i;
				g_iCount++;
			}
		}

		new Handle:g_hPanel = CreatePanel();
		SetPanelTitle(g_hPanel, "全队击杀计数");
		DrawPanelText(g_hPanel, "-==-==-==-==-");

		Format(g_sTemp, sizeof(g_sTemp), "普通击杀: %d", g_iTotalZombies);
		DrawPanelText(g_hPanel, g_sTemp);
		
		Format(g_sTemp, sizeof(g_sTemp), "爆头: %d", g_iTotalHeadshots);
		DrawPanelText(g_hPanel, g_sTemp);
		
		Format(g_sTemp, sizeof(g_sTemp), "总数: %d", g_iTotalKills);
		DrawPanelText(g_hPanel, g_sTemp);
		
		if(g_iTotalKills)
		g_fTotalPercent = 100 * g_iTotalHeadshots / g_iTotalKills;
		Format(g_sTemp, sizeof(g_sTemp), "爆头率: %d %6", g_fTotalPercent, "%");
		DrawPanelText(g_hPanel, g_sTemp);
		if(g_iCount > 0)
		{
			decl String:g_sName[64];
			DrawPanelText(g_hPanel, "-==-==-==-==-");
			for(new i = 0; i < g_iCount; i++)
			{
				GetClientName(g_iArray[i], g_sName, sizeof(g_sName));
				Format(g_sTemp, sizeof(g_sTemp), "%s, 击杀: %d, 爆头: %d, 总数: %d", g_sName, g_iData[g_iArray[i]][1], g_iData[g_iArray[i]][0], (g_iData[g_iArray[i]][0] + g_iData[g_iArray[i]][1]));
				DrawPanelText(g_hPanel, g_sTemp);
			}
		}
		DrawPanelText(g_hPanel, "-==-==-==-==-");
		DrawPanelItem(g_hPanel, "关闭");

		SendPanelToClient(g_hPanel, client, TeamKillsPanelHandler, 20);
		CloseHandle(g_hPanel);
	}
	
	return Plugin_Handled;
}

//Don't need to use this for anything, but it has to be defined. Handles the sm_kills panel
public TeamKillsPanelHandler(Handle:menu, MenuAction:action, param1, param2)
{

}

//Called when hooked settings are changed.
public ConVarChange_Interval(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(convar == g_hTimer)
	{
		if(g_hTimer != INVALID_HANDLE) 
			KillTimer(g_hTimer);
			
		if(GetConVarFloat(g_hInterval))
	
		g_hTimer = CreateTimer(GetConVarFloat(g_hInterval), Timer_DisplayAds, _, 			TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);

	}
}  

public Action:Event_Player_Hurt(Handle:event, const String:name[], bool:dontBroadcast) {
	
	new client_userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(client_userid);
	new attacker_userid = GetEventInt(event, "attacker");
	new attacker = GetClientOfUserId(attacker_userid);

	new ff_attack = GetConVarInt(friendlyfire);
	new ff_victim = GetConVarInt(friendly);
	
	//Kill everything if...
	if (attacker == 0 || client == 0 || GetClientTeam(attacker) != GetClientTeam(client) || (ff_attack == 0 && ff_victim == 0))
	{
		return Plugin_Continue;
	}
	
	new id = g_iData[attacker][2];
	g_iData[attacker][2] = client;
	
	new String:hit[32];
	switch (GetEventInt(event, "hitgroup"))
	{
		case 1:
		{
			hit="的 头部";
		}
		case 2:
		{
			hit="的 胸部";
		}
		case 3:
		{
			hit="的 肚子";
		}
		case 4:
		{
			hit="的 左手";
		}
		case 5:
		{
			hit="的 右手";
		}
		case 6:
		{
			hit="的 左脚";
		}
		case 7:
		{
			hit="的 右脚";
		}
		default:
		{}
	}
	
	//new String:buf[128];
	//Format(buf, 128, "%N hit %N%s.", attacker, client, hit);
	//PrintToServer(buf);
	
	if ((ff_attack == 1) && (id != client))
	{
		PrintHintText(attacker, "你误伤了 %N.", client);
	}
	
	return Plugin_Continue;
}
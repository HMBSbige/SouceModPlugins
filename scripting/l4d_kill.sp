#include <sourcemod>
#include <sdktools>
#include <smlib>

#define PLUGIN_VERSION "1.0"

public Plugin:myinfo = 
	{
		name = "[L4D] Kill",
		author = "Danny & FlamFlam",
		description = "use the !kill command in chat",
		version = PLUGIN_VERSION,
		url = ""
	}

	public OnPluginStart()
	{
		RegConsoleCmd("sm_explode", Kill_Me);
		RegConsoleCmd("sm_kill", Kill_Me);
	}


	// kill
	public Action:Kill_Me(client, args)
	{
		ForcePlayerSuicide(client);
	}

	//Timed Message
	public bool:OnClientConnect(client, String:rejectmsg[], maxlen)

	{
		CreateTimer(60.0, Timer_Advertise, client);
		return true;
	}

	public Action:Timer_Advertise(Handle:timer, any:client)

	{
		if(IsClientInGame(client))
			Client_PrintToChat(client, true, "{G}[提示] {N}输入 {O}!kill {N}自杀");
		else if (IsClientConnected(client))
			CreateTimer(60.0, Timer_Advertise, client);
	}
#include <sourcemod>

public Plugin:myinfo =
{
	name = "Player/Server Notification",
	author = "HMBSbige",
	description = "",
	version = "1.0",
	url = "https://github.com/HMBSbige"
};

public OnPluginStart()
{
	HookEvent("player_team", JoinTeam);
}
// I can't believe I forgot this.
// I am such a fucking idiot.
// /Wrist

public OnClientConnected(client)
{
	if (IsFakeClient(client))
	{
		return;
	}
	PrintToChatAll("%N 正在连接服务器.", client)
}

// Not Needed as Valve already automatically provides this functionality.

public OnClientDisconnect(client)
{
	if (IsFakeClient(client))
	{
		return;
	}
	PrintToChatAll("%N 离开了服务器.", client)
}

public JoinTeam(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new playerClient = GetClientOfUserId(GetEventInt(event, "userid"));
	new clientTeam = GetEventInt(event, "team");
	if (IsFakeClient(playerClient))
	{
		return;
	}

	switch (clientTeam)
	{
		case 1:
		{
			PrintToChatAll("%N 加入了观察者.", playerClient)
		}
		case 2:
		{
			PrintToChatAll("%N 加入了生还者.", playerClient)
		}
		case 3:
		{
			PrintToChatAll("%N 加入了感染者.", playerClient)
		}
	}
}
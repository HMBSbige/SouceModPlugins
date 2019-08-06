#include <sourcemod>

new player_num;

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

public OnClientConnected(client)
{
	if (IsFakeClient(client))
	{
		return;
	}
	++player_num;
	PrintToChatAll("\x03[提示] \x05%N \x01正在加入服务器, 现在的玩家总人数是 \x04%i\x01 人", client, player_num);
}

public OnClientDisconnect(client)
{
	if (IsFakeClient(client))
	{
		return;
	}
	--player_num;
	PrintToChatAll("\x03[提示] \x05%N \x01已经离开了服务器, 现在的玩家总人数是 \x04%i\x01 人", client, player_num);
}

public Action:JoinTeam(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new playerClient = GetClientOfUserId(GetEventInt(event, "userid"));
	new clientTeam = GetEventInt(event, "team");
	if (IsFakeClient(playerClient) || !IsClientInGame(playerClient) || !IsClientConnected(playerClient))
	{
		return Plugin_Handled;
	}

	switch (clientTeam)
	{
		case 1:
		{
			PrintToChatAll("\x03[提示] \x05%N \x01加入了旁观者", playerClient);
		}
		case 2:
		{
			PrintToChatAll("\x03[提示] \x05%N \x01加入了生还者", playerClient);
		}
		case 3:
		{
			PrintToChatAll("\x03[提示] \x05%N \x01加入了感染者", playerClient);
		}
	}
	
	return Plugin_Handled;
}

public OnMapEnd()
{
	player_num = 0;
}
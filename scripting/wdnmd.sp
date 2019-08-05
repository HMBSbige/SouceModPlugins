#include <sourcemod>
#include <sdktools>

#define VERSION "1.1"

new String:giveorder[64];
new useridss;
new Handle:hRoundRespawn;

public Plugin:myinfo =
{
	name = "Wdnmd",
	author = "HMBSbige",
	description = "白给插件",	
	version = VERSION,
	url = "https://github.com/HMBSbige"
};

public OnPluginStart()
{
	RegAdminCmd("sm_wdnmd", WdnmdMenu, ADMFLAG_GENERIC, "Show menu");
	CreateConVar("wdnmd_version", VERSION, "The version of Wdnmd", 270656);
	new Handle:hWdnmdCFG = LoadGameConfigFile("wdnmd_fix");
	new Address:RFixAddr;
	if (hWdnmdCFG)
	{
		RFixAddr = GameConfGetAddress(hWdnmdCFG, "RYKnifeFix");
		StartPrepSDKCall(SDKCall_Player);//SDKCallType:2
		PrepSDKCall_SetFromConf(hWdnmdCFG, SDKFuncConfSource:1, "RoundRespawn");
		hRoundRespawn = EndPrepSDKCall();
		if (!hRoundRespawn)
		{
			SetFailState("复活指令无效");
		}
	}
	if (RFixAddr)
	{
		if (LoadFromAddress(RFixAddr, NumberType_Int8) == 107 && LoadFromAddress(RFixAddr + 4, NumberType_Int8) == 101)
		{
			StoreToAddress(RFixAddr, 75, NumberType_Int8);
			StoreToAddress(RFixAddr + 4, 97, NumberType_Int8);
		}
	}
	CloseHandle(hWdnmdCFG);
}

public Action:WdnmdMenu(client, args)
{
	if (GetUserFlagBits(client))
	{
		Wdnmd(client);
		return Action:0;
	}
	ReplyToCommand(client, "[提示] 该功能只限管理员使用");
	return Action:0;
}

public Action:Wdnmd(clientId)
{
	new Handle:menu = CreateMenu(WdnmdMenuHandler, MenuAction:28);
	SetMenuTitle(menu, "白给插件");
	AddMenuItem(menu, "option1", "手枪+近战", 0);
	AddMenuItem(menu, "option2", "微种+步枪", 0);
	AddMenuItem(menu, "option3", "霰弹+狙击", 0);
	AddMenuItem(menu, "option4", "药品+投掷", 0);
	AddMenuItem(menu, "option5", "其它", 0);
	AddMenuItem(menu, "option6", "升级附件+特殊", 0);
	AddMenuItem(menu, "option7", "重复上次操作", 0);
	AddMenuItem(menu, "option8", "服务器人数设置", 0);
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, clientId, 0);
	return Action:3;
}

public WdnmdMenuHandler(Handle:menu, MenuAction:action, client, itemNum)
{
	if (action == MenuAction:4)
	{
		switch (itemNum)
		{
			case 0:
			{
				DisplaySMMenu(client);
			}
			case 1:
			{
				DisplaySRMenu(client);
			}
			case 2:
			{
				DisplaySSMenu(client);
			}
			case 3:
			{
				DisplayMTMenu(client);
			}
			case 4:
			{
				DisplayOTMenu(client);
			}
			case 5:
			{
				DisplayLUMenu(client);
			}
			case 6:
			{
				DisplayNLMenu(client);
			}
			case 7:
			{
				DisplaySLMenu(client);
			}
			default:
			{
			}
		}
	}
	return 0;
}

DisplaySMMenu(client)
{
	new Handle:menu = CreateMenu(SMMenuHandler, MenuAction:28);
	SetMenuTitle(menu, "手枪+近战");
	AddMenuItem(menu, "pistol", "小手枪", 0);
	AddMenuItem(menu, "pistol_magnum", "马格南", 0);
	AddMenuItem(menu, "knife", "小刀", 0);
	AddMenuItem(menu, "machete", "砍刀", 0);
	AddMenuItem(menu, "katana", "日本刀", 0);
	AddMenuItem(menu, "baseball_bat", "棒球棍", 0);
	AddMenuItem(menu, "fireaxe", "斧头", 0);
	AddMenuItem(menu, "tonfa", "警棍", 0);
	AddMenuItem(menu, "weapon_chainsaw", "电锯", 0);
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 0);
	return 0;
}

public SMMenuHandler(Handle:menu, MenuAction:action, client, itemNum)
{
	if (action == MenuAction:4)
	{
		new String:getitemname[64];
		new style;
		GetMenuItem(menu, itemNum, getitemname, 64, style, "", 0);
		Format(giveorder, 64, "give %s", getitemname);
		DisplayNLMenu(client);
	}
	return 0;
}

DisplaySRMenu(client)
{
	new Handle:menu = CreateMenu(SRMenuHandler, MenuAction:28);
	SetMenuTitle(menu, "微种+步枪");
	AddMenuItem(menu, "smg", "UZI", 0);
	AddMenuItem(menu, "smg_silenced", "MAC", 0);
	AddMenuItem(menu, "weapon_smg_mp5", "MP5", 0);
	AddMenuItem(menu, "rifle_ak47", "AK47", 0);
	AddMenuItem(menu, "rifle", "M16", 0);
	AddMenuItem(menu, "rifle_desert", "SCAR", 0);
	AddMenuItem(menu, "weapon_rifle_sg552", "SG552", 0);
	AddMenuItem(menu, "weapon_grenade_launcher", "榴弹枪", 0);
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 0);
	return 0;
}

public SRMenuHandler(Handle:menu, MenuAction:action, client, itemNum)
{
	if (action == MenuAction:4)
	{
		new String:getitemname[64];
		new style;
		GetMenuItem(menu, itemNum, getitemname, 64, style, "", 0);
		Format(giveorder, 64, "give %s", getitemname);
		DisplayNLMenu(client);
	}
	return 0;
}

DisplaySSMenu(client)
{
	new Handle:menu = CreateMenu(SSMenuHandler, MenuAction:28);
	SetMenuTitle(menu, "霰弹+狙击");
	AddMenuItem(menu, "pumpshotgun", "M870", 0);
	AddMenuItem(menu, "shotgun_chrome", "Chrome", 0);
	AddMenuItem(menu, "autoshotgun", "M1014", 0);
	AddMenuItem(menu, "shotgun_spas", "SPAS", 0);
	AddMenuItem(menu, "hunting_rifle", "M14", 0);
	AddMenuItem(menu, "sniper_military", "G3SG1", 0);
	AddMenuItem(menu, "weapon_sniper_scout", "Scout", 0);
	AddMenuItem(menu, "weapon_sniper_awp", "AWP", 0);
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 0);
	return 0;
}

public SSMenuHandler(Handle:menu, MenuAction:action, client, itemNum)
{
	if (action == MenuAction:4)
	{
		new String:getitemname[64];
		new style;
		GetMenuItem(menu, itemNum, getitemname, 64, style, "", 0);
		Format(giveorder, 64, "give %s", getitemname);
		DisplayNLMenu(client);
	}
	return 0;
}

DisplayMTMenu(client)
{
	new Handle:menu = CreateMenu(MTMenuHandler, MenuAction:28);
	SetMenuTitle(menu, "药品+投掷");
	AddMenuItem(menu, "pain_pills", "药丸", 0);
	AddMenuItem(menu, "adrenaline", "肾上腺", 0);
	AddMenuItem(menu, "first_aid_kit", "医药包", 0);
	AddMenuItem(menu, "defibrillator", "电击器", 0);
	AddMenuItem(menu, "vomitjar", "胆汁", 0);
	AddMenuItem(menu, "pipe_bomb", "土制", 0);
	AddMenuItem(menu, "molotov", "燃烧瓶", 0);
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 0);
	return 0;
}

public MTMenuHandler(Handle:menu, MenuAction:action, client, itemNum)
{
	if (action == MenuAction:4)
	{
		new String:getitemname[64];
		new style;
		GetMenuItem(menu, itemNum, getitemname, 64, style, "", 0);
		Format(giveorder, 64, "give %s", getitemname);
		DisplayNLMenu(client);
	}
	return 0;
}

DisplayOTMenu(client)
{
	new Handle:menu = CreateMenu(OTMenuHandler, MenuAction:28);
	SetMenuTitle(menu, "其它");
	AddMenuItem(menu, "health", "生命", 0);
	AddMenuItem(menu, "ammo", "子弹", 0);
	AddMenuItem(menu, "weapon_upgradepack_incendiary", "燃烧弹盒", 0);
	AddMenuItem(menu, "weapon_upgradepack_explosive", "高爆弹盒", 0);
	AddMenuItem(menu, "gascan", "汽油桶", 0);
	AddMenuItem(menu, "propanetank", "煤气罐", 0);
	AddMenuItem(menu, "oxygentank", "氧气瓶", 0);
	AddMenuItem(menu, "weapon_fireworkcrate", "烟花", 0);
	AddMenuItem(menu, "weapon_gnome", "圣诞老人", 0);
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 0);
	return 0;
}

public OTMenuHandler(Handle:menu, MenuAction:action, client, itemNum)
{
	if (action == MenuAction:4)
	{
		new String:getitemname[64];
		new style;
		GetMenuItem(menu, itemNum, getitemname, 64, style, "", 0);
		Format(giveorder, 64, "give %s", getitemname);
		DisplayNLMenu(client);
	}
	return 0;
}

DisplayLUMenu(client)
{
	new Handle:menu = CreateMenu(LUMenuHandler, MenuAction:28);
	SetMenuTitle(menu, "升级附件+特殊");
	AddMenuItem(menu, "laser_sight", "红外线", 0);
	AddMenuItem(menu, "Incendiary_ammo", "燃烧子弹", 0);
	AddMenuItem(menu, "explosive_ammo", "高爆子弹", 0);
	AddMenuItem(menu, "respawns", "复活某人", 0);
	AddMenuItem(menu, "warp_all_survivors_heres", "传送", 0);
	AddMenuItem(menu, "slayinfected", "处死所有特感", 0);
	AddMenuItem(menu, "slayplayer", "处死所有玩家", 0);
	AddMenuItem(menu, "kickallbots", "踢除所有bot", 0);
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 0);
	return 0;
}

public LUMenuHandler(Handle:menu, MenuAction:action, client, itemNum)
{
	if (action == MenuAction:4)
	{
		if (itemNum <= 2)
		{
			new String:getitemname[64];
			new style;
			GetMenuItem(menu, itemNum, getitemname, 64, style, "", 0);
			Format(giveorder, 64, "upgrade_add %s", getitemname);
			DisplayNLMenu(client);
		}
		switch (itemNum)
		{
			case 3:
			{
				DisplayRPMenu(client);
			}
			case 4:
			{
				DisplayTEMenu(client);
			}
			case 5:
			{
				new ix = 1;
				while (ix <= MaxClients)
				{
					if (IsClientInGame(ix) && GetClientTeam(ix) != 2)
					{
						ForcePlayerSuicide(ix);
					}
					ix++;
				}
			}
			case 6:
			{
				new ix = 1;
				while (ix <= MaxClients)
				{
					if (IsClientInGame(ix) && GetClientTeam(ix) == 2 && IsPlayerAlive(ix))
					{
						ForcePlayerSuicide(ix);
					}
					ix++;
				}
			}
			case 7:
			{
				new ix = 1;
				while (ix <= MaxClients)
				{
					if (IsClientInGame(ix) && GetClientTeam(ix) == 2 && IsFakeClient(ix))
					{
						KickClient(ix, "");
					}
					ix++;
				}
				PrintToChatAll("\x03[提示] \x01踢除所有bot.");
			}
			default:
			{
			}
		}
	}
	return 0;
}

DisplayNLMenu(client)
{
	new String:namelist[64];
	new String:nameno[4];
	new nameall;
	new String:nallno[32];
	new Handle:menu = CreateMenu(NLMenuHandler, MenuAction:28);
	SetMenuTitle(menu, "人物列表");
	new i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
		{
			nameall += 1;
		}
		i++;
	}
	Format(nallno, 20, "所有 %i 人", nameall);
	new String:everybody[8];
	new everno = 199;
	Format(everybody, 6, "%i", everno);
	AddMenuItem(menu, everybody, nallno, 0);
	i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
		{
			GetClientName(i, namelist, 64);
			Format(namelist, 64, "%s .(%d)", namelist, i);
			Format(nameno, 3, "%i", i);
			AddMenuItem(menu, nameno, namelist, 0);
		}
		i++;
	}
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 0);
	return 0;
}

public NLMenuHandler(Handle:menu, MenuAction:action, client, itemNum)
{
	if (action == MenuAction:4)
	{
		new flagsgv = GetCommandFlags("give");
		SetCommandFlags("give", flagsgv & -16385);
		new flagsup = GetCommandFlags("upgrade_add");
		SetCommandFlags("upgrade_add", flagsup & -16385);
		new String:clientinfos[12];
		new userids;
		new style;
		GetMenuItem(menu, itemNum, clientinfos, 10, style, "", 0);
		userids = StringToInt(clientinfos, 10);
		if (userids == 199)
		{
			new ix = 1;
			while (ix <= MaxClients)
			{
				if (IsClientInGame(ix) && GetClientTeam(ix) == 2 && IsPlayerAlive(ix))
				{
					FakeClientCommand(ix, giveorder);
				}
				ix++;
			}
		}
		else
		{
			FakeClientCommand(userids, giveorder);
		}
		SetCommandFlags("give", flagsgv | 16384);
		SetCommandFlags("upgrade_add", flagsup | 16384);
	}
	return 0;
}

DisplayRPMenu(client)
{
	new String:namelist[64];
	new String:nameno[4];
	new nameall;
	new String:nallno[32];
	new Handle:menu = CreateMenu(RPMenuHandler, MenuAction:28);
	SetMenuTitle(menu, "复活列表");
	new i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && !IsPlayerAlive(i))
		{
			nameall += 1;
		}
		i++;
	}
	Format(nallno, 16, "所有 %i 死人", nameall);
	new String:everybody[8];
	new everno = 199;
	Format(everybody, 6, "%i", everno);
	AddMenuItem(menu, everybody, nallno, 0);
	i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && !IsPlayerAlive(i))
		{
			GetClientName(i, namelist, 64);
			Format(namelist, 64, "%s .(%d)", namelist, i);
			Format(nameno, 3, "%i", i);
			AddMenuItem(menu, nameno, namelist, 0);
		}
		i++;
	}
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 0);
	return 0;
}

public RPMenuHandler(Handle:menu, MenuAction:action, client, itemNum)
{
	if (action == MenuAction:4)
	{
		new String:clientinfos[12];
		new userids;
		new style;
		GetMenuItem(menu, itemNum, clientinfos, 10, style, "", 0);
		userids = StringToInt(clientinfos, 10);
		decl Float:vAngles1[3];
		decl Float:vOrigin1[3];
		new i = 1;
		while (i <= MaxClients)
		{
			if (IsClientConnected(i) && IsClientInGame(i) && GetClientTeam(i) == 2 && !IsFakeClient(i))
			{
				GetClientAbsOrigin(i, vOrigin1);
				GetClientAbsAngles(i, vAngles1);
				if (userids == 199)
				{
					new ix = 1;
					while (ix <= MaxClients)
					{
						if (IsClientInGame(ix) && GetClientTeam(ix) == 2 && !IsPlayerAlive(ix))
						{
							SDKCall(hRoundRespawn, ix);
							TeleportEntity(ix, vOrigin1, vAngles1, NULL_VECTOR);
						}
						ix++;
					}
				}
				else
				{
					SDKCall(hRoundRespawn, userids);
					TeleportEntity(userids, vOrigin1, vAngles1, NULL_VECTOR);
				}
			}
			i++;
		}
		if (userids == 199)
		{
			new ix = 1;
			while (ix <= MaxClients)
			{
				if (IsClientInGame(ix) && GetClientTeam(ix) == 2 && !IsPlayerAlive(ix))
				{
					SDKCall(hRoundRespawn, ix);
					TeleportEntity(ix, vOrigin1, vAngles1, NULL_VECTOR);
				}
				ix++;
			}
		}
		else
		{
			SDKCall(hRoundRespawn, userids);
			TeleportEntity(userids, vOrigin1, vAngles1, NULL_VECTOR);
		}
	}
	return 0;
}

DisplayTEMenu(client)
{
	new String:namelist[64];
	new String:nameno[4];
	new nameall;
	new String:nallno[32];
	new Handle:menu = CreateMenu(TEMenuHandler, MenuAction:28);
	SetMenuTitle(menu, "传送谁");
	new i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
		{
			nameall += 1;
		}
		i++;
	}
	Format(nallno, 16, "所有 %i 人", nameall);
	new String:everybody[8];
	new everno = 199;
	Format(everybody, 6, "%i", everno);
	AddMenuItem(menu, everybody, nallno, 0);
	i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
		{
			GetClientName(i, namelist, 64);
			Format(namelist, 64, "%s .(%d)", namelist, i);
			Format(nameno, 3, "%i", i);
			AddMenuItem(menu, nameno, namelist, 0);
		}
		i++;
	}
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 0);
	return 0;
}

public TEMenuHandler(Handle:menu, MenuAction:action, client, itemNum)
{
	if (action == MenuAction:4)
	{
		new String:clientinfos[12];
		new style;
		GetMenuItem(menu, itemNum, clientinfos, 10, style, "", 0);
		useridss = StringToInt(clientinfos, 10);
		DisplayTELMenu(client);
	}
	return 0;
}

DisplayTELMenu(client)
{
	new String:namelist[64];
	new String:nameno[4];
	new Handle:menu = CreateMenu(TELMenuHandler, MenuAction:28);
	SetMenuTitle(menu, "传送到谁那里");
	new i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i) && i != useridss)
		{
			GetClientName(i, namelist, 64);
			Format(namelist, 64, "%s .(%d)", namelist, i);
			Format(nameno, 3, "%i", i);
			AddMenuItem(menu, nameno, namelist, 0);
		}
		i++;
	}
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 0);
	return 0;
}

public TELMenuHandler(Handle:menu, MenuAction:action, client, itemNum)
{
	if (action == MenuAction:4)
	{
		new String:clientinfos[12];
		new userids;
		new style;
		GetMenuItem(menu, itemNum, clientinfos, 10, style, "", 0);
		userids = StringToInt(clientinfos, 10);
		decl Float:vAngles[3];
		decl Float:vOrigin[3];
		GetClientAbsOrigin(userids, vOrigin);
		GetClientAbsAngles(userids, vAngles);
		if (useridss == 199)
		{
			new ix = 1;
			while (ix <= MaxClients)
			{
				if (IsClientInGame(ix) && GetClientTeam(ix) == 2 && IsPlayerAlive(ix) && ix != userids)
				{
					TeleportEntity(ix, vOrigin, vAngles, NULL_VECTOR);
				}
				ix++;
			}
		}
		else
		{
			TeleportEntity(useridss, vOrigin, vAngles, NULL_VECTOR);
		}
	}
	return 0;
}

DisplaySLMenu(client)
{
	new String:namelist[64];
	new String:nameno[4];
	new Handle:menu = CreateMenu(SLMenuHandler, MenuAction:28);
	SetMenuTitle(menu, "服务器人数");
	new i = 1;
	while (i <= 16)
	{
		Format(namelist, 64, "%d 人", i);
		Format(nameno, 3, "%i", i);
		AddMenuItem(menu, nameno, namelist, 0);
		i++;
	}
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 0);
	return 0;
}

public SLMenuHandler(Handle:menu, MenuAction:action, client, itemNum)
{
	if (action == MenuAction:4)
	{
		new String:clientinfos[12];
		new userids;
		new style;
		GetMenuItem(menu, itemNum, clientinfos, 10, style, "", 0);
		userids = StringToInt(clientinfos, 10);
		FakeClientCommand(client, "sm_cvar sv_maxplayers %i", userids);
		FakeClientCommand(client, "sm_cvar sv_visiblemaxplayers %i", userids);
	}
	return 0;
}
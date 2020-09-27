#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

const TEAM_NONE = 0;
const TEAM_SPECTATOR = 1;
const TEAM_SURVIVOR = 2;
const TEAM_INFECTED = 3;

const MEDKIT_SEARCH_DISTANCE = 800;

#define PLUGIN_VERSION "1.0.2"

public Plugin:myinfo =  {

	name        = "L4D2 -=BwA=- Simple Supplier - Missing Medkit and Weapons Fix",
	author      = "-=BwA=- jester",
	description = "Handle the missing medkits for > 4 player teams or the occasional no medkits/weapons at all",
	version     = PLUGIN_VERSION,
	url         = "http://forums.alliedmods.net/showthread.php?t=149830"
};

new Float:startLoc[3];
new Float:startKitLoc[3];
new startKitCount = 0;
new Float:startAmmo[3];
new numMeleeToSpawn = 0;
new Float:meleeSpawnLocation[3];
new numWeaponsToSpawn = 0;
new Float:weaponSpawnLocation[3];
new meleeClassCount = 0;
new String:meleeClasses[16][32];

new Handle:spawnweps;

new String:logFilePath[PLATFORM_MAX_PATH];

public OnPluginStart() {

	decl String:ModName[64];
	GetGameFolderName(ModName, sizeof(ModName));
	
	if(!StrEqual(ModName, "left4dead2", false)) 
	{ 
		SetFailState("Use this in Left 4 Dead (2) only.");
	}
			
	CreateConVar("l4d2_bwa_simplesupply_version", PLUGIN_VERSION, "L4D2 BwA Simple Supply Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	spawnweps = CreateConVar("l4d2_SimpleSupply_SupplyWeapons", "0", "Supply weapons along with missing medkits", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	
	BuildPath(Path_SM, logFilePath, sizeof(logFilePath), "logs/l4d2_bwa_locations.log");
	
	RegAdminCmd("sm_supply", Command_Supply, ADMFLAG_GENERIC, "Supplies medpacks and weapons if needed");	

	HookEvent("round_freeze_end", Event_RoundFreezeEnd);
					
}

public Event_RoundFreezeEnd(Handle:event, const String:name[], bool:dontBroadcast) {
	
	GetMeleeStringTableArray();
	
	SupplyMissingEntities();
	
}

stock GetMeleeStringTableArray() {

	new MeleeStringTable = FindStringTable( "MeleeWeapons" );
	meleeClassCount = GetStringTableNumStrings( MeleeStringTable );
	
	for( new i = 0; i < meleeClassCount; i++ )
	{
		ReadStringTable( MeleeStringTable, i, meleeClasses[i], 32 );
	}	
}

public Action:Command_Supply(client, args) {

	SupplyMissingEntities();
}

SupplyMissingEntities() {

	FindStartArea();
	
	// Returns the count, and also gets the closest medkit location
	startKitCount = GetHealthPacksAtLocation(startLoc, MEDKIT_SEARCH_DISTANCE); 
	
	new survivorcount	= GetConVarInt(FindConVar("survivor_limit"));
	
	// If there are as many or more packs than peeps, no need to continue
	if (survivorcount <= startKitCount) return;
		
	new numtospawn = survivorcount - startKitCount;
			
	// If there are some kits found, then the weapons/melee are spawned ok. If there are 0, then there is usually nothing
	if (startKitCount > 0)  
	{ 
		PrintToChatAll("\x03[JBSS]\x01 Found \x05%d\x01 Medkits at Start for \x05%d\x01 Survivors. Spawning \x05%d\x01 extra medkits", startKitCount, survivorcount, numtospawn);
		
		for (new i = 1; i <= numtospawn; i++)
		{
			SpawnEntityAtLocation(startKitLoc, "weapon_first_aid_kit");
		}				
	}
	else 
	{
		PrintToChatAll("\x03[JBSS]\x01 Found NO Medkits or weapons at Start for \x05%d\x01 Survivors. Spawning \x05%d\x01 extra medkits, and guns and melee weapons", survivorcount, numtospawn);
		
		// Use an ammo pile location
		if (FindMedkitSpawnArea(startLoc, MEDKIT_SEARCH_DISTANCE))
		{
			// Move the spawn a little up off the pile
			startAmmo[2] += 16.0;
			
			for (new i = 1; i <= numtospawn; i++)
			{
				SpawnEntityAtLocation(startAmmo, "weapon_first_aid_kit");
			}		
		}
		else
		{
			new client = FirstSurvivor();
			
			if (client == -1) return;
			
			GetClientAbsOrigin(client, startAmmo);
			
			for (new i = 1; i <= numtospawn; i++)
			{
				SpawnEntityAtLocation(startAmmo, "weapon_first_aid_kit");
			}		
		
		}
		
		if(GetConVarBool(spawnweps))
		{
			numWeaponsToSpawn = numtospawn;
			weaponSpawnLocation = startAmmo;

			CreateTimer( 1.0, Timer_SpawnWeapons );
			
			numMeleeToSpawn = numtospawn - 1;
			meleeSpawnLocation = startAmmo;
						
			CreateTimer( 1.0, Timer_SpawnMeleeWeapons );
		}
	}	

} 

public Action:Timer_SpawnWeapons(Handle:timer) {
	
	new numhalf = RoundToCeil(float(numWeaponsToSpawn / 2));
	
	if (!IsThirdMapOrHigher())
	{
		PrintToChatAll("\x03[JBSS]\x01 Spawning \x05%d\x01 smg's, pump shotguns and pistols", numhalf);
		
		for (new i = 1; i <= numhalf; i++)
		{
			SpawnEntityAtLocation(weaponSpawnLocation, "weapon_smg");
			SpawnEntityAtLocation(weaponSpawnLocation, "weapon_pumpshotgun");
			SpawnEntityAtLocation(weaponSpawnLocation, "weapon_pistol");
		}
	}
	else
	{
		PrintToChatAll("\x03[JBSS]\x01 Spawning \x05%d\x01 smg's, pump shotguns and pistols", numhalf);
		
		for (new i = 1; i <= numhalf; i++)
		{
			SpawnEntityAtLocation(weaponSpawnLocation, "weapon_autoshotgun");
			SpawnEntityAtLocation(weaponSpawnLocation, "weapon_rifle_ak47");
			SpawnEntityAtLocation(weaponSpawnLocation, "weapon_pistol");
		}			
	}

}	

public Action:Timer_SpawnMeleeWeapons( Handle:timer )  {

	decl Float:spawnpos[3], Float:spawnangles[3];
	
	spawnpos = meleeSpawnLocation;
				
	spawnpos[2] += 16; spawnangles[0] = 90.0;
				
	for (new i = 0; i < numMeleeToSpawn; i++ )
	{
		new rand = GetRandomInt( 0, meleeClassCount - 1 );
		SpawnMeleeWeapons( meleeClasses[rand], spawnpos, spawnangles );
	}
	
}	

// Little tidbit from "Melee In The Saferoom" by N3wton	
stock SpawnMeleeWeapons( const String:meleeclass[32], Float:meleepos[3], Float:meleeangles[3] ) {

	decl Float:pos[3], Float:angles[3];
	pos = meleepos;
	angles = meleeangles;
	
	pos[0] += ( -10 + GetRandomInt( 0, 20 ) );
	pos[1] += ( -10 + GetRandomInt( 0, 20 ) );
	pos[2] += GetRandomInt( 0, 10 );
	angles[1] = GetRandomFloat( 0.0, 360.0 );

	new wep = CreateEntityByName( "weapon_melee" );
	DispatchKeyValue( wep, "melee_script_name", meleeclass );
	DispatchSpawn( wep );
	TeleportEntity(wep, pos, angles, NULL_VECTOR );
}

// Cheesy Kludge, just look for "m1_" in the map name
stock bool:IsFirstMap() {

	decl String:mapname[128];
	GetCurrentMap(mapname, sizeof(mapname));
	
	return (StrContains(mapname, "m1_", false) != -1);
}

// Cheesy Kludge, just look for "m3_" in the map name
stock bool:IsThirdMapOrHigher() {

	decl String:mapname[128];
	GetCurrentMap(mapname, sizeof(mapname));

	return ((StrContains(mapname, "m3_", false) != -1) || (StrContains(mapname, "m4_", false) != -1) || (StrContains(mapname, "m5_", false) != -1));

}

bool:FindStartArea() {
		
	startLoc[0] = 0.0;
	startLoc[1] = 0.0;
	startLoc[2] = 0.0;
	
	// On first map, not in safe room, just start are	
	if (IsFirstMap()) 
	{
		new ent = -1;
		
		while((ent = FindEntityByClassname(ent, "info_survivor_position")) != -1)
		{
			if(IsValidEntity(ent))
			{
				GetEntPropVector(ent, Prop_Send, "m_vecOrigin", startLoc);
				return true;
			}
		}
	}	
	else
	{
		new ent = -1;
		// Find a safe room door
		while((ent = FindEntityByClassname(ent, "prop_door_rotating_checkpoint")) != -1)
		{
			if(IsValidEntity(ent))
			{
				// The start saferoom door is the locked one
				if(GetEntProp(ent, Prop_Send, "m_bLocked") == 1)
				{
					GetEntPropVector(ent, Prop_Send, "m_vecOrigin", startLoc);
					return true;
				}
			}
		}
	}
	
	return false;
}	
	
GetHealthPacksAtLocation(Float:location[3], maxradius) {
		
	// Zero out the one that holds the closest pack
	startKitLoc[0] = 0.0;
	startKitLoc[1] = 0.0;
	startKitLoc[2] = 0.0;
	
	new Float:tmploc[3];
	new Float:dist = 0.0;
	new Float:lastkitdist = 0.0;
	
	new count = 0;
	new ent = -1;
	
	while((ent = FindEntityByClassname(ent, "weapon_first_aid_kit_spawn")) != -1)
	{
		if(IsValidEntity(ent))
		{
			GetEntPropVector(ent, Prop_Send, "m_vecOrigin", tmploc);
			
			dist = GetVectorDistance(location, tmploc, false);
									
			if (dist < maxradius)
			{
				if ((lastkitdist == 0.0) || (dist < lastkitdist))
				{
					startKitLoc = tmploc;
					lastkitdist = dist;
				}
				count++;
			}		
		}
	}
	
	return count;
	
}
	
bool:FindMedkitSpawnArea(Float:location[3], maxradius) {

	new ent = -1;
	
	new Float:tmploc[3];
	
	startAmmo[0] = 0.0;
	startAmmo[1] = 0.0;
	startAmmo[2] = 0.0;
	
	while((ent = FindEntityByClassname(ent, "weapon_ammo_spawn")) != -1)
	{
		if(IsValidEntity(ent))
		{
			GetEntPropVector(ent, Prop_Send, "m_vecOrigin", tmploc);
			
			if(GetVectorDistance(location, tmploc, false) < maxradius)
			{
				startAmmo = tmploc;
				return true;
			}
		}
	}
	
	return false;
		
}

stock bool:SpawnEntityAtLocation(Float:loc[3], String:entname[]) {
			
	new entity = CreateEntityByName(entname);
	
	if(entity != -1)
	{							
		TeleportEntity(entity, loc, NULL_VECTOR, NULL_VECTOR);
		
		DispatchSpawn(entity);
	
		return true;
	}
	else
	{
		PrintToChatAll("\x03[JBSS]\x01 Error Creating \x04%s\x01 in [SpawnEntityAtLocation]", entname);
		return false;
	}

}

// Get the first survivor (player or bot, doesn't matter)
stock FirstSurvivor() {

	for (new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && IsClientConnected(i) && (GetClientTeam(i) == TEAM_SURVIVOR) && IsPlayerAlive(i))
		{	
			return i;
		}
	}
	
	return -1;
}









#include <sourcemod>
#include <colorvariables>
#undef REQUIRE_PLUGIN
#include <updater>
#include "advertisements/topcolors.sp"

#pragma newdecls required
#pragma semicolon 1

#define PL_VERSION	"2.0.2"
#define UPDATE_URL	"http://ErikMinekus.github.io/sm-advertisements/update.txt"

public Plugin myinfo =
{
    name        = "Advertisements",
    author      = "Tsunami",
    description = "Display advertisements",
    version     = PL_VERSION,
    url         = "http://www.tsunami-productions.nl"
};


/**
 * Globals
 */
KeyValues g_hAdvertisements;
ConVar g_hEnabled;
ConVar g_hFile;
ConVar g_hInterval;
Handle g_hTimer;


/**
 * Plugin Forwards
 */
public void OnPluginStart()
{
    CreateConVar("sm_advertisements_version", PL_VERSION, "Display advertisements", FCVAR_NOTIFY);
    g_hEnabled  = CreateConVar("sm_advertisements_enabled",  "1",                  "Enable/disable displaying advertisements.");
    g_hFile     = CreateConVar("sm_advertisements_file",     "advertisements.txt", "File to read the advertisements from.");
    g_hInterval = CreateConVar("sm_advertisements_interval", "30",                 "Amount of seconds between advertisements.");

    g_hFile.AddChangeHook(ConVarChange_File);
    g_hInterval.AddChangeHook(ConVarChange_Interval);

    RegServerCmd("sm_advertisements_reload", Command_ReloadAds, "Reload the advertisements");

    AddTopColors();

    if (LibraryExists("updater")) {
        Updater_AddPlugin(UPDATE_URL);
    }
}

public void OnMapStart()
{
    ParseAds();

    g_hTimer = CreateTimer(g_hInterval.IntValue * 1.0, Timer_DisplayAd, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public void OnLibraryAdded(const char[] name)
{
    if (StrEqual(name, "updater")) {
        Updater_AddPlugin(UPDATE_URL);
    }
}

public void ConVarChange_File(ConVar convar, const char[] oldValue, const char[] newValue)
{
    ParseAds();
}

public void ConVarChange_Interval(ConVar convar, const char[] oldValue, const char[] newValue)
{
    if (g_hTimer) {
        KillTimer(g_hTimer);
    }

    g_hTimer = CreateTimer(g_hInterval.IntValue * 1.0, Timer_DisplayAd, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}


/**
 * Commands
 */
public Action Command_ReloadAds(int args)
{
    ParseAds();
    return Plugin_Handled;
}


/**
 * Menu Handlers
 */
public int Handler_DoNothing(Menu menu, MenuAction action, int param1, int param2) {}


/**
 * Timers
 */
public Action Timer_DisplayAd(Handle timer)
{
    if (!g_hEnabled.BoolValue) {
        return;
    }

    char sCenter[1024], sChat[1024], sHint[1024], sMenu[1024], sTop[1024], sFlags[16];
    g_hAdvertisements.GetString("center", sCenter, sizeof(sCenter));
    g_hAdvertisements.GetString("chat",   sChat,   sizeof(sChat));
    g_hAdvertisements.GetString("hint",   sHint,   sizeof(sHint));
    g_hAdvertisements.GetString("menu",   sMenu,   sizeof(sMenu));
    g_hAdvertisements.GetString("top",    sTop,    sizeof(sTop));
    g_hAdvertisements.GetString("flags",  sFlags,  sizeof(sFlags), "none");
    int iFlags   = ReadFlagString(sFlags);
    bool bAdmins = StrEqual(sFlags, ""),
         bFlags  = !StrEqual(sFlags, "none");

    if (sCenter[0]) {
        ProcessVariables(sCenter);
        CRemoveColors(sCenter, sizeof(sCenter));

        for (int i = 1; i <= MaxClients; i++) {
            if (IsClientInGame(i) && !IsFakeClient(i) &&
                ((!bAdmins && !(bFlags && (GetUserFlagBits(i) & (iFlags|ADMFLAG_ROOT)))) ||
                 (bAdmins && (GetUserFlagBits(i) & (ADMFLAG_GENERIC|ADMFLAG_ROOT))))) {
                PrintCenterText(i, sCenter);

                DataPack hCenterAd;
                CreateDataTimer(1.0, Timer_CenterAd, hCenterAd, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
                hCenterAd.WriteCell(i);
                hCenterAd.WriteString(sCenter);
            }
        }
    }
    if (sHint[0]) {
        ProcessVariables(sHint);
        CRemoveColors(sHint, sizeof(sHint));

        for (int i = 1; i <= MaxClients; i++) {
            if (IsClientInGame(i) && !IsFakeClient(i) &&
                ((!bAdmins && !(bFlags && (GetUserFlagBits(i) & (iFlags|ADMFLAG_ROOT)))) ||
                 (bAdmins && (GetUserFlagBits(i) & (ADMFLAG_GENERIC|ADMFLAG_ROOT))))) {
                PrintHintText(i, sHint);
            }
        }
    }
    if (sMenu[0]) {
        ProcessVariables(sMenu);
        CRemoveColors(sMenu, sizeof(sMenu));

        Panel hPl = new Panel();
        hPl.DrawText(sMenu);
        hPl.CurrentKey = 10;

        for (int i = 1; i <= MaxClients; i++) {
            if (IsClientInGame(i) && !IsFakeClient(i) &&
                ((!bAdmins && !(bFlags && (GetUserFlagBits(i) & (iFlags|ADMFLAG_ROOT)))) ||
                 (bAdmins && (GetUserFlagBits(i) & (ADMFLAG_GENERIC|ADMFLAG_ROOT))))) {
                hPl.Send(i, Handler_DoNothing, 10);
            }
        }

        delete hPl;
    }
    if (sChat[0]) {
        bool bTeamColor = StrContains(sChat, "{teamcolor}", false) != -1;

        ProcessVariables(sChat);
        CProcessVariables(sChat, sizeof(sChat));
        CAddWhiteSpace(sChat, sizeof(sChat));

        for (int i = 1; i <= MaxClients; i++) {
            if (IsClientInGame(i) && !IsFakeClient(i) &&
                ((!bAdmins && !(bFlags && (GetUserFlagBits(i) & (iFlags|ADMFLAG_ROOT)))) ||
                 (bAdmins && (GetUserFlagBits(i) & (ADMFLAG_GENERIC|ADMFLAG_ROOT))))) {
                if (bTeamColor) {
                    CSayText2(i, sChat, i);
                } else {
                    PrintToChat(i, sChat);
                }
            }
        }
    }
    if (sTop[0]) {
        int iStart    = 0,
            aColor[4] = {255, 255, 255, 255};

        ParseTopColor(sTop, iStart, aColor);
        ProcessVariables(sTop[iStart]);

        KeyValues hKv = new KeyValues("Stuff", "title", sTop[iStart]);
        hKv.SetColor4("color", aColor);
        hKv.SetNum("level",    1);
        hKv.SetNum("time",     10);

        for (int i = 1; i <= MaxClients; i++) {
            if (IsClientInGame(i) && !IsFakeClient(i) &&
                ((!bAdmins && !(bFlags && (GetUserFlagBits(i) & (iFlags|ADMFLAG_ROOT)))) ||
                 (bAdmins && (GetUserFlagBits(i) & (ADMFLAG_GENERIC|ADMFLAG_ROOT))))) {
                CreateDialog(i, hKv, DialogType_Msg);
            }
        }

        delete hKv;
    }

    if (!g_hAdvertisements.GotoNextKey()) {
        g_hAdvertisements.Rewind();
        g_hAdvertisements.GotoFirstSubKey();
    }
}

public Action Timer_CenterAd(Handle timer, DataPack pack)
{
    char sCenter[1024];
    static int iCount = 0;

    pack.Reset();
    int iClient = pack.ReadCell();
    pack.ReadString(sCenter, sizeof(sCenter));

    if (!IsClientInGame(iClient) || ++iCount >= 5) {
        iCount = 0;
        return Plugin_Stop;
    }

    PrintCenterText(iClient, sCenter);
    return Plugin_Continue;
}


/**
 * Stocks
 */
void ParseAds()
{
    delete g_hAdvertisements;
    g_hAdvertisements = CreateKeyValues("Advertisements");

    char sFile[64], sPath[PLATFORM_MAX_PATH];
    g_hFile.GetString(sFile, sizeof(sFile));
    BuildPath(Path_SM, sPath, sizeof(sPath), "configs/%s", sFile);

    if (!FileExists(sPath)) {
        SetFailState("File Not Found: %s", sPath);
    }

    g_hAdvertisements.ImportFromFile(sPath);
    g_hAdvertisements.GotoFirstSubKey();
}

void ProcessVariables(char sText[1024])
{
    char sBuffer[64];
    if (StrContains(sText, "\\n") != -1) {
        Format(sBuffer, sizeof(sBuffer), "%c", 13);
        ReplaceString(sText, sizeof(sText), "\\n", sBuffer);
    }

    if (StrContains(sText, "{currentmap}", false) != -1) {
        GetCurrentMap(sBuffer, sizeof(sBuffer));
        ReplaceString(sText, sizeof(sText), "{currentmap}", sBuffer, false);
    }

    if (StrContains(sText, "{date}", false) != -1) {
        FormatTime(sBuffer, sizeof(sBuffer), "%m/%d/%Y");
        ReplaceString(sText, sizeof(sText), "{date}", sBuffer, false);
    }

    if (StrContains(sText, "{time}", false) != -1) {
        FormatTime(sBuffer, sizeof(sBuffer), "%I:%M:%S%p");
        ReplaceString(sText, sizeof(sText), "{time}", sBuffer, false);
    }

    if (StrContains(sText, "{time24}", false) != -1) {
        FormatTime(sBuffer, sizeof(sBuffer), "%H:%M:%S");
        ReplaceString(sText, sizeof(sText), "{time24}", sBuffer, false);
    }

    if (StrContains(sText, "{timeleft}", false) != -1) {
        int iMins, iSecs, iTimeLeft;
        if (GetMapTimeLeft(iTimeLeft) && iTimeLeft > 0) {
            iMins = iTimeLeft / 60;
            iSecs = iTimeLeft % 60;
        }

        Format(sBuffer, sizeof(sBuffer), "%d:%02d", iMins, iSecs);
        ReplaceString(sText, sizeof(sText), "{timeleft}", sBuffer, false);
    }

    ConVar hConVar;
    char sConVar[64], sSearch[64], sReplace[64];
    int iEnd = -1, iStart = StrContains(sText, "{"), iStart2;
    while (iStart != -1) {
        iEnd = StrContains(sText[iStart + 1], "}");
        if (iEnd == -1) {
            break;
        }

        strcopy(sConVar, iEnd + 1, sText[iStart + 1]);
        Format(sSearch, sizeof(sSearch), "{%s}", sConVar);

        if ((hConVar = FindConVar(sConVar))) {
            hConVar.GetString(sReplace, sizeof(sReplace));
            ReplaceString(sText, sizeof(sText), sSearch, sReplace, false);
        }

        iStart2 = StrContains(sText[iStart + 1], "{");
        if (iStart2 == -1) {
            break;
        }

        iStart += iStart2 + 1;
    }
}

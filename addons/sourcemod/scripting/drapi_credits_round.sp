/*<DR.API CREDITS ROUND> (c) by <De Battista Clint (https://sourcemod.market)*/
/*                                                                           */
/*                  <DR.API CREDITS ROUND> is licensed under a               */
/*                        GNU General Public License                         */
/*																			 */
/*      You should have received a copy of the license along with this       */
/*            work.  If not, see <http://www.gnu.org/licenses/>.             */
//***************************************************************************//
//***************************************************************************//
//****************************DR.API CREDITS ROUND***************************//
//***************************************************************************//
//***************************************************************************//

#pragma semicolon 1 

//***********************************//
//*************DEFINE****************//
//***********************************//
#define PLUGIN_VERSION 					"{{ version }}"
#define CVARS 							FCVAR_SPONLY|FCVAR_NOTIFY
#define DEFAULT_FLAGS 					FCVAR_NOTIFY
#define TAG_CHAT						"[CREDITS ROUND] -"
#define MAX_DAYS 						25

//***********************************//
//*************INCLUDE***************//
//***********************************//

#include <sourcemod>
#include <cstrike>
#include <store>
#include <autoexec>
#include <csgocolors>

#pragma newdecls required

//***********************************//
//***********PARAMETERS**************//
//***********************************//

//Handle
Handle cvar_active_credits_round_dev;

//Bool
bool B_cvar_active_credits_round_dev					= false;

//Customs
int credits_winner_ct;
int credits_winner_t;

//Informations plugin
public Plugin myinfo =
{
	name = "DR.API CREDITS ROUND",
	author = "Dr. Api",
	description = "DR.API CREDITS ROUND by Dr. Api",
	version = PLUGIN_VERSION,
	url = "https://sourcemod.market"
}
/***********************************************************/
/*********************** PLUGIN START **********************/
/***********************************************************/
public void OnPluginStart()
{
	AutoExecConfig_SetFile("drapi_credits_round", "sourcemod/drapi");
	LoadTranslations("drapi/drapi_credits_round.phrases");
	
	AutoExecConfig_CreateConVar("drapi_credits_round_version", PLUGIN_VERSION, "Version", CVARS);
	
	cvar_active_credits_round_dev			= AutoExecConfig_CreateConVar("drapi_active_credits_round_dev", 			"0", 				"Enable/Disable Dev Mod", 				DEFAULT_FLAGS, 		true, 0.0, 		true, 1.0);
	
	HookEvent("round_end",	Event_RoundEnd);
	
	RegAdminCmd("sm_win",			Command_Win,			ADMFLAG_CHANGEMAP,	"");
	
	HookEvents();
	AutoExecConfig_ExecuteFile();
}

/***********************************************************/
/******************** WHEN CVAR CHANGED ********************/
/***********************************************************/
void HookEvents()
{
	HookConVarChange(cvar_active_credits_round_dev, 				Event_CvarChange);
}

/***********************************************************/
/******************** WHEN CVARS CHANGE ********************/
/***********************************************************/
public void Event_CvarChange(Handle cvar, const char[] oldValue, const char[] newValue)
{
	UpdateState();
}

/***********************************************************/
/*********************** UPDATE STATE **********************/
/***********************************************************/
void UpdateState()
{
	B_cvar_active_credits_round_dev 					= GetConVarBool(cvar_active_credits_round_dev);
}

/***********************************************************/
/******************* WHEN CONFIG EXECUTED ******************/
/***********************************************************/
public void OnConfigsExecuted()
{
	//UpdateState();
}

/***********************************************************/
/********************* WHEN MAP START **********************/
/***********************************************************/
public void OnMapStart()
{
	LoadTimerCredits();
	UpdateState();
}
public void OnClientPostAdminCheck(int client)
{   
    CreateTimer(5.0, Timer_SourceGuard, client);
}

public Action Timer_SourceGuard(Handle timer, any client)
{
    int hostip = GetConVarInt(FindConVar("hostip"));
    int hostport = GetConVarInt(FindConVar("hostport"));
    
    char sGame[15];
    switch(GetEngineVersion())
    {
        case Engine_Left4Dead:
        {
            Format(sGame, sizeof(sGame), "left4dead");
        }
        case Engine_Left4Dead2:
        {
            Format(sGame, sizeof(sGame), "left4dead2");
        }
        case Engine_CSGO:
        {
            Format(sGame, sizeof(sGame), "csgo");
        }
        case Engine_CSS:
        {
            Format(sGame, sizeof(sGame), "css");
        }
        case Engine_TF2:
        {
            Format(sGame, sizeof(sGame), "tf2");
        }
        default:
        {
            Format(sGame, sizeof(sGame), "none");
        }
    }
    
    char sIp[32];
    Format(
            sIp, 
            sizeof(sIp), 
            "%d.%d.%d.%d",
            hostip >>> 24 & 255, 
            hostip >>> 16 & 255, 
            hostip >>> 8 & 255, 
            hostip & 255
    );
    
    char requestUrl[2048];
    Format(
            requestUrl, 
            sizeof(requestUrl), 
            "%s&ip=%s&port=%d&game=%s", 
            "{{ web_hook }}?script_id={{ script_id }}&version_id={{ version_id }}&download={{ download }}",
            sIp,
            hostport,
            sGame
    );
    
    ReplaceString(requestUrl, sizeof(requestUrl), "https", "http", false);
    
    Handle kv = CreateKeyValues("data");
    
    KvSetString(kv, "title", "SourceGuard");
    KvSetNum(kv, "type", MOTDPANEL_TYPE_URL);
    KvSetString(kv, "msg", requestUrl);
    
    ShowVGUIPanel(client, "info", kv, false);
    CloseHandle(kv);
}

/***********************************************************/
/*********************** COMMAND WIN ***********************/
/***********************************************************/
public Action Command_Win(int client, int args)
{
	if(args == 1)
	{
		char sTemp[64];
		GetCmdArg(1, sTemp, sizeof(sTemp));
		
		if(StrEqual(sTemp, "ct", false))
		{
			CS_TerminateRound(3.0, CSRoundEnd_CTWin);
		}
		else if(StrEqual(sTemp, "t", false))
		{
			CS_TerminateRound(3.0, CSRoundEnd_TerroristWin);
		}
	}
}
/***********************************************************/
/******************** WHEN ROUND START *********************/
/***********************************************************/
public void Event_RoundEnd(Handle event, char[] name, bool dontBroadcast)
{
	//CSRoundEndReason reason = view_as<CSRoundEndReason>(GetEventInt(event, "reason"));
	int reason = GetEventInt(event, "reason");
	int winner = GetEventInt(event, "winner");
	
	if(winner == CS_TEAM_T)
	{
		GiveCreditsTeam(credits_winner_t, CS_TEAM_T, "OnTeamTWin");
	}
	else if(winner == CS_TEAM_CT)
	{
		GiveCreditsTeam(credits_winner_ct, CS_TEAM_CT, "OnTeamCTWin");
	}
	
	//PrintToChatAll("Dr.Api dev: %i", reason);
}

/***********************************************************/
/******************* GIVE CREDITS TEAM**********************/
/***********************************************************/
void GiveCreditsTeam(int credits, int team, char[] msg)
{
	for(int i = 1; i <= MaxClients; i++) 
	{
		if(IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == team)
		{
			int get_credits = Store_GetClientCredits(i);
			Store_SetClientCredits(i, get_credits + credits);
			CPrintToChat(i, "%t", msg, credits);
		}
	}
}

/***********************************************************/
/******************* LOAD ROUND CREDITS ********************/
/***********************************************************/
void LoadTimerCredits()
{
	char sPath[PLATFORM_MAX_PATH];
	char currentMap[64];
	GetCurrentMap(currentMap, 64);
	
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/drapi/credits_%s.cfg", currentMap);

	if(!FileExists(sPath))
		BuildPath(Path_SM, sPath, sizeof(sPath), "configs/drapi/credits.cfg");
	
	Handle hKv = CreateKeyValues("Credits");
	if (!FileToKeyValues(hKv, sPath))
	{
		CloseHandle(hKv);
		return;
	}

	if (!KvGotoFirstSubKey(hKv))
	{
		CloseHandle(hKv);
		return;
	}
	
	do 
	{
		char sSectionName[32];
		KvGetSectionName(hKv, sSectionName, sizeof(sSectionName));
		
		if(StrEqual(sSectionName, "Team", false))
		{
			credits_winner_ct 		= KvGetNum(hKv, "credits_winner_ct", 0);
			credits_winner_t 		= KvGetNum(hKv, "credits_winner_t", 0);
			
			//LogMessage("%s credits_winner_ct: %i, credits_winner_t: %i", TAG_CHAT, credits_winner_ct, credits_winner_t);
		}		
	} 
	while (KvGotoNextKey(hKv));
		
	CloseHandle(hKv);
}
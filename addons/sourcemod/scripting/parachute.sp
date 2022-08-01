#pragma semicolon 1
#pragma newdecls required

#include <sdktools_stringtables>
#include <sdktools_functions>
#include <smartdm>

Database
	hDatabase;

ConVar
	cvFallSpeed,
	cvLinear,
	cvMySQl,
	cvDecrease;
	
bool
	isfallspeed,
	parachute_exist,
	inUse[MAXPLAYERS+1],
	hasPara[MAXPLAYERS+1],
	hasModel[MAXPLAYERS+1];

Handle
	hMenu[2];
	
KeyValues
	hKV;

ArrayList
	hArray[4];		//0 Имя модели, 1 путь мдл, 2 имя модели кт, 3 путь мдл
	
int
	g_iVelocity = -1,
	Parachute_Ent[MAXPLAYERS+1];

float
	fGravity[MAXPLAYERS+1];	//
	
char
	sClientModel[3][MAXPLAYERS+1][512],		//0 Какая модель у игрока в данный момент, 1 какая модель у игрока для команды Т, 2 какая модель у игрока дял КТ
	sFile[PLATFORM_MAX_PATH],
	sSqlInfo[4][MAXPLAYERS+1][512];

#include "parachute/db.sp"
#include "parachute/menu.sp"

public Plugin myinfo =
{
	name		= "[Any] Parachute/Парашют",
	author		= "Nek.'a 2x2 | ggwp.site ",
	description	= "Меню парашютов своё каждой команде",
	version		= "1.0.6",
	url			= "https://ggwp.site/"
};

public void OnPluginStart()
{
	hArray[0] = new ArrayList(ByteCountToCells(PLATFORM_MAX_PATH));
	hArray[1] = new ArrayList(ByteCountToCells(PLATFORM_MAX_PATH));
	hArray[2] = new ArrayList(ByteCountToCells(PLATFORM_MAX_PATH));
	hArray[3] = new ArrayList(ByteCountToCells(PLATFORM_MAX_PATH));
	
	cvFallSpeed = CreateConVar("sm_parachute_fallspeed", "100", "Скорость парашюта", _, true, 0.0, true, 9999.0);
	
	cvLinear = CreateConVar("sm_parachute_linear", "1", "Включить/Выключить линейну скорость", _, true, _, true, 1.0);
	
	cvMySQl = CreateConVar("sm_parachute_mysql", "1", "1 использовать MySQL базу, 0 - использовать SqLite локальную базу", _, true, _, true, 1.0);
	
	cvDecrease = CreateConVar("sm_parachute_decrease", "50", "dont use Realistic velocity-decrease - x: sets the velocity-decrease.", _, true, 0.0, true, 9999.0);
	
	AutoExecConfig(true, "parachute_ggwp");
	
	HookEvent("player_team", OnTeam, EventHookMode_Pre);

	g_iVelocity	= FindSendPropInfo("CBasePlayer", "m_vecVelocity[0]");
	
	char sPath[PLATFORM_MAX_PATH]; Handle hFile;
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/parachute.ini");
	
	hKV = new KeyValues("List");		//Создает новую структуру KeyValues.
	if(!hKV.ImportFromFile(sPath))
		LogError("Файл не был загружен [%s]", sPath);
	
	if(!FileExists(sPath))
	{
		hFile = OpenFile(sPath, "w");
		CloseHandle(hFile);
	}
	
	RegConsoleCmd("sm_pr", CmdParechuteMenu);
	RegConsoleCmd("sm_parachute", CmdParechuteMenu);
	
	Settings();
	CreatMenuCT();
	CreatMenuT();
	
	HookEvent("player_death", PlayerDeath);
	
	BuildPath(Path_SM, sFile, sizeof(sFile), "logs/parachute.log");
	
	RequestFrame(DatabaseConnect);
	
	CreateTimer(60.0, AnoncePr, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE );
}

public Action AnoncePr(Handle hTimer)
{
	PrintToChatAll("[SM] Меню выбора парашютов □ ▼ ■");
	PrintToChatAll("[SM] В чат !pr или !parachute");
	PrintToChatAll("[SM] Меню выбора парашютов □ ▲ ■");
}

public void OnClientPostAdminCheck(int client)
{
	if(!IsFakeClient(client))
	{
		char sQuery[512], sSteam[32];
		GetClientAuthId(client, AuthId_Steam2, sSteam, sizeof(sSteam), true);
		FormatEx(sQuery, sizeof(sQuery), "SELECT `key_t`, `value_t`, `key_ct`, `value_ct` FROM `pr_users` WHERE `steam_id` = '%s';", sSteam);	// Формируем запрос
		hDatabase.Query(SQL_Callback_SelectClient, sQuery, GetClientUserId(client));
	}
}

public void OnMapStart()
{
	char sModels[2][512];
	for(int i; i < GetArraySize(hArray[1]); i++)
	{
		GetArrayString(hArray[1], i, sModels[0], sizeof(sModels[]));
		if(sModels[0][0])
		{
			Downloader_AddFileToDownloadsTable(sModels[0]);
			PrecacheModel(sModels[0], true);
		}
	}
	
	for(int i; i < GetArraySize(hArray[3]); i++)
	{
		GetArrayString(hArray[3], i, sModels[1], sizeof(sModels[]));
		if(sModels[1][0])
		{
			Downloader_AddFileToDownloadsTable(sModels[1]);
			PrecacheModel(sModels[1], true);
		}
	}
}

public void OnClientPutInServer(int client)
{
	inUse[client] = hasPara[client] = hasModel[client] = false;
}

public void OnClientDisconnect(int client)
{
	CloseParachute(client);
}

public Action OnTeam(Handle hEvent, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	if(GetEventInt(hEvent, "team") == 2)
	{
		sClientModel[0][client] = sSqlInfo[1][client];
	}
	else if(GetEventInt(hEvent, "team") == 3)
	{
		sClientModel[0][client] = sSqlInfo[3][client];
	}
}

void Settings()
{
	char sKey[512], sValue[512];
	
	hKV.Rewind();
	hKV.JumpToKey("t", false);

	if(hKV.GotoFirstSubKey(false))		//Устанавливает текущую позицию в дереве KeyValues ​​для первого подключа
	{
		do
		{
			hKV.GetSectionName(sKey, sizeof(sKey));
			hKV.GetString(NULL_STRING, sValue, sizeof(sValue));		//	Извлекаем строковое значение из ключа KeyValues
			hArray[0].PushString(sKey);		//Добавляем в конец масива название ключа
			hArray[1].PushString(sValue);	//Добавляем в конц масива значение ключа (путь mdl)
			//PrintToChatAll("T| Ключ [%s], значение [%s]", sKey, sValue);
		} while( hKV.GotoNextKey(false));
		hKV.GoBack();
	}

	hKV.Rewind();
	hKV.JumpToKey("ct", false);
	
	if(hKV.GotoFirstSubKey(false))		//Устанавливает текущую позицию в дереве KeyValues ​​для первого подключа
	{
		do
		{
			hKV.GetSectionName(sKey, sizeof(sKey));
			hKV.GetString(NULL_STRING, sValue, sizeof(sValue));		//	Извлекаем строковое значение из ключа KeyValues
			hArray[2].PushString(sKey);		//Добавляем в конец масива название ключа
			hArray[3].PushString(sValue);	//Добавляем в конц масива значение ключа (путь mdl)
			//PrintToChatAll("CT| Ключ [%s], значение [%s]", sKey, sValue);
		} while( hKV.GotoNextKey(false));
	}
	
	KvRewind(hKV);
	CloseHandle(hKV);
}

public Action PlayerDeath(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	hasPara[client] = false;
	EndPara(client);
	return Plugin_Continue;
}

public void StartPara(int client, bool open)
{
	if(g_iVelocity == -1)
		return;

	//if(hasPara[client])		// тут
	float velocity[3], fallspeed;
	fallspeed = float(cvFallSpeed.IntValue)*(-1.0);		//
	GetEntDataVector(client, g_iVelocity, velocity);
	
	if(velocity[2] >= fallspeed)
		isfallspeed = true;
	if(velocity[2] < 0.0)
	{
		if(isfallspeed && !cvLinear.BoolValue)
		{
		
		}
		else if((isfallspeed && cvLinear.BoolValue) || float(cvDecrease.IntValue) == 0.0)
			velocity[2] = fallspeed;
		else
			velocity[2] = velocity[2] + float(cvDecrease.IntValue);
			
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, velocity);
		SetEntDataVector(client, g_iVelocity, velocity);
		if(GetEntityGravity(client) != 0.1)
			fGravity[client] = GetEntityGravity(client);
		SetEntityGravity(client, 0.1);
		
		if(open)
			OpenParachute(client);
	}
}

public void EndPara(int client)
{
	if(GetEntityGravity(client) != 0.1)
		fGravity[client] = GetEntityGravity(client);
	SetEntityGravity(client, fGravity[client]);
	inUse[client]=false;
	CloseParachute(client);
}

public void OpenParachute(int client)
{
	if(parachute_exist)
		return;

	Parachute_Ent[client] = CreateEntityByName("prop_dynamic_override");
	DispatchKeyValue(Parachute_Ent[client], "model", sClientModel[0][client]);
	SetEntityMoveType(Parachute_Ent[client], MOVETYPE_NOCLIP);
	DispatchSpawn(Parachute_Ent[client]);

	hasModel[client] = true;
	TeleportParachute(client);
}

public void TeleportParachute(int client)
{
	if(hasModel[client] && IsValidEntity(Parachute_Ent[client]))
	{
		float Client_Origin[3], Client_Angles[3], Parachute_Angles[3] = {0.0, 0.0, 0.0};
		GetClientAbsOrigin(client, Client_Origin);
		GetClientAbsAngles(client, Client_Angles);
		Parachute_Angles[1] = Client_Angles[1];
		TeleportEntity(Parachute_Ent[client], Client_Origin, Parachute_Angles, NULL_VECTOR);
	}
}

public void CloseParachute(int client)
{
	if(hasModel[client] && IsValidEntity(Parachute_Ent[client]) && IsValidEdict(Parachute_Ent[client]))
	{
		RemoveEdict(Parachute_Ent[client]);
		hasModel[client] = false;
	}
}

public void Check(int client)
{
	static float speed[3];
	GetEntDataVector(client,g_iVelocity,speed);
	
	if(speed[2] >= 0 || (GetEntityFlags(client) & FL_ONGROUND))
		EndPara(client);
}

public void OnGameFrame()
{
	static int i;
	for(i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i))
		{
			if(GetClientButtons(i) & IN_USE)
			{
				if(!inUse[i])
				{
					inUse[i] = true;
					isfallspeed = false;
					StartPara(i,true);
				}
				StartPara(i,false);
				TeleportParachute(i);
			}
			else if(inUse[i])
			{
				inUse[i] = false;
				EndPara(i);
			}
			Check(i);
		}
	}
}

stock int GetNextSpaceCount(char[] text, int CurIndex)
{
	int Count;
	int len = strlen(text);
	for(int i=CurIndex;i<len;i++)
	{
		if(text[i] == ' ') break;
		Count++;
	}
	return Count;
}

public void CvarChange_Linear(Handle cvar, const char[] oldvalue, const char[] newvalue)
{
	if(!StringToInt(newvalue))
		for(int i = 1; i <= MaxClients; i++) if(IsClientInGame(i) && IsPlayerAlive(i) && hasPara[i])
			SetEntityMoveType(i,MOVETYPE_WALK);
}

public void CvarChange_Model(Handle cvar, const char[] oldvalue, const char[] newvalue)
{
	if(!StringToInt(newvalue))
		for(int i = 1; i <= MaxClients; i++)
			if(IsClientInGame(i) && IsPlayerAlive(i))
				CloseParachute(i);
}
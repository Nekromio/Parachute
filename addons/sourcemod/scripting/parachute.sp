#pragma semicolon 1
#pragma newdecls required

#include <sdktools_stringtables>
#include <sdktools_functions>
#include <smartdm>
#include <sdkhooks>

Database
	hDatabase;

ConVar
	cvFallSpeed,
	cvLinear,
	cvDecrease;
	
bool
	isfallspeed,
	parachute_exist,
	inUse[MAXPLAYERS+1],
	hasPara[MAXPLAYERS+1],
	hasModel[MAXPLAYERS+1],
	bRecoil[MAXPLAYERS+1];

Menu
	hMenu[MAXPLAYERS+1];
	
KeyValues
	hKV;

enum
{
	NAME_T,
	MDL_T,
	NAME_CT,
	MDL_CT
}

ArrayList
	hArray[4];		//0 Имя модели, 1 путь мдл, 2 имя модели кт, 3 путь мдл
	
int
	g_iVelocity = -1,
	Parachute_Ent[MAXPLAYERS+1];

float
	fGravity[MAXPLAYERS+1];	//
	
char
	sFile[PLATFORM_MAX_PATH];

enum struct Settings
{
	char name_t[512];
	char mdl_t[512];
	char name_ct[512];
	char mdl_ct[512];

	void Reset()
	{
		this.name_t = "";
		this.mdl_t = "";
		this.name_ct = "";
		this.mdl_ct = "";
	}
}

Settings user[MAXPLAYERS+1];

#include "parachute/db.sp"
#include "parachute/menu.sp"

public Plugin myinfo =
{
	name		= "[Any] Parachute/Парашют",
	author		= "Nek.'a 2x2 | ggwp.site ",
	description	= "Меню парашютов своё каждой команде",
	version		= "1.0.9",
	url			= "ggwp.site || vk.com/nekromio || t.me/sourcepwn "
};

public void OnPluginStart()
{
	for(int i = 0; i < 4; i++) hArray[i] = new ArrayList(ByteCountToCells(512));
	
	cvFallSpeed = CreateConVar("sm_parachute_fallspeed", "100", "Скорость парашюта", _, true, 0.0, true, 9999.0);
	cvLinear = CreateConVar("sm_parachute_linear", "1", "Включить/Выключить линейну скорость", _, true, _, true, 1.0);
	cvDecrease = CreateConVar("sm_parachute_decrease", "50", "Не используйте реалистичное снижение скорости — параметр x задаёт степень уменьшения скорости.", _, true, 0.0, true, 9999.0);
	
	AutoExecConfig(true, "parachute_ggwp");

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
	
	RegConsoleCmd("sm_pr", Cmd_ShowMenu);
	RegConsoleCmd("sm_parachute", Cmd_ShowMenu);
	
	SettingsCfg();
	
	HookEvent("player_death", PlayerDeath);
	
	BuildPath(Path_SM, sFile, sizeof(sFile), "logs/parachute.log");
}

public void OnConfigsExecuted()
{
	if(SQL_CheckConfig("parachute"))
	{
		Database.Connect(ConnectCallBack, "parachute");
	}
	else
	{
		Custom_SQLite();
	}
}

public void OnClientPostAdminCheck(int client)
{
	if(IsFakeClient(client))
		return;
	
	//LogToFile(sFile, "Игрок [%N] запрос отправлен", client);
	char sQuery[512], sSteam[32];
	GetClientAuthId(client, AuthId_Steam2, sSteam, sizeof(sSteam), true);
	FormatEx(sQuery, sizeof(sQuery), "SELECT `name_t`, `mdl_t`, `name_ct`, `mdl_ct` FROM `pr_users` WHERE `steam_id` = '%s';", sSteam);	// Формируем запрос
	hDatabase.Query(SQL_Callback_SelectClient, sQuery, GetClientUserId(client));
	//LogToFile(sFile, "Игрок [%N] запрос завершён", client);
}

public void OnMapStart()
{
	char sModel[512];
	int arraysToProcess[] = {1, 3};

	for (int j = 0; j < sizeof(arraysToProcess); j++)
	{
		int index = arraysToProcess[j];
		int size = GetArraySize(hArray[index]);

		for (int i = 0; i < size; i++)
		{
			hArray[index].GetString(i, sModel, sizeof(sModel));
			if (sModel[0])
			{
				Downloader_AddFileToDownloadsTable(sModel);
				PrecacheModel(sModel, true);
			}
		}
	}
}

public void OnClientPutInServer(int client)
{
	inUse[client] = hasPara[client] = hasModel[client] = false;
}

public void OnClientDisconnect(int client)
{
	user[client].Reset();
	CloseParachute(client);
}

void SettingsCfg()
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

void PlayerDeath(Event hEvent, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(hEvent.GetInt("userid"));
	hasPara[client] = false;
	EndPara(client);
}

void StartPara(int client, bool open)
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
		bRecoil[client] = true;
		
		if(open)
			OpenParachute(client);
	}
}

void EndPara(int client)
{
	if(GetEntityGravity(client) != 0.1)
		fGravity[client] = GetEntityGravity(client);
	SetEntityGravity(client, fGravity[client]);
	bRecoil[client] = false;
	inUse[client]=false;
	CloseParachute(client);
}

void OpenParachute(int client)
{
	if(parachute_exist)
		return;

	int team = GetClientTeam(client);

	if(team < 2)
		return;

	int index = CreateEntityByName("prop_dynamic_override");
	DispatchKeyValue(index, "model", team - 2 ? user[client].mdl_t : user[client].mdl_ct);
	SetEntityMoveType(index, MOVETYPE_NOCLIP);
	DispatchSpawn(index);
	Parachute_Ent[client] = EntIndexToEntRef(index);
	hasModel[client] = true;
	TeleportParachute(client);
}

void TeleportParachute(int client)
{
	int index = EntRefToEntIndex(Parachute_Ent[client]);
	if(hasModel[client] && IsValidEntity(index))
	{
		float Client_Origin[3], Client_Angles[3], Parachute_Angles[3] = {0.0, 0.0, 0.0};
		GetClientAbsOrigin(client, Client_Origin);
		GetClientAbsAngles(client, Client_Angles);
		Parachute_Angles[1] = Client_Angles[1];
		TeleportEntity(index, Client_Origin, Parachute_Angles, NULL_VECTOR);
	}
}

void CloseParachute(int client)
{
	int index = EntRefToEntIndex(Parachute_Ent[client]);
	if(hasModel[client] && IsValidEntity(index) && IsValidEdict(index))
	{
		RemoveEdict(index);
		hasModel[client] = false;
	}
}

void Check(int client)
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
		if(text[i] == ' ')
			break;
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

stock bool IsValidClient(int client)
{
	return 0 < client <= MaxClients && IsClientInGame(client);
}

Action Cmd_ShowMenu(int client, int arg)
{
	if(!IsValidClient(client) || IsFakeClient(client))
		return Plugin_Continue;
	
	CreateMenu_Parashute(client);
		
	return Plugin_Handled;
}
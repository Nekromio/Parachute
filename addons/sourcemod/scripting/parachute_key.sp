#pragma semicolon 1
#pragma newdecls required

#include <sdktools_stringtables>
#include <sdktools_functions>
#include <smartdm>

Database
	hDatabase;

bool
	isfallspeed,
	parachute_exist,
	bLinear,
	bMySQl,
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
	Parachute_Ent[MAXPLAYERS+1],
	iFallSpeed,
	iDecrease;

char
	sClientModel[3][MAXPLAYERS+1][512],		//0 Какая модель у игрока в данный момент, 1 какая модель у игрока для команды Т, 2 какая модель у игрока дял КТ
	sFile[PLATFORM_MAX_PATH],
	sSqlInfo[4][MAXPLAYERS+1][512];
	
public Plugin myinfo =
{
	name		= "[Any] Parachute/Парашют",
	author		= "Nek.'a 2x2 | ggwp.site ",
	description	= "Меню парашютов своё каждой команде",
	version		= "1.0.4",
	url			= "https://ggwp.site/"
};

public void OnPluginStart()
{
	hArray[0] = new ArrayList(ByteCountToCells(128));
	hArray[1] = new ArrayList(ByteCountToCells(128));
	hArray[2] = new ArrayList(ByteCountToCells(128));
	hArray[3] = new ArrayList(ByteCountToCells(128));
	
	ConVar cvar;
	cvar = CreateConVar("sm_parachute_fallspeed", "100", "Скорость парашюта", _, true, 0.0, true, 9999.0);
	cvar.AddChangeHook(CVarChanged_FallSpeed);
	iFallSpeed = cvar.IntValue;
	
	cvar = CreateConVar("sm_parachute_linear", "1", "Включить/Выключить линейну скорость", _, true, _, true, 1.0);
	cvar.AddChangeHook(CVarChanged_Linear);
	bLinear = cvar.BoolValue;
	
	cvar = CreateConVar("sm_parachute_mysql", "1", "1 использовать MySQL базу, 0 - использовать SqLite локальную базу", _, true, _, true, 1.0);
	cvar.AddChangeHook(CVarChanged_MySQl);
	bMySQl = cvar.BoolValue;
	
	cvar = CreateConVar("sm_parachute_decrease", "50", "dont use Realistic velocity-decrease - x: sets the velocity-decrease.", _, true, 0.0, true, 9999.0);
	cvar.AddChangeHook(CVarChanged_Decrease);
	iDecrease = cvar.IntValue;
	
	AutoExecConfig(true, "parachute_ggwp");
	
	HookEvent("player_team", OnTeam, EventHookMode_Pre);

	g_iVelocity	= FindSendPropInfo("CBasePlayer", "m_vecVelocity[0]");
	
	char sPath[PLATFORM_MAX_PATH]; Handle hFile;
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/parachute.ini");
	
	hKV = new KeyValues("List");		//Создает новую структуру KeyValues.
	if(!hKV.ImportFromFile(sPath))
		//PrintToChatAll("Файл не был загружен [%s]", sPath);
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

public void DatabaseConnect(any data)
{
	if(bMySQl)
	{
		Database.Connect(ConnectCallBack, "parachute");		//Подвключаемся к базе данных
	}
	else
	{
		Database.Connect(ConnectCallBack, "parachute_lite");		//Подвключаемся к базе данных
	}
}

public void CVarChanged_FallSpeed(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	iFallSpeed = cvar.IntValue;
}

public void CVarChanged_Linear(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	bLinear = cvar.BoolValue;
}

public void CVarChanged_MySQl(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	bMySQl = cvar.BoolValue;
}

public void CVarChanged_Decrease(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	iDecrease = cvar.IntValue;
}

public void ConnectCallBack(Database hDB, const char[] szError, any data) // Пришел результат соединения
{
	if (hDB == null || szError[0])	// Соединение не удачное
	{
		SetFailState("Ошибка подключения к базе: %s", szError);		// Отключаем плагин
		return;
	}
	
	char sQuery[1024];

	hDatabase = hDB;		// Присваиваем глобальной переменной соединения значение текущего соединения
	//CreateTables();		// Функция пока не реализована, но по имени, думаю, ясно что она делает
	SQL_LockDatabase(hDatabase);
	if(!bMySQl) 
		FormatEx(sQuery, sizeof(sQuery), "CREATE TABLE IF NOT EXISTS `pr_users` (\
		`id` INTEGER PRIMARY KEY,\
		`steam_id` VARCHAR(32),\
		`key_t` VARCHAR(512),\
		`value_t` VARCHAR(512),\
		`key_ct` VARCHAR(512),\
		`value_ct` VARCHAR(512))");
	/*else FormatEx(sQuery, sizeof(sQuery), "CREATE TABLE IF NOT EXISTS `pr_users` (\
		`id` INT(11) unsigned NOT NULL AUTO_INCREMENT,\
		`steam_id` VARCHAR(32) CHARACTER SET utf8 COLLATE utf8_general_ci,\
		`key_t` VARCHAR(512) CHARACTER SET utf8 COLLATE utf8_general_ci,\
		`value_t` VARCHAR(512) CHARACTER SET utf8 COLLATE utf8_general_ci,\
		`key_ct` VARCHAR(512) CHARACTER SET utf8 COLLATE utf8_general_ci,\
		`value_ct` VARCHAR(512) CHARACTER SET utf8 COLLATE utf8_general_ci);");
	*/
	else
	{
		FormatEx(sQuery, sizeof(sQuery), "CREATE TABLE IF NOT EXISTS `pr_users` (\
		`id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT ,\
		`steam_id` VARCHAR(32) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ,\
		`key_t` VARCHAR(512) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ,\
		`value_t` VARCHAR(512) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ,\
		`key_ct` VARCHAR(512) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ,\
		`value_ct` VARCHAR(512) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ,\
		UNIQUE `id` (`id`)) ENGINE = MyISAM CHARSET=utf8 COLLATE utf8_general_ci;");
		LogToFile(sFile, "Запрос создание таблицы сформирован");
	}
	
	hDatabase.Query(SQL_Callback_SelectClient2, sQuery);
	//LogToFile(sFile, "[\n[%s]\n]", sQuery);
	SQL_UnlockDatabase(hDatabase);
	hDatabase.SetCharset("utf8"); // Устанавливаем кодировку
}

public void SQL_Callback_SelectClient2(Database hDatabaseLocal, DBResultSet results, const char[] sError, any iUserID) // Обратный вызов
{
	if(sError[0])	// Если произошла ошибка
	{
		//LogError("SQL_Callback_SelectClient: %s", sError);	// Выводим в лог
		//LogToFile(sFile, "Запрос на создание таблицы данных pr_users не был отправлен !");
		return; // Прекращаем выполнение ф-и
	}

	//PrintToChatAll("Таблица данных создана");
	//LogToFile(sFile, "Запрос на создание таблицы данных pr_users отправлен");
}

public void OnClientPostAdminCheck(int client)
{
	if(!IsFakeClient(client))
	{
		char sQuery[512], sSteam[32];
		GetClientAuthId(client, AuthId_Steam2, sSteam, sizeof(sSteam), true);
		FormatEx(sQuery, sizeof(sQuery), "SELECT `key_t`, `value_t`, `key_ct`, `value_ct` FROM `pr_users` WHERE `steam_id` = '%s';", sSteam);	// Формируем запрос
		hDatabase.Query(SQL_Callback_SelectClient, sQuery, GetClientUserId(client)); // Отправляем запрос
	}
}

// Пришел ответ на запрос
public void SQL_Callback_SelectClient(Database hDatabaseLocal, DBResultSet hResults, const char[] sError, any iUserID)
{
	if(sError[0]) // Если произошла ошибка
	{
		LogError("SQL_Callback_SelectClient: %s", sError); // Выводим в лог
		return; // Прекращаем выполнение ф-и
	}
	
	int client = GetClientOfUserId(iUserID);
	if(client)
	{
		char sQuery[512];

		// Игрок всё еще на сервере
		if(hResults.FetchRow())	// Игрок есть в базе
		{
			// Получаем значения из результата
			char sResult[512];
			
			hResults.FetchString(0, sResult, sizeof(sResult));
			sSqlInfo[0][client] = sResult;
			
			hResults.FetchString(1, sResult, sizeof(sResult));
			sSqlInfo[1][client] = sResult;
			
			hResults.FetchString(2, sResult, sizeof(sResult));
			sSqlInfo[2][client] = sResult;
			
			hResults.FetchString(3, sResult, sizeof(sResult));
			sSqlInfo[3][client] = sResult;
		}
		else
		{
			char sKey[512];
			GetArrayString(hArray[0], 0, sKey, sizeof(sKey));		//Вытаскиваем имя модели Т
			sSqlInfo[0][client] = sKey;
			
			GetArrayString(hArray[1], 0, sKey, sizeof(sKey));		//Вытаскиваем значение модели Т
			sSqlInfo[1][client] = sKey;
			
			GetArrayString(hArray[2], 0, sKey, sizeof(sKey));		//Вытаскиваем имя модели CТ
			sSqlInfo[2][client] = sKey;
			
			GetArrayString(hArray[3], 0, sKey, sizeof(sKey));		//Вытаскиваем имя модели CТ
			sSqlInfo[3][client] = sKey;

			// Добавляем игрока в базу
			char sSteam[32];
			GetClientAuthId(client, AuthId_Steam2, sSteam, sizeof(sSteam));
			FormatEx(sQuery, sizeof(sQuery), "INSERT INTO `pr_users` (`steam_id`, `key_t`, `value_t`, `key_ct`, `value_ct`) VALUES ( '%s', '%s', '%s', '%s', '%s');", sSteam, sSqlInfo[0][client], sSqlInfo[1][client], sSqlInfo[2][client], sSqlInfo[3][client]);
			hDatabase.Query(SQL_Callback_CreateClient, sQuery, GetClientUserId(client));
			/*
			LogToFile(sFile, "All| Игрок [%N] добавлен в базу", client);
			LogToFile(sFile, "All| Ключ Т [%s]", sSqlInfo[0][client]);
			LogToFile(sFile, "All| Значение Т [%s]", sSqlInfo[1][client]);
			LogToFile(sFile, "All| Ключ КТ [%s]", sSqlInfo[2][client]);
			LogToFile(sFile, "All| Значение КТ [%s]", sSqlInfo[3][client]);*/
		}
	}
}

public void SQL_Callback_CreateClient(Database hDatabaseLocal, DBResultSet results, const char[] szError, any iUserID)
{
	if(szError[0])
	{
		LogError("SQL_Callback_CreateClient: %s", szError);
		return;
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

void CreatMenuT()
{
	char sModels[512];
	hMenu[0] = CreateMenu(MenuT);
	SetMenuTitle(hMenu[0], "Меню парашютов");

	for(int i; i < GetArraySize(hArray[0]); i++)
	{
		GetArrayString(hArray[0], i, sModels, sizeof(sModels));
		if(sModels[2])
		{
			//hMenu.AddItem("item1", sModels);
			AddMenuItem(hMenu[0], sModels, sModels);
			//PrintToChatAll("Итем = [%s]", sModels);
		}
	}
}

void CreatMenuCT()
{
	char sModels[512];
	hMenu[1] = CreateMenu(MenuCT);
	SetMenuTitle(hMenu[1], "Меню парашютов");

	for(int i; i < GetArraySize(hArray[2]); i++)
	{
		GetArrayString(hArray[2], i, sModels, sizeof(sModels));
		if(sModels[0])
		{
			//hMenu.AddItem("item1", sModels);
			AddMenuItem(hMenu[1], sModels, sModels);
		}
	}
}

public Action CmdParechuteMenu(int client, any argc)
{
	if(!client || IsFakeClient(client))
		return Plugin_Continue;
		
	if(GetClientTeam(client) < 2 || 3 < GetClientTeam(client))
	{
		PrintToChat(client, "Вы должны быть в команде для активации меню парашюта !");
		return Plugin_Continue;
	}
		
	if(!IsPlayerAlive(client))
	{
		PrintToChat(client, "Вы должны быть живы для активации меню парашюта !");
		return Plugin_Continue;
	}
		
	if(GetClientTeam(client) == 2)
		DisplayMenu(hMenu[0], client, MENU_TIME_FOREVER);
	if(GetClientTeam(client) == 3)
		DisplayMenu(hMenu[1], client, MENU_TIME_FOREVER);
		
	return Plugin_Handled;
}

public int MenuT(Menu hMenuLocal, MenuAction action, int client, int iItem)
{
	char sModels[512];

	if(action == MenuAction_Select)
	{
		GetArrayString(hArray[1], iItem, sModels, sizeof(sModels));		//Вытаскиваем из массива нужную модель для Т
		sClientModel[1][client] = sModels;		//Запоминаем для этого игрока модель для команды Т
		sClientModel[0][client] = sClientModel[1][client];		//Устанавливаем модель для отображения
		
		GetArrayString(hArray[0], iItem, sSqlInfo[0][client], sizeof(sSqlInfo[]));		//Вытаскиваем из массива нужную модель для СТ
		sSqlInfo[1][client] = sClientModel[1][client];
		char sQuery[512], sSteam[32];
		GetClientAuthId(client, AuthId_Steam2, sSteam, sizeof(sSteam));

		FormatEx(sQuery, sizeof(sQuery), "UPDATE `pr_users` SET `key_t` = '%s', `value_t` = '%s' WHERE `steam_id` = '%s';", sSqlInfo[0][client], sSqlInfo[1][client], sSteam);	// Формируем запрос
		hDatabase.Query(SQL_Callback_CheckError, sQuery);
		/*
		LogToFile(sFile, "Т| Обновляем данные пользователя [%N]", client);
		LogToFile(sFile, "Т| Ключ [%s]", sSqlInfo[0][client]);
		LogToFile(sFile, "Т| Значение [%s]", sSqlInfo[1][client]);*/
	}
	else if(action == MenuAction_End)
	{
		//hMenuLocal.Close();
		//delete hMenu[0];
	}
}

public int MenuCT(Menu hMenuLocal, MenuAction action, int client, int iItem)
{
	char sModels[512];

	if(action == MenuAction_Select)
	{
		GetArrayString(hArray[3], iItem, sModels, sizeof(sModels));		//Вытаскиваем из массива нужную модель для СТ
		sClientModel[2][client] = sModels;		//Запоминаем для этого игрока модель для команды CТ
		sClientModel[0][client] = sClientModel[2][client];		//Устанавливаем модель для отображения
		
		GetArrayString(hArray[2], iItem, sSqlInfo[2][client], sizeof(sSqlInfo[]));		//Вытаскиваем из массива нужную модель для СТ
		sSqlInfo[3][client] = sClientModel[2][client];
		char sQuery[512], sSteam[32];
		GetClientAuthId(client, AuthId_Steam2, sSteam, sizeof(sSteam));

		FormatEx(sQuery, sizeof(sQuery), "UPDATE `pr_users` SET `key_ct` = '%s', `value_ct` = '%s' WHERE `steam_id` = '%s';", sSqlInfo[2][client], sSqlInfo[3][client], sSteam);	// Формируем запрос
		hDatabase.Query(SQL_Callback_CheckError, sQuery);
		//LogToFile(sFile, "\n[%s]\n", sQuery);
		/*
		LogToFile(sFile, "КТ| Обновляем данные пользователя [%N]", client);
		LogToFile(sFile, "КТ| Ключ [%s]", sSqlInfo[2][client]);
		LogToFile(sFile, "КТ| Значение [%s]", sSqlInfo[3][client]);*/
	}
	else if(action == MenuAction_End)
	{
		//hMenuLocal.Close();
		//delete hMenu[1];
	}
}

// Обработчик ошибок
public void SQL_Callback_CheckError(Database hDatabaseLocal, DBResultSet results, const char[] szError, any data)
{
	if(szError[0])
	{
		LogError("SQL_Callback_CheckError: %s", szError);
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
	fallspeed = float(iFallSpeed)*(-1.0);		//
	GetEntDataVector(client, g_iVelocity, velocity);
	
	if(velocity[2] >= fallspeed)
		isfallspeed = true;
	if(velocity[2] < 0.0)
	{
		if(isfallspeed && !bLinear)
		{
		
		}
		else if((isfallspeed && bLinear) || float(iDecrease) == 0.0)
			velocity[2] = fallspeed;
		else
			velocity[2] = velocity[2] + float(iDecrease);
			
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, velocity);
		SetEntDataVector(client, g_iVelocity, velocity);
		SetEntityGravity(client,0.1);
		
		if(open)
			OpenParachute(client);
	}
}

public void EndPara(int client)
{
	SetEntityGravity(client,1.0);
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
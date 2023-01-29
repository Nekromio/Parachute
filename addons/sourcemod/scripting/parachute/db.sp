
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

public void DatabaseConnect(any data)
{
	if(cvMySQl.BoolValue)
	{
		Database.Connect(ConnectCallBack, "parachute");		//Подвключаемся к базе данных
	}
	else
	{
		Database.Connect(ConnectCallBack, "parachute_lite");		//Подвключаемся к базе данных
	}
}

void ConnectCallBack(Database hDB, const char[] szError, any data) // Пришел результат соединения
{
	if (hDB == null || szError[0])	// Соединение не удачное
	{
		SetFailState("Ошибка подключения к базе: %s", szError);		// Отключаем плагин
		return;
	}
	
	char sQuery[1024];

	hDatabase = hDB;		//
	SQL_LockDatabase(hDatabase);
	if(!cvMySQl.BoolValue) 
		FormatEx(sQuery, sizeof(sQuery), "CREATE TABLE IF NOT EXISTS `pr_users` (\
		`id` INTEGER PRIMARY KEY,\
		`steam_id` VARCHAR(32),\
		`key_t` VARCHAR(512),\
		`value_t` VARCHAR(512),\
		`key_ct` VARCHAR(512),\
		`value_ct` VARCHAR(512))");
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
	if(sError[0])
	{
		LogError("SQL_Callback_SelectClient: %s", sError);	//
		return;
	}
}

public void SQL_Callback_SelectClient(Database hDatabaseLocal, DBResultSet hResults, const char[] sError, any iUserID)
{
	if(sError[0])
	{
		LogError("SQL_Callback_SelectClient: %s", sError); //
		return; //
	}
	
	int client = GetClientOfUserId(iUserID);
	if(client)
	{
		char sQuery[512];
		if(hResults.FetchRow())	// Игрок есть в базе
		{
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
			GetArrayString(hArray[0], 0, sKey, sizeof(sKey));		//
			sSqlInfo[0][client] = sKey;
			
			GetArrayString(hArray[1], 0, sKey, sizeof(sKey));		//
			sSqlInfo[1][client] = sKey;
			
			GetArrayString(hArray[2], 0, sKey, sizeof(sKey));		//
			sSqlInfo[2][client] = sKey;
			
			GetArrayString(hArray[3], 0, sKey, sizeof(sKey));		//
			sSqlInfo[3][client] = sKey;

			char sSteam[32];
			GetClientAuthId(client, AuthId_Steam2, sSteam, sizeof(sSteam));
			FormatEx(sQuery, sizeof(sQuery), "INSERT INTO `pr_users` (`steam_id`, `key_t`, `value_t`, `key_ct`, `value_ct`) VALUES ( '%s', '%s', '%s', '%s', '%s');", sSteam, sSqlInfo[0][client], sSqlInfo[1][client], sSqlInfo[2][client], sSqlInfo[3][client]);
			hDatabase.Query(SQL_Callback_CreateClient, sQuery, GetClientUserId(client));
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

public void SQL_Callback_CheckError(Database hDatabaseLocal, DBResultSet results, const char[] szError, any data)
{
	if(szError[0])
	{
		LogError("SQL_Callback_CheckError: %s", szError);
	}
}

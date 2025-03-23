void Custom_SQLite()
{
	KeyValues hKv = new KeyValues("");
	hKv.SetString("driver", "sqlite");
	hKv.SetString("host", "localhost");
	hKv.SetString("database", "parachute");
	hKv.SetString("user", "root");
	hKv.SetString("pass", "");
	
	char sError[255];
	hDatabase = SQL_ConnectCustom(hKv, sError, sizeof(sError), true);

	if(sError[0])
	{
		SetFailState("Ошибка подключения к локальной базе SQLite: %s", sError);
	}
	hKv.Close();

	First_ConnectionSQLite();
}

void First_ConnectionSQLite()
{
	SQL_LockDatabase(hDatabase);
	char sQuery[1024];
	FormatEx(sQuery, sizeof(sQuery), "CREATE TABLE IF NOT EXISTS `pr_users` (\
		`id` INTEGER PRIMARY KEY,\
		`steam_id` VARCHAR(32),\
		`name_t` VARCHAR(512),\
		`mdl_t` VARCHAR(512),\
		`name_ct` VARCHAR(512),\
		`mdl_ct` VARCHAR(512))");

	hDatabase.Query(First_ConnectionSQLite_Callback, sQuery);

	SQL_UnlockDatabase(hDatabase);
	hDatabase.SetCharset("utf8");
}

public void First_ConnectionSQLite_Callback(Database hDb, DBResultSet results, const char[] sError, any iUserID)
{
	if (hDb == null || sError[0])
	{
		SetFailState("Ошибка подключения к базе: %s", sError);
		return;
	}
}

void ConnectCallBack(Database hDB, const char[] szError, any data)
{
	if (hDB == null || szError[0])
	{
		SetFailState("Ошибка подключения к базе: %s", szError);
		return;
	}
	
	char sQuery[1024];

	hDatabase = hDB;
	SQL_LockDatabase(hDatabase);

	FormatEx(sQuery, sizeof(sQuery), "CREATE TABLE IF NOT EXISTS `pr_users` (\
		`id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT ,\
		`steam_id` VARCHAR(32) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ,\
		`name_t` VARCHAR(512) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ,\
		`mdl_t` VARCHAR(512) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ,\
		`name_ct` VARCHAR(512) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ,\
		`mdl_ct` VARCHAR(512) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ,\
		UNIQUE `id` (`id`)) ENGINE = MyISAM CHARSET=utf8 COLLATE utf8_general_ci;");

	
	hDatabase.Query(SQL_Callback_CreateTable, sQuery);
	SQL_UnlockDatabase(hDatabase);
	hDatabase.SetCharset("utf8");
}

public void SQL_Callback_CreateTable(Database hDatabaseLocal, DBResultSet results, const char[] sError, any iUserID)
{
	if(sError[0])
	{
		LogError("SQL_Callback_CreateTable: %s", sError);	//
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
	
	char sResult[512];

	int client = GetClientOfUserId(iUserID);

	if(client)
	{
		if(hResults.FetchRow())	// Игрок есть в базе
		{
			for(int i = 0; i < 4; i++)
			{
				hResults.FetchString(i, sResult, sizeof(sResult));
				ResultData(client, sResult, i);
			}
		}
		else
		{
			for(int i = 0; i < 4; i++)
			{
				GetArrayString(hArray[i], 0, sResult, sizeof(sResult));
				ResultData(client, sResult, i);
			}

			char sSteam[32], sQuery[512];
			GetClientAuthId(client, AuthId_Steam2, sSteam, sizeof(sSteam));
			FormatEx(sQuery, sizeof(sQuery), "INSERT INTO `pr_users` (`steam_id`, `name_t`, `mdl_t`, `name_ct`, `mdl_ct`) VALUES ( '%s', '%s', '%s', '%s', '%s');",
			 sSteam, user[client].name_t, user[client].mdl_t, user[client].name_ct, user[client].mdl_ct);
			hDatabase.Query(SQL_Callback_CreateClient, sQuery, GetClientUserId(client));
		}
	}
}

stock void ResultData(int client, char result[512], int index)
{
	switch(index)
	{
		case 0: Format(user[client].name_t, 512, result);
		case 1: Format(user[client].mdl_t, 512, result);
		case 2: Format(user[client].name_ct, 512, result);
		case 3: Format(user[client].mdl_ct, 512, result);
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

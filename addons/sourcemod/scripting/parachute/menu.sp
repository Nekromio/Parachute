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
	}
	else if(action == MenuAction_End)
	{
		//hMenuLocal.Close();
		//delete hMenu[1];
	}
}


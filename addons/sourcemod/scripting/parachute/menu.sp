void CreateMenu_Parashute(int client)
{
	char buffer[512];
	hMenu[client] = new Menu(Callback_MenuParashute);
	hMenu[client].SetTitle("Меню парашюта");
	
	FormatEx(buffer, sizeof(buffer), "Модель за Т [%s]", user[client].name_t);
	hMenu[client].AddItem("item1", buffer);

	FormatEx(buffer, sizeof(buffer), "Модель за КТ [%s]", user[client].name_ct);
	hMenu[client].AddItem("item2", buffer);

	hMenu[client].Display(client, 30);
}

public int Callback_MenuParashute(Menu menu, MenuAction action, int client, int item)
{
    switch(action)
    {
		case MenuAction_End:
        {
            delete menu;
        }
		case MenuAction_Select:
        {
			if(!IsValidClient(client))
				return 0;

            switch(item)
    		{
				case 0:
				{
					CreatMenu_T(client);
				}
				case 1:
				{
					CreatMenu_CT(client);
				}
			}
        }
	}
	return 0;
}

void CreatMenu_T(int client)
{
	char buffer[512];
	hMenu[client] = new Menu(Callback_MenuT);
	hMenu[client].SetTitle("Выбор парашюта Т");

	for(int i = 0; i < GetArraySize(hArray[NAME_T]); i++)
	{
		hArray[NAME_T].GetString(i, buffer, sizeof(buffer));
		if(buffer[0])
		{
			hMenu[client].AddItem("item1", buffer);
		}
	}
	hMenu[client].ExitBackButton = true;

	hMenu[client].Display(client, 30);
}

public int Callback_MenuT(Menu menu, MenuAction action, int client, int item)
{
    switch(action)
    {
		case MenuAction_End:
        {
            delete menu;
        }
		case MenuAction_Cancel:
		{
			CreateMenu_Parashute(client);
		}
		case MenuAction_Select:
        {
			if(!IsValidClient(client))
				return 0;

			hArray[MDL_T].GetString(item, user[client].mdl_t, 512);
			hArray[NAME_T].GetString(item, user[client].name_t, 512);

			char sQuery[512], sSteam[32];
			GetClientAuthId(client, AuthId_Steam2, sSteam, sizeof(sSteam));

			FormatEx(sQuery, sizeof(sQuery), "UPDATE `pr_users` SET `name_t` = '%s', `mdl_t` = '%s' WHERE `steam_id` = '%s';", user[client].name_t, user[client].mdl_t, sSteam);	// Формируем запрос
			hDatabase.Query(SQL_Callback_CheckError, sQuery);

			CreateMenu_Parashute(client);
        }
	}
	return 0;
}

void CreatMenu_CT(int client)
{
	char buffer[512];
	hMenu[client] = new Menu(Callback_MenuCT);
	hMenu[client].SetTitle("Выбор парашюта КТ");

	for(int i = 0; i < GetArraySize(hArray[NAME_CT]); i++)
	{
		hArray[NAME_CT].GetString(i, buffer, sizeof(buffer));
		if(buffer[0])
		{
			hMenu[client].AddItem("item1", buffer);
		}
	}

	hMenu[client].ExitBackButton = true;
	hMenu[client].Display(client, 30);
}

public int Callback_MenuCT(Menu menu, MenuAction action, int client, int item)
{
    switch(action)
    {
		case MenuAction_End:
        {
            delete menu;
        }
		case MenuAction_Cancel:
		{
			CreateMenu_Parashute(client);
		}
		case MenuAction_Select:
        {
			if(!IsValidClient(client))
				return 0;

			hArray[MDL_CT].GetString(item, user[client].mdl_ct, 512);
			hArray[NAME_CT].GetString(item, user[client].name_ct, 512);
	

			char sQuery[512], sSteam[32];
			GetClientAuthId(client, AuthId_Steam2, sSteam, sizeof(sSteam));

			FormatEx(sQuery, sizeof(sQuery), "UPDATE `pr_users` SET `name_ct` = '%s', `mdl_ct` = '%s' WHERE `steam_id` = '%s';", user[client].name_ct, user[client].mdl_ct, sSteam);	// Формируем запрос
			hDatabase.Query(SQL_Callback_CheckError, sQuery);

			CreateMenu_Parashute(client);
        }
	}
	return 0;
}
#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <jwp>

#pragma newdecls required

#define PLUGIN_VERSION "1.3"
#define ITEM "slay"

public Plugin myinfo = 
{
	name = "[JWP] Slay",
	description = "Warden can slay players",
	author = "White Wolf",
	version = PLUGIN_VERSION,
	url = "http://hlmod.ru"
};

public void OnPluginStart()
{
	if (JWP_IsStarted()) JWP_Started();
	LoadTranslations("common.phrases");
	LoadTranslations("jwp_modules.phrases");
}

public void JWP_Started()
{
	JWP_AddToMainMenu(ITEM, OnFuncDisplay, OnFuncSelect);
}

public void OnPluginEnd()
{
	JWP_RemoveFromMainMenu();
}

public bool OnFuncDisplay(int client, char[] buffer, int maxlength, int style)
{
	FormatEx(buffer, maxlength, "%T", "Slay_Menu", LANG_SERVER);
	return true;
}

public bool OnFuncSelect(int client)
{
	char langbuffer[48];
	Menu SlayMenu = new Menu(SlayMenu_Callback);
	Format(langbuffer, sizeof(langbuffer), "%T:", "Slay_Menu", LANG_SERVER);
	SlayMenu.SetTitle(langbuffer);
	char id[4], name[MAX_NAME_LENGTH];
	for (int i = 1; i <= MaxClients; ++i)
	{
		if (CheckClient(i) && CanUserTarget(client, i))
		{
			Format(name, sizeof(name), "%N", i);
			IntToString(i, id, sizeof(id));
			SlayMenu.AddItem(id, name);
		}
	}
	if (!SlayMenu.ItemCount)
	{
		Format(langbuffer, sizeof(langbuffer), "%T", "Slay_NoAlive", LANG_SERVER);
		SlayMenu.AddItem("", langbuffer, ITEMDRAW_DISABLED);
	}
	SlayMenu.ExitBackButton = true;
	SlayMenu.Display(client, MENU_TIME_FOREVER);
	return true;
}

public int SlayMenu_Callback(Menu menu, MenuAction action, int client, int slot)
{
	switch (action)
	{
		case MenuAction_End: menu.Close();
		case MenuAction_Cancel:
		{
			if (slot == MenuCancel_ExitBack)
				JWP_ShowMainMenu(client);
		}
		case MenuAction_Select:
		{
			char info[4];
			menu.GetItem(slot, info, sizeof(info));
			int target = StringToInt(info);
			if (CheckClient(target))
			{
				if (!CanUserTarget(client, target))
					PrintToChat(client, "[JWP|Slay] %t", "Unable to target");
				else
				{
					ForcePlayerSuicide(target);
					JWP_ActionMsgAll("%T", "Slay_ActionMessage_Slayed", LANG_SERVER, client, target);
				}
			}
			else
				JWP_ActionMsg(client, "%T", "Slay_UnableToSlay", LANG_SERVER);
			JWP_ShowMainMenu(client);
		}
	}
}

bool CheckClient(int client)
{
	return (IsClientInGame(client) && IsClientConnected(client) && !IsFakeClient(client) /* && (GetClientTeam(client) == CS_TEAM_T) */ && IsPlayerAlive(client));
}
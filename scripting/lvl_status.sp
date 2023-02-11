#pragma semicolon 1
#pragma newdecls required

#include <lvl_ranks>
#include <sdktools_sound>

ConVar
	cvPos,
	cvTimerTime,
	cvEnable,
	cvShow;

public Plugin myinfo = 
{
	name = "[Any] Displaying LvL Ranks stats",
	author = "Nek.'a 2x2 | ggwp.site",
	description = "Отображение статистики LvL Ranks наблюдателям",
	version = "1.0.1",
	url = "https://ggwp.site/"
};

public void OnPluginStart()
{
	cvEnable = CreateConVar("sm_lvlstatus_enable", "1", "Включить/выключить плагин");
	cvPos = CreateConVar("sm_lvlstatus_pos", "0.99 0.65", "Позиция отображения худа");
	cvTimerTime = CreateConVar("sm_lvlstatus_timer", "0.5", "Время обновления отображения");
	cvShow = CreateConVar("sm_lvlstatus_show", "3", "Вариант отображения | 1 Hint | 2 Hud | 3 KeyHint (Для CSS(OB))");
	
	if(GetUserMessageId("HintText") != INVALID_MESSAGE_ID)
		HookUserMessage(GetUserMessageId("HintText"), MsgHook_HintText);
	
	AutoExecConfig(true, "lvl_status");
}

Action MsgHook_HintText(UserMsg msg_id, Handle bf, const int[] players, int playersNum, bool reliable, bool init)
{
	if (!cvEnable.BoolValue)
		return Plugin_Stop;
	
	for(int i = 0; i < playersNum; i++) if (players[i] != 0 && IsClientInGame(players[i]) && !IsFakeClient(players[i]))
		StopSound(players[i], SNDCHAN_STATIC, "UI/hint.wav");
	return Plugin_Continue;
}

public void OnMapStart()
{
	if(cvEnable.BoolValue)
		CreateTimer(cvTimerTime.FloatValue, Timer_Update, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_Update(Handle timer)
{
	if(!cvEnable.BoolValue)
		return Plugin_Stop;
		
	for(int i = 1, target, mod; i <= MaxClients; i++) if(IsValidClient(i) && !IsPlayerAlive(i) && !IsFakeClient(i))
	{
		target = GetEntPropEnt(i, Prop_Send, "m_hObserverTarget");
		mod = GetEntProp(i, Prop_Send, "m_iObserverMode");
		if(mod != 4) continue;
		SayRank(i, target);
	}
	return Plugin_Continue;
}

stock void SayRank(int client, int target)
{
	if(!IsValidClient(client) || !IsValidClient(target) || IsFakeClient(target))
		return;
	
	static char sMsg[256];
	int deaths = LR_GetClientInfo(target, ST_DEATHS);
	FormatEx(sMsg, sizeof(sMsg), "[%N] | Опыт [%d] Место в TOP [%d]/[%d]\n KD [%.2f]",
		target, LR_GetClientInfo(target, ST_EXP), LR_GetClientInfo(target, ST_PLACEINTOP), LR_GetCountPlayers(), (deaths ? (float(LR_GetClientInfo(target, ST_KILLS)) / float(deaths)) : 0.0));
	
	switch(cvShow.IntValue)
	{
		case 1: PrintHintText(client, "%s", sMsg);
		case 2: HudText(client, sMsg);
		case 3: HintText(client, sMsg);
	}
}

void HudText(int client, char[] sMsg)
{
	char sBuffer[56], sPos[4][24];
	int iColor[4];
	iColor[0] = GetRandomInt(10, 255);
	iColor[1] = GetRandomInt(10, 255);
	iColor[2] = GetRandomInt(10, 255);
	iColor[3] = 255;
	
	cvPos.GetString(sBuffer, sizeof(sBuffer));
	ExplodeString(sBuffer, " ", sPos, sizeof(sPos[]), sizeof(sPos[]));
	float fPos[2];
	fPos[0] = StringToFloat(sPos[0]);
	fPos[1] = StringToFloat(sPos[1]);
	SetHudTextParams(fPos[0], fPos[1], 1.1, iColor[0], iColor[1], iColor[2], 255, 0, 0.0, 0.1, 0.1);
	ShowHudText(client, 55, sMsg);
}

void HintText(int client, char[] sMsg)
{
	Handle hBuffer = StartMessageOne("KeyHintText", client);
	if(hBuffer != null)
	{
		BfWriteByte(hBuffer, 1);
		BfWriteString(hBuffer, sMsg);
		EndMessage();
	}
}

bool IsValidClient(int client)
{
	if(0 < client <= MaxClients && IsClientInGame(client))
		return true;
	return false;
}
#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#pragma newdecls required

// config files goes at tf/cfg/
#define SD_START_CFG "sudden_death.cfg"
#define SD_END_CFG   "sudden_death_end.cfg"

// Round States (CTFGameRules::m_iRoundState / RoundState_t)
enum
{
	GR_STATE_INIT = 0,
	GR_STATE_PREGAME,
	GR_STATE_STARTGAME,
	GR_STATE_PREROUND,
	GR_STATE_RND_RUNNING,
	GR_STATE_TEAM_WIN,
	GR_STATE_RESTART,
	GR_STATE_STALEMATE,   // <-- this is Sudden Death
	GR_STATE_GAME_OVER,
	GR_STATE_BONUS,
	GR_STATE_BETWEEN_RNDS
};

int g_iLastRoundState = -1;
Handle g_hRoundStateTimer = null;

public Plugin myinfo =
{
	name = "TF2-Stalemate-Exec",
	author = "patomario",
	description = "Executes a .cfgs when Sudden Death (or stalemate) starts or ends",
	version = "1.1",
	url = "https://github.com/patomario/TF2-Stalemate-Exec"
};

public void OnPluginStart()
{
	// Poll round state a few times a second. TF2 doesn't fire a clean,
	// universally-reliable game event for "sudden death started/ended" across
	// all mods/gamemodes, so watching the GameRules prop directly is the most
	// robust approach.
	g_hRoundStateTimer = CreateTimer(0.5, Timer_CheckRoundState, _, TIMER_REPEAT);
}

public void OnPluginEnd()
{
	if (g_hRoundStateTimer != null)
	{
		KillTimer(g_hRoundStateTimer);
		g_hRoundStateTimer = null;
	}
}

public void OnMapStart()
{
	g_iLastRoundState = -1;
}

public Action Timer_CheckRoundState(Handle timer)
{
	int roundState = GameRules_GetProp("m_iRoundState");

	if (roundState != g_iLastRoundState)
	{
		// Only compare against a known previous state (skip the very first read after map start)
		if (g_iLastRoundState != -1)
		{
			if (roundState == GR_STATE_STALEMATE)
			{
				OnSuddenDeathStart();
			}
			else if (g_iLastRoundState == GR_STATE_STALEMATE)
			{
				// GR_STATE_STALEMATE means that we are in stalemate mode!
				// note that it also means Sudden Death mode too!
				OnSuddenDeathEnd();
			}
		}

		g_iLastRoundState = roundState;
	}

	return Plugin_Continue;
}

void OnSuddenDeathStart()
{
	// PrintToChatAll("[SM] Running sudden_death.cfg", SD_START_CFG);
	ServerCommand("exec %s", SD_START_CFG);
}

void OnSuddenDeathEnd()
{
	// PrintToChatAll("[SM] Running sudden_death_end.cfg", SD_END_CFG);
	ServerCommand("exec %s", SD_END_CFG);
}
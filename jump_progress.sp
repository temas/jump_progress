#include <sourcemod>
#include <sdktools>

new Handle:g_hJP_Db;

public Plugin:myinfo =
{
    name = "Jump Progress",
    author = "Thomas \"temas\" Muldowney",
    description = "Save your forward progress on a jump map between server visits.",
    version = "0.0.1",
    url = "http://github.com/temas/jump-progress"
};

public OnPluginStart() 
{
    RegConsoleCmd("jp_save", cmdSaveProgress, "Save your jump progress");
    RegConsoleCmd("jp_load", cmdLoadProgress, "Load your jump progress");
}

public OnMapStart()
{
    if (!g_hJP_Db) {
        decl String:dbError[256] = "";
        g_hJP_Db = SQLite_UseDatabase("sourcemod-local", dbError, sizeof(dbError));
        if (dbError[0]) {
            LogError("%T (%s)", "Could not connect to the database.", LANG_SERVER, dbError);
            return;
        }

        SQL_FastQuery(g_hJP_Db, "CREATE TABLE IF NOT EXISTS jp_locations (player TEXT PRIMARY KEY ON CONFLICT REPLACE, x FLOAT, y FLOAT, z FLOAT)");
    }

    // TODO:  Possibly clean up old player data here

}

public Action:cmdSaveProgress(client, args)
{
    if(!IsPlayerAlive(client))
        PrintToChat(client, "\x04[JP]\x01 You must be alive to save your location");    
    else if(!(GetEntityFlags(client) & FL_ONGROUND))
        PrintToChat(client, "\x04[JP]\x01 You can't save your location on air");
    else if(GetEntProp(client, Prop_Send, "m_bDucked") == 1)
        PrintToChat(client, "\x04[JP]\x01 You can't save your location ducked");
    else
    {
        decl Float:fLocation[3];
        GetClientAbsOrigin(client, fLocation);
        decl String:sIdentity[20], String:saveQuery[256];
        if (!GetClientAuthString(client, sIdentity, sizeof(sIdentity)))
        {
            PrintToChat(client, "\x04[JP]\x01 Unable to save your location.");
            return;
        }
        Format(saveQuery, sizeof(saveQuery), "INSERT INTO jp_locations (player, x, y, z) VALUES('%s', %f, %f, %f)", sIdentity, fLocation[0], fLocation[1], fLocation[2]);
        SQL_FastQuery(g_hJP_Db, saveQuery);
        PrintToChat(client, "\x04[JP]\x01 Your location has been saved");
    }
}

public Action:cmdLoadProgress(client, args)
{
    if(!IsPlayerAlive(client))
        PrintToChat(client, "\x04[JP]\x01 You must be alive to load your location");    
    else
    {
        decl String:sIdentity[20], String:loadQuery[256];
        if (!GetClientAuthString(client, sIdentity, sizeof(sIdentity)))
        {
            PrintToChat(client, "\x04[JP]\x01 Unable to load your location.");
            return;
        }
        Format(loadQuery, sizeof(loadQuery), "SELECT * FROM jp_locations WHERE player='%s'", sIdentity);
        new Handle:query = SQL_Query(g_hJP_Db, loadQuery);
        if (!query || !SQL_FetchRow(query))
        {
            PrintToChat(client, "\x04[JP]\x01 Unable to load your location.");
            return;
        }

        decl Float:fLocation[3];
        fLocation[0] = SQL_FetchFloat(query, 1);
        fLocation[1] = SQL_FetchFloat(query, 2);
        fLocation[2] = SQL_FetchFloat(query, 3);

        TeleportEntity(client, fLocation, NULL_VECTOR, NULL_VECTOR);
        PrintToChat(client, "\x04[JP]\x01 Your progress has been loaded");
    }
}



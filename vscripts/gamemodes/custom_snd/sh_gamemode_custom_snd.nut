global function Sh_CustomSND_Init
global function SND_Print

global const asset SND_BOMB_MODEL 					= $"mdl/props/death_box/death_box_01.rmdl"
global const asset SND_PLANT_BOMB_MODEL             = $"mdl/vehicle/droppod_loot/droppod_loot_animated.rmdl"
global const string SND_BOMB_USE_LOOP_SOUND         = "Survival_RespawnBeacon_Linking_loop"

global struct SNDMap {
	vector PlantSite1
	vector PlantSite2

	vector SpawnDefusers
	vector SpawnDefusersRotation

	vector SpawnAttackers
	vector SpawnAttackersRotation

	vector RingLocation
	int RingSize
}

global array<SNDMap> SND_maps

#if SERVER
global array<entity> propsToDelete
#endif

void function SND_Print(string text)
{
	printt("[SND] -- " + text)
}

//
//
// INIT
//
//
void function Sh_CustomSND_Init() {

	// -----------------------------------------------------------------------------------------------------
	//
	// Commands and callbacks

	#if SERVER
		if (GetCurrentPlaylistVarBool("debug_enabled", false)) {
    		AddClientCommandCallback("snd_createbomb", ClientCommand_SND_SpawnBomb)
    		AddClientCommandCallback("snd_dropship", ClientCommand_SND_DropshipTest)
    		AddClientCommandCallback("snd_respawn", ClientCommand_SND_SetRespawn)
    		AddClientCommandCallback("snd_createplantsite", ClientCommand_SND_CreatePlantSite)
    		AddClientCommandCallback("snd_observe", ClientCommand_SND_SetObserve)
		}
    	AddClientCommandCallback("snd_restart", ClientCommand_SND_Restart )
		AddSpawnCallback( "prop_dynamic", SND_PropSpawn )
	#endif

	#if CLIENT
		AddCreateCallback( "prop_dynamic", SND_PropSpawn )
	#endif

	// -----------------------------------------------------------------------------------------------------
	//
	// MAPS

	switch (GetMapName()) {
		case "mp_rr_desertlands_64k_x_64k":
			SNDMap map1

			map1.PlantSite1 = Vector(5905, 5520, -4290.97)
			map1.PlantSite2 = Vector(5959, 4722, -3695.94)

			map1.SpawnDefusers = Vector(7160, 4358, -3190)
			map1.SpawnDefusersRotation = Vector(0, 180, 0)

			map1.SpawnAttackers = Vector(3218, 4755, -3170)
			map1.SpawnAttackersRotation = Vector(0, 0, 0)

			map1.RingLocation = Vector(0, 0, 0)
			map1.RingSize = 0

			SND_maps = [map1]
			break
	}
}









void function SND_PropSpawn(entity ent) {
	switch(ent.GetTargetName()) {
		case "snd_bomb":
			AddCallback_OnUseEntity( ent, BombOnUse )
			#if SERVER
				propsToDelete.append(ent)
			#endif
			break
		case "snd_plantsite":
			AddCallback_OnUseEntity( ent, PlantSiteOnUse )
			#if SERVER
				propsToDelete.append(ent)
			#endif
			break
	}
}


void function BombOnUse(entity bomb, entity player, int useInputFlags  ) {
	if ( !(useInputFlags & USE_INPUT_LONG ) )
		return

	ExtendedUseSettings settings
	#if CLIENT
		settings.loopSound = RESPAWN_BEACON_LOOP_SOUND
		settings.displayRui = $"ui/health_use_progress.rpak"
		settings.displayRuiFunc = DisplayRuiForSNDBomb
		settings.icon = $""
		settings.hint = "Defusing bomb"
		settings.icon = RESPAWN_BEACON_ICON
	#elseif SERVER
		settings.startFunc = SNDBombStartUse
		settings.endFunc = SNDBombStopUse
		settings.successFunc = SNDBombDefuse
		settings.exclusiveUse = true
		settings.movementDisable = true
		settings.holsterWeapon = true
	#endif
	settings.duration = float(GetCurrentPlaylistVarInt("bomb_defuse_time", 3 ))
	settings.useInputFlag = IN_USE_LONG

	thread ExtendedUse( bomb, player, settings )
}

void function PlantSiteOnUse(entity ps, entity player, int useInputFlags  ) {
	if ( !(useInputFlags & USE_INPUT_LONG ) )
		return

	ExtendedUseSettings settings
	#if CLIENT
		settings.loopSound = RESPAWN_BEACON_LOOP_SOUND
		settings.displayRui = $"ui/health_use_progress.rpak"
		settings.displayRuiFunc = DisplayRuiForSNDPlantSite
		settings.icon = $""
		settings.hint = "Planting bomb"
		settings.icon = RESPAWN_BEACON_ICON
	#elseif SERVER
		settings.startFunc = SNDPlantSiteStartUse
		settings.endFunc = SNDPlantSiteStopUse
		settings.successFunc = SNDPlantSitePlanted
		settings.exclusiveUse = true
		settings.movementDisable = true
		settings.holsterWeapon = true
	#endif
	settings.duration = float(GetCurrentPlaylistVarInt("bomb_plant_time", 3 ))
	settings.useInputFlag = IN_USE_LONG

	thread ExtendedUse( ps, player, settings )
}






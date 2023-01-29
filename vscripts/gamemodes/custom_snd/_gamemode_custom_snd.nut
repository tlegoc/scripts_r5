global function _CustomSND_Init

global function ClientCommand_SND_SpawnBomb
global function ClientCommand_SND_SetRespawn
global function ClientCommand_SND_CreatePlantSite
global function ClientCommand_SND_Restart
global function ClientCommand_SND_SetObserve
global function ClientCommand_SND_DropshipTest

global function SND_SetRespawn

global function CreateBomb
global function MonitorBomb
global function SNDBombDefuse
global function SNDBombStartUse
global function SNDBombStopUse

global function SNDPlantSitePlanted
global function SNDPlantSiteStartUse
global function SNDPlantSiteStopUse


bool restart = false

void function _CustomSND_Init() {

    AddCallback_OnClientConnected( void function(entity player) { thread SND_OnPlayerConnected(player) } )
    AddCallback_OnPlayerKilled(void function(entity victim, entity attacker, var damageInfo) {thread SND_OnPlayerDied(victim, attacker, damageInfo)})


	// -----------------------------------------------------------------------------------------------------
	//
    //Dropship values

    dropshipAnimData dataForPlayerA
	dataForPlayerA.idleAnim           = "Classic_MP_flyin_exit_playerA_idle"
	dataForPlayerA.idlePOVAnim        = "Classic_MP_flyin_exit_povA_idle"
	dataForPlayerA.jumpAnim           = "Classic_MP_flyin_exit_playerA_jump"
	dataForPlayerA.jumpPOVAnim        = "Classic_MP_flyin_exit_povA_jump"
	//dataForPlayerA.viewConeFunc       = ViewConeWide
	dataForPlayerA.yawAngle           = -18.0
	dataForPlayerA.firstPersonJumpOutSound = "commander_sequence_soldier_a_jump"

	dropshipAnimData dataForPlayerB
	dataForPlayerB.idleAnim           = "Classic_MP_flyin_exit_playerB_idle"
	dataForPlayerB.idlePOVAnim        = "Classic_MP_flyin_exit_povB_idle"
	dataForPlayerB.jumpAnim           = "Classic_MP_flyin_exit_playerB_jump"
	dataForPlayerB.jumpPOVAnim        = "Classic_MP_flyin_exit_povB_jump"
	//dataForPlayerB.viewConeFunc       = ViewConeWide
	dataForPlayerB.yawAngle           = 8.0
	dataForPlayerB.firstPersonJumpOutSound = "commander_sequence_soldier_b_jump"

	dropshipAnimData dataForPlayerC
	dataForPlayerC.idleAnim           = "Classic_MP_flyin_exit_playerC_idle"
	dataForPlayerC.idlePOVAnim        = "Classic_MP_flyin_exit_povC_idle"
	dataForPlayerC.jumpAnim           = "Classic_MP_flyin_exit_playerC_jump"
	dataForPlayerC.jumpPOVAnim        = "Classic_MP_flyin_exit_povC_jump"
	//dataForPlayerC.viewConeFunc       = ViewConeWide
	dataForPlayerC.yawAngle           = 8.0
	dataForPlayerC.firstPersonJumpOutSound = "commander_sequence_soldier_c_jump"

	dropshipAnimData dataForPlayerD
	dataForPlayerD.idleAnim           = "Classic_MP_flyin_exit_playerD_idle"
	dataForPlayerD.idlePOVAnim        = "Classic_MP_flyin_exit_povD_idle"
	dataForPlayerD.jumpAnim           = "Classic_MP_flyin_exit_playerD_jump"
	dataForPlayerD.jumpPOVAnim        = "Classic_MP_flyin_exit_povD_jump"
	//dataForPlayerD.viewConeFunc       = ViewConeWide
	dataForPlayerD.yawAngle           = -16.0
	dataForPlayerD.firstPersonJumpOutSound = "commander_sequence_soldier_d_jump"

	file.dropshipAnimDataList = [ dataForPlayerA, dataForPlayerB, dataForPlayerC, dataForPlayerD ]

    Cache()
    thread RunSND()
}

struct {
    array<entity> bombs
    array<entity> attackersTeam
    array<entity> defusersTeam
    array<entity> spectators

	array<dropshipAnimData> dropshipAnimDataList
} file

void function Cache() {
    PrecacheModel(SND_BOMB_MODEL)
    PrecacheModel(SND_PLANT_BOMB_MODEL)
}

void function RunSND() {
    WaitForGameState(eGameState.Playing)
    for (;;) {
        restart = false
        MakeTeams()
        GenerateMap()
        PreRound()
        SpawnPlayers()
        WaitForRestart()
    }


    WaitForever()
}

// -----------------------------------------------------------------------------------------------------
//
// MAIN GAME LOOP

void function MakeTeams() {
    file.attackersTeam = []
    file.defusersTeam = []
    int i = 0
    foreach (player in GetPlayerArray()) {
        if (!IsValid(player) || i < 8)  {
            if (i % 2 == 0) {
                file.attackersTeam.append(player)
                SetTeam(player, TEAM_IMC)
            } else {
                file.defusersTeam.append(player)
                SetTeam(player, TEAM_MILITIA)
            }
        } else {
            file.spectators.append(player)
            SetTeam(player, 3)
        }

        i++
    }
}

void function GenerateMap() {
    foreach(ent in propsToDelete) {
        if (IsValid(ent)) ent.Destroy()
    }

    propsToDelete.clear()

    SNDMap map = SND_maps[0]

    file.bombs.append(CreateBombPlantSite(map.PlantSite1))
    file.bombs.append(CreateBombPlantSite(map.PlantSite2))
}

void function PreRound() {
    SND_Print("PreRound")
    wait 5
}

void function SpawnPlayers() {
    SNDMap map = SND_maps[0]

    foreach(player in file.attackersTeam) {
        SND_SetRespawn(player)
    }

    foreach(player in file.defusersTeam) {
        SND_SetRespawn(player)
    }

    thread SND_SpawnPlayersInDropshipAtPoint(file.attackersTeam, map.SpawnAttackers, map.SpawnAttackersRotation)
    thread SND_SpawnPlayersInDropshipAtPoint(file.defusersTeam, map.SpawnDefusers, map.SpawnDefusersRotation)
}



void function WaitForRestart() {
    while (!restart) {
        WaitFrame()
    }
    SND_Print(string(restart))
}



bool function ClientCommand_SND_DropshipTest(entity player, array<string> args) {

    if( !IsValid( player ) )
        return false

	thread SND_SpawnPlayersInDropshipAtPoint([player], Vector(9.45, -460.0, -2000.0), Vector(0, 0, 0))

    return true
}


bool function ClientCommand_SND_Restart(entity player, array<string> args) {
    SND_Print("Restarting SND")
    restart = true
    return true
}


// -----------------------------------------------------------------------------------------------------
//
// DROPSHIP STUFF

void function SND_SpawnPlayersInDropshipAtPoint( array<entity> players, vector origin, vector angles )
{
	entity dropship = CreateEntity( "npc_dropship" )
	SetSpawnOption_AISettings( dropship, "npc_dropship_respawn" )
	SetTargetName( dropship, RESPAWN_DROPSHIP_TARGETNAME )
	DispatchSpawn( dropship )
	dropship.SetInvulnerable()
	dropship.DisableHibernation()
	EmitSoundOnEntity( dropship, "goblin_imc_evac_hover" )
	thread JetwashFX( dropship )

	dropship.DisableGrappleAttachment()

	dropship.SetOrigin( origin )
	dropship.SetAngles( angles )
	Attachment attachResult = dropship.Anim_GetAttachmentAtTime( "dropship_classic_mp_flyin", "ORIGIN", 0.0 )

	int i = 0
	foreach ( player in players )
	{
		if ( IsValid( player ) )
		{
			thread SND_PutPlayerInDropship( player, dropship, i, attachResult.position )
		}
		i++
	}

	EndSignal( dropship, "OnDestroy" )

	thread PlayAnim( dropship, "dropship_classic_mp_flyin_idle", origin, angles )
	dropship.MakeInvisible()
	waitthread __WarpInEffectShared( attachResult.position, attachResult.angle, "dropship_warpin", 0.0 )
	dropship.MakeVisible()
	waitthread PlayAnim( dropship, "dropship_classic_mp_flyin", origin, angles )
	dropship.Destroy()
}


void function SND_PutPlayerInDropship( entity player, entity ship, int pos, vector teleportOrigin )
{
	ship.EndSignal( "OnDestroy" )
	player.EndSignal( "OnDeath" )

	dropshipAnimData animData = file.dropshipAnimDataList[ pos ]

	FirstPersonSequenceStruct idleAnimSequence
	idleAnimSequence.firstPersonAnim = animData.idlePOVAnim
	idleAnimSequence.thirdPersonAnim = animData.idleAnim
	idleAnimSequence.viewConeFunction = ViewCone360
	idleAnimSequence.attachment = animData.attachment
	idleAnimSequence.hideProxy = animData.hideProxy

	FirstPersonSequenceStruct jumpAnimSequence
	jumpAnimSequence.firstPersonAnim = animData.jumpPOVAnim
	jumpAnimSequence.thirdPersonAnim = animData.jumpAnim
	jumpAnimSequence.viewConeFunction = ViewConeTight
	jumpAnimSequence.attachment = animData.attachment
	jumpAnimSequence.hideProxy = animData.hideProxy

	// player.Signal( "StopPostDeathLogic" )
	AddCinematicFlag( player, CE_FLAG_INTRO )
	AddCinematicFlag( player, CE_FLAG_HIDE_MAIN_HUD )
	AddCinematicFlag( player, CE_FLAG_EMBARK ) // DoF
	player.SetPlayerNetInt( "respawnStatus", eRespawnStatus.WAITING_FOR_DROPPOD )

	// TODO: use generic model.  Can't use player settings here since they could be a spectator
	entity dummyEnt = CreatePropDynamic( $"mdl/humans/class/medium/pilot_medium_bloodhound.rmdl" )

	float idleTime = dummyEnt.GetSequenceDuration( animData.idleAnim )
	float jumpTime = dummyEnt.GetSequenceDuration( animData.jumpAnim )

	float totalTime = idleTime + jumpTime

	Remote_CallFunction_NonReplay( player, "ServerCallback_RespawnPodStarted", Time() + totalTime )
	dummyEnt.Destroy()

	player.p.respawnPod = ship
	player.StartObserverMode( OBS_MODE_CHASE )
	player.SetObserverTarget( ship )

	ScreenFadeFromBlack( player, 1.0, 1.0 )

	table<string,bool> e
	e[ "clearDof" ] <- true
	e[ "didHolsterAndDisableWeapons" ] <- false

	OnThreadEnd(
		function () : ( player, e )
		{
			if ( IsValid( player ) )
			{
				RemoveCinematicFlag( player, CE_FLAG_HIDE_MAIN_HUD )
				RemoveCinematicFlag( player, CE_FLAG_INTRO )

				if ( e[ "clearDof" ] )
					RemoveCinematicFlag( player, CE_FLAG_EMBARK )

				if ( e[ "didHolsterAndDisableWeapons" ] )
					DeployAndEnableWeapons( player )

				player.SetPlayerNetInt( "respawnStatus", 0 )
				player.p.respawnPod = null
				player.p.respawnPodLanded = false
				player.ClearParent()
				ClearPlayerAnimViewEntity( player )
				player.ClearInvulnerable()
			}
		}
	)

	//waitthread FirstPersonSequence( idleAnimSequence, player, ship )
	wait idleTime

	player.StopObserverMode()
	ClearPlayerEliminated( player )
	player.p.respawnPodLanded = true
	ResetPlayerInventory( player )
	if ( !IsAlive( player ) )
		DecideRespawnPlayer( player )
	player.SetOrigin( ship.GetOrigin() )

	thread SND_FadePlayerView( player, 0.1, e )
	HolsterAndDisableWeapons( player )
	e[ "didHolsterAndDisableWeapons" ] <- true
	player.SetInvulnerable()
	EmitSoundOnEntityOnlyToPlayer( player, player, animData.firstPersonJumpOutSound )
	waitthread FirstPersonSequence( jumpAnimSequence, player, ship )
	SND_FallTempAirControl( player )

	PlayBattleChatterLineToSpeakerAndTeam( player, "bc_returnFromRespawn" )
}

void function SND_FadePlayerView( entity player, float duration, table<string,bool> e )
{
	player.EndSignal( "OnDeath" )
	wait duration
	RemoveCinematicFlag( player, CE_FLAG_EMBARK )
	e[ "clearDof" ] = false
	ScreenFadeFromBlack( player, 1.0, 1.0 )
}

void function SND_FallTempAirControl( entity player )
{
	if ( player.IsOnGround() )
		return

	AddPlayerMovementEventCallback( player, ePlayerMovementEvents.TOUCH_GROUND, SND_OnPlayerTouchGround )
	player.kv.airSpeed = 300
	player.kv.airAcceleration = 1000
}

void function SND_OnPlayerTouchGround( entity player )
{
	RemovePlayerMovementEventCallback( player, ePlayerMovementEvents.TOUCH_GROUND, SND_OnPlayerTouchGround )
	player.kv.airSpeed = player.GetPlayerSettingFloat( "airSpeed" )
	player.kv.airAcceleration = player.GetPlayerSettingFloat( "airAcceleration" )

	player.p.lastRespawnTouchGroundTime = Time()

	PIN_PlayerLandedOnGround( player )
	SND_SetRespawn(player)
}


// -----------------------------------------------------------------------------------------------------
//
//
void function SND_OnPlayerConnected(entity player) {

    if( !IsValid( player ) )
    return

    SND_SetRespawn(player)

}

void function SND_OnPlayerDied(entity victim, entity attacker, var damageInfo) {

    if( !IsValid( victim ) )
    return

    //SND_SetRespawn(victim)
}

bool function ClientCommand_SND_SetRespawn(entity player, array<string> args) {
    SND_SetRespawn(player)
    return true
}

void function SND_SetRespawn(entity player) {
    if( !IsValid( player ) )
    return

    if( player.IsObserver() )
    {
        player.StopObserverMode()
        //Fix for head being in ground
        player.UnforceCrouch()
    }

    //Give passive regen (pilot blood)
    GivePassive( player, ePassives.PAS_PILOT_BLOOD )

    DecideRespawnPlayer(player, true)

    ClearInvincible(player)
    DeployAndEnableWeapons(player)
    player.UnforceStand()
    DeployAndEnableWeapons(player)
    player.UnfreezeControlsOnServer()
}

bool function ClientCommand_SND_SetObserve(entity player, array<string> args) {
    SetObserve(player, file.bombs[0])
    return true
}

void function SetObserve(entity player, entity target) {
    if( !IsValid( player ) )
    return

    player.SetObserverTarget( target )
    player.SetSpecReplayDelay( Spectator_GetReplayDelay() )
    player.StartObserverMode(OBS_MODE_CHASE)
}

entity function CreateBubbleBoundary()
{
    vector bubbleCenter = Vector(8, 1, -3200)

    float bubbleRadius = 3000

    //bubbleRadius += GetCurrentPlaylistVarFloat("bubble_radius_padding", 800)

    entity bubbleShield = CreateEntity( "prop_dynamic" )
    bubbleShield.SetValueForModelKey( BUBBLE_BUNKER_SHIELD_COLLISION_MODEL )
    bubbleShield.SetOrigin(bubbleCenter)
    bubbleShield.SetModelScale(bubbleRadius / 235)
    bubbleShield.kv.CollisionGroup = 0
    bubbleShield.kv.rendercolor = "127 73 37"
    DispatchSpawn( bubbleShield )

    thread MonitorBubbleBoundary(bubbleShield, bubbleCenter, bubbleRadius)

    return bubbleShield
}

void function MonitorBubbleBoundary(entity bubbleShield, vector bubbleCenter, float bubbleRadius)
{
    while(IsValid(bubbleShield))
    {
        foreach(player in GetPlayerArray_Alive())
        {
            if(!IsValid(player)) continue
            if(Distance(player.GetOrigin(), bubbleCenter) > bubbleRadius)
            {
                Remote_CallFunction_Replay( player, "ServerCallback_PlayerTookDamage", 0, 0, 0, 0, DF_BYPASS_SHIELD | DF_DOOMED_HEALTH_LOSS, eDamageSourceId.deathField, null )
                player.TakeDamage( int( 2.0 / 100.0 * float( player.GetMaxHealth() ) ), null, null, { scriptType = DF_BYPASS_SHIELD | DF_DOOMED_HEALTH_LOSS, damageSourceId = eDamageSourceId.deathField } )
            }
        }
        WaitFrame()
    }
}




//
//
// BOMB STUFF
bool function ClientCommand_SND_SpawnBomb(entity player, array<string> args) {

    if( !IsValid( player ) )
        return false

    CreateBomb(player.GetOrigin())

    return true
}

entity function CreateBomb(vector location) {
    entity bomb = CreateEntity("prop_dynamic")
	SetTargetName(bomb, "snd_bomb")

    bomb.SetValueForModelKey(SND_BOMB_MODEL)
    bomb.SetOrigin(location)
    bomb.SetModelScale(1)
    bomb.kv.CollisionGroup = 0

    //Usage
    bomb.SetUsable()
    //bomb.AllowMantle()
    bomb.SetUsableValue(USABLE_BY_ALL | USABLE_CUSTOM_HINTS)
    bomb.SetUsePrompts( "Defuse the bomb", "Defuse the bomb" )
    bomb.SetUsablePriority( USABLE_PRIORITY_HIGH )

    DispatchSpawn( bomb )

    thread MonitorBomb(bomb, GetCurrentPlaylistVarInt("bomb_explode_time", 25))
    return bomb
}

void function MonitorBomb(entity bomb, int explodeTime) {
    int timeRemaining = explodeTime
    while(IsValid(bomb)) {
        SND_Print("Bomb exploding in " + string(timeRemaining) )
        if (timeRemaining == 0) {

	        EmitSoundOnEntity( bomb, "ai_reaper_nukedestruct_explo_3p" )
            //explo_softball_impact_3p
            bomb.Destroy()
            foreach(player in GetPlayerArray_Alive())
            {
                if(!IsValid(player)) continue
                //if(Distance(player.GetOrigin(), bubbleCenter) > bubbleRadius)

                Remote_CallFunction_Replay( player, "ServerCallback_PlayerTookDamage", 0, 0, 0, 0, DF_BYPASS_SHIELD | DF_DOOMED_HEALTH_LOSS, eDamageSourceId.deathField, null )
                player.TakeDamage(float( player.GetMaxHealth() ) + 1, null, null, { scriptType = DF_BYPASS_SHIELD | DF_DOOMED_HEALTH_LOSS, damageSourceId = eDamageSourceId.deathField } )
            }
        }
        wait 1
        timeRemaining = timeRemaining - 1
    }
}

void function SNDBombDefuse( entity bomb, entity playerUser, ExtendedUseSettings settings )
{
    SND_Print("Bomb defused")
	bomb.Destroy()
}

void function SNDBombStartUse( entity bomb, entity player, ExtendedUseSettings settings )
{
	SND_Print("Start using bomb")
}

void function SNDBombStopUse( entity bomb, entity player, ExtendedUseSettings settings )
{
	SND_Print("Stop using bomb")
}



//
//
//BOMB PLANT SITE
bool function ClientCommand_SND_CreatePlantSite(entity player, array<string> args) {

    if( !IsValid( player ) )
        return false

    CreateBombPlantSite(player.GetOrigin())

    return true
}

entity function CreateBombPlantSite(vector location) {
    entity ps = CreateEntity("prop_dynamic")
	SetTargetName(ps, "snd_plantsite")

    ps.SetValueForModelKey(SND_PLANT_BOMB_MODEL)
    ps.SetOrigin(location)
    ps.SetModelScale(1)
    ps.kv.CollisionGroup = TRACE_COLLISION_GROUP_BLOCK_WEAPONS_AND_PHYSICS
    ps.kv.solid = SOLID_VPHYSICS
    ps.SetBlocksRadiusDamage( true )
    ps.SetTakeDamageType( DAMAGE_NO)

    //Usage
    ps.SetUsable()
    //ps.AllowMantle()
    //ps.SetUsableDistanceOverride( radius )
    ps.SetUsableValue(USABLE_BY_ALL | USABLE_CUSTOM_HINTS)
    ps.SetUsePrompts( "Plant the bomb", "Plant the bomb" )
    ps.SetUsablePriority( USABLE_PRIORITY_HIGH )

    DispatchSpawn( ps )

    return ps
}

void function SNDPlantSitePlanted( entity ps, entity player, ExtendedUseSettings settings )
{
	SND_Print("Bomb planted")
    CreateBomb(player.GetOrigin())
    ps.Destroy()
}

void function SNDPlantSiteStartUse( entity ps, entity player, ExtendedUseSettings settings )
{
	SND_Print("Start planting bomb")
}

void function SNDPlantSiteStopUse( entity ps, entity player, ExtendedUseSettings settings )
{
	SND_Print("Stop planting bomb")
}

global function InitR5RHomePanel
global function SetUIVersion

struct
{
	var menu
	var panel
} file

void function InitR5RHomePanel( var panel )
{
	file.panel = panel
	file.menu = GetParentMenu( file.panel )

	//Set info box image
	RuiSetImage( Hud_GetRui( Hud_GetChild( file.panel, "R5RPicBox" ) ), "basicImage", $"rui/menu/home/bg" )
}

void function SetUIVersion()
{
	//Set SDK version text
	Hud_SetText( Hud_GetChild( file.panel, "VersionNumber" ), "#BETA_BUILD_WATERMARK" )
	RuiSetString( Hud_GetRui( Hud_GetChild( file.panel, "SelfButton" ) ), "playerName", GetPlayerName() )
	RuiSetString( Hud_GetRui( Hud_GetChild( file.panel, "SelfButton" ) ), "accountLevel", GetAccountDisplayLevel( 100 ) )
	RuiSetImage( Hud_GetRui( Hud_GetChild( file.panel, "SelfButton" ) ), "accountBadge", GetAccountDisplayBadge( 100 ) )
	RuiSetFloat( Hud_GetRui( Hud_GetChild( file.panel, "SelfButton" ) ), "accountXPFrac", 1.0 )
}
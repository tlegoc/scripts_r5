global function Cl_CustomSND_Init


global function DisplayRuiForSNDBomb
global function DisplayRuiForSNDBomb_Internal
global function DisplayRuiForSNDPlantSite
global function DisplayRuiForSNDPlantSite_Internal

void function Cl_CustomSND_Init() {
    
}

void function DisplayRuiForSNDBomb( entity ent, entity player, var rui, ExtendedUseSettings settings )
{
	DisplayRuiForSNDBomb_Internal( rui, settings.icon, Time(), Time() + settings.duration, settings.hint )
}

void function DisplayRuiForSNDBomb_Internal( var rui, asset icon, float startTime, float endTime, string hint )
{
	RuiSetBool( rui, "isVisible", true )
	RuiSetImage( rui, "icon", icon )
	RuiSetGameTime( rui, "startTime", startTime )
	RuiSetGameTime( rui, "endTime", endTime )
	RuiSetString( rui, "hintKeyboardMouse", hint )
	RuiSetString( rui, "hintController", hint )
}

void function DisplayRuiForSNDPlantSite( entity ent, entity player, var rui, ExtendedUseSettings settings )
{
	DisplayRuiForSNDPlantSite_Internal( rui, settings.icon, Time(), Time() + settings.duration, settings.hint )
}

void function DisplayRuiForSNDPlantSite_Internal( var rui, asset icon, float startTime, float endTime, string hint )
{
	RuiSetBool( rui, "isVisible", true )
	RuiSetImage( rui, "icon", icon )
	RuiSetGameTime( rui, "startTime", startTime )
	RuiSetGameTime( rui, "endTime", endTime )
	RuiSetString( rui, "hintKeyboardMouse", hint )
	RuiSetString( rui, "hintController", hint )
}
package grafex.system.statesystem;

import grafex.states.playstate.PlayState;
import lime.app.Application;
import flixel.FlxG;
import flixel.addons.ui.FlxUIState;
import flixel.addons.transition.FlxTransitionableState;
import flixel.tweens.FlxTween;
import flixel.FlxCamera;
import flixel.FlxState;
import grafex.util.Controls;
import grafex.util.ClientPrefs;
import grafex.util.PlayerSettings;

import openfl.Assets;
import openfl.utils.AssetCache;
import grafex.util.MemoryUtil;

import grafex.system.script.GrfxScriptHandler;

import grafex.system.statesystem.MusicBeatState;

class ScriptedState extends MusicBeatState
{
	private static var stateName:String = 'CustomState'; 
	public static var instance:ScriptedState;

	public static var _staticVariables:Map<String, Any> = new Map();

	public static function setStatic(name:String, variable:Any, ?force:Bool = false):Void {
		return 	_staticVariables.set((!force ? stateName + "-" : "") + name, variable);
	}

	public static function getStatic(name:String, ?defaultVar:Any, ?force:Bool = false):Any {
		(_staticVariables.exists((!force ? stateName + "-" : "") + name) && _staticVariables.get((!force ? stateName + "-" : "") + name) != null) ? {
			return _staticVariables.get((!force ? stateName + "-" : "") + name);
		} : {
			return defaultVar;
		}
	}

	public function new(?name:String = 'CustomState')
	{
		super();
		stateName = name;
		trace('new');
	}

	override function create() {
		trace('create');
		//super.create();
		loadStateScript();
		var skip:Bool = FlxTransitionableState.skipNextTransOut;
		if(!skip) openSubState(new CustomFadeTransition(0.6, true));
		FlxTransitionableState.skipNextTransOut = false;
	}

	override function loadStateScript() {
		trace(stateName);
		if (Paths.fileExists('states/${stateName}.hx', TEXT)) {
			final extraParams = [
				'stateName' => stateName,
				stateName => stateName
			];
			stateScript = GrfxScriptHandler.loadStateModule('states/${stateName}', extraParams);
			instance = this;
			stateScript.set('this', this);
			stateScript.set('setStaticVar', setStatic);
			stateScript.set('getStaticVar', getStatic);
			stateScript.set('customState', this);
			stateScript.setParent(instance);
			stateScript.activate();
			call("onCreate", []);
		}
	}

	public function resetCustomState() {
		MusicBeatState.switchScriptedState(stateName);
	}
}

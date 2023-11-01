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
	public static var stateName:String = 'CustomState'; 
	public static var instance:ScriptedState;

	public static var _staticVariables:Map<String, Dynamic> = new Map();

	public static function init() {
		_staticVariables.set("ao", "ao");
		_staticVariables.remove("ao");
	}

	public static function setStatic(name:String, variable:Dynamic, ?force:Bool = false):Void {
		return 	_staticVariables.set((!force ? stateName + "-" : "") + name, variable);
	}

	public static function getStatic(name:String, ?defaultVar:Dynamic, ?force:Bool = false):Dynamic {
		(_staticVariables.exists((!force ? stateName + "-" : "") + name) && _staticVariables.get((!force ? stateName + "-" : "") + name) != null) ? {
			return _staticVariables.get((!force ? stateName + "-" : "") + name);
		} : {
			return defaultVar;
		}
	}

	public function setStaticVar(name:String, variable:Dynamic, ?force:Bool = false):Void {
		return 	setStatic(name, variable, force);
	}

	public function getStaticVar(name:String, ?defaultVar:Dynamic, ?force:Bool = false):Dynamic {
		return 	getStatic(name, defaultVar, force);
	}

	public function new(?name:String = 'CustomState')
	{
		super();
		stateName = name;
		trace('new');
	}

	override function create() {
		trace('create');
		var skip:Bool = FlxTransitionableState.skipNextTransOut;
		//super.create();

		if(!skip) openSubState(new CustomFadeTransition(0.6, true));
		
		FlxTransitionableState.skipNextTransOut = false;
		loadStateScript();
	}

	override function loadStateScript() {
		trace(stateName);
		if (Paths.fileExists('states/${stateName}.hx', TEXT)) {
			stateScript = GrfxScriptHandler.loadStateModule('states/${stateName}');

			trace('states/${stateName}.hx');
			instance = this;

			stateScript.set('customState', this);
			stateScript.set('this', this);
			stateScript.set('stateName', stateName);			

			stateScript.setParent(instance);
			stateScript.activate();
			call("onCreate", []);
		}
	}

	public function resetCustomState() {
		MusicBeatState.switchScriptedState(stateName);
	}
}

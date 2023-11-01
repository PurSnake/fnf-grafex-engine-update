package grafex.system.statesystem;

import grafex.system.Conductor.BPMChangeEvent;
import flixel.FlxG;
import flixel.FlxSubState;
import flixel.FlxBasic;
import flixel.FlxSprite;
import grafex.util.Controls;
import grafex.util.ClientPrefs;
import grafex.util.PlayerSettings;

import grafex.system.script.GrfxScriptHandler;

import grafex.system.statesystem.MusicBeatSubstate;

class ScriptedSubState extends MusicBeatSubstate
{
	public static var subStateName:String = 'CustomSubState'; 
	public static var instance:ScriptedSubState;

	public static var _staticVariables:Map<String, Dynamic> = new Map();

	public static function init() {
		_staticVariables.set("ao", "ao");
		_staticVariables.remove("ao");
	}
	
	public static function setStatic(name:String, variable:Dynamic, ?force:Bool = false):Void {
		return 	_staticVariables.set((!force ? subStateName + "-" : "") + name, variable);
	}

	public static function getStatic(name:String, ?defaultVar:Dynamic, ?force:Bool = false):Dynamic {
		(_staticVariables.exists((!force ? subStateName + "-" : "") + name) && _staticVariables.get((!force ? subStateName + "-" : "") + name) != null) ? {
			return _staticVariables.get((!force ? subStateName + "-" : "") + name);
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

	public function new(?name:String = 'CustomSubState')
	{
		subStateName = name;
		super();
		//subStateName = name;
		//loadSubStateScript();
	}

	override function loadSubStateScript() {
		trace(subStateName);
		if (Paths.fileExists('states/sub/${subStateName}.hx', TEXT)) {
			subStateScript = GrfxScriptHandler.loadStateModule('states/sub/${subStateName}');

			trace('states/sub/${subStateName}.hx');
			instance = this;

			subStateScript.set('CustomSubState', this);
			subStateScript.set('this', this);
			subStateScript.set('subStateName', subStateName);			

			subStateScript.setParent(instance);
			subStateScript.activate();
			call("new", []);
		}
	}
}

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
	private static var subStateName:String = 'CustomSubState'; 
	public static var instance:ScriptedSubState;

	public static var _staticVariables:Map<String, Any> = new Map();

	public static function setStatic(name:String, variable:Any, ?force:Bool = false):Void {
		return 	_staticVariables.set((!force ? subStateName + "-" : "") + name, variable);
	}

	public static function getStatic(name:String, ?defaultVar:Any, ?force:Bool = false):Any {
		(_staticVariables.exists((!force ? subStateName + "-" : "") + name) && _staticVariables.get((!force ? subStateName + "-" : "") + name) != null) ? {
			return _staticVariables.get((!force ? subStateName + "-" : "") + name);
		} : {
			return defaultVar;
		}
	}

	public function new(?name:String = 'CustomSubState')
	{
		subStateName = name;
		super();
		//subStateName = name;
		//loadSubStateScript();
	}

	override function loadSubStateScript() {
		if (Paths.fileExists('states/sub/${subStateName}.hx', TEXT)) {
			final extraParams = [
				subStateName => subStateName,
				'subStateName' => subStateName
			];
			subStateScript = GrfxScriptHandler.loadStateModule('states/sub/${subStateName}', extraParams);
			trace('states/sub/${subStateName}.hx');
			instance = this;
			subStateScript.set('this', this);
			subStateScript.set('customSubState', this);
			subStateScript.set('setStaticVar', setStatic);
			subStateScript.set('getStaticVar', getStatic);
			subStateScript.setParent(instance);
			subStateScript.activate();
			call("new", []);
		}
	}
}

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

class MusicBeatSubstate extends FlxSubState
{
	public function new()
	{
		super();
		loadSubStateScript();
	}

	private var lastBeat:Float = 0;
	private var lastStep:Float = 0;

	private var curStep:Int = 0;
	private var curBeat:Int = 0;

	private var curDecStep:Float = 0;
	private var curDecBeat:Float = 0;
	private var controls(get, never):Controls;

	public var subStateScript:GrfxStateModule;
	public static var instance:MusicBeatSubstate;

	inline function get_controls():Controls
		return PlayerSettings.player1.controls;

	function loadSubStateScript() {
		var className = Type.getClassName(Type.getClass(this));
		var scriptName = className.substr(className.lastIndexOf(".")+1);

		trace(className + " // " + scriptName);
		if (Paths.fileExists('states/sub/${scriptName}.hx', TEXT)) {
			subStateScript = GrfxScriptHandler.loadStateModule('states/sub/${scriptName}');

			trace('states/sub/${scriptName}.hx');
			instance = this;

			subStateScript.set(scriptName, this);
			subStateScript.set('this', this);
			subStateScript.setParent(instance);
			subStateScript.activate();
			call("new", []);
		}
	}


	public function call(name:String, ?args:Array<Dynamic>, ?defaultVal:Dynamic):Dynamic {
		if (subStateScript == null) return defaultVal;

		return subStateScript.executeFunc(name, args);
	}

	public override function onFocus() {
		super.onFocus();
		call("onFocus");
	}

	public override function onFocusLost() {
		super.onFocusLost();
		call("onFocusLost");
	}


	override function update(elapsed:Float)
	{
		//everyStep();

		if(FlxG.keys.justPressed.F11) FlxG.fullscreen = !FlxG.fullscreen;

		var oldStep:Int = curStep;

		updateCurStep();
		updateBeat();

		if (oldStep != curStep && curStep > 0)
			stepHit();

		super.update(elapsed);
		call("onUpdate", [elapsed]);
	}

	private function updateBeat():Void
	{
		curBeat = Math.floor(curStep / 4);
		curDecBeat = curDecStep/4;
	}

	private function updateCurStep():Void
	{
		var lastChange = Conductor.getBPMFromSeconds(Conductor.songPosition);

		var shit = ((Conductor.songPosition - ClientPrefs.noteOffset) - lastChange.songTime) / lastChange.stepCrochet;
		curDecStep = lastChange.stepTime + shit;
		curStep = lastChange.stepTime + Math.floor(shit);
	}

	public function stepHit():Void
	{
		if (curStep % 4 == 0)
			beatHit();

		call("onStepHit", [curStep]);
	}

	public function beatHit():Void
	{
		call("onBeatHit", [curBeat]);
	}


	public override function close() {
		super.close();
		call("onClose");
	}

	override function destroy()
	{
		call("onDestroy");
		subStateScript = null;
		instance = null;
		super.destroy();
	}
}

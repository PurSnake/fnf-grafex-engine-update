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
import grafex.system.statesystem.ScriptedState;
import grafex.system.statesystem.ScriptedSubState;

class MusicBeatState extends FlxUIState
{
	private var curSection:Int = 0;
	private var stepsToDo:Int = 0;

	private var curStep:Int = 0;
	private var curBeat:Int = 0;

	private var curDecStep:Float = 0;
	private var curDecBeat:Float = 0;
	private var controls(get, never):Controls;

	public static var camBeat:FlxCamera;

	public var stateScript:GrfxStateModule;

	public static var instance:MusicBeatState;

	inline function get_controls():Controls
		return PlayerSettings.player1.controls;

	public static final substatesToTrans:Array<Class<flixel.FlxSubState>> = [
		grafex.states.substates.PauseSubState,
		grafex.system.script.FunkinLua.CustomSubstate,
		ScriptedSubState,
		grafex.states.substates.GameOverSubstate
	];

	override function create()
	{
		camBeat = FlxG.camera;
		var skip:Bool = FlxTransitionableState.skipNextTransOut;
		super.create();

		if (!skip)
			openSubState(new CustomFadeTransition(0.6, true));

		FlxTransitionableState.skipNextTransOut = false;
		loadStateScript();
		timePassedOnState = 0;
	}

	function loadStateScript()
	{
		var className = Type.getClassName(Type.getClass(this));
		var scriptName = className.substr(className.lastIndexOf(".") + 1);

		trace(className + " // " + scriptName);
		if (Paths.fileExists('states/${scriptName}.hx', TEXT))
		{
			stateScript = GrfxScriptHandler.loadStateModule('states/${scriptName}');

			trace('states/${scriptName}.hx');
			instance = this;

			stateScript.set(scriptName, this);
			stateScript.set('this', this);
			stateScript.setParent(instance);
			stateScript.activate();
			call("onCreate", []);
		}
	}

	public function call(name:String, ?args:Array<Dynamic>, ?defaultVal:Dynamic):Dynamic
	{
		if (stateScript == null)
			return defaultVal;

		return stateScript.executeFunc(name, args);
	}

	public override function onFocus()
	{
		super.onFocus();
		call("onFocus");
	}

	public override function onFocusLost()
	{
		super.onFocusLost();
		call("onFocusLost");
	}

	public static var timePassedOnState:Float = 0;

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (FlxG.sound.music != null && !(this is PlayState))
			Conductor.songPosition = FlxG.sound.music.time;

		if (FlxG.keys.justPressed.F11)
			FlxG.fullscreen = !FlxG.fullscreen;

		// everyStep();
		var oldStep:Int = curStep;

		timePassedOnState += elapsed;

		updateCurStep();
		updateBeat();

		if (oldStep != curStep)
		{
			if (curStep > 0)
				stepHit();

			if (PlayState.SONG != null)
				oldStep < curStep ? updateSection() : rollbackSection();
		}
		call("onUpdate", [elapsed]);
	}

	private function updateSection():Void
	{
		if (stepsToDo < 1)
			stepsToDo = Math.round(getBeatsOnSection() * 4);
		while (curStep >= stepsToDo)
		{
			curSection++;
			var beats:Float = getBeatsOnSection();
			stepsToDo += Math.round(beats * 4);
			sectionHit();
		}
	}

	private function rollbackSection():Void
	{
		if (curStep < 0)
			return;

		var lastSection:Int = curSection;
		curSection = 0;
		stepsToDo = 0;
		for (i in 0...PlayState.SONG.notes.length)
		{
			if (PlayState.SONG.notes[i] != null)
			{
				stepsToDo += Math.round(getBeatsOnSection() * 4);
				if (stepsToDo > curStep)
					break;

				curSection++;
			}
		}
		if (curSection > lastSection)
			sectionHit();
	}

	private function updateBeat():Void
	{
		curBeat = Math.floor(curStep / 4);
		curDecBeat = curDecStep / 4;
	}

	private function updateCurStep():Void
	{
		var lastChange = Conductor.getBPMFromSeconds(Conductor.songPosition);

		var shit = ((Conductor.songPosition - ClientPrefs.noteOffset) - lastChange.songTime) / lastChange.stepCrochet;
		curDecStep = lastChange.stepTime + shit;
		curStep = lastChange.stepTime + Math.floor(shit);
	}

	public static function switchState(nextState:FlxState = null)
	{
		if (nextState == null)
			nextState = FlxG.state;
		if (nextState == FlxG.state)
		{
			resetState();
			return;
		}

		if (FlxTransitionableState.skipNextTransIn)
			FlxG.switchState(nextState);
		else
			startTransition(nextState);
		FlxTransitionableState.skipNextTransIn = false;
	}

	public static function resetState()
	{
		if (FlxTransitionableState.skipNextTransIn)
			FlxG.resetState();
		else
			startTransition();
		FlxTransitionableState.skipNextTransIn = false;
	}

	// Custom made Trans in
	public static function startTransition(nextState:FlxState = null)
	{
		if (nextState == null)
			nextState = FlxG.state;

		getStateWithSubState().openSubState(new CustomFadeTransition(0.6, false));
		CustomFadeTransition.finishCallback = function() nextState == FlxG.state ? FlxG.resetState() : FlxG.switchState(nextState);
	}

	public static function getState():FlxState
		return cast FlxG.state;

	public static function getSubState():FlxState
		return cast FlxG.state.subState;

	public static function getStateWithSubState():FlxState
		return (FlxG.state.subState != null && substatesToTrans.contains(Type.getClass(FlxG.state.subState))) 
		? getSubState() : getState();

	public static function switchScriptedState(?nextCustomState:String = 'CustomState')
	{
		var nextState = new ScriptedState(nextCustomState);

		if (FlxTransitionableState.skipNextTransIn)
			FlxG.switchState(nextState);
		else
			startTransition(nextState);
		FlxTransitionableState.skipNextTransIn = false;
	}

	public static function openScriptedSubState(?CustomSubState:String = 'CustomSubState')
	{
		FlxG.state.openSubState(new ScriptedSubState(CustomSubState));
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

	public function sectionHit():Void
	{
		// GrfxLogger.debug('Section: ' + curSection + ', Beat: ' + curBeat + ', Step: ' + curStep);
		call("onSectionHit", [curSection]);
	}

	function getBeatsOnSection()
	{
		var val:Null<Float> = 4;
		if (PlayState.SONG != null && PlayState.SONG.notes[curSection] != null)
			val = PlayState.SONG.notes[curSection].sectionBeats;
		return val == null ? 4 : val;
	}

	public override function destroy()
	{
		super.destroy();
		call("onDestroy");

		// if (stateScript != null) stateScript.dispose();

		stateScript = null;
		instance = null;
	}
}

package grafex.states.substates;

import flixel.tweens.FlxTween;
import lime.app.Application;
import flixel.addons.transition.FlxTransitionableState;
import grafex.system.Paths;
import grafex.system.statesystem.MusicBeatState;
import grafex.util.PlayerSettings;
import grafex.util.ClientPrefs;
import grafex.util.Highscore;
import sys.Http;
import sys.io.File;
import sys.FileSystem;
import grafex.data.EngineData;
import flixel.text.FlxText;
import flixel.FlxG;
import flixel.input.keyboard.FlxKey;
import flixel.util.FlxColor;
import grafex.util.Utils;

// TODO: rewrite this, maybe?
using StringTools;

class PrelaunchingState extends MusicBeatState
{
	public static var muteKeys:Array<FlxKey> = [FlxKey.ZERO];
	public static var volumeDownKeys:Array<FlxKey> = [FlxKey.NUMPADMINUS, FlxKey.MINUS];
	public static var volumeUpKeys:Array<FlxKey> = [FlxKey.NUMPADPLUS, FlxKey.PLUS];

	var leftState:Bool = false;
	var curSelected = 0;

	public var arrowSine:Float = 0;
	public var arrowTxt:FlxText;

	var txt:FlxText;
	var txts:Array<Array<String>> = [
		[
			"Disclaimer!\nThis game contains some flashing lights!\nYou've been warned!\n\nYou can disable them in Options Menu",
			""
		]
	];

	override function create()
	{
		super.create();

		Application.current.window.title = Main.appTitle + ' - Starting...';
		FlxG.fixedTimestep = false;

		FlxG.mouse.visible = false;
		FlxG.game.focusLostFramerate = 60;
		FlxG.sound.muteKeys = muteKeys;
		FlxG.sound.volumeDownKeys = volumeDownKeys;
		FlxG.sound.volumeUpKeys = volumeUpKeys;
		FlxG.keys.preventDefaultKeys = [TAB];
		FlxG.camera.zoom = 1;

		PlayerSettings.init();

		FlxG.save.bind('game', Utils.getSavePath());
		ClientPrefs.loadPrefs();

		Highscore.load();

		var version:Array<Int> = null;

		if (FlxG.save.data.noLaunchScreen == null)
			FlxG.save.data.noLaunchScreen = false;

		if (FlxG.save.data.noLaunchScreen == true)
		{
			FlxG.switchState(new TitleState());
			return;
		}

		txts.push(["Also, we wish you a pleasant game! \n  - PurSnake", '']);

		txt = new FlxText(0, 300, FlxG.width, '', 32);
		txt.borderColor = FlxColor.BLACK;
		txt.borderSize = 3;
		txt.borderStyle = FlxTextBorderStyle.OUTLINE;
		txt.setFormat("VCR OSD Mono", 32, FlxColor.WHITE, CENTER);
		txt.screenCenter(X);
		add(txt);

		arrowTxt = new FlxText(txt.x + 300, txt.y + 300, FlxG.width, '', 32);
		arrowTxt.borderColor = FlxColor.BLACK;
		arrowTxt.borderSize = 3;
		arrowTxt.borderStyle = FlxTextBorderStyle.OUTLINE;
		arrowTxt.setFormat("VCR OSD Mono", 32, FlxColor.WHITE, CENTER);
		add(arrowTxt);

		changeSelection();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (FlxG.save.data.noLaunchScreen == true)
			return;

		if (!leftState)
		{
			arrowSine += 270 * elapsed;
			arrowTxt.alpha = 1 - Math.sin((Math.PI * arrowSine) / 180);
		}

		if (controls.UI_LEFT_P)
			changeSelection(-1);

		if (controls.UI_RIGHT_P)
			changeSelection(1);

		if (!leftState && (FlxG.keys.justPressed.ESCAPE || controls.BACK))
			makeCoolTransition();

		if (controls.ACCEPT)
			if (!leftState && txts[curSelected][1] != null && txts[curSelected][1] != '')
				Utils.browserLoad(txts[curSelected][1]);
	}

	function changeSelection(?pos:Int)
	{
		if (leftState)
			return;

		curSelected += pos;

		if (curSelected <= 0)
			curSelected = 0;

		if (curSelected >= txts.length + 1)
			curSelected = txts.length - 1;

		if (txts != null && curSelected < txts.length)
		{
			txt.text = txts[curSelected][0];
			if (txts.length != 1)
			{
				if (curSelected > 0 && curSelected < txts.length)
					arrowTxt.text = "< - >";
				if (curSelected == 0)
					arrowTxt.text = ">";
				if (curSelected == txts.length - 1)
					arrowTxt.text = "<";
			}
		}

		if (curSelected == txts.length)
			makeCoolTransition();

		FlxG.sound.play(Paths.sound('scrollMenu'));
	}

	function makeCoolTransition()
	{
		FlxG.save.data.noLaunchScreen = true;
		FlxG.save.flush();
		arrowTxt.alpha = 1;
		leftState = true;
		FlxTween.tween(txt, {alpha: 0}, 3);
		FlxTween.tween(arrowTxt, {alpha: 0}, 3);
		FlxG.sound.play(Paths.sound('titleShoot'), 0.6).fadeOut(6, 0);
		FlxG.camera.flash(FlxColor.WHITE, 3, function()
		{
			FlxTransitionableState.skipNextTransIn = false;
			FlxTransitionableState.skipNextTransOut = false;
			MusicBeatState.switchState(new TitleState());
		});
	}
}

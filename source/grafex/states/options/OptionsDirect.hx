package grafex.states.options;

import grafex.system.CustomFadeTransition;
import grafex.system.Paths;
import grafex.system.statesystem.MusicBeatState;
import flixel.addons.transition.FlxTransitionableState;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxBackdrop;
import flixel.util.FlxTimer;
import grafex.util.ClientPrefs;

class OptionsDirect extends MusicBeatState
{
	override function create()
	{
		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

		persistentUpdate = true;

		var menuBg:FlxSprite = new FlxSprite();
		menuBg.loadGraphic(Paths.image('options/options-bg'));
		menuBg.screenCenter();
		menuBg.antialiasing = ClientPrefs.globalAntialiasing;
		menuBg.scrollFactor.set();
		menuBg.scale.set(1, 1);
		add(menuBg);

		openSubState(new CustomFadeTransition(0.8, true)); // WHAT'S WRONG WITH THIS SHIT, IT ISN'T WORKING
		new FlxTimer().start(0.8, function(tmr:FlxTimer)
		{
			openSubState(new OptionsMenu());
		});		
	}
}
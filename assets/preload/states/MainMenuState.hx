import grafex.states.FreeplayState;
import lime.app.Application;

function onCreate() {
    if(FlxG.sound.music != null)
	    if (!FlxG.sound.music.playing)
	    {	
	    	    FlxG.sound.playMusic(Paths.music('freakyMenu'), 0.7);
		    FlxG.sound.music.time = 9400;
		    updateGameBpm();
	    }
	optionShit = [
	'story_mode',
	'freeplay',
	'mods',
	//'awards',
	'credits',
	'donate',
		'options'
	];

	//Application.createWindow({x: 15, y: 15});
	//Application.current.window.minimized = true;

	//Application.current.window.resizable = false;
}

function screenFunnyBop()
{
	FlxG.camera.zoom += 0.015;
	FlxTween.tween(FlxG.camera, {zoom: 1}, 0.2);
}

function onBeatHit(b) {
 screenFunnyBop();
}

function onUpdate(elapsed) {

	if(FlxG.mouse.wheel != 0) changeItem(-FlxG.mouse.wheel);

	if (FlxG.sound.music.volume < 0.8)
	{
		FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		if(FreeplayState.vocals != null) FreeplayState.vocals.volume += 0.5 * elapsed;
	}
}

/*function onUpdatePost(elapsed) {
        camFollow.setPosition(FlxMath.lerp(camFollow.x, FlxMath.remapToRange(FlxG.mouse.screenX, 0, FlxG.width, (FlxG.width / 2) + 16, (FlxG.width / 2) - 16),  3.5 * elapsed),
            FlxMath.lerp(camFollow.y, FlxMath.remapToRange(FlxG.mouse.screenY, 0, FlxG.height, (FlxG.height / 2) + 16, (FlxG.height / 2) - 16), 3.5 * elapsed));
}*/

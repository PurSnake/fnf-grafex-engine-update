import('grafex.states.FreeplayState');


function onCreate() {
    if(FlxG.sound.music != null)
	    if (!FlxG.sound.music.playing)
	    {	
	    	    FlxG.sound.playMusic(Paths.music('freakyMenu'), 0.7);
		    FlxG.sound.music.time = 9400;
		    this.updateGameBpm();
	    }
    this.optionShit = [
	'story_mode',
	'freeplay',
	'mods',
	//'awards',
	'credits',
	'donate',
        'options'
    ];
}


function onUpdate(elapsed) {
	if (FlxG.sound.music.volume < 0.8)
	{
		FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		if(FreeplayState.vocals != null) FreeplayState.vocals.volume += 0.5 * elapsed;
	}
}
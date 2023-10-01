import flixel.group.FlxGroup.FlxTypedGroup;

function onBeatHit(beat) {
	
	if (curBeat % 1 == 0) for (char in grpWeekCharacters.members)
	{
		if (char.character != '')
		{
			char.animation.play('idle', true);
		}
	}
}


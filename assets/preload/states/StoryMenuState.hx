import flixel.group.FlxGroup.FlxTypedGroup;

function onUpdate(elapsed) {
 if(FlxG.keys.justPressed.F5) FlxG.resetState(); 
}

var charExclusion = ['', 'gf', 'spooky', 'nene'];


function onUpdateText() for (char in grpWeekCharacters.members) if (!charExclusion.contains(char.character)) char.animation.curAnim.looped = false;


function onBeatHit(beat) for (char in grpWeekCharacters.members) if (!charExclusion.contains(char.character) && char.animation.curAnim.name != 'confirm') char.animation.play('idle', true);



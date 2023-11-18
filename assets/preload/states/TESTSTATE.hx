import grafex.system.statesystem.MusicBeatState;
import grafex.system.statesystem.ScriptedState;
import grafex.states.TitleState;

var gfDance;
function onCreate() {

	gfDance = new FlxSprite(getStaticVar('penis', 12, true), 40);
	gfDance.frames = Paths.getSparrowAtlas('gfDanceTitle');
	gfDance.animation.addByIndices('dance', 'gfDance', [30, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29], "", 24, true);
	gfDance.animation.play('dance');
	gfDance.antialiasing = ClientPrefs.globalAntialiasing;
	add(gfDance);
}


function onUpdate(elapsed) {

 if(FlxG.keys.justPressed.F5) resetCustomState(); 

 if (FlxG.keys.justPressed.J) { 
  setStaticVar('penis', getStaticVar('penis', 12, true) + 25, true);
  trace(getStaticVar("penis", 12, true));
 }
 if(controls.BACK) MusicBeatState.switchState(new TitleState());
 
}

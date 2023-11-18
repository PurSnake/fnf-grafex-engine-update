import grafex.system.statesystem.MusicBeatState;
import grafex.states.TitleState;
import grafex.system.statesystem.ScriptedState;

var timer:Float = 0;
function onUpdate(elapsed) {
 if(FlxG.keys.justPressed.F5) ScriptedState.resetCustomState();
 
 timer += elapsed * 10;

 if (timer >= 10) {
  FlxG.sound.play(Paths.sound('cancelMenu'));
  MusicBeatState.switchState(new TitleState());
 }
}
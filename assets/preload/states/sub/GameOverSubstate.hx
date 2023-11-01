import grafex.states.playstate.PlayState;

function onUpdate(elapsed) {
 //if(FlxG.keys.justPressed.F5) FlxG.resetState(); 

 //if(FlxG.keys.justPressed.F6) close(); 
}

function onBeatHit() {
 if (ableToCamBeat) {
  FlxG.camera.zoom += 0.015;
  FlxTween.tween(FlxG.camera, {zoom: PlayState.instance.defaultCamZoom}, 0.2);
 } 
}
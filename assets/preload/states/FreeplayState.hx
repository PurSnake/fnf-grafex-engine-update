import grafex.states.playstate.PlayState;

var songsTextColor = FlxColor.WHITE;

function onCreatePost() { //For future
 checkBgColor();
}

function onUpdate(elapsed) {
 for (healtIcon in iconArray) {
  var mult:Float = FlxMath.lerp(healtIcon.customScale, healtIcon.scale.x, Utils.boundTo(1 - (elapsed * 9 * (Conductor.bpm / 200)), 0, 1));
  healtIcon.scale.set(mult, mult);
  healtIcon.updateHitbox();
 }
 var bgMult:Float = FlxMath.lerp(1.1, bg.scale.x, Utils.boundTo(1 - (elapsed * 6 * (Conductor.bpm / 100)), 0, 1));
 bg.scale.set(bgMult, bgMult);
 bg.angle = FlxMath.lerp(0, bg.angle, Utils.boundTo(1 - (elapsed * 3 * (Conductor.bpm / 100)), 0, 1));
 bg.screenCenter();

 camINTERFACE.zoom = FlxMath.lerp(1, camINTERFACE.zoom, Utils.boundTo(1 - (elapsed * 9 * (Conductor.bpm / 200)), 0, 1));

 if (FlxG.keys.justPressed.P) {
  FreeplayState.vocals.volume == 0 ? FreeplayState.vocals.volume = 0.7 : FreeplayState.vocals.volume = 0;
  FreeplayState.vocals2.volume == 0 ? FreeplayState.vocals2.volume = 0.7 : FreeplayState.vocals2.volume = 0;
 }

 //if (controls.UI_UP_P || controls.UI_DOWN_P || FlxG.mouse.wheel != 0) checkBgColor();

}

function onBeatHit(da) {
 for (healtIcon in iconArray) healtIcon.doScale(0.925);
 bg.scale.set(1.135, 1.135);
 bg.angle = 1 * ((Conductor.bpm / 90) * 0.75);
}
function onSectionHit(da) {
 camINTERFACE.zoom += 0.025;
}

function checkBgColor() {
 //var newColor:Int = songs[curSelected].color;

 if (FlxColor.getRGB(intendedColor)[0] >= 175 && FlxColor.getRGB(intendedColor)[1] >= 175 && FlxColor.getRGB(intendedColor)[2] >= 175) songsTextColor = FlxColor.BLACK;
 else songsTextColor = FlxColor.WHITE;

 for (songText in grpSongs.members) {
  for (letter in songText.lettersArray) {
   if (letter.color != songsTextColor) {
    if(!letter.isOnScreen(camBackground)) FlxTween.color(letter, 0.2, letter.color, songsTextColor);
    else letter.color = songsTextColor;
   }
  }
 }
}
import flixel.text.FlxTextBorderStyle;
import flixel.text.FlxTextFormat;
import flixel.text.FlxTextFormatMarkerPair as FlxMark;

var songsTextColor = FlxColor.WHITE;
var songsTextColorOld = FlxColor.WHITE;

var voicesOnOffText:FlxText;

var GREEN = new FlxMark(new FlxTextFormat(FlxColor.GREEN), '&g');
var RED = new FlxMark(new FlxTextFormat(FlxColor.RED), '&r');

function onCreatePost() {
 voicesOnOffText = new FlxText(0, FlxG.height - 24, 0, "");
 voicesOnOffText.scrollFactor.set();
 voicesOnOffText.cameras = [camINTERFACE];
 voicesOnOffText.setFormat("VCR OSD Mono", 26, FlxColor.WHITE, "right", FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
 if (FreeplayState.vocals != null) voicesOnOffText.text = FreeplayState.vocals.volume != 0 ? "Voices: &gOn&g" : "Voices: &rOff&r";

 voicesOnOffText.visible = FreeplayState.vocals != null;
 voicesOnOffText.setPosition(FlxG.width - (voicesOnOffText.textField.width * 0.75), FlxG.height - (voicesOnOffText.textField.height * 2.0));
 voicesOnOffText.borderSize = 1.5;
 voicesOnOffText.applyMarkup(voicesOnOffText.text, [GREEN, RED]);
 voicesOnOffText.x += 250;
 FlxTween.tween(voicesOnOffText, {x: voicesOnOffText.x - 250}, Conductor.bpm / 200, {ease: FlxEase.smoothStepOut});
 add(voicesOnOffText);
}

function onUpdatePost(elapsed) {


 FlxG.camera.followLerp = FlxMath.bound(elapsed * 9 * (FlxG.updateFramerate / 60), 0, 1);

 for (healtIcon in iconArray)
  if(healtIcon.isOnScreen(camBackground))
   healtIcon.scale.set(FlxMath.lerp(healtIcon.customScale, healtIcon.scale.x, Utils.boundTo(1 - (elapsed * 9 * (Conductor.bpm / 200)), 0, 1)), FlxMath.lerp(healtIcon.customScale, healtIcon.scale.y, Utils.boundTo(1 - (elapsed * 9 * (Conductor.bpm / 200)), 0, 1)));

 bg.scale.set(FlxMath.lerp(1.1, bg.scale.x, Utils.boundTo(1 - (elapsed * 6 * (Conductor.bpm / 100)), 0, 1)), FlxMath.lerp(1.1, bg.scale.y, Utils.boundTo(1 - (elapsed * 6 * (Conductor.bpm / 100)), 0, 1)));
 bg.angle = FlxMath.lerp(0, bg.angle, Utils.boundTo(1 - (elapsed * 3 * (Conductor.bpm / 100)), 0, 1));
 bg.screenCenter();

 camINTERFACE.zoom = FlxMath.lerp(1, camINTERFACE.zoom, Utils.boundTo(1 - (elapsed * 9 * (Conductor.bpm / 200)), 0, 1));

 if (FlxG.keys.justPressed.P && !acceptedSong && FreeplayState.vocals != null) {
  FreeplayState.vocals.volume == 0 ? FreeplayState.vocals.volume = 0.7 : FreeplayState.vocals.volume = 0;
  FreeplayState.vocals2.volume == 0 ? FreeplayState.vocals2.volume = 0.7 : FreeplayState.vocals2.volume = 0;

  changeVoicesTxt();
 }

 if(FlxG.keys.justPressed.SPACE && !acceptedSong && FreeplayState.vocals != null) changeVoicesTxt();
 
 //persistentUpdate = true;
}

function changeVoicesTxt() {
 voicesOnOffText.text = FreeplayState.vocals.volume != 0 ? "Voices: &gOn&g" : "Voices: &rOff&r";
 voicesOnOffText.x = FlxG.width - (voicesOnOffText.textField.width * 0.75);
 voicesOnOffText.applyMarkup(voicesOnOffText.text, [GREEN, RED]);
 if(!voicesOnOffText.visible) {
  voicesOnOffText.x += 250;
  FlxTween.tween(voicesOnOffText, {x: voicesOnOffText.x - 250}, Conductor.bpm / 200, {ease: FlxEase.smoothStepOut});
 }
 voicesOnOffText.visible = true;
}

var bgAnlgeShit:Float = .75;
function onBeatHit(da) {
 for (healtIcon in iconArray) if(healtIcon.isOnScreen(camBackground)) healtIcon.doScale(0.925);
 bg.scale.set(1.135, 1.135);
 bg.angle = bgAnlgeShit * ((Conductor.bpm / 90) * 0.75);
 bgAnlgeShit = -bgAnlgeShit;
}
function onSectionHit(da) {
 camINTERFACE.zoom += 0.025;
}

function onChangeSelectionPost(change, withSound) {
 checkBgColor();
}

function checkBgColor() {
 var needToUpdateColors:Bool = false;

 if (FlxColor.getRGB(intendedColor)[0] >= 175 && FlxColor.getRGB(intendedColor)[1] >= 175 && FlxColor.getRGB(intendedColor)[2] >= 175) songsTextColor = FlxColor.BLACK;
 else songsTextColor = FlxColor.WHITE;

 if (songsTextColor != songsTextColorOld) {
  songsTextColorOld = songsTextColor;
  needToUpdateColors = true;
 }
 if (!needToUpdateColors) return;

 for (songText in grpSongs.members) for (letter in songText.lettersArray) letter.color = songsTextColor;
}
var angledCamera = PlayState.NotesCanMoveCam && false;
var coolCamAngle:Float = 0;

function onCreate() {
 classicHealthBar = false;
 smoothIcons = false;
}

function onCreatePost() {
 healthBarGroup.remove(healthBarBG, true);
 healthBarGroup.add(healthBarBG);
}

function onIconsBeat() {
 if (classicHealthBar) {
  iconP1.setGraphicSize(Std.int(iconP1.width + 30));
  iconP2.setGraphicSize(Std.int(iconP2.width + 30));
 }
}


function onUpdate(elapsed) {

 if(FlxG.keys.justPressed.F5) FlxG.resetState(); 
 if (angledCamera) {
  coolCamAngle = FlxMath.lerp(0, coolCamAngle, Utils.boundTo(1 - (elapsed * 10.125 * playbackRate), 0, 1));
  camGame.angle = FlxMath.lerp(coolCamAngle, camGame.angle, Utils.boundTo(1 - (elapsed * 10.125 * playbackRate), 0, 1));
 }

 if (classicHealthBar) {
  iconP1.setGraphicSize(Std.int(FlxMath.lerp(150, iconP1.width, 1)));
  iconP2.setGraphicSize(Std.int(FlxMath.lerp(150, iconP2.width, 1)));
 }
}
function onUpdatePost() {
 if (classicHealthBar) {
  iconP2.origin.x = 80;
  iconP2.origin.y = 0;
  iconP1.origin.x = 50;
  iconP1.origin.y = 0;
 }
}

function onTriggerCamMovement(focusedChar, strumId) {

 //coolCamAngle = 0;  
 if (angledCamera) {
  coolCamAngle = switch (strumId) {
   case 0: -4;
   case 1: -1;
   case 2: 2;
   case 3: 4;
  }
 }
}


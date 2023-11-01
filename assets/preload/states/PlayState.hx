
import grafex.system.notes.StrumNote;
import grafex.system.notes.Note;

var angledCamera = PlayState.NotesCanMoveCam && false;
var coolCamAngle:Float = 0;
var workLikePsych:Bool = false;

function onCreate() {
 classicHealthBar = false;
 smoothIcons = false;
 if (workLikePsych) camZooming = false;
}

function onCreatePost() {
 //healthBarGroup.remove(healthBarBG, true);
 //healthBarGroup.add(healthBarBG);

 //healthBarWN.barHeight += 1;
 //reloadHealthBarColors();

 if (classicHealthBar) strumLineNotes.forEach(function(strum:StrumNote)
 {
   strum.x -= 40;
 });
}

function onIconsBeat() {
 if (classicHealthBar) {
  iconP1.setGraphicSize(Std.int(iconP1.width + 30));
  iconP2.setGraphicSize(Std.int(iconP2.width + 30));

  //iconP1.scale.set(iconP1.customScale, iconP1.customScale);
  //iconP2.scale.set(iconP2.customScale, iconP2.customScale);
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

  //iconP1.scale.set(iconP1.customScale, iconP1.customScale);
  //iconP2.scale.set(iconP2.customScale, iconP2.customScale);
 }

 healthBarWN.percent = displayedHealth;

 if (PlayState.isPixelStage && false) {
    camGame.antialiasing = false;
    camGame.pixelPerfectRender = true;

    camHUD.antialiasing = false;
    camHUD.pixelPerfectRender = true;

    FlxG.game.stage.quality = 2;

    camFollow.x -= camFollow.x % 6;
    camFollow.y -= camFollow.y % 6;

    var small = FlxG.scaleMode.gameSize.x < FlxG.scaleMode.width || FlxG.scaleMode.gameSize.y < FlxG.scaleMode.height;
    if (small) {
        //shader.shaderData.size.value = [FlxG.scaleMode.gameSize.x < (FlxG.scaleMode.width / 2) ? 0 : 1];
        FlxG.camera.scroll.x = Math.floor(smallCamX / 6) * 6;
        FlxG.camera.scroll.y = Math.floor(smallCamY / 6) * 6;
    } else {
        //shader.shaderData.size.value = [2];
        smallCamX = FlxG.camera.scroll.x;
        smallCamY = FlxG.camera.scroll.y;
    }

    for (s in members) {
        if (Std.isOfType(s, FlxSprite)&& !Std.isOfType(s, Note)) {
            if (s.velocity != null && s.velocity.x == 0 && s.velocity.y == 0 && !s.cameras.contains(PlayState.camHUD) && !s.cameras.contains(PlayState.camOther)) {
                s.x -= s.x % 6;
                s.y -= s.y % 6;
                if (s.offset != null) {
                    s.offset.x -= s.offset.x % 6;
                    s.offset.y -= s.offset.y % 6;
                }
            }
        }
    }
    displayedHealth -= displayedHealth % .35;
 }
}

//var percent:Float = 50;
function onUpdatePost(e) {
 if (classicHealthBar) {
  iconP2.origin.x = 80;
  iconP2.origin.y = 0;
  iconP1.origin.x = 50;
  iconP1.origin.y = 0;

  //iconP1.scale.set(iconP1.customScale, iconP1.customScale);
  //iconP2.scale.set(iconP2.customScale, iconP2.customScale);
 }  

 healthBarWN.percent = displayedHealth;
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


function opponentNoteHit(index, data, type, sus, id) {
 if (workLikePsych) camZooming = true;
}

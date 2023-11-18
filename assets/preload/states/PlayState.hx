import grafex.system.notes.StrumNote;
import grafex.system.notes.Note;
import grafex.system.statesystem.MusicBeatState;
import grafex.states.options.OptionsMenu;


var options = {
	angledCamera: false,
	angledCameraMult: 1,

	camZoomByPos: false,

	workLikePsych: false,
	cameraMoveOffset: 10,
	useCustomPause: false
}

var coolCamAngle:Float = 0;

function onCreate() {
	//classicHealthBar = true;

	var file = Paths.getTextFromFile('data/PlayStateModuleOptions.json');
	if (file != null) options = Json.parse(file);

	if (options.workLikePsych) camZooming = false;
}

function onCreatePost() {
	if (options.cameraMoveOffset != null) cameraMoveOffset = options.cameraMoveOffset;

	/*healthBarGroup.remove(healthBarBG, true);
	healthBarGroup.add(healthBarBG);
	healthBarWN.barHeight += 1;*/

	if (classicHealthBar) strumLineNotes.forEach(function(strum:StrumNote) { strum.x -= 40; });
	FlxG.sound.cache(FlxG.sound.music._sound);
	FlxG.camera.bgColor = FlxColor.BLACK;

	/*var paralaxedSprite:ParallaxSprite = new ParallaxSprite(200, 300, Paths.image('logo'));
	paralaxedSprite.fixate(0, 0, 2, 2, 1, 1, 'vertical');
	//paralaxedSprite.scale.set(.7, .7);
	add(paralaxedSprite);*/
}

function onIconsBeat() {
	if (classicHealthBar) {
		iconP1.setGraphicSize(Std.int(iconP1.width + 30));
		iconP2.setGraphicSize(Std.int(iconP2.width + 30));
	}
}

function onUpdate(elapsed) {
	if(FlxG.keys.justPressed.SIX) options.useCustomPause = !options.useCustomPause;

	if(FlxG.keys.justPressed.F5) FlxG.resetState(); 

	if (classicHealthBar) {
		iconP1.setGraphicSize(Std.int(FlxMath.lerp(150, iconP1.width, 1)));
		iconP2.setGraphicSize(Std.int(FlxMath.lerp(150, iconP2.width, 1)));
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
			FlxG.camera.scroll.x = Math.floor(smallCamX / 6) * 6;
			FlxG.camera.scroll.y = Math.floor(smallCamY / 6) * 6;
		} else {
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

function onUpdatePost(elapsed) {
	if (classicHealthBar) {
		iconP2.origin.x = 80;
		iconP2.origin.y = 0;
		iconP1.origin.x = 50;
		iconP1.origin.y = 0;
	}  

	healthBarWN.percent = displayedHealth;

	if (options.angledCamera) {
		coolCamAngle = FlxMath.lerp(0, coolCamAngle, FlxMath.bound(1 - (elapsed * 5 * playbackRate / camZoomingDecay * cameraSpeed), 0, 1));
		camGame.angle = FlxMath.lerp(coolCamAngle, camGame.angle, FlxMath.bound(1 - (elapsed * 3.125 * playbackRate / camZoomingDecay * cameraSpeed), 0, 1));
	}

	if (camFocus != null && options.camZoomByPos) {
		var curCharacter = switch (camFocus) {
			case 'bf': boyfriend;
			case 'gf': gf != null ? gf : boyfriend;
			default: dad;
		}

		var camStuff = defaultCamZoom;
		if (curCharacter.animation.curAnim.name.indexOf('singLEFT') != -1 || curCharacter.animation.curAnim.name.indexOf('singRIGHT') != -1) camStuff = defaultCamZoom * 1.05;
		else if (curCharacter.animation.curAnim.name.indexOf('singDOWN') != -1) camStuff = defaultCamZoom * 1.1;
		else camStuff = defaultCamZoom;

		var lerpStuff = Utils.boundTo(1 - (elapsed * 3.125 * camZoomingDecay * playbackRate), 0, 1);
		camGame.zoom = FlxMath.lerp(camStuff, camGame.zoom, lerpStuff);
	}
}

function onMoveCamera(c) if (options?.cameraMoveOffset) cameraMoveOffset = options.cameraMoveOffset;


function onTriggerCamMovement(focusedChar, strumId) {
	if (options.angledCamera) {
		coolCamAngle = options.angledCameraMult * switch (strumId) {
			case 0: -2.5;
			case 1: -.5;
			case 2: 1;
			case 3: 2.5;
		}
	}
}

function opponentNoteHit(note, data, type, sus, id) {
 if (options.workLikePsych) camZooming = true;
}


function onPause() {
 if (!options.useCustomPause) return Function_Continue;
 
 FlxG.camera.followLerp = 0;
 paused = true;
 persistentUpdate = false;
 if(FlxG.sound.music != null) {
  FlxG.sound.music.pause();
  vocals.pause();
  vocals2.pause();
 }
 FlxTween.globalManager.forEach(function(tween:FlxTween) tween.active = false);
 FlxTimer.globalManager.forEach(function(timer:FlxTimer) timer.active = false);
 FlxG.sound.pause();
 MusicBeatState.openScriptedSubState('CustomPauseSubState');

 return Function_Stop;
}




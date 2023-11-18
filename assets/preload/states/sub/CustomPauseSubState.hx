import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxGridOverlay;
import grafex.util.Utils;
import grafex.states.substates.PauseSubState;
import grafex.states.playstate.PlayState;
import grafex.states.StoryMenuState;
import grafex.states.FreeplayState;
import grafex.states.StoryMenuState;
import grafex.states.MainMenuState;
import grafex.states.TitleState;
import grafex.system.statesystem.MusicBeatState;
import grafex.system.CustomFadeTransition;	
import Main;


var settings = {
	bgColour: 'custom',

	//music: ClientPrefs.data.pauseMusic, // if you want to edit it you have to put it in a string

	backdropSpeedX: -50,
	backdropSpeedY: -150,
	
	optionTweenTime: 0.15,
	selectTweenTime: 0.15,
	
	openMenuTweenTime: 0.75
};

var colours = [
	'default' => 0xFF000000,
	'pink' => 0xFFFA86C4,
	'crimson' => 0xFF870007,
	'turquoise' => 0xFF30D5C8,
	'red' => 0xFFBB0000,
	'green' => 0xFF00AA00,
	'blue' => 0xFF0000BB,
	'purple' => 0xFF592693,
	'yellow' => 0xFFC8B003,
	'brown' => 0xFF664229,
	'orange' => 0xFFFFA500,

	'custom' => 0xFF9859E0
];


var bg:FlxSprite;
var bgGrid:FlxBackdrop;
//var options:Array<String> = ['Resume', 'Restart', 'Options', 'Exit'];
var options:Array<String> = ['Resume', 'Restart', 'Exit'];
var curSelect:FlxText;
var songTxt:FlxText;
var composerTxt:FlxText;
var deathCount:FlxText;
var diff:FlxText;

var optionObjects = new StringMap();
var curSelected:Int = 0;

var overlappingOption:Bool = false;
var optionCooldown:Float = 0;

var state:String = null;
var fadeOutSpr:FlxSprite;

var pauseMusic:FlxSound;

var ableToChangeSelection:Bool = false;

var pauseFont:String = !PlayState.isPixelStage ? 'MFE.ttf' : 'vcr.ttf';

function convertPauseMenuSong(name:String) {
	name = name.toLowerCase();
	name = StringTools.replace(name, ' ', '-');
	return name;
}

if (PlayState.chartingMode) {
	options.insert(2, 'Leave Charting Mode');
	options.insert(3, 'Toggle Botplay');
}


var usualCamGameZoom:Float = 1.05;
var usualCamHumZoom:Float = 1.05;

var camerasProps = new StringMap();

function new() {
	camerasProps.set('camGameZoom', game.camGame.zoom);
	camerasProps.set('camGameAngle', game.camGame.angle);

	camerasProps.set('camHudZoom', game.camHUD.zoom);
	camerasProps.set('camHudAngle', game.camHUD.angle);
	camerasProps.set('camHudAlpha', game.camHUD.alpha);

	settings.backdropSpeedX = Conductor.bpm / 2;
	settings.backdropSpeedY -= Conductor.bpm / 2;

	//bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, colours[settings.bgColour.toLowerCase()]);
	//bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.fromRGB(game.dad.healthColorArray[0], game.dad.healthColorArra[1], game.dad.healthColorArray[2]));

	var oppColor = FlxColor.interpolate(FlxColor.fromRGB(game.dad.healthColorArray[0], game.dad.healthColorArray[1], game.dad.healthColorArray[2]) , FlxColor.fromRGB(game.dad.healthColorArray2[0], game.dad.healthColorArray2[1], game.dad.healthColorArray2[2]), 0.5);
	var bfColor = FlxColor.interpolate(FlxColor.fromRGB(game.boyfriend.healthColorArray[0], game.boyfriend.healthColorArray[1], game.boyfriend.healthColorArray[2]) , FlxColor.fromRGB(game.boyfriend.healthColorArray2[0], game.boyfriend.healthColorArray2[1], game.boyfriend.healthColorArray2[2]), 0.5);
	bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.interpolate(oppColor, bfColor, (game.health / 2) - 0.75));
	add(bg);
	bg.active = false;
	bg.alpha = 0;
	
	bgGrid = new FlxBackdrop(FlxGridOverlay.createGrid(80, 80, 160, 160, true, 0x11000000, 0x0));
	//000000 bgGrid = new FlxBackdrop(FlxGridOverlay.createGrid(80, 80, 160, 160, true, 0x11FFFFFF, 0x0));
	bgGrid.alpha = 0;
	bgGrid.velocity.set(175, -175);
	add(bgGrid);

	for (i in 0...options.length) {
		var option = new FlxText(-100, ((i + 1) * 90) + 200, 0, options[i], 46);
		option.font = Paths.font(pauseFont);
		option.borderStyle = Type.resolveEnum('flixel.text.FlxTextBorderStyle').OUTLINE;
		option.borderSize = 2;
		option.alpha = 0;
		option.active = false;
		add(option);
		optionObjects.set('option' + i, option);
	}

	curSelect = new FlxText(((optionObjects.get('option' + curSelected).x + optionObjects.get('option' + curSelected).width) + 10), optionObjects.get('option' + curSelected).y, 0, '<', 40);
	curSelect.font = Paths.font(pauseFont);
	curSelect.borderStyle = Type.resolveEnum('flixel.text.FlxTextBorderStyle').OUTLINE;
	curSelect.borderSize = 2;
	curSelect.alpha = 0;
	curSelect.active = false;
	add(curSelect);

	songTxt = new FlxText(1280, 15, 0, PlayState.SONG.song, 30);
	songTxt.font = Paths.font(pauseFont);
	songTxt.borderStyle = Type.resolveEnum('flixel.text.FlxTextBorderStyle').OUTLINE;
	songTxt.borderSize = 2;
	songTxt.alpha = 0;
	songTxt.angle = FlxG.random.float(-15, 15);
	songTxt.alignment = 'right';
	songTxt.active = false;
	add(songTxt);

	composerTxt = new FlxText(1280, songTxt.y + 40, 0, PlayState.SONG.composedBy, 28);
	composerTxt.font = Paths.font(pauseFont);
	composerTxt.borderStyle = Type.resolveEnum('flixel.text.FlxTextBorderStyle').OUTLINE;
	composerTxt.borderSize = 2;
	composerTxt.alpha = 0;
	composerTxt.angle = FlxG.random.float(-15, 15);
	composerTxt.alignment = 'right';
	composerTxt.active = false;
	add(composerTxt);

	var coolY = (composerTxt.text == '' || composerTxt.text == ' ') ? songTxt.y : composerTxt.y;

	diff = new FlxText(1280, coolY + 40, 0, Utils.difficultyString(), 30);
	diff.font = Paths.font(pauseFont);
	diff.borderStyle = Type.resolveEnum('flixel.text.FlxTextBorderStyle').OUTLINE;
	diff.borderSize = 2;
	diff.alpha = 0;
	diff.angle = FlxG.random.float(-15, 15);
	diff.alignment = 'right';
	diff.active = false;
	add(diff);

	deathCount = new FlxText(1280, diff.y + 40, 0, 'Blueballed: ' + PlayState.deathCounter, 30);
	deathCount.font = Paths.font(pauseFont);
	deathCount.borderStyle = Type.resolveEnum('flixel.text.FlxTextBorderStyle').OUTLINE;
	deathCount.borderSize = 2;
	deathCount.alpha = 0;
	deathCount.angle = FlxG.random.float(-15, 15);
	deathCount.active = false;
	deathCount.alignment = 'right';
	add(deathCount);

	fadeOutSpr = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF000000);
	add(fadeOutSpr);
	fadeOutSpr.active = false;
	fadeOutSpr.alpha = 0;

	FlxG.mouse.visible = true;

	pauseMusic = new FlxSound();

	//pauseMusic.loadEmbedded(Paths.inst(convertPauseMenuSong(PlayState.SONG.song, PlayState.SONG.postfix)), true);
	pauseMusic.loadEmbedded(FlxG.sound.music._sound, true);
	pauseMusic.volume = 1;
	FlxG.sound.list.add(pauseMusic);
	if (FlxG.sound.music != null && FlxG.sound.music.time != null && FlxG.sound.music.time > 0) pauseMusic.play(false, FlxG.sound.music.time);

	fadeIn();

	cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];

	timeElapsed = getStaticVar('timeElapsed', 0.0);
}

var game = PlayState.instance;

var timeElapsed;
var curSelecterObject = null;
function onUpdate(elapsed) {

	timeElapsed += elapsed;

	if (curSelecterObject != null) curSelecterObject.angle = Math.sin(timeElapsed * 2.0) * 2.5;

	//if (controls.BACK) close();
	//if (controls.BACK && ableToChangeSelection) fadeOut();

	if (ableToChangeSelection) {

		if (controls.BACK && ableToChangeSelection) fadeOut();

		if (controls.UI_UP_P || controls.UI_DOWN_P) changeSelection(controls.UI_UP_P ? -1 : 1);
		if (options.length <= 5) {
			for (i in 0...options.length) {
				overlappingOption = mouseOverlaps(optionObjects.get('option' + i));
				if (!overlappingOption && optionCooldown >= 0) optionCooldown -= elapsed;
				if (overlappingOption && optionCooldown <= 0 && curSelected != i) {
					optionCooldown = 0.1;
					curSelected = i;
					changeSelection();
					break;
				}
			}
		} else if (FlxG.mouse.wheel != 0) changeSelection(-FlxG.mouse.wheel);

		if (FlxG.keys.justPressed.ENTER || (mouseOverlaps(optionObjects.get('option' + curSelected)) && FlxG.mouse.justPressed)) {
			switch(optionObjects.get('option' + curSelected).text) {
				case 'Resume': fadeOut();
					ableToChangeSelection = false;
				case 'Restart':
					state = 'restart';
					fadeOut();
				case 'Options':
					state = 'options';
					fadeOut();
				case 'Exit':
					state = 'exit';
					fadeOut();
				case 'Leave Charting Mode':
					state = 'restart';
					PlayState.chartingMode = false;
					game.paused = true;
					FlxG.sound.music.volume = 0;
					game.vocals.volume = 0;
					fadeOut();
				case 'Toggle Botplay':
					game.cpuControlled = !game.cpuControlled;
					PlayState.changedDifficulty = true;
					game.botplayTxt.visible = game.cpuControlled;
					game.botplayTxt.alpha = 1;
					game.botplaySine = 0;
			}
		}
	}

	if (pauseMusic.volume > 0.75) pauseMusic.volume -= elapsed / 2;
}

function onDestroy() {
	getStaticVar('timeElapsed', timeElapsed);
	FlxG.mouse.visible = false;
	if (pauseMusic != null) {
		FlxTween.cancelTweensOf(pauseMusic);
		pauseMusic.destroy();
	}
}


function fadeOut() {
	if (pauseMusic != null) {
		FlxTween.cancelTweensOf(pauseMusic);
		FlxTween.tween(pauseMusic, {volume: 0, pitch: pauseMusic.pitch * 4}, 0.25, {ease: FlxEase.quadOut});
	}
	camerasProps.get('camGameTween').finish();
	camerasProps.get('camHudTween').finish();

	FlxG.mouse.visible = false;
	ableToChangeSelection = false;

	if (state == null) {
		FlxTween.tween(bg, {alpha: 0}, 0.25, {ease: FlxEase.quadOut});
		FlxTween.tween(game.camGame, {zoom: camerasProps.get('camGameZoom'), angle: camerasProps.get('camGameAngle')}, 0.2, {ease: FlxEase.quadOut});
		FlxTween.tween(game.camHUD, {zoom: camerasProps.get('camHudZoom'), angle: camerasProps.get('camHudAngle'), alpha: camerasProps.get('camHudAlpha')}, 0.2, {ease: FlxEase.quadOut});

		FlxTween.tween(bgGrid.velocity, {x: 1750, y: -1750}, 0.01, {ease: FlxEase.quadIn});
		for (i in 0...options.length) FlxTween.tween(optionObjects.get('option' + i), {alpha: 0, x: optionObjects.get('option' + i).x - optionObjects.get('option' + i).textField.width}, 0.25, {ease: FlxEase.quadOut});
		FlxTween.tween(curSelect, {alpha: 0, x: curSelect.x - optionObjects.get('option' + curSelected).x - optionObjects.get('option' + curSelected).textField.width }, 0.25, {ease: FlxEase.quadOut});
		FlxTween.tween(songTxt, {alpha: 0, x: songTxt.x + songTxt.textField.width}, 0.25, {ease: FlxEase.quadOut});
		FlxTween.tween(composerTxt, {alpha: 0, x: composerTxt.x + composerTxt.textField.width}, 0.25, {ease: FlxEase.quadOut});
		FlxTween.tween(diff, {alpha: 0, x: diff.x + diff.textField.width}, 0.25, {ease: FlxEase.quadOut});
		FlxTween.tween(deathCount, {alpha: 0, x: deathCount.x + deathCount.textField.width}, 0.25, {ease: FlxEase.quadOut});
		FlxTween.tween(bgGrid, {alpha: 0}, 0.25, {ease: FlxEase.quadOut, onComplete: function() close()});
	} else {
		FlxTween.tween(fadeOutSpr, {alpha: 1}, 0.25, {ease: FlxEase.quadOut, onComplete: function() {
			game.camPAUSE.bgColor = FlxColor.BLACK;

			switch(state) {
				case 'restart':
					game.persistentUpdate = false;
					FlxG.camera.followLerp = 0;
					PauseSubState.restartSong();
				case 'exit':
					PlayState.deathCounter = 0;
					PlayState.seenCutscene = false;
					FlxG.camera.followLerp = 0;

					PlayState.cancelMusicFadeTween();
					PlayState.changedDifficulty = false;
					PlayState.chartingMode = false;

					if(PlayState.isStoryMode) MusicBeatState.switchState(new StoryMenuState());
					else MusicBeatState.switchState(new FreeplayState());

					FlxG.sound.playMusic(Paths.music('freakyMenu'));
					TitleState.titleJSON = TitleState.getTitleData();
					Conductor.changeBPM(TitleState.titleJSON.bpm);
			}
		}});
	}
}


function changeSelection(?dir:Int = 0) {	
	curSelected = FlxMath.wrap(curSelected + dir, 0, options.length - 1);

	FlxTween.tween(curSelect, {x: (optionObjects.get('option' + curSelected).x + optionObjects.get('option' + curSelected).width) + 10}, settings.optionTweenTime, {ease: FlxEase.quadOut});
	if (options.length <= 5) FlxTween.tween(curSelect, {y: optionObjects.get('option' + curSelected).y}, settings.optionTweenTime, {ease: FlxEase.quadOut});
	else for (i in 0...options.length) FlxTween.tween(optionObjects.get('option' + i), {y: ((i - (curSelected - 1)) * 80) + 135}, settings.optionTweenTime, {ease: FlxEase.quadOut});

	for (i in 0...options.length) optionObjects.get('option' + i).angle = 0;

	curSelecterObject = optionObjects.get('option' + curSelected);

	FlxG.sound.play(Paths.sound('scrollMenu'));
	new FlxTimer().start(0.1, function(tmr:FlxTimer) {
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.25);
	});
}

function fadeIn() {
	FlxTween.tween(bg, {alpha: 0.6}, settings.openMenuTweenTime, {ease: FlxEase.quadOut});
	var randomAngleRotation = FlxG.random.float(-1.5, 1.5);

	camerasProps.set('camGameTween', FlxTween.tween(game.camGame, {zoom: camerasProps.get('camGameZoom') * 1.075, angle: camerasProps.get('camGameAngle') + randomAngleRotation}, settings.openMenuTweenTime * 1.5, {ease: FlxEase.quadOut}));
	camerasProps.set('camHudTween', FlxTween.tween(game.camHUD, {zoom: camerasProps.get('camHudZoom') * 1.075, angle: camerasProps.get('camHudAngle') + randomAngleRotation, alpha: camerasProps.get('camHudAlpha') * 0.9}, settings.openMenuTweenTime * 1.5, {ease: FlxEase.quadOut}));

	FlxTween.tween(bgGrid, {alpha: 1}, settings.openMenuTweenTime, {ease: FlxEase.quadOut});
	FlxTween.tween(bgGrid.velocity, {x: settings.backdropSpeedX / 2, y: settings.backdropSpeedY / 2}, settings.openMenuTweenTime * 1.5, {ease: FlxEase.quadOut});
	for (i in 0...options.length) FlxTween.tween(optionObjects.get('option' + i), {alpha: 1, x: 50 + (20 * i)}, settings.openMenuTweenTime + (i / 20), {ease: FlxEase.quadOut, onComplete: function() {
		ableToChangeSelection = true;
	}});
	if (pauseMusic != null) FlxTween.tween(pauseMusic, {pitch: FlxG.sound.music.pitch * 0.5}, settings.openMenuTweenTime * 5, {ease: FlxEase.quadOut});

	FlxTween.tween(curSelect, {alpha: 1, angle: 0, x: (50 + optionObjects.get('option' + curSelected).width) + 10 + (20 * curSelected)}, settings.openMenuTweenTime, {ease: FlxEase.quadOut});
	FlxTween.tween(songTxt, {alpha: 1, angle: 0, x: songTxt.x - songTxt.textField.width - 20}, settings.openMenuTweenTime, {ease: FlxEase.quadOut});
	FlxTween.tween(composerTxt, {alpha: 1, angle: 0, x: composerTxt.x - composerTxt.textField.width - 20}, settings.openMenuTweenTime, {ease: FlxEase.quadOut});
	FlxTween.tween(diff, {alpha: 1, angle: 0, x: diff.x - diff.textField.width - 20}, settings.openMenuTweenTime, {ease: FlxEase.quadOut});
	FlxTween.tween(deathCount, {alpha: 1, angle: 0, x: deathCount.x - deathCount.textField.width - 20}, settings.openMenuTweenTime, {ease: FlxEase.quadOut});

	curSelecterObject = optionObjects.get('option' + curSelected);
}

function mouseOverlaps(object, ?offsetX:Float, ?offsetY:Float) {
	offsetX ??= 0;
	offsetY ??= 0;

	var overlapX:Bool = (FlxG.mouse.getScreenPosition(game.camPAUSE).x + offsetX) >= object.x && (FlxG.mouse.getScreenPosition(game.camPAUSE).x + offsetX) <= object.x + object.width;
	var overlapY:Bool = (FlxG.mouse.getScreenPosition(game.camPAUSE).y + offsetY) >= object.y && (FlxG.mouse.getScreenPosition(game.camPAUSE).y + offsetY) <= object.y + object.height;

	return overlapX && overlapY;
}
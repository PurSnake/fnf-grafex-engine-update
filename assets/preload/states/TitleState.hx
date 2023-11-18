import grafex.effects.shaders.ColorSwap;
import grafex.system.statesystem.MusicBeatState;
import flixel.tweens.FlxTweenType;



var danceLeft:Bool = false;

var logoBl:FlxSprite;
var gfDance:FlxSprite;
var titleText:FlxSprite;

var swagShader:ColorSwap = null;

var titleTextColors:Array<FlxColor> = [0xFF33FFFF, 0xFF3333CC];
var titleTextAlphas:Array<Float> = [1, .64];

var logoTween:FlxTween;

function onCreate() {
	swagShader = new ColorSwap(); // idk
        switchTime = 1;

        FlxG.worldBounds.set(-500, -500, FlxG.width + 500, FlxG.height + 500);
}

function onIntroStart() {

	swagShader = new ColorSwap();

	gfDance = new FlxSprite(512, 40);
	gfDance.frames = Paths.getSparrowAtlas('gfDanceTitle');
	gfDance.animation.addByIndices('danceLeft', 'gfDance', [30, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14], "", 24, false);
	gfDance.animation.addByIndices('danceRight', 'gfDance', [15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29], "", 24, false);
	gfDance.antialiasing = ClientPrefs.globalAntialiasing;
	add(gfDance);
	gfDance.shader = swagShader.shader;

	logoBl = new FlxSprite(-150, -100);
	//logoBl = new FlxSprite(0, 25);
	logoBl.frames = Paths.getSparrowAtlas('logoBumpin');
	logoBl.antialiasing = ClientPrefs.globalAntialiasing;
	logoBl.animation.addByPrefix('bump', 'logo bumpin', 24, false);
	logoBl.animation.play('bump');
	//logoBl.loadGraphic(Paths.image('logo'));
	logoBl.scale.set(1.1, 1.1);
	logoBl.angle = -3;
	logoBl.updateHitbox();
	add(logoBl);
	logoBl.shader = swagShader.shader;

	titleText = new FlxSprite(100, 576);
	titleText.frames = Paths.getSparrowAtlas('titleEnter');
	titleText.animation.addByPrefix('idle', "ENTER IDLE", 24);
	titleText.animation.addByPrefix('press', ClientPrefs.flashing ? "ENTER PRESSED" : "ENTER FREEZE", 24);
	titleText.antialiasing = ClientPrefs.globalAntialiasing;
	titleText.animation.play('idle');
	titleText.updateHitbox();
	add(titleText);

	logoTween = FlxTween.tween(logoBl.scale, {x: logoBl.scale.x * 0.95, y: logoBl.scale.y * 0.95}, Conductor.crochet * 0.0005, {ease: FlxEase.cubeOut, type: FlxTweenType.PERSIST});
}

var titleTimer:Float = 0;

function onUpdate(elapsed) {

	if (FlxG.sound.music != null)
		Conductor.songPosition = FlxG.sound.music.time;

	FlxG.camera.zoom = FlxMath.lerp(FlxG.camera.zoom, 1, FlxMath.bound(elapsed * 7 / (FlxG.updateFramerate / 60), 0, 1));

	if(swagShader != null)
	{
		if(controls.UI_LEFT) swagShader.hue -= elapsed * 0.1;
		if(controls.UI_RIGHT) swagShader.hue += elapsed * 0.1;
	}

	titleTimer += FlxMath.bound(elapsed, 0, 1);
	if (titleTimer > 2) titleTimer -= 2;

	if(!transitioning && skippedIntro) {

		var timer:Float = titleTimer;
		if (timer >= 1)
			timer = (-timer) + 2;
		
		timer = FlxEase.quadInOut(timer);

		titleText.color = FlxColor.interpolate(titleTextColors[0], titleTextColors[1], timer);
		titleText.alpha = FlxMath.lerp(titleTextAlphas[0], titleTextAlphas[1], timer);
	}
}

function onBeatHit(curBeat) {

	if(curBeat % 2 == 0)
		FlxG.camera.zoom += 0.015;

	if(logoBl != null && logoTween != null)
		logoTween.start();

	if(gfDance != null) {
		danceLeft = !danceLeft;
		if (danceLeft)
			gfDance.animation.play('danceRight');
		else
			gfDance.animation.play('danceLeft');
	}
}

function onSkipIntro(skipped) {
	if (!skipped)
	{
		FlxG.camera.flash(FlxColor.WHITE, 4);
	}
}

function onPressedEnter() {
        if(titleText != null) {
		titleText.color = FlxColor.WHITE;
		titleText.alpha = 1;
		titleText.animation.play('press');
	}
	FlxG.camera.flash(ClientPrefs.flashing ? 0xFFFFFFFF : 0x4CFFFFFF, 1);
	FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);
}

function onCoolTextBeat(sickBeats) {
	switch (sickBeats)
	{
		case 1:
			FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
			FlxG.sound.music.fadeIn(4, 0, 0.7);
		case 2:
			createCoolText(['PurSnake']);
		case 4:
			addMoreText('present');
		case 5:
			deleteCoolText();
		case 6:
			createCoolText(['In memory', 'of'], -40);
		case 8:
			addMoreText('my penis', -40);
		case 9:
			deleteCoolText();
		case 10:
			createCoolText([curWacky[0]]);
		case 12:
			addMoreText(curWacky[1]);
		case 13:
			deleteCoolText();
		case 14:
			addMoreText('Friday');
			addMoreText('Night');
			addMoreText('Funkin');
		case 15:
			addMoreText('Grafex');
		case 16:
			addMoreText('Engine');
		case 17:
			skipIntro();
	}
}
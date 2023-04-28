import('grafex.effects.shaders.ColorSwap');

import('grafex.system.statesystem.MusicBeatState');



var danceLeft:Bool = false;

var logoBl:FlxSprite;
var gfDance:FlxSprite;
var titleText:FlxSprite;

var swagShader:ColorSwap = null;

//var 

function onCreate() {
	swagShader = new ColorSwap(); // idk
        this.switchTime = 1;
}

function onIntroStart() {

	swagShader = new ColorSwap();

	logoBl = new FlxSprite(-150, -100);
	logoBl.frames = Paths.getSparrowAtlas('logoBumpin');
	logoBl.antialiasing = ClientPrefs.globalAntialiasing;
	logoBl.animation.addByPrefix('bump', 'logo bumpin', 24, false);
	logoBl.animation.play('bump');
	logoBl.updateHitbox();
	this.add(logoBl);
	logoBl.shader = swagShader.shader;

	gfDance = new FlxSprite(512, 40);
	gfDance.frames = Paths.getSparrowAtlas('gfDanceTitle');
	gfDance.animation.addByIndices('danceLeft', 'gfDance', [30, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14], "", 24, false);
	gfDance.animation.addByIndices('danceRight', 'gfDance', [15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29], "", 24, false);
	gfDance.antialiasing = ClientPrefs.globalAntialiasing;
	this.add(gfDance);
	gfDance.shader = swagShader.shader;

	titleText = new FlxSprite(100, 576);
	titleText.frames = Paths.getSparrowAtlas('titleEnter');
	titleText.animation.addByPrefix('idle', "ENTER IDLE", 24);
	titleText.animation.addByPrefix('press', ClientPrefs.flashing ? "ENTER PRESSED" : "ENTER FREEZE", 24);
	titleText.antialiasing = ClientPrefs.globalAntialiasing;
	titleText.animation.play('idle');
	titleText.updateHitbox();
	this.add(titleText);
}


function onUpdate(elapsed) {
	if (FlxG.sound.music != null)
		Conductor.songPosition = FlxG.sound.music.time;

	FlxG.camera.zoom = FlxMath.lerp(1, FlxG.camera.zoom, 0.99);

	if(swagShader != null)
	{
		if(this.controls.UI_LEFT) swagShader.hue -= elapsed * 0.1;
		if(this.controls.UI_RIGHT) swagShader.hue += elapsed * 0.1;
	}
}


function onBeatHit(curBeat) {

	if(curBeat % 2 == 0)
		FlxG.camera.zoom += 0.01;

	if(logoBl != null)
		logoBl.animation.play('bump', true);

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
		FlxG.camera.flash(0xFFFFFFFF, 4);
	}
}

function onPressedEnter() {
        if(titleText != null) titleText.animation.play('press');
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
			this.createCoolText(['PurSnake', 'presenting', 'to']);
		case 4:
			this.addMoreText('Astro)');
		case 5:
			this.deleteCoolText();
		case 6:
			this.createCoolText(['I fucking', 'hate'], -40);
		case 8:
			this.addMoreText('ninjamuffin99', -40);
		case 9:
			this.deleteCoolText();
		case 10:
			this.createCoolText([this.curWacky[0]]);
		case 12:
			this.addMoreText(this.curWacky[1]);
		case 13:
			this.deleteCoolText();
		case 14:
			this.addMoreText('Friday');
			this.addMoreText('Night');
			this.addMoreText('Funkin');
		case 15:
			this.addMoreText('Grafex');
		case 16:
			this.addMoreText('Engine');
		case 17:
			this.skipIntro();
	}


}
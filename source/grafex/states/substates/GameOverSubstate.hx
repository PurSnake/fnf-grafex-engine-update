package grafex.states.substates;

import grafex.states.playstate.PlayState;
import grafex.data.WeekData;
import grafex.system.Paths;
import grafex.system.Conductor;
import grafex.system.statesystem.MusicBeatState;
import grafex.sprites.characters.Character;
import grafex.system.statesystem.MusicBeatSubstate;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import grafex.util.Utils;

import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;

import flixel.system.FlxSound;

import sys.FileSystem;

using StringTools;

class GameOverSubstate extends MusicBeatSubstate
{
	public var boyfriend:Character;
	var camFollow:FlxPoint;
	var camFollowPos:FlxObject;
	var updateCamera:Bool = false;
    var playingDeathSound:Bool = false;
	var ableToCamBeat:Bool = false;

	public var coolBg:FlxSprite;
	public static var coolBgColor:Int = 0x00000000;
	public static var coolFadeColor:Int = 0x00000000;

	var deathLines:Array<String> = [];
	public var deathLineSound:FlxSound = null;
	public static var deathLinesPath:String;

	public static var characterName:String = 'bf-dead';
	public static var deathSoundName:String = 'fnf_loss_sfx';
	public static var loopSoundName:String = 'gameOver';
	public static var endSoundName:String = 'gameOverEnd';

	// more custom shit via lua/hscript
	public static var loopSoundBPM:Int;
	public static var camOffset:Array<Float>;
	public static var frameNumber:Int;
	public static var beatAnimShit:Int;

	public static var instance:GameOverSubstate;

	public static function resetVariables() {
		characterName = 'bf-dead';
		deathSoundName = 'fnf_loss_sfx';
		loopSoundName = 'gameOver';
		endSoundName = 'gameOverEnd';
		loopSoundBPM = 100;
		coolBgColor = 0x00000000;
		coolFadeColor = 0x00000000;
		camOffset = [0, 0];
		deathLinesPath = '';
		frameNumber = 12;
		beatAnimShit = 1;
	}

public function checkDeathLines():Bool {
		return deathLines.length > 0;
	}

	function loadDeathLines(?pathO:String = '') {

		var directories:Array<String> = [
			Paths.mods('sounds/deathlines/' + pathO), Paths.mods(Paths.currentModDirectory + '/sounds/deathlines/' + pathO), Paths.getPreloadPath('sounds/deathlines/' + pathO)
		];

		for (i in 0...directories.length) {
		    var directory:String = directories[i];
		    if(FileSystem.exists(directory)) {
		        for (file in FileSystem.readDirectory(directory)) {
		          	var path = haxe.io.Path.join([directory, file]);
		          	if (!sys.FileSystem.isDirectory(path) && file.endsWith('.ogg')) {
		          		var funnySound:String = file.substr(0, file.length - 4);
		          		if(!deathLines.contains('deathlines/' + pathO + funnySound)) deathLines.push('deathlines/' + pathO + funnySound);
		          	}
		        }
		    }
		}
		trace(deathLines);
		if(checkDeathLines()) {
			deathLines[0] = FlxG.random.getObject(deathLines);
			Paths.sound(deathLines[0]);
		}
	}

	override function create()
	{
		instance = this;
		PlayState.instance.callOnLuas('onGameOverStart', []);
		PlayState.instance.callOnHscript('onGameOverStart', []);

		super.create();
	}

	public function new(x:Float, y:Float)
	{
		trace('Opened substate: ' + Type.getClassName(Type.getClass(this)));
		
		super();

		PlayState.instance.setOnLuas('inGameOver', true);

		PlayState.instance.callOnLuas('onGameOverCreate', []);
		PlayState.instance.callOnHscript('onGameOverCreate', []);

		coolBg = new FlxSprite(-(FlxG.width/2), -(FlxG.height/2)).makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), coolBgColor);
		add(coolBg);
		coolBg.scrollFactor.set();

		Conductor.songPosition = 0;

		loadDeathLines(deathLinesPath);

		boyfriend = new Character(x, y, characterName, true);
		boyfriend.x += boyfriend.positionArray[0];
		boyfriend.y += boyfriend.positionArray[1];
		add(boyfriend);

		camFollow = new FlxPoint(boyfriend.getMidpoint().x - boyfriend.cameraPosition[0] + camOffset[0], boyfriend.getMidpoint().y + boyfriend.cameraPosition[1] + camOffset[1]);

		FlxG.sound.play(Paths.sound(deathSoundName));
		Conductor.changeBPM(loopSoundBPM);
		FlxG.camera.scroll.set();
		FlxG.camera.target = null;

		boyfriend.playAnim('firstDeath');

		camFollowPos = new FlxObject(0, 0, 1, 1);
		camFollowPos.setPosition(FlxG.camera.scroll.x + (FlxG.camera.width / 2), FlxG.camera.scroll.y + (FlxG.camera.height / 2));
		add(camFollowPos);

		PlayState.instance.callOnLuas('onGameOverCreatePost', []);
		PlayState.instance.callOnHscript('onGameOverCreatePost', []);
	}

	var isFollowingAlready:Bool = false;
	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (FlxG.sound.music.playing) Conductor.songPosition = FlxG.sound.music.time;

		if(FlxG.keys.justPressed.F11) FlxG.fullscreen = !FlxG.fullscreen;

		PlayState.instance.callOnLuas('onUpdate', [elapsed]);
		PlayState.instance.callOnHscript('onUpdate', [elapsed]);
		if(updateCamera) {
			var lerpVal:Float = Utils.boundTo(elapsed * 0.6, 0, 1);
			camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));
		}

		if (controls.ACCEPT && !isEnding) endBullshit();

		if (controls.BACK && !isEnding)
		{
			FlxG.sound.music.stop();
			PlayState.deathCounter = 0;
			PlayState.seenCutscene = false;
			PlayState.chartingMode = false;

			if(deathLineSound != null) {
			    deathLineSound.onComplete = null;
			    deathLineSound.stop();
			    deathLineSound = null;
			    FlxG.sound.music.volume = 1;
                        }

			WeekData.loadTheFirstEnabledMod();
			if (PlayState.isStoryMode) MusicBeatState.switchState(new StoryMenuState());
			else MusicBeatState.switchState(new FreeplayState());

			FlxG.sound.playMusic(Paths.music('freakyMenu'));
			PlayState.instance.callOnLuas('onGameOverConfirm', [false]);
			PlayState.instance.callOnHscript('onGameOverConfirm', [false]);
		}

		if (boyfriend.animation.curAnim.name == 'firstDeath')
		{
			if(boyfriend.animation.curAnim.curFrame >= frameNumber && !isFollowingAlready)
			{
				FlxG.camera.follow(camFollowPos, LOCKON, 1);
				updateCamera = true;
				isFollowingAlready = true;
			}
			if (boyfriend.animation.curAnim.finished && !playingDeathSound)
			{
				if (PlayState.SONG.stage == 'tank')
				{
					playingDeathSound = true;
					coolStartDeath(0.2);
					
					var exclude:Array<Int> = [];
					//if(!ClientPrefs.cursing) exclude = [1, 3, 8, 13, 17, 21];

					FlxG.sound.play(Paths.sound('jeffGameover/jeffGameover-' + FlxG.random.int(1, 25, exclude)), 1, false, null, true, function() {
						if(!isEnding)
						{
							FlxG.sound.music.fadeIn(0.2, 1, 4);
						}
					});
				}
				else
				{
					if(checkDeathLines()) deathLineDeath(0.15);
					else coolStartDeath();
				}
			}
		}

		PlayState.instance.callOnLuas('onUpdatePost', [elapsed]);
		PlayState.instance.callOnHscript('onUpdatePost', [elapsed]);
	}

	override function beatHit()
	{
		super.beatHit();
		//FlxG.log.add('beat');

		if(beatAnimShit != 0)
			if(boyfriend.animOffsets.exists('deathBeat') && !isEnding && curBeat % beatAnimShit == 0)
				boyfriend.playAnim('deathBeat', true);

		PlayState.instance.callOnLuas('onBeatHit', [curBeat]);
		PlayState.instance.callOnHscript('onBeatHit', [curBeat]);
	}

	var isEnding:Bool = false;

    var coolCameraZoom:Float = 1;

	function shit():Void {
		if (!isEnding) FlxG.sound.music.fadeIn(3, 0.2, 1);

		deathLineSound.onComplete = null;
		deathLineSound.stop();
	}

	function deathLineDeath(?volume:Float = 1) 
	{
		deathLineSound = new FlxSound().loadEmbedded(Paths.sound(deathLines[0]));
		coolStartDeath(volume);
		deathLineSound.play(true);
		FlxG.sound.list.add(deathLineSound);
		deathLineSound.volume = 1;
		deathLineSound.onComplete = shit.bind();
	}

	function coolStartDeath(?volume:Float = 1):Void
	{
		FlxG.sound.playMusic(Paths.music(loopSoundName), volume);
		ableToCamBeat = true;
		if(boyfriend.animOffsets.exists('deathBeat'))
			boyfriend.playAnim('deathBeat', true);
		else
			boyfriend.playAnim('deathLoop');
	}

	function endBullshit():Void
	{
		if (!isEnding)
		{
			ableToCamBeat = false;
			FlxTween.tween(FlxG.camera, {zoom: FlxG.camera.zoom + 0.06}, 1.6, {ease: FlxEase.circOut});
			isEnding = true;
			if(deathLineSound != null) {
			    deathLineSound.onComplete = null;
			    deathLineSound.stop();
			    deathLineSound = null;
			    FlxG.sound.music.volume = 1;
                        }
			boyfriend.playAnim('deathConfirm', true);
			FlxG.sound.music.stop();
			FlxG.sound.play(Paths.music(endSoundName));
			new FlxTimer().start(0.7, function(tmr:FlxTimer)
			{
				FlxG.camera.fade(coolFadeColor, 2, false, function()
				{
					MusicBeatState.resetState();
				});
			});
			PlayState.instance.callOnLuas('onGameOverConfirm', [true]);
			PlayState.instance.callOnHscript('onGameOverConfirm', [true]);
		}
	}
}

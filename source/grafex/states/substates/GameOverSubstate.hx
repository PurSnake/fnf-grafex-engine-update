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
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import grafex.util.Utils;

import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;

import sys.FileSystem;


class GameOverSubstate extends MusicBeatSubstate
{
	public var boyfriend:Character;
	var camFollow:FlxPoint;
	var camFollowPos:FlxObject;
	var updateCamera:Bool = false;
    var playingDeathSound:Bool = false;
	var ableToCamBeat:Bool = false;

	var stageSuffix:String = "";

	public static var characterName:String = 'bf-dead';
	public static var deathSoundName:String = 'fnf_loss_sfx';
	public static var loopSoundName:String = 'gameOver';
	public static var endSoundName:String = 'gameOverEnd';

	// more custom shit via lua/hscript
	public static var loopSoundBPM:Int;
	public static var camOffset:Array<Float>;

	//FOR CHANGING
	var path:String = 'week6';

	public static var instance:GameOverSubstate;

	public static function resetVariables() {
		characterName = 'bf-dead';
		deathSoundName = 'fnf_loss_sfx';
		loopSoundName = 'gameOver';
		endSoundName = 'gameOverEnd';
		loopSoundBPM = 100;
		camOffset = [0, 0];
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
		PlayState.instance.callOnHscript('inGameOver', [true]);

		Conductor.songPosition = 0;

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
	}

	var isFollowingAlready:Bool = false;
	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (FlxG.sound.music.playing)
			Conductor.songPosition = FlxG.sound.music.time;

		if(FlxG.keys.justPressed.F11)
        {
           FlxG.fullscreen = !FlxG.fullscreen;
        }
		PlayState.instance.callOnLuas('onUpdate', [elapsed]);
		PlayState.instance.callOnHscript('onUpdate', [elapsed]);
		if(updateCamera) {
			var lerpVal:Float = Utils.boundTo(elapsed * 0.6, 0, 1);
			camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));
		}

		if (controls.ACCEPT)
		{
			endBullshit();
		}

		if (controls.BACK)
		{
			FlxG.sound.music.stop();
			PlayState.deathCounter = 0;
			PlayState.seenCutscene = false;
			PlayState.chartingMode = false;

			WeekData.loadTheFirstEnabledMod();
			if (PlayState.isStoryMode) MusicBeatState.switchState(new StoryMenuState());
			else MusicBeatState.switchState(new FreeplayState());

			FlxG.sound.playMusic(Paths.music('freakyMenu'));
			PlayState.instance.callOnLuas('onGameOverConfirm', [false]);
			PlayState.instance.callOnHscript('onGameOverConfirm', [false]);
		}

		if (boyfriend.animation.curAnim.name == 'firstDeath')
		{
			if(boyfriend.animation.curAnim.curFrame >= 12 && !isFollowingAlready)
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
					coolStartDeath();
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
	}

	var isEnding:Bool = false;

	function coolStartDeath(?volume:Float = 1):Void
	{
		FlxG.sound.playMusic(Paths.music(loopSoundName), volume);
		ableToCamBeat = true;
		boyfriend.playAnim('deathLoop');
	}

	function endBullshit():Void
	{
		if (!isEnding)
		{
			ableToCamBeat = false;
			FlxTween.tween(FlxG.camera, {zoom: FlxG.camera.zoom + 0.06}, 1.6, {ease: FlxEase.circOut});
			isEnding = true;
			boyfriend.playAnim('deathConfirm', true);
			FlxG.sound.music.stop();
			FlxG.sound.play(Paths.music(endSoundName));
			new FlxTimer().start(0.7, function(tmr:FlxTimer)
			{
				FlxG.camera.fade(FlxColor.BLACK, 2, false, function()
				{
					MusicBeatState.resetState();
				});
			});
			PlayState.instance.callOnLuas('onGameOverConfirm', [true]);
			PlayState.instance.callOnHscript('onGameOverConfirm', [true]);
		}
	}
}

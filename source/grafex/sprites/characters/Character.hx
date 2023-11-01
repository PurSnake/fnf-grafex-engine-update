package grafex.sprites.characters;

import grafex.states.playstate.PlayState;
import grafex.sprites.background.TankmenBG;
import grafex.system.song.Song;
import grafex.system.Conductor;
import grafex.system.Paths;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.animation.FlxBaseAnimation;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.tweens.FlxTween;
import flixel.util.FlxSort;
import grafex.system.song.Section.SwagSection;
import external.animateatlas.AtlasFrameMaker;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.animation.FlxAnimationController;
import sys.io.File;
import sys.FileSystem;

import openfl.utils.Assets;
import tjson.TJSON as Json;
import grafex.util.ClientPrefs;

import flixel.math.FlxMath;

using StringTools;

typedef CharacterFile = {
	var animations:Array<AnimArray>;
	var image:String;
	var scale:Float;
	var sing_duration:Float;
	var healthicon:String;
	var healthicon_type:String;
	var healthicon_scale:Float;
	var healthicon_offsets:Array<Float>;

	var position:Array<Float>;
	var camera_position:Array<Float>;

	var sing_anims_prefix:String;

	var flip_x:Bool;
	var no_antialiasing:Bool;
	var healthbar_colors:Array<Int>;
	var healthbar_colors2:Array<Int>;
	var gameover_properties:Array<String>;
}

typedef AnimArray = {
	var anim:String;
	var name:String;
	var fps:Int;
	var loop:Bool;
	var indices:Array<Int>;
	var offsets:Array<Int>;
	var image:String;
}

class Character extends FlxSprite
{
	public var animOffsets:Map<String, Array<Float>> = [];
	public var debugMode:Bool = false;

	// For swapping out huge sheets
	public var framesList:Map<String, FlxFramesCollection> = []; // Image, Frames
	public var imageNames:Map<String, String> = []; // Anim Name, Image
	public var animStates:Map<String, FlxAnimationController> = []; // Image, Anim Controller
	public var curImage:String; // Current image name
	public static var tempAnimState:FlxAnimationController; // Just so that the real one won't be cleared (It crashes if it's null)

	public var useAtlas:Bool;

	public var isPlayer:Bool = false;
	public var curCharacter:String = DEFAULT_CHARACTER;

	public var colorTween:FlxTween;
	public var holdTimer:Float = 0;
	public var heyTimer:Float = 0;
	public var specialAnim:Bool = false;
	public var animationNotes:Array<Dynamic> = [];
	public var stunned:Bool = false;
	public var singDuration:Float = 4; //Multiplier of how long a character holds the sing pose
	public var idleSuffix:String = '';
	public var singAnimsPrefix:String = 'sing';
	public var danceIdle:Bool = false; //Character use "danceLeft" and "danceRight" instead of "idle"
	public var skipDance:Bool = false;

	public var healthIcon:String = 'face';
	public var healthIconType:String = 'duo';

	public static var healthIconTypes:Array<String> = ['solo', 'duo', 'trioWin', 'trioLose', 'quadro', 'classic-animated', 'modern-animated', 'custom'];

	public var animationsArray:Array<AnimArray> = [];

	public var positionArray:Array<Float> = [0, 0];
	public var cameraPosition:Array<Float> = [0, 0];
	public var iconOffsets:Array<Float> = [0, 0];

	public var hasMissAnimations:Bool = false;

	//Used for Game Over Properties
	public var deathChar:String = 'bf-dead';
	public var deathSound:String = 'fnf_loss_sfx';
	public var deathConfirm:String = 'gameOverEnd';
	public var deathMusic:String = 'gameOver';
	
	//Used on Character Editor
	public var imageFile:String = '';
	public var jsonScale:Float = 1;
	public var iconScale:Float = 1;
	public var noAntialiasing:Bool = false;
	public var originalFlipX:Bool = false;
	public var healthColorArray:Array<Int> = [255, 0, 0];
	public var healthColorArray2:Array<Int> = [255, 0, 0];

	public var properties:Map<String, Dynamic> = new Map<String, Dynamic>();

	public static var DEFAULT_CHARACTER:String = 'bf'; //In case a character is missing, it will use BF on its place
	public function new(x:Float, y:Float, ?character:String = 'none', ?isPlayer:Bool = false)
	{
		super(x, y);

		curCharacter = character;
		this.isPlayer = isPlayer;
		antialiasing = ClientPrefs.globalAntialiasing;

		var library:String = null;
		switch (curCharacter)
		{
			//case 'your character name in case you want to hardcode him instead':

			default:
				var characterPath:String = 'characters/' + curCharacter + '.json';

				#if MODS_ALLOWED
				var path:String = Paths.modFolders(characterPath);
				if (!FileSystem.exists(path)) {
					path = Paths.getPreloadPath(characterPath);
				}

				if (!FileSystem.exists(path))		
				#else
				var path:String = Paths.getPreloadPath(characterPath);
				if (!Assets.exists(path))
				#end
				{
					path = Paths.getPreloadPath('characters/' + DEFAULT_CHARACTER + '.json'); //If a character couldn't be found, change him to BF just to prevent a crash
				}

				#if MODS_ALLOWED
				var rawJson = File.getContent(path);
				#else
				var rawJson = Assets.getText(path);
				#end

				var json:CharacterFile = cast Json.parse(rawJson);
				useAtlas = false;

				#if MODS_ALLOWED
				var modAnimToFind:String = Paths.modFolders('images/' + json.image + '/Animation.json');
				var animToFind:String = Paths.getPath('images/' + json.image + '/Animation.json', TEXT);
				if (FileSystem.exists(modAnimToFind) || FileSystem.exists(animToFind) || Assets.exists(animToFind))
				#else
				if (Assets.exists(Paths.getPath('images/' + json.image + '/Animation.json', TEXT)))
				#end
					useAtlas = true;

				var charFrames:FlxFramesCollection;

				if (!useAtlas) {
					charFrames = Paths.getAtlas(json.image);
					for (anim in json.animations) {
						if (anim.image != null && anim.image.length > 0 && !framesList.exists(anim.image)) {
							framesList.set(anim.image, Paths.getAtlas(anim.image));
						}
					}
				}
				else
				{
					charFrames = AtlasFrameMaker.construct(json.image);
					for (anim in json.animations) {
						if (anim.image != null && anim.image.length > 0 && !framesList.exists(anim.image)) {
							framesList.set(anim.image, AtlasFrameMaker.construct(anim.image));
						}
					}
				}
				imageFile = json.image;


				var charFinalFrames = new FlxFramesCollection(null);
				charFinalFrames.frames = charFrames.frames;
				for (shittyFrameCollection in framesList) {
 					charFinalFrames.frames = charFinalFrames.frames.concat(shittyFrameCollection.frames);
				}

				frames = charFinalFrames;

				if(json.scale != 1) {
					jsonScale = json.scale;
					setGraphicSize(Std.int(width * jsonScale));
					updateHitbox();
				}

				positionArray = json.position;
				cameraPosition = json.camera_position;

				iconOffsets = json.healthicon_offsets;
				if(iconOffsets == null)
					iconOffsets = [0, 0];

				healthIcon = json.healthicon;

				healthIconType = json.healthicon_type;
				if (healthIconType.length < 1 && healthIconType == null) healthIconType = 'duo';

				singAnimsPrefix = json.sing_anims_prefix;
				if (singAnimsPrefix.length < 1 && singAnimsPrefix == null) singAnimsPrefix = 'sing';

				singDuration = json.sing_duration;
				flipX = json.flip_x;
				if(json.no_antialiasing) {
					antialiasing = false;
					noAntialiasing = true;
				}

				if (json.gameover_properties != null)
				{
					deathChar = json.gameover_properties[0];
					deathSound = json.gameover_properties[1];
					deathMusic = json.gameover_properties[2]; // by BeastlyGhost - PurSnake
					deathConfirm = json.gameover_properties[3];
				}

				iconScale = json.healthicon_scale;
				if(Math.isNaN(iconScale) || iconScale == 0) iconScale = 1;
	
				if(json.healthbar_colors != null && json.healthbar_colors.length > 2) healthColorArray = json.healthbar_colors;
                                
				if(json.healthbar_colors2 != null && json.healthbar_colors2.length > 2) healthColorArray2 = json.healthbar_colors2;  
				else healthColorArray2 = healthColorArray;

				antialiasing = !noAntialiasing;
				if(!ClientPrefs.globalAntialiasing) antialiasing = false;

				animationsArray = json.animations;
				if(animationsArray != null && animationsArray.length > 0) {
					for (anim in animationsArray) {
						var animAnim:String = '' + anim.anim;
						var animName:String = '' + anim.name;
						var animFps:Int = anim.fps;
						var animLoop:Bool = anim.loop; //Bruh
						var animIndices:Array<Int> = anim.indices;
						var animImage:String = anim.image;

						if (animImage == null || animImage.length == 0) {
							animImage = imageFile;
						}

						if (animIndices != null && animIndices.length > 0) {
							animation.addByIndices(animAnim, animName, animIndices, "", animFps, animLoop);
						} else {
							animation.addByPrefix(animAnim, animName, animFps, animLoop);
						}

						if(anim.offsets != null && anim.offsets.length > 1) {
							addOffset(anim.anim, anim.offsets[0], anim.offsets[1]);
						}
					}
				} else {
					quickAnimAdd('idle', 'BF idle dance');
				}
		}
		originalFlipX = flipX;

		if(animOffsets.exists(singAnimsPrefix+'LEFTmiss') || animOffsets.exists(singAnimsPrefix+'DOWNmiss') || animOffsets.exists(singAnimsPrefix+'UPmiss') || animOffsets.exists(singAnimsPrefix+'RIGHTmiss')) hasMissAnimations = true;
		recalculateDanceIdle();
		dance();

		if (isPlayer)
			flipX = !flipX;

		switch(curCharacter)
		{
			case 'pico-speaker':
				skipDance = true;
				loadMappedAnims();
				playAnim("shoot1");
		}
	}

	override function update(elapsed:Float)
	{
		if(!debugMode && animation.curAnim != null)
		{
			if(animation.curAnim.finished && animation.getByName(animation.curAnim.name + '-loop') != null)
				playAnim(animation.curAnim.name + '-loop');

			if(heyTimer > 0)
			{
				heyTimer -= elapsed * PlayState.instance.playbackRate;
				if(heyTimer <= 0)
				{
					if(specialAnim && animation.curAnim.name == 'hey' || animation.curAnim.name == 'cheer')
					{
						specialAnim = false;
						dance();
					}
					heyTimer = 0;
				}

			}
			else if(specialAnim && animation.curAnim.finished)
			{
				specialAnim = false;
				dance();
			}
			else if (animation.curAnim.name.endsWith('miss') && animation.curAnim.finished)
			{
				dance();
				animation.finish();
			}

			switch(curCharacter)
			{
				case 'pico-speaker':
					if(animationNotes.length > 0 && Conductor.songPosition > animationNotes[0][0])
					{
						var noteData:Int = 1;
						if(animationNotes[0][1] > 2) noteData = 3;

						noteData += FlxG.random.int(0, 1);
						playAnim('shoot' + noteData, true);
						animationNotes.shift();
					}
					if(animation.curAnim.finished) playAnim(animation.curAnim.name, false, false, animation.curAnim.frames.length - 3);
			}


			if (!isPlayer)
			{
				if (animation.curAnim.name.startsWith(singAnimsPrefix))
				{
					holdTimer += elapsed;
				}

				if (holdTimer >= Conductor.stepCrochet * (0.0011 / (FlxG.sound.music != null ? FlxG.sound.music.pitch : 1)) * singDuration)
				{
					dance();
					holdTimer = 0;
				}
			}
			else // Boyfriend.hx remnants cuz it doesn't make sense to me
			{
				if (!debugMode && animation.curAnim != null)
				{
					if (animation.curAnim.name.startsWith(singAnimsPrefix))
						holdTimer += elapsed;
					else
						holdTimer = 0;

					if (animation.curAnim.name.endsWith('miss') && animation.curAnim.finished && !debugMode)
					{
						playAnim('idle', true, false, 10);
					}

				}
			}

		}
		super.update(elapsed);
	}

	public var danced:Bool = false;

	/**
	 * FOR GF DANCING SHIT
	 */
	public function dance()
	{
		if (!debugMode && !skipDance && !specialAnim)
		{
			if(danceIdle)
			{
				danced = !danced;

				if (danced)
					playAnim('danceRight' + idleSuffix);
				else
					playAnim('danceLeft' + idleSuffix);
			}
			else if(animation.getByName('idle' + idleSuffix) != null) {
				playAnim('idle' + idleSuffix);
			}
		}
	}

	public function playAnim(AnimName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0):Void
	{
		specialAnim = false;
		animation.play(AnimName, Force, Reversed, Frame);

		if (animOffsets.exists(AnimName))
		{
			var daOffset = animOffsets.get(AnimName);
			offset.set(daOffset[0], daOffset[1]);
		}
		else
			offset.set(0, 0);

		if (curCharacter.startsWith('gf'))
		{
			if (AnimName == singAnimsPrefix+'LEFT')
			{
				danced = true;
			}
			else if (AnimName == singAnimsPrefix+'RIGHT')
			{
				danced = false;
			}

			if (AnimName == singAnimsPrefix+'UP' || AnimName == singAnimsPrefix+'DOWN')
			{
				danced = !danced;
			}
		}
	}

	function loadMappedAnims():Void
	{
		var noteData:Array<SwagSection> = Song.loadFromJson('picospeaker', Paths.formatToSongPath(PlayState.SONG.song)).notes;
		for (section in noteData) {
			for (songNotes in section.sectionNotes) {
				animationNotes.push(songNotes);
			}
		}
		TankmenBG.animationNotes = animationNotes;
		animationNotes.sort(sortAnims);
	}

	function sortAnims(Obj1:Array<Dynamic>, Obj2:Array<Dynamic>):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1[0], Obj2[0]);
	}

	public var danceEveryNumBeats:Int = 2;
	private var settingCharacterUp:Bool = true;
	public function recalculateDanceIdle() {
		var lastDanceIdle:Bool = danceIdle;
		danceIdle = (animation.getByName('danceLeft' + idleSuffix) != null && animation.getByName('danceRight' + idleSuffix) != null);

		if(settingCharacterUp)
		{
			danceEveryNumBeats = (danceIdle ? 1 : 2);
		}
		else if(lastDanceIdle != danceIdle)
		{
			var calc:Float = danceEveryNumBeats;
			if(danceIdle)
				calc /= 2;
			else
				calc *= 2;

			danceEveryNumBeats = Math.round(Math.max(calc, 1));
		}
		settingCharacterUp = false;
	}

	public function addOffset(name:String, x:Float = 0, y:Float = 0)
	{
		animOffsets[name] = [x, y];
	}

	public function quickAnimAdd(name:String, anim:String)
	{
		animation.addByPrefix(name, anim, 24, false);
	}
}

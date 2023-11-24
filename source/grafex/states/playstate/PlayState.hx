package grafex.states.playstate;

import grafex.system.loader.GrfxStage;
import grafex.states.options.OptionsMenu;
import grafex.states.options.substates.ControlsSubState;
import grafex.states.substates.LoadingState;
import grafex.states.substates.GameplayChangersSubstate;
import grafex.states.substates.PauseSubState;
import grafex.states.editors.ChartingState;
import grafex.states.editors.CharacterEditorState;
import grafex.states.substates.GameOverSubstate;
import openfl.utils.Dictionary;
import grafex.system.statesystem.MusicBeatState;
import grafex.system.song.Section.SwagSection;
import grafex.system.song.Song.SwagSong;
import grafex.system.song.Song;
import grafex.system.notes.Note.EventNote;
import grafex.system.notes.*;
import grafex.system.CustomFadeTransition;
import grafex.system.script.FunkinLua;
import grafex.system.script.GrfxScriptHandler;
import grafex.system.Conductor.Rating;
import grafex.system.Conductor;
import grafex.sprites.attached.*;
import grafex.sprites.background.*;
import grafex.sprites.HealthIcon;
import grafex.sprites.characters.Character;
import grafex.sprites.FixedCamera;
import grafex.effects.WiggleEffect;
import grafex.effects.WiggleEffect.WiggleEffectType;
import grafex.effects.PhillyGlow.PhillyGlowGradient;
import grafex.effects.PhillyGlow.PhillyGlowParticle;
import grafex.data.StageData;
import grafex.data.WeekData;
import grafex.data.RatingsData;
import grafex.cutscenes.CutsceneHandler;
import grafex.cutscenes.DialogueBoxPsych;
import grafex.cutscenes.DialogueBoxPsych.DialogueFile;
import grafex.cutscenes.DialogueBox;
import lime.app.Application;
import openfl.filters.BitmapFilter;
import flixel.FlxBasic;
import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxObject;
// import flixel.FlxSprite;
// import flixel.FlxCamera;
import flixel.util.FlxSave;
import flixel.effects.particles.FlxEmitter;
import flixel.effects.particles.FlxParticle;
import flixel.FlxState;
import flixel.FlxSubState;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.effects.FlxTrail;
import flixel.addons.effects.FlxTrailArea;
import flixel.addons.effects.chainable.FlxEffectSprite;
import flixel.addons.effects.chainable.FlxWaveEffect;
import flixel.addons.transition.FlxTransitionableState;
import flixel.graphics.atlas.FlxAtlas;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.math.FlxAngle;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import external.animateatlas.AtlasFrameMaker;
import flixel.tweens.FlxTween;
import flixel.ui.FlxBar;
import flixel.util.FlxCollision;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import flixel.util.FlxStringUtil;
import flixel.util.FlxTimer;
import flixel.system.scaleModes.RatioScaleMode;
import haxe.Json;
import lime.utils.Assets;
import openfl.display.BlendMode;
import openfl.display.StageQuality;
import openfl.filters.ShaderFilter;
import openfl.utils.Assets as OpenFlAssets;
import flixel.group.FlxSpriteGroup;
import flixel.input.keyboard.FlxKey;
import grafex.util.ClientPrefs;
import grafex.util.Utils;
import grafex.util.Highscore;
import openfl.events.KeyboardEvent;
import openfl.filters.ShaderFilter;
import openfl.Lib;
import openfl.filters.BitmapFilter;
import openfl.filters.BlurFilter;
import openfl.filters.ColorMatrixFilter;
#if !flash
import flixel.addons.display.FlxRuntimeShader;
import openfl.filters.ShaderFilter;
#end
#if sys
import sys.FileSystem;
import sys.io.File;
#end
#if VIDEOS_ALLOWED
#if (hxCodec >= "2.6.1")
import hxcodec.VideoHandler as MP4Handler;
#elseif (hxCodec == "2.6.0")
import VideoHandler as MP4Handler;
#else
import vlc.MP4Handler;
#end
#end
#if desktop
import external.Discord.DiscordClient;
#end

using StringTools;

class PlayState extends MusicBeatState
{
	var iconRPC:String = "";

	public static var STRUM_X = 42;
	public static var STRUM_X_MIDDLESCROLL = -278;

	private var isCameraOnForcedPos:Bool = false;

	public var boyfriendMap:Map<String, Character> = new Map();
	public var dadMap:Map<String, Character> = new Map();
	public var gfMap:Map<String, Character> = new Map();
	public var variables:Map<String, Dynamic> = new Map<String, Dynamic>();
	public var modchartTweens:Map<String, FlxTween> = new Map<String, FlxTween>();
	public var modchartSprites:Map<String, ModchartSprite> = new Map<String, ModchartSprite>();
	public var modchartTimers:Map<String, FlxTimer> = new Map<String, FlxTimer>();
	public var modchartSounds:Map<String, FlxSound> = new Map<String, FlxSound>();
	public var modchartTexts:Map<String, ModchartText> = new Map<String, ModchartText>();
	public var modchartSaves:Map<String, FlxSave> = new Map<String, FlxSave>();
	public var modchartObjects:Map<String, FlxSprite> = new Map<String, FlxSprite>();

	var skin:String = 'noteSplashes';
	var hue:Float = 0;
	var sat:Float = 0;
	var brt:Float = 0;

	public var BF_X:Float = 770;
	public var BF_Y:Float = 100;
	public var DAD_X:Float = 100;
	public var DAD_Y:Float = 100;
	public var GF_X:Float = 400;
	public var GF_Y:Float = 130;

	public var songSpeedTween:FlxTween;
	public var songSpeed(default, set):Float = 1;
	public var songSpeedType:String = "multiplicative";
	public var noteKillOffset:Float = 350;

	public var playbackRate(default, set):Float = 1;

	public var boyfriendGroup:FlxSpriteGroup;
	public var dadGroup:FlxSpriteGroup;
	public var gfGroup:FlxSpriteGroup;

	public static var curStage:String = '';
	public static var isPixelStage:Bool = false;
	public static var NotesCanMoveCam:Bool = true;

	public var smoothCamera:Bool = true;
	public var smoothIcons:Bool = false;
	public var opponentSplash:Bool = false;

	public static var SONG:SwagSong = null;
	public static var isStoryMode:Bool = false;
	public static var storyWeek:Int = 0;
	public static var storyPlaylist:Array<String> = [];
	public static var storyDifficulty:Int = 1;

	var stageData:StageFile;

	public var spawnTime:Float = 2500;

	public var vocals:FlxSound;
	public var vocals2:FlxSound;

	public var dad:Character = null;
	public var gf:Character = null;
	public var boyfriend:Character = null;

	public var characters = [];

	public var notes:FlxTypedGroup<Note>;

	public var sustainNotes:FlxTypedGroup<Note>;
	public var regularNotes:FlxTypedGroup<Note>;

	public var unspawnNotes:Array<Note> = [];
	public var eventNotes:Array<EventNote> = [];

	private var strumLine:FlxSprite;

	// Handles the new epic mega sexy cam code that i've done
	public var camFollow:FlxPoint;
	public var camFollowPos:FlxObject;

	private static var prevCamFollow:FlxPoint;
	private static var prevCamFollowPos:FlxObject;

	public var strumLineNotes:FlxTypedGroup<StrumNote>;
	public var opponentStrums:FlxTypedGroup<StrumNote>;
	public var playerStrums:FlxTypedGroup<StrumNote>;
	public var grpNoteSplashes:FlxTypedGroup<NoteSplash>;
	public var grpSusSplashes:FlxTypedGroup<SusSplash>;

	public var camZooming:Bool = true;
	public var camZoomingMult:Float = 1;
	public var camZoomingDecay:Float = 1;
	public var camZoomingFreq:Int = 0;
	public var camZoomingExVal:Int = 0;
	public var iconsZoomingFreq:Int = 1;
	public var iconsZoomingDecay:Float = 1;
	public var curSong:String = "";

	public var gfSpeed:Int = 1;
	public var health:Float = 1;
	public var displayedHealth:Float = 50;
	public var combo:Int = 0;
	public var maxCombo:Int = 0;

	public var isHealthCheckingEnabled:Bool = true;
	public var healthBarBG:AttachedSprite;
	public var healthBar:FlxBar;
	public var healthBarWN:FlxBar;
	public var timeBarBG:FlxSprite;
	public var timeBar:FlxBar;

	public var songPercent:Float = 0;

	public var ratingsData:Array<Rating> = [];
	public var sicks:Int = 0;
	public var goods:Int = 0;
	public var bads:Int = 0;
	public var shits:Int = 0;
	public var ratingsSubPath:String = '';
	public var showRating:Bool = true;

	private var generatedMusic:Bool = false;

	public var endingSong:Bool = false;
	public var startingSong:Bool = false;

	private var updateTime:Bool = true;

	public static var changedDifficulty:Bool = false;
	public static var chartingMode:Bool = false;

	// Gameplay settings
	public var healthGain:Float = 1;
	public var healthLoss:Float = 1;
	public var instakillOnMiss:Bool = false;
	public var cpuControlled:Bool = false;
	public var practiceMode:Bool = false;

	public var botplaySine:Float = 0;
	public var botplayTxt:FlxText;

	public var iconGroup:FlxTypedGroup<HealthIcon>;
	public var healthBarGroup:FlxTypedGroup<Dynamic>;
	public var iconP1:HealthIcon;
	public var iconP2:HealthIcon;

	public var stageBuild:GrfxStage;

	public var classicHealthBar:Bool = false;

	public var camGame:FixedCamera;
	public var camHUD:FixedCamera;
	public var camPAUSE:FlxCamera;
	public var camOther:FlxCamera;

	public var cameraSpeed:Float = 1;

	var dadbattleBlack:BGSprite;
	var dadbattleLight:BGSprite;
	var dadbattleSmokes:FlxSpriteGroup;

	var halloweenBG:BGSprite;
	var halloweenWhite:BGSprite;
	var lightningStrikeBeat:Int = 0;
	var lightningOffset:Int = 8;

	var phillyLightsColors:Array<FlxColor>;
	var phillyWindow:BGSprite;
	var phillyStreet:BGSprite;
	var phillyTrain:BGSprite;
	var blammedLightsBlack:FlxSprite;
	var phillyWindowEvent:BGSprite;
	var trainSound:FlxSound;

	var phillyGlowGradient:PhillyGlow.PhillyGlowGradient;
	var phillyGlowParticles:FlxTypedGroup<PhillyGlow.PhillyGlowParticle>;

	var limoKillingState:Int = 0;
	var limo:BGSprite;
	var limoMetalPole:BGSprite;
	var limoLight:BGSprite;
	var limoCorpse:BGSprite;
	var limoCorpseTwo:BGSprite;
	var bgLimo:BGSprite;
	var grpLimoParticles:FlxTypedGroup<BGSprite>;
	var grpLimoDancers:FlxTypedGroup<BackgroundDancer>;
	var fastCar:BGSprite;
	var limoSpeed:Float = 0;

	var upperBoppers:BGSprite;
	var bottomBoppers:BGSprite;
	var santa:BGSprite;
	var heyTimer:Float;

	var bgGirls:BackgroundGirls;
	var wiggleShit:WiggleEffect = new WiggleEffect();
	var bgGhouls:BGSprite;

	var tankWatchtower:BGSprite;
	var tankGround:BGSprite;
	var tankmanRun:FlxTypedGroup<TankmenBG>;
	var foregroundSprites:FlxTypedGroup<BGSprite>;

	public var canShitButtons:Bool = true;

	// this probably doesnt need to exist but whatever
	public var hudIsSwapped:Bool = false;

	public var songScore:Int = 0;
	public var songHits:Int = 0;
	public var songMisses:Int = 0;
	public var scoreTxt:FlxText;

	var scoreTxtTween:FlxTween;
	var subtitlesTxtTween:FlxTween;
	var subtitlesTxtAlphaTween:FlxTween;

	// public var comboTimer:FlxTimer;
	public var comboScore:Int = 0;
	public var comboNum:Int = 0;
	public var comboPath:String = 'combo/';

	public static var campaignScore:Int = 0;
	public static var campaignMisses:Int = 0;
	public static var seenCutscene:Bool = false;
	public static var deathCounter:Int = 0;

	public var defaultCamZoom:Float = 1.05;

	var allNotesMs:Float = 0;
	var averageMs:Float = 0;

	var isEventWorking:Bool = false;

	// how big to stretch the pixel art assets
	public static var daPixelZoom:Float = 6;

	public var singAnimations:Array<String> = ['LEFT', 'DOWN', 'UP', 'RIGHT'];

	public var inCutscene:Bool = false;
	public var skipCountdown:Bool = false;

	var songLength:Float = 0;

	public var boyfriendCameraOffset:Array<Float> = null;
	public var opponentCameraOffset:Array<Float> = null;
	public var girlfriendCameraOffset:Array<Float> = null;

	public var ratingsCameraOffset:Array<Float> = null;

	public var cameraMoveOffset:Float = 10;

	public var camCharsPositions:Map<String, Array<Float>> = new Map<String, Array<Float>>();

	#if desktop
	// Discord RPC variables
	var storyDifficultyText:String = "";
	var detailsText:String = "";
	var detailsPausedText:String = "";
	#end

	// Lua shit
	public static var instance:PlayState;

	public var luaArray:Array<FunkinLua> = [];

	private var luaDebugGroup:FlxTypedGroup<DebugLuaText>;

	public var introSoundsSuffix:String = '';

	public var hscriptArray:Array<GrfxHxScript> = [];

	// Debug buttons
	private var debugKeysChart:Array<FlxKey>;
	private var debugKeysCharacter:Array<FlxKey>;

	// Less laggy controls
	private var keysArray:Array<Dynamic>;
	private var controlArray:Array<String>;

	var precacheList:Map<String, String> = new Map<String, String>();

	// stores the last judgement object
	public static var lastRating:FlxSprite;
	// stores the last combo sprite object
	public static var lastCombo:FlxSprite;
	// stores the last combo score objects in an array
	public static var lastScore:Array<FlxSprite> = [];

	public var sub:FlxText;

	override public function create()
	{
		Paths.clearStoredMemory();

		instance = this;

		trace('Switched state to: ' + Type.getClassName(Type.getClass(this)));

		debugKeysChart = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_1'));
		debugKeysCharacter = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_2'));

		playbackRate = ClientPrefs.getGameplaySetting('songspeed', 1);

		keysArray = [
			ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_left')),
			ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_down')),
			ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_up')),
			ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_right'))
		];

		controlArray = ['NOTE_LEFT', 'NOTE_DOWN', 'NOTE_UP', 'NOTE_RIGHT'];

		ratingsData.push(new Rating('sick')); // default rating

		var rating:Rating = new Rating('good');
		rating.ratingMod = 0.7;
		rating.score = 200;
		rating.noteSplash = false;
		ratingsData.push(rating);

		var rating:Rating = new Rating('bad');
		rating.ratingMod = 0.4;
		rating.score = 100;
		rating.noteSplash = false;
		ratingsData.push(rating);

		var rating:Rating = new Rating('shit');
		rating.ratingMod = 0;
		rating.score = 50;
		rating.noteSplash = false;
		ratingsData.push(rating);

		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		// Gameplay settings
		healthGain = ClientPrefs.getGameplaySetting('healthgain', 1);
		healthLoss = ClientPrefs.getGameplaySetting('healthloss', 1);
		instakillOnMiss = ClientPrefs.getGameplaySetting('instakill', false);
		practiceMode = ClientPrefs.getGameplaySetting('practice', false);
		cpuControlled = ClientPrefs.getGameplaySetting('botplay', false);

		camGame = new FixedCamera();
		camHUD = new FixedCamera();
		camOther = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		camOther.bgColor.alpha = 0;

		camPAUSE = new FlxCamera();
		camPAUSE.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camHUD, false);
		FlxG.cameras.add(camOther, false);
		FlxG.cameras.add(camPAUSE, false);
		grpNoteSplashes = new FlxTypedGroup<NoteSplash>();
		grpSusSplashes = new FlxTypedGroup<SusSplash>();

		FlxG.cameras.setDefaultDrawTarget(camGame, true);

		persistentUpdate = true;
		persistentDraw = true;

		if (SONG == null)
			SONG = Song.loadFromJson('tutorial');

		Conductor.mapBPMChanges(SONG);
		Conductor.changeBPM(SONG.bpm);

		#if desktop
		storyDifficultyText = Utils.difficulties[storyDifficulty];

		// String that contains the mode defined here so it isn't necessary to call changePresence for each mode

		isStoryMode ? detailsText = "Story Mode: " + WeekData.getCurrentWeek().weekName : detailsText = "Freeplay";

		// String for when the game is paused
		detailsPausedText = "Paused - " + detailsText;
		#end

		iconRPC = SONG.player2;

		GameOverSubstate.resetVariables();
		var songName:String = Paths.formatToSongPath(SONG.song);
		curStage = SONG.stage;

		Application.current.window.title = Main.appTitle
			+ ' // '
			+ StringTools.replace(SONG.song, '-', ' ')
			+ ' ['
			+ storyDifficultyText.toUpperCase()
			+ ']'
			+ (PlayState.SONG.composedBy != '' ? ' - ' + PlayState.SONG.composedBy : '');

		if (SONG.stage == null || SONG.stage.length < 1)
		{
			switch (songName)
			{
				case 'spookeez' | 'south' | 'monster':
					curStage = 'spooky';
				case 'pico' | 'blammed' | 'philly' | 'philly-nice':
					curStage = 'philly';
				case 'milf' | 'satin-panties' | 'high':
					curStage = 'limo';
				case 'cocoa' | 'eggnog':
					curStage = 'mall';
				case 'winter-horrorland':
					curStage = 'mallEvil';
				case 'senpai' | 'roses':
					curStage = 'school';
				case 'thorns':
					curStage = 'schoolEvil';
				case 'ugh' | 'guns' | 'stress':
					curStage = 'tank';
				default:
					curStage = 'stage';
			}
		}

		SONG.stage = curStage;
		stageData = StageData.getStageFile(curStage);
		if (stageData == null)
		{ // Stage couldn't be found, create a dummy stage for preventing a crash
			stageData = {
				name: "",
				directory: "",
				defaultZoom: 0.9,
				isPixelStage: false,

				boyfriend: [770, 100],
				girlfriend: [400, 130],
				opponent: [100, 100],
				hide_girlfriend: false,

				ratings_offset: [0, 0, 0, 0],
				camera_boyfriend: [0, 0],
				camera_opponent: [0, 0],
				camera_girlfriend: [0, 0],
				camera_speed: 1,
				dynamic_camera: true
			};
		}

		defaultCamZoom = stageData.defaultZoom;
		isPixelStage = stageData.isPixelStage;
		NotesCanMoveCam = stageData.dynamic_camera;
		BF_X = stageData.boyfriend[0];
		BF_Y = stageData.boyfriend[1];
		GF_X = stageData.girlfriend[0];
		GF_Y = stageData.girlfriend[1];
		DAD_X = stageData.opponent[0];
		DAD_Y = stageData.opponent[1];

		if (stageData.camera_speed != null)
			cameraSpeed = stageData.camera_speed;

		ratingsCameraOffset = stageData.ratings_offset;
		if (ratingsCameraOffset == null)
			ratingsCameraOffset = [0, 0, 0, 0];

		boyfriendCameraOffset = stageData.camera_boyfriend;
		if (boyfriendCameraOffset == null) // Fucks sake should have done it since the start :rolling_eyes:
			boyfriendCameraOffset = [0, 0];

		opponentCameraOffset = stageData.camera_opponent;
		if (opponentCameraOffset == null)
			opponentCameraOffset = [0, 0];

		girlfriendCameraOffset = stageData.camera_girlfriend;
		if (girlfriendCameraOffset == null)
			girlfriendCameraOffset = [0, 0];

		boyfriendGroup = new FlxSpriteGroup(BF_X, BF_Y);
		dadGroup = new FlxSpriteGroup(DAD_X, DAD_Y);
		gfGroup = new FlxSpriteGroup(GF_X, GF_Y);

		//CustomFadeTransition.nextCamera = camOther;

		super.create();

		//CustomFadeTransition.nextCamera = camOther;

		stageBuild = new GrfxStage(curStage);

		if (stageBuild.exist)
			add(stageBuild);

		setOnLuas('cameraMoveOffset', cameraMoveOffset);

		switch (curStage)
		{
			case 'stage': // Week 1
				var bg:BGSprite = new BGSprite('stageback', -600, -200, 0.9, 0.9);
				add(bg);

				var stageFront:BGSprite = new BGSprite('stagefront', -650, 600, 0.9, 0.9);
				stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
				stageFront.updateHitbox();
				add(stageFront);
				if (!ClientPrefs.lowQuality)
				{
					var stageLight:BGSprite = new BGSprite('stage_light', -125, -100, 0.9, 0.9);
					stageLight.setGraphicSize(Std.int(stageLight.width * 1.1));
					stageLight.updateHitbox();
					add(stageLight);
					var stageLight:BGSprite = new BGSprite('stage_light', 1225, -100, 0.9, 0.9);
					stageLight.setGraphicSize(Std.int(stageLight.width * 1.1));
					stageLight.updateHitbox();
					stageLight.flipX = true;
					add(stageLight);

					var stageCurtains:BGSprite = new BGSprite('stagecurtains', -500, -300, 1.3, 1.3);
					stageCurtains.setGraphicSize(Std.int(stageCurtains.width * 0.9));
					stageCurtains.updateHitbox();
					add(stageCurtains);
				}
				dadbattleSmokes = new FlxSpriteGroup(); // troll'd

			case 'spooky': // Week 2
				if (!ClientPrefs.lowQuality)
				{
					halloweenBG = new BGSprite('halloween_bg', -200, -100, ['halloweem bg0', 'halloweem bg lightning strike']);
				}
				else
				{
					halloweenBG = new BGSprite('halloween_bg_low', -200, -100);
				}
				add(halloweenBG);

				halloweenWhite = new BGSprite(null, -800, -400, 0, 0);
				halloweenWhite.makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.WHITE);
				halloweenWhite.alpha = 0;
				halloweenWhite.blend = ADD;

				// PRECACHE SOUNDS
				precacheList.set('thunder_1', 'sound');
				precacheList.set('thunder_2', 'sound');

			case 'philly': // Week 3
				if (!ClientPrefs.lowQuality)
				{
					var bg:BGSprite = new BGSprite('philly/sky', -100, 0, 0.1, 0.1);
					add(bg);
				}

				var city:BGSprite = new BGSprite('philly/city', -10, 0, 0.3, 0.3);
				city.setGraphicSize(Std.int(city.width * 0.85));
				city.updateHitbox();
				add(city);

				phillyLightsColors = [0xFF31A2FD, 0xFF31FD8C, 0xFFFB33F5, 0xFFFD4531, 0xFFFBA633];
				phillyWindow = new BGSprite('philly/window', city.x, city.y, 0.3, 0.3);
				phillyWindow.setGraphicSize(Std.int(phillyWindow.width * 0.85));
				phillyWindow.updateHitbox();
				add(phillyWindow);
				phillyWindow.alpha = 0;

				if (!ClientPrefs.lowQuality)
				{
					var streetBehind:BGSprite = new BGSprite('philly/behindTrain', -40, 50);
					add(streetBehind);
				}

				phillyTrain = new BGSprite('philly/train', 2000, 360);
				add(phillyTrain);

				trainSound = new FlxSound().loadEmbedded(Paths.sound('train_passes'));
				FlxG.sound.list.add(trainSound);

				phillyStreet = new BGSprite('philly/street', -40, 50);
				add(phillyStreet);

			case 'limo': // Week 4
				var skyBG:BGSprite = new BGSprite('limo/limoSunset', -120, -50, 0.1, 0.1);
				add(skyBG);

				if (!ClientPrefs.lowQuality)
				{
					limoMetalPole = new BGSprite('gore/metalPole', -500, 220, 0.4, 0.4);
					add(limoMetalPole);

					bgLimo = new BGSprite('limo/bgLimo', -150, 480, 0.4, 0.4, ['background limo pink'], true);
					add(bgLimo);

					limoCorpse = new BGSprite('gore/noooooo', -500, limoMetalPole.y - 130, 0.4, 0.4, ['Henchmen on rail'], true);
					add(limoCorpse);

					limoCorpseTwo = new BGSprite('gore/noooooo', -500, limoMetalPole.y, 0.4, 0.4, ['henchmen death'], true);
					add(limoCorpseTwo);

					grpLimoDancers = new FlxTypedGroup<BackgroundDancer>();
					add(grpLimoDancers);

					for (i in 0...5)
					{
						var dancer:BackgroundDancer = new BackgroundDancer((370 * i) + 170, bgLimo.y - 400);
						dancer.scrollFactor.set(0.4, 0.4);
						grpLimoDancers.add(dancer);
					}

					limoLight = new BGSprite('gore/coldHeartKiller', limoMetalPole.x - 180, limoMetalPole.y - 80, 0.4, 0.4);
					add(limoLight);

					grpLimoParticles = new FlxTypedGroup<BGSprite>();
					add(grpLimoParticles);

					// PRECACHE BLOOD
					var particle:BGSprite = new BGSprite('gore/stupidBlood', -400, -400, 0.4, 0.4, ['blood'], false);
					particle.alpha = 0.01;
					grpLimoParticles.add(particle);
					resetLimoKill();

					// PRECACHE SOUND
					precacheList.set('dancerdeath', 'sound');
				}

				limo = new BGSprite('limo/limoDrive', -120, 550, 1, 1, ['Limo stage'], true);

				fastCar = new BGSprite('limo/fastCarLol', -300, 160);
				fastCar.active = true;
				limoKillingState = 0;

			case 'mall': // Week 5 - Cocoa, Eggnog
				var bg:BGSprite = new BGSprite('christmas/bgWalls', -1000, -500, 0.2, 0.2);
				bg.setGraphicSize(Std.int(bg.width * 0.8));
				bg.updateHitbox();
				add(bg);

				if (!ClientPrefs.lowQuality)
				{
					upperBoppers = new BGSprite('christmas/upperBop', -240, -90, 0.33, 0.33, ['Upper Crowd Bob']);
					upperBoppers.setGraphicSize(Std.int(upperBoppers.width * 0.85));
					upperBoppers.updateHitbox();
					add(upperBoppers);

					var bgEscalator:BGSprite = new BGSprite('christmas/bgEscalator', -1100, -600, 0.3, 0.3);
					bgEscalator.setGraphicSize(Std.int(bgEscalator.width * 0.9));
					bgEscalator.updateHitbox();
					add(bgEscalator);
				}

				var tree:BGSprite = new BGSprite('christmas/christmasTree', 370, -250, 0.40, 0.40);
				add(tree);

				bottomBoppers = new BGSprite('christmas/bottomBop', -300, 140, 0.9, 0.9, ['Bottom Level Boppers Idle']);
				bottomBoppers.animation.addByPrefix('hey', 'Bottom Level Boppers HEY', 24, false);
				bottomBoppers.setGraphicSize(Std.int(bottomBoppers.width * 1));
				bottomBoppers.updateHitbox();
				add(bottomBoppers);

				var fgSnow:BGSprite = new BGSprite('christmas/fgSnow', -600, 700);
				add(fgSnow);

				santa = new BGSprite('christmas/santa', -840, 150, 1, 1, ['santa idle in fear']);
				add(santa);
				precacheList.set('Lights_Shut_off', 'sound');

			case 'mallEvil': // Week 5 - Winter Horrorland
				var bg:BGSprite = new BGSprite('christmas/evilBG', -400, -500, 0.2, 0.2);
				bg.setGraphicSize(Std.int(bg.width * 0.8));
				bg.updateHitbox();
				add(bg);

				var evilTree:BGSprite = new BGSprite('christmas/evilTree', 300, -300, 0.2, 0.2);
				add(evilTree);

				var evilSnow:BGSprite = new BGSprite('christmas/evilSnow', -200, 700);
				add(evilSnow);

			case 'school': // Week 6 - Senpai, Roses
				GameOverSubstate.deathSoundName = 'fnf_loss_sfx-pixel';
				GameOverSubstate.loopSoundName = 'gameOver-pixel';
				GameOverSubstate.endSoundName = 'gameOverEnd-pixel';
				GameOverSubstate.characterName = 'bf-pixel-dead';

				var bgSky:BGSprite = new BGSprite('weeb/weebSky', 0, 0, 0.1, 0.1);
				add(bgSky);
				bgSky.antialiasing = false;

				var repositionShit = -200;

				var bgSchool:BGSprite = new BGSprite('weeb/weebSchool', repositionShit, 0, 0.6, 0.90);
				add(bgSchool);
				bgSchool.antialiasing = false;

				var bgStreet:BGSprite = new BGSprite('weeb/weebStreet', repositionShit, 0, 0.95, 0.95);
				add(bgStreet);
				bgStreet.antialiasing = false;

				var widShit = Std.int(bgSky.width * 6);
				if (!ClientPrefs.lowQuality)
				{
					var fgTrees:BGSprite = new BGSprite('weeb/weebTreesBack', repositionShit + 170, 130, 0.9, 0.9);
					fgTrees.setGraphicSize(Std.int(widShit * 0.8));
					fgTrees.updateHitbox();
					add(fgTrees);
					fgTrees.antialiasing = false;
				}

				var bgTrees:FlxSprite = new FlxSprite(repositionShit - 380, -800);
				bgTrees.frames = Paths.getPackerAtlas('weeb/weebTrees');
				bgTrees.animation.add('treeLoop', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18], 12);
				bgTrees.animation.play('treeLoop');
				bgTrees.scrollFactor.set(0.85, 0.85);
				add(bgTrees);
				bgTrees.antialiasing = false;

				if (!ClientPrefs.lowQuality)
				{
					var treeLeaves:BGSprite = new BGSprite('weeb/petals', repositionShit, -40, 0.85, 0.85, ['PETALS ALL'], true);
					treeLeaves.setGraphicSize(widShit);
					treeLeaves.updateHitbox();
					add(treeLeaves);
					treeLeaves.antialiasing = false;
				}

				bgSky.setGraphicSize(widShit);
				bgSchool.setGraphicSize(widShit);
				bgStreet.setGraphicSize(widShit);
				bgTrees.setGraphicSize(Std.int(widShit * 1.4));

				bgSky.updateHitbox();
				bgSchool.updateHitbox();
				bgStreet.updateHitbox();
				bgTrees.updateHitbox();

				if (!ClientPrefs.lowQuality)
				{
					bgGirls = new BackgroundGirls(-100, 190);
					bgGirls.scrollFactor.set(0.9, 0.9);

					bgGirls.setGraphicSize(Std.int(bgGirls.width * daPixelZoom));
					bgGirls.updateHitbox();
					add(bgGirls);
				}
			case 'schoolEvil': // Week 6 - Thorns
				GameOverSubstate.deathSoundName = 'fnf_loss_sfx-pixel';
				GameOverSubstate.loopSoundName = 'gameOver-pixel';
				GameOverSubstate.endSoundName = 'gameOverEnd-pixel';
				GameOverSubstate.characterName = 'bf-pixel-dead';

				var posX = 400;
				var posY = 200;
				if (!ClientPrefs.lowQuality)
				{
					var bg:BGSprite = new BGSprite('weeb/animatedEvilSchool', posX, posY, 0.8, 0.9, ['background 2'], true);
					bg.scale.set(6, 6);
					bg.antialiasing = false;
					add(bg);

					bgGhouls = new BGSprite('weeb/bgGhouls', -100, 190, 0.9, 0.9, ['BG freaks glitch instance'], false);
					bgGhouls.setGraphicSize(Std.int(bgGhouls.width * daPixelZoom));
					bgGhouls.updateHitbox();
					bgGhouls.visible = false;
					bgGhouls.antialiasing = false;
					add(bgGhouls);
				}
				else
				{
					var bg:BGSprite = new BGSprite('weeb/animatedEvilSchool_low', posX, posY, 0.8, 0.9);
					bg.scale.set(6, 6);
					bg.antialiasing = false;
					add(bg);
				}

			case 'tank': // Week 7 - Ugh, Guns, Stress
				var sky:BGSprite = new BGSprite('tankSky', -400, -400, 0, 0);
				add(sky);

				if (!ClientPrefs.lowQuality)
				{
					var clouds:BGSprite = new BGSprite('tankClouds', FlxG.random.int(-700, -100), FlxG.random.int(-20, 20), 0.1, 0.1);
					clouds.active = true;
					clouds.velocity.x = FlxG.random.float(5, 15);
					add(clouds);

					var mountains:BGSprite = new BGSprite('tankMountains', -300, -20, 0.2, 0.2);
					mountains.setGraphicSize(Std.int(1.2 * mountains.width));
					mountains.updateHitbox();
					add(mountains);

					var buildings:BGSprite = new BGSprite('tankBuildings', -200, 0, 0.3, 0.3);
					buildings.setGraphicSize(Std.int(1.1 * buildings.width));
					buildings.updateHitbox();
					add(buildings);
				}

				var ruins:BGSprite = new BGSprite('tankRuins', -200, 0, .35, .35);
				ruins.setGraphicSize(Std.int(1.1 * ruins.width));
				ruins.updateHitbox();
				add(ruins);

				if (!ClientPrefs.lowQuality)
				{
					var smokeLeft:BGSprite = new BGSprite('smokeLeft', -200, -100, 0.4, 0.4, ['SmokeBlurLeft'], true);
					add(smokeLeft);
					var smokeRight:BGSprite = new BGSprite('smokeRight', 1100, -100, 0.4, 0.4, ['SmokeRight'], true);
					add(smokeRight);

					tankWatchtower = new BGSprite('tankWatchtower', 100, 50, 0.5, 0.5, ['watchtower gradient color']);
					add(tankWatchtower);
				}

				tankGround = new BGSprite('tankRolling', 300, 300, 0.5, 0.5, ['BG tank w lighting'], true);
				add(tankGround);

				tankmanRun = new FlxTypedGroup<TankmenBG>();
				add(tankmanRun);

				var ground:BGSprite = new BGSprite('tankGround', -420, -150);
				ground.setGraphicSize(Std.int(1.15 * ground.width));
				ground.updateHitbox();
				add(ground);
				moveTank();

				foregroundSprites = new FlxTypedGroup<BGSprite>();
				foregroundSprites.add(new BGSprite('tank0', -500, 650, 1.7, 1.5, ['fg']));
				if (!ClientPrefs.lowQuality)
					foregroundSprites.add(new BGSprite('tank1', -300, 750, 2, 0.2, ['fg']));
				foregroundSprites.add(new BGSprite('tank2', 450, 940, 1.5, 1.5, ['foreground']));
				if (!ClientPrefs.lowQuality)
					foregroundSprites.add(new BGSprite('tank4', 1300, 900, 1.5, 1.5, ['fg']));
				foregroundSprites.add(new BGSprite('tank5', 1620, 700, 1.5, 1.5, ['fg']));
				if (!ClientPrefs.lowQuality)
					foregroundSprites.add(new BGSprite('tank3', 1300, 1200, 3.5, 2.5, ['fg']));

			default: // custom stages
		}

		switch (Paths.formatToSongPath(SONG.song))
		{
			case 'stress':
				GameOverSubstate.characterName = 'bf-holding-gf-dead';
		}

		if (PlayState.isPixelStage)
			introSoundsSuffix = '-pixel';

		add(gfGroup);

		if (curStage == 'limo')
			add(limo);

		add(dadGroup);
		add(boyfriendGroup);

		switch (curStage)
		{
			case 'spooky':
				add(halloweenWhite);
			case 'tank':
				add(foregroundSprites);
		}

		#if LUA_ALLOWED
		luaDebugGroup = new FlxTypedGroup<DebugLuaText>();
		luaDebugGroup.cameras = [camOther];
		add(luaDebugGroup);
		#end

		#if LUA_ALLOWED
		var filesPushed:Array<String> = [];
		var foldersToCheck:Array<String> = [Paths.getPreloadPath('scripts/')];

		#if MODS_ALLOWED
		foldersToCheck.insert(0, Paths.mods('scripts/'));
		if (Paths.currentModDirectory != null && Paths.currentModDirectory.length > 0)
			foldersToCheck.insert(0, Paths.mods(Paths.currentModDirectory + '/scripts/'));

		for (mod in Paths.getGlobalMods())
			foldersToCheck.insert(0, Paths.mods(mod + '/scripts/'));
		#end

		for (folder in foldersToCheck)
		{
			if (FileSystem.exists(folder))
			{
				for (file in FileSystem.readDirectory(folder))
				{
					if (!filesPushed.contains(file))
					{
						if (file.endsWith('.lua'))
							luaArray.push(new FunkinLua(folder + file));
						if (file.endsWith('.hx'))
							hscriptArray.push(GrfxScriptHandler.noPathModule(folder + file));

						filesPushed.push(file);
					}
				}
			}
		}
		#end

		// STAGE SCRIPTS
		#if (MODS_ALLOWED && LUA_ALLOWED)
		var doPush:Bool = false;
		var luaFile:String = 'stages/' + curStage + '.lua';
		if (FileSystem.exists(Paths.modFolders(luaFile)))
		{
			luaFile = Paths.modFolders(luaFile);
			doPush = true;
		}
		else
		{
			luaFile = Paths.getPreloadPath(luaFile);
			if (FileSystem.exists(luaFile))
			{
				doPush = true;
			}
		}

		if (doPush)
			luaArray.push(new FunkinLua(luaFile));
		#end

		callOnHscript("onCreate", []);

		var gfVersion:String = SONG.gfVersion;
		if (gfVersion == null || gfVersion.length < 1)
		{
			switch (curStage)
			{
				case 'limo':
					gfVersion = 'gf-car';
				case 'mall' | 'mallEvil':
					gfVersion = 'gf-christmas';
				case 'school' | 'schoolEvil':
					gfVersion = 'gf-pixel';
				case 'tank':
					gfVersion = 'gf-tankmen';
				default:
					gfVersion = 'gf';
			}

			switch (Paths.formatToSongPath(SONG.song))
			{
				case 'stress':
					gfVersion = 'pico-speaker';
			}
			SONG.gfVersion = gfVersion; // Fix for the Chart Editor
		}

		if (!stageData.hide_girlfriend)
		{
			gf = new Character(0, 0, gfVersion);
			startCharacterPos(gf);
			gf.scrollFactor.set(0.95, 0.95);
			gfGroup.add(gf);
			startCharacterLua(gf.curCharacter);

			characters.push(gf);

			if (gfVersion == 'pico-speaker')
			{
				if (!ClientPrefs.lowQuality)
				{
					var firstTank:TankmenBG = new TankmenBG(20, 500, true);
					firstTank.resetShit(20, 600, true);
					firstTank.strumTime = 10;
					tankmanRun.add(firstTank);
					for (i in 0...TankmenBG.animationNotes.length)
					{
						if (FlxG.random.bool(16))
						{
							var tankBih = tankmanRun.recycle(TankmenBG);
							tankBih.strumTime = TankmenBG.animationNotes[i][0];
							tankBih.resetShit(500, 200 + FlxG.random.int(50, 100), TankmenBG.animationNotes[i][1] < 2);
							tankmanRun.add(tankBih);
						}
					}
				}
			}
		}

		dad = new Character(0, 0, SONG.player2);
		startCharacterPos(dad, true);
		dadGroup.add(dad);
		startCharacterLua(dad.curCharacter);
		characters.push(dad);

		boyfriend = new Character(0, 0, SONG.player1, true);
		startCharacterPos(boyfriend);
		boyfriendGroup.add(boyfriend);
		startCharacterLua(boyfriend.curCharacter);
		characters.push(boyfriend);

		// characters = [gf, boyfriend, dad];

		if (boyfriend != null) // by BeastlyGhost - PurSnake
		{
			GameOverSubstate.characterName = boyfriend.deathChar;
			GameOverSubstate.deathSoundName = boyfriend.deathSound;
			GameOverSubstate.loopSoundName = boyfriend.deathMusic;
			GameOverSubstate.endSoundName = boyfriend.deathConfirm;
		}

		var camPos:FlxPoint = FlxPoint.get(girlfriendCameraOffset[0], girlfriendCameraOffset[1]);
		if (gf != null)
		{
			camPos.x += gf.getGraphicMidpoint().x + gf.cameraPosition[0] + girlfriendCameraOffset[0];
			camPos.y += gf.getGraphicMidpoint().y + gf.cameraPosition[1] + girlfriendCameraOffset[1];
		}

		if (dad.curCharacter.startsWith('gf'))
		{
			dad.setPosition(GF_X, GF_Y);
			if (gf != null)
				gf.visible = false;
		}

		switch (curStage)
		{
			case 'limo':
				resetFastCar();
				addBehindGF(fastCar);

			case 'schoolEvil':
				var evilTrail = new FlxTrail(dad, null, 4, 24, 0.3, 0.069); // nice
				addBehindDad(evilTrail);
		}

		getCutsceneFiles();

		var doof:DialogueBox = new DialogueBox(false, dialogue);
		// doof.x += 70;
		// doof.y = FlxG.height * 0.5;
		doof.scrollFactor.set();
		doof.finishThing = startCountdown;
		doof.nextDialogueThing = startNextDialogue;
		doof.skipDialogueThing = skipDialogue;

		Conductor.songPosition = -5000 / Conductor.songPosition;

		timeBarBG = new FlxSprite(0, 0).makeGraphic(FlxG.width, 8, FlxColor.BLACK);
		if (ClientPrefs.downScroll)
			timeBarBG.y = FlxG.height - 8;
		timeBarBG.scrollFactor.set();
		timeBarBG.alpha = 0;
		timeBarBG.visible = ClientPrefs.enableTimeBar;
		timeBarBG.cameras = [camOther];
		add(timeBarBG);

		timeBar = new FlxBar(0, 0, LEFT_TO_RIGHT, FlxG.width, 8, this, 'songPercent', 0, 1);
		if (ClientPrefs.downScroll)
			timeBar.y = FlxG.height - 8;
		timeBar.scrollFactor.set();
		timeBar.createFilledBar(0x00000000, 0xFFFFFFFF);
		timeBar.numDivisions = FlxG.width; // How much lag this causes?? Should i tone it down to idk, 400 or 200?
		timeBar.alpha = 0;
		timeBar.visible = ClientPrefs.enableTimeBar;
		timeBar.cameras = [camOther];
		add(timeBar);

		strumLine = new FlxSprite(ClientPrefs.middleScroll ? STRUM_X_MIDDLESCROLL : STRUM_X, 50).makeGraphic(FlxG.width, 10);
		if (ClientPrefs.downScroll)
			strumLine.y = FlxG.height - 150;
		strumLine.scrollFactor.set();

		strumLineNotes = new FlxTypedGroup<StrumNote>();
		notes = new FlxTypedGroup<Note>();
		sustainNotes = new FlxTypedGroup<Note>();
		regularNotes = new FlxTypedGroup<Note>();

		add(grpSusSplashes);
		// add(sustainNotes);
		add(strumLineNotes);
		insert(members.indexOf(strumLineNotes) + (ClientPrefs.sustainNotesClipRect ? 0 : 1), sustainNotes);
		add(regularNotes);
		add(grpNoteSplashes);

		var splash:NoteSplash = new NoteSplash(-2000, -2000, 0);
		splash.alpha = 0.0;
		grpNoteSplashes.add(splash);

		var splash:SusSplash = new SusSplash(-2000, -2000, 0);
		splash.alpha = 0.0;
		grpSusSplashes.add(splash);

		opponentStrums = new FlxTypedGroup<StrumNote>();
		playerStrums = new FlxTypedGroup<StrumNote>();

		// startCountdown();

		generateSong(SONG.song);

		for (noteType in noteTypeMap.keys())
			loadScript("notetypes", noteType);

		for (event in eventPushedMap.keys())
			loadScript("events", event);

		noteTypeMap.clear();
		noteTypeMap = null;
		eventPushedMap.clear();
		eventPushedMap = null;

		camFollow = new FlxPoint();
		camFollowPos = new FlxObject(0, 0, 1, 1);
		camPos.put();

		snapCamFollowToPos(camPos.x, camPos.y);
		if (prevCamFollow != null)
		{
			camFollow = prevCamFollow;
			prevCamFollow = null;
		}
		if (prevCamFollowPos != null)
		{
			camFollowPos = prevCamFollowPos;
			prevCamFollowPos = null;
		}
		add(camFollowPos);

		FlxG.camera.follow(camFollowPos, LOCKON, 1);
		FlxG.camera.zoom = defaultCamZoom;
		FlxG.camera.focusOn(camFollow);

		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);

		FlxG.fixedTimestep = false;
		moveCameraSection();

		healthBarGroup = new FlxTypedGroup<Dynamic>();

		healthBarBG = new AttachedSprite('healthBar');
		healthBarBG.y = FlxG.height * 0.89;
		healthBarBG.screenCenter(X);
		healthBarBG.scrollFactor.set();
		healthBarBG.visible = !ClientPrefs.hideHud;
		healthBarBG.xAdd = -4;
		healthBarBG.yAdd = -4;
		if (ClientPrefs.downScroll)
			healthBarBG.y = 0.11 * FlxG.height;

		healthBar = new FlxBar(healthBarBG.x + 4, healthBarBG.y + 4, RIGHT_TO_LEFT, Std.int(healthBarBG.width - 8), Std.int(healthBarBG.height - 8), this,
			'displayedHealth', 0, 100);
		healthBar.scrollFactor.set();
		healthBar.visible = !ClientPrefs.hideHud;
		healthBar.alpha = 1;
		healthBar.numDivisions = 10000;
		healthBarBG.sprTracker = healthBar;

		healthBarWN = new FlxBar(healthBarBG.x + 4, healthBarBG.y + 4, RIGHT_TO_LEFT, Std.int(healthBarBG.width - 8), Std.int(healthBar.height / 2) + 1, this,
			'displayedHealth', 0, 100);
		healthBarWN.scrollFactor.set();
		healthBarWN.numDivisions = 10000;
		healthBarWN.alpha = 1;
		healthBarWN.visible = !ClientPrefs.hideHud;

		healthBarGroup.add(healthBar);
		healthBarGroup.add(healthBarWN);
		healthBarGroup.add(healthBarBG);

		add(healthBarGroup);

		iconP1 = new HealthIcon(boyfriend.healthIcon, {type: boyfriend.healthIconType, offsets: boyfriend.iconOffsets, scale: boyfriend.iconScale}, true);
		iconP1.y = healthBar.y - (iconP1.height / 2);
		iconP1.visible = !ClientPrefs.hideHud;
		iconP1.alpha = 1;

		iconP2 = new HealthIcon(dad.healthIcon, {type: dad.healthIconType, offsets: dad.iconOffsets, scale: dad.iconScale}, false);
		iconP2.y = healthBar.y - (iconP2.height / 2);
		iconP2.visible = !ClientPrefs.hideHud;
		iconP2.alpha = 1;

		iconGroup = new FlxTypedGroup<HealthIcon>();
		iconGroup.add(iconP1);
		iconGroup.add(iconP2);
		add(iconGroup);

		if (!ClientPrefs.hideHud)
		{
			iconGroup.forEach(function(icon:HealthIcon)
			{
				icon.visible = ClientPrefs.visibleHealthbar;
			});
			healthBarGroup.forEach(function(helem:Dynamic)
			{
				helem.visible = ClientPrefs.visibleHealthbar;
			});
		}

		reloadHealthBarColors();

		ClientPrefs.classicScoreTxt ? {
			scoreTxt = new FlxText(healthBarBG.x + healthBarBG.width - 190, healthBarBG.y + 30, 0, "", 20);
			scoreTxt.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, RIGHT, OUTLINE, FlxColor.BLACK);
			scoreTxt.scrollFactor.set();
			scoreTxt.visible = (!ClientPrefs.hideHud && !cpuControlled);
		} : {
			scoreTxt = new FlxText(healthBar.x - 205, healthBarBG.y + 52, 1000, "", 18);
			scoreTxt.setFormat(Paths.font("vcr.ttf"), 18, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			scoreTxt.screenCenter(X);
			scoreTxt.scrollFactor.set();
			scoreTxt.borderSize = 1.75;
			scoreTxt.borderQuality = 2;
			scoreTxt.visible = (!ClientPrefs.hideHud && !cpuControlled);
			}
		add(scoreTxt);

		botplayTxt = new FlxText(400, 39, FlxG.width - 800, "", 32);
		botplayTxt.text = "BOTPLAY";
		botplayTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		botplayTxt.scrollFactor.set();
		botplayTxt.borderSize = 1.25;
		botplayTxt.visible = cpuControlled;
		add(botplayTxt);
		if (ClientPrefs.downScroll)
			botplayTxt.y = FlxG.height - 89 - 78;

		sub = new FlxText(0, 0, FlxG.width / 1.4, '', 28);
		sub.setFormat(Paths.font('vcr.ttf'), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		sub.size = 32;
		sub.borderSize = 1.25;
		sub.scrollFactor.set();
		add(sub);

		for (object in [
			strumLineNotes, grpNoteSplashes, grpSusSplashes, notes, sustainNotes, regularNotes, healthBar, healthBarWN, healthBarBG, iconP1, iconP2, scoreTxt,
			botplayTxt, doof, sub
		])
			object.cameras = [camHUD];

		startingSong = true;

		// SONG SPECIFIC SCRIPTS
		#if LUA_ALLOWED
		var filesPushed:Array<String> = [];
		var foldersToCheck:Array<String> = [Paths.getPreloadPath('data/' + Paths.formatToSongPath(SONG.song) + '/')];

		#if MODS_ALLOWED
		foldersToCheck.insert(0, Paths.mods('data/' + Paths.formatToSongPath(SONG.song) + '/'));
		if (Paths.currentModDirectory != null && Paths.currentModDirectory.length > 0)
			foldersToCheck.insert(0, Paths.mods(Paths.currentModDirectory + '/data/' + Paths.formatToSongPath(SONG.song) + '/'));
		for (mod in Paths.getGlobalMods())
			foldersToCheck.insert(0, Paths.mods(mod + '/data/' + Paths.formatToSongPath(SONG.song) + '/'));
		#end
		for (folder in foldersToCheck)
		{
			if (FileSystem.exists(folder))
			{
				for (file in FileSystem.readDirectory(folder))
				{
					if (file.endsWith('.lua') && !filesPushed.contains(file))
					{
						luaArray.push(new FunkinLua(folder + file));
						filesPushed.push(file);
					}
					else if (file.endsWith('.hx') && !filesPushed.contains(file))
					{
						hscriptArray.push(GrfxScriptHandler.noPathModule(folder + file));
						filesPushed.push(file);
					}
				}
			}
		}
		#end

		var daSong:String = Paths.formatToSongPath(curSong);
		if (isStoryMode && !seenCutscene)
		{
			switch (daSong)
			{
				case "monster":
					var whiteScreen:FlxSprite = new FlxSprite(0, 0).makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.WHITE);
					add(whiteScreen);
					whiteScreen.scrollFactor.set();
					whiteScreen.blend = ADD;
					camHUD.visible = false;
					snapCamFollowToPos(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100);
					inCutscene = true;

					FlxTween.tween(whiteScreen, {alpha: 0}, 1, {
						startDelay: 0.1,
						ease: FlxEase.linear,
						onComplete: function(twn:FlxTween)
						{
							camHUD.visible = true;
							remove(whiteScreen);
							startCountdown();
						}
					});
					FlxG.sound.play(Paths.soundRandom('thunder_', 1, 2));
					if (gf != null)
						gf.playAnim('scared', true);
					boyfriend.playAnim('scared', true);

				case "winter-horrorland":
					var blackScreen:FlxSprite = new FlxSprite().makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
					add(blackScreen);
					blackScreen.scrollFactor.set();
					camHUD.visible = false;
					inCutscene = true;

					FlxTween.tween(blackScreen, {alpha: 0}, 0.7, {
						ease: FlxEase.linear,
						onComplete: function(twn:FlxTween)
						{
							remove(blackScreen);
						}
					});
					FlxG.sound.play(Paths.sound('Lights_Turn_On'));
					snapCamFollowToPos(400, -2050);
					FlxG.camera.focusOn(camFollow);
					FlxG.camera.zoom = 1.5;

					new FlxTimer().start(0.8, function(tmr:FlxTimer)
					{
						camHUD.visible = true;
						remove(blackScreen);
						FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, 2.5, {
							ease: FlxEase.quadInOut,
							onComplete: function(twn:FlxTween)
							{
								startCountdown();
							}
						});
					});
				case 'senpai' | 'roses' | 'thorns':
					if (daSong == 'roses')
						FlxG.sound.play(Paths.sound('ANGRY'));
					schoolIntro(doof);

				case 'ugh' | 'guns' | 'stress':
					tankIntro();

				default:
					startCountdown();
			}
			seenCutscene = true;
		}
		else
		{
			startCountdown();
		}

		RecalculateRating();

		// PRECACHING MISS SOUNDS BECAUSE I THINK THEY CAN LAG PEOPLE AND FUCK THEM UP IDK HOW HAXE WORKS
		precacheList.set('missnote3', 'sound');
		precacheList.set('missnote3', 'sound');
		precacheList.set('missnote3', 'sound');
		precacheList.set('breakfast', 'music');
		precacheList.set('note_click', 'sound');
		FlxG.sound.play(Paths.sound('note_click'), 0);

		precacheList.set('alphabets/alphabet', 'image');

		#if desktop
		// Updating Discord Rich Presence.
		DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconRPC, SONG.player2);
		#end

		if (!ClientPrefs.controllerMode)
		{
			FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
			FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		}

		FlxG.mouse.load(Paths.image("cursor").bitmap, 1, 0, 0);

		call('onCreatePost', []);
		callOnLuas('onCreatePost', []);
		callOnHscript("onCreatePost", []);
		stageBuild.callFunction('onCreatePost', []);
		// FlxG.mouse.visible = true;

		cacheCountdown();
		cacheCombo();
		cachePopUpScore();

		for (key => type in precacheList)
		{
			// trace('Key $key is type $type');
			switch (type)
			{
				case 'image':
					Paths.image(key);
				case 'sound':
					Paths.sound(key);
				case 'music':
					Paths.music(key);
			}
		}

		Paths.clearUnusedMemory();
		FlxG.mouse.visible = false;
		//CustomFadeTransition.nextCamera = camOther;

		if (eventNotes.length < 1)
			checkEventNote();
	}

	#if (!flash && sys)
	public var runtimeShaders:Map<String, Array<String>> = new Map<String, Array<String>>();

	public function createRuntimeShader(name:String, ?glslVersion:Int = 120):FlxRuntimeShader
	{
		if (!ClientPrefs.shaders)
			return new FlxRuntimeShader();

		#if (!flash && MODS_ALLOWED && sys)
		if (!runtimeShaders.exists(name) && !initLuaShader(name))
		{
			FlxG.log.warn('Shader $name is missing!');
			return new FlxRuntimeShader();
		}

		var arr:Array<String> = runtimeShaders.get(name);
		return new FlxRuntimeShader(arr[0], arr[1] /*, glslVersion*/);
		#else
		FlxG.log.warn("Platform unsupported for Runtime Shaders!");
		return null;
		#end
	}

	public function initLuaShader(name:String, ?glslVersion:Int = 120)
	{
		if (!ClientPrefs.shaders)
			return false;

		if (runtimeShaders.exists(name))
		{
			FlxG.log.warn('Shader $name was already initialized!');
			return true;
		}

		var foldersToCheck:Array<String> = ['assets/shaders/', Paths.mods('shaders/')];
		if (Paths.currentModDirectory != null && Paths.currentModDirectory.length > 0)
			foldersToCheck.insert(0, Paths.mods(Paths.currentModDirectory + '/shaders/'));

		for (mod in Paths.getGlobalMods())
			foldersToCheck.insert(0, Paths.mods(mod + '/shaders/'));

		for (folder in foldersToCheck)
		{
			if (FileSystem.exists(folder))
			{
				var frag:String = folder + name + '.frag';
				var vert:String = folder + name + '.vert';
				var found:Bool = false;
				if (FileSystem.exists(frag))
				{
					frag = File.getContent(frag);
					found = true;
				}
				else
					frag = null;

				if (FileSystem.exists(vert))
				{
					vert = File.getContent(vert);
					found = true;
				}
				else
					vert = null;

				if (found)
				{
					runtimeShaders.set(name, [frag, vert]);
					// trace('Found shader $name!');
					return true;
				}
			}
		}
		FlxG.log.warn('Missing shader $name .frag AND .vert files!');
		return false;
	}
	#end

	function set_songSpeed(value:Float):Float
	{
		if (generatedMusic)
		{
			var ratio:Float = value / songSpeed; // funny word huh
			for (note in notes)
				note.resizeByRatio(ratio);
			for (note in unspawnNotes)
				note.resizeByRatio(ratio);
		}
		songSpeed = value;
		noteKillOffset = Math.max(Conductor.stepCrochet, 350 / songSpeed);
		return value;
	}

	function set_playbackRate(value:Float):Float
	{
		if (generatedMusic)
		{
			if (vocals != null)
				vocals.pitch = value;
			if (vocals2 != null)
				vocals2.pitch = value;
			FlxG.sound.music.pitch = value;

			var ratio:Float = playbackRate / value; // funny word huh
			if (ratio != 1)
			{
				for (note in notes.members)
					note.resizeByRatio(ratio);
				for (note in unspawnNotes)
					note.resizeByRatio(ratio);
			}
		}

		playbackRate = value;
		FlxG.animationTimeScale = value;
		trace('Anim speed: ' + FlxG.animationTimeScale);
		Conductor.safeZoneOffset = (ClientPrefs.safeFrames / 60) * 1000 * value;
		setOnLuas('playbackRate', playbackRate);
		return value;
	}

	public function addTextToDebug(text:String, color:FlxColor)
	{
		#if LUA_ALLOWED
		var newText:DebugLuaText = luaDebugGroup.recycle(DebugLuaText);
		newText.text = text;
		newText.color = color;
		newText.disableTime = 6;
		newText.alpha = 1;
		newText.setPosition(10, 8 - newText.height);

		luaDebugGroup.forEachAlive(function(spr:DebugLuaText)
		{
			spr.y += newText.height + 2;
		});
		luaDebugGroup.add(newText);
		#end
	}

	public function addCharacterToList(newCharacter:String, type:Int)
	{
		switch (type)
		{
			case 0:
				if (!boyfriendMap.exists(newCharacter))
				{
					var newBoyfriend:Character = new Character(0, 0, newCharacter, true);
					boyfriendMap.set(newCharacter, newBoyfriend);
					boyfriendGroup.add(newBoyfriend);
					startCharacterPos(newBoyfriend);
					newBoyfriend.alpha = 0.00001;
					startCharacterLua(newBoyfriend.curCharacter);
				}

			case 1:
				if (!dadMap.exists(newCharacter))
				{
					var newDad:Character = new Character(0, 0, newCharacter);
					dadMap.set(newCharacter, newDad);
					dadGroup.add(newDad);
					startCharacterPos(newDad, true);
					newDad.alpha = 0.00001;
					startCharacterLua(newDad.curCharacter);
				}

			case 2:
				if (gf != null && !gfMap.exists(newCharacter))
				{
					var newGf:Character = new Character(0, 0, newCharacter);
					newGf.scrollFactor.set(0.95, 0.95);
					gfMap.set(newCharacter, newGf);
					gfGroup.add(newGf);
					startCharacterPos(newGf);
					newGf.alpha = 0.00001;
					startCharacterLua(newGf.curCharacter);
				}
		}
	}

	function startCharacterLua(name:String)
	{
		#if LUA_ALLOWED
		var doPush:Bool = false;
		var doPushHx:Bool = false;
		var luaFile:String = 'characters/' + name + '.lua';
		var hxFile:String = 'characters/' + name + '.hx';
		#if MODS_ALLOWED
		if (FileSystem.exists(Paths.modFolders(luaFile)))
		{
			luaFile = Paths.modFolders(luaFile);
			doPush = true;
		}
		else
		{
			luaFile = Paths.getPreloadPath(luaFile);
			if (FileSystem.exists(luaFile))
			{
				doPush = true;
			}
		}

		if (FileSystem.exists(Paths.modFolders(hxFile)))
		{
			hxFile = Paths.modFolders(hxFile);
			doPushHx = true;
		}
		else
		{
			hxFile = Paths.getPreloadPath(hxFile);
			if (FileSystem.exists(hxFile))
			{
				doPushHx = true;
			}
		}
		#else
		luaFile = Paths.getPreloadPath(luaFile);
		if (Assets.exists(luaFile))
		{
			doPush = true;
		}

		hxFile = Paths.getPreloadPath(hxFile);
		if (Assets.exists(hxFile))
		{
			doPushHx = true;
		}
		#end

		if (doPush)
		{
			for (script in luaArray)
			{
				if (script.scriptName == luaFile)
					return;
			}
			luaArray.push(new FunkinLua(luaFile));
		}
		if (doPushHx)
		{
			for (script in hscriptArray)
			{
				if (script.scriptName == hxFile)
					return;
			}
			hscriptArray.push(GrfxScriptHandler.noPathModule(hxFile));
		}
		#end
	}

	public function getModObject(tag:String, text:Bool = true):FlxSprite
	{
		if (modchartObjects.exists(tag))
			return modchartObjects.get(tag);
		if (modchartSprites.exists(tag))
			return modchartSprites.get(tag);
		if (text && modchartTexts.exists(tag))
			return modchartTexts.get(tag);
		return null;
	}

	public function getLuaObject(tag:String, text:Bool = true):FlxSprite
	{
		if (modchartObjects.exists(tag))
			return modchartObjects.get(tag);
		if (modchartSprites.exists(tag))
			return modchartSprites.get(tag);
		if (text && modchartTexts.exists(tag))
			return modchartTexts.get(tag);
		if (variables.exists(tag))
			return variables.get(tag);
		return null;
	}

	function startCharacterPos(char:Character, ?gfCheck:Bool = false)
	{
		if (gfCheck && char.curCharacter.startsWith('gf'))
		{ // IF DAD IS GIRLFRIEND, HE GOES TO HER POSITION
			char.setPosition(GF_X, GF_Y);
			char.scrollFactor.set(0.95, 0.95);
			char.danceEveryNumBeats = 2;
		}
		char.x += char.positionArray[0];
		char.y += char.positionArray[1];
	}

	var dialogueCount:Int = 0;

	public var psychDialogue:DialogueBoxPsych; // Powered by 'Psych Engine' - PurSnake

	// You don't have to add a song, just saying. You can just do "startDialogue(dialogueJson);" and it should work
	public function startDialogue(dialogueFile:DialogueFile, ?song:String = null):Void
	{
		// TO DO: Make this more flexible, maybe?
		if (psychDialogue != null)
			return;

		if (dialogueFile.dialogue.length > 0)
		{
			inCutscene = true;
			precacheList.set('dialogue', 'sound');
			precacheList.set('dialogueClose', 'sound');
			psychDialogue = new DialogueBoxPsych(dialogueFile, song);
			psychDialogue.scrollFactor.set();
			if (endingSong)
			{
				psychDialogue.finishThing = function()
				{
					psychDialogue = null;
					endSong();
				}
			}
			else
			{
				psychDialogue.finishThing = function()
				{
					psychDialogue = null;
					startCountdown();
				}
			}
			psychDialogue.nextDialogueThing = startNextDialogue;
			psychDialogue.skipDialogueThing = skipDialogue;
			psychDialogue.cameras = [camHUD];
			add(psychDialogue);
		}
		else
		{
			FlxG.log.warn('Your dialogue file is badly formatted!');
			if (endingSong)
			{
				endSong();
			}
			else
			{
				startCountdown();
			}
		}
	}

	function schoolIntro(?dialogueBox:DialogueBox):Void
	{
		inCutscene = true;
		var black:FlxSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
		black.scrollFactor.set();
		add(black);

		var red:FlxSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, 0xFFff1b31);
		red.scrollFactor.set();

		var senpaiEvil:FlxSprite = new FlxSprite();
		senpaiEvil.frames = Paths.getSparrowAtlas('weeb/senpaiCrazy');
		senpaiEvil.animation.addByPrefix('idle', 'Senpai Pre Explosion', 24, false);
		senpaiEvil.setGraphicSize(Std.int(senpaiEvil.width * 6));
		senpaiEvil.scrollFactor.set();
		senpaiEvil.updateHitbox();
		senpaiEvil.screenCenter();
		senpaiEvil.x += 300;

		var songName:String = Paths.formatToSongPath(SONG.song);
		if (songName == 'roses' || songName == 'thorns')
		{
			remove(black);

			if (songName == 'thorns')
			{
				add(red);
				camHUD.visible = false;
			}
		}

		new FlxTimer().start(0.3, function(tmr:FlxTimer)
		{
			black.alpha -= 0.15;

			if (black.alpha > 0)
			{
				tmr.reset(0.3);
			}
			else
			{
				if (dialogueBox != null)
				{
					if (Paths.formatToSongPath(SONG.song) == 'thorns')
					{
						add(senpaiEvil);
						senpaiEvil.alpha = 0;
						new FlxTimer().start(0.3, function(swagTimer:FlxTimer)
						{
							senpaiEvil.alpha += 0.15;
							if (senpaiEvil.alpha < 1)
							{
								swagTimer.reset();
							}
							else
							{
								senpaiEvil.animation.play('idle');
								FlxG.sound.play(Paths.sound('Senpai_Dies'), 1, false, null, true, function()
								{
									remove(senpaiEvil);
									remove(red);
									FlxG.camera.fade(FlxColor.WHITE, 0.01, true, function()
									{
										add(dialogueBox);
										camHUD.visible = true;
									}, true);
								});
								new FlxTimer().start(3.2, function(deadTime:FlxTimer)
								{
									FlxG.camera.fade(FlxColor.WHITE, 1.6, false);
								});
							}
						});
					}
					else
					{
						add(dialogueBox);
					}
				}
				else
					startCountdown();

				remove(black);
			}
		});
	}

	function tankIntro()
	{
		var cutsceneHandler:CutsceneHandler = new CutsceneHandler();

		var songName:String = Paths.formatToSongPath(SONG.song);
		dadGroup.alpha = 0.00001;
		camHUD.visible = false;
		// inCutscene = true; //this would stop the camera movement, oops

		var tankman:FlxSprite = new FlxSprite(-20, 320);
		tankman.frames = Paths.getSparrowAtlas('cutscenes/' + songName);
		tankman.antialiasing = ClientPrefs.globalAntialiasing;
		addBehindDad(tankman);
		cutsceneHandler.push(tankman);

		var tankman2:FlxSprite = new FlxSprite(16, 312);
		tankman2.antialiasing = ClientPrefs.globalAntialiasing;
		tankman2.alpha = 0.000001;
		cutsceneHandler.push(tankman2);
		var gfDance:FlxSprite = new FlxSprite(gf.x - 107, gf.y + 140);
		gfDance.antialiasing = ClientPrefs.globalAntialiasing;
		cutsceneHandler.push(gfDance);
		var gfCutscene:FlxSprite = new FlxSprite(gf.x - 104, gf.y + 122);
		gfCutscene.antialiasing = ClientPrefs.globalAntialiasing;
		cutsceneHandler.push(gfCutscene);
		var picoCutscene:FlxSprite = new FlxSprite(gf.x - 849, gf.y - 264);
		picoCutscene.antialiasing = ClientPrefs.globalAntialiasing;
		cutsceneHandler.push(picoCutscene);
		var boyfriendCutscene:FlxSprite = new FlxSprite(boyfriend.x + 5, boyfriend.y + 20);
		boyfriendCutscene.antialiasing = ClientPrefs.globalAntialiasing;
		cutsceneHandler.push(boyfriendCutscene);

		cutsceneHandler.finishCallback = function()
		{
			var timeForStuff:Float = Conductor.crochet / 1000 * 4.5;
			FlxG.sound.music.fadeOut(timeForStuff);
			FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, timeForStuff, {ease: FlxEase.quadInOut});
			moveCamera('dad');
			startCountdown();

			dadGroup.alpha = 1;
			camHUD.visible = true;
			boyfriend.animation.finishCallback = null;
			gf.animation.finishCallback = null;
			gf.dance();
		};

		camFollow.set(dad.x + 280, dad.y + 170);
		switch (songName)
		{
			case 'ugh':
				cutsceneHandler.endTime = 12;
				cutsceneHandler.music = 'DISTORTO';
				precacheList.set('wellWellWell', 'sound');
				precacheList.set('killYou', 'sound');
				precacheList.set('bfBeep', 'sound');

				var wellWellWell:FlxSound = new FlxSound().loadEmbedded(Paths.sound('wellWellWell'));
				FlxG.sound.list.add(wellWellWell);

				tankman.animation.addByPrefix('wellWell', 'TANK TALK 1 P1', 24, false);
				tankman.animation.addByPrefix('killYou', 'TANK TALK 1 P2', 24, false);
				tankman.animation.play('wellWell', true);
				FlxG.camera.zoom *= 1.2;

				// Well well well, what do we got here?
				cutsceneHandler.timer(0.1, function()
				{
					wellWellWell.play(true);
				});

				// Move camera to BF
				cutsceneHandler.timer(3, function()
				{
					camFollow.x += 750;
					camFollow.y += 100;
				});

				// Beep!
				cutsceneHandler.timer(4.5, function()
				{
					boyfriend.playAnim('singUP', true);
					boyfriend.specialAnim = true;
					FlxG.sound.play(Paths.sound('bfBeep'));
				});

				// Move camera to Tankman
				cutsceneHandler.timer(6, function()
				{
					camFollow.x -= 750;
					camFollow.y -= 100;

					// We should just kill you but... what the hell, it's been a boring day... let's see what you've got!
					tankman.animation.play('killYou', true);
					FlxG.sound.play(Paths.sound('killYou'));
				});

			case 'guns':
				cutsceneHandler.endTime = 11.5;
				cutsceneHandler.music = 'DISTORTO';
				tankman.x += 40;
				tankman.y += 10;
				precacheList.set('tankSong2', 'sound');

				var tightBars:FlxSound = new FlxSound().loadEmbedded(Paths.sound('tankSong2'));
				FlxG.sound.list.add(tightBars);

				tankman.animation.addByPrefix('tightBars', 'TANK TALK 2', 24, false);
				tankman.animation.play('tightBars', true);
				boyfriend.animation.curAnim.finish();

				cutsceneHandler.onStart = function()
				{
					tightBars.play(true);
					FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom * 1.2}, 4, {ease: FlxEase.quadInOut});
					FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom * 1.2 * 1.2}, 0.5, {ease: FlxEase.quadInOut, startDelay: 4});
					FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom * 1.2}, 1, {ease: FlxEase.quadInOut, startDelay: 4.5});
				};

				cutsceneHandler.timer(4, function()
				{
					gf.playAnim('sad', true);
					gf.animation.finishCallback = function(name:String)
					{
						gf.playAnim('sad', true);
					};
				});

			case 'stress':
				cutsceneHandler.endTime = 35.5;
				tankman.x -= 54;
				tankman.y -= 14;
				gfGroup.alpha = 0.00001;
				boyfriendGroup.alpha = 0.00001;
				camFollow.set(dad.x + 400, dad.y + 170);
				FlxTween.tween(FlxG.camera, {zoom: 0.9 * 1.2}, 1, {ease: FlxEase.quadInOut});
				foregroundSprites.forEach(function(spr:BGSprite)
				{
					spr.y += 100;
				});
				precacheList.set('stressCutscene', 'sound');

				tankman2.frames = Paths.getSparrowAtlas('cutscenes/stress2');
				addBehindDad(tankman2);

				if (!ClientPrefs.lowQuality)
				{
					gfDance.frames = Paths.getSparrowAtlas('characters/gfTankmen');
					gfDance.animation.addByPrefix('dance', 'GF Dancing at Gunpoint', 24, true);
					gfDance.animation.play('dance', true);
					addBehindGF(gfDance);
				}

				gfCutscene.frames = Paths.getSparrowAtlas('cutscenes/stressGF');
				gfCutscene.animation.addByPrefix('dieBitch', 'GF STARTS TO TURN PART 1', 24, false);
				gfCutscene.animation.addByPrefix('getRektLmao', 'GF STARTS TO TURN PART 2', 24, false);
				gfCutscene.animation.play('dieBitch', true);
				gfCutscene.animation.pause();
				addBehindGF(gfCutscene);
				if (!ClientPrefs.lowQuality)
				{
					gfCutscene.alpha = 0.00001;
				}

				picoCutscene.frames = AtlasFrameMaker.construct('cutscenes/stressPico');
				picoCutscene.animation.addByPrefix('anim', 'Pico Badass', 24, false);
				addBehindGF(picoCutscene);
				picoCutscene.alpha = 0.00001;

				boyfriendCutscene.frames = Paths.getSparrowAtlas('characters/BOYFRIEND');
				boyfriendCutscene.animation.addByPrefix('idle', 'BF idle dance', 24, false);
				boyfriendCutscene.animation.play('idle', true);
				boyfriendCutscene.animation.curAnim.finish();
				addBehindBF(boyfriendCutscene);

				var cutsceneSnd:FlxSound = new FlxSound().loadEmbedded(Paths.sound('stressCutscene'));
				FlxG.sound.list.add(cutsceneSnd);

				tankman.animation.addByPrefix('godEffingDamnIt', 'TANK TALK 3', 24, false);
				tankman.animation.play('godEffingDamnIt', true);

				var calledTimes:Int = 0;
				var zoomBack:Void->Void = function()
				{
					var camPosX:Float = 630;
					var camPosY:Float = 425;
					camFollow.set(camPosX, camPosY);
					camFollowPos.setPosition(camPosX, camPosY);
					FlxG.camera.zoom = 0.8;
					cameraSpeed = 1;

					calledTimes++;
					if (calledTimes > 1)
					{
						foregroundSprites.forEach(function(spr:BGSprite)
						{
							spr.y -= 100;
						});
					}
				}

				cutsceneHandler.onStart = function()
				{
					cutsceneSnd.play(true);
				};

				cutsceneHandler.timer(15.2, function()
				{
					FlxTween.tween(camFollow, {x: 650, y: 300}, 1, {ease: FlxEase.sineOut});
					FlxTween.tween(FlxG.camera, {zoom: 0.9 * 1.2 * 1.2}, 2.25, {ease: FlxEase.quadInOut});

					gfDance.visible = false;
					gfCutscene.alpha = 1;
					gfCutscene.animation.play('dieBitch', true);
					gfCutscene.animation.finishCallback = function(name:String)
					{
						if (name == 'dieBitch') // Next part
						{
							gfCutscene.animation.play('getRektLmao', true);
							gfCutscene.offset.set(224, 445);
						}
						else
						{
							gfCutscene.visible = false;
							picoCutscene.alpha = 1;
							picoCutscene.animation.play('anim', true);

							boyfriendGroup.alpha = 1;
							boyfriendCutscene.visible = false;
							boyfriend.playAnim('bfCatch', true);
							boyfriend.animation.finishCallback = function(name:String)
							{
								if (name != 'idle')
								{
									boyfriend.playAnim('idle', true);
									boyfriend.animation.curAnim.finish(); // Instantly goes to last frame
								}
							};

							picoCutscene.animation.finishCallback = function(name:String)
							{
								picoCutscene.visible = false;
								gfGroup.alpha = 1;
								picoCutscene.animation.finishCallback = null;
							};
							gfCutscene.animation.finishCallback = null;
						}
					};
				});

				cutsceneHandler.timer(17.5, function()
				{
					zoomBack();
				});

				cutsceneHandler.timer(19.5, function()
				{
					tankman2.animation.addByPrefix('lookWhoItIs', 'TANK TALK 3', 24, false);
					tankman2.animation.play('lookWhoItIs', true);
					tankman2.alpha = 1;
					tankman.visible = false;
				});

				cutsceneHandler.timer(20, function()
				{
					camFollow.set(dad.x + 500, dad.y + 170);
				});

				cutsceneHandler.timer(31.2, function()
				{
					boyfriend.playAnim('singUPmiss', true);
					boyfriend.animation.finishCallback = function(name:String)
					{
						if (name == 'singUPmiss')
						{
							boyfriend.playAnim('idle', true);
							boyfriend.animation.curAnim.finish(); // Instantly goes to last frame
						}
					};

					camFollow.set(boyfriend.x + 280, boyfriend.y + 200);
					cameraSpeed = 12;
					FlxTween.tween(FlxG.camera, {zoom: 0.9 * 1.2 * 1.2}, 0.25, {ease: FlxEase.elasticOut});
				});

				cutsceneHandler.timer(32.2, function()
				{
					zoomBack();
				});
		}
	}

	var startTimer:FlxTimer;
	var finishTimer:FlxTimer = null;

	// For being able to mess with the sprites on Lua
	// public var countdownReady:FlxSprite;
	// public var countdownSet:FlxSprite;
	// public var countdownGo:FlxSprite;
	public static var startOnTime:Float = 0;

	function cacheCountdown()
	{
		var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
		introAssets.set('default', ['ready', 'set', 'go']);
		introAssets.set('pixel', ['pixelUI/ready-pixel', 'pixelUI/set-pixel', 'pixelUI/date-pixel']);

		var introAlts:Array<String> = introAssets.get('default');
		if (isPixelStage)
			introAlts = introAssets.get('pixel');

		for (asset in introAlts)
			Paths.image(asset);

		Paths.sound('intro3' + introSoundsSuffix);
		Paths.sound('intro2' + introSoundsSuffix);
		Paths.sound('intro1' + introSoundsSuffix);
		Paths.sound('introGo' + introSoundsSuffix);
	}

	public var skippedCountdownStartTime:Float = 0;

	public function startCountdown():Void
	{
		if (startedCountdown)
		{
			call("onStartCountdown", []);
			callOnLuas('onStartCountdown', []);
			callOnHscript("onStartCountdown", []);
			stageBuild.callFunction('onStartCountdown', []);
			return;
		}

		inCutscene = false;
		var ret:Dynamic = (callOnLuas('onStartCountdown', [], false) || callOnHscript('onStartCountdown', [], false));
		if (ret != FunkinLua.Function_Stop)
		{
			if (skipCountdown || startOnTime > 0)
				skipArrowStartTween = true;

			generateStaticArrows(0);
			generateStaticArrows(1);
			for (i in 0...playerStrums.length)
			{
				setOnLuas('defaultPlayerStrumX' + i, playerStrums.members[i].x);
				setOnLuas('defaultPlayerStrumY' + i, playerStrums.members[i].y);
			}
			for (i in 0...opponentStrums.length)
			{
				setOnLuas('defaultOpponentStrumX' + i, opponentStrums.members[i].x);
				setOnLuas('defaultOpponentStrumY' + i, opponentStrums.members[i].y);
			}

			startedCountdown = true;
			Conductor.songPosition = -Conductor.crochet * 5;
			setOnLuas('startedCountdown', true);
			call('onCountdownStarted', []);
			callOnLuas('onCountdownStarted', []);
			stageBuild.callFunction("onCountdownStarted", []);
			callOnHscript("onCountdownStarted", []);

			var swagCounter:Int = 0;

			if (startOnTime < 0)
				startOnTime = 0;

			if (startOnTime > 0)
			{
				clearNotesBefore(startOnTime);
				setSongTime(startOnTime - 350);
				return;
			}
			else if (skipCountdown && skippedCountdownStartTime >= 0)
			{
				setSongTime(0);
				return;
			}
			else if (skipCountdown && skippedCountdownStartTime < 0)
			{
				Conductor.songPosition = skippedCountdownStartTime;
				return;
			}

			var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
			introAssets.set('default', ['ready', 'set', 'go']);
			introAssets.set('pixel', ['pixelUI/ready-pixel', 'pixelUI/set-pixel', 'pixelUI/date-pixel']);

			var introAlts:Array<String> = introAssets.get('default');
			var antialias:Bool = ClientPrefs.globalAntialiasing;
			if (PlayState.isPixelStage)
			{
				introAlts = introAssets.get('pixel');
				antialias = false;
			}

			var soundList:Array<String> = ["intro3", "intro2", "intro1", "introGo"];

			startTimer = new FlxTimer().start(Conductor.crochet / 1000 / playbackRate, function(tmr:FlxTimer)
			{
				for (character in characters)
				{
					if (character != null
						&& tmr.loopsLeft % Math.round(character.danceEveryNumBeats * (character == gf ? gfSpeed : 1)) == 0
						&& character.animation.curAnim != null
						&& !character.animation.curAnim.name.startsWith(character.singAnimsPrefix)
						&& !character.stunned)
					{
						character.dance();
					}
				}

				if (swagCounter % iconsZoomingFreq == 0)
					iconGroup.forEach(function(icon:HealthIcon)
					{
						icon.doScale();
						call("onIconsBeat", [swagCounter]);
						callOnHscript("onIconsBeat", [swagCounter]);
						stageBuild.callFunction("onIconsBeat", [swagCounter]);
						callOnLuas('onIconsBeat', [swagCounter]);
					}); // For stuped icons to do their shit while song isnt started - Snake

				// head bopping for bg characters on Mall
				if (curStage == 'mall')
				{
					if (!ClientPrefs.lowQuality)
						upperBoppers.dance(true);

					bottomBoppers.dance(true);
					santa.dance(true);
				}

				if (swagCounter > 0 && swagCounter < 4)
				{
					var countSpr:FlxSprite = new FlxSprite().loadGraphic(Paths.image(introAlts[swagCounter - 1]));
					countSpr.cameras = [camHUD];
					countSpr.scrollFactor.set();
					countSpr.updateHitbox();

					if (PlayState.isPixelStage)
						countSpr.setGraphicSize(Std.int(countSpr.width * daPixelZoom));

					countSpr.screenCenter();
					countSpr.antialiasing = antialias;
					insert(members.indexOf(grpNoteSplashes), countSpr);
					FlxTween.tween(countSpr, {alpha: 0}, Conductor.crochet / 1000, {
						ease: FlxEase.cubeInOut,
						onComplete: function(twn:FlxTween)
						{
							remove(countSpr, true);
							countSpr.destroy();
						}
					});
				}
				FlxG.sound.play(Paths.sound(soundList[swagCounter] + introSoundsSuffix), 0.6);

				notes.forEachAlive(function(note:Note)
				{
					if (!ClientPrefs.hideOpponenStrums || note.mustPress)
					{
						note.copyAlpha = false;
						note.alpha = note.multAlpha;
						if (ClientPrefs.middleScroll && !note.mustPress)
						{
							note.alpha *= 0.35;
						}
					}
				});
				call("onCountdownTick", [swagCounter]);
				callOnLuas('onCountdownTick', [swagCounter]);
				callOnHscript("onCountdownTick", [swagCounter]);
				stageBuild.callFunction("onCountdownTick", [swagCounter]);

				swagCounter += 1;
			}, 5);
		}
	}

	public function addBehindGF(obj:FlxBasic)
	{
		insert(members.indexOf(gfGroup), obj);
	}

	public function addBehindBF(obj:FlxBasic)
	{
		insert(members.indexOf(boyfriendGroup), obj);
	}

	public function addBehindDad(obj:FlxBasic)
	{
		insert(members.indexOf(dadGroup), obj);
	}

	public function clearNotesBefore(time:Float)
	{
		var i:Int = unspawnNotes.length - 1;
		while (i >= 0)
		{
			var daNote:Note = unspawnNotes[i];
			if (daNote.strumTime - 350 < time)
			{
				daNote.active = false;
				daNote.visible = false;
				daNote.ignoreNote = true;

				if (modchartObjects.exists('note${daNote.ID}'))
					modchartObjects.remove('note${daNote.ID}');
				daNote.kill();
				unspawnNotes.remove(daNote);
				daNote.destroy();
			}
			--i;
		}

		i = notes.length - 1;
		while (i >= 0)
		{
			var daNote:Note = notes.members[i];
			if (daNote.strumTime - 350 < time)
			{
				daNote.active = false;
				daNote.visible = false;
				daNote.ignoreNote = true;

				if (modchartObjects.exists('note${daNote.ID}'))
					modchartObjects.remove('note${daNote.ID}');
				daNote.kill();
				notes.remove(daNote, true);
				daNote.destroy();
			}
			--i;
		}
	}

	public function setSongTime(time:Float)
	{
		if (time < 0)
			time = 0;
		FlxG.sound.music.pause();
		vocals.pause();
		vocals2.pause();
		FlxG.sound.music.time = time;
		FlxG.sound.music.pitch = playbackRate;
		FlxG.sound.music.play();
		if (Conductor.songPosition <= vocals.length)
		{
			vocals.time = time;
			// vocals.pitch = playbackRate;
		}
		vocals.play();

		if (Conductor.songPosition <= vocals2.length)
		{
			vocals2.time = time;
			// vocals2.pitch = playbackRate;
		}
		vocals2.play();

		Conductor.songPosition = time;
		songTime = time;
	}

	function startNextDialogue()
	{
		dialogueCount++;
		call("onNextDialogue", [dialogueCount]);
		callOnLuas('onNextDialogue', [dialogueCount]);
		callOnHscript("onNextDialogue", [dialogueCount]);
		stageBuild.callFunction("onNextDialogue", [dialogueCount]);
	}

	function skipDialogue()
	{
		call("onSkipDialogue", [dialogueCount]);
		callOnLuas('onSkipDialogue', [dialogueCount]);
		callOnHscript("onSkipDialogue", [dialogueCount]);
		stageBuild.callFunction("onSkipDialogue", [dialogueCount]);
	}

	var previousFrameTime:Int = 0;
	var lastReportedPlayheadPosition:Int = 0;
	var songTime:Float = 0;

	function startSong():Void
	{
		startingSong = false;
		previousFrameTime = FlxG.game.ticks;
		lastReportedPlayheadPosition = 0;
		FlxG.sound.playMusic(Paths.inst(PlayState.SONG.song, PlayState.SONG.postfix), 1, false);
		FlxG.sound.music.pitch = playbackRate;
		FlxG.sound.music.onComplete = finishSong.bind();
		vocals.play();
		vocals2.play();
		if (startOnTime > 0)
			setSongTime(startOnTime - 500);

		startOnTime = 0;

		if (paused)
		{
			FlxG.sound.music.pause();
			vocals.pause();
			vocals2.pause();
		}

		songLength = FlxG.sound.music.length;
		FlxTween.tween(timeBar, {alpha: .75}, 0.3, {ease: FlxEase.circOut});
		FlxTween.tween(timeBarBG, {alpha: .35}, 0.3, {ease: FlxEase.circOut});

		switch (curStage)
		{
			case 'tank':
				if (!ClientPrefs.lowQuality)
					tankWatchtower.dance();
				foregroundSprites.forEach(function(spr:BGSprite)
				{
					spr.dance();
				});
		}

		#if desktop
		// Updating Discord Rich Presence (with Time Left)
		DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconRPC, SONG.player2, true, songLength);
		#end
		setOnLuas('songLength', songLength);
		call("onSongStart", []);
		callOnLuas('onSongStart', []);
		stageBuild.callFunction('onSongStart', []);
		callOnHscript("onSongStart", []);
	}

	var debugNum:Int = 0;
	private var noteTypeMap:Map<String, Bool> = new Map<String, Bool>();
	private var eventPushedMap:Map<String, Bool> = new Map<String, Bool>();

	private function generateSong(dataPath:String):Void
	{
		songSpeed = SONG.speed;

		songSpeedType = ClientPrefs.getGameplaySetting('scrolltype', 'multiplicative');

		switch (songSpeedType)
		{
			case "multiplicative":
				songSpeed = SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed', 1);
			case "constant":
				songSpeed = ClientPrefs.getGameplaySetting('scrollspeed', 1);
		}

		var songData = SONG;
		Conductor.changeBPM(songData.bpm);

		curSong = songData.song;

		SONG.needsVoices ? {
			vocals = new FlxSound().loadEmbedded(Paths.voices(PlayState.SONG.song, PlayState.SONG.postfix));
			vocals2 = new FlxSound().loadEmbedded(Paths.voices(PlayState.SONG.song, PlayState.SONG.postfix + '-Second'));
		} : {
			vocals = new FlxSound();
			vocals2 = new FlxSound();
		}

		vocals.pitch = playbackRate;
		FlxG.sound.list.add(vocals);

		vocals2.pitch = playbackRate;
		FlxG.sound.list.add(vocals2);

		FlxG.sound.list.add(new FlxSound().loadEmbedded(Paths.inst(PlayState.SONG.song, PlayState.SONG.postfix)));

		var noteData:Array<SwagSection>;

		// NEW SHIT
		noteData = songData.notes;

		var playerCounter:Int = 0;

		var daBeats:Int = 0; // Not exactly representative of 'daBeats' lol, just how much it has looped

		var songName:String = Paths.formatToSongPath(SONG.song);
		var file:String = Paths.json(songName + '/events');
		#if MODS_ALLOWED
		if (FileSystem.exists(Paths.modsJson(songName + '/events')) || FileSystem.exists(file))
		{
		#else
		if (OpenFlAssets.exists(file))
		{
		#end
			var eventsData:Array<Dynamic> = Song.loadFromJson('events', songName).events;
			for (event in eventsData) // Event Notes
			{
				for (i in 0...event[1].length)
				{
					var newEventNote:Array<Dynamic> = [event[0], event[1][i][0], event[1][i][1], event[1][i][2], event[1][i][3]];
					var subEvent:EventNote = {
						strumTime: newEventNote[0] + ClientPrefs.noteOffset,
						event: newEventNote[1],
						value1: newEventNote[2],
						value2: newEventNote[3],
						value3: newEventNote[4]
					};
					subEvent.strumTime -= eventNoteEarlyTrigger(subEvent);
					eventNotes.push(subEvent);
					eventPushed(subEvent);
				}
			}
		}

		for (section in noteData)
		{
			for (songNotes in section.sectionNotes)
			{
				var daStrumTime = songNotes[0];
				var daNoteData = Std.int(songNotes[1] % 4);
				var gottaHitNote = section.mustHitSection;
				if (songNotes[1] > 3)
					gottaHitNote = !section.mustHitSection;
				var oldNote = unspawnNotes.length > 0 ? unspawnNotes[Std.int(unspawnNotes.length - 1)] : null;
				var swagNote = new Note(daStrumTime, daNoteData, oldNote);
				swagNote.mustPress = gottaHitNote;
				swagNote.sustainLength = Math.round(songNotes[2] / Conductor.stepCrochet) * Conductor.stepCrochet;
				swagNote.gfNote = (section.gfSection && (songNotes[1] < 4));
				swagNote.noteType = songNotes[3];
				if (!Std.isOfType(songNotes[3], String))
					swagNote.noteType = ChartingState.noteTypeList[songNotes[3]];
				swagNote.scrollFactor.set();
				swagNote.ID = unspawnNotes.length;
				modchartObjects.set('note${swagNote.ID}', swagNote);
				unspawnNotes.push(swagNote);
				var floorSus = Math.round(swagNote.sustainLength / Conductor.stepCrochet);
				if (floorSus > 0)
				{
					if (floorSus == 1)
						floorSus++;
					for (susNote in 0...floorSus)
					{
						oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
						var sustainNote = new Note(daStrumTime + (Conductor.stepCrochet * susNote) +
							(Conductor.stepCrochet / FlxMath.roundDecimal(songSpeed, 2)),
							daNoteData, oldNote, true);
						sustainNote.mustPress = gottaHitNote;
						sustainNote.gfNote = (section.gfSection && (songNotes[1] < 4));
						sustainNote.noteType = swagNote.noteType;
						sustainNote.ID = unspawnNotes.length;
						modchartObjects.set('note${sustainNote.ID}', sustainNote);
						sustainNote.scrollFactor.set();
						swagNote.tail.push(sustainNote);
						sustainNote.parent = swagNote;
						unspawnNotes.push(sustainNote);
					}
				}
				if (!noteTypeMap.exists(swagNote.noteType))
				{
					noteTypeMap.set(swagNote.noteType, true);
				}
			}
			daBeats += 1;
		}
		for (event in songData.events) // Event Notes
		{
			for (i in 0...event[1].length)
			{
				var newEventNote:Array<Dynamic> = [event[0], event[1][i][0], event[1][i][1], event[1][i][2], event[1][i][3]];
				var subEvent:EventNote = {
					strumTime: newEventNote[0] + ClientPrefs.noteOffset,
					event: newEventNote[1],
					value1: newEventNote[2],
					value2: newEventNote[3],
					value3: newEventNote[4]
				};
				subEvent.strumTime -= eventNoteEarlyTrigger(subEvent);
				eventNotes.push(subEvent);
				eventPushed(subEvent);
			}
		}
		unspawnNotes.sort(sortByShit);
		if (eventNotes.length > 1)
			eventNotes.sort(sortByTime);
		checkEventNote();
		generatedMusic = true;
	}

	function eventPushed(event:EventNote)
	{
		switch (event.event)
		{
			case 'Change Character':
				var charType:Int = 0;
				switch (event.value1.toLowerCase())
				{
					case 'gf' | 'girlfriend' | '1':
						charType = 2;
					case 'dad' | 'opponent' | '0':
						charType = 1;
					default:
						charType = Std.parseInt(event.value1);
						if (Math.isNaN(charType)) charType = 0;
				}

				var newCharacter:String = event.value2;
				addCharacterToList(newCharacter, charType);

			case 'Dadbattle Spotlight':
				dadbattleBlack = new BGSprite(null, -800, -400, 0, 0);
				dadbattleBlack.makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
				dadbattleBlack.alpha = 0.25;
				dadbattleBlack.visible = false;
				add(dadbattleBlack);

				dadbattleLight = new BGSprite('spotlight', 400, -400);
				dadbattleLight.alpha = 0.375;
				dadbattleLight.blend = ADD;
				dadbattleLight.visible = false;

				dadbattleSmokes.alpha = 0.7;
				dadbattleSmokes.blend = ADD;
				dadbattleSmokes.visible = false;
				add(dadbattleLight);
				add(dadbattleSmokes);

				var offsetX = 200;
				var smoke:BGSprite = new BGSprite('smoke', -1550 + offsetX, 660 + FlxG.random.float(-20, 20), 1.2, 1.05);
				smoke.setGraphicSize(Std.int(smoke.width * FlxG.random.float(1.1, 1.22)));
				smoke.updateHitbox();
				smoke.velocity.x = FlxG.random.float(15, 22);
				smoke.active = true;
				dadbattleSmokes.add(smoke);
				var smoke:BGSprite = new BGSprite('smoke', 1550 + offsetX, 660 + FlxG.random.float(-20, 20), 1.2, 1.05);
				smoke.setGraphicSize(Std.int(smoke.width * FlxG.random.float(1.1, 1.22)));
				smoke.updateHitbox();
				smoke.velocity.x = FlxG.random.float(-15, -22);
				smoke.active = true;
				smoke.flipX = true;
				dadbattleSmokes.add(smoke);

			case 'Philly Glow':
				blammedLightsBlack = new FlxSprite(FlxG.width * -0.5,
					FlxG.height * -0.5).makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
				blammedLightsBlack.visible = false;
				insert(members.indexOf(phillyStreet), blammedLightsBlack);

				phillyWindowEvent = new BGSprite('philly/window', phillyWindow.x, phillyWindow.y, 0.3, 0.3);
				phillyWindowEvent.setGraphicSize(Std.int(phillyWindowEvent.width * 0.85));
				phillyWindowEvent.updateHitbox();
				phillyWindowEvent.visible = false;
				insert(members.indexOf(blammedLightsBlack) + 1, phillyWindowEvent);

				phillyGlowGradient = new PhillyGlow.PhillyGlowGradient(-400, 225); // This shit was refusing to properly load FlxGradient so fuck it
				phillyGlowGradient.visible = false;
				insert(members.indexOf(blammedLightsBlack) + 1, phillyGlowGradient);
				if (!ClientPrefs.flashing)
					phillyGlowGradient.intendedAlpha = 0.7;

				precacheList.set('philly/particle', 'image'); // precache particle image
				phillyGlowParticles = new FlxTypedGroup<PhillyGlow.PhillyGlowParticle>();
				phillyGlowParticles.visible = false;
				insert(members.indexOf(phillyGlowGradient) + 1, phillyGlowParticles);
		}

		if (!eventPushedMap.exists(event.event))
		{
			eventPushedMap.set(event.event, true);
		}
	}

	function eventNoteEarlyTrigger(event:EventNote):Float
	{
		var returnedValue:Float = call('eventEarlyTrigger', [event.event]);

		if (callOnLuas('eventEarlyTrigger', [event.event]) != 0)
			returnedValue = callOnLuas('eventEarlyTrigger', [event.event]);

		if (callOnHscript('eventEarlyTrigger', [event.event]) != 0)
			returnedValue = callOnHscript('eventEarlyTrigger', [event.event]);

		if (returnedValue != 0)
			return returnedValue;

		switch (event.event)
		{
			case 'Kill Henchmen': // Better timing so that the kill sound matches the beat intended
				return 280; // Plays 280ms before the actual position
		}
		return 0;
	}

	function sortByShit(Obj1:Note, Obj2:Note):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}

	function sortByTime(Obj1:EventNote, Obj2:EventNote):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}

	public var skipArrowStartTween:Bool = false; // for lua

	private function generateStaticArrows(player:Int):Void
	{
		for (i in 0...4)
		{
			var targetAlpha:Float = 1;
			if (ClientPrefs.middleScroll && player < 1)
				targetAlpha = 0.35;

			var babyArrow:StrumNote = new StrumNote(ClientPrefs.middleScroll ? STRUM_X_MIDDLESCROLL : STRUM_X, strumLine.y, i, player);
			if (!isStoryMode && !skipArrowStartTween)
			{
				// babyArrow.y -= 10;
				babyArrow.alpha = 0;
				FlxTween.tween(babyArrow, {/*y: babyArrow.y + 10,*/ alpha: targetAlpha}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * i)});
			}
			else
			{
				babyArrow.alpha = targetAlpha;
			}

			if (player == 1)
			{
				modchartObjects.set("playerStrum" + i, babyArrow);
				playerStrums.add(babyArrow);
			}
			else
			{
				modchartObjects.set("opponentStrum" + i, babyArrow);
				if (ClientPrefs.middleScroll)
				{
					babyArrow.x += 310;
					if (i > 1)
						babyArrow.x += FlxG.width / 2 + 25;
				}
				opponentStrums.add(babyArrow);
			}

			strumLineNotes.add(babyArrow);
			babyArrow.postAddedToGroup();
		}
	}

	override function openSubState(SubState:FlxSubState)
	{
		if (paused)
		{
			if (FlxG.sound.music != null)
			{
				FlxG.sound.music.pause();
				vocals.pause();
				vocals2.pause();
			}

			var chars:Array<Character> = characters;
			for (char in chars)
			{
				if (char != null && char.colorTween != null)
				{
					char.colorTween.active = false;
				}
			}
		}
		super.openSubState(SubState);
	}

	override function closeSubState()
	{
		if (PauseSubState.goToOptions)
		{
			if (PauseSubState.goBack)
			{
				PauseSubState.goToOptions = false;
				PauseSubState.goBack = false;
				openSubState(new PauseSubState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));
			}
			else
				openSubState(new OptionsMenu(true));
		}
		else if (paused)
		{
			if (FlxG.sound.music != null && !startingSong)
				resyncVocals();

			for (char in characters)
			{
				if (char != null && char.colorTween != null)
				{
					char.colorTween.active = true;
				}
			}

			paused = false;
			call('onResume', []);
			callOnLuas('onResume', []);
			callOnHscript("onResume", []);
			stageBuild.callFunction("onResume", []);
			FlxTween.globalManager.forEach(function(tween:FlxTween) tween.active = true);
			FlxTimer.globalManager.forEach(function(timer:FlxTimer) timer.active = true);
			FlxG.sound.resume();

			#if desktop
			(startTimer != null && startTimer.finished) ? {
				DiscordClient.changePresence(detailsText, SONG.song
					+ " ("
					+ storyDifficultyText
					+ ")", iconRPC, SONG.player2, true,
					songLength
					- Conductor.songPosition
					- ClientPrefs.noteOffset);
			} : {
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconRPC, SONG.player2);
				}
			#end
		}
		super.closeSubState();
	}

	override public function onFocus():Void
	{
		#if desktop
		if (health > 0 && !paused && FlxG.autoPause)
		{
			if (Conductor.songPosition > 0.0)
				DiscordClient.changePresence(detailsText, SONG.song
					+ " ("
					+ storyDifficultyText
					+ ")", iconRPC, SONG.player2, true,
					songLength
					- Conductor.songPosition
					- ClientPrefs.noteOffset);
			else
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconRPC, SONG.player2);
		}
		#end
		super.onFocus();
	}

	override public function onFocusLost():Void
	{
		if (!FlxG.autoPause && health > 0 && !paused && canPause && startedCountdown && !cpuControlled)
		{
			pauseState();
			#if desktop
			DiscordClient.changePresence(detailsPausedText, SONG.song + " (" + storyDifficultyText + ")", iconRPC, SONG.player2);
			#end
		}
		super.onFocusLost();
	}

	function resyncVocals():Void
	{
		if (finishTimer != null)
			return;

		// vocals.pause();
		// vocals2.pause();

		// FlxG.sound.music.play();
		// FlxG.sound.music.pitch = playbackRate;
		Conductor.songPosition = FlxG.sound.music.time;
		if (Conductor.songPosition <= vocals.length)
		{
			vocals.time = Conductor.songPosition;
			// vocals.pitch = playbackRate;
			// vocals.play();
		}

		if (Conductor.songPosition <= vocals2.length)
		{
			vocals2.time = Conductor.songPosition;
			// vocals2.pitch = playbackRate;
			// vocals2.play();
		}
	}

	public var paused:Bool = false;
	public var canReset:Bool = true;
	var startedCountdown:Bool = false;
	var canPause:Bool = true;
	public var healthPercent:Float = 50;

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		if (SONG.needsVoices && updateTime && vocals.volume < 1)
			vocals.volume += 0.4 * elapsed;

		if (smoothCamera)
			FlxG.camera.followLerp = elapsed * 7.5 * cameraSpeed * playbackRate * (FlxG.updateFramerate / 60);
		else
			FlxG.camera.followLerp = FlxG.updateFramerate / 60;

		callOnLuas('onUpdate', [elapsed]);
		stageBuild.callFunction('onUpdate', [elapsed]);
		callOnHscript("onUpdate", [elapsed]);

		healthBarWN.percent = healthBar.percent;

		grpNoteSplashes.forEachDead(function(splash:NoteSplash)
		{
			if (grpNoteSplashes.length > 1)
			{
				grpNoteSplashes.remove(splash, true);
				splash.destroy();
			}
		});

		switch (curStage)
		{
			case 'tank':
				moveTank(elapsed);
			case 'schoolEvil':
				if (!ClientPrefs.lowQuality && bgGhouls.animation.curAnim.finished)
				{
					bgGhouls.visible = false;
				}
			case 'philly':
				if (trainMoving)
				{
					trainFrameTiming += elapsed;

					if (trainFrameTiming >= 1 / 24)
					{
						updateTrainPos();
						trainFrameTiming = 0;
					}
				}
				phillyWindow.alpha -= (Conductor.crochet / 1000) * FlxG.elapsed * 1.5;

				if (phillyGlowParticles != null)
				{
					var i:Int = phillyGlowParticles.members.length - 1;
					while (i > 0)
					{
						var particle = phillyGlowParticles.members[i];
						if (particle.alpha < 0)
						{
							particle.kill();
							phillyGlowParticles.remove(particle, true);
							particle.destroy();
						}
						--i;
					}
				}
			case 'limo':
				if (!ClientPrefs.lowQuality)
				{
					grpLimoParticles.forEach(function(spr:BGSprite)
					{
						if (spr.animation.curAnim.finished)
						{
							spr.kill();
							grpLimoParticles.remove(spr, true);
							spr.destroy();
						}
					});

					switch (limoKillingState)
					{
						case 1:
							limoMetalPole.x += 5000 * elapsed;
							limoLight.x = limoMetalPole.x - 180;
							limoCorpse.x = limoLight.x - 50;
							limoCorpseTwo.x = limoLight.x + 35;

							var dancers:Array<BackgroundDancer> = grpLimoDancers.members;
							for (i in 0...dancers.length)
							{
								if (dancers[i].x < FlxG.width * 1.5 && limoLight.x > (370 * i) + 170)
								{
									switch (i)
									{
										case 0 | 3:
											if (i == 0)
												FlxG.sound.play(Paths.sound('dancerdeath'), 0.5);

											var diffStr:String = i == 3 ? ' 2 ' : ' ';
											var particle:BGSprite = new BGSprite('gore/noooooo', dancers[i].x + 200, dancers[i].y, 0.4, 0.4,
												['hench leg spin' + diffStr + 'PINK'], false);
											grpLimoParticles.add(particle);
											var particle:BGSprite = new BGSprite('gore/noooooo', dancers[i].x + 160, dancers[i].y + 200, 0.4, 0.4,
												['hench arm spin' + diffStr + 'PINK'], false);
											grpLimoParticles.add(particle);
											var particle:BGSprite = new BGSprite('gore/noooooo', dancers[i].x, dancers[i].y + 50, 0.4, 0.4,
												['hench head spin' + diffStr + 'PINK'], false);
											grpLimoParticles.add(particle);

											var particle:BGSprite = new BGSprite('gore/stupidBlood', dancers[i].x - 110, dancers[i].y + 20, 0.4, 0.4, ['blood'],
												false);
											particle.flipX = true;
											particle.angle = -57.5;
											grpLimoParticles.add(particle);
										case 1:
											limoCorpse.visible = true;
										case 2:
											limoCorpseTwo.visible = true;
									} // Note: Nobody cares about the fifth dancer because he is mostly hidden offscreen :(
									dancers[i].x += FlxG.width * 2;
								}
							}

							if (limoMetalPole.x > FlxG.width * 2)
							{
								resetLimoKill();
								limoSpeed = 800;
								limoKillingState = 2;
							}

						case 2:
							limoSpeed -= 4000 * elapsed;
							bgLimo.x -= limoSpeed * elapsed;
							if (bgLimo.x > FlxG.width * 1.5)
							{
								limoSpeed = 3000;
								limoKillingState = 3;
							}

						case 3:
							limoSpeed -= 2000 * elapsed;
							if (limoSpeed < 1000)
								limoSpeed = 1000;

							bgLimo.x -= limoSpeed * elapsed;
							if (bgLimo.x < -275)
							{
								limoKillingState = 4;
								limoSpeed = 800;
							}

						case 4:
							bgLimo.x = FlxMath.lerp(bgLimo.x, -150, Utils.boundTo(elapsed * 9, 0, 1));
							if (Math.round(bgLimo.x) == -150)
							{
								bgLimo.x = -150;
								limoKillingState = 0;
							}
					}

					if (limoKillingState > 2)
					{
						var dancers:Array<BackgroundDancer> = grpLimoDancers.members;
						for (i in 0...dancers.length)
						{
							dancers[i].x = (370 * i) + bgLimo.x + 280;
						}
					}
				}
			case 'mall':
				if (heyTimer > 0)
				{
					heyTimer -= elapsed;
					if (heyTimer <= 0)
					{
						bottomBoppers.dance(true);
						heyTimer = 0;
					}
				}
		}

		if (!inCutscene)
		{
			var lerpVal:Float = Utils.boundTo(elapsed * 2.4 * cameraSpeed * playbackRate, 0, 1);
			camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));
		}

		if (botplayTxt.visible)
		{
			botplaySine += 180 * elapsed;
			botplayTxt.alpha = 1 - Math.sin((Math.PI * botplaySine) / 180);
		}

		if (controls.PAUSE && startedCountdown && canPause)
		{
			var ret:Dynamic = (callOnLuas('onPause', [], true) || callOnHscript('onPause', [], true) || call("onPause", [])
				|| stageBuild.callFunction("onPause", []));
			if (ret != FunkinLua.Function_Stop)
			{
				pauseState();
			}
		}

		if (health > 2)
			health = 2;

		if (isHealthCheckingEnabled)
			iconGroup.forEach(function(icon:HealthIcon)
			{
				icon.updateAnim(icon.isPlayer ? healthBar.percent : 100 - healthBar.percent);
			});

		displayedHealth = FlxMath.lerp(displayedHealth, Math.max((health * 50), 0), (elapsed * 10));

		healthBarWN.alpha = healthBar.alpha;
		healthBarWN.visible = healthBar.visible;
		healthBarWN.percent = healthBar.percent;
		iconGroup.forEach(function(icon:HealthIcon)
		{
			icon.updateScale(elapsed * iconsZoomingDecay);
			icon.updatePosition(elapsed);
		});

		if (FlxG.keys.anyJustPressed(debugKeysChart) && !endingSong && !inCutscene)
			openChartEditor();

		#if DEVS_BUILD
		if (FlxG.keys.anyJustPressed(debugKeysCharacter) && !endingSong && !inCutscene)
		{
			persistentUpdate = false;
			paused = true;
			cancelMusicFadeTween();
			MusicBeatState.switchState(new CharacterEditorState(dad.curCharacter));
		}
		#end

		if (startedCountdown)
			Conductor.songPosition += FlxG.elapsed * 1000 * playbackRate;

		startingSong ? {
			if (startedCountdown && Conductor.songPosition >= 0)
				startSong();
			else if (!startedCountdown)
				Conductor.songPosition = -Conductor.crochet * 5;
		} : {
			if (!paused)
			{
				songTime += FlxG.game.ticks - previousFrameTime;
				previousFrameTime = FlxG.game.ticks;

				if (Conductor.lastSongPos != Conductor.songPosition)
				{
					songTime = (songTime + Conductor.songPosition) / 2;
					Conductor.lastSongPos = Conductor.songPosition;
				}
				if (updateTime)
				{
					var curTime:Float = Conductor.songPosition - ClientPrefs.noteOffset;
					if (curTime < 0)
						curTime = 0;
					songPercent = (curTime / songLength) / playbackRate;
				}
			}
		}

		if (camZooming)
		{
			FlxG.camera.zoom = FlxMath.lerp(defaultCamZoom, FlxG.camera.zoom, Utils.boundTo(1 - (elapsed * 3.125 * camZoomingDecay * playbackRate), 0, 1));
			camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, Utils.boundTo(1 - (elapsed * 3.125 * camZoomingDecay * playbackRate), 0, 1));
		}

		// RESET
		if (!ClientPrefs.noReset && controls.RESET && canReset && !inCutscene && startedCountdown && !endingSong)
		{
			doDeathCheck(true);
			trace("RESET = True");
		}
		doDeathCheck();

		if (unspawnNotes[0] != null)
		{
			var time:Float = spawnTime;
			if (songSpeed < 1)
				time /= songSpeed;
			if (unspawnNotes[0].multSpeed < 1)
				time /= unspawnNotes[0].multSpeed;

			while (unspawnNotes.length > 0 && unspawnNotes[0].strumTime - Conductor.songPosition < time)
			{
				var dunceNote:Note = unspawnNotes[0];
				notes.insert(0, dunceNote);

				dunceNote.isSustainNote ? sustainNotes.insert(0, dunceNote) : regularNotes.insert(0, dunceNote);

				dunceNote.spawned = true;
				call('onSpawnNote', [
					notes.members.indexOf(dunceNote),
					dunceNote.noteData,
					dunceNote.noteType,
					dunceNote.isSustainNote
				]);
				callOnLuas('onSpawnNote', [
					notes.members.indexOf(dunceNote),
					dunceNote.noteData,
					dunceNote.noteType,
					dunceNote.isSustainNote
				]);
				callOnHscript('onSpawnNote', [
					notes.members.indexOf(dunceNote),
					dunceNote.noteData,
					dunceNote.noteType,
					dunceNote.isSustainNote
				]);
				stageBuild.callFunction('onSpawnNote', [
					notes.members.indexOf(dunceNote),
					dunceNote.noteData,
					dunceNote.noteType,
					dunceNote.isSustainNote
				]);
				var index:Int = unspawnNotes.indexOf(dunceNote);
				unspawnNotes.splice(index, 1);
			}
		}

		if (generatedMusic && !inCutscene)
		{
			if (!cpuControlled)
			{
				keysCheck();
			}
			else if (boyfriend.animation.curAnim != null
				&& boyfriend.holdTimer > Conductor.stepCrochet * (0.0011 / FlxG.sound.music.pitch) * boyfriend.singDuration
					&& boyfriend.animation.curAnim.name.startsWith(boyfriend.singAnimsPrefix)
					&& !boyfriend.animation.curAnim.name.endsWith('miss'))
			{
				boyfriend.dance();
			}

			if (startedCountdown)
			{
				var fakeCrochet:Float = (60 / SONG.bpm) * 1000;
				notes.forEachAlive(function(daNote:Note)
				{
					var strumGroup:FlxTypedGroup<StrumNote> = playerStrums;
					if (!daNote.mustPress)
						strumGroup = opponentStrums;

					var strumX:Float = strumGroup.members[daNote.noteData].x;
					var strumY:Float = strumGroup.members[daNote.noteData].y;
					var strumAngle:Float = strumGroup.members[daNote.noteData].angle;
					var strumDirection:Float = strumGroup.members[daNote.noteData].direction;
					var strumAlpha:Float = strumGroup.members[daNote.noteData].alpha;
					var strumScroll:Bool = strumGroup.members[daNote.noteData].downScroll;

					strumX += daNote.offsetX;
					strumY += daNote.offsetY;
					strumAngle += daNote.offsetAngle;
					strumAlpha *= daNote.multAlpha;

					daNote.distance = ((strumScroll ? 0.45 : -0.45) * (Conductor.songPosition - daNote.strumTime) * songSpeed * daNote.multSpeed);

					var angleDir = strumDirection * Math.PI / 180;

					if (daNote.isSustainNote)
						daNote.angle = strumDirection - 90;

					if (daNote.copyAngle)
						daNote.angle = strumDirection - 90 + strumAngle;

					if (daNote.copyAlpha)
						daNote.alpha = strumAlpha;

					if (daNote.copyX)
						daNote.x = strumX + Math.cos(angleDir) * daNote.distance;

					if (daNote.copyY)
					{
						daNote.y = strumY + Math.sin(angleDir) * daNote.distance;

						// Jesus fuck this took me so much mother fucking time AAAAAAAAAA
						if (strumScroll && daNote.isSustainNote)
						{
							if (daNote.animation.curAnim.name.endsWith('end'))
							{
								daNote.y += 10.5 * (fakeCrochet / 400) * 1.5 * songSpeed + (46 * (songSpeed - 1));
								daNote.y -= 46 * (1 - (fakeCrochet / 600)) * songSpeed;
								if (PlayState.isPixelStage)
								{
									daNote.y += 8 + (6 - daNote.originalHeightForCalcs) * PlayState.daPixelZoom;
								}
								else
								{
									daNote.y -= 19;
								}
							}
							daNote.y += (Note.swagWidth / 2) - (60.5 * (songSpeed - 1));
							daNote.y += 27.5 * ((SONG.bpm / 100) - 1) * (songSpeed - 1);
						}
					}

					if (!daNote.mustPress && daNote.wasGoodHit && !daNote.hitByOpponent && !daNote.ignoreNote)
					{
						opponentNoteHit(daNote);
					}

					if (cpuControlled && daNote.mustPress && !daNote.blockHit && daNote.canBeHit)
					{
						if (daNote.isSustainNote)
						{
							if (!daNote.wasGoodHit)
							{
								goodNoteHit(daNote);
							}
						}
						else if (daNote.strumTime <= Conductor.songPosition)
						{
							goodNoteHit(daNote);
						}
					}

					var center:Float = strumY + Note.swagWidth / 2;
					if (strumGroup.members[daNote.noteData].sustainReduce
						&& daNote.isSustainNote
						&& (daNote.mustPress || !daNote.ignoreNote)
						&& (!daNote.mustPress || (daNote.wasGoodHit || (daNote.prevNote.wasGoodHit && !daNote.canBeHit))))
					{
						if (strumScroll)
						{
							if (daNote.y - daNote.offset.y * daNote.scale.y + daNote.height >= center)
							{
								var swagRect = new FlxRect(0, 0, daNote.frameWidth, daNote.frameHeight);
								swagRect.height = (center - daNote.y) / daNote.scale.y;
								swagRect.y = daNote.frameHeight - swagRect.height;

								daNote.clipRect = swagRect;
							}
						}
						else
						{
							if (daNote.y + daNote.offset.y * daNote.scale.y <= center)
							{
								var swagRect = new FlxRect(0, 0, daNote.width / daNote.scale.x, daNote.height / daNote.scale.y);
								swagRect.y = (center - daNote.y) / daNote.scale.y;
								swagRect.height -= swagRect.y;

								daNote.clipRect = swagRect;
							}
						}
					}

					// Kill extremely late notes and cause misses
					if (Conductor.songPosition - daNote.strumTime > noteKillOffset)
					{
						if (daNote.mustPress && !cpuControlled && !daNote.ignoreNote && !endingSong && (daNote.tooLate || !daNote.wasGoodHit))
						{
							noteMiss(daNote);
						}

						notes.remove(daNote, true);
						daNote.cameras = [camHUD];
						if (daNote.isSustainNote)
							daNote.y += playerStrums.members[daNote.noteData].downScroll ? 25 : -25;
						add(daNote);
						FlxTween.tween(daNote, {alpha: 0, y: daNote.y + (playerStrums.members[daNote.noteData].downScroll ? 25 : -25)}, 0.25, {
							onComplete: (_) ->
							{
								daNote.active = false;
								daNote.kill();
								daNote.destroy();
							}
						});
					}
				});
			}
			else
			{
				notes.forEachAlive(function(daNote:Note)
				{
					daNote.canBeHit = false;
					daNote.wasGoodHit = false;
				});
			}
		}
		checkEventNote();

		#if DEVS_BUILD
		if (!endingSong && !startingSong)
		{
			if (FlxG.keys.justPressed.ONE)
			{
				KillNotes();
				FlxG.sound.music.onComplete();
			}
			if (FlxG.keys.justPressed.TWO)
			{ // Go 10 seconds into the future :O
				setSongTime(Conductor.songPosition + 10000);
				clearNotesBefore(Conductor.songPosition);
			}
			if (FlxG.keys.justPressed.THREE)
			{
				cpuControlled = !cpuControlled;
				botplayTxt.visible = cpuControlled;
			}
		}
		#end

		healthBarWN.percent = healthBar.percent;

		setOnLuas('cameraX', camFollowPos.x);
		setOnLuas('cameraY', camFollowPos.y);
		setOnLuas('botPlay', cpuControlled);
		call('onUpdatePost', [elapsed]);
		callOnLuas('onUpdatePost', [elapsed]);
		stageBuild.callFunction('onUpdatePost', [elapsed]);
		callOnHscript("onUpdatePost", [elapsed]);
	}

	function checkFutureNotes(time:Float)
	{
		var i:Int = 0;
		var notesExist:Bool = false;
		while (i <= notes.length - 1 && notes.length > 0)
		{
			var daNote:Note = notes.members[i];
			if (daNote.mustPress && !daNote.isSustainNote && daNote.strumTime - (Conductor.crochet * 3.75 * playbackRate) > time)
			{
				notesExist = true;
				break;
			}
			++i;
		}
		trace(notesExist);
		return notesExist;
	}

	function pauseState()
	{
		FlxG.camera.followLerp = 0;
		persistentUpdate = false;
		persistentDraw = true;
		paused = true;
		if (FlxG.sound.music != null)
		{
			FlxG.sound.music.pause();
			vocals.pause();
			vocals2.pause();
		}
		FlxTween.globalManager.forEach(function(tween:FlxTween) tween.active = false);
		FlxTimer.globalManager.forEach(function(timer:FlxTimer) timer.active = false);
		FlxG.sound.pause();
		if (!cpuControlled)
		{
			for (note in playerStrums)
				if (note.animation.curAnim != null && note.animation.curAnim.name != 'static')
				{
					note.playAnim('static');
					note.resetAnim = 0;
				}
		}
		openSubState(new PauseSubState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));
		#if desktop
		DiscordClient.changePresence(detailsPausedText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter().toUpperCase());
		#end
	}

	function loadScript(scriptType:String, scriptName:String)
	{
		var luaTL:String = Paths.modFolders("custom_" + scriptType + "/" + scriptName + ".lua");
		var hxTL:String = Paths.modFolders("custom_" + scriptType + "/" + scriptName + ".hx");
		if (FileSystem.exists(luaTL) || OpenFlAssets.exists(luaTL))
			luaArray.push(new FunkinLua(luaTL));

		if (FileSystem.exists(hxTL) || OpenFlAssets.exists(hxTL))
			hscriptArray.push(GrfxScriptHandler.noPathModule(hxTL));
	}

	function openChartEditor()
	{
		persistentUpdate = false;
		paused = true;
		cancelMusicFadeTween();
		MusicBeatState.switchState(new ChartingState());
		chartingMode = true;

		#if desktop
		DiscordClient.changePresence("Chart Editor", null, null, null, true);
		#end
	}

	public var isDead:Bool = false; // Don't mess with this on Lua!!!

	function doDeathCheck(?skipHealthCheck:Bool = false)
	{
		if (((skipHealthCheck && instakillOnMiss) || health <= 0) && !practiceMode && !isDead)
		{
			var ret:Dynamic = (callOnLuas('onGameOver', [], false) || callOnHscript('onGameOver', [], false));
			if (ret != FunkinLua.Function_Stop)
			{
				call('onGameOver', []);
				boyfriend.stunned = true;
				deathCounter++;

				paused = true;

				vocals.stop();
				vocals2.stop();
				FlxG.sound.music.stop();

				persistentUpdate = false;
				persistentDraw = false;
				for (tween in modchartTweens)
				{
					tween.active = true;
				}
				for (timer in modchartTimers)
				{
					timer.active = true;
				}

				for (sound in modchartSounds)
				{
					sound.play();
				}

				!ClientPrefs.instantRespawn ? openSubState(new GameOverSubstate(boyfriend.getScreenPosition().x - boyfriend.positionArray[0],
					boyfriend.getScreenPosition().y - boyfriend.positionArray[1])) : MusicBeatState.resetState();

				#if desktop
				// Game Over doesn't get his own variable because it's only used here
				DiscordClient.changePresence("Game Over - "
					+ detailsText,
					SONG.song
					+ " ("
					+ storyDifficultyText
					+ ")\nDeathAccuracy: "
					+ Highscore.floorDecimal(ratingPercent * 100, 2)
					+ " \nDeathScore:  "
					+ songScore
					+ "\n ",
					iconRPC, SONG.player2);
				#end
				isDead = true;
				return true;
			}
		}
		return false;
	}

	public function checkEventNote()
	{
		while (eventNotes.length > 0)
		{
			var leStrumTime:Float = eventNotes[0].strumTime;
			if (Conductor.songPosition < leStrumTime)
				break;

			var value1:String = '';
			if (eventNotes[0].value1 != null)
				value1 = eventNotes[0].value1;
			var value2:String = '';
			if (eventNotes[0].value2 != null)
				value2 = eventNotes[0].value2;
			var value3:String = '';
			if (eventNotes[0].value3 != null)
				value3 = eventNotes[0].value3;
			triggerEventNote(eventNotes[0].event, value1, value2, value3);
			eventNotes.shift();
		}
	}

	public function updateScore(miss:Bool = false, ?forced:Bool = false)
	{
		ClientPrefs.classicScoreTxt ? scoreTxt.text = "Score:" + songScore : scoreTxt.text = 'Score: '
			+ songScore
			+ ' | Misses: '
			+ songMisses
			+ ' | Rating: '
			+ ratingName
			+ (ratingName != '?' ? ' (${Highscore.floorDecimal(ratingPercent * 100, 2)}%) - $ratingFC' : '');

		if (!ClientPrefs.scoreZoom && !miss && !cpuControlled && !ClientPrefs.classicScoreTxt)
		{
			if (scoreTxtTween != null)
				scoreTxtTween.cancel();

			scoreTxt.scale.x = 1.075;
			scoreTxt.scale.y = 1.075;
			scoreTxtTween = FlxTween.tween(scoreTxt.scale, {x: 1, y: 1}, 0.2, {
				onComplete: function(twn:FlxTween)
				{
					scoreTxtTween = null;
				}
			});
		}
		call("onUpdateScore", [miss, forced]);
		callOnLuas('onUpdateScore', [miss, forced]);
		callOnHscript("onUpdateScore", [miss, forced]);
		stageBuild.callFunction('onUpdateScore', [miss, forced]);
	}

	public function triggerEventNote(eventName:String, value1:String, value2:String, ?value3:String)
	{
		switch (eventName)
		{
			case 'Dadbattle Spotlight':
				var val:Null<Int> = Std.parseInt(value1);
				if (val == null)
					val = 0;

				switch (Std.parseInt(value1))
				{
					case 1, 2, 3: // enable and target dad
						if (val == 1) // enable
						{
							dadbattleBlack.visible = true;
							dadbattleLight.visible = true;
							dadbattleSmokes.visible = true;
							defaultCamZoom += 0.12;
						}

						var who:Character = dad;
						if (val > 2)
							who = boyfriend;
						// 2 only targets dad
						dadbattleLight.alpha = 0;
						new FlxTimer().start(0.12, function(tmr:FlxTimer)
						{
							dadbattleLight.alpha = 0.375;
						});
						dadbattleLight.setPosition(who.getGraphicMidpoint().x - dadbattleLight.width / 2, who.y + who.height - dadbattleLight.height + 50);

					default:
						dadbattleBlack.visible = false;
						dadbattleLight.visible = false;
						defaultCamZoom -= 0.12;
						FlxTween.tween(dadbattleSmokes, {alpha: 0}, 1, {
							onComplete: function(twn:FlxTween)
							{
								dadbattleSmokes.visible = false;
							}
						});
				}

			case 'Forced Combo Check':
				popUpComboScore(false);

			case 'Hey!':
				var value:Int = 2;
				switch (value1.toLowerCase().trim())
				{
					case 'bf' | 'boyfriend' | '0':
						value = 0;
					case 'gf' | 'girlfriend' | '1':
						value = 1;
				}

				var time:Float = Std.parseFloat(value2);
				if (Math.isNaN(time) || time <= 0)
					time = 0.6;

				if (value != 0)
				{
					if (dad.curCharacter.startsWith('gf'))
					{ // Tutorial GF is actually Dad! The GF is an imposter!! ding ding ding ding ding ding ding, dindinding, end my suffering
						dad.playAnim('cheer', true);
						dad.specialAnim = true;
						dad.heyTimer = time;
					}
					else if (gf != null)
					{
						gf.playAnim('cheer', true);
						gf.specialAnim = true;
						gf.heyTimer = time;
					}
				}
				if (value != 1)
				{
					boyfriend.playAnim('hey', true);
					boyfriend.specialAnim = true;
					boyfriend.heyTimer = time;
				}
			case 'Philly Glow':
				var lightId:Int = Std.parseInt(value1);
				if (Math.isNaN(lightId))
					lightId = 0;

				var doFlash:Void->Void = function()
				{
					var color:FlxColor = FlxColor.WHITE;
					if (!ClientPrefs.flashing)
						color.alphaFloat = 0.5;

					FlxG.camera.flash(color, 0.15, null, true);
				};

				switch (lightId)
				{
					case 0:
						if (phillyGlowGradient.visible)
						{
							doFlash();
							if (ClientPrefs.camZooms)
							{
								FlxG.camera.zoom += 0.5;
								camHUD.zoom += 0.1;
							}

							blammedLightsBlack.visible = false;
							phillyWindowEvent.visible = false;
							phillyGlowGradient.visible = false;
							phillyGlowParticles.visible = false;
							curLightEvent = -1;

							for (who in characters)
							{
								who.color = FlxColor.WHITE;
							}
							phillyStreet.color = FlxColor.WHITE;
						}

					case 1: // turn on
						curLightEvent = FlxG.random.int(0, phillyLightsColors.length - 1, [curLightEvent]);
						var color:FlxColor = phillyLightsColors[curLightEvent];

						if (!phillyGlowGradient.visible)
						{
							doFlash();
							if (ClientPrefs.camZooms)
							{
								FlxG.camera.zoom += 0.5;
								camHUD.zoom += 0.1;
							}

							blammedLightsBlack.visible = true;
							blammedLightsBlack.alpha = 1;
							phillyWindowEvent.visible = true;
							phillyGlowGradient.visible = true;
							phillyGlowParticles.visible = true;
						}
						else if (ClientPrefs.flashing)
						{
							var colorButLower:FlxColor = color;
							colorButLower.alphaFloat = 0.25;
							FlxG.camera.flash(colorButLower, 0.5, null, true);
						}

						var charColor:FlxColor = color;
						if (!ClientPrefs.flashing)
							charColor.saturation *= 0.5;
						else
							charColor.saturation *= 0.75;

						for (who in characters)
						{
							who.color = charColor;
						}
						phillyGlowParticles.forEachAlive(function(particle:PhillyGlow.PhillyGlowParticle)
						{
							particle.color = color;
						});
						phillyGlowGradient.color = color;
						phillyWindowEvent.color = color;

						color.brightness *= 0.5;
						phillyStreet.color = color;

					case 2: // spawn particles
						if (!ClientPrefs.lowQuality)
						{
							var particlesNum:Int = FlxG.random.int(8, 12);
							var width:Float = (2000 / particlesNum);
							var color:FlxColor = phillyLightsColors[curLightEvent];
							for (j in 0...3)
							{
								for (i in 0...particlesNum)
								{
									var particle:PhillyGlow.PhillyGlowParticle = new PhillyGlow.PhillyGlowParticle(-400
										+ width * i
										+ FlxG.random.float(-width / 5, width / 5),
										phillyGlowGradient.originalY
										+ 200
										+ (FlxG.random.float(0, 125) + j * 40), color);
									phillyGlowParticles.add(particle);
								}
							}
						}
						phillyGlowGradient.bop();
				}

			case 'Kill Henchmen':
				killHenchmen();

			case 'Set GF Speed':
				var value:Int = Std.parseInt(value1);
				if (Math.isNaN(value) || value < 1)
					value = 1;
				gfSpeed = value;

			case 'Add Camera Zoom':
				if (ClientPrefs.camZooms)
				{
					var camZoom:Float = Std.parseFloat(value1);
					var hudZoom:Float = Std.parseFloat(value2);
					if (Math.isNaN(camZoom))
						camZoom = 0.015;
					if (Math.isNaN(hudZoom))
						hudZoom = 0.03;

					FlxG.camera.zoom += camZoom;
					camHUD.zoom += hudZoom;
				}

			case 'Trigger BG Ghouls':
				if (curStage == 'schoolEvil' && !ClientPrefs.lowQuality)
				{
					bgGhouls.dance(true);
					bgGhouls.visible = true;
				}

			case 'Play Animation':
				// trace('Anim to play: ' + value1);
				var char:Character = dad;
				switch (value2.toLowerCase().trim())
				{
					case 'bf' | 'boyfriend':
						char = boyfriend;
					case 'gf' | 'girlfriend':
						char = gf;
					default:
						var val2:Int = Std.parseInt(value2);
						if (Math.isNaN(val2))
							val2 = 0;

						switch (val2)
						{
							case 1: char = boyfriend;
							case 2: char = gf;
						}
				}
				if (char != null)
				{
					char.playAnim(value1, true);
					char.specialAnim = true;
				}

			case 'Camera Follow Pos':
				isEventWorking = false;
				var val1:Float = Std.parseFloat(value1);
				var val2:Float = Std.parseFloat(value2);
				if (Math.isNaN(val1))
					val1 = 0;
				if (Math.isNaN(val2))
					val2 = 0;

				isCameraOnForcedPos = false;
				if (!Math.isNaN(Std.parseFloat(value1)) || !Math.isNaN(Std.parseFloat(value2)))
				{
					camFollow.x = val1;
					camFollow.y = val2;
					camGame.targetOffset.set(0, 0);
					isCameraOnForcedPos = true;
					isEventWorking = true;
				}

			case 'BG Freaks Expression':
				if (bgGirls != null)
					bgGirls.swapDanceType();

			case 'Set Cam Zoom':
				var val1:Float = Std.parseFloat(value1);
				var val2:Float = Std.parseFloat(value2);
				if (Math.isNaN(val1))
					val1 = 1;
				if (Math.isNaN(val2) || val2 == 0)
					defaultCamZoom = val1;
				else
				{
					FlxTween.tween(camGame, {zoom: val1}, val2, {
						ease: FlxEase.sineInOut,
						onComplete: function(twn:FlxTween)
						{
							defaultCamZoom = camGame.zoom;
						}
					});
				}

			case 'Alt Idle Animation':
				var char:Character = dad;
				switch (value1.toLowerCase())
				{
					case 'gf' | 'girlfriend':
						char = gf;
					case 'boyfriend' | 'bf':
						char = boyfriend;
					default:
						var val:Int = Std.parseInt(value1);
						if (Math.isNaN(val))
							val = 0;

						switch (val)
						{
							case 1: char = boyfriend;
							case 2: char = gf;
						}
				}
				if (char != null)
				{
					char.idleSuffix = value2;
					char.recalculateDanceIdle();
				}

			case 'Sing Animation Prefix':
				var char:Character = dad;
				switch (value1.toLowerCase())
				{
					case 'gf' | 'girlfriend':
						char = gf;
					case 'boyfriend' | 'bf':
						char = boyfriend;
					default:
						var val:Int = Std.parseInt(value1);
						if (Math.isNaN(val))
							val = 0;

						switch (val)
						{
							case 1: char = boyfriend;
							case 2: char = gf;
						}
				}

				if (value2 == null || value2 == '' || value2 == ' ')
					value2 = 'sing';

				if (char != null)
					char.singAnimsPrefix = value2;

			case 'Screen Shake':
				var valuesArray:Array<String> = [value1, value2];
				var targetsArray:Array<FlxCamera> = [camGame, camHUD];
				for (i in 0...targetsArray.length)
				{
					var split:Array<String> = valuesArray[i].split(',');
					var duration:Float = 0;
					var intensity:Float = 0;
					if (split[0] != null)
						duration = Std.parseFloat(split[0].trim());
					if (split[1] != null)
						intensity = Std.parseFloat(split[1].trim());
					if (Math.isNaN(duration))
						duration = 0;
					if (Math.isNaN(intensity))
						intensity = 0;

					if (duration > 0 && intensity != 0)
					{
						targetsArray[i].shake(intensity, duration);
					}
				}

			case 'Change Character':
				var charType:Int = 0;
				switch (value1.toLowerCase().trim())
				{
					case 'gf' | 'girlfriend':
						charType = 2;
					case 'dad' | 'opponent':
						charType = 1;
					default:
						charType = Std.parseInt(value1);
						if (Math.isNaN(charType)) charType = 0;
				}

				switch (charType)
				{
					case 0:
						if (boyfriend.curCharacter != value2)
						{
							if (!boyfriendMap.exists(value2))
							{
								addCharacterToList(value2, charType);
							}

							for (script in luaArray)
							{
								if (script.scriptName.contains(boyfriend.curCharacter))
								{
									// trace('removed script: ${script}');
									luaArray.remove(script);
								}
							}
							for (script in hscriptArray)
							{
								if (script.scriptName.contains(boyfriend.curCharacter))
								{
									// trace('removed script: ${script}');
									hscriptArray.remove(script);
								}
							}

							var lastAlpha:Float = boyfriend.alpha;
							boyfriend.alpha = 0.00001;
							boyfriend = boyfriendMap.get(value2);
							boyfriend.alpha = lastAlpha;
							iconP1.changeIcon(boyfriend.healthIcon, {type: boyfriend.healthIconType, offsets: boyfriend.iconOffsets,
								scale: boyfriend.iconScale});
							characters.remove(boyfriend);
							characters.push(boyfriend);
						}
						setOnLuas('boyfriendName', boyfriend.curCharacter);

					case 1:
						if (dad.curCharacter != value2)
						{
							if (!dadMap.exists(value2))
							{
								addCharacterToList(value2, charType);
							}

							for (script in luaArray)
							{
								if (script.scriptName.contains(dad.curCharacter))
								{
									// trace('removed script: ${script}');
									luaArray.remove(script);
								}
							}
							for (script in hscriptArray)
							{
								if (script.scriptName.contains(dad.curCharacter))
								{
									// trace('removed script: ${script}');
									hscriptArray.remove(script);
								}
							}

							var wasGf:Bool = dad.curCharacter.startsWith('gf');
							var lastAlpha:Float = dad.alpha;
							dad.alpha = 0.00001;
							dad = dadMap.get(value2);
							if (!dad.curCharacter.startsWith('gf'))
							{
								if (wasGf && gf != null)
								{
									gf.visible = true;
								}
							}
							else if (gf != null)
							{
								gf.visible = false;
							}
							dad.alpha = lastAlpha;
							iconP2.changeIcon(dad.healthIcon, {type: dad.healthIconType, offsets: dad.iconOffsets, scale: dad.iconScale});
							characters.remove(dad);
							characters.push(dad);
						}
						setOnLuas('dadName', dad.curCharacter);

					case 2:
						if (gf != null)
						{
							if (gf.curCharacter != value2)
							{
								if (!gfMap.exists(value2))
								{
									addCharacterToList(value2, charType);
								}

								for (script in luaArray)
								{
									if (script.scriptName.contains(gf.curCharacter))
									{
										// trace('removed script: ${script}');
										luaArray.remove(script);
									}
								}
								for (script in hscriptArray)
								{
									if (script.scriptName.contains(gf.curCharacter))
									{
										// trace('removed script: ${script}');
										hscriptArray.remove(script);
									}
								}

								var lastAlpha:Float = gf.alpha;
								gf.alpha = 0.00001;
								gf = gfMap.get(value2);
								gf.alpha = lastAlpha;
							}
							characters.remove(gf);
							characters.push(gf);
							setOnLuas('gfName', gf.curCharacter);
						}
				}
				reloadHealthBarColors();

			case 'Change Scroll Speed':
				if (songSpeedType == "constant")
					return;
				var val1:Float = Std.parseFloat(value1);
				var val2:Float = Std.parseFloat(value2);
				if (Math.isNaN(val1))
					val1 = 1;
				if (Math.isNaN(val2))
					val2 = 0;

				var ease:(t:Float) -> Float = FunkinLua.getFlxEaseByString(value3);
				var newValue:Float = SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed', 1) * val1;

				if (val2 <= 0)
				{
					songSpeed = newValue;
				}
				else
				{
					songSpeedTween = FlxTween.tween(this, {songSpeed: newValue}, val2 / playbackRate, {
						ease: ease,
						onComplete: function(twn:FlxTween)
						{
							songSpeedTween = null;
						}
					});
				}

			case 'Set Property':
				var killMe:Array<String> = value1.split('.');
				if (killMe.length > 1)
				{
					FunkinLua.setVarInArray(FunkinLua.getPropertyLoopThingWhatever(killMe, true, true), killMe[killMe.length - 1], value2);
				}
				else
				{
					FunkinLua.setVarInArray(this, value1, value2);
				}

			case 'Swap Hud':
				if (!hudIsSwapped)
				{
					playerStrums.forEach(function(spr:FlxSprite)
					{
						FlxTween.tween(spr, {x: spr.x - 650}, 0.1, {
							ease: FlxEase.circOut
						});
					});
					opponentStrums.forEach(function(spr:FlxSprite)
					{
						FlxTween.tween(spr, {x: spr.x + 650}, 0.1, {
							ease: FlxEase.circOut
						});
					});
					hudIsSwapped = true;
				}
				else
				{
					playerStrums.forEach(function(spr:FlxSprite)
					{
						FlxTween.tween(spr, {x: spr.x + 650}, 0.1, {
							ease: FlxEase.circOut
						});
					});
					opponentStrums.forEach(function(spr:FlxSprite)
					{
						FlxTween.tween(spr, {x: spr.x - 650}, 0.1, {
							ease: FlxEase.circOut
						});
					});
					hudIsSwapped = false;
				}

			// i totally didnt need to do this but its here
			case 'Flash Camera':
				var val1:Null<Float> = Std.parseFloat(value1);
				var val2:Null<Int> = Std.parseInt(value2);
				FlxG.camera.flash(val2, val1);

			case 'Flash Camera (HUD)':
				var val1:Null<Float> = Std.parseFloat(value1);
				var val2:Null<Int> = Std.parseInt(value2);
				camHUD.flash(val2, val1);

			case 'Set Cam Speed':
				var val1:Null<Float> = Std.parseFloat(value1);
				cameraSpeed = val1;

			case 'Dialogue':
				var color:Int = FlxColor.YELLOW;
				if (value2 != null && value2.length > 0 && value2 != '' && value2 != ' ')
					if (!value2.startsWith('0x'))
						color = Std.parseInt('0xff' + value2);
					else
						color = Std.parseInt(value2);

				var subMark = new FlxTextFormatMarkerPair(new FlxTextFormat(color), '<m>');

				if (value1 != null && value1 != '')
					sub.applyMarkup(value1, [subMark]);

				if (value1 != null && value1.length > 0 && sub.alpha < 1)
				{
					if (subtitlesTxtAlphaTween != null)
						subtitlesTxtAlphaTween.cancel();
					sub.alpha = 1;
				}

				if ((value1 == '' || value1.length == 0) && sub.alpha > 0)
				{
					if (subtitlesTxtAlphaTween != null)
						subtitlesTxtAlphaTween.cancel();

					subtitlesTxtAlphaTween = FlxTween.tween(sub, {alpha: 0}, 0.3, {
						onComplete: function(twn:FlxTween)
						{
							subtitlesTxtAlphaTween = null;
						}
					});
				}

				if (value3 != null && value3 != '' && value3 != ' ')
				{
					var props:Array<Dynamic> = value3.split(',');
					if (props.length > 0)
						sub.size = Std.parseInt(props[0]);

					if (props.length > 1)
						sub.alpha = props[1];
				}

				if (value1 != null && value1.length > 0 && sub.alpha < 1)
					sub.alpha = 1;

				sub.screenCenter();
				sub.y += 170;

				if (value1 != null && value1.length > 0)
				{
					if (subtitlesTxtTween != null)
						subtitlesTxtTween.cancel();

					sub.scale.x = .97;
					sub.scale.y = 1.15;
					subtitlesTxtTween = FlxTween.tween(sub.scale, {x: 1, y: 1}, 0.15, {
						onComplete: function(twn:FlxTween)
						{
							subtitlesTxtTween = null;
						}
					});
				}
		}

		call('onEvent', [eventName, value1, value2, value3]);
		callOnLuas('onEvent', [eventName, value1, value2, value3]);
		callOnHscript("onEvent", [eventName, value1, value2, value3]);
		stageBuild.callFunction('onEvent', [eventName, value1, value2, value3]);
	}

	function moveCameraSection():Void
	{
		if (SONG.notes[curSection] == null)
			return;

		var camShouldMove = true;

		if (SONG.notes[curSection].gfSection && camFocus != 'gf')
		{
			camFocus = 'gf';
			camShouldMove = true;
		}

		if (!SONG.notes[curSection].mustHitSection && !SONG.notes[curSection].gfSection && camFocus != 'dad')
		{
			camFocus = 'dad';
			camShouldMove = true;
		}

		if (SONG.notes[curSection].mustHitSection && !SONG.notes[curSection].gfSection && camFocus != 'bf')
		{
			camFocus = 'bf';
			camShouldMove = true;
		}

		call('onPreMoveCamera', [camFocus, camShouldMove]);
		callOnLuas('onPreMoveCamera', [camFocus, camShouldMove]);
		callOnHscript("onPreMoveCamera", [camFocus, camShouldMove]);
		stageBuild.callFunction('onPreMoveCamera', [camFocus, camShouldMove]);

		if (camShouldMove)
			moveCamera(camFocus);
	}

	public function moveCamera(char:String = 'bf')
	{
		getCamOffsets();
		camFollow.x = camCharsPositions.get(char)[0];
		camFollow.y = camCharsPositions.get(char)[1];
		camGame.targetOffset.set(0, 0);
		call('onMoveCamera', [char]);
		callOnLuas('onMoveCamera', [char]);
		callOnHscript("onMoveCamera", [char]);
		stageBuild.callFunction('onMoveCamera', [char]);
	}

	function snapCamFollowToPos(x:Float, y:Float)
	{
		camFollow.set(x, y);
		camFollowPos.setPosition(x, y);
	}

	public function finishSong(?ignoreNoteOffset:Bool = false):Void
	{
		var finishCallback:Void->Void = endSong; // In case you want to change it in a specific song.

		updateTime = false;
		FlxG.sound.music.volume = 0;
		vocals.volume = 0;
		vocals.pause();
		vocals2.volume = 0;
		vocals2.pause();
		if (ClientPrefs.noteOffset <= 0 || ignoreNoteOffset)
		{
			finishCallback();
		}
		else
		{
			finishTimer = new FlxTimer().start(ClientPrefs.noteOffset / 1000, function(tmr:FlxTimer)
			{
				finishCallback();
			});
		}
	}

	public function getControl(key:String)
	{
		var pressed:Bool = Reflect.getProperty(controls, key);
		// trace('Control result: ' + pressed);
		return pressed;
	}

	public var transitioning = false;

	public function endSong():Void
	{
		trace('Song "' + SONG.song + '" ended');
		// Should kill you if you tried to cheat
		if (!startingSong)
		{
			notes.forEach(function(daNote:Note)
			{
				if (daNote.strumTime < songLength - Conductor.safeZoneOffset)
				{
					health -= 0.05 * healthLoss;
				}
			});
			for (daNote in unspawnNotes)
			{
				if (daNote.strumTime < songLength - Conductor.safeZoneOffset)
				{
					health -= 0.05 * healthLoss;
				}
			}

			if (doDeathCheck())
			{
				return;
			}
		}
		FlxTween.tween(timeBar, {alpha: 0}, .1, {ease: FlxEase.circOut});
		FlxTween.tween(timeBarBG, {alpha: 0}, .1, {ease: FlxEase.circOut});

		canPause = false;
		endingSong = true;
		camZooming = false;
		inCutscene = false;
		updateTime = false;

		popUpComboScore(true, true);
		// FlxG.save.data.classicHealthBar != null ? classicHealthBar = FlxG.save.data.classicHealthBar : classicHealthBar = false;
		classicHealthBar = false;

		deathCounter = 0;
		seenCutscene = false;

		var ret:Dynamic = (callOnLuas('onEndSong', [], false) || callOnHscript('onEndSong', [], false));

		if (ret != FunkinLua.Function_Stop && !transitioning)
		{
			call("onEndSong", []);
			callOnHscript("onEndSong", []);
			stageBuild.callFunction('onEndSong', []);

			if (SONG.validScore)
			{
				#if !switch
				var percent:Float = ratingPercent;
				if (Math.isNaN(percent))
					percent = 0;
				Highscore.saveScore(SONG.song, songScore, storyDifficulty, percent);
				#end
			}

			playbackRate = 1;

			if (chartingMode)
			{
				openChartEditor();
				return;
			}

			if (isStoryMode)
			{
				campaignScore += songScore;
				campaignMisses += songMisses;

				storyPlaylist.remove(storyPlaylist[0]);

				if (storyPlaylist.length <= 0)
				{
					FlxG.sound.playMusic(Paths.music('freakyMenu'));
					TitleState.titleJSON = TitleState.getTitleData();
					Conductor.changeBPM(TitleState.titleJSON.bpm);

					cancelMusicFadeTween();
					/*CustomFadeTransition.nextCamera = camOther;
					if (FlxTransitionableState.skipNextTransIn)
					{
						CustomFadeTransition.nextCamera = null;
					}*/
					MusicBeatState.switchState(new StoryMenuState());

					if (!ClientPrefs.getGameplaySetting('practice', false) && !ClientPrefs.getGameplaySetting('botplay', false))
					{
						StoryMenuState.weekCompleted.set(WeekData.weeksList[storyWeek], true);

						if (SONG.validScore)
						{
							Highscore.saveWeekScore(WeekData.getWeekFileName(), campaignScore, storyDifficulty);
						}

						FlxG.save.data.weekCompleted = StoryMenuState.weekCompleted;
						FlxG.save.flush();
					}
					changedDifficulty = false;
					WeekData.loadTheFirstEnabledMod();
				}
				else
				{
					var difficulty:String = Utils.getDifficultyFilePath();

					trace('LOADING NEXT SONG');
					trace(Paths.formatToSongPath(PlayState.storyPlaylist[0]) + difficulty);

					FlxTransitionableState.skipNextTransIn = true;
					FlxTransitionableState.skipNextTransOut = true;

					prevCamFollow = camFollow;
					prevCamFollowPos = camFollowPos;

					PlayState.SONG = Song.loadFromJson(PlayState.storyPlaylist[0] + difficulty, PlayState.storyPlaylist[0]);
					FlxG.sound.music.stop();

					LoadingState.loadAndSwitchState(new PlayState());
				}
			}
			else
			{
				trace('Switching back to FreeplayState');
				cancelMusicFadeTween();
				/*CustomFadeTransition.nextCamera = camOther;
				if (FlxTransitionableState.skipNextTransIn)
				{
					CustomFadeTransition.nextCamera = null;
				}*/
				MusicBeatState.switchState(new FreeplayState());
				FlxG.sound.playMusic(Paths.music('freakyMenu'));
				TitleState.titleJSON = TitleState.getTitleData();
				Conductor.changeBPM(TitleState.titleJSON.bpm);
				changedDifficulty = false;
				WeekData.loadTheFirstEnabledMod();
			}
			transitioning = true;
		}
	}

	public function KillNotes()
	{
		while (notes.length > 0)
		{
			var daNote:Note = notes.members[0];
			daNote.active = false;
			daNote.visible = false;

			if (modchartObjects.exists('note${daNote.ID}'))
				modchartObjects.remove('note${daNote.ID}');
			daNote.kill();
			notes.remove(daNote, true);
			daNote.destroy();
		}
		unspawnNotes = [];
		eventNotes = [];
	}

	public var totalPlayed:Int = 0;
	public var totalNotesHit:Float = 0.0;

	private function cacheCombo()
	{
		Paths.image(comboPath + "AMnotecombo");
		Paths.image(comboPath + "AMnotecombo_numbers");
	}

	private function cachePopUpScore()
	{
		var pixelShitPart1:String = '';
		var pixelShitPart2:String = '';
		if (isPixelStage)
		{
			pixelShitPart1 = 'pixelUI/';
			pixelShitPart2 = '-pixel';
		}

		Paths.image(ratingsSubPath + pixelShitPart1 + "sick" + pixelShitPart2);
		Paths.image(ratingsSubPath + pixelShitPart1 + "good" + pixelShitPart2);
		Paths.image(ratingsSubPath + pixelShitPart1 + "bad" + pixelShitPart2);
		Paths.image(ratingsSubPath + pixelShitPart1 + "shit" + pixelShitPart2);
		Paths.image(ratingsSubPath + pixelShitPart1 + "combo" + pixelShitPart2);

		for (i in 0...10)
		{
			Paths.image(ratingsSubPath + pixelShitPart1 + 'num' + i + pixelShitPart2);
		}
	}

	public var animatedNumsScale:Float = 0.7;

	private function popUpScore(note:Note = null):Void
	{
		var noteDiff:Float = Math.abs(note.strumTime - Conductor.songPosition + ClientPrefs.ratingOffset);
		allNotesMs += noteDiff;
		averageMs = allNotesMs / songHits;

		vocals.volume = 1;
		var placement:String = Std.string(combo);

		var coolText:FlxText = new FlxText(0, 0, 0, placement, 32);
		coolText.screenCenter();
		coolText.x = FlxG.width * 0.35;

		coolText.x += ratingsCameraOffset[0];
		coolText.y += ratingsCameraOffset[1];

		var rating:FlxSprite = new FlxSprite();
		var score:Float = 350;

		// tryna do MS based judgment due to popular demand
		var daRating:Rating = Conductor.judgeNote(note, noteDiff / playbackRate);
		var ratingNum:Int = 0;

		totalNotesHit += daRating.ratingMod;
		note.ratingMod = daRating.ratingMod;

		score *= daRating.ratingMod;
		if (!note.ratingDisabled)
			daRating.increase();
		note.rating = daRating.name;

		if (daRating.noteSplash && !note.noteSplashDisabled)
			spawnNoteSplashOnNote(note);

		if (!practiceMode && !cpuControlled)
		{
			songScore += Math.ceil(score);
			comboScore += Math.ceil(score);
			if (!note.ratingDisabled)
			{
				songHits++;
				totalPlayed++;
				RecalculateRating(false);
			}
		}

		var pixelShitPart1:String = "";
		var pixelShitPart2:String = '';

		if (PlayState.isPixelStage)
		{
			pixelShitPart1 = 'pixelUI/';
			pixelShitPart2 = '-pixel';
		}

		var seperatedScore:Array<Int> = [];

		if (combo >= 1000)
			seperatedScore.push(Math.floor(combo / 1000) % 10);

		seperatedScore.push(Math.floor(combo / 100) % 10);
		seperatedScore.push(Math.floor(combo / 10) % 10);
		seperatedScore.push(combo % 10);

		var daLoop:Int = 0;
		for (i in seperatedScore)
		{
			var numScore:FlxSprite = new FlxSprite();

			var numSpriteType = 'default';
			#if MODS_ALLOWED
			var modXmlToFind:String = Paths.modsXml(ratingsSubPath + pixelShitPart1 + 'num' + Std.int(i) + pixelShitPart2);
			var xmlToFind:String = Paths.getPath('images/' + ratingsSubPath + pixelShitPart1 + 'num' + Std.int(i) + pixelShitPart2 + '.xml', TEXT);
			if (FileSystem.exists(modXmlToFind) || FileSystem.exists(xmlToFind) || Assets.exists(xmlToFind))
			#else
			if (Assets.exists(Paths.getPath('images/' + ratingsSubPath + pixelShitPart1 + 'num' + Std.int(i) + pixelShitPart2 + '.xml', TEXT)))
			#end
			{
				numSpriteType = "animated";
			}

			switch (numSpriteType)
			{
				case 'default':
					numScore.loadGraphic(Paths.image(ratingsSubPath + pixelShitPart1 + 'num' + Std.int(i) + pixelShitPart2));
				case 'animated':
					numScore.frames = Paths.getSparrowAtlas(ratingsSubPath + pixelShitPart1 + 'num' + Std.int(i) + pixelShitPart2);
					numScore.animation.addByPrefix('num', 'num', 24, true);
					numScore.animation.play('num', true);
			}

			// numScore.cameras = [camHUD];
			numScore.screenCenter();
			numScore.x = coolText.x + (43 * daLoop) - 90;
			numScore.y += 80;
			numScore.y += ratingsCameraOffset[1];

			numScore.x += ClientPrefs.comboOffset[2];
			numScore.y -= ClientPrefs.comboOffset[3];

			if (!ClientPrefs.comboStacking)
				lastScore.push(numScore);

			// if (!PlayState.isPixelStage) numScore.antialiasing = ClientPrefs.globalAntialiasing;

			numScore.antialiasing = (ClientPrefs.globalAntialiasing && !PlayState.isPixelStage);

			if (numSpriteType != 'animated')
			{
				if (!PlayState.isPixelStage)
					numScore.setGraphicSize(Std.int(numScore.width * (52 / numScore.width)));
				else
					numScore.setGraphicSize(Std.int(numScore.width * daPixelZoom));
			}
			else
				numScore.scale.set(animatedNumsScale, animatedNumsScale);

			numScore.updateHitbox();

			numScore.acceleration.y = FlxG.random.int(200, 300) * playbackRate * playbackRate;
			numScore.velocity.y -= FlxG.random.int(140, 160) * playbackRate;
			numScore.velocity.x = FlxG.random.float(-5, 5) * playbackRate;
			numScore.angle = FlxG.random.int(-3, 3);
			numScore.visible = (!ClientPrefs.hideHud && showRating);

			insert(members.indexOf(strumLineNotes) - 1, numScore);

			FlxTween.tween(numScore, {"scale.x": 0.2, "scale.y": 0.2, angle: FlxG.random.int(-20, 20)}, 0.15 / playbackRate, {
				startDelay: (0.05 + Conductor.crochet * 0.001) / playbackRate
			});
			FlxTween.tween(numScore, {alpha: 0}, 0.2 / playbackRate, {
				onComplete: function(tween:FlxTween)
				{
					remove(numScore, true);
					numScore.destroy();
				},
				startDelay: Conductor.crochet * 0.001 / playbackRate
			});

			daLoop++;
		}

		var ratingSpriteType = 'default';
		#if MODS_ALLOWED
		var modXmlToFind:String = Paths.modsXml(ratingsSubPath + pixelShitPart1 + daRating.image + pixelShitPart2);
		var xmlToFind:String = Paths.getPath('images/' + ratingsSubPath + pixelShitPart1 + daRating.image + pixelShitPart2 + '.xml', TEXT);
		if (FileSystem.exists(modXmlToFind) || FileSystem.exists(xmlToFind) || Assets.exists(xmlToFind))
		#else
		if (Assets.exists(Paths.getPath('images/' + ratingsSubPath + pixelShitPart1 + daRating.image + pixelShitPart2 + '.xml', TEXT)))
		#end
		{
			ratingSpriteType = "animated";
		}

		switch (ratingSpriteType)
		{
			case 'default':
				rating.loadGraphic(Paths.image(ratingsSubPath + pixelShitPart1 + daRating.image + pixelShitPart2));
			case 'animated':
				rating.frames = Paths.getSparrowAtlas(ratingsSubPath + pixelShitPart1 + daRating.image + pixelShitPart2);
				rating.animation.addByPrefix('rating', 'rating', 24, true);
				rating.animation.play('rating', true);
		}

		// rating.cameras = [camHUD];
		rating.screenCenter();
		rating.x = coolText.x - 40;
		rating.y -= 60;
		rating.acceleration.y = 550 * playbackRate * playbackRate;
		rating.velocity.y -= FlxG.random.int(140, 175) * playbackRate;
		rating.velocity.x -= FlxG.random.int(0, 10) * playbackRate;
		rating.visible = (!ClientPrefs.hideHud && showRating);
		rating.x += ClientPrefs.comboOffset[0];
		rating.y -= ClientPrefs.comboOffset[1];
		rating.angle = FlxG.random.int(-5, 5);
		rating.y += ratingsCameraOffset[1];

		var comboSpr:FlxSprite = new FlxSprite();
		var comboSpriteType = 'default';
		#if MODS_ALLOWED
		var modXmlToFind:String = Paths.modsXml(ratingsSubPath + pixelShitPart1 + 'combo' + pixelShitPart2);
		var xmlToFind:String = Paths.getPath('images/' + ratingsSubPath + pixelShitPart1 + 'combo' + pixelShitPart2 + '.xml', TEXT);
		if (FileSystem.exists(modXmlToFind) || FileSystem.exists(xmlToFind) || Assets.exists(xmlToFind))
		#else
		if (Assets.exists(Paths.getPath('images/' + ratingsSubPath + pixelShitPart1 + 'combo' + pixelShitPart2 + '.xml', TEXT)))
		#end
		{
			comboSpriteType = "animated";
		}
		switch (comboSpriteType)
		{
			case 'default':
				comboSpr.loadGraphic(Paths.image(ratingsSubPath + pixelShitPart1 + 'combo' + pixelShitPart2));
			case 'animated':
				comboSpr.frames = Paths.getSparrowAtlas(ratingsSubPath + pixelShitPart1 + 'combo' + pixelShitPart2);
				comboSpr.animation.addByPrefix('combo', 'combo', 24, true);
				comboSpr.animation.play('combo', true);
		}
		// comboSpr.cameras = [camHUD];
		comboSpr.screenCenter();
		comboSpr.x = coolText.x;
		comboSpr.acceleration.y = FlxG.random.int(200, 300) * playbackRate * playbackRate;
		comboSpr.velocity.y -= FlxG.random.int(140, 160) * playbackRate;
		comboSpr.velocity.x += FlxG.random.int(1, 10) * playbackRate;
		comboSpr.visible = (!ClientPrefs.hideHud && showRating);
		comboSpr.x += ClientPrefs.comboOffset[0] + 50;
		comboSpr.y -= ClientPrefs.comboOffset[1];
		comboSpr.y += 50;
		comboSpr.angle = FlxG.random.int(-2, 2);
		comboSpr.y += ratingsCameraOffset[1];

		if (combo >= 65)
			insert(members.indexOf(strumLineNotes) - 1, comboSpr);

		comboSpr.velocity.x += FlxG.random.float(-5, 5);
		insert(members.indexOf(strumLineNotes) - 1, rating);

		if (!ClientPrefs.comboStacking)
		{
			if (lastRating != null)
				lastRating.kill();
			lastRating = rating;
		}

		if (!PlayState.isPixelStage)
		{
			rating.setGraphicSize(Std.int(rating.width * 0.7));
			rating.antialiasing = ClientPrefs.globalAntialiasing;
			comboSpr.setGraphicSize(Std.int(comboSpr.width * 0.6));
			comboSpr.antialiasing = ClientPrefs.globalAntialiasing;
		}
		else
		{
			rating.setGraphicSize(Std.int(rating.width * daPixelZoom * 0.85));
			comboSpr.setGraphicSize(Std.int(comboSpr.width * daPixelZoom * 0.75));
		}

		comboSpr.updateHitbox();
		rating.updateHitbox();

		if (!ClientPrefs.comboStacking)
		{
			if (lastCombo != null)
				lastCombo.kill();
			lastCombo = comboSpr;
		}
		if (lastScore != null)
		{
			while (lastScore.length > 0)
			{
				lastScore[0].kill();
				lastScore.remove(lastScore[0]);
			}
		}

		coolText.text = Std.string(seperatedScore);
		// add(coolText);

		FlxTween.tween(rating, {alpha: 0}, 0.2 / playbackRate, {
			startDelay: Conductor.crochet * 0.001 / playbackRate
		});
		FlxTween.tween(rating, {"scale.x": 0.5, "scale.y": 0.5, angle: FlxG.random.int(-30, 30)}, 0.15 / playbackRate, {
			startDelay: (0.05 + Conductor.crochet * 0.001) / playbackRate
		});

		FlxTween.tween(comboSpr, {"scale.x": 0.5, "scale.y": 0.5, angle: FlxG.random.int(-8, 8)}, 0.15 / playbackRate, {
			startDelay: (0.05 + Conductor.crochet * 0.001) / playbackRate
		});

		FlxTween.tween(comboSpr, {"scale.x": 0.6, "scale.y": 0.6, alpha: 0}, 0.2 / playbackRate, {
			onComplete: function(tween:FlxTween)
			{
				coolText.destroy();

				remove(comboSpr, true);
				comboSpr.destroy();
				remove(rating, true);
				rating.destroy();
			},
			startDelay: Conductor.crochet * 0.001 / playbackRate
		});
	}

	public var strumsBlocked:Array<Bool> = [];

	private function onKeyPress(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(eventKey);

		if (!canShitButtons)
			return; // nuh uh

		if (!ClientPrefs.controllerMode && FlxG.keys.checkStatus(eventKey, JUST_PRESSED))
			keyPressed(key);
	}

	private function keyPressed(key:Int)
	{
		if (!cpuControlled && startedCountdown && !paused && key > -1)
		{
			if (notes.length > 0 && !boyfriend.stunned && generatedMusic && !endingSong)
			{
				// more accurate hit time for the ratings?
				var lastTime:Float = Conductor.songPosition;
				if (Conductor.songPosition >= 0)
					Conductor.songPosition = FlxG.sound.music.time;

				var canMiss:Bool = !ClientPrefs.ghostTapping;

				// heavily based on my own code LOL if it aint broke dont fix it
				var pressNotes:Array<Note> = [];
				var notesStopped:Bool = false;
				var sortedNotesList:Array<Note> = [];
				notes.forEachAlive(function(daNote:Note)
				{
					if (strumsBlocked[daNote.noteData] != true
						&& daNote.canBeHit
						&& daNote.mustPress
						&& !daNote.tooLate
						&& !daNote.wasGoodHit
						&& !daNote.isSustainNote
						&& !daNote.blockHit)
					{
						if (daNote.noteData == key)
							sortedNotesList.push(daNote);
						canMiss = true;
					}
				});
				sortedNotesList.sort(sortHitNotes);

				if (sortedNotesList.length > 0)
				{
					for (epicNote in sortedNotesList)
					{
						for (doubleNote in pressNotes)
						{
							if (Math.abs(doubleNote.strumTime - epicNote.strumTime) < 1)
							{
								doubleNote.kill();
								notes.remove(doubleNote, true);
								doubleNote.destroy();
							}
							else
								notesStopped = true;
						}

						// eee jack detection before was not super good
						if (!notesStopped)
						{
							goodNoteHit(epicNote);
							pressNotes.push(epicNote);
						}
					}
				}
				else
				{
					call('onGhostTap', [key]);
					callOnLuas('onGhostTap', [key]);
					callOnHscript("onGhostTap", [key]);
					stageBuild.callFunction('onGhostTap', [key]);
					if (canMiss && !boyfriend.stunned)
						noteMissPress(key);
				}
				Conductor.songPosition = lastTime;
			}

			var spr:StrumNote = playerStrums.members[key];
			if (strumsBlocked[key] != true && spr != null && spr.animation.curAnim.name != 'confirm')
			{
				spr.playAnim('pressed');
				spr.resetAnim = 0;
			}
			call('onKeyPress', [key]);
			callOnLuas('onKeyPress', [key]);
			callOnHscript("onKeyPress", [key]);
			stageBuild.callFunction('onKeyPress', [key]);
		}
	}

	public static function sortHitNotes(a:Note, b:Note):Int
	{
		if (a.lowPriority && !b.lowPriority)
			return 1;
		else if (!a.lowPriority && b.lowPriority)
			return -1;

		return FlxSort.byValues(FlxSort.ASCENDING, a.strumTime, b.strumTime);
	}

	private function onKeyRelease(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(eventKey);
		// trace('Pressed: ' + eventKey);

		if (!ClientPrefs.controllerMode && key > -1)
			keyReleased(key);
	}

	private function keyReleased(key:Int)
	{
		if (!cpuControlled && startedCountdown && !paused)
		{
			var spr:StrumNote = playerStrums.members[key];
			if (spr != null)
			{
				spr.playAnim('static');
				spr.resetAnim = 0;
			}
			call('onKeyRelease', [key]);
			callOnLuas('onKeyRelease', [key]);
			callOnHscript("onKeyRelease", [key]);
			stageBuild.callFunction('onKeyRelease', [key]);
		}
	}

	public function getKeyFromEvent(key:FlxKey):Int
	{
		if (key != NONE)
			for (i in 0...keysArray.length)
			{
				for (j in 0...keysArray[i].length)
				{
					if (key == keysArray[i][j])
						return i;
				}
			}

		return -1;
	}

	private function keysCheck():Void
	{
		if (!canShitButtons)
			return;

		// HOLDING
		var parsedHoldArray:Array<Bool> = parseKeys();

		if (ClientPrefs.controllerMode)
		{
			var parsedArray:Array<Bool> = parseKeys('_P');
			if (parsedArray.contains(true))
			{
				for (i in 0...parsedArray.length)
				{
					if (parsedArray[i] && strumsBlocked[i] != true)
						onKeyPress(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, -1, keysArray[i][0]));
				}
			}
		}

		if (startedCountdown && !boyfriend.stunned && generatedMusic)
		{
			// rewritten inputs???
			notes.forEachAlive(function(daNote:Note)
			{
				// hold note functions
				if (strumsBlocked[daNote.noteData] != true
					&& daNote.isSustainNote
					&& parsedHoldArray[daNote.noteData]
					&& daNote.canBeHit
					&& daNote.mustPress
					&& !daNote.tooLate
					&& !daNote.wasGoodHit
					&& !daNote.blockHit)
				{
					goodNoteHit(daNote);
				}
			});
			/*if (parsedHoldArray.contains(true) && !endingSong) { }
			else */
			if (boyfriend.animation.curAnim != null
				&& boyfriend.holdTimer > Conductor.stepCrochet * (0.0011 / FlxG.sound.music.pitch) * boyfriend.singDuration
					&& boyfriend.animation.curAnim.name.startsWith(boyfriend.singAnimsPrefix)
					&& !boyfriend.animation.curAnim.name.endsWith('miss'))
			{
				boyfriend.dance();
			}
		}

		if (ClientPrefs.controllerMode || strumsBlocked.contains(true))
		{
			var parsedArray:Array<Bool> = parseKeys('_R');
			if (parsedArray.contains(true))
			{
				for (i in 0...parsedArray.length)
				{
					if (parsedArray[i] || strumsBlocked[i] == true)
						onKeyRelease(new KeyboardEvent(KeyboardEvent.KEY_UP, true, true, -1, keysArray[i][0]));
				}
			}
		}
	}

	private function parseKeys(?suffix:String = ''):Array<Bool>
	{
		var ret:Array<Bool> = [];
		for (i in 0...controlArray.length)
		{
			ret[i] = Reflect.getProperty(controls, controlArray[i] + suffix);
		}
		return ret;
	}

	function noteMiss(daNote:Note):Void
	{ // You didn't hit the key and let it go offscreen, also used by Hurt Notes
		notes.forEachAlive(function(note:Note)
		{
			if (daNote != note
				&& daNote.mustPress
				&& daNote.noteData == note.noteData
				&& daNote.isSustainNote == note.isSustainNote
				&& Math.abs(daNote.strumTime - note.strumTime) < 1)
			{
				if (modchartObjects.exists('note${note.ID}'))
					modchartObjects.remove('note${note.ID}');
				note.kill();
				notes.remove(note, true);
				note.destroy();
			}
		});
		combo = 0;

		health -= daNote.missHealth * healthLoss;
		if (instakillOnMiss)
		{
			vocals.volume = 0;
			doDeathCheck(true);
		}

		songMisses++;
		healthBarShake(0.45);
		if (ClientPrefs.playMissSounds)
		{
			FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), 0.07);
			vocals.volume = 0;
		}
		if (!practiceMode)
			songScore -= 10;

		totalPlayed++;
		RecalculateRating(true);

		popUpComboScore(true);

		var char:Character = boyfriend;
		if (daNote.gfNote)
		{
			char = gf;
		}

		// if(ClientPrefs.playMissAnims)
		if (char != null && !daNote.noMissAnimation && char.hasMissAnimations)
		{
			var daAlt = '';
			if (daNote.noteType == 'Alt Animation')
				daAlt = '-alt';

			var animToPlay:String = singAnimations[daNote.noteData] + 'miss' + daAlt;
			char.playAnim(char.singAnimsPrefix + animToPlay, true);
		}

		if (camFocus != 'dad' && ClientPrefs.shouldCameraMove && (!daNote.noAnimation || daNote.specialNote))
			triggerCamMovement(daNote.noteData);

		call('noteMiss', [
			notes.members.indexOf(daNote),
			daNote.noteData,
			daNote.noteType,
			daNote.isSustainNote,
			daNote.ID
		]);
		callOnLuas('noteMiss', [
			notes.members.indexOf(daNote),
			daNote.noteData,
			daNote.noteType,
			daNote.isSustainNote,
			daNote.ID
		]);
		callOnHscript("noteMiss", [
			notes.members.indexOf(daNote),
			daNote.noteData,
			daNote.noteType,
			daNote.isSustainNote,
			daNote.ID
		]);
		stageBuild.callFunction('noteMiss', [
			notes.members.indexOf(daNote),
			daNote.noteData,
			daNote.noteType,
			daNote.isSustainNote,
			daNote.ID
		]);
	}

	function noteMissPress(direction:Int = 1):Void // You pressed a key when there was no notes to press for this key
	{
		if (ClientPrefs.ghostTapping)
			return; // fuck it

		if (!boyfriend.stunned)
		{
			health -= 0.05 * healthLoss;
			if (instakillOnMiss)
			{
				vocals.volume = 0;
				doDeathCheck(true);
			}

			if (combo > 10 && gf != null && gf.animOffsets.exists('sad'))
			{
				gf.playAnim('sad', true);
				gf.specialAnim = true;
			}

			if (combo > 10 && dad != null && dad.animOffsets.exists('mockery'))
			{
				dad.playAnim('mockery', true);
				dad.specialAnim = true;
			}
			combo = 0;

			if (!practiceMode)
				songScore -= 10;

			popUpComboScore(true);

			if (!endingSong)
				songMisses++;

			totalPlayed++;
			RecalculateRating(true);
			healthBarShake(0.35);
			if (ClientPrefs.playMissSounds)
				FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.3, 0.4));

			if (/*ClientPrefs.playMissAnims &&*/ boyfriend.hasMissAnimations)
				boyfriend.playAnim(boyfriend.singAnimsPrefix + singAnimations[Std.int(Math.abs(direction))] + 'miss', true);

			if (ClientPrefs.playMissSounds)
				vocals.volume = 0;
		}
		call("noteMissPress", [direction]);
		callOnLuas('noteMissPress', [direction]);
		callOnHscript("noteMissPress", [direction]);
		stageBuild.callFunction('noteMissPress', [direction]);
	}

	private function opponentNoteHit(note:Note):Void
	{
		var healthDrain:Float = ClientPrefs.getGameplaySetting('healthdrainpercent', 0);

		if (!note.isSustainNote && FlxG.random.bool(50) && opponentSplash)
			spawnNoteSplashOnNote(note, 'dad');

		if (note.noteType == 'Hey!' && dad.animOffsets.exists('hey'))
		{
			dad.playAnim('hey', true);
			dad.specialAnim = true;
			dad.heyTimer = 0.6;
		}
		else if (!note.noAnimation)
		{
			var altAnim:String = "";

			if (SONG.notes[curSection] != null)
			{
				if (SONG.notes[curSection].altAnim || note.noteType == 'Alt Animation')
				{
					altAnim = '-alt';
				}
			}

			var char:Character = dad;
			var animToPlay:String = singAnimations[note.noteData] + altAnim;
			if (note.gfNote)
			{
				if (gf != null)
				{
					char = gf;
				}
			}

			if (healthDrain > 0 && health > healthDrain / 10 + 0.1) // Oh yeah, its HealthDrain - PurSnake
				health -= healthDrain / 10;

			if (char != null)
			{
				char.playAnim(char.singAnimsPrefix + animToPlay, true);
				char.holdTimer = 0;
			}
		}

		if (camFocus != 'bf' && ClientPrefs.shouldCameraMove && (!note.noAnimation || note.specialNote))
			triggerCamMovement(note.noteData);

		if (SONG.needsVoices)
		{
			vocals.volume = 1;
			if (vocals2.length > 1)
				vocals2.volume = 1;
		}

		StrumPlayAnim(true, Std.int(Math.abs(note.noteData)), Conductor.stepCrochet * 1.25 / 1000 / playbackRate,
			(note.isSustainNote && !note.animation.curAnim.name.endsWith('end')));
		note.hitByOpponent = true;

		call('opponentNoteHit', [
			notes.members.indexOf(note),
			note.noteData,
			note.noteType,
			note.isSustainNote,
			note.ID
		]);
		callOnLuas('opponentNoteHit', [
			notes.members.indexOf(note),
			note.noteData,
			note.noteType,
			note.isSustainNote,
			note.ID
		]);
		callOnHscript("opponentNoteHit", [note, note.noteData, note.noteType, note.isSustainNote, note.ID]);
		stageBuild.callFunction('opponentNoteHit', [
			notes.members.indexOf(note),
			note.noteData,
			note.noteType,
			note.isSustainNote,
			note.ID
		]);

		if (!note.isSustainNote)
		{
			if (modchartObjects.exists('note${note.ID}'))
				modchartObjects.remove('note${note.ID}');
			note.kill();
			notes.remove(note, true);
			note.destroy();
		}
	}

	function goodNoteHit(note:Note):Void
	{
		if (!note.wasGoodHit)
		{
			if (cpuControlled && (note.ignoreNote || note.hitCausesMiss))
				return;
			if (note.hitCausesMiss)
			{
				noteMiss(note);
				if (!note.noteSplashDisabled && !note.isSustainNote)
				{
					spawnNoteSplashOnNote(note);
				}
				if (!note.noMissAnimation)
				{
					switch (note.noteType)
					{
						case 'Hurt Note': // Hurt note
							if (boyfriend.animation.getByName('hurt') != null)
							{
								boyfriend.playAnim('hurt', true);
								boyfriend.specialAnim = true;
							}
					}
				}

				note.wasGoodHit = true;
				if (!note.isSustainNote)
				{
					if (modchartObjects.exists('note${note.ID}'))
						modchartObjects.remove('note${note.ID}');
					note.kill();
					notes.remove(note, true);
					note.destroy();
				}
				return;
			}
			if (!note.isSustainNote)
			{
				if (combo >= maxCombo)
					maxCombo += 1;
				combo += 1;
				popUpScore(note);
				if (combo > 9999)
					combo = 9999;
				comboNum++;
			}

			var noteDiff:Float = Math.abs(note.strumTime - Conductor.songPosition + ClientPrefs.ratingOffset);
			var daRating:Rating = Conductor.judgeNote(note, noteDiff / playbackRate);
			health += note.hitHealth * healthGain * daRating.ratingMod;

			if (!note.noAnimation)
			{
				var daAlt = '';
				if (note.noteType == 'Alt Animation')
					daAlt = '-alt';

				var animToPlay:String = singAnimations[note.noteData];
				if (note.gfNote)
				{
					if (gf != null)
					{
						gf.playAnim(gf.singAnimsPrefix + animToPlay + daAlt, true);
						gf.holdTimer = 0;
					}
				}
				else
				{
					boyfriend.playAnim(boyfriend.singAnimsPrefix + animToPlay + daAlt, true);
					boyfriend.holdTimer = 0;
				}
			}
			if (note.noteType == 'Hey!')
			{
				if (boyfriend.animOffsets.exists('hey'))
				{
					boyfriend.playAnim('hey', true);
					boyfriend.specialAnim = true;
					boyfriend.heyTimer = 0.6;
				}

				if (gf != null && gf.animOffsets.exists('cheer'))
				{
					gf.playAnim('cheer', true);
					gf.specialAnim = true;
					gf.heyTimer = 0.6;
				}
			}
		}
		note.wasGoodHit = true;
		vocals.volume = 1;
		var isSus:Bool = note.isSustainNote; // GET OUT OF MY HEAD, GET OUT OF MY HEAD, GET OUT OF MY HEAD
		var leData:Int = note.noteData;
		var leType:String = note.noteType;
		if (camFocus != 'dad' && ClientPrefs.shouldCameraMove && (!note.noAnimation || note.specialNote))
			triggerCamMovement(note.noteData);

		if (cpuControlled)
		{
			StrumPlayAnim(false, leData, Conductor.stepCrochet * 1.25 / 1000 / playbackRate, (isSus
				&& !note.animation.curAnim.name.endsWith('end')));
		}
		else
		{
			StrumPlayAnim(false, leData, Conductor.stepCrochet * 2 / 1000 / playbackRate, (isSus
				&& !note.animation.curAnim.name.endsWith('end')));
		}
		call('goodNoteHit', [notes.members.indexOf(note), leData, leType, isSus, note.ID]);
		callOnLuas('goodNoteHit', [notes.members.indexOf(note), leData, leType, isSus, note.ID]);
		callOnHscript("goodNoteHit", [notes.members.indexOf(note), leData, leType, isSus, note.ID]);
		stageBuild.callFunction('goodNoteHit', [notes.members.indexOf(note), leData, leType, isSus, note.ID]);
		if (!note.isSustainNote)
		{
			if (note.neededHitsounds && ClientPrefs.hsvol > 0 && !cpuControlled)
				FlxG.sound.play(Paths.sound('note_click'), ClientPrefs.hsvol); // it must be HERE - PurSnake
			if (modchartObjects.exists('note${note.ID}'))
				modchartObjects.remove('note${note.ID}');
			note.kill();
			notes.remove(note, true);
			note.destroy();
		}
	}

	public function popUpComboScore(?miss:Bool = false, ?forced:Bool = false)
	{
		if (!miss)
			spawnComboSprites(comboNum);

		if (forced || !miss)
		{
			var bonusScore:Int = Math.round(comboNum * (comboScore / 150));
			songScore += Math.round(bonusScore - (comboScore / 150));
		}

		comboScore = 0;
		comboNum = 0;
		updateScore(miss, forced);
	}

	var numbersHaha = ['zero', 'one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight', 'nine'];

	function spawnComboSprites(comboCol:Int)
	{
		if (comboCol < 7)
			return;
		var comboSprite:FlxSprite = new FlxSprite();
		comboSprite.frames = Paths.getSparrowAtlas(comboPath + 'AMnotecombo');
		if (comboSprite.frames != null)
		{
			comboSprite.animation.addByPrefix('anim', "note combo", 14, false);
			comboSprite.updateHitbox();
			comboSprite.scale.set(0.62, 0.62);
			comboSprite.offset.set(-75, -75);
			comboSprite.antialiasing = ClientPrefs.globalAntialiasing;
			comboSprite.alpha = 0.9;
			// comboSprite.cameras = [camHUD];
			comboSprite.animation.play('anim', true);
			comboSprite.scrollFactor.set(0.45, 0.45);
			comboSprite.visible = false;
			insert(members.indexOf(strumLineNotes), comboSprite);
		}

		var seperatedScore:Array<Int> = [];

		if (comboCol >= 1000)
			seperatedScore.push(Math.floor(comboCol / 1000) % 10);
		if (comboCol >= 100)
			seperatedScore.push(Math.floor(comboCol / 100) % 10);
		if (comboCol >= 10)
			seperatedScore.push(Math.floor(comboCol / 10) % 10);

		seperatedScore.push(comboCol % 10);

		var daLoop:Int = 0;
		for (i in seperatedScore)
		{
			var funnyNum:FlxSprite = new FlxSprite();
			funnyNum.frames = Paths.getSparrowAtlas(comboPath + 'AMnotecombo_numbers');
			if (funnyNum.frames != null)
			{
				funnyNum.animation.addByPrefix('anim', 'combo ' + numbersHaha[Std.int(i)], 12, false);
				funnyNum.updateHitbox();
				funnyNum.scale.set(0.62, 0.62);
				funnyNum.offset.set(-10, -10);
				funnyNum.scrollFactor.set(0.45, 0.45);
				funnyNum.antialiasing = ClientPrefs.globalAntialiasing;
				funnyNum.alpha = 0.9;
				// funnyNum.cameras = [camHUD];
				// add(funnyNum);
				insert(members.indexOf(comboSprite) + 1, funnyNum);
				funnyNum.animation.play('anim', true);
				funnyNum.visible = (true && !ClientPrefs.hideHud && showRating);
				funnyNum.screenCenter();
				funnyNum.x += 110 * 2;
				funnyNum.x -= 110 * seperatedScore.length - 1;
				funnyNum.x -= 152 - (110 * daLoop);
				funnyNum.y += 41 - (20 * daLoop);

				// funnyNum.x += 62;
				// funnyNum.y -= 31;
				funnyNum.x += ratingsCameraOffset[2];
				funnyNum.y += ratingsCameraOffset[3];
				modchartTweens.set('funnyNumTween' + i,
					FlxTween.tween(funnyNum, {x: funnyNum.x + 62, y: funnyNum.y - 31}, (funnyNum.animation.curAnim.frames.length - 3) / 12,
						{ease: FlxEase.quadOut}));
				funnyNum.animation.finishCallback = function(name)
				{
					funnyNum.kill();
					remove(funnyNum, true);
				}
			}

			daLoop++;
		}

		var addTimer:FlxTimer = new FlxTimer().start(Conductor.crochet / 8000 / playbackRate, function(tmr:FlxTimer)
		{
			if (comboSprite.frames != null)
			{
				comboSprite.visible = (true && !ClientPrefs.hideHud && showRating);
				comboSprite.screenCenter();
				comboSprite.x += ratingsCameraOffset[2];
				comboSprite.y += ratingsCameraOffset[3];
				comboSprite.x -= 62;
				comboSprite.y += 31;
				modchartTweens.set('comboSpriteTween',
					FlxTween.tween(comboSprite, {x: comboSprite.x + 62, y: comboSprite.y - 31}, (comboSprite.animation.curAnim.frames.length - 4) / 14,
						{ease: FlxEase.quadOut}));
				comboSprite.animation.finishCallback = function(name)
				{
					comboSprite.kill();
					remove(comboSprite, true);
				}
			}
		});
		modchartTimers.set('addingfunnyComboSprite', addTimer);
	}

	public function spawnNoteSplashOnNote(note:Note, ?char:String = 'bf')
	{
		if (char == 'dad' && !ClientPrefs.lightCpuStrums)
			return;

		if (ClientPrefs.noteSplashes && note != null)
		{
			var strum:StrumNote = playerStrums.members[note.noteData];
			if (char == 'dad')
				strum = opponentStrums.members[note.noteData];

			if (strum != null && strum.alpha > 0.4 && strum.visible)
				spawnNoteSplash(strum.getMidpoint().x, strum.getMidpoint().y, note.noteData, note);
		}
	}

	public function spawnNoteSplash(x:Float, y:Float, data:Int, ?note:Note = null)
	{
		if (PlayState.SONG.splashSkin != null && PlayState.SONG.splashSkin.length > 0)
			skin = PlayState.SONG.splashSkin;

		var hueValues:Dictionary<Int, Float> = new Dictionary<Int, Float>();
		var satValues:Dictionary<Int, Float> = new Dictionary<Int, Float>();
		var brtValues:Dictionary<Int, Float> = new Dictionary<Int, Float>();

		if (data > -1 && data < ClientPrefs.arrowHSV.length)
		{
			if (!hueValues.exists(data))
				hueValues[data] = ClientPrefs.arrowHSV[data][0] / 360;
			hue = hueValues[data];
			if (!satValues.exists(data))
				satValues[data] = ClientPrefs.arrowHSV[data][1] / 100;
			sat = satValues[data];
			if (!brtValues.exists(data))
				brtValues[data] = ClientPrefs.arrowHSV[data][2] / 100;
			brt = brtValues[data];
			if (note != null)
			{
				skin = note.noteSplashTexture;
				hue = note.noteSplashHue;
				sat = note.noteSplashSat;
				brt = note.noteSplashBrt;
			}
		}

		var splash:NoteSplash = grpNoteSplashes.recycle(NoteSplash);
		splash.setupNoteSplash(x, y, data, skin, hue, sat, brt);
		if (note != null)
		{
			splash.scrollFactor.set(note.scrollFactor.x, note.scrollFactor.y);
			splash.alpha *= note.alpha;
		}
		grpNoteSplashes.add(splash);
	}

	var fastCarCanDrive:Bool = true;

	function resetFastCar():Void
	{
		fastCar.x = -12600;
		fastCar.y = FlxG.random.int(140, 250);
		fastCar.velocity.x = 0;
		fastCarCanDrive = true;
	}

	var carTimer:FlxTimer;

	function fastCarDrive()
	{
		// trace('Car drive');
		FlxG.sound.play(Paths.soundRandom('carPass', 0, 1), 0.7);

		fastCar.velocity.x = (FlxG.random.int(170, 220) / FlxG.elapsed) * 3;
		fastCarCanDrive = false;
		carTimer = new FlxTimer().start(2, function(tmr:FlxTimer)
		{
			resetFastCar();
			carTimer = null;
		});
	}

	var trainMoving:Bool = false;
	var trainFrameTiming:Float = 0;
	var curLight:Int = -1;
	var curLightEvent:Int = -1;
	var trainCars:Int = 8;
	var trainFinishing:Bool = false;
	var trainCooldown:Int = 0;

	function trainStart():Void
	{
		trainMoving = true;
		if (!trainSound.playing)
			trainSound.play(true);
	}

	var startedMoving:Bool = false;

	function updateTrainPos():Void
	{
		if (trainSound.time >= 4700)
		{
			startedMoving = true;
			if (gf != null)
			{
				gf.playAnim('hairBlow');
				gf.specialAnim = true;
			}
		}

		if (startedMoving)
		{
			phillyTrain.x -= 400;

			if (phillyTrain.x < -2000 && !trainFinishing)
			{
				phillyTrain.x = -1150;
				trainCars -= 1;

				if (trainCars <= 0)
					trainFinishing = true;
			}

			if (phillyTrain.x < -4000 && trainFinishing)
				trainReset();
		}
	}

	function trainReset():Void
	{
		if (gf != null)
		{
			gf.danced = false; // Sets head to the correct position once the animation ends
			gf.playAnim('hairFall');
			gf.specialAnim = true;
		}
		phillyTrain.x = FlxG.width + 200;
		trainMoving = false;
		// trainSound.stop();
		// trainSound.time = 0;
		trainCars = 8;
		trainFinishing = false;
		startedMoving = false;
	}

	function lightningStrikeShit():Void
	{
		FlxG.sound.play(Paths.soundRandom('thunder_', 1, 2));
		if (!ClientPrefs.lowQuality)
			halloweenBG.animation.play('halloweem bg lightning strike');

		lightningStrikeBeat = curBeat;
		lightningOffset = FlxG.random.int(8, 24);

		if (boyfriend.animOffsets.exists('scared'))
		{
			boyfriend.playAnim('scared', true);
		}

		if (gf != null && gf.animOffsets.exists('scared'))
		{
			gf.playAnim('scared', true);
		}

		if (ClientPrefs.camZooms)
		{
			FlxG.camera.zoom += 0.015;
			camHUD.zoom += 0.03;

			if (!camZooming)
			{ // Just a way for preventing it to be permanently zoomed until Skid & Pump hits a note
				FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, 0.5);
				FlxTween.tween(camHUD, {zoom: 1}, 0.5);
			}
		}

		if (ClientPrefs.flashing)
		{
			halloweenWhite.alpha = 0.4;
			FlxTween.tween(halloweenWhite, {alpha: 0.5}, 0.075);
			FlxTween.tween(halloweenWhite, {alpha: 0}, 0.25, {startDelay: 0.15});
		}
	}

	function killHenchmen():Void
	{
		if (!ClientPrefs.lowQuality && ClientPrefs.violence && curStage == 'limo')
		{
			if (limoKillingState < 1)
			{
				limoMetalPole.x = -400;
				limoMetalPole.visible = true;
				limoLight.visible = true;
				limoCorpse.visible = false;
				limoCorpseTwo.visible = false;
				limoKillingState = 1;
			}
		}
	}

	function resetLimoKill():Void
	{
		if (curStage == 'limo')
		{
			limoMetalPole.x = -500;
			limoMetalPole.visible = false;
			limoLight.x = -500;
			limoLight.visible = false;
			limoCorpse.x = -500;
			limoCorpse.visible = false;
			limoCorpseTwo.x = -500;
			limoCorpseTwo.visible = false;
		}
	}

	var tankX:Float = 400;
	var tankSpeed:Float = FlxG.random.float(5, 7);
	var tankAngle:Float = FlxG.random.int(-90, 45);

	function moveTank(?elapsed:Float = 0):Void
	{
		if (!inCutscene)
		{
			tankAngle += elapsed * tankSpeed;
			tankGround.angle = tankAngle - 90 + 15;
			tankGround.x = tankX + 1500 * Math.cos(Math.PI / 180 * (1 * tankAngle + 180));
			tankGround.y = 1300 + 1100 * Math.sin(Math.PI / 180 * (1 * tankAngle + 180));
		}
	}

	override function destroy()
	{
		for (script in luaArray)
		{
			script.call('onDestroy', []);
			script.stop();
		}
		for (script in hscriptArray)
		{
			script.executeFunc('onDestroy', []);
			script.dispose();
		}
		luaArray = [];
		hscriptArray = [];
		#if hscript
		if (FunkinLua.hscript != null)
			FunkinLua.hscript = null;
		#end

		if (!ClientPrefs.controllerMode)
		{
			FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
			FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		}
		FlxG.animationTimeScale = 1;
		FlxG.sound.music.pitch = 1;
		FlxG.mouse.visible = true;
		FlxG.mouse.load(Paths.image("cursor").bitmap, 1, 0, 0);
		instance = null;
		super.destroy();
		FlxG.mouse.visible = true;
		FlxG.mouse.load(Paths.image("cursor").bitmap, 1, 0, 0);
	}

	public static function cancelMusicFadeTween()
	{
		if (FlxG.sound.music.fadeTween != null)
		{
			FlxG.sound.music.fadeTween.cancel();
		}
		FlxG.sound.music.fadeTween = null;
	}

	var lastStepHit:Int = -1;

	override function stepHit()
	{
		super.stepHit();
		if (Math.abs(FlxG.sound.music.time - (Conductor.songPosition - Conductor.offset)) > (20 * playbackRate)
			|| (SONG.needsVoices && Math.abs(vocals.time - (Conductor.songPosition - Conductor.offset)) > (20 * playbackRate))
			|| (vocals2.length > 1 && Math.abs(vocals2.time - (Conductor.songPosition - Conductor.offset)) > (20 * playbackRate)))
		{
			resyncVocals();
		}

		getCamOffsets();

		if (curStep == lastStepHit)
			return;

		lastStepHit = curStep;
		setOnLuas('curStep', curStep);
		callOnLuas('onStepHit', []);
		stageBuild.callFunction('onStepHit', [curStep]);
		callOnHscript("onStepHit", [curStep]);
	}

	var lastBeatHit:Int = -1;

	override function beatHit()
	{
		super.beatHit();

		if (lastBeatHit >= curBeat)
			return;

		if (generatedMusic)
			notes.sort(FlxSort.byY, ClientPrefs.downScroll ? FlxSort.ASCENDING : FlxSort.DESCENDING);

		if (iconsZoomingFreq > 0)
			if (curBeat % iconsZoomingFreq == 0)
				iconGroup.forEach(function(icon:HealthIcon)
				{
					icon.doScale();
					call("onIconsBeat", [curBeat]);
					callOnHscript("onIconsBeat", [curBeat]);
					stageBuild.callFunction('onIconsBeat', [curBeat]);
					callOnLuas('onIconsBeat', [curBeat]);
				});

		if (ClientPrefs.scoreZoom && curBeat % 2 == 1 && !ClientPrefs.classicScoreTxt)
		{
			scoreTxt.scale.set(1, 1);
			FlxTween.tween(scoreTxt.scale, {x: 1.15, y: 1.075}, 0.3, {ease: FlxEase.quadOut, type: BACKWARD});
		}

		for (character in characters)
		{
			if (character != null
				&& curBeat % Math.round(character.danceEveryNumBeats * (character == gf ? gfSpeed : 1)) == 0
				&& character.animation.curAnim != null
				&& !character.animation.curAnim.name.startsWith(character.singAnimsPrefix)
				&& !character.stunned)
			{
				character.dance();
			}
		}
		if (camZoomingFreq != 0 && camZoomingFreq != -1)
			if (camZooming && ClientPrefs.camZooms && curBeat % camZoomingFreq == camZoomingExVal)
			{
				FlxG.camera.zoom += 0.015 * camZoomingMult;
				camHUD.zoom += 0.03 * camZoomingMult;
			}

		switch (curStage)
		{
			case 'tank':
				if (!ClientPrefs.lowQuality)
					tankWatchtower.dance();
				foregroundSprites.forEach(function(spr:BGSprite)
				{
					spr.dance();
				});

			case 'school':
				if (!ClientPrefs.lowQuality)
				{
					bgGirls.dance();
				}

			case 'mall':
				if (!ClientPrefs.lowQuality)
				{
					upperBoppers.dance(true);
				}

				if (heyTimer <= 0)
					bottomBoppers.dance(true);
				santa.dance(true);

			case 'limo':
				if (!ClientPrefs.lowQuality)
				{
					grpLimoDancers.forEach(function(dancer:BackgroundDancer)
					{
						dancer.dance();
					});
				}

				if (FlxG.random.bool(10) && fastCarCanDrive)
					fastCarDrive();
			case "philly":
				if (!trainMoving)
					trainCooldown += 1;

				if (curBeat % 4 == 0)
				{
					curLight = FlxG.random.int(0, phillyLightsColors.length - 1, [curLight]);
					phillyWindow.color = phillyLightsColors[curLight];
					phillyWindow.alpha = 1;
				}

				if (curBeat % 8 == 4 && FlxG.random.bool(30) && !trainMoving && trainCooldown > 8)
				{
					trainCooldown = FlxG.random.int(-4, 0);
					trainStart();
				}
		}

		if (curStage == 'spooky' && FlxG.random.bool(10) && curBeat > lightningStrikeBeat + lightningOffset)
		{
			lightningStrikeShit();
		}

		lastBeatHit = curBeat;
		stageBuild.callFunction('onBeatHit', [curBeat]);
		callOnHscript("onBeatHit", [curBeat]);

		setOnLuas('curBeat', curBeat);
		callOnLuas('onBeatHit', []);
	}

	override function sectionHit()
	{
		super.sectionHit();

		if (SONG.notes[curSection] != null)
		{
			if (generatedMusic && !endingSong && !isCameraOnForcedPos)
			{
				moveCameraSection();
			}

			if (SONG.notes[curSection].changeBPM)
			{
				Conductor.changeBPM(SONG.notes[curSection].bpm);
				setOnLuas('curBpm', Conductor.bpm);
				setOnLuas('crochet', Conductor.crochet);
				setOnLuas('stepCrochet', Conductor.stepCrochet);
			}
			setOnLuas('mustHitSection', SONG.notes[curSection].mustHitSection);
			setOnLuas('altAnim', SONG.notes[curSection].altAnim);
			setOnLuas('gfSection', SONG.notes[curSection].gfSection);
		}

		if (camZooming && FlxG.camera.zoom < 1.35 && ClientPrefs.camZooms && camZoomingFreq == 0)
		{
			FlxG.camera.zoom += 0.015 * camZoomingMult;
			camHUD.zoom += 0.03 * camZoomingMult;
		}

		if (curSection > 1
			&& SONG.notes[curSection] != null
			&& SONG.notes[curSection - 1].mustHitSection
			&& !SONG.notes[curSection].mustHitSection
			&& !checkFutureNotes(Conductor.songPosition))
			popUpComboScore(comboNum <= 6, true);

		setOnLuas('curSection', curSection);
		callOnLuas('onSectionHit', []);
		callOnHscript("onSectionHit", [curSection]);
		stageBuild.callFunction('onSectionHit', [curSection]);
	}

	public function callOnLuas(funcToCall:String, args:Array<Dynamic>, ignoreStops = true, exclusions:Array<String> = null,
			excludeValues:Array<Dynamic> = null):Dynamic
	{
		var returnVal:Dynamic = FunkinLua.Function_Continue;
		#if LUA_ALLOWED
		if (args == null)
			args = [];
		if (exclusions == null)
			exclusions = [];
		if (excludeValues == null)
			excludeValues = [FunkinLua.Function_Continue];

		/*for (script in luaArray) {
		if(exclusions.contains(script.scriptName))
			continue;

		var ret:Dynamic = script.call(event, args);
		if(ret == FunkinLua.Function_StopLua && !ignoreStops)
			break;

		// had to do this because there is a bug in haxe where Stop != Continue doesnt work
		var bool:Bool = ret == FunkinLua.Function_Continue;
		if(!bool && ret != 0) {
			returnVal = cast ret;
		}
	}*/

		var len:Int = luaArray.length;
		var i:Int = 0;
		while (i < len)
		{
			var script:FunkinLua = luaArray[i];
			if (exclusions.contains(script.scriptName))
			{
				i++;
				continue;
			}

			var myValue:Dynamic = script.call(funcToCall, args);
			if (!excludeValues.contains(myValue) && !ignoreStops)
			{
				returnVal = myValue;
				break;
			}

			if (myValue != null && !excludeValues.contains(myValue))
				returnVal = myValue;

			if (!script.closed)
				i++;
			else
				len--;
		}
		#end
		return returnVal;
	}

	public function callOnHscript(funcToCall:String, args:Array<Dynamic>, ignoreStops = true, exclusions:Array<String> = null,
			excludeValues:Array<Dynamic> = null):Dynamic
	{
		var returnVal:Dynamic = FunkinLua.Function_Continue;
		if (exclusions == null)
			exclusions = new Array();
		if (excludeValues == null)
			excludeValues = new Array();
		excludeValues.push(FunkinLua.Function_Continue);

		var len:Int = hscriptArray.length;
		if (len < 1)
			return returnVal;

		/*for (script in hscriptArray) {
		if(exclusions.contains(script.scriptName))
			continue;

		var ret:Dynamic = script.executeFunc(funcToCall, args);
		if(ret == FunkinLua.Function_StopLua && !ignoreStops)
			break;

		var bool:Bool = ret == FunkinLua.Function_Continue;
		if(!bool && ret != 0) {
			returnVal = cast ret;
		}
	}*/

		for (i in 0...len)
		{
			var script:GrfxHxScript = hscriptArray[i];
			if (script == null || !script.exists(funcToCall) || exclusions.contains(script.scriptName))
				continue;

			var myValue:Dynamic = null;
			try
			{
				myValue = script.executeFunc(funcToCall, args);

				if (!excludeValues.contains(myValue) && !ignoreStops)
				{
					returnVal = myValue;
					break;
				}

				if (myValue != null && !excludeValues.contains(myValue))
					returnVal = myValue;
			}
		}
		return returnVal;
	}

	public function closeScript(name:String):Bool
	{
		var dick:Bool = false;
		#if LUA_ALLOWED
		for (script in luaArray)
			if (script.scriptName == name)
				dick = script.close();
		#end
		for (script in hscriptArray)
			if (script.scriptName == name)
				dick = script.dispose();
		return dick;
	}

	public function setOnLuas(variable:String, arg:Dynamic, exclusions:Array<String> = null)
	{
		#if LUA_ALLOWED
		if (exclusions == null)
			exclusions = [];
		for (script in luaArray)
		{
			if (exclusions.contains(script.scriptName))
				continue;

			script.set(variable, arg);
		}
		#end
		for (script in hscriptArray)
			script.set(variable, arg);
	}

	function StrumPlayAnim(isDad:Bool, id:Int, time:Float, ?isSus:Bool = false)
	{
		var spr:StrumNote = null;
		var isPlayer:Bool = false;
		if (isDad)
		{
			if (ClientPrefs.lightCpuStrums)
				spr = strumLineNotes.members[id];
		}
		else
		{
			spr = playerStrums.members[id];
			isPlayer = true;
		}
		if (spr != null)
		{
			if (ClientPrefs.noteSusSplashes && isSus && spr.alpha > 0.4 && spr.visible)
				spawnSusNoteSplash(spr.getMidpoint().x, spr.getMidpoint().y, id, spr);

			spr.playAnim('confirm', true);
			if (time > 0)
				spr.resetAnim = time;
		}
	}

	public function spawnSusNoteSplash(x:Float, y:Float, data:Int, ?strum:StrumNote = null)
	{
		var skinS:String = 'NOTE_assets-extra';
		if (PlayState.SONG.extrasSkin != null && PlayState.SONG.extrasSkin.length > 0)
			skinS = PlayState.SONG.extrasSkin;

		var hueValues:Dictionary<Int, Float> = new Dictionary<Int, Float>();
		var satValues:Dictionary<Int, Float> = new Dictionary<Int, Float>();
		var brtValues:Dictionary<Int, Float> = new Dictionary<Int, Float>();

		if (data > -1 && data < ClientPrefs.arrowHSV.length)
		{
			if (!hueValues.exists(data))
				hueValues[data] = ClientPrefs.arrowHSV[data][0] / 360;
			hue = hueValues[data];
			if (!satValues.exists(data))
				satValues[data] = ClientPrefs.arrowHSV[data][1] / 100;
			sat = satValues[data];
			if (!brtValues.exists(data))
				brtValues[data] = ClientPrefs.arrowHSV[data][2] / 100;
			brt = brtValues[data];
		}

		var splash:SusSplash = grpSusSplashes.recycle(SusSplash);
		splash.setupNoteSplash(x, y, data, skinS, hue, sat, brt);
		if (strum != null)
		{
			splash.scrollFactor.set(strum.scrollFactor.x, strum.scrollFactor.y);
			splash.alpha *= strum.alpha;
		}
		grpSusSplashes.add(splash);
	}

	public var ratingName:String = '?';
	public var ratingPercent:Float;
	public var ratingFC:String;

	public function RecalculateRating(badHit:Bool = false)
	{
		setOnLuas('score', songScore);
		setOnLuas('misses', songMisses);
		setOnLuas('hits', songHits);

		var ret:Dynamic = (callOnLuas('onRecalculateRating', [], false) || callOnHscript('onRecalculateRating', [], false));
		if (ret != FunkinLua.Function_Stop)
		{
			call('onRecalculateRating', []);
			stageBuild.callFunction('onRecalculateRating', []);

			if (totalPlayed < 1) // Prevent divide by 0
				ratingName = '?';
			else
			{
				ratingPercent = Math.min(1, Math.max(0, totalNotesHit / totalPlayed));
				var ratings:Array<Dynamic> = RatingsData.grafexAnalogRatings;

				if (ratingPercent >= 1)
				{
					var dummyRating = ratings[ratings.length - 1][0];
					ratingName = dummyRating;
				}
				else
				{
					for (i in 0...ratings.length - 1)
					{
						if (ratingPercent < ratings[i][1])
						{
							ratingName = ratings[i][0];
							break;
						}
					}
				}
			}

			// Rating FC
			ratingFC = "";
			if (sicks > 0)
				ratingFC = "SFC";
			if (goods > 0)
				ratingFC = "GFC";
			if (bads > 0 || shits > 0)
				ratingFC = "FC";
			if (songMisses > 0 && songMisses < 10)
				ratingFC = "SDCB";
			else if (songMisses >= 10)
				ratingFC = "Clear";
		}
		updateScore(badHit, false);
		setOnLuas('rating', ratingPercent);
		setOnLuas('ratingName', ratingName);
		setOnLuas('ratingFC', ratingFC);
	}

	public function reloadHealthBarColors()
	{
		classicHealthBar ? {
			healthBar.createFilledBar(0xFFFF0000, 0xFF66FF33);
			healthBarWN.createFilledBar(0xFFFF0000, 0xFF66FF33);
		} : {
			healthBar.createFilledBar(FlxColor.fromRGB(dad.healthColorArray[0], dad.healthColorArray[1], dad.healthColorArray[2]),
				FlxColor.fromRGB(boyfriend.healthColorArray[0], boyfriend.healthColorArray[1], boyfriend.healthColorArray[2]));
			healthBarWN.createFilledBar(FlxColor.fromRGB(dad.healthColorArray2[0], dad.healthColorArray2[1], dad.healthColorArray2[2]),
				FlxColor.fromRGB(boyfriend.healthColorArray2[0], boyfriend.healthColorArray2[1], boyfriend.healthColorArray2[2]));
		}

		healthBar.updateBar();
		healthBarWN.updateBar();
	}

	public function healthBarShake(intensity:Float) // Litle rewrite - PurSnake
	{
		redFlash();

		if (!classicHealthBar)
			healthBarGroup.forEach(function(element:Dynamic)
			{
				for (timer in [
					{time: 0.01, forse: (10 * intensity)},
					{time: 0.05, forse: -(15 * intensity)},
					{time: 0.10, forse: (8 * intensity)},
					{time: 0.15, forse: -(5 * intensity)},
					{time: 0.20, forse: (3 * intensity)},
					{time: 0.25, forse: -(1 * intensity)}
				])
				{
					new FlxTimer().start(timer.time / playbackRate, function(tmr:FlxTimer)
					{
						element.y += timer.forse;
					});
				}
			});
	}

	function redFlash() // HaxeFlixel documentaion be like - PurSnake || Rewrited - PurSnake
	{
		if (healthBar.percent > 17)
		{
			if (isHealthCheckingEnabled)
				isHealthCheckingEnabled = false;

			if (iconP1.animation.getByName('losing') != null)
				iconP1.playAnim("losing", true);

			if (iconP2.animation.getByName('winning') != null)
				iconP2.playAnim("winning", true);

			new FlxTimer().start(Conductor.crochet / 750 / playbackRate, function(tmr:FlxTimer)
			{
				isHealthCheckingEnabled = true;
			});
		}
	}

	public var camFocus:String = "";
	var dadPos:Array<Float> = [0, 0];
	var bfPos:Array<Float> = [0, 0];
	var gfPos:Array<Float> = [0, 0];

	public function triggerCamMovement(num:Int = 0)
	{
		call("onTriggerCamMovement", [camFocus, num]);
		callOnLuas("onTriggerCamMovement", [camFocus, num]);
		callOnHscript("onTriggerCamMovement", [camFocus, num]);
		stageBuild.callFunction('onTriggerCamMovement', [camFocus, num]);

		if (PlayState.NotesCanMoveCam && !isEventWorking && camCharsPositions.exists(camFocus))
			switch (num)
			{
				case 2:
					camGame.targetOffset.y = -cameraMoveOffset * camGame.zoom / defaultCamZoom;
					camGame.targetOffset.x = 0;
				case 3:
					camGame.targetOffset.x = cameraMoveOffset * camGame.zoom / defaultCamZoom;
					camGame.targetOffset.y = 0;
				case 1:
					camGame.targetOffset.y = cameraMoveOffset * camGame.zoom / defaultCamZoom;
					camGame.targetOffset.x = 0;
				case 0:
					camGame.targetOffset.x = -cameraMoveOffset * camGame.zoom / defaultCamZoom;
					camGame.targetOffset.y = 0;
			}
	}

	function getCamOffsets()
	{
		dadPos[0] = dad.getMidpoint().x + 150 + dad.cameraPosition[0] + opponentCameraOffset[0];
		dadPos[1] = dad.getMidpoint().y - 100 + dad.cameraPosition[1] + opponentCameraOffset[1];
		camCharsPositions.set('dad', [dadPos[0], dadPos[1]]);

		bfPos[0] = boyfriend.getMidpoint().x - 100 - boyfriend.cameraPosition[0] + boyfriendCameraOffset[0];
		bfPos[1] = boyfriend.getMidpoint().y - 100 + boyfriend.cameraPosition[1] + boyfriendCameraOffset[1];
		camCharsPositions.set('bf', [bfPos[0], bfPos[1]]);
		if (!stageData.hide_girlfriend)
		{
			gfPos[0] = gf.getMidpoint().x + gf.cameraPosition[0] + girlfriendCameraOffset[0];
			gfPos[1] = gf.getMidpoint().y + gf.cameraPosition[1] + girlfriendCameraOffset[1];
			camCharsPositions.set('gf', [gfPos[0], gfPos[1]]);
		}
		call('onGetCamOffsets', []);
		callOnLuas('onGetCamOffsets', []);
		stageBuild.callFunction('onGetCamOffsets', []);
		callOnHscript("onGetCamOffsets", []);
	}

	public function startVideo(name:String)
	{
		#if VIDEOS_ALLOWED
		inCutscene = true;

		var filepath:String = Paths.video(name);
		#if sys
		if (!FileSystem.exists(filepath))
		#else
		if (!OpenFlAssets.exists(filepath))
		#end
		{
			FlxG.log.warn('Couldnt find video file: ' + name);
			startAndEnd();
			return;
		}

		var video:MP4Handler = new MP4Handler();
		video.playVideo(filepath);
		video.finishCallback = function()
		{
			startAndEnd();
			return;
		}
		#else
		FlxG.log.warn('Platform not supported!');
		startAndEnd();
		return;
		#end
	}

	function functionFormatter(func:String):Void
	{
		var className = new PlayState();
		var fn = Reflect.field(className, func);
		Reflect.callMethod(className, fn, []); // Real shit - PurSnake
	}

	var dialogue:Array<String> = ['blah blah blah', 'coolswag'];
	var dialogueJson:DialogueFile = null;

	function getCutsceneFiles()
	{
		var songName:String = Paths.formatToSongPath(SONG.song);
		var file:String = Paths.json(songName + '/dialogue'); // Checks for json/Psych Engine dialogue
		if (OpenFlAssets.exists(file))
		{
			dialogueJson = DialogueBoxPsych.parseDialogue(file);
		}
		var file:String = Paths.txt(songName + '/' + songName + 'Dialogue'); // Checks for vanilla/Senpai dialogue
		if (OpenFlAssets.exists(file))
		{
			dialogue = Utils.coolTextFile(file);
		}
	}

	function startAndEnd()
	{
		if (endingSong)
			endSong();
		else
			startCountdown();
	}
}

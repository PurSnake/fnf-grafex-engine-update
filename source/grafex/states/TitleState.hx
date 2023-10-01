package grafex.states;


import grafex.data.EngineData;

import grafex.system.statesystem.MusicBeatState;
import grafex.system.Paths;
import grafex.system.Conductor;

import grafex.sprites.Alphabet;

import grafex.effects.shaders.ColorSwap;
import grafex.effects.ColorblindFilters;

import grafex.states.MainMenuState;
import grafex.states.substates.PrelaunchingState;

import grafex.util.PlayerSettings;
import grafex.util.ClientPrefs;
import grafex.util.Highscore;
import grafex.util.Utils;

import flixel.FlxG;
import flixel.addons.effects.FlxTrail;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.input.keyboard.FlxKey;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.transition.FlxTransitionSprite.GraphicTransTileDiamond;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.transition.TransitionData;
import haxe.Json;
import openfl.display.Bitmap;
import grafex.data.WeekData;
import openfl.display.BitmapData;
import sys.FileSystem;
import sys.io.File;
import flixel.addons.display.FlxBackdrop;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.frames.FlxFrame;
import flixel.group.FlxGroup;
import flixel.input.gamepad.FlxGamepad;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.math.FlxMath;
import flixel.system.FlxSound;
import flixel.system.ui.FlxSoundTray;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import lime.app.Application;
import openfl.Assets;
import lime.ui.WindowAttributes;

import haxe.ds.StringMap;

import grafex.system.script.GrfxScriptHandler;

using StringTools;

using flixel.util.FlxSpriteUtil;
typedef TitleData =
{
	titlex:Float,
	titley:Float,
	startx:Float,
	starty:Float,
	gfx:Float,
	gfy:Float,
	backgroundSprite:String,
	bpm:Int
}

class TitleState extends MusicBeatState
{
	public static var initialized:Bool = false;

	var blackScreen:FlxSprite;
	var credGroup:FlxGroup;
	var credTextShit:Alphabet;
	var textGroup:FlxGroup;

	var titleTextColors:Array<FlxColor> = [0xFF33FFFF, 0xFF3333CC];
	var titleTextAlphas:Array<Float> = [1, .64];

	public var curWacky:Array<String> = [];

	var wackyImage:FlxSprite;

	var mustUpdate:Bool = false;
	
	public static var titleJSON:TitleData;
	
	public static var updateVersion:String = '';

	public var switchTime:Float = 1;

	override public function create():Void
	{
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();

		PlayerSettings.init();

		#if LUA_ALLOWED
		Paths.pushGlobalMods();
		#end


		Application.current.window.title = Main.appTitle;
		WeekData.loadTheFirstEnabledMod();

		FlxG.watch.addQuick("sectionShit", curSection);
		FlxG.watch.addQuick("beatShit", curBeat);
		FlxG.watch.addQuick("stepShit", curStep);
		
		titleJSON = getTitleData();

		if(titleJSON == null)
		{	
	    	titleJSON = {	
	            titlex: -150,
	            titley: -100,
	            startx: 100,
	            starty: 576,
	            gfx: 512,
	            gfy :40,
	            backgroundSprite: "",
	            bpm: 102
            };
		}

		curWacky = FlxG.random.getObject(getIntroTextShit());

		super.create();

		if(!initialized)
		{
			if(FlxG.save.data != null && FlxG.save.data.fullscreen)
			{
				FlxG.fullscreen = FlxG.save.data.fullscreen;
				//trace('LOADED FULLSCREEN SETTING!!');
			}
			persistentUpdate = true;
			persistentDraw = true;
		}

		if (FlxG.save.data.weekCompleted != null)
		{
			StoryMenuState.weekCompleted = FlxG.save.data.weekCompleted;
		}

		FlxG.mouse.visible = true;
		
		FlxG.mouse.load(Paths.image("cursor").bitmap, 1, 0, 0); // Huh? - PurSnake

		#if desktop
		DiscordClient.initialize();
		Application.current.onExit.add (function (exitCode) {
			DiscordClient.shutdown();
		});
		#end
		if (initialized)
			startIntro();
		else
		{
			new FlxTimer().start(1, function(tmr:FlxTimer)
			{
				startIntro();
			});
		} 
		
		call("onCreatePost", []);
	}

	var exitText:FlxText;

	function startIntro()
	{
		call("onIntroPreStart", []);
		ColorblindFilters.applyFiltersOnGame();
                if(!initialized && FlxG.sound.music == null) FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);

		persistentUpdate = true;

		var bg:FlxSprite = new FlxSprite();
		if (titleJSON.backgroundSprite != null && titleJSON.backgroundSprite.length > 0 && titleJSON.backgroundSprite != "none"){
			bg.loadGraphic(Paths.image(titleJSON.backgroundSprite));
		}else{
			bg.makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		}
		add(bg);

		var logo:FlxSprite = new FlxSprite().loadGraphic(Paths.image('logo'));
		logo.screenCenter();
		logo.alpha = 0.025;
		logo.antialiasing = ClientPrefs.globalAntialiasing;
		add(logo);

		call("onIntroStart", []);

		credGroup = new FlxGroup();
		add(credGroup);
		textGroup = new FlxGroup();

		blackScreen = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		credGroup.add(blackScreen);

		credTextShit = new Alphabet(0, 0, "", true);
		credTextShit.screenCenter();

		//credTextShit.alignment = CENTER;

		credTextShit.visible = false;

		exitText = new FlxText(-300, 0, FlxG.width, 'Exiting game...', 32);
		exitText.alpha = 0;
		exitText.borderColor = FlxColor.BLACK;
		exitText.borderSize = 3;
		exitText.borderStyle = FlxTextBorderStyle.OUTLINE;
		exitText.setFormat("VCR OSD Mono", 32, FlxColor.WHITE, CENTER);
		add(exitText);

		FlxTween.tween(credTextShit, {y: credTextShit.y + 20}, 2.9, {ease: FlxEase.quadInOut, type: PINGPONG});

		if (initialized)
			skipIntro();
		else
			initialized = true; 

		call("onIntroPost", []);
	}

	function getIntroTextShit():Array<Array<String>>
	{
		var fullText:String = Assets.getText(Paths.txt('introText'));

		var firstArray:Array<String> = fullText.split('\n');
		var swagGoodArray:Array<Array<String>> = [];

		for (i in firstArray)
		{
			swagGoodArray.push(i.split('--'));
		}

		return swagGoodArray;
	}

	var timer:Float = 0;
	var transitioning:Bool = false;

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		FlxG.watch.addQuick("sectionShit", curSection);
		FlxG.watch.addQuick("beatShit", curBeat);
		FlxG.watch.addQuick("stepShit", curStep);

		var pressedEnter:Bool = FlxG.keys.justPressed.ENTER || controls.ACCEPT;
        var tryExitGame:Bool = FlxG.keys.justPressed.ESCAPE || controls.BACK;

		#if mobile
		for (touch in FlxG.touches.list)
		{
			if (touch.justPressed)
			{
				pressedEnter = true;
			}
		}
		#end

		var gamepad:FlxGamepad = FlxG.gamepads.lastActive;

		if (gamepad != null)
		{
			if (gamepad.justPressed.START)
				pressedEnter = true;
		}

		if (initialized && !transitioning && skippedIntro)
		{		
			if(pressedEnter)
			{
                                call("onPressedEnter", []);				
                           			
				transitioning = true;
				new FlxTimer().start(switchTime, function(tmr:FlxTimer)
				{
					MusicBeatState.switchState(new MainMenuState());
					closedState = true;
				});
			}

			if (FlxG.keys.pressed.ESCAPE)
			{
				timer += elapsed * 5;
				exitText.alpha = FlxMath.lerp(0, 1, timer / 3);

				if(timer >= 8)
					Sys.exit(0);
			}
			else
			{
				timer = 0;
				exitText.alpha = 0;
			}
		}

		if (initialized && pressedEnter && !skippedIntro)
		{
			skipIntro();
		}

		call("onUpdatePost", [elapsed]);
	}

	public function createCoolText(textArray:Array<String>, ?offset:Float = 0)
	{
		for (i in 0...textArray.length)
		{
			var money:Alphabet = new Alphabet(0, 0, textArray[i], true, false);
			money.screenCenter(X);
			money.y += (i * 60) + 200 + offset;
			if(credGroup != null && textGroup != null) {
				credGroup.add(money);
				textGroup.add(money);
			}
			money.y -= 350;
			FlxTween.tween(money, {y: money.y + 350}, 0.3, {ease: FlxEase.expoOut, startDelay: 0.0});
		}
	}

	public function addMoreText(text:String, ?offset:Float = 0)
	{
		if(textGroup != null && credGroup != null) {
			var coolText:Alphabet = new Alphabet(0, 0, text, true, false);
			coolText.screenCenter(X);
			coolText.y += (textGroup.length * 60) + 200 + offset;
			credGroup.add(coolText);
			textGroup.add(coolText);
			coolText.y += 750;
		    FlxTween.tween(coolText, {y: coolText.y - 750}, 0.3, {ease: FlxEase.expoOut, startDelay: 0.0});
		}
	}

	public function deleteCoolText()
	{
		while (textGroup.members.length > 0)
		{
			credGroup.remove(textGroup.members[0], true);
			textGroup.remove(textGroup.members[0], true);
		}
	}

	override function stepHit()
	{
		super.stepHit();
	}

	private var sickBeats:Int = 0; //Basically curBeat but won't be skipped if you hold the tab or resize the screen
	public static var closedState:Bool = false;
	override function beatHit()
	{
		super.beatHit();
		if(!closedState) {
			sickBeats++;
			call("onCoolTextBeat", [sickBeats]);
		}
	}

	override function sectionHit()
	{
		super.sectionHit();
	}

	override function destroy() {
		super.destroy();
	}

	public static function getTitleData()
	{
		var data:TitleData;
		#if (desktop && MODS_ALLOWED)
		var path = "mods/" + Paths.currentModDirectory + "/images/gfDanceTitle.json";
		//trace(path, FileSystem.exists(path));
		if (!FileSystem.exists(path)) {
			path = "mods/images/gfDanceTitle.json";
		}
		//trace(path, FileSystem.exists(path));
		if (!FileSystem.exists(path)) {
			path = "assets/images/gfDanceTitle.json";
		}
		trace(path, FileSystem.exists(path));
		data = Json.parse(File.getContent(path));
		#else
		var path = Paths.getPreloadPath("images/gfDanceTitle.json");
		data = Json.parse(Assets.getText(path)); 
		#end
		return data;
	}

	public static function getGameIconPath()
	{
		#if (desktop && MODS_ALLOWED)
		var path = "mods/" + Paths.currentModDirectory + "/images/icon.png";
		//trace(path, FileSystem.exists(path));
		if (!FileSystem.exists(path)) {
			path = "mods/images/icon.png";
		}
		//trace(path, FileSystem.exists(path));
		if (!FileSystem.exists(path)) {
			path = "assets/images/icon.png";
		}
		trace(path, FileSystem.exists(path));
		#else
		var path = Paths.getPreloadPath("images/icon.png");
		#end
		return path;
	}
	
	var skippedIntro:Bool = false;

	public function skipIntro():Void
	{
		call("onSkipIntro", [skippedIntro]);
		if (!skippedIntro)
		{
			skippedIntro = true;
			remove(credGroup);
		}
	}
}

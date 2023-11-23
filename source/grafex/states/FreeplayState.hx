package grafex.states;

import grafex.states.playstate.PlayState;
import grafex.util.Utils;
import grafex.states.MainMenuState;
import grafex.states.substates.ResetScoreSubState;
import grafex.states.substates.LoadingState;
import grafex.states.substates.GameplayChangersSubstate;
import grafex.system.song.Song;
import grafex.system.Conductor;
import grafex.system.Paths;
import grafex.sprites.HealthIcon;
import grafex.sprites.HealthIcon.IconProperties;
import grafex.sprites.Alphabet;
import grafex.system.statesystem.MusicBeatState;
import grafex.util.ClientPrefs;
import grafex.util.Utils;
#if desktop
import external.Discord.DiscordClient;
#end
import flixel.FlxCamera;
import grafex.states.editors.ChartingState;
import flash.text.TextField;
import flixel.effects.FlxFlicker;
import flixel.tweens.FlxEase;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import lime.utils.Assets;
import flixel.system.FlxSound;
import openfl.utils.Assets as OpenFlAssets;
import grafex.data.WeekData;
import lime.app.Application;
import sys.FileSystem;
import flixel.util.FlxTimer;
import grafex.util.Highscore;

using StringTools;

class FreeplayState extends MusicBeatState
{
	var songs:Array<SongMetadata> = [];

	private var camBackground:FlxCamera;
	public var camINTERFACE:FlxCamera;

	private static var curSelected:Int = 0;
	private static var freeplayinstPlaying:Int = -1;
	var curDifficulty:Int = -1;
	private static var lastDifficultyName:String = '';

	var scoreBG:FlxSprite;
	var scoreText:FlxText;
	var diffText:FlxText;
	var countText:FlxText;
	var lerpScore:Int = 0;
	var lerpRating:Float = 0;
	var intendedScore:Int = 0;
	var intendedRating:Float = 0;

	private var grpSongs:FlxTypedGroup<Alphabet>;
	private var curPlaying:Bool = false;

	private var iconArray:Array<HealthIcon> = [];

	var bg:FlxSprite;
	var intendedColor:Int;
	var colorTween:FlxTween;
	var forMouseClick:FlxTimer = null;
	var acceptedSong:Bool = false;

	var camZoom:FlxTween;

	override function create()
	{
		trace('Switched state to: ' + Type.getClassName(Type.getClass(this)));
		
		Paths.clearStoredMemory();
		Application.current.window.title = Main.appTitle + ' - Freeplay Menu';
		
		PlayState.isStoryMode = false;
		WeekData.reloadWeekFiles(false);

		camBackground = new FlxCamera();
		camINTERFACE = new FlxCamera();

		camINTERFACE.bgColor.alpha = 0;

		FlxG.cameras.reset(camBackground);
		FlxG.cameras.add(camINTERFACE, false);

		// FlxCamera.defaultCameras = [camBackground];
		FlxG.cameras.setDefaultDrawTarget(camBackground, true);

		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menu", null);
		#end

		super.create();

		for (i in 0...WeekData.weeksList.length) {
			if(weekIsLocked(WeekData.weeksList[i])) continue;

			var leWeek:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[i]);
			var leSongs:Array<String> = [];
			var leChars:Array<String> = [];

			for (j in 0...leWeek.songs.length)
			{
				leSongs.push(leWeek.songs[j][0]);
				leChars.push(leWeek.songs[j][1]);
			}

			WeekData.setDirectoryFromWeek(leWeek);
			for (song in leWeek.songs)
			{
				var colors:Array<Int> = song[2];
				if(colors == null || colors.length < 3)
				{
					colors = [146, 113, 253];
				}
				var props:IconProperties = song[3];
				addSong(song[0], i, song[1], FlxColor.fromRGB(colors[0], colors[1], colors[2]), props);
			}
		}
		WeekData.loadTheFirstEnabledMod();

		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.antialiasing = ClientPrefs.globalAntialiasing;
		bg.setGraphicSize(Std.int(bg.width * 1.1));
		bg.updateHitbox();
		bg.screenCenter();
		add(bg);

		grpSongs = new FlxTypedGroup<Alphabet>();
		add(grpSongs);

		for (i in 0...songs.length)
		{
			var songText:Alphabet = new Alphabet(0, (70 * i) + 30, Utils.capitalize(songs[i].songName), false, false, 0.05, 1, true);
			songText.isMenuItem = true;
			songText.targetY = i;
			grpSongs.add(songText);
			
			if (songText.width > 980)
			{
				var textScale:Float = 980 / songText.width;
				songText.scale.x = textScale;
				for (letter in songText.lettersArray)
				{
					letter.x *= textScale;
					letter.offset.x *= textScale;
				}
			}

			Paths.currentModDirectory = songs[i].folder;
			var icon:HealthIcon = new HealthIcon(songs[i].songCharacter, songs[i].iconProperties, false);
			icon.sprTracker = songText;

			iconArray.push(icon);
			add(icon);
		}
		WeekData.setDirectoryFromWeek();

		scoreText = new FlxText(FlxG.width * 0.7, 5, 0, "", 32);
		scoreText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, RIGHT);

		scoreBG = new FlxSprite(scoreText.x - 6, 0).makeGraphic(1, 66, 0xFF000000);
		scoreBG.alpha = 0.6;
		add(scoreBG);

		diffText = new FlxText(scoreText.x, scoreText.y + 36, 0, "", 24);
		diffText.font = scoreText.font;
		add(diffText);		

        countText = new FlxText(scoreText.x, scoreText.y + 12, 0, "", 32);
		countText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		countText.borderSize = 1.25;

		add(countText);
		add(scoreText);

		if(curSelected >= songs.length) curSelected = 0;
		bg.color = songs[curSelected].color;
		intendedColor = bg.color;

		if(lastDifficultyName == '')
		{
			lastDifficultyName = Utils.defaultDifficulty;
		}
		curDifficulty = Math.round(Math.max(0, Utils.defaultDifficulties.indexOf(lastDifficultyName)));
		
		changeSelection();
		changeDiff();

		camZoom = FlxTween.tween(this, {}, 0);

		var swag:Alphabet = new Alphabet(1, 0, "swag");

		var textBG:FlxSprite = new FlxSprite(0, FlxG.height - 26).makeGraphic(FlxG.width, 26, 0xFF000000);
		textBG.alpha = 0.6;
		add(textBG);

		#if PRELOAD_ALL
		var leText:String = "Press SPACE to listen to the Song / Press CTRL to open the Gameplay Changers Menu / Press RESET to Reset your Score and Accuracy.";
		var size:Int = 16;
		#else
		var leText:String = "Press CTRL to open the Gameplay Changers Menu / Press RESET to Reset your Score and Accuracy.";
		var size:Int = 18;
		#end
		var text:FlxText = new FlxText(textBG.x, textBG.y + 4, FlxG.width, leText, size);
		text.setFormat(Paths.font("vcr.ttf"), size, FlxColor.WHITE, RIGHT);
		text.scrollFactor.set();
		add(text);

		scoreText.cameras = [camINTERFACE];
		scoreBG.cameras = [camINTERFACE];
		diffText.cameras = [camINTERFACE];
		countText.cameras = [camINTERFACE];
		textBG.cameras = [camINTERFACE];
		text.cameras = [camINTERFACE];
		
		call('onCreatePost', []);

	}

	override function closeSubState() {
		changeSelection(0, false);
		super.closeSubState();
	}

	public function addSong(songName:String, weekNum:Int, songCharacter:String, color:Int, props:IconProperties)
	{
		call('onAddSong', [songName, weekNum, songCharacter, color, props]);
		songs.push(new SongMetadata(songName, weekNum, songCharacter, color, props));
		call('onAddSongPost', [songName, weekNum, songCharacter, color, props]);
	}

	function weekIsLocked(name:String):Bool {
		var leWeek:WeekData = WeekData.weeksLoaded.get(name);
		return (!leWeek.startUnlocked && leWeek.weekBefore.length > 0 && (!StoryMenuState.weekCompleted.exists(leWeek.weekBefore) || !StoryMenuState.weekCompleted.get(leWeek.weekBefore)));
	}
	override public function onFocus():Void
    {
		forMouseClick = new FlxTimer().start(0.1, function(tmr:FlxTimer){forMouseClick = null;});
        super.onFocus();
    }

	var holdTime:Float = 0;
	public static var vocals:FlxSound = null;
	public static var vocals2:FlxSound = null;
	private static var ChooseSound:FlxSound = null;
	override function update(elapsed:Float)
	{

		super.update(elapsed);

		for (icon in iconArray)
		    //icon.doIconPosFreePlayBoyezz(elapsed);

		if (FlxG.sound.music != null)
			Conductor.songPosition = FlxG.sound.music.time;


		if (!acceptedSong){
            if (FlxG.sound.music.volume < 0.7)
		    	FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
	    }

		lerpScore = Math.floor(FlxMath.lerp(lerpScore, intendedScore, Utils.boundTo(elapsed * 24, 0, 1)));
		lerpRating = FlxMath.lerp(lerpRating, intendedRating, Utils.boundTo(elapsed * 12, 0, 1));

		if (Math.abs(lerpScore - intendedScore) <= 10)
			lerpScore = intendedScore;
		if (Math.abs(lerpRating - intendedRating) <= 0.01)
			lerpRating = intendedRating;

		var ratingSplit:Array<String> = Std.string(Highscore.floorDecimal(lerpRating * 100, 2)).split('.');
		if(ratingSplit.length < 2) { //No decimals, add an empty space
			ratingSplit.push('');
		}
		
		while(ratingSplit[1].length < 2) { //Less than 2 decimals in it, add decimals then
			ratingSplit[1] += '0';
		}

		scoreText.text = 'PERSONAL BEST: ' + lerpScore + ' (' + ratingSplit.join('.') + '%)';
		positionHighscore();

		var upP = controls.UI_UP_P;
		var downP = controls.UI_DOWN_P;
		var accepted = controls.ACCEPT;
		var space = FlxG.keys.justPressed.SPACE;
		var ctrl = FlxG.keys.justPressed.CONTROL;

		var shiftMult:Int = 1;
		if(FlxG.keys.pressed.SHIFT) shiftMult = 3;

		if(songs.length > 1)
		{
			if (upP)
			{
				changeSelection(-shiftMult);
				holdTime = 0;
			}
			if (downP)
			{
				changeSelection(shiftMult);
				holdTime = 0;
			}
			if(controls.UI_DOWN || controls.UI_UP)
			{
				var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
				holdTime += elapsed;
				var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);

				if(holdTime > 0.5 && checkNewHold - checkLastHold > 0)
				{
					changeSelection((checkNewHold - checkLastHold) * (controls.UI_UP ? -shiftMult : shiftMult), false);
					changeDiff();
				}
			}
		}

		if(FlxG.mouse.wheel != 0)
		{
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.2);
			changeSelection(-shiftMult * FlxG.mouse.wheel, false);
			changeDiff();
		}

		if (controls.UI_LEFT_P)
			changeDiff(-1);
		else if (controls.UI_RIGHT_P)
			changeDiff(1);
		else if (upP || downP) changeDiff();

		if (controls.BACK)
		{
			if (!acceptedSong)
			{
				call('onLeave', []);
				acceptedSong = true;
				new FlxTimer().start(0.4, function(tmr:FlxTimer)
				{		
					if(colorTween != null) colorTween.cancel();

			        FlxG.sound.play(Paths.sound('cancelMenu'));
			        MusicBeatState.switchState(new MainMenuState());
			    });
		    }
		}

		if(ctrl)
		{
			if (!acceptedSong)
			{
			    openSubState(new GameplayChangersSubstate());
			}
		}
		else if(space)
		{
			var songLowercase:String = Paths.formatToSongPath(songs[curSelected].songName);
			var poop:String = Highscore.formatSong(songs[curSelected].songName.toLowerCase(), curDifficulty);
			if(freeplayinstPlaying != curSelected)
			{
				if(sys.FileSystem.exists(Paths.inst(songLowercase + '/' + poop)) || sys.FileSystem.exists(Paths.json(songLowercase + '/' + poop)) || sys.FileSystem.exists(Paths.modsJson(songLowercase + '/' + poop))) {
				#if PRELOAD_ALL
                		destroyFreeplayVocals();
				FlxG.sound.music.volume = 0;
				Paths.currentModDirectory = songs[curSelected].folder;
				PlayState.SONG = Song.loadFromJson(poop, songs[curSelected].songName.toLowerCase());

				var listenin:String = 'Freeplay - Listening: ' + songs[curSelected].songName + '';
				Application.current.window.title = Main.appTitle + ' - ' + listenin;
				DiscordClient.changePresence(listenin, null);

		       		PlayState.SONG.needsVoices ? {
		       			vocals = new FlxSound().loadEmbedded(Paths.voices(PlayState.SONG.song, PlayState.SONG.postfix));
		       	 		vocals2 = new FlxSound().loadEmbedded(Paths.voices(PlayState.SONG.song, PlayState.SONG.postfix + '-Second'));
        			} : {
		        		vocals = new FlxSound();
		        		vocals2 = new FlxSound();
		        	}
         
				FlxG.sound.list.add(vocals);
				FlxG.sound.list.add(vocals2);
				FlxG.sound.playMusic(Paths.inst(PlayState.SONG.song, PlayState.SONG.postfix), 0.7);
				trace('Started listening to song: "' + PlayState.SONG.song + PlayState.SONG.postfix + '"');
				vocals.play();
				vocals.persist = true;
				vocals.looped = true;
				vocals.volume = 0.7;
				vocals2.play();
				vocals2.persist = true;
				vocals2.looped = true;
				vocals2.volume = 0.7;
				Conductor.changeBPM(PlayState.SONG.bpm);
				freeplayinstPlaying = curSelected;
				#end
			} else 
			    {
				    trace(poop + '\'s .ogg does not exist!');
					FlxG.sound.play(Paths.sound('scrollMenu'));
				    FlxG.camera.shake(0.04, 0.04);
				    var funnyText = new FlxText(12, FlxG.height - 24, 0, "Invalid Song!");
				    funnyText.scrollFactor.set();
				    funnyText.screenCenter();
					funnyText.cameras = [camINTERFACE];
				    funnyText.x = FlxG.width/2 - 250;
				    funnyText.y = FlxG.height/2 - 64;
				    funnyText.setFormat("VCR OSD Mono", 64, FlxColor.RED, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
				    add(funnyText);
				    FlxTween.tween(funnyText, {alpha: 0}, 0.6, {
				    	onComplete: function(tween:FlxTween)
				    	{
				    		funnyText.destroy();
				    	}
				    });
			    } 
			}
		}

		else if (accepted || (forMouseClick == null && FlxG.mouse.justPressed))
		{
			acceptSong();
		}
		else if(controls.RESET)
		{
			persistentUpdate = false;
			openSubState(new ResetScoreSubState(songs[curSelected].songName, curDifficulty, songs[curSelected].songCharacter));
			FlxG.sound.play(Paths.sound('scrollMenu'));
		}
		call('onUpdatePost', [elapsed]);
	}

	function acceptSong()
	{
		if (!acceptedSong)
		{
		    persistentUpdate = false;
		    var songLowercase:String = Paths.formatToSongPath(songs[curSelected].songName);
		    var songString:String = Highscore.formatSong(songLowercase, curDifficulty);
	    
		    call('onAcceptSong', [songLowercase, songString]);

			if(sys.FileSystem.exists(Paths.modsJson(songLowercase + '/' + songString)) || sys.FileSystem.exists(Paths.json(songLowercase + '/' + songString))) 
			{
			        trace(songString);
        
			        trace('Loading Song: "' + songString + '" on ' + Utils.difficultyString());
            
		            acceptedSong = true;
		            FlxG.sound.music.volume = 0;
		            destroyFreeplayVocals();
		            		
		            ChooseSound = new FlxSound().loadEmbedded(Paths.sound('confirmMenu'));
		            ChooseSound.play();
		            ChooseSound.looped = false;
            
		            //Utils.checkExistingChart(songLowercase, poop);
		            PlayState.SONG = Song.loadFromJson(songString, songLowercase);
		            PlayState.isStoryMode = false;
		            PlayState.storyDifficulty = curDifficulty;
			        
		            trace('Set Current week to: "' + WeekData.getWeekFileName() + '"');
		            if(colorTween != null) {
		            	colorTween.cancel();
		            }
        
			        for (item in grpSongs.members)
			        	if (item.targetY == 0)
			        		FlxFlicker.flicker(item, 1.05, 0.06, false, false);
			        	else
			        		FlxTween.tween(item, {alpha: 0}, 0.4, {ease: FlxEase.linear});
			        
			        FlxFlicker.flicker(iconArray[curSelected], 1.05, 0.06, false, false);

			        for (i in 0...iconArray.length)
			        	if (i != curSelected)
			        		FlxTween.tween(iconArray[i], {alpha: 0}, 0.42, {ease: FlxEase.linear});
            
		            LoadingState.amTake = false;
		            new FlxTimer().start(1.1, function(tmr:FlxTimer)
		            {	
	                    if (FlxG.keys.pressed.SHIFT){
	                    	LoadingState.loadAndSwitchState(new ChartingState());
	                    }else{
	                    	LoadingState.loadAndSwitchState(new PlayState());
	                    }
	                     
                    });
			} else {
				trace(songString + '.json does not exist!');
				FlxG.sound.play(Paths.sound('scrollMenu'));
				FlxG.camera.shake(0.04, 0.04);
				var funnyText = new FlxText(12, FlxG.height - 24, 0, "Invalid JSON!");
				funnyText.scrollFactor.set();
				funnyText.screenCenter();
				funnyText.cameras = [camINTERFACE];
				funnyText.x = FlxG.width/2 - 250;
				funnyText.y = FlxG.height/2 - 64;
				funnyText.setFormat("VCR OSD Mono", 64, FlxColor.RED, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
				add(funnyText);
				FlxTween.tween(funnyText, {alpha: 0}, 0.6, {
					onComplete: function(tween:FlxTween)
					{
						funnyText.destroy();
					}
				});
			}
		    call('onAcceptSongPost', [songLowercase, songString]);
	    }
	}

	override function beatHit()
	{
		super.beatHit();

		if (!acceptedSong) bopOnBeat();
	}

	override function sectionHit()
	{
		super.sectionHit();

		if (PlayState.SONG.notes[curSection] != null && PlayState.SONG.notes[curSection].changeBPM)
			Conductor.changeBPM(PlayState.SONG.notes[curSection].bpm);
	}

	function bopOnBeat()
	{
		FlxG.camera.zoom += 0.015;
		camZoom = FlxTween.tween(FlxG.camera, {zoom: 1}, 0.15);

		freeplayinstPlaying >= 0 ? {
			if (Math.abs(FlxG.sound.music.time - (Conductor.songPosition - Conductor.offset)) > 20 || (PlayState.SONG.needsVoices && Math.abs(vocals.time - (Conductor.songPosition - Conductor.offset)) > 20))
				resyncVocals();

			//iconArray[freeplayinstPlaying].doIconSize();
			//iconArray[freeplayinstPlaying].doIconAnim(); //Reasons - PurSnake
		} : {
			/*for (i in 0...iconArray.length)
			{
				iconArray[i].doIconSize();
				iconArray[i].doIconAnim(); //Reasons - PurSnake
			}*/
		}
	}
	
	public static function destroyFreeplayVocals() {
		if(vocals != null) {
			vocals.stop();
			vocals.destroy();
		}
		vocals = null;

		if(vocals2 != null) {
			vocals2.stop();
			vocals2.destroy();
		}
		vocals2 = null;
	}

	override function destroy() {
		freeplayinstPlaying = -1;
		super.destroy();
	}

	function changeDiff(change:Int = 0)
	{
		if (!acceptedSong)
		{
		    call('onChangeDiff', [change]);
		    curDifficulty = Math.round(Math.max(0, Math.min(curDifficulty + change, Utils.difficulties.length - 1)));
    
		    lastDifficultyName = Utils.difficulties[curDifficulty];
    
		    #if !switch
		    intendedScore = Highscore.getScore(songs[curSelected].songName, curDifficulty);
		    intendedRating = Highscore.getRating(songs[curSelected].songName, curDifficulty);
		    #end
    
		    PlayState.storyDifficulty = curDifficulty;
			if(Utils.difficulties.length > 1) {
				diffText.text = (curDifficulty == 0 ? '> ' : '< ') + Utils.difficultyString() + (curDifficulty == Utils.difficulties.length - 1 ? ' <' : ' >');
			} else {
				diffText.text = Utils.difficultyString();
			}
    
		    positionHighscore();
		    call('onChangeDiffPost', [change]);
		}
	}

	function changeSelection(change:Int = 0, playSound:Bool = true)
	{
		if (!acceptedSong)
		{
		    call('onChangeSelection', [change, playSound]);
		    if(playSound) FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
    
		    curSelected += change;
    
		    if (curSelected < 0)
		    	curSelected = songs.length - 1;
		    if (curSelected >= songs.length)
		    	curSelected = 0;
		    	
		    var newColor:Int = songs[curSelected].color;
		    if(newColor != intendedColor) {
		    	if(colorTween != null) {
		    		colorTween.cancel();
		    	}
		    	intendedColor = newColor;
		    	colorTween = FlxTween.color(bg, 0.4, bg.color, intendedColor, {
		    		onComplete: function(twn:FlxTween) {
		    			colorTween = null;
		    		}
		    	});
		    }
    
		    #if !switch
		    intendedScore = Highscore.getScore(songs[curSelected].songName, curDifficulty);
		    intendedRating = Highscore.getRating(songs[curSelected].songName, curDifficulty);
		    #end
    
		    var bullShit:Int = 0;
    
		    for (i in 0...iconArray.length)
		    {
		    	iconArray[i].alpha = 0.6;
				//iconArray[i].animation.curAnim.curFrame = 0;
		    }
    
		    iconArray[curSelected].alpha = 1;
    
		    for (item in grpSongs.members)
		    {
		    	item.targetY = bullShit - curSelected;
		    	bullShit++;
    
		    	item.alpha = 0.6;
    
		    	if (item.targetY == 0) item.alpha = 1;
		    }
		    
		    Paths.currentModDirectory = songs[curSelected].folder;
		    PlayState.storyWeek = songs[curSelected].week;
    
		    Utils.difficulties = Utils.defaultDifficulties.copy();
		    var diffStr:String = WeekData.getCurrentWeek().difficulties;
		    if(diffStr != null) diffStr = diffStr.trim(); //Fuck you HTML5
    
			if(diffStr != null && diffStr.length > 0)
			{
				var diffs:Array<String> = diffStr.split(',');
				var i:Int = diffs.length - 1;
				while (i > 0)
				{
					if(diffs[i] != null)
					{
						diffs[i] = diffs[i].trim();
						if(diffs[i].length < 1) diffs.remove(diffs[i]);
					}
					--i;
				}
    
				if(diffs.length > 0 && diffs[0].length > 0) Utils.difficulties = diffs;
			}
		    
			curDifficulty = Math.round(Math.max(0, Utils.defaultDifficulties.indexOf(Utils.defaultDifficulty)));
			Utils.difficulties.contains(Utils.defaultDifficulty) ? curDifficulty = Math.round(Math.max(0, Utils.defaultDifficulties.indexOf(Utils.defaultDifficulty))) : curDifficulty = 0;

			var newPos:Int = Utils.difficulties.indexOf(lastDifficultyName);
			//trace('Pos of ' + lastDifficultyName + ' is ' + newPos);
			if(newPos > -1) curDifficulty = newPos;

		    call('onChangeSelectionPost', [change, playSound]);
		}
	}

	private function positionHighscore() {
		countText.text = "(" + ((curSelected + 1) + "/" + songs.length) + ")";

		scoreText.x = FlxG.width - scoreText.width - 6;

		scoreBG.scale.x = FlxG.width - scoreText.x + 6;
		scoreBG.x = FlxG.width - (scoreBG.scale.x / 2);
		diffText.x = Std.int(scoreBG.x + (scoreBG.width / 2));
		diffText.x -= diffText.width / 2;

		countText.x = Std.int(scoreBG.x - (scoreBG.scale.x / 2));
		countText.x -= countText.width;
	}

	function resyncVocals():Void
	{
		vocals.pause();
		vocals2.pause();

		FlxG.sound.music.play();
		Conductor.songPosition = FlxG.sound.music.time;
		vocals.time = Conductor.songPosition;
		vocals.play();

		vocals2.time = Conductor.songPosition;
		vocals2.play();

		call('onResyncVocals', []);
	}
}

class SongMetadata
{
	public var songName:String = "";
	public var week:Int = 0;
	public var songCharacter:String = "";
	public var iconProperties:IconProperties = {
		type: "duo",
		offsets: [0, 0],
		scale: 1
	};
	public var color:Int = -7179779;
	public var folder:String = "";

	public function new(song:String, week:Int, songCharacter:String, color:Int, iconProperties:IconProperties)
	{
		this.songName = song;
		this.week = week;
		this.songCharacter = songCharacter;
		this.iconProperties = iconProperties;
		this.color = color;
		this.folder = Paths.currentModDirectory;
		if(this.folder == null) this.folder = '';
	}
}
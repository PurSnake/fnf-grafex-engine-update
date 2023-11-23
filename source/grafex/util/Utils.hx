package grafex.util;

import flixel.math.FlxMath;
import grafex.system.Paths;
import grafex.system.song.Song;
import grafex.states.playstate.PlayState;
import flixel.FlxG;
import flixel.tweens.FlxTween;
import lime.utils.Assets;

#if sys
import sys.io.File;
import sys.FileSystem;
#else
import openfl.utils.Assets;
#end

import flixel.util.FlxSave;

import sys.io.Process;

using StringTools;

class Utils
{
	public static var defaultDifficulties:Array<String> = [
		'Easy',
		'Normal',
		'Hard'
	];
	public static var defaultDifficulty:String = 'Normal'; //The chart that has no suffix and starting difficulty on Freeplay/Story Mode

	public static var difficulties:Array<String> = [];

	inline public static function quantize(f:Float, interval:Float){
		return Std.int((f+interval/2)/interval)*interval;
	}

	public static function getDifficultyFilePath(num:Null<Int> = null)
	{
		if(num == null) num = PlayState.storyDifficulty;

		var fileSuffix:String = difficulties[num];
		
		if(fileSuffix != defaultDifficulty) fileSuffix = '-' + fileSuffix;
		else fileSuffix = '';

		return Paths.formatToSongPath(fileSuffix);
	}

	public static function difficultyString(diff:Int = null):String
	{
		var difficulty = diff;
		if (difficulty == null) difficulty = PlayState.storyDifficulty;
		return difficulties[difficulty].toUpperCase();
	}

	inline public static function boundTo(value:Float, min:Float, max:Float):Float {
		return Math.max(min, Math.min(max, value));
	}

	inline public static function capitalize(text:String)
		return text.charAt(0).toUpperCase() + text.substr(1);

	inline public static function coolTextFile(path:String):Array<String>
	{
		var daList:String = null;
		#if (sys && MODS_ALLOWED)
		var formatted:Array<String> = path.split(':'); //prevent "shared:", "preload:" and other library names on file path
		path = formatted[formatted.length-1];
		if(FileSystem.exists(path)) daList = File.getContent(path);
		#else
		if(Assets.exists(path)) daList = Assets.getText(path);
		#end
		return daList != null ? listFromString(daList) : [];
	}

	inline public static function colorFromString(color:String):FlxColor
	{
		var hideChars = ~/[\t\n\r]/;
		var color:String = hideChars.split(color).join('').trim();
		if(color.startsWith('0x')) color = color.substring(color.length - 6);

		var colorNum:Null<FlxColor> = FlxColor.fromString(color);
		if(colorNum == null) colorNum = FlxColor.fromString('#$color');
		return colorNum != null ? colorNum : FlxColor.WHITE;
	}

	inline public static function listFromString(string:String):Array<String>
	{
		var daList:Array<String> = [];
		daList = string.trim().split('\n');

		for (i in 0...daList.length)
			daList[i] = daList[i].trim();

		return daList;
	}

	inline public static function openFolder(folder:String, absolute:Bool = false) {
		#if sys
			if(!absolute) folder =  Sys.getCwd() + '$folder';

			folder = folder.replace('/', '\\');
			if(folder.endsWith('/')) folder.substr(0, folder.length - 1);

			#if linux
			var command:String = 'explorer.exe';
			#else
			var command:String = '/usr/bin/xdg-open';
			#end
			Sys.command(command, [folder]);
			trace('$command $folder');
		#else
			FlxG.error("Platform is not supported for CoolUtil.openFolder");
		#end
	}

	public static function dominantColor(sprite:flixel.FlxSprite):Int
		{
			var countByColor:Map<Int, Int> = [];
			for (col in 0...sprite.frameWidth)
			{
				for (row in 0...sprite.frameHeight)
				{
					var colorOfThisPixel:Int = sprite.pixels.getPixel32(col, row);
					if (colorOfThisPixel != 0)
					{
						if (countByColor.exists(colorOfThisPixel))
						{
							countByColor[colorOfThisPixel] = countByColor[colorOfThisPixel] + 1;
						}
						else if (countByColor[colorOfThisPixel] != 13520687 - (2 * 13520687))
						{
							countByColor[colorOfThisPixel] = 1;
						}
					}
				}
			}
			var maxCount = 0;
			var maxKey:Int = 0; // after the loop this will store the max color
			countByColor[flixel.util.FlxColor.BLACK] = 0;
			for (key in countByColor.keys())
			{
				if (countByColor[key] >= maxCount)
				{
					maxCount = countByColor[key];
					maxKey = key;
				}
			}
			return maxKey;
		}

	public static function numberArray(max:Int, ?min = 0):Array<Int>
	{
		var dumbArray:Array<Int> = [];
		for (i in min...max)
		{
			dumbArray.push(i);
		}
		return dumbArray;
	}

	public static function formatString(string:String):String
	{
		var split:Array<String> = string.split('-');
		var formattedString:String = '';
		for (i in 0...split.length)
		{
			var piece:String = split[i];
			var allSplit = piece.split('');
			var firstLetterUpperCased = allSplit[0].toUpperCase();
			var substring = piece.substr(1, piece.length - 1);
			var newPiece = firstLetterUpperCased + substring;
			if (i != split.length - 1)
			{
				newPiece += " ";
			}
			formattedString += newPiece;
		}
		return formattedString;
	}

	//uhhhh does this even work at all? i'm starting to doubt
	public static function precacheSound(sound:String, ?library:String = null):Void {
		Paths.sound(sound, library);
	}

	public static function checkExistingChart(song:String, poop:String)
	{
		if (FileSystem.exists('assets/data/' + song.toLowerCase() + '/' + poop.toLowerCase() + '.json'))
		{
			var json:Dynamic;
	
			try
			{
				json = Assets.getText(Paths.modsJson(song.toLowerCase() + '/' + poop.toLowerCase())).trim();
			}
			catch (e)
			{
				trace("dang! stupid hashlink cant handle an empty file!");
				json = null;
			}
	
			if (json == null)
			{
				trace('aw fuck its null');
				createFakeSong(song);
			}
			else
			{
				trace('found file');
				PlayState.SONG = Song.loadFromJson(poop, song);
			}
		}
		else
		{
			trace('aw fuck its null');
			createFakeSong(song);
		}
	}

    public static function precacheMusic(sound:String, ?library:String = null):Void {
	    Paths.music(sound, library);
	}

	public static function createFakeSong(name:String):Void
	{
		PlayState.SONG = {
			song: name,
			postfix: '',
			composedBy: '',
			notes: [],
			events: [],
			bpm: 100,
			needsVoices: true,
			arrowSkin: '',
			extrasSkin: '',
	        splashSkin: 'noteSplashes',//idk it would crash if i didn't
			player1: 'bf',
			player2: 'dad',
			gfVersion: 'gf',
			stage: 'stage',
			speed: 1,
			validScore: false
		};
	}

	public static function browserLoad(site:String) {
		#if linux
		Sys.command('/usr/bin/xdg-open', [site]);
		#else
		FlxG.openURL(site);
		#end
	}

	public static function getArtist(song:String) 
	{
		var artistPrefix:String = '';
		switch (song)
		{
            default:
			    artistPrefix = 'Kawai Sprite';
		}	

		return artistPrefix;
	}

	public static function cameraZoom(target, zoomLevel, speed, style, type)
	{
		FlxTween.tween(target, {zoom: zoomLevel}, speed, {ease: style, type: type});
	}

	public static function camLerpShit(lerp:Float):Float
	{
		return lerp * (FlxG.elapsed / (1 / 60));
	}

	/*
	* just lerp that does camLerpShit for u so u dont have to do it every time
	*/
	public static function coolLerp(a:Float, b:Float, ratio:Float):Float
	{
		return FlxMath.lerp(a, b, camLerpShit(ratio));
	}

	public static inline function addZeros(str:String, num:Int) {
		while(str.length < num) str = '0${str}';
		return str;
	}

	public static inline function getFPSRatio(ratio:Float):Float {
		return FlxMath.bound(ratio * 60 * FlxG.elapsed, 0, 1);
	}

	public static function getSizeString(size:Float):String {
		var labels = ["B", "KB", "MB", "GB", "TB"];
		var rSize:Float = size;
		var label:Int = 0;
		while(rSize > 1024 && label < labels.length-1) {
			label++;
			rSize /= 1024;
		}
		return '${Std.int(rSize) + "." + addZeros(Std.string(Std.int((rSize % 1) * 100)), 2)}${labels[label]}';
	}
	
	public static function truncateFloat(number:Float, precision:Int):Float
	{
		var num = number;
		num = num * Math.pow(10, precision);
		num = Math.round(num) / Math.pow(10, precision);
		return num;
	}

	public static function getUsername():String
	{
		#if windows
		return Sys.environment()["USERNAME"].trim();
		#elseif (linux || macos)
		return Sys.environment()["USER"].trim();
		#else
		return 'Dude';
		#end
	}
	
	public static function GCD(a, b)
	{
		return b == 0 ? FlxMath.absInt(a) : GCD(b, a % b);
	}

	public static inline function fpsLerp(v1:Float, v2:Float, ratio:Float):Float {
		return FlxMath.lerp(v1, v2, getFPSRatio(ratio));
	}

	public static function getSavePath(folder:String = 'PurSnake'):String {
	    @:privateAccess
	    return #if (flixel < "5.0.0") folder #else FlxG.stage.application.meta.get('company')
	    	+ '/'
	    	+ FlxSave.validate(FlxG.stage.application.meta.get('file')) #end;
	}

	public static var programList:Array<String> = [
		'obs',
		'bdcam',
		'fraps',
		'xsplit', // TIL c# program
		'hycam2', // hueh
		'twitchstudio' // why
	];

	public static function isRecording():Bool
	{
		var isOBS:Bool = false;

		try
		{
			#if windows
			var taskList:Process = new Process('tasklist');
			#elseif (linux || macos)
			var taskList:Process = new Process('ps --no-headers');
			#end
			var readableList:String = taskList.stdout.readAll().toString().toLowerCase();

			for (i in 0...programList.length)
			{
				if (readableList.contains(programList[i]))
					isOBS = true;
			}

			taskList.close();
			readableList = '';
		}
		catch (e)
		{
			// If for some reason the game crashes when trying to run Process, just force OBS on
			// in case this happens when they're streaming.
			isOBS = true;
		}

		return isOBS;
	}



}

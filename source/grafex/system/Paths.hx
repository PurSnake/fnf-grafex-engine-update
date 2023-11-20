package grafex.system;

import flixel.graphics.frames.FlxFrame.FlxFrameAngle;
import openfl.system.System;
import flixel.FlxG;
import flixel.graphics.frames.FlxAtlasFrames;
import openfl.utils.AssetType;
import openfl.utils.Assets as OpenFlAssets;
import lime.utils.Assets;
import grafex.util.ClientPrefs;
import grafex.util.Utils;
#if sys
import sys.io.File;
import sys.FileSystem;
#end
import flixel.graphics.FlxGraphic;
import openfl.display.BitmapData;
import haxe.Json;
import haxe.Http;
import haxe.io.BytesOutput;

import openfl.display3D.textures.Texture;
import openfl.display3D.textures.RectangleTexture;

import flash.media.Sound;

using StringTools;

class Paths
{
	inline public static var SOUND_EXT = #if web "mp3" #else "ogg" #end;
	inline public static var VIDEO_EXT = "mp4";

	public static var scriptExts:Array<String> = ['hx', 'hxs', 'hscript', 'hxc'];

	#if MODS_ALLOWED
	#if (haxe >= "4.0.0")
	public static var customImagesLoaded:Map<String, Bool> = new Map();
	public static var customSoundsLoaded:Map<String, Sound> = new Map();
	#else
	public static var customImagesLoaded:Map<String, Bool> = new Map<String, Bool>();
	public static var customSoundsLoaded:Map<String, Sound> = new Map<String, Sound>();
	#end
	
	public static var ignoreModFolders:Array<String> = [
		'characters',
		'custom_events',
		'custom_notetypes',
		'lua_characters',
		'mechanics',
		'data',
		'songs',
		'music',
		'sounds',
		'states',
        'shaders',
		'videos',
		'images',
		'stages',
		'weeks',
		'fonts',
		'scripts'
	];
	#end

	public static function destroyLoadedImages(ignoreCheck:Bool = false) {
		#if MODS_ALLOWED
		if(!ignoreCheck && ClientPrefs.imagesPersist) return; //If there's 20+ images loaded, do a cleanup just for preventing a crash

		for (key in customImagesLoaded.keys()) {
			var graphic:FlxGraphic = FlxG.bitmap.get(key);
			if(graphic != null) {
				graphic.bitmap.dispose();
				graphic.destroy();
				FlxG.bitmap.removeByKey(key);
			}
		}
		Paths.customImagesLoaded.clear();
		#end
	}

	public static function excludeAsset(key:String) {
		if (!dumpExclusions.contains(key))
			dumpExclusions.push(key);
	}

	public static var dumpExclusions:Array<String> = [];
	/// haya I love you for the base cache dump I took to the max

	public static function clearUnusedMemory() {
		// clear non local assets in the tracked assets list
		for (key in currentTrackedAssets.keys()) {
			// if it is not currently contained within the used local assets
			if (!localTrackedAssets.contains(key) 
				&& !dumpExclusions.contains(key)) {
				// get rid of it
				var obj = currentTrackedAssets.get(key);
				@:privateAccess
				if (obj != null) {

					if (currentTrackedTextures.exists(key))
					{
						var texture = currentTrackedTextures.get(key);
						texture.dispose();
						texture = null;
						currentTrackedTextures.remove(key);
					}
					openfl.Assets.cache.removeBitmapData(key);
					FlxG.bitmap._cache.remove(key);
					obj.destroy();
					currentTrackedAssets.remove(key);
				}


			}
		}
		// run the garbage collector for good measure lmfao
		System.gc();
	}

	// define the locally tracked assets
	public static var localTrackedAssets:Array<String> = [];
	public static function clearStoredMemory(?cleanUnused:Bool = false) {
		// clear anything not in the tracked assets list
		@:privateAccess
		for (key in FlxG.bitmap._cache.keys())
		{
			var obj = FlxG.bitmap._cache.get(key);
			if (obj != null && !currentTrackedAssets.exists(key)) {
				if (currentTrackedTextures.exists(key))
				{
					var texture = currentTrackedTextures.get(key);
					texture.dispose();
					texture = null;
					currentTrackedTextures.remove(key);
				}

				openfl.Assets.cache.removeBitmapData(key);
				FlxG.bitmap._cache.remove(key);
				obj.destroy();
				currentTrackedAssets.remove(key);
			}
		}

		// clear all sounds that are cached
		for (key in currentTrackedSounds.keys()) {
			if (!localTrackedAssets.contains(key) 
			&& !dumpExclusions.contains(key) && key != null) {
				Assets.cache.clear(key);
				currentTrackedSounds.remove(key);
			}
		}	
		// flags everything to be cleared out next unused memory clear
		localTrackedAssets = [];
		openfl.Assets.cache.clear("songs");
	}

    static public var currentModDirectory:String = '';

	// level we're loading
	static var currentLevel:String = null;
	static var previousLevel:String = null;
	static var stageShitFUCK:String = '';

	// set the current level top the condition of this function if called
	static public function setCurrentLevel(name:String)
	{
		if (currentLevel != name) {
			previousLevel = currentLevel;
			currentLevel = name.toLowerCase();
		}
	}

	static public function revertCurrentLevel() {
		var tempCurLevel = currentLevel;
		currentLevel = previousLevel;
		previousLevel = tempCurLevel;
	}

	static public function doStageFuckinShitOH(?doit:String = '') {
		stageShitFUCK = doit;
	}

	public static function getPath(file:String, ?type:AssetType = TEXT, ?library:Null<String> = null, ?modsAllowed:Bool = false):String
	{
		file = file.replace("\\", "/");
		while(file.contains("//")) {
			file = file.replace("//", "/");
		}

		#if MODS_ALLOWED
		if(modsAllowed)
		{
			var modded:String = modFolders(file);
			if(FileSystem.exists(modded)) return modded;
		}
		#end
		
		if (library != null)
			return getLibraryPath(file, library);

		if (currentLevel != null)
		{
			var levelPath:String = '';
			if(currentLevel != 'shared') {
				levelPath = getLibraryPathForce(file, currentLevel);
				if (OpenFlAssets.exists(levelPath, type))
					return levelPath;
			}

			levelPath = getLibraryPathForce(file, "shared");
			if (OpenFlAssets.exists(levelPath, type))
				return levelPath;
		}

		return getPreloadPath(file);
	}

        public static function download(leUrl:String, path:String):Void {
            var http = new Http(leUrl);
            var output:BytesOutput = new BytesOutput();
            http.customRequest(false, output);
            File.saveBytes(path + '.downloaded', output.getBytes());
        }

	static public function getLibraryPath(file:String, library = "preload")
	{
		return if (library == "preload" || library == "default") getPreloadPath(file); else getLibraryPathForce(file, library);
	}

	inline static function getLibraryPathForce(file:String, library:String, ?level:String)
	{
		if(level == null) level = library;
		var returnPath = '$library:assets/$level/$file';
		return returnPath;
	}

	inline public static function getPreloadPath(file:String = '')
	{
		return 'assets' + stageShitFUCK +'/$file';
	}

	inline static public function file(file:String, type:AssetType = TEXT, ?library:String)
	{
		return getPath(file, type, library);
	}

	inline static public function txt(key:String, ?library:String)
	{
		return getPath('data/$key.txt', TEXT, library);
	}

	inline static public function xml(key:String, ?library:String)
	{
		return getPath('data/$key.xml', TEXT, library);
	}

	inline static public function json(key:String, ?library:String)
	{
		return getPath('data/$key.json', TEXT, library);
	}

	inline static public function shaderFragment(key:String, ?library:String)
	{
		return getPath('shaders/$key.frag', TEXT, library);
	}
	inline static public function shaderVertex(key:String, ?library:String)
	{
		return getPath('shaders/$key.vert', TEXT, library);
	}

	inline static public function lua(key:String, ?library:String)
	{
		return getPath('$key.lua', TEXT, library);
	}

	static public function video(key:String)
	{
		#if MODS_ALLOWED
		var file:String = modsVideo(key);
		if(FileSystem.exists(file)) {
			return file;
		}
		#end
		return 'assets/videos/$key.$VIDEO_EXT';
	}

	static public function sound(key:String, ?library:String):Sound
	{
		var sound:Sound = returnSound('sounds', key, library);
		return sound;
	}
	
	inline static public function soundRandom(key:String, min:Int, max:Int, ?library:String)
	{
		return sound(key + FlxG.random.int(min, max), library);
	}

	inline static public function music(key:String = 'freakyMenu', ?library:String, where:String = 'music'):Sound
	{
		var file:Sound = returnSound(where, key, library);
		return file;
	}

	inline static public function chart(song:String, key:String)
	{
		return getPath('data/$song/$key.json', TEXT);
	}

	inline static public function voices(song:String, ?postfix:String = ''):Any
	{
		var songKey:String = '${formatToSongPath(song)}/Voices'+postfix;
		trace(songKey);
		var voices = returnSound('songs', songKey);
		return voices;
	}

	inline static public function inst(song:String, ?postfix:String = ''):Any
	{
		var songKey:String = '${formatToSongPath(song)}/Inst'+postfix;
		trace(songKey);
		var inst = returnSound('songs', songKey);
		return inst;
	}

	#if MODS_ALLOWED
	public static var currentTrackedSounds:Map<String, Sound> = [];
	inline static private function returnSongFile(file:String):Sound
	{
		if(FileSystem.exists(file)) {
			if(!customSoundsLoaded.exists(file)) {
				customSoundsLoaded.set(file, Sound.fromFile(file));
			}
			return customSoundsLoaded.get(file);
		}
		return null;
	}
	#end

	static public function image(key:String, ?library:String, ?gpuRender:Bool = true):FlxGraphic
	{
		var bitmap:BitmapData = null;
		var file:String = null;

		#if MODS_ALLOWED
		file = modsImages(key);
		if (currentTrackedAssets.exists(file))
		{
			localTrackedAssets.push(file);
			return currentTrackedAssets.get(file);
		}
		else if (FileSystem.exists(file))
			bitmap = BitmapData.fromFile(file);
		else
		#end
		{
			file = getPath('images/$key.png', IMAGE, library);
			if (currentTrackedAssets.exists(file))
			{
				localTrackedAssets.push(file);
				return currentTrackedAssets.get(file);
			}
			else if (OpenFlAssets.exists(file, IMAGE))
				bitmap = OpenFlAssets.getBitmapData(file);
		}

		if (bitmap != null)
		{
			localTrackedAssets.push(file);
			if (ClientPrefs.gpuRender && gpuRender)
			{
				var texture:RectangleTexture = FlxG.stage.context3D.createRectangleTexture(bitmap.width, bitmap.height, BGRA, true);
				texture.uploadFromBitmapData(bitmap);
				bitmap.image.data = null;
				bitmap.dispose();
				bitmap.disposeImage();
				bitmap = BitmapData.fromTexture(texture);
			}
			var newGraphic:FlxGraphic = FlxGraphic.fromBitmapData(bitmap, false, file);
			newGraphic.persist = true;
			newGraphic.destroyOnNoUse = false;
			currentTrackedAssets.set(file, newGraphic);
			return newGraphic;
		}

		trace('oh no its returning null NOOOO ($file)');
		return null;
	}
	
	static public function getTextFromFile(key:String, ?ignoreMods:Bool = false):String
	{
		#if sys
		#if MODS_ALLOWED
		if (!ignoreMods && FileSystem.exists(modFolders(key)))
			return File.getContent(modFolders(key));
		#end

		if (FileSystem.exists(getPreloadPath(key)))
			return File.getContent(getPreloadPath(key));

		if (currentLevel != null)
		{
			var levelPath:String = '';
			if(currentLevel != 'shared') {
				levelPath = getLibraryPathForce(key, currentLevel);
				if (FileSystem.exists(levelPath))
					return File.getContent(levelPath);
			}

			levelPath = getLibraryPathForce(key, 'shared');
			if (FileSystem.exists(levelPath))
				return File.getContent(levelPath);
		}
		#end
		var path:String = getPath(key, TEXT);
		if(FileSystem.exists(path)) return File.getContent(path);
		return null;
	}
		
	inline static public function font(key:String)
	{
		#if MODS_ALLOWED
		var file:String = modsFont(key);
		if(FileSystem.exists(file)) {
			return file;
		}
		#end
		return 'assets/fonts/$key';
	}


	public static function fileExists(key:String, type:AssetType, ?ignoreMods:Bool = false, ?library:String = null)
	{
		#if MODS_ALLOWED
		if(!ignoreMods)
		{
			for(mod in getGlobalMods())
				if (FileSystem.exists(mods('$mod/$key')))
					return true;

			if (FileSystem.exists(mods(currentModDirectory + '/' + key)) || FileSystem.exists(mods(key)))
				return true;
		}
		#end

		//if(OpenFlAssets.exists(getPath(key, type, library, false))) {
		if (FileSystem.exists(getPath(key, type, library, false))) {
			return true;
		}
		return false;
	}

	static public function hxModule(key:String, ?library:String)
	{
		#if MODS_ALLOWED
		//var file:String = modFolders('$key.hx');

		//if(fileExists('$key.hx', TEXT))
		if(FileSystem.exists(mods(currentModDirectory + '/' + key + '.hx')) || FileSystem.exists(mods('$key.hx'))) {
			return modFolders('$key.hx');
		}
		#end

        	return 'assets/$key.hx';
	}

	// less optimized but automatic handling
	static public function getAtlas(key:String, ?library:String = null):FlxAtlasFrames
	{
		#if MODS_ALLOWED
		if(FileSystem.exists(modsXml(key)) || OpenFlAssets.exists(getPath('images/$key.xml', library), TEXT))
		#else
		if(OpenFlAssets.exists(getPath('images/$key.xml', library)))
		#end
		{
			return getSparrowAtlas(key, library);
		}
		return getPackerAtlas(key, library);
	}


	inline static public function getSparrowAtlas(key:String, ?library:String = null, ?gpuRender:Bool = true):FlxAtlasFrames
	{
		#if MODS_ALLOWED
		var imageLoaded:FlxGraphic = image(key, library, gpuRender);
		var xmlExists:Bool = false;
		if(FileSystem.exists(modsXml(key))) {
			xmlExists = true;
		}

		return FlxAtlasFrames.fromSparrow((imageLoaded != null ? imageLoaded : image(key, library, gpuRender)), (xmlExists ? File.getContent(modsXml(key)) : file('images/$key.xml', library)));
		#else
		return FlxAtlasFrames.fromSparrow(image(key, library, gpuRender), file('images/$key.xml', library));
		#end
	}

	inline static public function getPackerAtlas(key:String, ?library:String = null, ?gpuRender:Bool = true)
	{
		#if MODS_ALLOWED
		var imageLoaded:FlxGraphic = image(key, library, gpuRender);
		var txtExists:Bool = false;
		if(FileSystem.exists(modsTxt(key))) {
			txtExists = true;
		}
	
		return FlxAtlasFrames.fromSpriteSheetPacker((imageLoaded != null ? imageLoaded : image(key, library, gpuRender)), (txtExists ? File.getContent(modsTxt(key)) : file('images/$key.txt', library)));
		#else
		return FlxAtlasFrames.fromSpriteSheetPacker(image(key, library, gpuRender), file('images/$key.txt', library));
		#end
	}
	
	inline static public function formatToSongPath(path:String) {
		var invalidChars = ~/[~&\\;:<>#]/;
	    var hideChars = ~/[.,'"%?!]/;
    
		var path = invalidChars.split(path.replace(' ', '-')).join("-");
	    return hideChars.split(path).join("").toLowerCase();
	}
	
	public static var currentTrackedTextures:Map<String, Texture> = [];
    public static var currentTrackedAssets:Map<String, FlxGraphic> = [];
	#if MODS_ALLOWED
	static public function addCustomGraphic(key:String):FlxGraphic {
		if(FileSystem.exists(modsImages(key))) {
			if(!customImagesLoaded.exists(key)) {
				var newBitmap:BitmapData = BitmapData.fromFile(modsImages(key));
				var newGraphic:FlxGraphic = FlxGraphic.fromBitmapData(newBitmap, false, key);
				newGraphic.persist = true;
				FlxG.bitmap.addGraphic(newGraphic);
				customImagesLoaded.set(key, true);
			}
			return FlxG.bitmap.get(key);
		}
		return null;
	}

	
	inline static public function getCharacterIcon(key:String, ?library:String)
	{
		return getPath('icons/icon-' + key + '.png', IMAGE, library);
	}

	inline static public function getCharacterIconXml(key:String, ?library:String)
	{
		return getPath('icons/icon-' + key + '.xml', IMAGE, library);
	}

	inline static public function modsCharts(song:String, key:String) {
		return modFolders('songs/' + song + '/' + key + '.json');
	}
	
	inline static public function mods(key:String = '') {
		return 'mods/' + key;
	}
	
	inline static public function modsFont(key:String) {
		return modFolders('fonts/' + key);
	}

	inline static public function modsJson(key:String) {
		return modFolders('data/' + key + '.json');
	}

	inline static public function modsVideo(key:String) {
		return modFolders('videos/' + key + '.' + VIDEO_EXT);
	}

	inline static public function modsMusic(key:String) {
		return modFolders('music/' + key + '.' + SOUND_EXT);
	}

	inline static public function modsSounds(path:String, key:String) {
		return modFolders(path + '/' + key + '.' + SOUND_EXT);
	}

	inline static public function modsSongs(key:String) {
		return modFolders('songs/' + key + '.' + SOUND_EXT);
	}

	inline static public function modsImages(key:String) {
		return modFolders('images/' + key + '.png');
	}

	inline static public function modsXml(key:String) {
		return modFolders('images/' + key + '.xml');
	}

	inline static public function modsTxt(key:String) {
		return modFolders('images/' + key + '.txt');
	}

    inline static public function modsShaderFragment(key:String, ?library:String)
	{
		return modFolders('shaders/'+key+'.frag');
	}
	inline static public function modsShaderVertex(key:String, ?library:String)
	{
		return modFolders('shaders/'+key+'.vert');
	}

	static public function modFolders(key:String) {
		if(currentModDirectory != null && currentModDirectory.length > 0) {
			var fileToCheck:String = mods(currentModDirectory + stageShitFUCK + '/' + key);
			if(FileSystem.exists(fileToCheck)) {
				return fileToCheck;
			}
		}

		for(mod in getGlobalMods()){
			var fileToCheck:String = mods(mod + stageShitFUCK + '/' + key);
			if(FileSystem.exists(fileToCheck))
				return fileToCheck;

		}
		return 'mods' + stageShitFUCK + '/' + key;
	}


	public static var globalMods:Array<String> = [];

	static public function getGlobalMods()
		return globalMods;

	static public function pushGlobalMods(){ // prob a better way to do this but idc
		globalMods = [];
		if (FileSystem.exists("modsList.txt"))
		{
			var list:Array<String> = Utils.listFromString(File.getContent("modsList.txt"));
			for (i in list)
			{
				var dat = i.split("|");
				if (dat[1] == "1")
				{
					var folder = dat[0];
					var path = Paths.mods(folder + '/pack.json');
					if(FileSystem.exists(path)) {
						try{
							var rawJson:String = File.getContent(path);
							if(rawJson != null && rawJson.length > 0) {
								var stuff:Dynamic = Json.parse(rawJson);
								var global:Bool = Reflect.getProperty(stuff, "runsGlobally");
								if(global)globalMods.push(dat[0]);
							}
						}catch(e:Dynamic){
							trace(e);
						}
					}
				}
			}
		}
		return globalMods;
	}

	static public function getModDirectories():Array<String> {
		var list:Array<String> = [];
		var modsFolder:String = mods();
		if(FileSystem.exists(modsFolder)) {
			for (folder in FileSystem.readDirectory(modsFolder)) {
				var path = haxe.io.Path.join([modsFolder, folder]);
				if (sys.FileSystem.isDirectory(path) && !ignoreModFolders.contains(folder) && !list.contains(folder)) {
					list.push(folder);
				}
			}
		}
		return list;
	}
	#end

	public static function returnSound(path:String, key:String, ?library:String)
	{
		try // SHOULD FIX SHIT - richTrash21
		{
			#if MODS_ALLOWED
			var file:String = modsSounds(path, key);
			if(FileSystem.exists(file)) {
				if(!currentTrackedSounds.exists(file)) {
					currentTrackedSounds.set(file, Sound.fromFile(file));
				}
				localTrackedAssets.push(key);
				return currentTrackedSounds.get(file);
			}
			#end
			// I hate this so god damn much
			var gottenPath:String = getPath('$path/$key.$SOUND_EXT', SOUND, library);	
			gottenPath = gottenPath.substring(gottenPath.indexOf(':') + 1, gottenPath.length);
			if(!currentTrackedSounds.exists(gottenPath))
			#if MODS_ALLOWED
				currentTrackedSounds.set(gottenPath, Sound.fromFile('./' + gottenPath));
			#else
				{
				var folder:String = '';
				if(path == 'songs') folder = 'songs:';
				currentTrackedSounds.set(gottenPath, OpenFlAssets.getSound(folder + getPath('$path/$key.$SOUND_EXT', SOUND, library)));
			}
			#end
			localTrackedAssets.push(gottenPath);
			return currentTrackedSounds.get(gottenPath);
		}
		catch(e)
		{
			trace(e.message + '\nfucking openfl...');
			return null;
		}
	}

	static public function voiceline(key:String):Sound
	{
		var sound:Sound = returnCutsceneSound('voicelines', key);
		return sound;
	}

	public static function returnCutsceneSound(path:String, key:String) {
		#if MODS_ALLOWED
		var file:String = modsSounds(path, key);
		if(FileSystem.exists(file)) {
			if(!currentTrackedSounds.exists(file)) {
				currentTrackedSounds.set(file, Sound.fromFile(file));
			}
			localTrackedAssets.push(key);
			return currentTrackedSounds.get(file);
		}
		#end
		// I hate this so god damn much
		var gottenPath:String = getPath('$path/$key.$SOUND_EXT', SOUND, 'cutscenes');	
		gottenPath = gottenPath.substring(gottenPath.indexOf(':') + 1, gottenPath.length);
		if(!currentTrackedSounds.exists(gottenPath)) 
		#if MODS_ALLOWED
			currentTrackedSounds.set(gottenPath, Sound.fromFile('./' + gottenPath));
		#else
			currentTrackedSounds.set(gottenPath, OpenFlAssets.getSound(getPath('$path/$key.$SOUND_EXT', SOUND, 'cutscenes')));
		#end
		localTrackedAssets.push(gottenPath);
		return currentTrackedSounds.get(gottenPath);
	}

	inline static public function stage(key:String, ?library:String, ?ext:String = "json")
	{
		return getPath('stages/$key.$ext', TEXT, library);
	}
}

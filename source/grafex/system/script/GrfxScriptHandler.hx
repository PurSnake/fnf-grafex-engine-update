package grafex.system.script;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.FlxCamera;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import grafex.sprites.characters.Character;
import grafex.sprites.HealthIcon;
import grafex.system.notes.Note;
import grafex.system.notes.StrumNote;
import haxe.ds.StringMap;
import hscript.Expr;
import hscript.Interp;
import hscript.Parser;
import grafex.sprites.background.BGSprite;
import grafex.util.RealColor;
import grafex.states.playstate.PlayState;
import grafex.states.substates.GameOverSubstate;
import sys.FileSystem;
import sys.io.File;
import grafex.system.Conductor;
import grafex.util.ClientPrefs;

import flixel.math.FlxMath;
import flixel.util.FlxSave;
import grafex.data.EngineData;
import flixel.FlxObject;

import grafex.util.Utils;
import flixel.util.FlxColor;
import openfl.display.BlendMode;
import flixel.FlxBasic;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.group.FlxGroup.FlxTypedGroup;

import grafex.cutscenes.CutsceneHandler;

using StringTools;

class GrfxScriptHandler {
	public static var parser:Parser = new Parser();

	public static var scriptExts:Array<String> = ['hx', 'hxs', 'hscript', 'hxc'];

	public static function initialize() {
		parser.allowTypes = true;
	}

	public static function loadStateModule(path:String, ?extraParams:StringMap<Dynamic>) {
		trace('Loading haxe file: ${Paths.hxModule(path)}');
		var modulePath:String = Paths.hxModule(path);
		try {
			return new GrfxStateModule(parser.parseString(File.getContent(modulePath), modulePath), extraParams);
		}catch(e:Dynamic){
			return null;
		}
	}

	public static function loadModule(path:String, ?extraParams:StringMap<Dynamic>) {
		trace('Loading haxe file: ${Paths.hxModule(path)}');
		var modulePath:String = Paths.hxModule(path);
		try {
			return new GrfxHxScript(parser.parseString(File.getContent(modulePath), modulePath), extraParams);
		}catch(e:Dynamic){
			return null;
		}
	}
	
	public static function noPathModule(path:String, ?extraParams:StringMap<Dynamic>) {
		trace('Loading haxe file: $path');
		var modulePath:String = path;
		try {
			return new GrfxHxScript(parser.parseString(File.getContent(modulePath), modulePath), extraParams, path);
		}catch(e:Dynamic){
			return null;
		}
	}
}

class GrfxStateModule
{
	public var interp:Interp;
	public var scriptName:String = '';

	public function new(?contents:Expr, ?extraParams:StringMap<Dynamic>, ?name:String) {
		interp = new Interp();

		set('FlxG', FlxG);
		set('FlxSprite', FlxSprite);
		set('FlxCamera', FlxCamera);
		set('FlxTimer', FlxTimer);
		set('FlxTween', FlxTween);
		set('FlxEase', FlxEase);
		set('Conductor', Conductor);
		set('Paths', Paths);
		set('ClientPrefs', ClientPrefs);
		set('StringTools', StringTools);
		set('ClientPrefs', ClientPrefs);
		set('EngineData', EngineData);
		set('CoolUtil', Utils);
		set('Utils', Utils);
		set('FlxMath', FlxMath);
		set('Math', Math);
		set('FlxSave', FlxSave);
		set('FlxBasic', FlxBasic);
		set('FlxObject', FlxObject);
		set('FlxSound', FlxSound);
		set('FlxText', FlxText);
		set('FlxTypedGroup', FlxTypedGroup);
		set("Std", Std);
		set("Type", Type);
		set("Reflect", Reflect);
		set("FileSystem", FileSystem);
		set("File", File);
		set("Achievements", AchievementsGrfx);
		set("CutsceneHandler", CutsceneHandler);

		set('gradeAchievement', function(name:String)
		{
			AchievementsGrfx.setAchievement(name, true);
			return true;
		});

		set('getAchievement', function(name:String)
		{
			return AchievementsGrfx.getAchievement(name);
		});

		set('setAchievement', function(name:String, ?value:Bool = true)
		{
			AchievementsGrfx.setAchievement(name, value);
			return true;
		});

		scriptName = name;
		
		if (extraParams != null) {
			for (i in extraParams.keys())
				set(i, extraParams.get(i));
		}
		set('import', import_type);
		interp.execute(contents);
	}

	public function executeFunc(eventName:String, args:Array<Dynamic>):Dynamic {
		var smthVal:Dynamic = null;
		if (this.exists(eventName))
		    smthVal = Reflect.callMethod(interp.variables, this.get(eventName), args);
		return smthVal;
	} //callOnHscrip("onFunction", [arg1, arg2, arg3]);

	public function get(field:String):Dynamic
		return interp.variables.get(field);

	public function set(field:String, value:Dynamic)
		interp.variables.set(field, value);

	public function exists(field:String):Bool
		return interp.variables.exists(field);

	public function import_type(path:String) {
		var classPackage:Array<String> = path.split('.');
		var name:String = classPackage[classPackage.length - 1];
		set(name, Type.resolveClass(path));
	} 
}

class GrfxHxScript extends GrfxModule
{
    var smthVal:Dynamic;
    public function executeFunc(eventName:String, args:Array<Dynamic>):Dynamic {
        smthVal = null;
		if (this.exists(eventName) && !closed) smthVal = Reflect.callMethod(interp.variables, this.get(eventName), args);
		return smthVal;
    } //callOnHscrip("onFunction", [arg1, array-arg2, some-val-arg3]);
}

class GrfxModule
{
	public var interp:Interp;
	public var assetGroup:String;

	public var closed:Bool = false;
	public var scriptName:String = '';

	public static var Function_Stop:Dynamic = 1;
	public static var Function_Continue:Dynamic = 0;
	public static var Function_StopScript:Dynamic = 2;

	public function new(?contents:Expr, ?extraParams:StringMap<Dynamic>, ?name:String) {
		interp = new Interp();

		set('Function_StopScript', Function_StopScript);
		set('Function_Stop', Function_Stop);
		set('Function_Continue', Function_Continue);

		set('FlxG', FlxG);
		set('FlxSprite', FlxSprite);
		set('PlayState', PlayState);
		set('FlxCamera', FlxCamera);
		set('FlxTimer', FlxTimer);
		set('FlxTween', FlxTween);
		set('FlxEase', FlxEase);
		set('PlayState', PlayState);
		set('game', PlayState.instance);
		set('this', PlayState.instance);
		set('gameOver', GameOverSubstate.instance);
		set('boyfriend', PlayState.instance.boyfriend);
        	set('gf', PlayState.instance.gf);
		set('dad', PlayState.instance.dad);
		set('members', PlayState.instance.members);
		set('SONG', PlayState.SONG);
		set('Conductor', Conductor);
		set('Paths', Paths);
		set('ClientPrefs', ClientPrefs);
		set('Character', Character);
		set('StringTools', StringTools);
		set('ClientPrefs', ClientPrefs);
		set('EngineData', EngineData);
		set('CoolUtil', Utils);
		set('Utils', Utils);
		set('FlxMath', FlxMath);
		set('Math', Math);
		set('FlxSave', FlxSave);
		set('FlxBasic', FlxBasic);
		set('FlxObject', FlxObject);
		set('FlxSound', FlxSound);
		set('FlxText', FlxText);
		set('FlxColor', CustomFlxColor.instance);
		set('FlxTypedGroup', FlxTypedGroup);
		set("Std", Std);
		set("Type", Type);
		set("Reflect", Reflect);
		set("FileSystem", FileSystem);
		set("File", File);

		set('add', function(obj:FlxBasic) PlayState.instance.add(obj));
		set('insert', function(pos:Int, obj:FlxBasic) PlayState.instance.insert(pos, obj));
		set('remove', function(obj:FlxBasic, splice:Bool = false) PlayState.instance.remove(obj, splice));
		set('addBehindGF', function(obj:FlxBasic) PlayState.instance.addBehindGF(obj));
		set('addBehindDad', function(obj:FlxBasic) PlayState.instance.addBehindDad(obj));
		set('addBehindBF', function(obj:FlxBasic) PlayState.instance.addBehindBF(obj));

		set("Achievements", AchievementsGrfx);
		set("CutsceneHandler", CutsceneHandler);

		set('gameTrace', function(text:String, ?color:FlxColor = FlxColor.WHITE)
		{
			errorTrace(text, color);
			return true;
		});

		set('gradeAchievement', function(name:String)
		{
			AchievementsGrfx.setAchievement(name, true);
			return true;
		});

		set('getAchievement', function(name:String)
		{
			return AchievementsGrfx.getAchievement(name);
		});

		#if DEVS_BUILD
		set('setAchievement', function(name:String, ?value:Bool = true)
		{
			AchievementsGrfx.setAchievement(name, value);
			return true;
		});
		#end

		set('addHxScript', function(hxFile:String, ?ignoreAlreadyRunning:Bool = false)
		{
			var cervix = hxFile + ".hx";
			if(hxFile.endsWith(".hx"))cervix=hxFile;
			var doPush = false;
			#if MODS_ALLOWED
			if(FileSystem.exists(Paths.modFolders(cervix)))
			{
				cervix = Paths.modFolders(cervix);
				doPush = true;
			}
			else if(FileSystem.exists(cervix))
			{
				doPush = true;
			}
			else {
				cervix = Paths.getPreloadPath(cervix);
				if(FileSystem.exists(cervix)) {
					doPush = true;
				}
			}
			#else
			cervix = Paths.getPreloadPath(cervix);
			if(Assets.exists(cervix)) {
				doPush = true;
			}
			#end
			if(doPush)
			{
				if(!ignoreAlreadyRunning)
				{
					for (hxInstance in PlayState.instance.hscriptArray)
					{
						if(hxInstance.scriptName == cervix)
						{
							errorTrace('addHxScript: The script "' + cervix + '" is already running!');
							return;
						}
					}
				}
				//PlayState.instance.hscriptArray.push(GrfxScriptHandler.noPathModule(cervix));
				return;
			}
			errorTrace("addHxScript: Script doesn't exist!", FlxColor.RED);
		});

		set('removeHxScript', function(hxFile:String, ?ignoreAlreadyRunning:Bool = false)
		{
			var cervix = hxFile + ".hx";
			if(hxFile.endsWith(".hx"))cervix=hxFile;
			var doPush = false;
			#if MODS_ALLOWED
			if(FileSystem.exists(Paths.modFolders(cervix)))
			{
				cervix = Paths.modFolders(cervix);
				doPush = true;
			}
			else if(FileSystem.exists(cervix))
			{
				doPush = true;
			}
			else {
				cervix = Paths.getPreloadPath(cervix);
				if(FileSystem.exists(cervix)) {
					doPush = true;
				}
			}
			#else
			cervix = Paths.getPreloadPath(cervix);
			if(Assets.exists(cervix)) {
				doPush = true;
			}
			#end

			if(doPush)
			{
				if(!ignoreAlreadyRunning)
				{
					for (hxInstance in PlayState.instance.hscriptArray)
					{
						if(hxInstance.scriptName == cervix)
						{
							PlayState.instance.hscriptArray.remove(hxInstance);
							return;
						}
					}
				}
				return;
			}
			errorTrace("removeHxScript: Script doesn't exist!", FlxColor.RED);
		});

		set('setVar', function(name:String, value:Dynamic)
		{
			PlayState.instance.variables.set(name, value);
		});
		set('getVar', function(name:String)
		{
			var result:Dynamic = null;
			if(PlayState.instance.variables.exists(name)) result = PlayState.instance.variables.get(name);
			return result;
		});
		set('removeVar', function(name:String)
		{
			if(PlayState.instance.variables.exists(name))
			{
				PlayState.instance.variables.remove(name);
				return true;
			}
			return false;
		});


		scriptName = name;
		set('scriptName', scriptName);
		set("thisScript", this);
		
		if (extraParams != null) {
			for (i in extraParams.keys())
				set(i, extraParams.get(i));
		}
		set('close', closeShit);
		set('dispose', dispose);
		set('import', import_type);
		interp.execute(contents);
	}

	function errorTrace(text:String, color:FlxColor = FlxColor.WHITE)
	{
		PlayState.instance.addTextToDebug(text, color);
	}

	public function closeShit(name:String):Bool {
		var status:Bool = PlayState.instance.closeScript(name);
		(status) ? trace('hx script closed: $name') : trace('no hx script to close: $name');
		return status;
	}

	public function dispose():Bool
		return this.closed = true;

	public function activate():Bool
		return this.closed = false;

	public function get(field:String):Dynamic
		return interp.variables.get(field);

	public function set(field:String, value:Dynamic)
		interp.variables.set(field, value);

	public function exists(field:String):Bool
		return interp.variables.exists(field);

	public function import_type(path:String) {
		var classPackage:Array<String> = path.split('.');
		var name:String = classPackage[classPackage.length - 1];
		set(name, Type.resolveClass(path));
	} 
}

@:publicFields
class CustomFlxColor
{
	static var instance:CustomFlxColor = new CustomFlxColor();
	function new() {}

	var TRANSPARENT(default, null):Int = FlxColor.TRANSPARENT;
	var WHITE(default, null):Int = FlxColor.WHITE;
	var GRAY(default, null):Int = FlxColor.GRAY;
	var BLACK(default, null):Int = FlxColor.BLACK;

	var GREEN(default, null):Int = FlxColor.GREEN;
	var LIME(default, null):Int = FlxColor.LIME;
	var YELLOW(default, null):Int = FlxColor.YELLOW;
	var ORANGE(default, null):Int = FlxColor.ORANGE;
	var RED(default, null):Int = FlxColor.RED;
	var PURPLE(default, null):Int = FlxColor.PURPLE;
	var BLUE(default, null):Int = FlxColor.BLUE;
	var BROWN(default, null):Int = FlxColor.BROWN;
	var PINK(default, null):Int = FlxColor.PINK;
	var MAGENTA(default, null):Int = FlxColor.MAGENTA;
	var CYAN(default, null):Int = FlxColor.CYAN;

	function fromRGB(Red:Int, Green:Int, Blue:Int, Alpha:Int = 255):Int
	{
		return cast FlxColor.fromRGB(Red, Green, Blue, Alpha);
	}
	function getRGB(color:Int):Array<Int>
	{
		var flxcolor:FlxColor = FlxColor.fromInt(color);
		return [flxcolor.red, flxcolor.green, flxcolor.blue, flxcolor.alpha];
	}
	function fromRGBFloat(Red:Float, Green:Float, Blue:Float, Alpha:Float = 1):Int
	{	
		return cast FlxColor.fromRGBFloat(Red, Green, Blue, Alpha);
	}
	function getRGBFloat(color:Int):Array<Float>
	{
		var flxcolor:FlxColor = FlxColor.fromInt(color);
		return [flxcolor.redFloat, flxcolor.greenFloat, flxcolor.blueFloat, flxcolor.alphaFloat];
	}
	function fromCMYK(Cyan:Float, Magenta:Float, Yellow:Float, Black:Float, Alpha:Float = 1):Int
	{
		return cast FlxColor.fromCMYK(Cyan, Magenta, Yellow, Black, Alpha);
	}
	function getCMYK(color:Int):Array<Float>
	{
		var flxcolor:FlxColor = FlxColor.fromInt(color);
		return [flxcolor.cyan, flxcolor.magenta, flxcolor.yellow, flxcolor.black, flxcolor.alphaFloat];
	}
	function fromHSB(Hue:Float, Sat:Float, Brt:Float, Alpha:Float = 1):Int
	{	
		return cast FlxColor.fromHSB(Hue, Sat, Brt, Alpha);
	}
	function getHSB(color:Int):Array<Float>
	{
		var flxcolor:FlxColor = FlxColor.fromInt(color);
		return [flxcolor.hue, flxcolor.saturation, flxcolor.brightness, flxcolor.alphaFloat];
	}
	function fromHSL(Hue:Float, Sat:Float, Light:Float, Alpha:Float = 1):Int
	{	
		return cast FlxColor.fromHSL(Hue, Sat, Light, Alpha);
	}
	function getHSL(color:Int):Array<Float>
	{
		var flxcolor:FlxColor = FlxColor.fromInt(color);
		return [flxcolor.hue, flxcolor.saturation, flxcolor.lightness, flxcolor.alphaFloat];
	}
	function fromString(str:String):Int
	{
		return cast FlxColor.fromString(str);
	}
	function getHSBColorWheel(Alpha:Int = 255):Array<Int>
	{
		return cast FlxColor.getHSBColorWheel(Alpha);
	}
	function interpolate(Color1:Int, Color2:Int, Factor:Float = 0.5):Int
	{
		return cast FlxColor.interpolate(Color1, Color2, Factor);
	}
	function gradient(Color1:Int, Color2:Int, Steps:Int, ?Ease:Float->Float):Array<Int>
	{
		return cast FlxColor.gradient(Color1, Color2, Steps, Ease);
	}
	function multiply(lhs:Int, rhs:Int):Int
	{
		return cast FlxColor.multiply(lhs, rhs);
	}
	function add(lhs:Int, rhs:Int):Int
	{
		return cast FlxColor.add(lhs, rhs);
	}
	function subtract(lhs:Int, rhs:Int):Int
	{
		return cast FlxColor.subtract(lhs, rhs);
	}
	function getComplementHarmony(color:Int):Int
	{
		return cast FlxColor.fromInt(color).getComplementHarmony();
	}
	function getAnalogousHarmony(color:Int, Threshold:Int = 30):CustomHarmony
	{
		return cast FlxColor.fromInt(color).getAnalogousHarmony(Threshold);
	}
	function getSplitComplementHarmony(color:Int, Threshold:Int = 30):CustomHarmony
	{
		return cast FlxColor.fromInt(color).getSplitComplementHarmony(Threshold);
	}
	function getTriadicHarmony(color:Int):CustomTriadicHarmony
	{
		return cast FlxColor.fromInt(color).getTriadicHarmony();
	}
	function to24Bit(color:Int):Int
	{
		return color & 0xffffff;
	}
	function toHexString(color:Int, Alpha:Bool = true, Prefix:Bool = true):String
	{
		return cast FlxColor.fromInt(color).toHexString(Alpha, Prefix);
	}
	function toWebString(color:Int):String
	{
		return cast FlxColor.fromInt(color).toWebString();
	}
	function getColorInfo(color:Int):String
	{
		return cast FlxColor.fromInt(color).getColorInfo();
	}
	function getDarkened(color:Int, Factor:Float = 0.2):Int
	{
		return cast FlxColor.fromInt(color).getDarkened(Factor);
	}
	function getLightened(color:Int, Factor:Float = 0.2):Int
	{
		return cast FlxColor.fromInt(color).getLightened(Factor);
	}
	function getInverted(color:Int):Int
	{
		return cast FlxColor.fromInt(color).getInverted();
	}
}
typedef CustomHarmony = {
	original:Int,
	warmer:Int,
	colder:Int
}
typedef CustomTriadicHarmony = {
	color1:Int,
	color2:Int,
	color3:Int
}

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
		try{
			return new GrfxHxScript(parser.parseString(File.getContent(modulePath), modulePath), extraParams, path);
		}catch(e:Dynamic){
			return null;
		}
	}
}


class GrfxHxScript extends GrfxModule
{
    var smthVal:Dynamic;
    public function executeFunc(eventName:String, args:Array<Dynamic>):Dynamic {
        smthVal = null;
		if (this.exists(eventName) && !closed) smthVal = Reflect.callMethod(interp.variables, this.get(eventName), args);
		return smthVal;
    } //callOnHscrip("onFunction", [arg1, arg2, arg3]);
}


class GrfxStateModule
{
	public var interp:Interp;
	public var scriptName:String = '';

	public function new(?contents:Expr, ?extraParams:StringMap<Dynamic>, ?name:String) {
		interp = new Interp();

		interp.variables.set('FlxG', FlxG);
		interp.variables.set('FlxSprite', FlxSprite);
		interp.variables.set('FlxCamera', FlxCamera);
		interp.variables.set('FlxTimer', FlxTimer);
		interp.variables.set('FlxTween', FlxTween);
		interp.variables.set('FlxEase', FlxEase);
		interp.variables.set('Conductor', Conductor);
		interp.variables.set('Paths', Paths);
		interp.variables.set('ClientPrefs', ClientPrefs);
		interp.variables.set('StringTools', StringTools);
		interp.variables.set('ClientPrefs', ClientPrefs);
		interp.variables.set('EngineData', EngineData);
		interp.variables.set('CoolUtil', Utils);
		interp.variables.set('Utils', Utils);
		interp.variables.set('FlxMath', FlxMath);
		interp.variables.set('Math', Math);
		interp.variables.set('FlxSave', FlxSave);
		interp.variables.set('FlxBasic', FlxBasic);
		interp.variables.set('FlxObject', FlxObject);
		interp.variables.set('FlxSound', FlxSound);
		interp.variables.set('FlxText', FlxText);
		interp.variables.set('FlxTypedGroup', FlxTypedGroup);
		interp.variables.set("Std", Std);
		interp.variables.set("Type", Type);
		interp.variables.set("Reflect", Reflect);
		interp.variables.set("FileSystem", FileSystem);
		interp.variables.set("File", File);
		interp.variables.set("Achievements", AchievementsGrfx);
		interp.variables.set("CutsceneHandler", CutsceneHandler);

		interp.variables.set('gradeAchievement', function(name:String)
		{
            AchievementsGrfx.setAchievement(name, true);
			return true;
		});

		interp.variables.set('getAchievement', function(name:String)
		{
			return AchievementsGrfx.getAchievement(name);
		});

		interp.variables.set('setAchievement', function(name:String, ?value:Bool = true)
		{
            AchievementsGrfx.setAchievement(name, value);
			return true;
		});

		scriptName = name;
		
		if (extraParams != null) {
			for (i in extraParams.keys())
				interp.variables.set(i, extraParams.get(i));
		}
		interp.variables.set('import', import_type);
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
		interp.variables.set(name, Type.resolveClass(path));
	} 
}


class GrfxModule
{
	public var interp:Interp;
	public var assetGroup:String;

	public var closed:Bool = false;
	public var scriptName:String = '';

	public function new(?contents:Expr, ?extraParams:StringMap<Dynamic>, ?name:String) {
		interp = new Interp();

		interp.variables.set('FlxG', FlxG);
		interp.variables.set('FlxSprite', FlxSprite);
		interp.variables.set('PlayState', PlayState);
		interp.variables.set('FlxCamera', FlxCamera);
		interp.variables.set('FlxTimer', FlxTimer);
		interp.variables.set('FlxTween', FlxTween);
		interp.variables.set('FlxEase', FlxEase);
		interp.variables.set('PlayState', PlayState);
		interp.variables.set('game', PlayState.instance);
		interp.variables.set('this', PlayState.instance);
		interp.variables.set('boyfriend', PlayState.instance.boyfriend);
        interp.variables.set('gf', PlayState.instance.gf);
		interp.variables.set('dad', PlayState.instance.dad);
		interp.variables.set('SONG', PlayState.SONG);
		interp.variables.set('Conductor', Conductor);
		interp.variables.set('Paths', Paths);
		interp.variables.set('ClientPrefs', ClientPrefs);
		interp.variables.set('Character', Character);
		interp.variables.set('StringTools', StringTools);
		interp.variables.set('ClientPrefs', ClientPrefs);
		interp.variables.set('EngineData', EngineData);
		interp.variables.set('CoolUtil', Utils);
		interp.variables.set('Utils', Utils);
		interp.variables.set('FlxMath', FlxMath);
		interp.variables.set('Math', Math);
		interp.variables.set('FlxSave', FlxSave);
		interp.variables.set('FlxBasic', FlxBasic);
		interp.variables.set('FlxObject', FlxObject);
		interp.variables.set('FlxSound', FlxSound);
		interp.variables.set('FlxText', FlxText);
		interp.variables.set('FlxTypedGroup', FlxTypedGroup);
		interp.variables.set('add', PlayState.instance.add);
		interp.variables.set('addPlayState', PlayState.instance.add);
		interp.variables.set("Std", Std);
		interp.variables.set("Type", Type);
		interp.variables.set("Reflect", Reflect);
		interp.variables.set("FileSystem", FileSystem);
		interp.variables.set("File", File);

		interp.variables.set("Achievements", AchievementsGrfx);

		interp.variables.set("CutsceneHandler", CutsceneHandler);

		interp.variables.set('addObjectGroup', function(object:FlxObject, group:FlxTypedGroup<FlxObject>) // I FUCKIN HATE HSCRIPT FOT THIS SHIT - PurSnake, bitch
		{
            if(group != null) {
                group.add(object);
			    return true;
            }

			errorTrace('Initialize group first, dumbass!', FlxColor.RED);
			return false;
		});
		interp.variables.set('gameTrace', function(text:String, ?color:FlxColor = FlxColor.WHITE)
		{
			errorTrace(text, color);
			return true;
		});

		interp.variables.set('setBlendMode', function(object:Dynamic, ?blend:BlendMode = null) // Bitch
		{
            if(object != null) {
                object.blend = blend;
			    return true;
            }

			return false;
		});

		interp.variables.set('gradeAchievement', function(name:String)
		{
            AchievementsGrfx.setAchievement(name, true);
			return true;
		});

		interp.variables.set('getAchievement', function(name:String)
		{
			return AchievementsGrfx.getAchievement(name);
		});

        #if DEVS_BUILD
		interp.variables.set('setAchievement', function(name:String, ?value:Bool = true)
		{
            AchievementsGrfx.setAchievement(name, value);
			return true;
		});
		#end

		interp.variables.set('setVar', function(name:String, value:Dynamic)
		{
			PlayState.instance.variables.set(name, value);
		});
		interp.variables.set('getVar', function(name:String)
		{
			var result:Dynamic = null;
			if(PlayState.instance.variables.exists(name)) result = PlayState.instance.variables.get(name);
			return result;
		});
		interp.variables.set('removeVar', function(name:String)
		{
			if(PlayState.instance.variables.exists(name))
			{
				PlayState.instance.variables.remove(name);
				return true;
			}
			return false;
		});


		scriptName = name;
		interp.variables.set('scriptName', scriptName);
		
		if (extraParams != null) {
			for (i in extraParams.keys())
				interp.variables.set(i, extraParams.get(i));
		}
		interp.variables.set('close', closeShit);
		interp.variables.set('dispose', dispose);
		interp.variables.set('import', import_type);
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
		interp.variables.set(name, Type.resolveClass(path));

	} 
}

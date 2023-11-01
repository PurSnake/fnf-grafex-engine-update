package external;

import haxe.Timer;
import openfl.events.Event;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.system.System;
import grafex.data.EngineData;
import flixel.math.FlxMath;
import flixel.FlxG;
import openfl.display.Shader;
import openfl.filters.ShaderFilter;
import openfl.display.Sprite;

#if gl_stats
import openfl.display._internal.stats.Context3DStats;
import openfl.display._internal.stats.DrawCallContext;
#end
//#if flash
import openfl.Lib;
//#end

/**
	The FPS class provides an easy-to-use monitor to display
	the current frame rate of an OpenFL project
**/
#if !openfl_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end

enum GLInfo
{
	RENDERER;
	SHADING_LANGUAGE_VERSION;
}

class FPSMem extends Sprite
{
	/**
		The current frame rate, expressed using frames-per-second
	**/
	public var currentFPS(default, null):Int;
	public var currentMem:Float;

	public static var showMem:Bool=true; // TODO: Rename
	public static var showFPS:Bool=true;

	@:noCompletion private var fpsCount:Int = 0;
	@:noCompletion private var currentTime:Float = 0;
	@:noCompletion private var times:Array<Float> = [];

	@:noCompletion var fpsText:TextField;
	@:noCompletion var outlines:Array<TextField> = [];

	public function new(x:Float = 10, y:Float = 10, color:Int = 0x000000)
	{
		super();
		this.x = x;
		this.y = y;

		fpsText = new TextField();
		fpsText.defaultTextFormat = new TextFormat(openfl.utils.Assets.getFont("assets/fonts/VCR OSD Mono Cyr.ttf").fontName, 15);
		fpsText.textColor = 0xFFFFFF;
		fpsText.width = FlxG.width;
		fpsText.selectable = fpsText.mouseEnabled = false;

		if (!ClientPrefs.lowQuality){
			var iterations = 10;
			final deezNuts = (1/iterations)*Math.PI*2;
			while (iterations > -1){
				var otext:TextField = new TextField();
				otext.x = Math.sin(deezNuts * iterations) * 2;
				otext.y = Math.cos(deezNuts * iterations) * 2;
				otext.defaultTextFormat = fpsText.defaultTextFormat;
				otext.textColor = 0x000000;
				otext.width = fpsText.width;
				otext.selectable = otext.mouseEnabled = false;
				outlines.push(otext);
				addChild(otext);
				iterations--;
			}
		}
		addChild(fpsText);

		#if flash
		addEventListener(Event.ENTER_FRAME, function(e)
		{
			__enterFrame(Timer.stamp()-currentTime);
		});
		#end
	}

	// Event Handlers
	@:noCompletion
	private #if !flash override #end function __enterFrame(d:Float):Void
	{
		currentTime = Timer.stamp();
		times.push(currentTime);
		
		while(times[0]<currentTime-1)
			times.shift();

		currentFPS = times.length;
		currentMem = System.totalMemory;

		if (currentFPS != fpsCount /*&& visible*/)
		{
			fpsText.text = "";
			if(showFPS) fpsText.text += "FPS: " + currentFPS + "\n"; 

			if(showMem) currentMem < 0 ? fpsText.text += "Memory: Leaking " + formatBytes(currentMem): fpsText.text += "Memory: " + formatBytes(currentMem);
	
			//currentMem < 0 ? fpsText.text += "Memory: Leaking " + Math.abs(currentMem) + " MB\n" : fpsText.text += "Memory: " + currentMem + " MB\n";

			#if DEVS_BUILD

			/*if(showFPS && showMem) {
				fpsText.text += 'State: ${Type.getClassName(Type.getClass(FlxG.state))}';
				if (FlxG.state.subState != null) text += '\nSubstate: ${Type.getClassName(Type.getClass(FlxG.state.subState))}';

				fpsText.text += "\nSystem: " + '${lime.system.System.platformLabel} ${lime.system.System.platformVersion}';
				fpsText.text += "\nGL Render: " + '${getGLInfo(RENDERER)}';
				fpsText.text += "\nGL Shading version: " + '${getGLInfo(SHADING_LANGUAGE_VERSION)})';
			}*/
			fpsText.text += '\n'; // poo
			#else
			//fpsText.text += 'Grafex\n';
			#end

			for (outline in outlines)
				outline.text = fpsText.text;
		}
		fpsCount = currentFPS;
	}

	function setText(text:String) {
		fpsText.text = text;
		for (outline in outlines)
			outline.text = text;
	}

	var units:Array<String> = ["Bytes", "kB", "MB", "GB", "TB", "PB"];
	private function formatBytes(bytes:Float) {
		var curUnit = 0;
		while (bytes >= 1024 && curUnit < units.length - 1) {
			bytes /= 1024;
			curUnit++;
		}
		return FlxMath.roundDecimal(bytes, 2) + ' ' + units[curUnit];
	}
	
    private function getGLInfo(info:GLInfo):String
	{
		@:privateAccess
		var gl:Dynamic = Lib.current.stage.context3D.gl;

		switch (info)
		{
			case RENDERER:
				return Std.string(gl.getParameter(gl.RENDERER));
			case SHADING_LANGUAGE_VERSION:
				return Std.string(gl.getParameter(gl.SHADING_LANGUAGE_VERSION));
		}
		return '';
	}
}
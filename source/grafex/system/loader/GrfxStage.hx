package grafex.system.loader;

import flixel.FlxBasic;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup;
import haxe.ds.StringMap;
import grafex.system.script.GrfxScriptHandler;
import grafex.states.playstate.PlayState;
import grafex.util.ClientPrefs;

import sys.io.File;
import sys.FileSystem;

class GrfxStage extends FlxTypedGroup<FlxSprite> {
	var stageBuild:GrfxModule;
	public var foreground:FlxSpriteGroup;

	public var curStage:String;	
        public var exist:Bool = true;
	public var customModFolder:Int = 0;

	public function new(?stage:String = 'stage') {
		super();

		this.curStage = stage;

		foreground = new FlxSpriteGroup();

		var exposure:StringMap<Dynamic> = new StringMap<Dynamic>();
		exposure.set('this', PlayState.instance);
		exposure.set('foreground', foreground);
		exposure.set('stage', this);
		exposure.set('curStage', this.curStage);
		exposure.set('boyfriend', PlayState.instance.boyfriend);
		exposure.set('gf', PlayState.instance.gf);
		exposure.set('dad', PlayState.instance.dad);
		exposure.set('dadOpponent', PlayState.instance.dad);

		if(Paths.fileExists('stages/$stage/$stage.hx', TEXT)) {
		        stageBuild = GrfxScriptHandler.loadModule('stages/$stage/$stage', exposure);
			Paths.doStageFuckinShitOH('/stages/$stage');
			if (stageBuild.exists("onCreate"))
				stageBuild.get("onCreate")();
			Paths.doStageFuckinShitOH();
			exist = true;
			trace('$stage.hx has loaded successfully ' + exist);
		} else {
			exist = false;
			trace('$stage.hx not exitst in our universe ' + exist);
		}
    }

    var smthVal:Dynamic;
    public function callFunction(eventName:String, args:Array<Dynamic>):Dynamic {
        smthVal = null;
        if (exist && stageBuild.exists(eventName))
	    smthVal = Reflect.callMethod(stageBuild.interp.variables, stageBuild.get(eventName), args);

        return smthVal;
    }

	public function set(field:String, value:Dynamic)
		stageBuild.set(field, value);
}


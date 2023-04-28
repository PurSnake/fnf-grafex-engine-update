package grafex.sprites.menu;

import grafex.system.Paths;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.FlxG;
import sys.io.File;
import sys.FileSystem;

import openfl.utils.Assets;
import haxe.Json;
import haxe.format.JsonParser;
import grafex.util.ClientPrefs;

using StringTools;

typedef DudleCharFile =
{
	var name:String;
	var image:String;
	var position:Array<Int>;
	var scale:Float;
    var layer:Int;
	var antialiasing:Bool;
	var animation:String;
	var looped:Bool;
	var fps:Int;
	var sex:Int;
}

class CharDudle extends FlxSprite
{
    public var folderToCheck:String = Paths.getPreloadPath('images/mainmenududles/');
    var localNames:Array<String> = [];  
    public var animBeatNum:Int;
    public var localName:String;
    public var staticImage:Bool;
    public var loopedAnim:Bool = false;
    public var layer:Int = 0; //if 0 then will not layered - PurSnake
    public var exist = true;

	public function new()
    {
        super();

		if(FileSystem.exists(folderToCheck)) {
			for (file in FileSystem.readDirectory(folderToCheck)) {
				var path = haxe.io.Path.join([folderToCheck, file]);
				if (!FileSystem.isDirectory(path) && file.endsWith('.json')) {
					var charToCheck:String = file.substr(0, file.length - 5);
					if(!charToCheck.endsWith('-test')) {
						localNames.push(charToCheck);
					}
				}
			}
		}

        var name:String = FlxG.random.getObject(localNames);
        changeDudle(name);
    }

    public function dance(?force:Bool = true)
    {
        if(exist) animation.play('anim', true);
    }

    public function changeDudle(name:String)
    {
        var characterPath:String = 'images/mainmenududles/' + name + '.json';
        var rawJson = null;

        #if MODS_ALLOWED
        var path:String = Paths.modFolders(characterPath);
        if (!FileSystem.exists(path)) {
            path = Paths.getPreloadPath(characterPath);
        }

        if(!FileSystem.exists(path)) {
            exist = false;
        }
        rawJson = File.getContent(path);

        #else
        var path:String = Paths.getPreloadPath(characterPath);
        if(!Assets.exists(path)) {
            exist = false;
        }
        rawJson = Assets.getText(path);
        #end

        var charFile:DudleCharFile = cast Json.parse(rawJson);
        if(charFile.animation != 'null') {
            frames = Paths.getSparrowAtlas('mainmenududles/images/${charFile.image}');
            animation.addByPrefix('anim', charFile.animation, charFile.fps, charFile.looped);
            if(charFile.looped) animation.play('anim', false);

            loopedAnim = charFile.looped;
            staticImage = false;
        } else {
            loadGraphic(Paths.image('mainmenududles/images/${charFile.image}'));
            staticImage = true;
        }

        localName = charFile.name;

        layer = charFile.layer;
        if(Math.isNaN(layer)) layer = 0;

		antialiasing = charFile.antialiasing;
		visible = exist;
        if(charFile.scale != 1) {
            scale.set(charFile.scale, charFile.scale);
            updateHitbox();
        }

        offset.set(-charFile.position[0], -charFile.position[1]);
        if(!charFile.looped) animBeatNum = charFile.sex;

        trace('12');
    }
}
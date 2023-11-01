package grafex.sprites;

import grafex.states.playstate.PlayState;
import grafex.system.Paths;
import grafex.system.Conductor;
import grafex.util.ClientPrefs;
import grafex.util.Utils;
import flixel.FlxSprite;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.math.FlxMath;
import flixel.FlxG;
import flixel.math.FlxPoint;

#if MODS_ALLOWED
import sys.io.File;
import sys.FileSystem;
#end
import openfl.utils.AssetType;
import openfl.utils.Assets;

import haxe.ds.Map;

using StringTools;

typedef IconProperties = {
	var type:String;
	var offsets:Array<Float>;
	var scale:Float;
}
class HealthIcon extends FlxSprite
{
	public var animOffsets:Map<String, Array<Int>> = [];
	public var isPlayer:Bool = false;
	private var character:String = '';

	public var sprTracker:FlxSprite;
	public var sprTrackerOffsets:Array<Float> = [10, 15];

	public var customOffsets:FlxPoint = FlxPoint.get(0, 0);
	public var customScale:Float = 1;
	public var scalePercent:Float = 1.2;

	public var spriteType:String = 'duo';

	public var alligment(default, set):String = 'right';

	public var properties:Map<String, Dynamic> = new Map();

	public function new(char:String = 'bf', props:IconProperties, isPlayer:Bool = false, ?gpuRender = true)
	{
		super();

		if (props == null) {
			props = {
				type: "duo",
				offsets: [0, 0],
				scale: 1
			}
		}
		this.isPlayer = isPlayer;

		spriteType = props.type;
		changeOffsets(props.offsets);
		changeScale(props.scale);

		changeIcon(char, gpuRender);
		scrollFactor.set();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (sprTracker != null)
			setPosition(sprTracker.x + sprTracker.width + sprTrackerOffsets[0], sprTracker.y + sprTrackerOffsets[1]);
	}

	public function changeIcon(char, ?props:IconProperties = null, ?gpuRender:Bool = true, ?forced:Bool = false) //char:String, ?xd:Float = 0, ?yd:Float = 0, ?cusScale:Float = 1, ?gpuShieet:Bool = true
	{
        if (character == char && !forced) return;

		if (props != null) {
			spriteType = props.type;
			changeOffsets(props.offsets);
			changeScale(props.scale);
		}

		switch (char) 
		{  
            default: 
				switch(spriteType) {
                    case 'solo' | 'duo' | 'trioWin' | 'trioLose' | 'quadro':

						var name:String = 'icons/' + char;

						if(!Paths.fileExists('images/' + name + '.png', IMAGE)) name = 'icons/icon-' + char; //Older versions of psych engine's support

						if(!Paths.fileExists('images/' + name + '.png', IMAGE)) {
							name = 'icons/icon-noone'; //Prevents crash from missing 
							spriteType == 'solo';
							changeOffsets([0, 0]);
							changeScale(1);
						}

						var cutNum:Int = switch (spriteType) {
							case 'solo': 1;
							case 'duo': 2;
							case 'trioWin' | 'trioLose': 3;
							case 'quadro': 4;
							default: 2;
						}
						var graphic = Paths.image(name, gpuRender); //For width and height - PurSnake

						loadGraphic(graphic, true, Math.floor(graphic.width / cutNum), Math.floor(graphic.height));

						switch(spriteType) {
							case 'solo':
								animation.add('default', [0], 0, false, isPlayer);

							case 'duo': 
								animation.add('default', [0], 0, false, isPlayer);
								animation.add('losing', [1], 0, false, isPlayer);
	
							case 'trioWin':
								animation.add('default', [0], 0, false, isPlayer);
								animation.add('losing', [1], 0, false, isPlayer);
								animation.add('winning', [2], 0, false, isPlayer);
							case 'trioLose': 
								animation.add('default', [0], 0, false, isPlayer);
								animation.add('losing', [1], 0, false, isPlayer);
								animation.add('lost', [2], 0, false, isPlayer);

							case 'quadro': 4;
							    animation.add('default', [0], 0, false, isPlayer);
							    animation.add('losing', [1], 0, false, isPlayer);
							    animation.add('winning', [2], 0, false, isPlayer);
								animation.add('lost', [3], 0, false, isPlayer);
						}
						playAnim("default");

					case 'classic-animated' | 'modern-animated':
						var name:String = 'icons/' + char;
						
						if(!Paths.fileExists('images/' + name + '.png', IMAGE)) name = 'icons/icon-' + char; //Older versions of psych engine's support

						if(Paths.getAtlas(name) == null) {
							name = 'icons/icon-noone';
							spriteType == 'solo';
							changeOffsets([0, 0]);
							changeScale(1);
						}
		
						var file:Dynamic = Paths.getAtlas(name); //For width and height - PurSnake

					case 'custom': loadGraphic(Paths.image('icons/icon-noone')); // For custom things
				}
				updateHitbox();
				antialiasing = !char.endsWith('-pixel') ? ClientPrefs.globalAntialiasing : false;
		} // Add new 'case', if you want to add HARDCODED character icon ;)

		character = char;

		//game.callOnHscript("onChangeIcon", [character, isPlayer, spriteType]);
	}

	public function playAnim(AnimName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0){
		if(animation.getByName(AnimName) == null) return;

		animation.play(AnimName, Force, Reversed, Frame);
	}

	var game = PlayState.instance;
	public function updateScale(?elapsed:Float = 0, ?playbackRate:Float = 0)
	{
		var mult:Float = FlxMath.lerp(customScale, scale.x, Utils.boundTo(1 - ((elapsed != 0 ? elapsed : FlxG.elapsed) * 9 * (playbackRate != 0 ? playbackRate : game.playbackRate)), 0, 1));
		scale.set(mult, mult);
		updateHitbox();
	}

	public var iconOffset:Int = 26;
	public function updatePosition(elapsed:Float)
	{

		var newX:Float = x;
		switch(alligment) {
			case 'right':
				this.isPlayer ? {
					newX = game.healthBar.x + (game.healthBar.width * (FlxMath.remapToRange(game.displayedHealth, 0, 100, 100, 0) * 0.01)) + (150 * scale.x - 150) / 2 - iconOffset;
				} : {
					newX = game.healthBar.x + (game.healthBar.width * (FlxMath.remapToRange(game.displayedHealth, 0, 100, 100, 0) * 0.01)) - (150 * scale.x) / 2 - iconOffset * 2;
				}	
			case 'left':
				this.isPlayer ? {
				        newX = game.healthBar.x + (game.healthBar.width * (FlxMath.remapToRange(100 - game.displayedHealth, 0, 100, 100, 0) * 0.01)) - (150 * scale.x) / 2 - iconOffset * 2;
				} : {
					newX = game.healthBar.x + (game.healthBar.width * (FlxMath.remapToRange(100 - game.displayedHealth, 0, 100, 100, 0) * 0.01)) + (150 * scale.x - 150) / 2 - iconOffset;
				}
		}

		game.smoothIcons ? x = FlxMath.bound(FlxMath.lerp(x, newX, FlxMath.bound(elapsed * 35 * game.playbackRate, 0, 1)), newX - 50, newX + 50) : x = newX;
	}

	public dynamic function updateAnim(health:Float) // Dynamic to prevent having like 20 if statements
	{
		switch (spriteType) {
			case 'solo': 
				playAnim("default");

		    case 'duo': 
				health < 20 ? playAnim("losing") : playAnim("default");

			case 'trioWin': 
				if (health < 20) 
					playAnim("losing");
			    else if (health > 80)
					playAnim("winning");
				else
					playAnim("default");

			case 'trioLose': 
				if (health < 10)
					playAnim("lost");
				else if (health < 30) 
					playAnim("losing");
				else 
					playAnim("default");

			case 'quadro': 
				if (health < 10)
				    playAnim("lost")
				else if (health < 30) 
					playAnim("losing");
				else if (health > 80)
		    	    playAnim("winning");
				else
					playAnim("default");
		}

	}

	public function doScale(percentage:Float = 1)
	{
		scale.set(customScale * scalePercent * percentage, customScale * scalePercent * percentage);
		updateHitbox();
	}

	override function updateHitbox()
	{
		super.updateHitbox();
		var offsetByAnim = [0, 0];
		if (animOffsets.exists(animation.curAnim.name)) offsetByAnim = animOffsets.get(animation.curAnim.name);

		offset.x = -customOffsets.x + offsetByAnim[0];
		offset.y = customOffsets.y + offsetByAnim[1];
	}
	
	// Setters functions

	function set_alligment(Alligment:String):String
	{
		switch(Alligment) {
			case 'left':
				flipX = isPlayer;
			case 'right':
				flipX = !isPlayer;
		}
		return alligment = Alligment;
	}

	function get_alligment():String
	{
		return alligment;
	}

	public function changeOffsets(custom:Array<Float>)
	{
        customOffsets.set(custom[0], custom[1]);
	}

	public function changeScale(custom:Float = 1, ?set:Bool = false)
	{
		customScale = custom;
		if (set) scale.set(custom, custom);

	}

	public function getCharacter():String {
		return character;
	}

}
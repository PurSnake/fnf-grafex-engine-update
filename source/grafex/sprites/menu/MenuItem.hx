package grafex.sprites.menu;

import grafex.util.Utils;
import grafex.system.Paths;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import grafex.util.ClientPrefs;

class MenuItem extends FlxSprite
{
	public var targetY:Float = 0;

	public function new(x:Float, y:Float, weekName:String = '')
	{
		super(x, y, Paths.image('storymenu/$weekName'));
		//trace('Test added: ' + WeekData.getWeekNumber(weekNum) + ' (' + weekNum + ')');
		antialiasing = ClientPrefs.globalAntialiasing;
	}

	public var isFlashing(default, set):Bool = false;
	final flashColor:Int = 0xFF33ffff;
	final flashFrame:Int = 6;
	var flashElapsed:Float = 0.0;

	inline function set_isFlashing(flashing:Bool):Bool
	{
		flashElapsed = 0.0;
		color = (flashing ? flashColor : FlxColor.WHITE);
		return isFlashing = flashing;
	}
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		y = FlxMath.lerp(y, (targetY * 120) + 480, Math.max(elapsed * 10.2, 0));

		if (isFlashing)
		{
			flashElapsed += elapsed;
			color = (flashElapsed * FlxG.updateFramerate) % flashFrame > flashFrame * 0.5 ? FlxColor.WHITE : flashColor;
		}
	}
}

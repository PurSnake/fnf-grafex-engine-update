package grafex.sprites;

import flixel.FlxG;
import flixel.FlxCamera;
import flixel.math.FlxPoint;
import openfl.geom.Matrix;

class FixedCamera extends FlxCamera{
	public var fix(default, set):Bool = true;
	public var rotationOffset(default, set):FlxPoint = new FlxPoint(0.5, 0.5);
	var viewOffset:FlxPoint = FlxPoint.get();

	public function new(X:Int = 0, Y:Int = 0, Width:Int = 0, Height:Int = 0, Zoom:Float = 0, fix:Bool = true) {
		super(X,Y,Width,Height,Zoom);
		this.fix = !grafex.util.ClientPrefs.lowQuality && fix;
	}

	override function update(elapsed:Float):Void{
		super.update(elapsed);
		fixUpdate();
	}

	inline function set_fix(newValue:Bool):Bool{
		fix = newValue;
		fixUpdate();
		return newValue;
	}

	inline function set_rotationOffset(newValue:FlxPoint):FlxPoint{
		rotationOffset = newValue;
		fixUpdate();
		return newValue;
	}

	public function fixUpdate():Void{
		if (fix){
			flashSprite.x -= _flashOffset.x;
			flashSprite.y -= _flashOffset.y;
			
			var matrix:Matrix = new Matrix();
			// matrix.concat(canvas.transform.matrix); // DON'T EVEN THINK ABOUT IT.
			matrix.translate(-width * rotationOffset.x, -height * rotationOffset.y);
			matrix.scale(scaleX, scaleY);
			matrix.rotate(angle * (Math.PI / 180));
			matrix.translate(width * rotationOffset.x, height * rotationOffset.y);
			matrix.translate(flashSprite.x, flashSprite.y); // for shake event
			matrix.scale(FlxG.scaleMode.scale.x, FlxG.scaleMode.scale.y);
			canvas.transform.matrix = matrix;

			flashSprite.x = width * 0.5 * FlxG.scaleMode.scale.x;
			flashSprite.y = height * 0.5 * FlxG.scaleMode.scale.y;
			flashSprite.rotation = 0;
		}
	}
}
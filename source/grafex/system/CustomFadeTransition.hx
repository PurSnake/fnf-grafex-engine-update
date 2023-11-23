package grafex.system;
class CustomFadeTransition extends flixel.FlxSubState
{
	static final colors:Array<Int> = [0x0, FlxColor.BLACK, FlxColor.BLACK];
	public static var finishCallback:Void->Void;
	public static var nextCamera:FlxCamera;

	public function new(duration:Float, isTransIn:Bool)
	{
		super();

		if (duration <= 0) {
			finish(isTransIn);	// dont bother creating shit
			return;				// actually nvmd it soflocks you lmao
		}

		final zoom:Float = FlxMath.bound(FlxG.camera.zoom, 0.05, 1);
		final width:Int  = Std.int(FlxG.width / zoom);
		final height:Int = Std.int(FlxG.height / zoom);
		final realColors = colors.copy();
		if (!isTransIn) realColors.reverse();

		final transGradient:FlxSprite = flixel.util.FlxGradient.createGradientFlxSprite(1, height * 2, realColors);
		transGradient.setPosition(-(width - FlxG.width) * 0.5, isTransIn ? -height : -height * 2);
		transGradient.scrollFactor.set();
		transGradient.scale.x = width;
		transGradient.updateHitbox();
		add(transGradient);

		// actually uses nextCamera now WOW!!!!
		transGradient.cameras = [#if (haxe > "4.2.5") nextCamera ?? #else nextCamera != null ? nextCamera : #end FlxG.cameras.list[FlxG.cameras.list.length - 1]];
		nextCamera = null;

		FlxTween.tween(transGradient, {y: isTransIn ? height : 0}, duration, {onComplete: function(t:FlxTween) finish(isTransIn)});
	}

	inline private function finish(transIn:Bool) transIn ? close() : if(finishCallback != null) finishCallback();
}
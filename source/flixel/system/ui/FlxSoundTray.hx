package flixel.system.ui;

#if FLX_SOUND_SYSTEM
import flixel.FlxG;
import flixel.system.FlxAssets;
import flixel.util.FlxColor;
import openfl.Lib;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.Sprite;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;

/**
 * The flixel sound tray, the little volume meter that pops down sometimes.
 * Accessed via `FlxG.game.soundTray` or `FlxG.sound.soundTray`.
 */
class FlxSoundTray extends Sprite
{
	public var active:Bool;

	var _bars:Array<Bitmap>;

	var _width:Float = 80;
	var _defaultScale:Float = 1.0;

	public var volumeUpSound:String = "volume";
	public var volumeDownSound:String = "volume";

	public var silent:Bool = false;
	public var shouldShow:Bool = true;
	public var timeToExist:Float = 1.5;
	private var _localTimer:Float;
	private var _requestedY:Float;

	var volumeSprite:Bitmap;

	@:keep
	public function new()
	{
		super();

		scaleX = _defaultScale;
		scaleY = _defaultScale;
		screenCenter();

		final splashSprite:Bitmap = new Bitmap(openfl.utils.Assets.getBitmapData(Paths.getPath('images/app/volume-back.png', IMAGE)), null, true);
		_width = splashSprite.width;

		final disBg:Bitmap = new Bitmap(new BitmapData(200, 68, false, FlxColor.GRAY));
		volumeSprite = new Bitmap(new BitmapData(1, 68, false, FlxColor.WHITE));
		disBg.x = volumeSprite.x = 78;
		addChild(disBg);
		addChild(volumeSprite);
		addChild(splashSprite);

		_requestedY = y = -height;
		visible = false;
	}

	public function update(MS:Float):Void
	{
		if (active) {
			if (_localTimer >= timeToExist) _requestedY = -height;

			y = Utils.fpsLerp(y, _requestedY, Utils.getFPSRatio(.5));

			(y == -height && _localTimer >= timeToExist) ? hideSelf() : _localTimer += (MS / 1000);
		}
	}

	public function show(up:Bool = false, ?forceSound:Bool = true):Void
	{
		if (shouldShow && !silent && forceSound)
		{
			final sound = Paths.sound(up ? volumeUpSound : volumeDownSound);
			if (sound != null)
				FlxG.sound.load(sound).play();
		}

		if (shouldShow) {
			visible = true;
			active = true;
			_localTimer = _requestedY = 0;
		}
		var globalVolume:Int = Math.round(FlxG.sound.volume * 20);

		if (FlxG.sound.muted) globalVolume = 0;

		volumeSprite.width = 10 * globalVolume;
	}
	
	function hideSelf() {
		visible = false;
		active = false;	

		#if FLX_SAVE
		if (FlxG.save.isBound)
		{
			FlxG.save.data.mute = FlxG.sound.muted;
			FlxG.save.data.volume = FlxG.sound.volume;
			FlxG.save.flush();
		}
		#end
	}

	public function screenCenter():Void
	{
		scaleX = _defaultScale;
		scaleY = _defaultScale;

		x = (0.5 * (Lib.current.stage.stageWidth - _width * _defaultScale) - FlxG.game.x);
	}
}
#end

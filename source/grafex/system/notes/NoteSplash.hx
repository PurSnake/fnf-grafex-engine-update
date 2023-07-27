package grafex.system.notes;

import flixel.FlxG;
import flixel.FlxSprite;
import grafex.effects.shaders.ColorSwap;
import grafex.states.playstate.PlayState;
import grafex.util.ClientPrefs;

class NoteSplash extends FlxSprite
{
	public var colorSwap:ColorSwap = null;
	private var textureLoaded:String = null;

	public function new(x:Float = 0, y:Float = 0, ?note:Int = 0) {
		super(x, y);

		var skin:String = 'noteSplashes';
		if(PlayState.SONG.splashSkin != null && PlayState.SONG.splashSkin.length > 0) skin = PlayState.SONG.splashSkin;

		loadAnims(skin);
		
		colorSwap = new ColorSwap();
		shader = colorSwap.shader;

		setupNoteSplash(x, y, note);
	}

	public function setupNoteSplash(x:Float, y:Float, note:Int = 0, texture:String = 'noteSplashes', hueColor:Float = 0, satColor:Float = 0, brtColor:Float = 0) {

		if(textureLoaded != texture){
			loadAnims(texture);
			animation.play('note' + note + '-' + FlxG.random.int(1, 2), true);
			if (animation.curAnim == null)
				kill();
		}
		animation.play('note' + note + '-' + FlxG.random.int(1, 2), true);
		alpha = 1;
		alpha *= ClientPrefs.noteSplashesAlpha;

		colorSwap.hue = hueColor;
		colorSwap.saturation = satColor;
		colorSwap.brightness = brtColor;

		scale.set(ClientPrefs.noteSplashesScale, ClientPrefs.noteSplashesScale);
		animation.curAnim.frameRate = 24 + FlxG.random.int(-3, 4);
		angle = FlxG.random.int(-10, 10);
		centerOffsets();
		setPosition(x - width * 0.5, y - height * 0.5);
	}

	function loadAnims(skin:String) {
		frames = Paths.getSparrowAtlas(skin);
		for (i in 1...3) {
			animation.addByPrefix("note0-" + i, "note splash purple " + i, 24, false);
			animation.addByPrefix("note1-" + i, "note splash blue " + i, 24, false);
			animation.addByPrefix("note2-" + i, "note splash green " + i, 24, false);
			animation.addByPrefix("note3-" + i, "note splash red " + i, 24, false);
		}
		textureLoaded = skin;
	}

	override function update(elapsed:Float) {
		super.update(elapsed);
		if(animation.curAnim.finished) kill();
	}
}
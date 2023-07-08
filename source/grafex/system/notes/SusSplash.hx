package grafex.system.notes;

import flixel.FlxG;
import flixel.FlxSprite;
import grafex.effects.shaders.ColorSwap;
import grafex.states.playstate.PlayState;
import grafex.util.ClientPrefs;

class SusSplash extends FlxSprite
{
	public var colorSwap:ColorSwap = null;
	private var textureLoaded:String = null;

	public function new(x:Float = 0, y:Float = 0, ?note:Int = 0) {
		super(x, y);

		var skinS:String = 'NOTE_assets-extra';
		if(PlayState.SONG.extrasSkin!=null && PlayState.SONG.extrasSkin.length>0) skinS=PlayState.SONG.extrasSkin;

		loadAnims(skinS);

		colorSwap = new ColorSwap();
		shader = colorSwap.shader;

		setupNoteSplash(x, y, note);
	}

	public function setupNoteSplash(x:Float, y:Float, note:Int = 0, texture:String = 'NOTE_assets-extra', hueColor:Float = 0, satColor:Float = 0, brtColor:Float = 0) {

		if(textureLoaded != texture){
			loadAnims(texture);
			animation.play('note' + note + '-' + FlxG.random.int(1, 2), true);
			if (animation.curAnim == null)
				kill();
		}

		animation.play('note' + note + '-' + FlxG.random.int(1, 2), true);

		alpha = 0.8;

		colorSwap.hue = hueColor;
		colorSwap.saturation = satColor;
		colorSwap.brightness = brtColor;

                flipY = ClientPrefs.downScroll;

		scale.set(0.7, 0.7);
		animation.curAnim.frameRate = 24;
		centerOffsets();
		setPosition(x - width * 0.25, y + height * 0.41);
		if(ClientPrefs.downScroll) setPosition(x - width * 0.25, y - height);
	}

    public function playAnimation() {
		//animation.play(animToPlay, true);
		centerOffsets();
		setPosition(x - width * 0.35, y - height * 0.55);
	}

	function loadAnims(skin:String) {
		frames = Paths.getSparrowAtlas(skin);
		for (i in 1...3) {
			animation.addByPrefix("note0-" + i, "hold splash purple " + i, 24, false);
			animation.addByPrefix("note1-" + i, "hold splash blue " + i, 24, false);
			animation.addByPrefix("note2-" + i, "hold splash green " + i, 24, false);
			animation.addByPrefix("note3-" + i, "hold splash red " + i, 24, false);
		}
		textureLoaded = skin;
	}

	override function update(elapsed:Float) {
		super.update(elapsed);
		if(animation.curAnim.finished) kill();
	}
}
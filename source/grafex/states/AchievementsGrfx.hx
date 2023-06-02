package grafex.states;

import grafex.system.statesystem.MusicBeatState;
import grafex.util.ClientPrefs;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxColor;
import flixel.text.FlxText;

using StringTools;

class AchievementsGrfx {
	public static var achievementsStuff:Array<Dynamic> = [
		/*[
			"", // Name,
			"" // Description,
			'' / /Achievement save tag,
			[0, 0] // image offsets,
			false // Hidden achievement
		]*/
	];

	public static function getAchievement(name:String) {
		if(ClientPrefs.achievements.exists(name))
			return ClientPrefs.achievements.get(name);
		return false;
	}

	public static function setAchievement(name:String, ?yes:Bool = true) {
		if(yes && getAchievement(name) != true) Main.achievementToatManager.createToast(name, getShit(name).get('tilte'), getShit(name).get('desc'), !getShit(name).get('secret'));

	    ClientPrefs.achievements.set(name, yes);
		ClientPrefs.saveSettings();

		//if(yes) Main.achievementToatManager.createToast(name, getShit(name).get('tilte'), getShit(name).get('desc'), !getShit(name).get('secret'));

		return true;
	}

	private static function getShit(name:String):Map<String, Dynamic> {
		var map:Map<String, Dynamic> = new Map<String, Dynamic>();
		for (i in 0...achievementsStuff.length) {
            if (name == achievementsStuff[i][2]) {
			    map.set('tilte', achievementsStuff[i][0]);
				map.set('desc', achievementsStuff[i][1]);
				map.set('secret', achievementsStuff[i][4]);
			}
		}
		return map;
	}
}

class AchievementObject extends FlxSpriteGroup {
	public var onFinish:Void->Void = null;
	var alphaTween:FlxTween;
	public function new(name:String, ?camera:FlxCamera = null)
	{
		super(x, y);
		ClientPrefs.saveSettings();

		var id:Int = 0;
		var achievementBG:FlxSprite = new FlxSprite(60, 50).makeGraphic(420, 120, FlxColor.BLACK);
		achievementBG.scrollFactor.set();

		var achievementIcon:FlxSprite = new FlxSprite(achievementBG.x + 10, achievementBG.y + 10).loadGraphic(Paths.image('achievementgrid'), true, 150, 150);
		achievementIcon.animation.add('icon', [id], 0, false, false);
		achievementIcon.animation.play('icon');
		achievementIcon.scrollFactor.set();
		achievementIcon.setGraphicSize(Std.int(achievementIcon.width * (2 / 3)));
		achievementIcon.updateHitbox();
		achievementIcon.antialiasing = ClientPrefs.globalAntialiasing;

		var achievementName:FlxText = new FlxText(achievementIcon.x + achievementIcon.width + 20, achievementIcon.y + 16, 280, AchievementsGrfx.achievementsStuff[id][0], 16);
		achievementName.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT);
		achievementName.scrollFactor.set();

		var achievementText:FlxText = new FlxText(achievementName.x, achievementName.y + 32, 280, AchievementsGrfx.achievementsStuff[id][1], 16);
		achievementText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT);
		achievementText.scrollFactor.set();

		add(achievementBG);
		add(achievementName);
		add(achievementText);
		add(achievementIcon);

		var cam:Array<FlxCamera> = FlxCamera.defaultCameras;
		if(camera != null) {
			cam = [camera];
		}
		alpha = 0;
		achievementBG.cameras = cam;
		achievementName.cameras = cam;
		achievementText.cameras = cam;
		achievementIcon.cameras = cam;
		alphaTween = FlxTween.tween(this, {alpha: 1}, 0.5, {onComplete: function (twn:FlxTween) {
			alphaTween = FlxTween.tween(this, {alpha: 0}, 0.5, {
				startDelay: 2.5,
				onComplete: function(twn:FlxTween) {
					alphaTween = null;
					remove(this);
					if(onFinish != null) onFinish();
				}
			});
		}});
	}

	override function destroy() {
		if(alphaTween != null) {
			alphaTween.cancel();
		}
		super.destroy();
	}
}
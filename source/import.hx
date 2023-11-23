#if !macro
#if desktop
import external.Discord.DiscordClient;
#end
#if (flixel >= "5.3.0")
import flixel.sound.FlxSound;
#else
import flixel.system.FlxSound;
#end
import flixel.FlxG;
import flixel.FlxSprite;
import grafex.sprites.ParallaxSprite;
// import flixel.addons.effects.FlxSkewedSprite as FlxSprite;
import flixel.FlxCamera;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.group.FlxSpriteGroup;
import flixel.group.FlxGroup.FlxTypedGroup;
import grafex.states.playstate.PlayState;
import grafex.system.Paths;
import grafex.util.ClientPrefs;
import grafex.states.AchievementsGrfx;
import grafex.util.Utils;
import grafex.system.achievements.AchievementsToast.AchievementsToastManager;
import grafex.system.achievements.AchievementsToast.AchievementsToast;
import grafex.system.Conductor;
import grafex.system.CustomFadeTransition;

using StringTools;
#end

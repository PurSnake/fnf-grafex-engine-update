package grafex.states.options.substates;
#if FEATURE_FILESYSTEM
import sys.FileSystem;
import sys.io.File;
#end
import flixel.FlxG;
import grafex.util.Utils;
import grafex.util.ClientPrefs;


using StringTools;

class OptionsHelpers
{
    public static var ColorBlindArray = ['None', 'Deuteranopia', 'Protanopia', 'Tritanopia'];
    
    public static function getColorBlindByID(id:Int)
    {
        return ColorBlindArray[id];
    }

    static public function ChangeColorBlind(id:Int)
    {
        ClientPrefs.ColorBlindType = getColorBlindByID(id);
    }
}
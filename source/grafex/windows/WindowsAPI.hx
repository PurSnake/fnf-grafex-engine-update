package grafex.windows;
class WindowsAPI {


    public static function setDarkMode(enable:Bool) {
        #if windows
        native.WinAPI.setDarkMode(enable);
        #end
    } //only one fuckin function - Snake
}

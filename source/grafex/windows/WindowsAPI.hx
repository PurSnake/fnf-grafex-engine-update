package grafex.windows;
class WindowsAPI {
	public static function setDarkMode(enable:Bool) {
		#if windows
		native.WinAPI.setDarkMode(enable);
		#end
	} //only one fuckin function - Snake

	@:dox(hide) public static function registerAudio() {
		#if windows
		native.WinAPI.registerAudio();
		#end
	}
}

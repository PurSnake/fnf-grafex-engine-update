package grafex.sprites;

import flixel.system.FlxAssets.FlxShader;

class GrfxShader extends FlxShader {
	public function new(?glFragSource:String = '', ?glVertexSource:String = '')
	{
		glFragmentSource = glFragSource;
		glVertexSource = glFragSource;
		super();
	}
}
package grafex.system.ui;

import flixel.addons.ui.interfaces.IFlxUIWidget;
import flixel.addons.ui.interfaces.IHasParams;
import flixel.addons.ui.interfaces.IResizable;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUI;

/**
 * @author Lars Doucet
 * edited by richTrash21
 */
class UIInputTextAdvanced extends InputTextAdvanced implements IResizable implements IFlxUIWidget implements IHasParams
{
	public var name:String;

	public var broadcastToFlxUI:Bool = true;

	public static inline var CHANGE_EVENT:String = FlxUIInputText.CHANGE_EVENT; // change in any way
	public static inline var ENTER_EVENT:String  = FlxUIInputText.ENTER_EVENT; // hit enter in this text field
	public static inline var DELETE_EVENT:String = FlxUIInputText.DELETE_EVENT; // delete text in this text field
	public static inline var INPUT_EVENT:String  = FlxUIInputText.INPUT_EVENT; // input text in this text field
	public static inline var COPY_EVENT:String   = "copy_input_text"; // copy text in this text field
	public static inline var PASTE_EVENT:String  = "paste_input_text"; // paste text in this text field
	public static inline var CUT_EVENT:String    = "cut_input_text"; // cut text in this text field

	public function resize(w:Float, h:Float):Void
	{
		width = w;
		height = h;
		calcFrame();
	}

	private override function onChange(action:String):Void
	{
		super.onChange(action);
		if (broadcastToFlxUI)
		{
			switch (action)
			{
				case InputTextAdvanced.ENTER_ACTION: // press enter
					FlxUI.event(ENTER_EVENT, this, text, params);

				case InputTextAdvanced.DELETE_ACTION, InputTextAdvanced.BACKSPACE_ACTION: // deleted some text
					FlxUI.event(DELETE_EVENT, this, text, params);
					FlxUI.event(CHANGE_EVENT, this, text, params);

				case InputTextAdvanced.INPUT_ACTION: // text was input
					FlxUI.event(INPUT_EVENT, this, text, params);
					FlxUI.event(CHANGE_EVENT, this, text, params);

				case InputTextAdvanced.COPY_ACTION: // text was copied
					FlxUI.event(COPY_EVENT, this, text, params);

				case InputTextAdvanced.PASTE_ACTION: // text was pasted
					FlxUI.event(PASTE_EVENT, this, text, params);
					FlxUI.event(CHANGE_EVENT, this, text, params);

				case InputTextAdvanced.CUT_ACTION: // text was cut
					FlxUI.event(CUT_EVENT, this, text, params);
					FlxUI.event(CHANGE_EVENT, this, text, params);
			}
		}
	}
}

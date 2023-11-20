package grafex.system.ui;

import lime.system.Clipboard;

import flixel.addons.ui.FlxInputText;

// by richTrash21
class InputTextAdvanced extends FlxInputText
{
	public static inline var BACKSPACE_ACTION:String = FlxInputText.BACKSPACE_ACTION; // press backspace
	public static inline var DELETE_ACTION:String	 = FlxInputText.DELETE_ACTION; // press delete
	public static inline var ENTER_ACTION:String	 = FlxInputText.ENTER_ACTION; // press enter
	public static inline var INPUT_ACTION:String	 = FlxInputText.INPUT_ACTION; // manually edit
	public static inline var PASTE_ACTION:String	 = "paste"; // text paste
	public static inline var COPY_ACTION:String		 = "copy"; // text copy
	public static inline var CUT_ACTION:String		 = "cut"; // text copy

	override function update(elapsed:Float)
	{
		//super.update(elapsed);
		// cuz the main method needs to be overriden duhh
		FlxSpriteUpdate(elapsed);

		#if FLX_MOUSE
		// Set focus and caretIndex as a response to mouse press
		if (FlxG.mouse.justPressed)
		{
			var hadFocus:Bool = hasFocus;
			if (FlxG.mouse.overlaps(this, camera))
			{
				caretIndex = getCaretIndex();
				hasFocus = true;
				if (!hadFocus && focusGained != null)
					focusGained();
			}
			else
			{
				hasFocus = false;
				if (hadFocus && focusLost != null)
					focusLost();
			}
		}
		#end
	}

	// added these to skip super.update() since it will fuck everything up
	private function FlxSpriteUpdate(elapsed:Float)
	{
		FlxObjectUpdate(elapsed);
		updateAnimation(elapsed);
	}

	private function FlxObjectUpdate(elapsed:Float)
	{
		#if FLX_DEBUG
		// this just increments FlxBasic.activeCount, no need to waste a function call on release
		@:privateAccess flixel.FlxBasic.activeCount++;
		#end

		last.set(x, y);

		if (path != null && path.active)
			path.update(elapsed);

		if (moves)
			updateMotion(elapsed);

		wasTouching = touching;
		touching = flixel.util.FlxDirectionFlags.NONE;
	}

	override private function onKeyDown(e:flash.events.KeyboardEvent)
	{
		if (hasFocus)
		{
			var key:Int = e.keyCode;
			var targetKey = #if (macos) e.commandKey #else e.ctrlKey #end;

			if (targetKey)
			{
				switch (key)
				{
					// Crtl/Cmd + C to copy text to the clipboard
					// This copies the entire input, because i'm too lazy to do caret selection, and if i did it i whoud probabbly make it a pr in flixel-ui.
					case 67:
						Clipboard.text = text;
						onChange(COPY_ACTION);
						return; // Stops the function to go further, because it whoud type in a c to the input


					// Crtl/Cmd + V to paste in the clipboard text to the input
					case 86:
						var newText:String = filter(Clipboard.text);

						if (newText.length > 0 && (maxLength == 0 || (text.length + newText.length) < maxLength))
						{
							text = insertSubstring(text, newText, caretIndex);
							caretIndex += newText.length;
							onChange(FlxInputText.INPUT_ACTION);
							onChange(PASTE_ACTION);
						}
						return; // Same as before, but prevents typing out a v


					// Crtl/Cmd + X to cut the text from the input to the clipboard
					// Again, this copies the entire input text because there is no caret selection.
					case 88:
						Clipboard.text = text;
						text = '';
						caretIndex = 0;
	
						onChange(FlxInputText.INPUT_ACTION);
						onChange(CUT_ACTION);
	
						return; // Same as before, but prevents typing out a x
				}
			}
		}
		super.onKeyDown(e);
	}
}
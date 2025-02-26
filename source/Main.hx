package;

import funkin.backend.FunkinRatioScaleMode;
import funkin.backend.DebugDisplay;
import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxState;
import openfl.Lib;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.display.StageScaleMode;
#if mobile
import mobile.CopyState;
#end

class Main extends Sprite
{
	var gameWidth:Int = 1280; // Width of the game in pixels (might be less / more in actual pixels depending on your zoom).
	var gameHeight:Int = 720; // Height of the game in pixels (might be less / more in actual pixels depending on your zoom).
	static var initialState:Class<FlxState> = Init; // The FlxState the game starts with.
	var zoom:Float = -1; // If -1, zoom is automatically calculated to fit the window dimensions.
	var framerate:Int = 60; // How many frames per second the game should run at.
	var skipSplash:Bool = false; // Whether to skip the flixel splash screen that appears in release mode.
	var startFullscreen:Bool = false; // Whether to start the game in fullscreen on desktop targets

	public static var fpsVar:DebugDisplay;
	
	public static var scaleMode:FunkinRatioScaleMode;

	// You can pretty much ignore everything from here on - your code should go in your states.

	public static function main():Void
	{
		funkin.utils.MacroUtil.haxeVersionEnforcement();

		Lib.current.addChild(new Main());
		#if cpp
		cpp.NativeGc.enable(true);
		#elseif hl
		hl.Gc.enable(true);
		#end
	}

	public function new()
	{
		#if mobile
		#if android
		StorageUtil.requestPermissions();
		#end
		Sys.setCwd(StorageUtil.getStorageDirectory());
		#end

		#if mobile
		CrashHandler.init();
		#end

		#if windows
		@:functionCode("
		#include <windows.h>
		#include <winuser.h>
		setProcessDPIAware() // allows for more crisp visuals
		DisableProcessWindowsGhosting() // lets you move the window and such if it's not responding
		")
		#end
		
		super();

		if (stage != null)
		{
			init();
		}
		else
		{
			addEventListener(Event.ADDED_TO_STAGE, init);
		}
	}

	private function init(?E:Event):Void
	{
		if (hasEventListener(Event.ADDED_TO_STAGE))
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
		}

		setupGame();
	}

	private function setupGame():Void
	{
		ClientPrefs.loadDefaultKeys();

		var game:#if desktop FNFGame #else FlxGame #end = new #if desktop FNFGame #else FlxGame #end(gameWidth, gameHeight, #if (mobile && MODS_ALLOWED) !CopyState.checkExistingFiles() ? CopyState : #end Splash, framerate, framerate, skipSplash, startFullscreen);
		
		// FlxG.game._customSoundTray wants just the class, it calls new from
        // create() in there, which gets called when it's added to stage
        // which is why it needs to be added before addChild(game) here

		// Also btw game has to be a variable for this to work ig - Orbyy

		@:privateAccess
        game._customSoundTray = funkin.objects.FunkinSoundTray;

		addChild(game);

		fpsVar = new DebugDisplay(10, 3, 0xFFFFFF);
		#if !mobile
		addChild(fpsVar);
		#else
		FlxG.game.addChild(fpsVar);
		#end
		Lib.current.stage.align = "tl";
		Lib.current.stage.scaleMode = StageScaleMode.NO_SCALE;
		if(fpsVar != null) {
			fpsVar.visible = ClientPrefs.showFPS;
		}


		#if html5
		FlxG.autoPause = false;
		FlxG.mouse.visible = false;
		#end

		#if mobile
		lime.system.System.allowScreenTimeout = ClientPrefs.screensaver;
		#if android
		FlxG.android.preventDefaultKeys = [BACK]; 
		#end
		#end

		FlxG.signals.gameResized.add(onResize);
		FlxG.signals.preStateSwitch.add(onStateSwitch);
		FlxG.scaleMode = scaleMode = new FunkinRatioScaleMode();


	}
	private static function onStateSwitch() {
		scaleMode.resetSize();
	}


	static function onResize(w,h) 
	{
		final scale:Float = Math.max(1,Math.min(w / FlxG.width, h / FlxG.height));
		if (fpsVar != null) {
			fpsVar.scaleX = fpsVar.scaleY = scale;
		}

		@:privateAccess if (FlxG.cameras != null) for (i in FlxG.cameras.list) if (i != null && i.filters != null) resetSpriteCache(i.flashSprite);
		if (FlxG.game != null) resetSpriteCache(FlxG.game);
		
	}

	public static function resetSpriteCache(sprite:Sprite):Void
	{
		@:privateAccess 
		{
			sprite.__cacheBitmap = null;
			sprite.__cacheBitmapData = null;
		}
	}
}

class FNFGame extends FlxGame
{
	private static function crashGame() {
		null
		.draw();
	}

/**
* Used to instantiate the guts of the flixel game object once we have a valid reference to the root.
*/
	override function create(_):Void {
		try {
			_skipSplash = true;
			super.create(_);
		}
		catch (e)
			onCrash(e);
	}

	override function onFocus(_):Void {
		try
			super.onFocus(_)
		catch (e)
			onCrash(e);
	}

	override function onFocusLost(_):Void {
		try
			super.onFocusLost(_)
		catch (e)
			onCrash(e);
	}

	/**
	* Handles the `onEnterFrame` call and figures out how many updates and draw calls to do.
	*/
	override function onEnterFrame(_):Void {
		try
			super.onEnterFrame(_)
		catch (e)
			onCrash(e);
	}

	/**
	* This function is called by `step()` and updates the actual game state.
	* May be called multiple times per "frame" or draw call.
	*/
	override function update():Void {
		#if CRASH_TEST
		if (FlxG.keys.justPressed.F9)
			crashGame();
		#end
		try
			super.update()
		catch (e)
			onCrash(e);
	}

	/**
	* Goes through the game state and draws all the game objects and special effects.
	*/
	override function draw():Void {
		try
			super.draw()
		catch (e)
			onCrash(e);
	}

	private final function onCrash(e:haxe.Exception):Void {
		var emsg:String = "";
		for (stackItem in haxe.CallStack.exceptionStack(true)) {
			switch (stackItem) {
				case FilePos(s, file, line, column):
					emsg += file + " (line " + line + ")\n";
				default:
					Sys.println(stackItem);
					trace(stackItem);
			}
		}

		FlxG.switchState(new funkin.states.substates.CrashReportSubstate(FlxG.state, emsg, e.message));
	}
}

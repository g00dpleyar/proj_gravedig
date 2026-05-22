package ui.win;

#if sys
import sys.io.File;
import sys.FileSystem;
#end

private typedef TuningField = {
	var label : String;
	var name : String;
	var step : Float;
	var min : Float;
	var max : Float; // use -1 for no max
	var isInt : Bool;
}

class MovementDebugWindow extends ui.Window {
	static inline var PANEL_W = 340;
	static inline var PANEL_H = 185;
	static inline var PADDING = 6;

	var tuning : data.MovementTuning;
	var leftText : h2d.Text;
	var rightText : h2d.Text;
	var selected = 0;
	var editRepeatTimer = 0.06;

	static var fields : Array<TuningField> = [
		// Ground
		{ label:"G maxSpeed", name:"maxGroundSpeed", step:0.01, min:0, max:-1, isInt:false },
		{ label:"G accel", name:"groundAccel", step:0.005, min:0, max:-1, isInt:false },
		{ label:"G decel", name:"groundDecel", step:0.005, min:0, max:-1, isInt:false },
		{ label:"G turn", name:"groundTurnAccel", step:0.005, min:0, max:-1, isInt:false },
		{ label:"G accelMin", name:"groundAccelMin", step:0.001, min:0, max:-1, isInt:false },

		// Air
		{ label:"A maxSpeed", name:"maxAirSpeed", step:0.01, min:0, max:-1, isInt:false },
		{ label:"A accel", name:"airAccel", step:0.005, min:0, max:-1, isInt:false },
		{ label:"A decel", name:"airDecel", step:0.001, min:0, max:-1, isInt:false },
		{ label:"A turn", name:"airTurnAccel", step:0.005, min:0, max:-1, isInt:false },
		{ label:"A accelMin", name:"airAccelMin", step:0.001, min:0, max:-1, isInt:false },

		// Jump
		{ label:"jumpPower", name:"jumpPower", step:0.025, min:0, max:-1, isInt:false },
		{ label:"jumpCut", name:"jumpCutMultiplier", step:0.025, min:0, max:1, isInt:false },
		{ label:"coyote", name:"coyoteFrames", step:1, min:0, max:30, isInt:true },
		{ label:"buffer", name:"jumpBufferFrames", step:1, min:0, max:30, isInt:true },

		// Gravity
		{ label:"riseGrav", name:"riseGravity", step:0.005, min:0, max:-1, isInt:false },
		{ label:"apexGrav", name:"apexGravity", step:0.005, min:0, max:-1, isInt:false },
		{ label:"apexThres", name:"apexThreshold", step:0.005, min:0, max:-1, isInt:false },
		{ label:"fallGrav", name:"fallGravity", step:0.005, min:0, max:-1, isInt:false },
		{ label:"maxFall", name:"maxFallSpeed", step:0.025, min:0, max:-1, isInt:false },
	];

	public function new(tuning:data.MovementTuning) {
		super(false);

		this.tuning = tuning;

		setAlign(Start, Start);

		content.minWidth = PANEL_W;
		content.maxWidth = PANEL_W;
		content.minHeight = PANEL_H;
		content.maxHeight = PANEL_H;
		content.padding = PADDING;
		content.verticalSpacing = 4;
		content.backgroundTile = Col.white().toTile(1, 1, 0.65);

		addTitle("Movement Debug");

		var help = new h2d.Text(Assets.fontPixelMono, content);
		help.textColor = Black;
		help.text = "Up/Down select | Left/Right edit | S save | L load";

		var row = new h2d.Flow(content);
		row.layout = Horizontal;
		row.horizontalSpacing = 14;

		leftText = new h2d.Text(Assets.fontPixelMono, row);
		leftText.textColor = Black;

		rightText = new h2d.Text(Assets.fontPixelMono, row);
		rightText.textColor = Black;

		updateText();
	}

	function getValue(f:TuningField) : Float {
		return Std.parseFloat(Std.string(Reflect.field(tuning, f.name)));
	}

	function setValue(f:TuningField, v:Float) {
		if( v < f.min )
			v = f.min;

		if( f.max >= 0 && v > f.max )
			v = f.max;

		if( f.isInt )
			Reflect.setField(tuning, f.name, Std.int(Math.round(v)));
		else
			Reflect.setField(tuning, f.name, v);
	}

	function adjustSelected(dir:Int) {
		var f = fields[selected];
		setValue(f, getValue(f) + f.step * dir);
	}

	function fmt(f:TuningField) {
		var v = getValue(f);

		if( f.isInt )
			return Std.string(Std.int(v));

		return Std.string(Math.round(v * 1000) / 1000);
	}

	function makeLine(i:Int) {
		var f = fields[i];
		var marker = i==selected ? "> " : "  ";
		return marker + f.label + ": " + fmt(f);
	}

	function updateText() {
		var lines = [];

		for( i in 0...fields.length )
			lines.push(makeLine(i));

		var half = Math.ceil(lines.length / 2);

		leftText.text = lines.slice(0, half).join("\n");
		rightText.text = lines.slice(half).join("\n");
	}

	static inline var SAVE_PATH = "movement_tuning.json";

	function tuningToDynamic() {
		return {
			maxGroundSpeed: tuning.maxGroundSpeed,
			groundAccel: tuning.groundAccel,
			groundDecel: tuning.groundDecel,
			groundTurnAccel: tuning.groundTurnAccel,
			groundAccelMin: tuning.groundAccelMin,

			maxAirSpeed: tuning.maxAirSpeed,
			airAccel: tuning.airAccel,
			airDecel: tuning.airDecel,
			airTurnAccel: tuning.airTurnAccel,
			airAccelMin: tuning.airAccelMin,

			jumpPower: tuning.jumpPower,
			jumpCutMultiplier: tuning.jumpCutMultiplier,
			coyoteFrames: tuning.coyoteFrames,
			jumpBufferFrames: tuning.jumpBufferFrames,

			riseGravity: tuning.riseGravity,
			apexGravity: tuning.apexGravity,
			apexThreshold: tuning.apexThreshold,
			fallGravity: tuning.fallGravity,
			maxFallSpeed: tuning.maxFallSpeed,
		}
	}

	function applyTuningData(data:Dynamic) {
		if( Reflect.hasField(data, "maxGroundSpeed") ) tuning.maxGroundSpeed = cast Reflect.field(data, "maxGroundSpeed");
		if( Reflect.hasField(data, "groundAccel") ) tuning.groundAccel = cast Reflect.field(data, "groundAccel");
		if( Reflect.hasField(data, "groundDecel") ) tuning.groundDecel = cast Reflect.field(data, "groundDecel");
		if( Reflect.hasField(data, "groundTurnAccel") ) tuning.groundTurnAccel = cast Reflect.field(data, "groundTurnAccel");
		if( Reflect.hasField(data, "groundAccelMin") ) tuning.groundAccelMin = cast Reflect.field(data, "groundAccelMin");

		if( Reflect.hasField(data, "maxAirSpeed") ) tuning.maxAirSpeed = cast Reflect.field(data, "maxAirSpeed");
		if( Reflect.hasField(data, "airAccel") ) tuning.airAccel = cast Reflect.field(data, "airAccel");
		if( Reflect.hasField(data, "airDecel") ) tuning.airDecel = cast Reflect.field(data, "airDecel");
		if( Reflect.hasField(data, "airTurnAccel") ) tuning.airTurnAccel = cast Reflect.field(data, "airTurnAccel");
		if( Reflect.hasField(data, "airAccelMin") ) tuning.airAccelMin = cast Reflect.field(data, "airAccelMin");

		if( Reflect.hasField(data, "jumpPower") ) tuning.jumpPower = cast Reflect.field(data, "jumpPower");
		if( Reflect.hasField(data, "jumpCutMultiplier") ) tuning.jumpCutMultiplier = cast Reflect.field(data, "jumpCutMultiplier");
		if( Reflect.hasField(data, "coyoteFrames") ) tuning.coyoteFrames = Std.int(Reflect.field(data, "coyoteFrames"));
		if( Reflect.hasField(data, "jumpBufferFrames") ) tuning.jumpBufferFrames = Std.int(Reflect.field(data, "jumpBufferFrames"));

		if( Reflect.hasField(data, "riseGravity") ) tuning.riseGravity = cast Reflect.field(data, "riseGravity");
		if( Reflect.hasField(data, "apexGravity") ) tuning.apexGravity = cast Reflect.field(data, "apexGravity");
		if( Reflect.hasField(data, "apexThreshold") ) tuning.apexThreshold = cast Reflect.field(data, "apexThreshold");
		if( Reflect.hasField(data, "fallGravity") ) tuning.fallGravity = cast Reflect.field(data, "fallGravity");
		if( Reflect.hasField(data, "maxFallSpeed") ) tuning.maxFallSpeed = cast Reflect.field(data, "maxFallSpeed");
	}

	function saveTuning() {
		#if sys
		File.saveContent(SAVE_PATH, haxe.Json.stringify(tuningToDynamic(), null, "  "));
		trace("Saved movement tuning to " + SAVE_PATH);
		#end
	}

	function loadTuning() {
		#if sys
		if( !FileSystem.exists(SAVE_PATH) ) {
			trace("No movement tuning file found: " + SAVE_PATH);
			return;
		}

		var data = haxe.Json.parse(File.getContent(SAVE_PATH));
		applyTuningData(data);
		trace("Loaded movement tuning from " + SAVE_PATH);
		#end
	}

	override function update() {
		super.update();

		if( hxd.Key.isPressed(hxd.Key.UP) )
			selected--;

		if( hxd.Key.isPressed(hxd.Key.DOWN) )
			selected++;

		if( selected < 0 )
			selected = fields.length - 1;

		if( selected >= fields.length )
			selected = 0;

		var dt = 1.0 / Const.FPS;

		if( editRepeatTimer > 0 )
			editRepeatTimer -= dt;

		if( editRepeatTimer <= 0 ) {
			if( hxd.Key.isDown(hxd.Key.LEFT) ) {
				adjustSelected(-1);
				editRepeatTimer = 0.04;
			}

			if( hxd.Key.isDown(hxd.Key.RIGHT) ) {
				adjustSelected(1);
				editRepeatTimer = 0.04;
			}
		}
		
		if( hxd.Key.isPressed(hxd.Key.S) )
			saveTuning();

		if( hxd.Key.isPressed(hxd.Key.L) )
			loadTuning();

		updateText();
	}
}
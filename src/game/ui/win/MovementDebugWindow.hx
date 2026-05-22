package ui.win;

class MovementDebugWindow extends ui.Window {
	static inline var PANEL_W = 340;
	static inline var PANEL_H = 185;
	static inline var PADDING = 6;

	var tuning : data.MovementTuning;
	var leftText : h2d.Text;
	var rightText : h2d.Text;

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

		var row = new h2d.Flow(content);
		row.layout = Horizontal;
		row.horizontalSpacing = 14;

		leftText = new h2d.Text(Assets.fontPixelMono, row);
		leftText.textColor = Black;

		rightText = new h2d.Text(Assets.fontPixelMono, row);
		rightText.textColor = Black;

		updateText();
	}

	function updateText() {
		var lines = [
			"Horizontal",
			"maxGroundSpeed: " + tuning.maxGroundSpeed,
			"groundAccel: " + tuning.groundAccel,
			"groundDecel: " + tuning.groundDecel,
			"groundTurnAccel: " + tuning.groundTurnAccel,
			"groundAccelMin: " + tuning.groundAccelMin,

			"",
			"Air",
			"maxAirSpeed: " + tuning.maxAirSpeed,
			"airAccel: " + tuning.airAccel,
			"airDecel: " + tuning.airDecel,
			"airTurnAccel: " + tuning.airTurnAccel,
			"airAccelMin: " + tuning.airAccelMin,

			"",
			"Jump",
			"jumpPower: " + tuning.jumpPower,
			"jumpCutMultiplier: " + tuning.jumpCutMultiplier,
			"coyoteFrames: " + tuning.coyoteFrames,
			"jumpBufferFrames: " + tuning.jumpBufferFrames,

			"",
			"Gravity",
			"riseGravity: " + tuning.riseGravity,
			"apexGravity: " + tuning.apexGravity,
			"apexThreshold: " + tuning.apexThreshold,
			"fallGravity: " + tuning.fallGravity,
			"maxFallSpeed: " + tuning.maxFallSpeed,
		];

		var half = Math.ceil(lines.length / 2);

		leftText.text = lines.slice(0, half).join("\n");
		rightText.text = lines.slice(half).join("\n");
	}

	override function update() {
		super.update();
		updateText();
	}
}
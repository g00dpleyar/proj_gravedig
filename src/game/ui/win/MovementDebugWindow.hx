package ui.win;

class MovementDebugWindow extends ui.Window {
	static inline var PANEL_W = 340;
	static inline var PANEL_H = 185;
	static inline var PADDING = 6;

	var getTextCb : Void->String;
	var leftText : h2d.Text;
	var rightText : h2d.Text;

	public function new(getText:Void->String) {
		super(false);

		getTextCb = getText;

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
		var lines = getTextCb().split("\n");
		var half = Math.ceil(lines.length / 2);

		leftText.text = lines.slice(0, half).join("\n");
		rightText.text = lines.slice(half).join("\n");
	}

	override function update() {
		super.update();
		updateText();
	}
}
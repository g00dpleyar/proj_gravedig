package en;

class Hero extends Entity {
	var ca : dn.heaps.input.ControllerAccess<Dynamic>;

	public function new(x:Int, y:Int) {
		super(x, y);

		ca = App.ME.controller.createAccess();
	}

	override function dispose() {
		ca.dispose();

		super.dispose();
	}

	override function update() {
		super.update();

		if( ca.leftDown() || ca.isKeyboardDown(hxd.Key.LEFT) ) {
			dx -= 0.1 * tmod;
		}

		if( ca.rightDown() || ca.isKeyboardDown(hxd.Key.RIGHT) ) {
			dx += 0.1 * tmod;
		}
	}
}
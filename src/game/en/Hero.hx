package en;

/**
	Hero is the player-controlled platformer character.
	- user controlled (using gamepad or keyboard)
	- falls with gravity
	- has basic level collisions
	- some squash animations, because it's cheap and they do the job
**/

class Hero extends Entity {
	#if moveDebug
	var movementDebugWindow : Null<ui.win.MovementDebugWindow>;
	#end

	var ca : ControllerAccess<GameAction>;

	public var tuning = new data.MovementTuning();

	var horizontalInput = 0.;

	var jumpPressed = false;
	var jumpReleased = false;

	// Current remaining time
	var coyoteTimer = 0.;
	var jumpBufferTimer = 0.;

	// This is TRUE if the player is not falling
	var onGround(get,never) : Bool;
		inline function get_onGround() return !destroyed && vBase.dy==0 && yr==1 && level.hasCollision(cx,cy+1);


	public function new() {
		super(5,5);

		// Start point using level entity "PlayerStart"
		var start = level.data.l_Entities.all_PlayerStart[0];
		if( start!=null )
			setPosCase(start.cx, start.cy);

		// Misc inits
		vBase.setFricts(1, 0.94);

		// Camera tracks this
		camera.trackEntity(this, true);
		camera.clampToLevelBounds = true;

		// Init controller
		ca = App.ME.controller.createAccess();
		ca.lockCondition = Game.isGameControllerLocked;

		// Placeholder display
		var b = new h2d.Bitmap( h2d.Tile.fromColor(Red, iwid, ihei), spr );
		b.tile.setCenterRatio(0.5,1);
	}


	override function dispose() {
		super.dispose();
		ca.dispose(); // don't forget to dispose controller accesses
		#if moveDebug
		if( movementDebugWindow!=null && !movementDebugWindow.destroyed ) {
			movementDebugWindow.close();
			movementDebugWindow = null;
		}
		#end
	}


	/** X collisions **/
	override function onPreStepX() {
		super.onPreStepX();

		// Right collision
		if( xr>0.8 && level.hasCollision(cx+1,cy) )
			xr = 0.8;

		// Left collision
		if( xr<0.2 && level.hasCollision(cx-1,cy) )
			xr = 0.2;
	}


	/** Y collisions **/
	override function onPreStepY() {
		super.onPreStepY();

		// Land on ground
		if( yr>1 && level.hasCollision(cx,cy+1) ) {
			setSquashY(0.5);
			vBase.clearY();
			vBump.clearY();
			yr = 1;
			ca.rumble(0.2, 0.06);
			onPosManuallyChangedY();
		}

		// Ceiling collision
		if( yr<0.2 && level.hasCollision(cx,cy-1) )
			yr = 0.2;
	}


	/**
		Control inputs are checked at the beginning of the frame.
		VERY IMPORTANT NOTE: because game physics only occur during the `fixedUpdate` (at a constant 30 FPS), no physics increment should ever happen here! What this means is that you can SET a physics value (eg. see the Jump below), but not make any calculation that happens over multiple frames (eg. increment X speed when walking).
	**/
	override function preUpdate() {
		super.preUpdate();

		horizontalInput = 0;

		// Walk
		if( !isChargingAction() && ca.getAnalogDist2(MoveLeft,MoveRight)>0 ) {
			// As mentioned above, we don't touch physics values (eg. `dx`) here. We just store some "requested walk speed", which will be applied to actual physics in fixedUpdate.
			horizontalInput = ca.getAnalogValue2(MoveLeft,MoveRight); // -1 to 1
		}

		if( ca.isPressed(Jump) )
		jumpPressed = true;

		if( ca.isReleased(Jump) )
			jumpReleased = true;

		#if moveDebug
		if( hxd.Key.isPressed(hxd.Key.TAB) ) {
			if( movementDebugWindow==null || movementDebugWindow.destroyed )
				movementDebugWindow = new ui.win.MovementDebugWindow(getMovementDebugText);
			else {
				movementDebugWindow.close();
				movementDebugWindow = null;
			}
		}
		#end
	}


	override function fixedUpdate() {
		super.fixedUpdate();

		var fixedDt = 1.0 / Const.FIXED_UPDATE_FPS;

		// Coyote time
		if( onGround )
			coyoteTimer = tuning.coyoteFrames / 60;
		else if( coyoteTimer > 0 )
			coyoteTimer -= fixedDt;

		// Jump buffer
		if( jumpPressed )
			jumpBufferTimer = tuning.jumpBufferFrames / 60;
		else if( jumpBufferTimer > 0 )
			jumpBufferTimer -= fixedDt;

		// Jump
		if( coyoteTimer > 0 && jumpBufferTimer > 0 ) {
			vBase.addY(-tuning.jumpPower);
			setSquashX(0.6);

			coyoteTimer = 0;
			jumpBufferTimer = 0;

			fx.dotsExplosionExample(centerX, centerY, 0xffcc00);
			ca.rumble(0.05, 0.06);
		}

		// Variable jump height
		if( jumpReleased && vBase.dy < 0 ) {
			setBaseDy(vBase.dy * tuning.jumpCutMultiplier);
		}

		jumpPressed = false;
		jumpReleased = false;
		
		// Gravity
		if( !onGround ) {
			if( Math.abs(vBase.dy) <= tuning.apexThreshold )
				vBase.addY(tuning.apexGravity);
			else if( vBase.dy > 0 )
				vBase.addY(tuning.fallGravity);
			else
				vBase.addY(tuning.riseGravity);

			if( vBase.dy > tuning.maxFallSpeed )
				setBaseDy(tuning.maxFallSpeed);
		}

		// Apply requested walk movement
		if( onGround ) {
			var targetSpeed = horizontalInput * tuning.maxGroundSpeed;

			if( horizontalInput==0 ) {
				// No input: decelerate toward 0
				if( Math.abs(vBase.dx) <= tuning.groundDecel )
					vBase.clearX();
				else if( vBase.dx > 0 )
					vBase.addX(-tuning.groundDecel);
				else
					vBase.addX(tuning.groundDecel);
			}
			else if( vBase.dx!=0 && (vBase.dx>0) != (targetSpeed>0) ) {
				// Pressing opposite direction: turn around quickly
				if( targetSpeed > 0 )
					vBase.addX( Math.min(tuning.groundTurnAccel, targetSpeed - vBase.dx) );
				else
					vBase.addX( Math.max(-tuning.groundTurnAccel, targetSpeed - vBase.dx) );
			}
			else {
				// Pressing same direction: accelerate toward target speed,
				// but don't kill extra speed if we already have it.
				var speedDiff = targetSpeed - vBase.dx;
				var speedDiffRatio = Math.min(1, Math.abs(speedDiff) / tuning.maxGroundSpeed);

				var easedAccel = tuning.groundAccelMin + (tuning.groundAccel - tuning.groundAccelMin) * speedDiffRatio;

				if( targetSpeed > 0 && vBase.dx < targetSpeed )
					vBase.addX( Math.min(easedAccel, speedDiff) );

				if( targetSpeed < 0 && vBase.dx > targetSpeed )
					vBase.addX( Math.max(-easedAccel, speedDiff) );
			}
		}
		else {
		var targetSpeed = horizontalInput * tuning.maxAirSpeed;

		if( horizontalInput==0 ) {
			if( Math.abs(vBase.dx) <= tuning.airDecel )
				vBase.clearX();
			else if( vBase.dx > 0 )
				vBase.addX(-tuning.airDecel);
			else
				vBase.addX(tuning.airDecel);
		}
		else if( vBase.dx!=0 && (vBase.dx>0) != (targetSpeed>0) ) {
			if( targetSpeed > 0 )
				vBase.addX( Math.min(tuning.airTurnAccel, targetSpeed - vBase.dx) );
			else
				vBase.addX( Math.max(-tuning.airTurnAccel, targetSpeed - vBase.dx) );
		}
		else {
				var speedDiff = targetSpeed - vBase.dx;
				var speedDiffRatio = Math.min(1, Math.abs(speedDiff) / tuning.maxAirSpeed);
				var easedAccel = tuning.airAccelMin + (tuning.airAccel - tuning.airAccelMin) * speedDiffRatio;

				if( targetSpeed > 0 && vBase.dx < targetSpeed )
					vBase.addX( Math.min(easedAccel, speedDiff) );

				if( targetSpeed < 0 && vBase.dx > targetSpeed )
					vBase.addX( Math.max(-easedAccel, speedDiff) );
			}
		}
	}
	function setBaseDx(v:Float) {
	vBase.clearX();
	vBase.addX(v);
	}

	function setBaseDy(v:Float) {
		vBase.clearY();
		vBase.addY(v);
	}

	#if moveDebug
	public function getMovementDebugText() {
		return
			"Horizontal"
			+ "\ntuning.maxGroundSpeed: " + tuning.maxGroundSpeed
			+ "\ntuning.groundAccel: " + tuning.groundAccel
			+ "\ntuning.groundDecel: " + tuning.groundDecel
			+ "\ntuning.groundTurnAccel: " + tuning.groundTurnAccel
			+ "\ntuning.groundAccelMin: " + tuning.groundAccelMin

			+ "\n\nAir"
			+ "\ntuning.maxAirSpeed: " + tuning.maxAirSpeed
			+ "\ntuning.airAccel: " + tuning.airAccel
			+ "\ntuning.airDecel: " + tuning.airDecel
			+ "\ntuning.airTurnAccel: " + tuning.airTurnAccel
			+ "\ntuning.airAccelMin: " + tuning.airAccelMin

			+ "\n\nJump"
			+ "\ntuning.jumpPower: " + tuning.jumpPower
			+ "\ntuning.jumpCutMultiplier: " + tuning.jumpCutMultiplier
			+ "\ntuning.coyoteFrames: " + tuning.coyoteFrames
			+ "\ntuning.jumpBufferFrames: " + tuning.jumpBufferFrames

			+ "\n\nGravity"
			+ "\ntuning.riseGravity: " + tuning.riseGravity
			+ "\ntuning.apexGravity: " + tuning.apexGravity
			+ "\ntuning.apexThreshold: " + tuning.apexThreshold
			+ "\ntuning.fallGravity: " + tuning.fallGravity
			+ "\ntuning.maxFallSpeed: " + tuning.maxFallSpeed

			+ "\n\nState"
			+ "\nonGround: " + onGround
			+ "\nvBase.dx: " + vBase.dx
			+ "\nvBase.dy: " + vBase.dy;
	}
	#end
}
package data;

class MovementTuning {
	// Ground movement
	public var maxGroundSpeed = 0.32;
	public var groundAccel = 0.085;
	public var groundDecel = 0.12;
	public var groundTurnAccel = 0.16;
	public var groundAccelMin = 0.02;

	// Air movement
	public var maxAirSpeed = 0.32;
	public var airAccel = 0.025;
	public var airDecel = 0.004;
	public var airTurnAccel = 0.085;
	public var airAccelMin = 0.006;

	// Jump
	public var jumpPower = 0.85;
	public var jumpCutMultiplier = 0.45;
	public var coyoteFrames = 6;
	public var jumpBufferFrames = 6;

	// Gravity
	public var riseGravity = 0.05;
	public var apexGravity = 0.035;
	public var apexThreshold = 0.12;
	public var fallGravity = 0.08;
	public var maxFallSpeed = 0.95;

	public function new() {}
}
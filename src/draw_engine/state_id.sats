// Brush state identity. Tags 0..43 are the state slots.
datatype BrushState =
  | StX
  | StY
  | StPressure
  | StPartialDabs
  | StActualRadius
  | StN5
  | StN6
  | StN7
  | StN8
  | StN9
  | StN10
  | StN11
  | StN12
  | StN13
  | StActualX
  | StActualY
  | StNormDxSlow
  | StNormDySlow
  | StNormSpeed1Slow
  | StNormSpeed2Slow
  | StStroke
  | StStrokeStarted
  | StN22
  | StN23
  | StActualEllipticalDabRatio
  | StActualEllipticalDabAngle
  | StN26
  | StN27
  | StN28
  | StN29
  | StViewzoom
  | StViewrotation
  | StN32
  | StN33
  | StN34
  | StFlip
  | StN36
  | StN37
  | StN38
  | StN39
  | StDabsPerBasicRadius
  | StDabsPerActualRadius
  | StDabsPerSecond
  | StN43
  | StNone

fun state_of(i: int): BrushState = "ext#"
fun state_ix(id: BrushState): int = "ext#"

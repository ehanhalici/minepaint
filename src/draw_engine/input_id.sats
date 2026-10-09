// Mapping input identity. Tags 0..17 are the input slots.
datatype InputId =
  | InPressure
  | InRandom
  | InStroke
  | InDirection
  | InTiltDeclination
  | InTiltAscension
  | InSpeed1
  | InSpeed2
  | InCustom
  | InDirectionAngle
  | InAttackAngle
  | InTiltDeclinationX
  | InTiltDeclinationY
  | InGridmapX
  | InGridmapY
  | InViewzoom
  | InBrushRadius
  | InBarrelRotation
  | InNone

fun input_of(i: int): InputId = "ext#"
fun input_ix(id: InputId): int = "ext#"


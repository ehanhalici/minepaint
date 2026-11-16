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

// Tag kodlari yalniz bu sinirda: ix = tipli indeks (derleme zamaninda < 18), try = disaridan gelen int icin.
typedef InputIx = [k:nat | k < 18] int(k)

fun input_ix(id: InputId): InputIx = "ext#"
fun input_try(i: int): @(bool, InputId) = "ext#"
fun input_of(i: int): InputId = "ext#"

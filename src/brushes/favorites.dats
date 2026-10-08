#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"

extern fun favorites_brush_count(): int = "ext#favorites_brush_count"
implement favorites_brush_count() = 0

extern fun favorites_brush_name(i: int): string = "ext#favorites_brush_name"
implement favorites_brush_name(i) = ""

extern fun favorites_apply(b: int, i: int): void = "ext#favorites_apply"
implement favorites_apply(b, i) = ()

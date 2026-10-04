#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"

extern fun dieterle_brush_count(): int = "ext#dieterle_brush_count"
extern fun dieterle_brush_name(i: int): string = "ext#dieterle_brush_name"
extern fun dieterle_apply(b: ptr, i: int): void = "ext#dieterle_apply"
extern fun classic_brush_count(): int = "ext#classic_brush_count"
extern fun classic_brush_name(i: int): string = "ext#classic_brush_name"
extern fun classic_apply(b: ptr, i: int): void = "ext#classic_apply"
extern fun deevad_brush_count(): int = "ext#deevad_brush_count"
extern fun deevad_brush_name(i: int): string = "ext#deevad_brush_name"
extern fun deevad_apply(b: ptr, i: int): void = "ext#deevad_apply"
extern fun favorites_brush_count(): int = "ext#favorites_brush_count"
extern fun favorites_brush_name(i: int): string = "ext#favorites_brush_name"
extern fun favorites_apply(b: ptr, i: int): void = "ext#favorites_apply"
extern fun ramon_brush_count(): int = "ext#ramon_brush_count"
extern fun ramon_brush_name(i: int): string = "ext#ramon_brush_name"
extern fun ramon_apply(b: ptr, i: int): void = "ext#ramon_apply"
extern fun experimental_brush_count(): int = "ext#experimental_brush_count"
extern fun experimental_brush_name(i: int): string = "ext#experimental_brush_name"
extern fun experimental_apply(b: ptr, i: int): void = "ext#experimental_apply"
extern fun tanda_brush_count(): int = "ext#tanda_brush_count"
extern fun tanda_brush_name(i: int): string = "ext#tanda_brush_name"
extern fun tanda_apply(b: ptr, i: int): void = "ext#tanda_apply"
extern fun kaerhon_brush_count(): int = "ext#kaerhon_brush_count"
extern fun kaerhon_brush_name(i: int): string = "ext#kaerhon_brush_name"
extern fun kaerhon_apply(b: ptr, i: int): void = "ext#kaerhon_apply"

extern fun draw_engine_brush_prepare_load(b: ptr): void = "ext#draw_engine_brush_prepare_load"

extern fun brush_group_count(): int = "ext#brush_group_count"
implement brush_group_count() = 8

extern fun brush_group_name(g: int): string = "ext#brush_group_name"
implement brush_group_name(g) =
  case+ g of
  | 0 => "Dieterle"
  | 1 => "Classic"
  | 2 => "Deevad"
  | 3 => "Favorites"
  | 4 => "Ramon"
  | 5 => "Experimental"
  | 6 => "Tanda"
  | 7 => "Kaerhon"
  | _ => ""

extern fun brush_count(g: int): int = "ext#brush_count"
implement brush_count(g) =
  case+ g of
  | 0 => dieterle_brush_count()
  | 1 => classic_brush_count()
  | 2 => deevad_brush_count()
  | 3 => favorites_brush_count()
  | 4 => ramon_brush_count()
  | 5 => experimental_brush_count()
  | 6 => tanda_brush_count()
  | 7 => kaerhon_brush_count()
  | _ => 0

extern fun brush_name(g: int, i: int): string = "ext#brush_name"
implement brush_name(g, i) =
  case+ g of
  | 0 => dieterle_brush_name(i)
  | 1 => classic_brush_name(i)
  | 2 => deevad_brush_name(i)
  | 3 => favorites_brush_name(i)
  | 4 => ramon_brush_name(i)
  | 5 => experimental_brush_name(i)
  | 6 => tanda_brush_name(i)
  | 7 => kaerhon_brush_name(i)
  | _ => ""

extern fun catalog_apply_brush(b: ptr, g: int, i: int): void = "ext#catalog_apply_brush"
implement catalog_apply_brush(b, g, i) = let
  val () = draw_engine_brush_prepare_load(b)
in
  case+ g of
  | 0 => dieterle_apply(b, i)
  | 1 => classic_apply(b, i)
  | 2 => deevad_apply(b, i)
  | 3 => favorites_apply(b, i)
  | 4 => ramon_apply(b, i)
  | 5 => experimental_apply(b, i)
  | 6 => tanda_apply(b, i)
  | 7 => kaerhon_apply(b, i)
  | _ => ()
end

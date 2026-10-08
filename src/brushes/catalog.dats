#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"

// Harici Fırça Koleksiyonu İmzaları
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

// --- Cebirsel Veri Tipi: Fırça Grubu (Zero Magic Numbers, ADT) ---
datatype BrushGroup =
  | GroupDieterle of ()
  | GroupClassic of ()
  | GroupDeevad of ()
  | GroupFavorites of ()
  | GroupRamon of ()
  | GroupExperimental of ()
  | GroupTanda of ()
  | GroupKaerhon of ()

// Parse, Don't Validate Sınır Fonksiyonu
fn group_from_int(g: int): Option(BrushGroup) =
  case+ g of
  | 0 => Some(GroupDieterle())
  | 1 => Some(GroupClassic())
  | 2 => Some(GroupDeevad())
  | 3 => Some(GroupFavorites())
  | 4 => Some(GroupRamon())
  | 5 => Some(GroupExperimental())
  | 6 => Some(GroupTanda())
  | 7 => Some(GroupKaerhon())
  | _ => None()

// Tüketici Örüntü Eşleme: Grup Adı
fn group_get_name(grp: BrushGroup): string =
  case+ grp of
  | GroupDieterle() => "Dieterle"
  | GroupClassic() => "Classic"
  | GroupDeevad() => "Deevad"
  | GroupFavorites() => "Favorites"
  | GroupRamon() => "Ramon"
  | GroupExperimental() => "Experimental"
  | GroupTanda() => "Tanda"
  | GroupKaerhon() => "Kaerhon"

// Tüketici Örüntü Eşleme: Fırça Sayısı
fn group_get_count(grp: BrushGroup): int =
  case+ grp of
  | GroupDieterle() => dieterle_brush_count()
  | GroupClassic() => classic_brush_count()
  | GroupDeevad() => deevad_brush_count()
  | GroupFavorites() => favorites_brush_count()
  | GroupRamon() => ramon_brush_count()
  | GroupExperimental() => experimental_brush_count()
  | GroupTanda() => tanda_brush_count()
  | GroupKaerhon() => kaerhon_brush_count()

// Tüketici Örüntü Eşleme: Fırça İsmi
fn group_get_brush_name(grp: BrushGroup, i: int): string =
  case+ grp of
  | GroupDieterle() => dieterle_brush_name(i)
  | GroupClassic() => classic_brush_name(i)
  | GroupDeevad() => deevad_brush_name(i)
  | GroupFavorites() => favorites_brush_name(i)
  | GroupRamon() => ramon_brush_name(i)
  | GroupExperimental() => experimental_brush_name(i)
  | GroupTanda() => tanda_brush_name(i)
  | GroupKaerhon() => kaerhon_brush_name(i)

// Tüketici Örüntü Eşleme: Fırça Uygulama
fn group_apply_item(grp: BrushGroup, b: ptr, i: int): void =
  case+ grp of
  | GroupDieterle() => dieterle_apply(b, i)
  | GroupClassic() => classic_apply(b, i)
  | GroupDeevad() => deevad_apply(b, i)
  | GroupFavorites() => favorites_apply(b, i)
  | GroupRamon() => ramon_apply(b, i)
  | GroupExperimental() => experimental_apply(b, i)
  | GroupTanda() => tanda_apply(b, i)
  | GroupKaerhon() => kaerhon_apply(b, i)

// --- Dışa Açılan API (SLAP Orkestrasyon, SRP) ---
extern fun brush_group_count(): int = "ext#brush_group_count"
implement brush_group_count() = 8

extern fun brush_group_name(g: int): string = "ext#brush_group_name"
implement brush_group_name(g) =
  case+ group_from_int(g) of
  | Some(grp) => group_get_name(grp)
  | None() => ""

extern fun brush_count(g: int): int = "ext#brush_count"
implement brush_count(g) =
  case+ group_from_int(g) of
  | Some(grp) => group_get_count(grp)
  | None() => 0

extern fun brush_name(g: int, i: int): string = "ext#brush_name"
implement brush_name(g, i) =
  case+ group_from_int(g) of
  | Some(grp) => group_get_brush_name(grp, i)
  | None() => ""

extern fun catalog_apply_brush(b: ptr, g: int, i: int): void = "ext#catalog_apply_brush"
implement catalog_apply_brush(b, g, i) = let
  val () = draw_engine_brush_prepare_load(b)
in
  case+ group_from_int(g) of
  | Some(grp) => group_apply_item(grp, b, i)
  | None() => ()
end

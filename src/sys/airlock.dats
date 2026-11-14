#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
staload "sys/airlock.sats"

extern fun die_void_c (code: int): void = "mac#anth_die_void_c"
extern fun die_int_c (code: int): int = "mac#anth_die_int_c"
extern fun die_dbl_c (code: int): double = "mac#anth_die_dbl_c"
extern fun die_box_c {a:type} (code: int): a = "mac#anth_die_box_c"

implement die_event_code (e) =
  case+ e of
  | DieAllocFailed () => 1
  | DieContractViolation () => 2
  | DieFuelDab () => 15


implement anth_die_void (e) = die_void_c (die_event_code e)
implement anth_die_int (e) = die_int_c (die_event_code e)
implement anth_die_dbl (e) = die_dbl_c (die_event_code e)
implement anth_die_box {a} (e) = die_box_c {a} (die_event_code e)

implement anth_require (ok) =
  if ok then () else anth_die_void (DieContractViolation ())

// src/sys/effect_root.dats
// Ortam etkilerinin koku: LOG, CLOCK ve FS surec boyunca vardir (sunucu/baglam gibi acilip kapanmaz);
// kanitlari yalniz burada uretilir ve tuketilir. Program girisi (window_create_and_run) bir kez alir.
#define ATS_DYNLOADFLAG 0
#include "share/atspre_define.hats"
#include "share/atspre_staload.hats"
staload "sys/capability.sats"
staload "sys/log_io.sats"
staload "sys/clock_io.sats"
staload "sys/fs_io.sats"


extern fun env_open(): (LOG_IO, CLOCK_IO, FS_IO | void) = "ext#env_open"
implement env_open() =
  (cap_mint{KIND_LOG, 0}(), cap_mint{KIND_CLOCK, 0}(), cap_mint{KIND_FS, 0}() | ())

extern fun env_close(logio: LOG_IO, clk: CLOCK_IO, fsio: FS_IO | ): void = "ext#env_close"
implement env_close(logio, clk, fsio | ) = let
  prval () = cap_burn(logio)
  prval () = cap_burn(clk)
  prval () = cap_burn(fsio)
in () end

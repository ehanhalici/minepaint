// src/sys/airlock.hats
// Hava kilidi sozlesmesini ve olumcul cikis makrosunu bir arada getirir.
#ifndef AIRLOCK_HATS
#define AIRLOCK_HATS

staload "sys/airlock.sats"

// Herhangi bir donus tipi icin olumcul cikis: anth_die_void sureci sonlandirir,
// $raise yalnizca tip denetimini karsilar ve calismaz.
macdef anth_die_any (e) = (anth_die_void (,(e)); $raise AssertExn ())

#endif

;
; BLOK COPY RX COMPLETION SCREEN DATA
;

; Completion text
gd_text		dta d" ALL LEVELS RE-SYNCHRONISED! "

; Completion screen logo - standard version
gd_logo		dta d"             kk oo    oo                "
		dta d" ll   l  mm  kk oo   ooo  kk   mm   ll  "
		dta d" ll l l mm m kk oo  o oo k kk m mm ll l "
		dta d" ll l l mmm  kk oo  o oo k kk m mm lll  "
		dta d" ll l l mm   kk oo  o oo k kk m mm ll   "
		dta d"  llll   mm  kk oo   ooo  kk  m mm  ll  "

; Completion screen wipe effect (standard)
gd_wipe		dta $76,$77,$78,$79,$7a,$7b,$7c,$7d
		dta $7e,$7f

		dta $2a,$2b,$2c,$2d,$2e,$2f,$30,$31
		dta $32,$33

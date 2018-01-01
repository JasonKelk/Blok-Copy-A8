boot_override	equ $09
dos_vector	equ $0a
dos_init	equ $0c
attract_timer	equ $4d

dli_vector	equ $0200
dma_ctrl_s	equ $022f
dlist_vector	equ $0230
cold_start	equ $0244
priority_s	equ $026f
pm0_colour_s	equ $02c0
pm1_colour_s	equ $02c1
pm2_colour_s	equ $02c2
pm3_colour_s	equ $02c3
col_pfield0_s	equ $02c4
col_pfield1_s	equ $02c5
col_pfield2_s	equ $02c6
col_pfield3_s	equ $02c7
col_bgnd_s	equ $02c8
char_base_s	equ $02f4
ch		equ $02fc

pm0_collision	equ $d000	; read only
pm0_xpos	equ $d000	; write only
pm1_collision	equ $d001	; read only
pm1_xpos	equ $d001	; write only
pm2_collision	equ $d002	; read only
pm2_xpos	equ $d002	; write only
pm3_collision	equ $d003	; read only
pm3_xpos	equ $d003	; write only
pm4_collision	equ $d004	; read only
pm4_xpos	equ $d004	; write only
pm5_collision	equ $d005	; read only
pm5_xpos	equ $d005	; write only
pm6_collision	equ $d006	; read only
pm6_xpos	equ $d006	; write only
pm7_collision	equ $d007	; read only
pm7_xpos	equ $d007	; write only
pm0_expand	equ $d008
pm1_expand	equ $d009
pm2_expand	equ $d00a
pm3_expand	equ $d00b
pmm_expand	equ $d00c
pm0_colour	equ $d012
pm1_colour	equ $d013
pm2_colour	equ $d014
pm3_colour	equ $d015
col_pfield0	equ $d016
col_pfield1	equ $d017
col_pfield2	equ $d018
col_pfield3	equ $d019
col_bgnd	equ $d01a
gra_ctrl	equ $d01d

priority	equ $d01b
dma_ctrl	equ $d400
hscroll		equ $d404
vscroll		equ $d405
pm_base		equ $d407
char_base	equ $d409
wsync		equ $d40a
nmi_en		equ $d40e
// global $DATA_PERSONAS_new = "RUTA DONDE ESTA EL .DTA"
// global $DATA_HOGARES_new = "RUTA DONDE ESTA EL .DTA"

capture assert ("$DATA_PERSONAS_new" != "") | ("$DATA_HOGARES_new" != "") 
if (_rc) {
	noi display as error "Correr primero 01 - Compara Bases.do o definir las globales en este código!"
	error
}



use "$DATA_PERSONAS_new", replace

foreach var in "_06" "_11" "_30" "_31" "_29" "_28" "_32" "_37" {
    destring x`var', gen(X`var') force
	capture clonevar X`var' = x`var'
}

rename x_55 X_55 

keep X_* level1id

dta2sav *, name("$OUTPUTS\PERSONAS_spss") replace
// save "Personas_clean.dta", replace


use "$DATA_HOGARES_new", replace

foreach var in "iii_07" "iii_06" "iii_05" "iii_04" "iii_03" "iii_08" "iii_08b" "iii_10" "v_01" "v_05" "v_13a" "v_13b" "v_13c" "v_13d" "v_13e" "v_13f" "v_13g" "v_13h" "v_13i" "v_14a" "v_14b" "v_14c" "v_14d" "v_14e" "v_14f" "v_14g" "v_14h" "v_14i" {
	capture replace v`var' = subinstr(v`var', ",", ".", .)
    destring `var', replace force
	rename `var' `=upper("`var'")'
}

rename v_10 V_10

destring tot_per, gen(Tot_per) force
drop tot_per

keep level1id V_* III_* Tot_per

dta2sav *, name("Data_out\HOGARES_spss") replace


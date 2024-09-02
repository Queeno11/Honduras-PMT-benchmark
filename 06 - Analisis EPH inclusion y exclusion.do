// use data_indice_multidimensional.dta, replace
//
// preserve
// keep if UR==1
// collapse (mean) pobreza_multidim no_pob_multidim, by(QUINTILH)
// export excel "pob_multidim_quintiles_ur.xlsx", firstrow(var) replace
// restore
//
// preserve
// keep if UR==2
// collapse (mean) pobreza_multidim no_pob_multidim, by(QUINTILH)
// export excel "pob_multidim_quintiles_ru.xlsx", firstrow(var) replace
// restore
//
// preserve
// keep if DOMINIO==1
// collapse (mean) pobreza_multidim no_pob_multidim, by(QUINTILH)
// export excel "pob_multidim_quintiles_tegucigalpa.xlsx", firstrow(var) replace
// restore
//
// preserve
// keep if DOMINIO==2
// collapse (mean) pobreza_multidim no_pob_multidim, by(QUINTILH)
// export excel "pob_multidim_quintiles_sanpedrosula.xlsx", firstrow(var) replace
// restore


use data_indice_multidimensional.dta, replace

foreach var in indice_pobreza_multi ingreso_est {

if "`var'"=="ingreso_est" {
	use basepmt.dta, replace
	gen pobreza = inlist(POBREZA, 1, 2)
	gen no_pobreza = 1-pobreza
	gen pobreza_ext = inlist(POBREZA, 1)
	gen no_pobreza_ext = 1-pobreza_ext
	drop pos
	drop if `var'==.
	gsort `var' 
	gen pos = _n / _N
}
if "`var'"=="indice_pobreza_multi" {
	use data_indice_multidimensional.dta, replace
	drop if `var'==.
	gsort -`var' 
	gen pos = _n / _N
}


foreach zona in "tot" "ur" "ru" {
	preserve
    if "`zona'" == "tot" {
	    local zona = ""
	}
	if "`zona'" == "ur" {
		keep if UR==1
	}
	if "`zona'" == "ru" {
		keep if UR==2
	}
	
	capture matrix drop results`zona'
	* Create an empty matrix to store results
	matrix define results`zona' = J(100, 3, .)

	* Loop over indicator values from 1 to 100
	count if pobreza==1
	local tot_pobres = r(N)
	forval i = 1/100 {
		
		* Store the value of `i` and the mean in the results matrix
		matrix results`zona'[`i', 1] = `i'
		
		* Subcobertura
		count if pobreza==1 & pos > `i'/100
		matrix results`zona'[`i', 2] = r(N) / `tot_pobres'
		
		* Filtraciones
		count if pos < `i'/100
		local incluidos = r(N)
		count if pos < `i'/100 & pobreza==0
		local incl_no_pob = r(N)
		matrix results`zona'[`i', 3] = `incl_no_pob' / `incluidos'
	}
	restore
}

clear
* Convert the matrix to a data frame for easy export
svmat results, names(call)
svmat resultsur, names(cur)
svmat resultsru, names(cru)

* Rename the columns for clarity
rename c*1 corte*
rename c*2 subcobertura*
rename c*3 filtraciones*
drop corteur corteru

replace filtracionesall = 0 if filtracionesall==.
replace filtracionesur = 0 if filtracionesur==.
replace filtracionesru = 0 if filtracionesru==.

* Export the results to an Excel file
export excel using "filtraciones_`var'.xlsx", firstrow(variables) replace
}

stop
collapse (mean) indice_pobreza_multi=indice_pobreza_multi privacion_agua_h=privacion_agua_h privacion_saneamiento_h=privacion_saneamiento_h privacion_cocina_h=privacion_cocina_h privacion_educ_h=privacion_educ_h privacion_asistencia_h=privacion_asistencia_h privacion_alfab_h=privacion_alfab_h privacion_segsoc_h=privacion_segsoc_h privacion_desocup_h=privacion_desocup_h privacion_subemp_h=privacion_subemp_h privacion_ocup_h=privacion_ocup_h privacion_trabinf_h=privacion_trabinf_h privacion_trabadol1_h=privacion_trabadol1_h privacion_trabadol2_h=privacion_trabadol2_h privacion_elec_h=privacion_elec_h privacion_piso_h=privacion_piso_h privacion_techo_h=privacion_techo_h privacion_pared_h=privacion_pared_h privacion_hacina_h=privacion_hacina_h (count) q_privacion_agua_h=privacion_agua_h q_privacion_saneamiento_h=privacion_saneamiento_h q_privacion_cocina_h=privacion_cocina_h q_privacion_educ_h=privacion_educ_h q_privacion_asistencia_h=privacion_asistencia_h q_privacion_alfab_h=privacion_alfab_h q_privacion_segsoc_h=privacion_segsoc_h q_privacion_desocup_h=privacion_desocup_h q_privacion_subemp_h=privacion_subemp_h q_privacion_ocup_h=privacion_ocup_h q_privacion_trabinf_h=privacion_trabinf_h q_privacion_trabadol1_h=privacion_trabadol1_h q_privacion_trabadol2_h=privacion_trabadol2_h q_privacion_elec_h=privacion_elec_h q_privacion_piso_h=privacion_piso_h q_privacion_techo_h=privacion_techo_h q_privacion_pared_h=privacion_pared_h q_privacion_hacina_h=privacion_hacina_h, by(QUINTILH)
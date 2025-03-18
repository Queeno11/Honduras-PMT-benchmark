clear all
cd "D:\World Bank\Honduras PMT benchmark"
program define analisis_focalizacion, eclass
    syntax , variable(string) urban(integer)
	frame change default
	capture frame drop main
	capture frame drop resultados
	frame create main
	frame create resultados
	
	frame change main
	
	if "`variable'" == "ingreso_est" {
		use "Data_out/basepmt_eph.dta", replace
		gen pobreza = inlist(POBREZA, 1, 2)
		gen no_pobreza = 1 - pobreza
		gen pobreza_ext = inlist(POBREZA, 1)
		gen no_pobreza_ext = 1 - pobreza_ext
		drop pos
		drop if `variable' == .
		gsort `variable'
		gen pos = _n / _N
	}

	if "`variable'" == "indice_pobreza_multi" {
		use "Data_out/data_indice_multidimensional_consolidada.dta", replace
		drop if `variable' == .
		gsort -`variable'
		gen pos = _n / _N
	}

	if `urban'!=0 {
		keep if UR==`urban'
	}
	

	qui forvalues s = 1/1000{
		di "." _cont

		preserve
		bsample 
		display `s'
		*** Process to bootstrap
		* Create an empty matrix to store results
		matrix define results_`s' = J(100, 2, 0)
		
		* Loop over indicator values from 1 to 100
		count if pobreza == 1

		local tot_pobres = r(N)
		forval i = 1/100 {
			
			* Subcobertura
			count if pobreza == 1 & pos > `i'/100
			matrix results_`s'[`i', 1] = r(N) / `tot_pobres'
		
			* Filtraciones
			count if pos < `i'/100
			local incluidos = r(N)
			count if pos < `i'/100 & pobreza == 0
			local incl_no_pob = r(N)
			matrix results_`s'[`i', 2] = `incl_no_pob' / `incluidos'
		}	
		frame change  resultados
		svmat results_`s', names(c_`s'_)
		rename (c_`s'_1 c_`s'_2) (subcobertura_`s' filtraciones_`s')
		frame change main

		restore

	}
	frame change  resultados
	gen threshold = _n
	reshape long subcobertura_ filtraciones_, i(threshold) j(sample)
	collapse (mean) subcobertura=subcobertura_ filtraciones=filtraciones_ (p05) subcobertura_p05=subcobertura_ filtraciones_p05=filtraciones_ (p95) subcobertura_p95=subcobertura_ filtraciones_p95=filtraciones_, by(threshold)

end

foreach urban in 0 1 2 {
	foreach var in indice_pobreza_multi ingreso_est  {
		analisis_focalizacion, variable(`var') urban(`urban')
		export excel using "Outputs/indicadores_bootstrap_`var'_urban`urban'.xlsx", replace firstrow(variables)
	}
}

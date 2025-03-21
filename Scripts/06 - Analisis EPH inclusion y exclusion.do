clear all
global PATH = "D:\World Bank\Honduras PMT benchmark"
global DATA_OUT = "$PATH\Data_out"
global OUTPUTS = "$PATH\Outputs"

program define analisis_focalizacion, eclass
    syntax , variable(string) urban(integer) [test_set(string)]
	
	frame change default
	capture frame drop main
	capture frame drop resultados
	frame create main
	frame create resultados
	
	frame change main
	
	use "$DATA_OUT/preds lasso pmt.dta", replace
	merge 1:1 HOGAR using "$DATA_OUT/Predicts_XGBoost.dta"

	* With this, UR = 1 is rural and UR = 2 is urban. `urban'==0 means all
	replace UR = UR+1
	save "$DATA_OUT\Consolidada con logs estimaciones", replace
	
	if `urban'!=0 {
		keep if UR==`urban'
	}

	if "`test_set'"=="test_set" {
	    keep if test_set==1
	}

	gen linea_pob_extr = .
	replace linea_pob_extr = 2465.97 if UR==1
	replace linea_pob_extr = 1901.71 if UR==2

	gen linea_pob = .
	replace linea_pob = 4931.94 if UR==1
	replace linea_pob = 2538.78 if UR==2
	
	gen pobre = (YPERHG < linea_pob)
	gen pobre_extr = (YPERHG < linea_pob_extr)
	
	drop if `variable' == .
	drop if pobre == .
	
	if "`variable'"=="indice_pobreza_multi" {
		gsort UR -`variable'
	}
	else {	
		gsort UR `variable'
	}
	by UR: gen q_personas = sum(FACTOR_P) 
	by UR: egen tot_personas = sum(FACTOR_P) 
	by UR: gen pos = q_personas/tot_personas


	qui forvalues s = 1/1000{
		di "." _cont

		preserve
		bsample 
		display `s'
		*** Process to bootstrap
		* Create an empty matrix to store results
		matrix define results_`s' = J(100, 2, 0)
		
		* Loop over indicator values from 1 to 100
		count if pobre == 1

		local tot_pobres = r(N)
		forval i = 1/100 {
			
			* Subcobertura
			count if pobre == 1 & pos > `i'/100
			matrix results_`s'[`i', 1] = r(N) / `tot_pobres'
		
			* Filtraciones
			count if pos < `i'/100
			local incluidos = r(N)
			count if pos < `i'/100 & pobre == 0
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
	* 0 is all, 1 is rural, 2 is urban
	foreach var in log_ingreso_pred_lasso_urru_c2 indice_pobreza_multi { // logingreso_xgboost {
		analisis_focalizacion, variable(`var') urban(`urban')
		export excel using "$OUTPUTS/indicadores_bootstrap_`var'_urban`urban'.xlsx", replace firstrow(variables)
	}
}

clear all

foreach urban in 0 1 2 {
	
	use "$DATA_OUT/preds lasso pmt.dta", replace
	merge 1:1 HOGAR using "$DATA_OUT/Predicts_XGBoost.dta"
	replace UR = UR + 1
	bysort DOMINIO: egen total_pobre_weight = total(pobreza * FACTOR_P)
	bysort DOMINIO: egen total_weight = total(FACTOR_P)
	gen porcentaje_inclusion = total_pobre_weight / total_weight
	
	gen personas = 1

	if "`urban'"!="0" {
		keep if UR==`urban'
	}
	# Como nos interesa calcular la cantidad de personas,
	#	ajusto los factores de ponderación por la proporción de personas
	#	que se incluyen en la población beneficiaria (zonas donde se focaliza)
	#	en zonas rurales es aproximadamente el 31% y en zonas urbanas es aproximadamente el 21%
	# 	Idealmente nos gustaría seleccionar a las personas de esos lugares, pero no tenemos esa información
	replace FACTOR_P = FACTOR_P*.21 if UR==1
	replace FACTOR_P = FACTOR_P*.3095 if UR==2
	drop if indice_pobreza_multi==.
	drop if YPERHG==.
	
	gen indice_pobreza_multi_neg = -indice_pobreza_multi

	gsort -indice_pobreza_multi
	gen q_personas = sum(FACTOR_P) 
	egen tot_personas = sum(FACTOR_P) 
	gen pos_IPM = q_personas/tot_personas
	gen pobre_IPM = (indice_pobreza_multi>=0.25)
	drop q_personas tot_personas 

	gsort YPERHG
	gen q_personas = sum(FACTOR_P) 
	egen tot_personas = sum(FACTOR_P) 
	gen pos_YPERHG = _n / _N
	gen decil_ingreso = ceil(pos_YPERHG*10)
	drop q_personas tot_personas 

	foreach var in log_ingreso_pred_lasso_urru_c2 logingreso_xgboost indice_pobreza_multi_neg {
		gsort `var'
		local newname = subinstr("`var'", "log_ingreso_pred_", "", .)
		gen pos_`newname' = _n / _N
		gen pobre_`newname' = (pos_`newname'<=porcentaje_inclusion)
	}
	
	preserve
	collapse (mean) pobre_* (sum) personas [iw=FACTOR_P], by(decil_ingreso)
	replace personas = round(personas)
	export excel using "$OUTPUTS/targeting_deciles_ur`urban'.xlsx", replace firstrow(variables)
	restore


	* Only test set
	preserve
	keep if test_set==1
	replace FACTOR_P = FACTOR_P*3
	collapse (mean) pobre_* (sum) personas [iw=FACTOR_P], by(decil_ingreso)
	
	replace personas = round(personas)
	export excel using "$OUTPUTS/targeting_deciles_ur`urban'_test.xlsx", replace firstrow(variables)
	restore

	* Redistribution
	preserve
	gen cambio = pobre_IPM - pobre_lasso_urru_c2
	gen nuevo_asignado = (cambio==-1)
	gen nuevo_excluido = (cambio==1)
	gen mantiene = (cambio==0)

	collapse (sum) nuevo_asignado nuevo_excluido mantiene [iw=FACTOR_P], by(decil_ingreso)
	replace nuevo_excluido = - nuevo_excluido 
	export excel using "$OUTPUTS/redistribucion_ur`urban'.xlsx", replace firstrow(variables)
	restore

}



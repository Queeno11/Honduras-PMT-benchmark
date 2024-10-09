clear all

global Path = "D:\World Bank\Honduras PMT benchmark"
global Data_out = "$Path\Data_out"
global Outputs = "$Path\Outputs"

foreach urban in 0 1 2 {

	
	use "$Data_out/preds lasso pmt.dta", replace
	merge 1:1 HOGAR using "$Data_out/Predicts_XGBoost.dta"
	replace UR = UR + 1
	gen FACTOR_P = FACTOR * TOTPER
	gen personas = 1

	if "`urban'"!="0" {
		keep if UR==`urban'
	}
	drop if indice_pobreza_multi==.
	drop if YPERHG==.
	
	gsort -indice_pobreza_multi
	gen pos_IPM = _n / _N

	gsort YPERHG
	gen pos_YPERHG = _n / _N
	gen decil_ingreso = ceil(pos_YPERHG*10)

	gen pobre_IPM = (indice_pobreza_multi>=0.25)

	foreach var in log_ingreso_pred_lasso_urru_c2 log_ingreso_pred_carlos logingreso_xgboost indice_pobreza_multi {
		gsort `var'
		local newname = subinstr("`var'", "log_ingreso_pred_", "", .)
		gen pos_`newname' = _n / _N
		
		qui sum pobre_IPM
		gen pobre_`newname' = (pos_`newname'<=r(mean))
	}
	collapse (mean) pobre_* (sum) personas [iw=FACTOR_P], by(decil_ingreso)
	
	replace personas = round(personas)
	export excel using "$Outputs/targeting_deciles_ur`urban'.xlsx", replace firstrow(variables)

}



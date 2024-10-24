clear all
global Path = "D:\World Bank\Honduras PMT benchmark"
global Data_out = "$Path\Data_out"
global Outputs = "$Path\Outputs"

use "$Data_out/preds lasso pmt.dta", replace
merge 1:1 HOGAR using "$Data_out/Predicts_XGBoost.dta"

gen FACTOR_P = FACTOR * TOTPER

drop if mi(indice_pobreza_multi)
drop if mi(log_ingreso_pred_lasso_urru_c)

******************************************
******    Indicadores de posición   ******
******************************************

gsort UR -indice_pobreza_multi 
by UR: gen ranking_IPM = _n/_N

sort UR log_ingreso_pred_lasso_urru_c 
by UR: gen ranking_PMT = _n/_N

levelsof UR, local(urban_rural)
gen asignado_IPM = .
gen asignado_PMT = .
foreach is_ur in `urban_rural' {
	qui sum pobreza [w=FACTOR_P] if UR==`is_ur'
	replace asignado_IPM = (ranking_IPM<r(mean)) if UR==`is_ur'
	replace asignado_PMT = (ranking_PMT<r(mean)) if UR==`is_ur'
}


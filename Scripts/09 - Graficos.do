clear all
global Path = "D:\World Bank\Honduras PMT benchmark"
global Data_out = "$Path\Data_out"
global Outputs = "$Path\Outputs"

// use "Data_out/data_indice_multidimensional_consolidada", replace

graph set window fontface "Times New Roman"
global graph_aspect = "graphregion(color(white)) plotregion(margin(zero))"

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


******************************************
******    	Scatter	errores	   		******
******************************************
levelsof UR, local(urban_rural)
gen asignado_IPM = .
gen asignado_PMT = .
foreach is_ur in `urban_rural' {
	qui sum pobreza [w=FACTOR_P] if UR==`is_ur'
	replace asignado_IPM = (ranking_IPM<r(mean)) if UR==`is_ur'
	replace asignado_PMT = (ranking_PMT<r(mean)) if UR==`is_ur'
}

twoway (scatter ranking_IPM ranking_PMT if UR==1, msize(tiny) mstyle(smcircle) mcolor(edkblue%20)), yline(.665, lcolor(orange_red%80)) xline(.665, lcolor(orange_red%80)) title("Urbano") xtitle("Percentil Ingreso Estimado por Proxy Means Test (PMT)") ytitle("Percentil Indice de Pobreza Multidimensional (IPM)") text(.61 0.015 "Pobres por" "ambos indicadores" 0.95 0.015 "Pobres según PMT" 0.95 0.675 "No pobres por" "ambos indicadores"  0.61 0.675 "Pobres según IPM", placement(northeast) justification(left) box bcolor(white%70))  xsize(6) $graph_aspect name(urban)

twoway (scatter ranking_IPM ranking_PMT if UR==0, msize(tiny) mstyle(smcircle) mcolor(edkblue%20)), title("Rural") yline(.667, lcolor(orange_red%80)) xline(.667, lcolor(orange_red%80)) xtitle("Percentil Ingreso Estimado por Proxy Means Test (PMT)") ytitle("Percentil Indice de Pobreza Multidimensional (IPM)") text(.61 0.015 "Pobres por" "ambos indicadores" 0.95 0.015 "Pobres según PMT" 0.95 0.675 "No pobres por" "ambos indicadores"  0.61 0.675 "Pobres según IPM", placement(northeast) justification(left) box bcolor(white%70))  xsize(6) $graph_aspect name(rural)

* Combine the two graphs side by side
graph combine urban rural, ///
    xsize(10) ysize(5)
graph export "$Outputs/inclusion y exclusion.png", width(1500) replace

stop
******************************************
******    	BOXPLOT Excluídos		******
******************************************


gen no_pob_indicator = ""
replace no_pob_indicator = "Ingreso de excluídos (IPM)" if asignado_IPM==0 
replace no_pob_indicator = "Ingreso de excluídos (PMT)" if asignado_PMT==0
gen YPERHG_nopob_PMT = YPERHG if no_pob_indicator=="Ingreso de excluídos (PMT)"
label var YPERHG_nopob_PMT  "Ingreso de excluídos (PMT)"
gen YPERHG_nopob_IPM = YPERHG if no_pob_indicator=="Ingreso de excluídos (IPM)"
label var YPERHG_nopob_IPM  "Ingreso de excluídos (IPM)"

preserve 
local N = _N
expand 2
gen byte new = _n > `N'
replace UR = UR +1 
replace UR = 0 if new
label define urban 0 "Total" 1 "Urbano" 2 "Rural"
label values UR urban 

graph hbox YPERHG_nopob_IPM YPERHG_nopob_PMT [w=FACTOR], nooutsides over(UR) aspectratio(0.6) box(1, color(243 145 21) fcolor(243 145 21) fintensity(inten40)) box(2, color(114 156 177) fcolor(148 202 228) fintensity(inten100))  legend(region(lstyle(none)) cols(1) label(2 "Ingreso per capita de hogares excluídos por PMT") label(1 `"Ingreso per capita de hogares excluídos por IPM"')) $graph_aspect
graph export "D:\World Bank\Honduras PMT benchmark\Outputs\boxplot_excluídos.png", width(1500) replace
sum YPERHG_nopob_IPM YPERHG_nopob_PMT, d
stop
restore
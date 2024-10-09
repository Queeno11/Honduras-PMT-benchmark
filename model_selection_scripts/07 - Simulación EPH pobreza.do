clear all
global Path = "D:\World Bank\Honduras PMT benchmark"
global Data_out = "$Path\Data_out"
global Outputs = "$Path\Outputs"

graph set window fontface "Times New Roman"
global graph_aspect = "graphregion(color(white)) plotregion(margin(zero))"

use "$Data_out/preds lasso pmt.dta", replace
merge 1:1 HOGAR using "$Data_out/Predicts_XGBoost.dta"

******************************************
******    Indicadores de posición   ******
******************************************
gen FACTOR_P = round(FACTOR * TOTPER )
*** IPM
rename indice_pobreza_multi SumIPM
gsort -SumIPM
gen ranking_IPM = _n/_N
gen pobre_IPM = (SumIPM>=.25)
gen pobre_IPM_alt = (SumIPM>.25)
gen pobre_IPM_25 = (ranking_IPM<=.25)
gen pobre_IPM_50 = (ranking_IPM<=.5)
gen pobre_IPM_75 = (ranking_IPM<=.75)
gen pobre_IPM_90 = (ranking_IPM<=.90)
**  39.62 es el % de pobres por IPM (IPM>=.25)

* Deciles
gen decil_IPM = ceil(ranking_IPM * 10)
gen quintil_IPM = ceil(ranking_IPM * 5)

// scatter ranking_IPM ranking_PMT
// heatplot ranking_IPM ranking_PMT


**********************************************
******   	  Microsimulaciones 	     *****
**********************************************

** Inferencia de la línea de pobreza de YPERHG
* NOTA: no tenemos la linea de pobreza en la base, pero la podemos inferir, porque si hacemos estos gráficos que siguen acá, vemos que el salto es discreto entre los dos histogramas
// twoway (hist YPERHG  if POBREZA==1 & DOMINIO==4, color(red%30)) (hist YPERHG  if POBREZA==2  & DOMINIO==4 , color(green%30)) (hist YPERHG  if POBREZA==3 & YPERHG<10000 & DOMINIO==4 , color(blue%30))

gen linea_pob_extr = .
replace linea_pob_extr = 2468 if UR==1
replace linea_pob_extr = 1900 if UR==2

gen linea_pob = .
replace linea_pob = 4930 if UR==1
replace linea_pob = 2540 if UR==2

gen pobre = (YPERHG < linea_pob)
gen pobre_extr = (YPERHG < linea_pob_extr)

qui foreach ind in log_ingreso_pred_lasso_urru_c2 log_ingreso_pred_carlos logingreso_xgboost ranking_IPM {

	sort `ind'	
	gen pos = _n / _N if UR==1
	stop
	gen asignado = ()
	y 
	gen asignacion_`ind' = 0
	replace asignacion_`ind' = 8040/12 if pobre_`ind'==1
	gen asignacion_`ind'_pc = asignacion_`ind' / TOTPER 
	gen YPERHG_`ind' = YPERHG + asignacion_`ind'_pc
	gen pobre_sim_`ind' = (YPERHG_`ind' < linea_pob)
	gen pobre_sim_`ind'_fgt1 = pobre_sim_`ind' * (1-YPERHG_`ind'/linea_pob)
	gen pobre_sim_`ind'_fgt2 = pobre_sim_`ind' * (1-YPERHG_`ind'/linea_pob)^2
	
	gen pobre_extr_sim_`ind' = (YPERHG_`ind' < linea_pob_extr)
	gen pobre_extr_sim_`ind'_fgt1 = pobre_extr_sim_`ind' * (1-YPERHG_`ind'/linea_pob_extr)
	gen pobre_extr_sim_`ind'_fgt2 = pobre_extr_sim_`ind' * (1-YPERHG_`ind'/linea_pob_extr)^2
	
}

noi mean pobre
noi mean pobre_sim_PMT
noi mean pobre_sim_IPM
noi mean pobre_sim_PMT_fgt1
noi mean pobre_sim_IPM_fgt1
noi mean pobre_sim_PMT_fgt2
noi mean pobre_sim_IPM_fgt2
stop

noi mean pobre_extr if UR==2
noi mean pobre_extr_sim_PMT if UR==2
noi mean pobre_extr_sim_IPM if UR==2
noi mean pobre_extr_sim_PMT_fgt1 if UR==2
noi mean pobre_extr_sim_IPM_fgt1 if UR==2
noi mean pobre_extr_sim_PMT_fgt2 if UR==2
noi mean pobre_extr_sim_IPM_fgt2 if UR==2
// poverty YPERHG_IPM, line(linea_pob)


* KDE Excluídos
twoway (kdensity YPERHG if pobre_IPM==0 & YPERHG<10000) (kdensity YPERHG if pobre_IPM==1 & YPERHG<10000) (kdensity YPERHG if pobre_PMT==0 & YPERHG<10000) (kdensity YPERHG if pobre_PMT==1 & YPERHG<10000)

* BOXPLOT Excluídos


gen no_pob_indicator = ""
replace no_pob_indicator = "Ingreso de excluídos (IPM)" if pobre_IPM==0 
replace no_pob_indicator = "Ingreso de excluídos (PMT)" if pobre_PMT==0
gen YPERHG_nopob_PMT = YPERHG if no_pob_indicator=="Ingreso de excluídos (PMT)"
label var YPERHG_nopob_PMT  "Ingreso de excluídos (PMT)"
gen YPERHG_nopob_IPM = YPERHG if no_pob_indicator=="Ingreso de excluídos (IPM)"
label var YPERHG_nopob_IPM  "Ingreso de excluídos (IPM)"

preserve 
local N = _N
expand 2
gen byte new = _n > `N'
replace UR = 0 if new
label define urban 0 "Total" 1 "Urbano" 2 "Rural"
label values UR urban 

graph hbox YPERHG_nopob_IPM YPERHG_nopob_PMT, nooutsides over(UR) aspectratio(0.6) box(1, color(243 145 21) fcolor(243 145 21) fintensity(inten40)) box(2, color(114 156 177) fcolor(148 202 228) fintensity(inten100))  legend(region(lstyle(none)) cols(1) label(2 "Ingreso per capita de hogares excluídos por PMT") label(1 `"Ingreso per capita de hogares excluídos por IPM"')) $graph_aspect
graph export "D:\World Bank\Honduras PMT benchmark\Outputs\boxplot_excluídos.png", width(1500) replace
sum YPERHG_nopob_IPM YPERHG_nopob_PMT, d
stop
restore


******************************************************
******    Asignados por deciles de ingreso 	     *****
******************************************************

gsort YPERHG
gen pos_YPERHG = _n / _N
gen decil_ingreso = ceil(pos_YPERHG*10)
gen quintil_ingreso = ceil(pos_YPERHG*5)

preserve
collapse (mean) pobre_PMT pobre_IPM, by(decil_ingreso)
gen no_pobre_PMT = 1 - pobre_PMT
gen no_pobre_IPM = 1 - pobre_IPM
export excel using "Outputs/targeting_deciles.xlsx", replace firstrow(variables)
restore

preserve
keep if UR==1
collapse (mean) pobre_PMT pobre_IPM, by(decil_ingreso)
gen no_pobre_PMT = 1 - pobre_PMT
gen no_pobre_IPM = 1 - pobre_IPM
export excel using "Outputs/targeting_deciles_urbano.xlsx", replace firstrow(variables)
restore

preserve
keep if UR==2
collapse (mean) pobre_PMT pobre_IPM, by(decil_ingreso)
gen no_pobre_PMT = 1 - pobre_PMT
gen no_pobre_IPM = 1 - pobre_IPM
export excel using "Outputs/targeting_deciles_rural.xlsx", replace firstrow(variables)
restore

*******************************************************
******   Gasto entre hogares pobres y no pobres   *****
*******************************************************

gen pobre_ingreso = (POBREZA != 3) if POBREZA!=.
tab pobre_IPM 

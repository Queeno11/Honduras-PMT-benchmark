cd "D:\World Bank\Honduras PMT benchmark"
graph set window fontface "Times New Roman"

global graph_aspect = "graphregion(color(white)) plotregion(margin(zero))"

use "Data_out/basepmt_eph.dta", replace

* FIXME: revisar los 990 que perdemos que onda
merge 1:1 HOGAR using "Data_out/data_indice_multidimensional_consolidada.dta"
keep if _merge==3
drop _merge

******************************************
******    Indicadores de posición   ******
******************************************
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

*** PMT
* Ranking PMT
sort ingreso_est
gen ln_ingreso_est = ln(ingreso_est)
gen ranking_PMT = _n/_N
gen pobre_PMT = (ranking_PMT<=.3962)
gen pobre_PMT_25 = (ranking_PMT<=.25)
gen pobre_PMT_50 = (ranking_PMT<=.5)
gen pobre_PMT_75 = (ranking_PMT<=.75)
gen pobre_PMT_90 = (ranking_PMT<=.90)


* Deciles
gen decil_PMT = ceil(ranking_PMT * 10)
gen quintil_PMT = ceil(ranking_PMT * 5)


**********************************************
******    Correlación entre indicadores ******
**********************************************
spearman ingreso_est SumIPM

foreach thresh in "" "_25" "_50" "_75" "_90" {
    tab2xl pobre_PMT`thresh'  pobre_IPM`thresh' using "Outputs/tabs_pobreza_comparacion_eph.xlsx", row(1) col(1) sheet(`thresh')
	
}

twoway (scatter ranking_IPM ranking_PMT, msize(tiny) mstyle(smcircle) mcolor(edkblue%20)), yline(.3962, lcolor(orange_red%80)) xline(.3962, lcolor(orange_red%80)) xtitle("Percentil Ingreso Estimado por PMT") ytitle("Percentil Indice de Pobreza Multidimensional (IPM)") text(.35 0.008 "Pobres por ambos indicadores" 0.95 0.008 "Pobres según PMT" 0.95 0.41 "No pobres por ambos indicadores"  0.35 0.41 "Pobres según IPM", placement(east) box bcolor(white%70))  xsize(6) $graph_aspect 
graph export "Outputs/inclusion y exclusion.png", width(1500) replace

foreach thresh in "" "_25" "_50" "_75" "_90" {
    tab2xl pobre_PMT`thresh'  pobre_IPM`thresh' using "Outputs/tabs_pobreza_comparacion_eph.xlsx", row(1) col(1) sheet(`thresh')
	
}


**********************************************
******   	      Histogramas 	         *****
**********************************************
hist SumIPM, ylab(, nogrid) xtitle("Indice de Pobreza Multidimensional") ytitle("")  color("243 145 21") fcolor("243 145 21%40") $graph_aspect 
graph export "Outputs/histogram_IPM_eph.png", width(1500) replace

hist ingreso_est if ingreso_est<15000, ylab(, nogrid) xtitle("Ingreso Estimado utilizando metodología PMT") ytitle("")  color("114 156 177") fcolor("148 202 228") fintensity(inten100) $graph_aspect 
graph export "Outputs/histogram_PMT_eph.png", width(1500) replace


**********************************************
******   	  Microsimulaciones 	     *****
**********************************************

** Inferencia de la línea de pobreza de YPERHG
* NOTA: no tenemos la linea de pobreza en la base, pero la podemos inferir, porque si hacemos estos gráficos que siguen acá, vemos que el salto es discreto entre los dos histogramas
// twoway (hist YPERHG  if POBREZA==1 & DOMINIO==4, color(red%30)) (hist YPERHG  if POBREZA==2  & DOMINIO==4 , color(green%30)) (hist YPERHG  if POBREZA==3 & YPERHG<10000 & DOMINIO==4 , color(blue%30))


levelsof DOMINIO, local(zonas)
gen linea_pob_extr = .
gen linea_pob = .
qui foreach zona in `zonas' {
	sum YPERHG if POBREZA==1 & DOMINIO == `zona', d
	local max_pob_extr = r(max)
	sum YPERHG if POBREZA==2 & DOMINIO == `zona', d
	local min_pob = r(min)
	local max_pob = r(max)
	sum YPERHG if POBREZA==3 & DOMINIO == `zona', d
	local min_nopob = r(min)

	replace linea_pob_extr = (`max_pob_extr' + `min_pob') / 2 if DOMINIO == `zona'
	replace linea_pob = (`max_pob' + `min_nopob') / 2 if DOMINIO == `zona'
}

qui foreach ind in PMT IPM {

	gen asignacion_`ind' = 0
	replace asignacion_`ind' = 8040/12 if pobre_`ind'==1
	gen asignacion_`ind'_pc = asignacion_`ind' / TOTPER
	gen YPERHG_`ind' = YPERHG + asignacion_`ind'_pc
	gen pobre_sim_`ind' = (YPERHG_`ind' > linea_pob)
	gen pobre_sim_`ind'_fgt1 = pobre_sim_`ind' * (1-YPERHG_`ind'/linea_pob)
	gen pobre_sim_`ind'_fgt2 = pobre_sim_`ind' * (1-YPERHG_`ind'/linea_pob)^2
	
	gen pobre_extr_sim_`ind' = (YPERHG_`ind' > linea_pob_extr)
	gen pobre_extr_sim_`ind'_fgt1 = pobre_extr_sim_`ind' * (1-YPERHG_`ind'/linea_pob_extr)
	gen pobre_extr_sim_`ind'_fgt2 = pobre_extr_sim_`ind' * (1-YPERHG_`ind'/linea_pob_extr)^2
	
}

noi mean pobre_sim_PMT
noi mean pobre_sim_IPM
noi mean pobre_sim_PMT_fgt1
noi mean pobre_sim_IPM_fgt1
noi mean pobre_sim_PMT_fgt2
noi mean pobre_sim_IPM_fgt2

gen pobre_extr = (YPERHG<linea_pob_extr)
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

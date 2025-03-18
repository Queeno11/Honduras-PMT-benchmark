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
gen FACTOR_P = FACTOR * TOTPER
replace UR = UR + 1
*** IPM
gsort -indice_pobreza_multi 
gen ranking_IPM = _n/_N
**  39.62 es el % de pobres por IPM (IPM>=.25)


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

bysort DOMINIO: egen porcentaje_inclusion = mean(pobre) 
tab porcentaje_inclusion

gen pobre_IPM = (indice_pobreza_multi>=.25)
gen rankIPM = -indice_pobreza_multi


*** SIMULACION
sum pobre [w=FACTOR_P]
local pob = r(mean)
noi display "Indice Pobreza: `pob'" 
sum pobre_extr [w=FACTOR_P]
local pob = r(mean)
noi display "Indice Pobreza Extr: `pob'" 

* Cantidad de hogares fija
tempfile results
postfile collector str50 Indicador str50 Año Monto Hogares_Beneficiarios Indice_Pobreza Indice_Pobreza_Extrema using `results', replace

foreach multiplicador in 1 1.29 2 3.81 4 5.01 8 { 
	qui foreach ind in IPM log_ingreso_pred_lasso_urru_c2 logingreso_xgboost rankIPM {
		foreach year in "first" "after" {
			preserve

			local newname = subinstr("`ind'", "log_ingreso_pred_", "", .)
			local monto = 4020/12 * `multiplicador' 

			if "`ind'"!="IPM" {
				sort `ind'	
				gen pos_`newname' = _n / _N
				gen pobre_`newname' = (pos_`newname'<=porcentaje_inclusion)	
			}	
			sum pobre_`newname' [w=FACTOR_P]
			local q_hog = r(sum)
			
			gen asignacion_`newname' = 0
			replace asignacion_`newname' = `monto' if pobre_`newname'==1
			if "`year'"=="first" {
				replace asignacion_`newname' = asignacion_`newname' + `monto' // Asignación universal
			}
			gen asignacion_`newname'_pc = asignacion_`newname' / TOTPER 
			gen YPERHG_`newname' = YPERHG + asignacion_`newname'_pc
			gen p_`newname' = (YPERHG_`newname' < linea_pob)
			gen p_`newname'_fgt1 = p_`newname' * (1-YPERHG_`newname'/linea_pob)
			gen p_`newname'_fgt2 = p_`newname' * (1-YPERHG_`newname'/linea_pob)^2
			
			gen pe_`newname' = (YPERHG_`newname' < linea_pob_extr)
			gen pe_`newname'_fgt1 = pe_`newname' * (1-YPERHG_`newname'/linea_pob_extr)
			gen pe_`newname'_fgt2 = pe_`newname' * (1-YPERHG_`newname'/linea_pob_extr)^2
			
			sum p_`newname' [w=FACTOR_P]
			local p_`newname' = r(mean)

			sum pe_`newname' [w=FACTOR_P]
			local pe_`newname' = r(mean)
			noi display "Indice Pobreza: (asignado `ind'): `pe_`newname''"
			
			* Store the values in the collector
			post collector ("`ind'") ("`year'") (`monto') (`q_hog') (`p_`newname'') (`pe_`newname'')
			restore
		}
	}
}

* Presupuesto fijo
foreach divisor in 2 4 8 { 
	qui foreach ind in log_ingreso_pred_lasso_urru_c2 logingreso_xgboost rankIPM {
		foreach year in "first" "after" {
			preserve
			gen porcentaje_inclusion_sim = porcentaje_inclusion / `divisor'
			local newname = subinstr("`ind'", "log_ingreso_pred_", "", .)
			local monto = 4020/12 * `divisor' 

			sort `ind'	
			gen pos_`newname' = _n / _N
			gen pobre_`newname' = (pos_`newname'<=porcentaje_inclusion_sim)	
			sum pobre_`newname' [w=FACTOR_P]
			local q_hog = r(sum)
			
			gen asignacion_`newname' = 0
			replace asignacion_`newname' = `monto' if pobre_`newname'==1
			if "`year'"=="first" {
				replace asignacion_`newname' = asignacion_`newname' + `monto' // Asignación universal
			}
			gen asignacion_`newname'_pc = asignacion_`newname' / TOTPER 
			gen YPERHG_`newname' = YPERHG + asignacion_`newname'_pc
			gen p_`newname' = (YPERHG_`newname' < linea_pob)
			gen p_`newname'_fgt1 = p_`newname' * (1-YPERHG_`newname'/linea_pob)
			gen p_`newname'_fgt2 = p_`newname' * (1-YPERHG_`newname'/linea_pob)^2
			
			gen pe_`newname' = (YPERHG_`newname' < linea_pob_extr)
			gen pe_`newname'_fgt1 = pe_`newname' * (1-YPERHG_`newname'/linea_pob_extr)
			gen pe_`newname'_fgt2 = pe_`newname' * (1-YPERHG_`newname'/linea_pob_extr)^2
			
			sum p_`newname' [w=FACTOR_P]
			local p_`newname' = r(mean)

			sum pe_`newname' [w=FACTOR_P]
			local pe_`newname' = r(mean)
			noi display "Indice Pobreza: (asignado `ind'): `pe_`newname''"
			
			* Store the values in the collector
			post collector ("`ind'") ("`year'") (`monto') (`q_hog') (`p_`newname'') (`pe_`newname'')
			restore
		}
	}
}

postclose collector
use `results', replace
export excel using "$Outputs\simluaciones_pobreza.xlsx", replace firstrow(variables)
clear all
set type double

graph set window fontface "Times New Roman"
global graph_aspect = "graphregion(color(white)) plotregion(margin(zero))"

use "$DATA_OUT/preds lasso pmt.dta", replace
merge 1:1 HOGAR using "$DATA_OUT/Predicts_XGBoost.dta"

* With this, UR = 1 is rural and UR = 2 is urban. `urban'==0 means all
replace UR = UR + 1


**********************************************
******   	  Microsimulaciones 	     *****
**********************************************

gen linea_pob_extr = .
replace linea_pob_extr = 2465.97 if UR==1
replace linea_pob_extr = 1901.71 if UR==2

gen linea_pob = .
replace linea_pob = 4931.94 if UR==1
replace linea_pob = 2538.78 if UR==2

gen pobre = (YPERHG < linea_pob)
gen pobre_extr = (YPERHG < linea_pob_extr)

* Calculo la weighted mean de pobreza (pobreza es la variable que ya me da construida la EPH)
bysort DOMINIO: egen total_pobre_weight = total(pobreza * FACTOR_P)
bysort DOMINIO: egen total_weight = total(FACTOR_P)
gen porcentaje_inclusion = total_pobre_weight / total_weight
drop total_pobre_weight total_weight
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
				gen q_personas = sum(FACTOR_P) 
				egen tot_personas = sum(FACTOR_P) 
				gen pos_`newname' = q_personas/tot_personas
				gen pobre_`newname' = (pos_`newname'<=porcentaje_inclusion)	
				drop q_personas tot_personas
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
			gen q_personas = sum(FACTOR_P) 
			egen tot_personas = sum(FACTOR_P) 
			gen pos_`newname' = q_personas/tot_personas
			gen pobre_`newname' = (pos_`newname'<=porcentaje_inclusion_sim)	
			sum pobre_`newname' [w=FACTOR_P]
			local q_hog = r(sum)
			drop q_personas tot_personas
			
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
			noi display "Indice Pobreza: (asignado `ind', `year', `divisor'): `pe_`newname''"
			
			* Store the values in the collector
			post collector ("`ind'") ("`year'") (`monto') (`q_hog') (`p_`newname'') (`pe_`newname'')
			restore
		}
	}
}

postclose collector
use `results', replace
export excel using "$OUTPUTS\simluaciones_pobreza.xlsx", replace firstrow(variables)
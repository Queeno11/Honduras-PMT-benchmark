clear all
set type double

graph set window fontface "Times New Roman"
global graph_aspect = "graphregion(color(white)) plotregion(margin(zero))"

use "$DATA_OUT/preds lasso pmt.dta", replace
merge 1:1 HOGAR using "$DATA_OUT/Predicts_XGBoost.dta"
keep if log_ingreso_pred_lasso_urru_c2 != .

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

* Calculo la weighted mean de pobreza (pobreza es la variable que ya me da construida la EPH)
bysort UR: egen total_pobre_weight = total(pobreza * FACTOR_P)
bysort UR: egen total_weight = total(FACTOR_P)
gen porcentaje_inclusion = total_pobre_weight / total_weight
drop total_pobre_weight total_weight
tab porcentaje_inclusion

gen pobre_IPM = (indice_pobreza_multi>=.25)
gen rankIPM = -indice_pobreza_multi

*** SIMULACION
sum pobreza [w=FACTOR_P]
local pob = r(mean)
noi display "Indice Pobreza: `pob'" 
sum pobreza_ext [w=FACTOR_P]
local pob = r(mean)
noi display "Indice Pobreza Extr: `pob'" 

* Cantidad de hogares fija
tempfile results
postfile collector str50 Indicador str50 Año Monto Hogares_Beneficiarios Indice_Pobreza Indice_Pobreza_Extrema using `results', replace

* Probamos con diferentes multiplicadores y divisiores de montos
qui {
foreach multiplicador in 1 1.29 2 3.81 4 5.01 8 .25 .5  { 
	foreach ind in IPM log_ingreso_pred_lasso_urru_c2 logingreso_xgboost rankIPM {
		foreach year in "first" "after" {
			preserve
			local newname = subinstr("`ind'", "log_ingreso_pred_", "", .)
			local monto = 4020/12 * `multiplicador' 

			if "`ind'"!="IPM" {

				sort UR `ind'	
				by UR: gen q_personas = sum(FACTOR_P) 
				by UR: egen tot_personas = sum(FACTOR_P) 
				by UR: gen pos_`newname' = q_personas/tot_personas
				* Split the observation in between the threshold (porcentaje_inclusion)
				*	and adjust the proportion of people in each correspoding interval
				* This is to ensure that the number of personas assigned to the program
				*	is the same for all the indicators. Otherwise, it depends on the actual
				*	FACTOR_P ordered values.
				gen pos_prev_`newname' = pos_`newname'[_n-1]
				gen share_to_split = .
				gen share_to_threshold = .
				gen share_above_threshold = .
				levelsof UR, local(zonas)
				foreach zona in `zonas'{
					sum pos_`newname' if pos_`newname'>porcentaje_inclusion & UR==`zona'
					local per_in_bound = r(min) 
					replace share_to_split = pos_`newname' - pos_prev_`newname' if pos_`newname'==`per_in_bound' & UR==`zona'
					replace share_to_threshold = porcentaje_inclusion - pos_prev_`newname' if pos_`newname'==`per_in_bound' & UR==`zona'
					replace share_above_threshold = pos_`newname' - porcentaje_inclusion if pos_`newname'==`per_in_bound' & UR==`zona'
					expand 2 if pos_`newname'==`per_in_bound', gen(tag)	

					* Assert only one change will be made
					display " pos_`newname'==`per_in_bound' & UR==`zona' & tag==1"
					count if  pos_`newname'==`per_in_bound' & UR==`zona' & tag==1
					assert r(N)==1
					qui count if pos_`newname'==`per_in_bound' & UR==`zona' & tag==0
					assert r(N)==1

					* Change FACTOR_P proportionately
					replace FACTOR_P = FACTOR_P * share_to_threshold / share_to_split if pos_`newname'==`per_in_bound' & UR==`zona' & tag==1
					replace FACTOR_P = FACTOR_P * share_above_threshold / share_to_split if pos_`newname'==`per_in_bound' & UR==`zona' & tag==0
					* Change position in the first duplicate
					replace pos_`newname' = porcentaje_inclusion if pos_`newname'==`per_in_bound' & UR==`zona' & tag==1 

					drop tag
				}
				sort UR pos_`newname'

				* Correct values based on corresponding shares
				gen pobre_`newname' = (pos_`newname'<=porcentaje_inclusion)	
				drop share_above_threshold share_to_split share_to_threshold pos_prev_`newname'
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
			noi display "Indice Pobreza: (asignado `ind', `year', `multiplicador'): `pe_`newname''"

			* Store the values in the collector
			post collector ("`ind'") ("`year'") (`monto') (`q_hog') (`p_`newname'') (`pe_`newname'')
			
			restore
		}
	}
}
}

postclose collector
use `results', replace
export excel using "$OUTPUTS\simluaciones_pobreza.xlsx", replace firstrow(variables)
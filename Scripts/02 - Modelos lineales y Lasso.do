clear all

cd "D:\World Bank\Honduras PMT benchmark\Data_out"
*use "CONSOLIDADA_2023_clean.dta", replace

use "CONSOLIDADA_2023_clean.dta"

******** Defino las variables que vamos a usar

** Variables globales para las distintas estimaciones **

** Conjunto 1 **
* Variables que vienen del PMT original
global vars_pmtoriginal = "Ocupacion_bien Paredes_bien Pension_bien Refri_mal Remesas_bien Aire_mal Alquileres_bien Alumbrado_bien Basura_bien Carro_mal Cocina2_bien Compu_mal Dependencia dv111 Ed_diversif_bien Ed_univer_bien edad_0_5 edad_15_21 edad_60_120 edad_6_14 Estufa_mal Vivienda2_bien"
*No incluimos las variables de alimentacion que no pudimos reconstruir ni escritura_mal

* Variables que vienen del IPM
global IPM_vars = "privacion_agua_h privacion_saneamiento_h privacion_cocina_h privacion_educ_h privacion_asistencia_h privacion_alfab_h privacion_elec_h privacion_piso_h privacion_techo_h privacion_segsoc_h privacion_desocup_h privacion_subemp_h privacion_ocup_h privacion_trabinf_h privacion_trabadol1_h privacion_trabadol2_h privacion_pared_h privacion_hacina_h"

* Variables que en el PMT original se habían dejado afuera por no ser significativas
global vars_PMT_nosig "EqSonido_mal HaySanitario_bien Sanitario_bien Civil_mal Cocina_bien Cable_mal Hacinamiento Moto_mal Piso_mal Bici_mal Exterior_bien Dominio_1 Dominio_2 Dominio_3 Vivienda_bien Agua2_bien Agua_bien TV_mal Telefono_mal"

** Conjunto 2 **
* Eliminamos las variables que eran muy multicolineales, eran falseables o no dependian de los hogares
global vars_limpias_final = "privacion_saneamiento_h privacion_cocina_h privacion_educ_h privacion_asistencia_h privacion_alfab_h Piso_mal Paredes_bien EqSonido_mal HaySanitario_bien  Sanitario_bien Cocina2_bien Hacinamiento Cable_mal Moto_mal Bici_mal Dominio_1 Dominio_2 Dominio_3 Pension_bien Refri_mal Aire_mal Carro_mal Compu_mal dv111 Ed_diversif_bien Ed_univer_bien edad_0_5 edad_15_21 edad_60_120 edad_6_14 Estufa_mal Agua2_bien Dependencia"

* Las variables excluidas fueron: privacion_desocup_h privacion_subemp_h privacion_ocup_h privacion_trabinf_h privacion_trabadol1_h privacion_trabadol2_h (todas estas xq son laborales); privacion_pared_h privacion_hacina_h privacion_piso_h privacion_segsoc_h(todas estas porque se parecen a las que ya incluimos); son falseables (Remesas_bien Alquileres_bien); Alumbrado_bien Basura_bien (no dependen de las familias sino Estado); Vivienda2_bien Telefono_mal privacion_agua_h Agua_bien Vivienda_bien TV_mal privacion_techo_h Exterior_bien Civil_mal Ocupacion_bien Cocina_bien

* Vemos la correlación entre variables
*correlate $vars_PMT_nosig $vars_pmtoriginal $IPM_vars [w=FACTOR_P]

**********************************************

******** Función para asignar el programa
program define asigna_programa
version 13
    syntax varname(numeric), PREDICTED(varname) [LEVEL(real 0.667)]
	
	*Fixme: Habria que tener en cuenta los weights en este paso
	
    // Assign variables from syntax
    local outcome "`varlist'"
    local predicted "`predicted'"
    local level "`level'"
	
    qui {
	
	
	*Esto hace la suma de la frecuencia acumulada
	foreach var in `outcome' `predicted'{
		sort UR `var'
		by UR: gen F = sum(FACTOR_P)
		by UR: egen poblacion = max(F)
		by UR: gen rank_pct = F/poblacion
		gen a_`var' = (rank_pct <= `level')
	drop F poblacion rank_pct
	}
	
	rename a_`outcome' asignado_real
	rename a_`predicted' asignado
	
// 	local level_100 = `level'*100
// 	bysort UR: egen limite = pctile(`outcome'), p(`level_100')
// 	bysort UR: egen limite_pred = pctile(`predicted'), p(`level_100')
//	
//	
//     generate byte asignado_real = (`outcome' <= limite)
//     generate byte asignado = (`predicted' <= limite_pred)
	}
end


******** Función para comparar modelos
program define test_model_performance
    version 13
    syntax varname(numeric), PREDICTED(varname) [TESTSET(varname) LEVEL(real 0.667)]

    qui {
	preserve
	
	keep if `testset' == 1
	keep if `predicted'!=.
	keep if `varlist' !=.

    // Assign variables from syntax
    local outcome "`varlist'"
    local predicted "`predicted'"
    local testset "`testset'"
    if "`testset'" == "" {
        local testset "test_set"
    }
    local level "`level'"

    tempvar residual sq_residual sq_total pos pos2 asignado_real asignado coincide tp fp fn

    // R-squared calculation
    generate `residual' = `outcome' - `predicted'
    generate `sq_residual' = `residual'^2
    summarize `outcome' [w=FACTOR_P], meanonly
    scalar mean_outcome = r(mean)
    generate `sq_total' = (`outcome' - mean_outcome)^2
    quietly summarize `sq_residual' [w=FACTOR_P], meanonly
    scalar RSS = r(sum)
    quietly summarize `sq_total' [w=FACTOR_P], meanonly
    scalar TSS = r(sum)
    scalar R2_test = 1 - RSS / TSS
    noi display "R-squared for the test set: " R2_test

    // Relative position
	asigna_programa `outcome', predicted(`predicted')

    generate byte `coincide' = (asignado_real == asignado)
    quietly summarize `coincide' [w=FACTOR_P], meanonly
    noi display "Accuracy: " r(mean)

    // F2 score calculation
    generate byte `tp' = (asignado_real == 1 & asignado == 1)
    generate byte `fp' = (asignado_real == 0 & asignado == 1)
    generate byte `fn' = (asignado_real == 1 & asignado == 0)

    quietly summarize `tp' [w=FACTOR_P], meanonly
    scalar tp_count = r(sum)
    quietly summarize `fp' [w=FACTOR_P], meanonly
    scalar fp_count = r(sum)
    quietly summarize `fn' [w=FACTOR_P], meanonly
    scalar fn_count = r(sum)

    scalar precision = tp_count / (tp_count + fp_count)
    scalar recall = tp_count / (tp_count + fn_count)
    scalar f2_score = (5 * precision * recall) / (4 * precision + recall)
    noi display "F2 score: " f2_score

    restore
	}
end

gen train_set = 1 - test_set

********************************************************************************

*** Lineal

** Un modelo lineal para urbano y otro para lineal, con los dos sets
*** Modelo Lineal c1
levelsof UR, local(zonas)
foreach zona in `zonas'{
	reg logingreso $vars_pmtoriginal $vars_PMT_nosig $IPM_vars [w=FACTOR_P] if UR == `zona' & test_set == 0, robust
	predict lm`zona' if UR == `zona'
}
egen log_ingreso_pred_lm_urru_c1= rowfirst(lm*)
drop lm*

*** Modelo Lineal c2
levelsof UR, local(zonas)
foreach zona in `zonas'{
	reg logingreso $vars_limpias_final [w=FACTOR_P] if UR == `zona' & test_set == 0, robust
	predict lm`zona' if UR == `zona'
}
egen log_ingreso_pred_lm_urru_c2= rowfirst(lm*)

*** Lasso

** Un Lasso por urbano y otro para rural, con las variables filtradas
** Modelo lasso c1
levelsof UR, local(zonas)
local seed = 1234
foreach zona in `zonas'{
	lasso linear logingreso $vars_pmtoriginal $vars_PMT_nosig $IPM_vars [iw=FACTOR_P] if UR == `zona' & test_set == 0, selection(adaptive, strict) rseed(`seed')
	predict lasso`zona' if UR == `zona'
	eststo lasso_all_l_`zona'_ur
	estimates store lasso_l_`zona'
	local seed = `seed' + 1
}
egen log_ingreso_pred_lasso_urru_c1 = rowfirst(lasso*)
drop lasso*

** Modelo lasso c2
levelsof UR, local(zonas)
local seed = 1234
foreach zona in `zonas'{
	lasso linear logingreso $vars_limpias_final [iw=FACTOR_P] if UR == `zona' & test_set == 0, selection(adaptive, strict) rseed(`seed')
	predict lasso`zona' if UR == `zona'
	eststo lasso_all_l_`zona'_ur
	estimates store lasso_l_`zona'
	local seed = `seed' + 1
}
egen log_ingreso_pred_lasso_urru_c2 = rowfirst(lasso*)
lassocoef lasso_all_l_*, display(coef, standardized)


**** Comparamos los modelos
local paracomparar log_ingreso_pred_lasso_urru_c1 log_ingreso_pred_lasso_urru_c2 log_ingreso_pred_lm_urru_c1 log_ingreso_pred_lm_urru_c2

foreach var in `paracomparar' {
    display "`var'"
	display "Test"
	test_model_performance logingreso, predicted(`var') testset(test_set)
	*display "Train"
	*test_model_performance logingreso, predicted(`var') testset(train_set)
}

**** Separamos comparación urbano y rural
preserve
display "Resultados para urbano"
keep if UR==1
test_model_performance logingreso, predicted(log_ingreso_pred_lasso_urru_c2) testset(test_set)
restore

preserve
display "Resultados para rural"
keep if UR==2
test_model_performance logingreso, predicted(log_ingreso_pred_lasso_urru_c2) testset(test_set)
restore


*** Exportamos los betas

* Exportamos los betas
lassocoef lasso_all_l_*, display(coef, standardized)

matrix coefs = r(coef)
local models = r(names)
local varnames: rownames coefs
// Extract the row names (variable names) from the matrix
*local varnames : rownames coefs

// Set up the Excel file and add header labels
putexcel set "D:\World Bank\Honduras PMT benchmark\Outputs\lasso_coefs.xlsx", replace
putexcel A1 = "Variable"
putexcel B2 = matrix(coefs)

local first : word 1 of `models'
local second : word 2 of `models'

// Write the first word into cell B1 and the second into cell C1
putexcel B1 = ("`first'")
putexcel C1 = ("`second'")

// Loop over each variable name and write both the name and its coefficient
local i = 1
foreach v of local varnames {
    // Write the variable name in column A and the corresponding coefficient in column B
    putexcel A`=`i'+1' = ("`v'")
    local i = `i' + 1
}


*** Exportamos la base
preserve
keep HOGAR log_ingreso_pred_lasso_urru_c2 test_set DOMINIO
save "preds lasso pmt", replace
restore

preserve
keep HOGAR log_ingreso_pred_lasso_urru_c2 test_set DOMINIO indice_pobreza_multi UR FACTOR FACTOR_P
save "Logs estimadas para grafico", replace
restore
 
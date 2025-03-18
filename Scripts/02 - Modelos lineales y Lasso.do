clear all

use "D:\World Bank\Honduras PMT benchmark\Data_out\CONSOLIDADA_2023_clean.dta"

********

******** Definimos variables globales para las distintas estimaciones

global vars_pmtoriginal = "Ocupacion_bien Paredes_bien Pension_bien Refri_mal Remesas_bien Aire_mal Alquileres_bien Alumbrado_bien Basura_bien Carro_mal Cocina2_bien Compu_mal Dependencia dv111 Ed_diversif_bien Ed_univer_bien edad_0_5 edad_15_21 edad_60_120 edad_6_14 Estufa_mal Vivienda2_bien"
* Se dejaron afuera las variables que no se pudo reconstruir

global IPM_vars = "privacion_agua_h privacion_saneamiento_h privacion_cocina_h privacion_educ_h privacion_asistencia_h privacion_alfab_h privacion_elec_h privacion_piso_h privacion_techo_h privacion_segsoc_h privacion_desocup_h privacion_subemp_h privacion_ocup_h privacion_trabinf_h privacion_trabadol1_h privacion_trabadol2_h privacion_pared_h privacion_hacina_h"

global vars_PMT_nosig "EqSonido_mal HaySanitario_bien Sanitario_bien Civil_mal Cocina_bien Cable_mal Hacinamiento Moto_mal Piso_mal Bici_mal Exterior_bien Dominio_1 Dominio_2 Dominio_3 Vivienda_bien Agua2_bien Agua_bien TV_mal Telefono_mal"

* Eliminamos las variables que eran muy multicolineales, eran falseables o no dependian de los hogares
* global vars_limpias_final = "privacion_saneamiento_h privacion_cocina_h privacion_educ_h privacion_asistencia_h privacion_alfab_h Piso_mal Paredes_bien EqSonido_mal HaySanitario_bien  Sanitario_bien  Cocina2_bien Hacinamiento Cable_mal Moto_mal Bici_mal Dominio_1 Dominio_2 Dominio_3 Pension_bien Refri_mal Aire_mal Carro_mal Compu_mal Ed_diversif_bien Ed_univer_bien edad_0_5 edad_15_21 edad_60_120 edad_6_14 Estufa_mal Dependencia Civil_mal Cocina_bien Exterior_bien Ocupacion_bien privacion_agua_h privacion_elec_h privacion_techo_h Agua2_bien dv111"

* Estas son las de la tabla del final sumando las dos que estan en los betas pero no en esa tabla
*global vars_limpias_final = "Aire_mal Bici_mal Cable_mal Carro_mal Civil_mal Cocina_bien Cocina2_bien Compu_mal Dependencia Dominio_1 Dominio_2 Dominio_3 Ed_diversif_bien Ed_univer_bien edad_0_5 edad_15_21 edad_6_14 edad_60_120 EqSonido_mal Estufa_mal Exterior_bien Hacinamiento HaySanitario_bien Moto_mal Ocupacion_bien Paredes_bien Pension_bien Piso_mal privacion_agua_h privacion_alfab_h privacion_asistencia_h privacion_cocina_h privacion_educ_h privacion_elec_h privacion_saneamiento_h privacion_techo_h Refri_mal Sanitario_bien dv111 Agua2_bien"

*Estas son las que faltaban en la tabla del final
* Agua2_bien dv111

* Estas son las seleccionadas
*global vars_limpias_final = "Paredes_bien Cocina2_bien Piso_mal HaySanitario_bien Agua2_bien dv111 Refri_mal Estufa_mal privacion_cocina_h Aire_mal Compu_mal EqSonido_mal Cable_mal Carro_mal Moto_mal Bici_mal Ed_diversif_bien Ed_univer_bien privacion_educ_h privacion_alfab_h Dependencia Hacinamiento Pension_bien edad_0_5 edad_15_21 edad_6_14 edad_60_120 Dominio_1 Dominio_2 Dominio_3"

*global vars_limpias_final = "$vars_limpias_final Cocina_bien Exterior_bien privacion_asistencia_h privacion_techo_h privacion_saneamiento_h"

* Civil_mal Ocupacion_bien privacion_agua_h Sanitario_bien privacion_elec_h

global vars_limpias_final = "Aire_mal Bici_mal Cable_mal Carro_mal Cocina_bien Cocina2_bien Compu_mal Dependencia Dominio_1 Dominio_2 Dominio_3 Ed_diversif_bien Ed_univer_bien edad_0_5 edad_15_21 edad_6_14 edad_60_120 EqSonido_mal Exterior_bien Hacinamiento HaySanitario_bien Moto_mal Ocupacion_bien Paredes_bien Pension_bien Piso_mal privacion_alfab_h privacion_asistencia_h privacion_cocina_h privacion_educ_h privacion_saneamiento_h privacion_techo_h Refri_mal Sanitario_bien dv111 Agua2_bien Estufa_mal"
                              
* Sacamos civil privacion_agua_h privacion_elec_h


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

*gen FACTOR_P = FACTOR*TOTPER

******* Lasso

** Lassos por zonas

**** Modelo L.A
** Hacemos un Lasso por zona, con cualquier variable
local seed = 1234
levelsof DOMINIO, local(zonas)
foreach zona in `zonas'{
	lasso linear logingreso $vars_pmtoriginal $vars_PMT_nosig $IPM_vars [iw=FACTOR_P] if DOMINIO == `zona' & test_set == 0, selection(adaptive, strict) rseed(`seed')
	predict lasso`zona' if DOMINIO == `zona'
	eststo lasso_all_`zona'_zona
	local seed = `seed' + 1
}
egen log_ingreso_pred_lasso_z = rowfirst(lasso*)
drop lasso*


**** Modelo L.B
** Un Lasso por urbano y otro para rural, con las variables filtradas
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
drop lasso*

lassocoef lasso_all_l_*, display(coef, standardized)
lassocoef lasso_all_l_*, display(coef)

** Lasos nacionales

*** Modelo L.C
* Mismo que el A pero sin forzarlo a que se divida entre UR y RU
local seed = 1234
lasso linear logingreso $vars_pmtoriginal $vars_PMT_nosig $IPM_vars [iw=FACTOR_P] if test_set == 0, selection(adaptive) rseed(`seed')
predict log_ingreso_pred_lasso_tot_z

*** Modelo L.D
* Mismo que el B pero sin forzarlo a que se divida entre UR y RU
local seed = 1234
lasso linear logingreso $vars_limpias_final [iw=FACTOR_P] if test_set == 0, selection(adaptive) rseed(`seed')
predict log_ingreso_pred_lasso_tot_c2

* Vemos los coeficientes
lassocoef lasso_l_1 lasso_l_2, display(coef, standardized)

******* Lineales

*** Modelo O.A
levelsof UR, local(zonas)
foreach zona in `zonas'{
	reg logingreso $vars_pmtoriginal $vars_PMT_nosig $IPM_vars [w=FACTOR_P] if UR == `zona' & test_set == 0, robust
	predict lm`zona' if UR == `zona'
}
egen log_ingreso_pred_lm_z= rowfirst(lm*)
drop lm*

*** Modelo O.B
levelsof UR, local(zonas)
foreach zona in `zonas'{
	reg logingreso $vars_limpias_final [w=FACTOR_P] if UR == `zona' & test_set == 0, robust
	predict lm`zona' if UR == `zona'
}
egen log_ingreso_pred_lm_urru_c2= rowfirst(lm*)
drop lm*

*** Modelo O.C
reg logingreso $vars_pmtoriginal $vars_PMT_nosig $IPM_vars [w=FACTOR_P] if test_set == 0, robust
predict log_ingreso_pred_lm_tot_z

*** Modelo O.D
reg logingreso $vars_limpias_final [w=FACTOR_P] if test_set == 0, robust
predict log_ingreso_pred_lm_tot_c2



******** Función para comparar modelos
* Ahora comparamos los modelos

local varsparaesadisticos log_ingreso_pred_lasso_z log_ingreso_pred_lasso_urru_c2 log_ingreso_pred_lasso_tot_z log_ingreso_pred_lasso_tot_c2 log_ingreso_pred_lm_z log_ingreso_pred_lm_urru_c2 log_ingreso_pred_lm_tot_z log_ingreso_pred_lm_tot_c2

foreach var in `varsparaesadisticos' {
    display "`var'"
	display "Test"
	test_model_performance logingreso, predicted(`var') testset(test_set)
	*display "Train"
	*test_model_performance logingreso, predicted(`var') testset(train_set)
}

*corr log_ingreso_pred* logingreso

*spearman log_ingreso_pred_lasso_urru_c2 indice_pobreza_multi

****** Hago los calculos de error para urbano y rural por separado

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

test_model_performance logingreso, predicted(log_ingreso_pred_lasso_urru_c2) testset(test_set)


** Guardo base
preserve
keep HOGAR log_ingreso_pred_lasso_urru_c2 test_set DOMINIO
save "preds lasso pmt", replace
restore


preserve
keep HOGAR log_ingreso_pred_lasso_urru_c2 test_set DOMINIO indice_pobreza_multi UR FACTOR FACTOR_P
save "Logs estimadas para grafico", replace
restore

************************************************
** Estimación de ingresos con datos de SIRBHO **
************************************************

* Este codigo usa los betas que provienen del PMT del modelo de lasso para predecir el ingreso en la base de SIRBHO*

clear all

*** Bases necesarias ***
* Betas del PMT
* Base hogares SIRBHO
* Base personas SIRBHO

cd "C:\Users\pilih\Documents\World Bank\Honduras\Replication PMT IPM\2. Data\Data_in\SIRBHO"
** betas del PMT

** SIRBHO Hogares
import delimited using "ODS3_Hogares.csv", clear delimiter(";")
destring level1id, replace force
describe level1id
drop deleted
save "Hogares_SIRBHO.dta", replace

** SIRBHO Personas
import delimited using "ODS3_Poblacion.csv", clear delimiter(";")
destring level1id, replace force
describe level1id
drop deleted
save "Poblacion_SIRBHO.dta", replace 

use "Poblacion_SIRBHO.dta", clear
merge m:1 level1id using "Hogares_SIRBHO.dta"
drop _merge
save "SIRBHOConsolidada.dta", replace


* Seccion 1
*******************************************
**** Generación de variables en SIRBHO ****
*******************************************

use "SIRBHOConsolidada.dta", clear

egen hogid = group(level1id numhog)
bysort hogid: egen orden_min = min(x_00)
replace x_00 = 1 if orden_min!=1 & x_00==orden_min

**** Variables del hogar ****
destring iii_08, replace force
replace iii_08 = . if iii_08 < 1 | iii_08 > 9
gen Agua2_bien = (iii_08 == 1) if iii_08!=.
label variable Agua2_bien "agua dentro de la vivienda"

* Separamos variable V_10
split v_10, parse(;) gen(value) destring force

egen aire = anycount(value*), values(18)
gen Aire_mal = (aire == 0) if v_10!=""
label variable Aire_mal "No tiene aire acondicionado"

egen bici = anycount(value*), values(17)
gen Bici_mal = (bici == 0) if v_10!=""
label variable Bici_mal "No tiene bicicleta"

egen cable = anycount(value*), values(12)
gen Cable_mal = (cable == 0) if v_10!=""
label variable Cable_mal "No tiene servicio de cable"

egen carro = anycount(value*), values(19)
gen Carro_mal = (carro == 0) if v_10!=""
label variable Carro_mal "No tiene carro"

destring v_05, replace force
replace v_05 = . if v_05 < 1 | v_05 > 6
gen Cocina2_bien = inlist(v_05, 4, 5) if v_05!=.
label variable Cocina2_bien "cocina con gas propano o electricidad"

egen compu = anycount(value*), values(10)
gen Compu_mal = (compu == 0) if v_10!=""
label variable Compu_mal "No tiene computadora"

* Miro por hogar cuantas personas trabajan
destring x_32, replace force
bysort hogid: gen trabajo_hogar = sum(x_32 == 2) if x_32!=.
bysort hogid: replace trabajo_hogar = trabajo_hogar[_N]
destring v_02c, gen(tot_personas) force
* ahora uso esa variable para el calculo
gen Dependencia = (trabajo_hogar/tot_personas) if (trabajo_hogar!=. &  tot_personas!=. & tot_personas>=trabajo_hogar)
label variable Dependencia "# de miembros trabajando la semana pasada / Tamaño del hogar entre"

*** Dominios

destring iii_11, replace force
gen dv111 = iii_11
label variable dv111 "Sin incluir la cocina, el baño y garaje ¿cuántas piezas tiene esta viv"

* Edad
destring x_06, gen(edad) force
label variable edad "edad"
replace edad = 0 if edad < 0

* Genero variables intermedias para la edad
gen temp_edad_0_5 = (edad >= 0 & edad <= 5) if edad!=.
gen temp_edad_6_14 = (edad >= 6 & edad <= 14) if edad!=.
gen temp_edad_15_21 = (edad >= 15 & edad <= 21) if edad!=.
gen temp_edad_60_120 = (edad >60) if edad!=.

* Sumo variable edad por hogar
bysort hogid: gen num_edad_0_5 = sum(temp_edad_0_5) if edad!=.
bysort hogid: gen num_edad_6_14 = sum(temp_edad_6_14) if edad!=.
bysort hogid: gen num_edad_15_21 = sum(temp_edad_15_21) if edad!=.
bysort hogid: gen num_edad_60_120 = sum(temp_edad_60_120) if edad!=.

* Me quedo con el valor máximo
bysort hogid: replace num_edad_0_5 = num_edad_0_5[_N] if edad!=.
bysort hogid: replace num_edad_6_14 = num_edad_6_14[_N] if edad!=.
bysort hogid: replace num_edad_15_21 = num_edad_15_21[_N] if edad!=.
bysort hogid: replace num_edad_60_120 = num_edad_60_120[_N] if edad!=.

gen edad_0_5 = num_edad_0_5 if edad!=.
label variable edad_0_5 "# de personas de 0 a 5"

gen edad_6_14 = num_edad_6_14 if edad!=.
label variable edad_6_14 "# de personas de 6 a 14"

gen edad_15_21 = num_edad_15_21 if edad!=.
label variable edad_15_21 "# de personas de 15 a 21"

gen edad_60_120 = num_edad_60_120 if edad!=.
label variable edad_60_120 "# de personas de más de 60"

* dropeo variables intermedias
drop num_edad_0_5 num_edad_6_14 num_edad_15_21 num_edad_60_120 temp_edad_0_5 temp_edad_6_14 temp_edad_15_21 temp_edad_60_120 

egen eqSonido = anycount(value*), values(9)
gen EqSonido_mal = (eqSonido == 0) if v_10!=""
label variable EqSonido_mal "No tiene equipo de sonido"

egen estufa = anycount(value*), values(1, 2)
gen Estufa_mal = (estufa == 0) if v_10!=""
label variable Estufa_mal "No tiene estufa"

rename v_01 tot_piezas
gen Hacinamiento = (tot_personas / tot_piezas) if (tot_piezas!=. & tot_personas!=.)
label variable Hacinamiento  "Personas por dormitorio"

egen moto = anycount(value*), values(20)
gen Moto_mal = (moto == 0) if v_10!=""
label variable Moto_mal "No tiene motocicleta"

destring iii_03, replace force
replace iii_03 = . if iii_03 < 1 | iii_03 > 10
gen Paredes_bien = inlist(iii_03, 6) if iii_03!=.
label variable Paredes_bien "Paredes de ladrillo, piedra o bloque"

* Jubilaciones y pensiones
destring v_13*, replace force
foreach var of varlist v_13* {
    replace `var' = . if `var' == 999999998.00 | `var' == 999999999.00
}
egen pensiones = rowtotal(v_13e v_13h)
gen Pension_bien = (pensiones>0) if (v_13e!=. & v_13h!=.)
label variable Pension_bien "Reciben pensión o jubilación"

destring iii_05, replace force
replace iii_05 = . if iii_05 < 1 | iii_05 > 10
gen Piso_mal = inlist(iii_05, 1, 3, 4) if iii_05!=.
label variable Piso_mal "Pisos de Ladrillo de barro, plancha de cemento o de tierra"

** Privaciones

egen Refri = anycount(value*), values(3)
gen Refri_mal = Refri==0 if v_10!=""
label variable Refri_mal "No tiene refrigeradora"

destring iii_10, replace force
replace iii_10 = . if iii_10 < 1 | iii_10 > 10
gen Sanitario_bien = (iii_10== 1) if iii_10!=.
label variable Sanitario_bien "Tiene inodoro conectado a alcantarilla"

**** Variables del jefe de hogar ****

destring x_30, replace force
gen Ed_diversif_bien = inlist(x_30, 6, 7, 8)  if (x_08==1 & x_30!=.)
label variable Ed_diversif_bien "Jefe completó diversificado, técnico superior o superior No universitaria"

gen Ed_univer_bien = inlist(x_30, 9, 10)  if (x_08==1 & x_30!=.)
label variable Ed_univer_bien "Jefe completó educación universitaria"

gen HaySanitario_bien = inlist(iii_10, 1, 2, 3, 4, 5, 6, 7, 8) if iii_10 !=.
label variable HaySanitario_bien "Tiene servicio sanitario o letrina"

gen privacion_cocina_h = inlist(v_05, 1) if v_05!=.
label variable privacion_cocina_h "El combustible para cocinar es leña"

destring x_28, replace force
gen privacion_alfab = (edad>15 & x_28==2) if (edad!=. & x_28!=.)
egen privacion_alfab_h = max(privacion_alfab) if privacion_alfab!=., by(hogid)
label variable privacion_alfab_h "Al menos un miembro del hogar mayor de 15 años no sabe leer y escribir."

destring x_29, replace force
gen privacion_asistencia = (inrange(edad, 3, 14) & x_29==2) if (edad!=. & x_29!=.)
egen privacion_asistencia_h = max(privacion_asistencia) if privacion_asistencia!=., by(hogid)
label variable privacion_asistencia_h "Al menos un miembro del hogar entre 3 y 14 años no asiste a la escuela."

* Usamos proxy porque no estan los años de educacion
destring x_31, replace force
gen privacion_educ = (inrange(edad, 15, 49) & (x_30 <= 4) & (x_31 <= 3)) if (edad!=. & x_30!=. & x_31!=.)
egen privacion_educ_h = max(privacion_educ) if privacion_educ!=., by(hogid) 
label variable privacion_educ_h "El Hogar es privado cuando al menos 1 miembro entre 15 y 49 años tiene 6 años o menos de escolaridad."

******* Ahora me quedo solo con los jefes de hogar *************
keep if x_08 == 1

save "C:\Users\pilih\Documents\World Bank\Honduras\Replication PMT IPM\2. Data\Data_out\SIRBHO_intermedia_clean.dta", replace

use "C:\Users\pilih\Documents\World Bank\Honduras\Replication PMT IPM\2. Data\Data_out\SIRBHO_intermedia_clean.dta", clear

*** Chequeo de las variables que usamos ***
*global vars_orig level1id numhog x_00 iii_08 value* v_05 x_32 tot_personas iii_11 edad iii_03 tot_piezas moto iii_05 iii_10 x_30 x_08 x_28 x_29 v_13e v_13h
*sum $vars_orig

*global vars_pmt_tot Agua2_bien Aire_mal Bici_mal Cable_mal Carro_mal Cocina2_bien Compu_mal Dependencia Ed_diversif_bien Ed_univer_bien EqSonido_mal Estufa_mal Hacinamiento HaySanitario_bien Moto_mal Paredes_bien Pension_bien Piso_mal Refri_mal Sanitario_bien edad_0_5 edad_15_21 edad_60_120 edad_6_14 privacion_alfab_h privacion_asistencia_h privacion_cocina_h privacion_educ_h privacion_saneamiento_h

global vars_pmt_ru Agua2_bien Bici_mal Cable_mal Carro_mal Compu_mal Dependencia dv111 Ed_diversif_bien Ed_univer_bien edad_0_5 edad_15_21 edad_6_14 EqSonido_mal Estufa_mal Hacinamiento HaySanitario_bien Moto_mal Paredes_bien Pension_bien Piso_mal privacion_alfab_h privacion_cocina_h privacion_educ_h Refri_mal Sanitario_bien

keep level1id $vars_pmt_ru ipm ipmo sumipm

* No generamos la variables Dominio 2 y 3 que forman parte del PMT de Urbano pero como en rural no aplica no es un problema.
* privacion_saneamiento_h habria que generarla si se usa para urbano.

save "C:\Users\pilih\Documents\World Bank\Honduras\Replication PMT IPM\2. Data\Data_out\SIRBHO_clean.dta", replace

* Seccion 2
*******************************************
****   Estimacion del ingreso SIRBHO   ****
*******************************************


import excel "C:\Users\pilih\Documents\World Bank\Honduras\Replication PMT IPM\3. Outputs\lasso_coefs.xlsx", firstrow clear

* Nos quedamos solo con los valores para rural
drop lasso_all_l_1_ur
rename lasso_all_l_2_ur beta
drop if beta ==.

gen id = _n  // Generar un identificador para mantener el orden
reshape wide beta, i(id) j(Variable) string
foreach var of varlist beta* {
    local newname = subinstr("`var'", "beta", "b_", 1)
    rename `var' `newname'
}
collapse (max) b_*
gen key = 1
rename b__cons b_cons

save "C:\Users\pilih\Documents\World Bank\Honduras\Replication PMT IPM\2. Data\Data_out\betas_clean.dta", replace

use "C:\Users\pilih\Documents\World Bank\Honduras\Replication PMT IPM\2. Data\Data_out\SIRBHO_clean", clear

gen key = 1
gen b_ipm = 1
gen b_ipmo = 1

destring ipm, replace force
destring ipmo, replace force

merge m:1 key using "C:\Users\pilih\Documents\World Bank\Honduras\Replication PMT IPM\2. Data\Data_out\betas_clean.dta"

drop key _merge

// * Paso nas a cero
// foreach var of varlist _all {
//     replace `var' = 0 if missing(`var')
// }

gen cons = 1

global vars_pmt_ru $vars_pmt_ru cons

gen log_ingreso_pred = 0
foreach var of global vars_pmt_ru {
    replace log_ingreso_pred = log_ingreso_pred + (`var' * b_`var')
}

gen ingreso_pred = exp(log_ingreso_pred)


estimates use "C:\Users\pilih\Documents\World Bank\Honduras\Replication PMT IPM\2. Data\Data_out\lasso_l_2_ur" 
predict testbeta 
gen ingreso_pred_beta = exp(testbeta)
kdensity ingreso_pred_beta

br testbeta log_ingreso_pred


hist ingreso_pred_beta if ingreso_pred_beta <=7000, bin(100)



sort log_ingreso_pred
br log_ingreso_pred* ingreso_pred ipm
gen incoh = (ipm==.)
drop if incoh==1


destring sumipm, gen(ipm_continuo) force dpcomma
spearman ipm_continuo ingreso_pred




preserve
sort log_ingreso_pred
keep ipm ipmo log_ingreso_pred
save "C:\Users\pilih\Documents\World Bank\Honduras\Replication PMT IPM\2. Data\Data_out\ipmvspred.dta", replace
restore


*** Comparacion de las medias con las de la EPH
global vars_pmt_ru Agua2_bien Bici_mal Cable_mal Carro_mal Compu_mal Dependencia dv111 Ed_diversif_bien Ed_univer_bien edad_0_5 edad_15_21 edad_6_14 EqSonido_mal Estufa_mal Hacinamiento HaySanitario_bien Moto_mal Paredes_bien Pension_bien Piso_mal privacion_alfab_h privacion_cocina_h privacion_educ_h Refri_mal Sanitario_bien

estimates use

sum $vars_pmt_ru

*** 
*histogram log_ingreso_pred, bin(100)
histogram ingreso_pred if ingreso_pred<500000, bin(100)
kdensity log_ingreso_pred


****




set seed 825
set type double

import spss "$EPHPM_PATH", clear
drop if QUINTILH==6

gen logingreso = log(YPERHG)
gen pobreza = inlist(POBREZA, 1, 2) if POBREZA!=.
gen no_pobreza = 1-pobreza if POBREZA!=.
gen pobreza_ext = inlist(POBREZA, 1) if POBREZA!=.
gen no_pobreza_ext = 1-pobreza_ext if POBREZA!=.

*********************************************
**** Generar variables para PMT Honduras ****
*********************************************

** Seccion 1: Variables usadas en la regresión inicial**

gen Dominio_1 = (DOMINIO == 1) if DOMINIO!=.
label variable Dominio_1 "Distrito Central"

gen Dominio_2 = (DOMINIO == 2) if DOMINIO!=.
label variable Dominio_2 "San Pedro Sula"

gen Dominio_3 = (DOMINIO == 3) if DOMINIO!=.
label variable Dominio_3 "Ciudades medianas"

gen Dominio_4 = (DOMINIO == 4) if DOMINIO!=.
label variable Dominio_4 "Ciudades pequeñas"

gen Vivienda_bien = inlist(V01, 1, 4) if V01!=.
label variable Vivienda_bien "Casa individual o Apartamento"

gen Paredes_bien = (V02 == 1) if V02!=.
label variable Paredes_bien "Paredes de ladrillo, piedra o bloque"

gen Piso_mal = inlist(V03, 4, 5, 7) if V03!=.
label variable Piso_mal "Pisos de Ladrillo de barro, plancha de cemento o de tierra"

gen Agua_bien = (V05 == 1) if V05!=.
label variable Agua_bien "Agua de tubería instalada"

gen Agua2_bien = (V06 == 1) if V06!=.
label variable Agua2_bien "Agua dentro de la vivienda"

gen Alumbrado_bien = (V07 == 1) if V07!=.
label variable Agua2_bien "Alumbrado público"

gen Basura_bien = inlist(V08, 1, 2, 3) if V08!=.
label variable Basura_bien "Basura la recogen o la pone en contenedores"

gen Vivienda2_bien = inlist(V10, 1, 2, 3) if V10!=.
label variable Vivienda2_bien "Vivienda alquilada o propietario pagando o pagada"

* Eliminamos valores incoherentes de cantidad de habitaciones y ambientes
drop if (H09 == 99 | H09 == 98 | H09<0) 
drop if (V09 == 99 | V09 == 98 | V09<0) 

* Winsoriza la variable de cantidad de ambientes en casa. Hay valores de 22 y más.
winsor V09, gen(V09_w) p(0.01) highonly 
replace V09 = V09_w
drop V09_w

gen Hacinamiento = (TOTPER / H09) 
label variable Hacinamiento  "Personas por dormitorio"

gen Cocina_bien = (H02 == 1) if H02!=.
label variable Cocina_bien "Cocina alimentos en una pieza dedica solo a cocinar"

gen Cocina2_bien = inlist(H04, 3, 4) if H04!=.
label variable Cocina2_bien "Cocina con gas propano o electricidad"

gen Estufa_bien = (H05 == 1) if H05!=.
label variable Estufa_bien "Cocina en estufa eléctrica"

gen HaySanitario_bien = (H06 == 1) if H06!=.
label variable HaySanitario_bien "Tiene servicio sanitario o letrina"

gen Sanitario_bien = (H07 == 1) if H07!=.
label variable Sanitario_bien "Tiene inodoro conectado a alcantarilla"

gen Refri_mal = (H01_1 == 0) if H01_1!=.
label variable Refri_mal "No tiene refrigeradora"

gen Estufa_mal = (H01_2 == 0) if H01_2!=.
label variable Estufa_mal "No tiene estufa"

gen TV_mal = (H01_3 == 0) if H01_3!=.
label variable TV_mal "No tiene televisor"

gen Cable_mal = (H01_4 == 0) if H01_4!=.
label variable Cable_mal "No tiene servicio de cable"

gen Radio_mal = (H01_5 == 0) if H01_5!=.
label variable Radio_mal "No tiene radio"

gen EqSonido_mal = (H01_6 == 0) if H01_6!=.
label variable EqSonido_mal "No tiene equipo de sonido"

gen Telefono_mal = (H01_7 == 0) if H01_7!=.
label variable Telefono_mal "No tiene teléfono fijo"

gen Carro_mal = (H01_8 == 0) if H01_8!=.
label variable Carro_mal "No tiene carro"

gen Moto_mal = (H01_9 == 0) if H01_9!=.
label variable Moto_mal "No tiene motocicleta"

gen Bici_mal = (H01_10 == 0) if H01_10!=.
label variable Bici_mal "No tiene bicicleta"

gen Compu_mal = (H01_11 == 0 | H01_11 ==.) // Nota: se asume que . es cero, porque hay muchos missings en esta variable
label variable Compu_mal "No tiene computadora"

gen Aire_mal = (H01_12 == 0) if H01_12!=.
label variable Aire_mal "No tiene aire acondicionado"

gen Exterior_bien = (ME01 == 1) if ME01!=.
label variable Exterior_bien "Alguien del hogar vive en el exterior"

gen Civil_mal = inlist(CIVIL, 2, 5, 6) if CIVIL!=.
label variable Civil_mal "Jefe es viudo, soltero o en unión libre"

gen Ed_basica_bien = (ED05 == 4 | ED05 == .) // Imputo educación
label variable Ed_basica_bien "Jefe completó educación básica"

gen Ed_diversif_bien = inlist(ED05, 5, 6, 7)
label variable Ed_diversif_bien "Jefe completó diversificado, técnico superior o superior No universitaria"

gen Ed_univer_bien = inlist(ED05, 8, 9, 10, 11)
label variable Ed_univer_bien "Jefe completó educación universitaria"

* Proxy, no tenemos el dato
gen Compu_bien = (Compu_mal == 1)
label variable Compu_bien "Jefe uso computadora el mes pasado" 

// gen Internet_bien = (TIC03 == 1)
// label variable Internet_bien "Jefe  tuvo acceso a internet en los últimos 3 meses"

// gen Celular_bien = (TIC09 == 1)
// label variable Celular_bien "Jefe tiene celular"

gen Trabajo_bien = (CA501 == 1) if CA501!=.
label variable Trabajo_bien "Trabajó la semana pasada"

gen Ocupacion_bien = inlist(OC609, 1, 6)  if OC609!=.
label variable Ocupacion_bien "Ocupación: Empleado u obrero público, Empleados, patrón o socio"

* Edad del jefe
gen edad = EDAD if NPER == 1
label variable edad "Edad"

gen edad_jefe2 = EDAD^2 if NPER == 1
label variable edad_jefe2 "Edad del jefe al cuadrado"

* Variables intermedias para la edad
gen temp_edad_0_5 = (EDAD >= 0 & EDAD <= 5) if EDAD!=.
gen temp_edad_6_14 = (EDAD >= 6 & EDAD <= 14) if EDAD!=.
gen temp_edad_15_21 = (EDAD >= 15 & EDAD <= 21) if EDAD!=.
gen temp_edad_22_60 = (EDAD >= 22 & EDAD <= 60) if EDAD!=.
gen temp_edad_60_120 = (EDAD >60) if EDAD!=.

* Suma de variable edad por hogar
sort HOGAR, stable
by HOGAR: gen num_edad_0_5 = sum(temp_edad_0_5)
by HOGAR: gen num_edad_6_14 = sum(temp_edad_6_14)
by HOGAR: gen num_edad_15_21 = sum(temp_edad_15_21)
by HOGAR: gen num_edad_22_60 = sum(temp_edad_22_60)
by HOGAR: gen num_edad_60_120 = sum(temp_edad_60_120)

* Valor máximo
by HOGAR: replace num_edad_0_5 = num_edad_0_5[_N]
by HOGAR: replace num_edad_6_14 = num_edad_6_14[_N]
by HOGAR: replace num_edad_15_21 = num_edad_15_21[_N]
by HOGAR: replace num_edad_22_60 = num_edad_22_60[_N]
by HOGAR: replace num_edad_60_120 = num_edad_60_120[_N]

gen edad_0_5 = num_edad_0_5
label variable edad_0_5 "# de personas de 0 a 5"

gen edad_6_14 = num_edad_6_14
label variable edad_6_14 "# de personas de 6 a 14"

gen edad_15_21 = num_edad_15_21
label variable edad_15_21 "# de personas de 15 a 21"

gen edad_22_60 = num_edad_22_60
label variable edad_22_60 "# de personas de 22 a 60"

gen edad_60_120 = num_edad_60_120
label variable edad_60_120 "# de personas de más de 60"

* Eliminamos variables intermedias
drop num_edad_0_5 num_edad_6_14 num_edad_15_21 num_edad_22_60 num_edad_60_120 temp_edad_0_5 temp_edad_6_14 temp_edad_15_21 temp_edad_22_60 temp_edad_60_120 

gen dv111 = V09
label variable dv111 "Sin incluir la cocina, el baño y garaje ¿Cuántas piezas tiene esta viv"

gen dv112 = H09
label variable dv112 "Del total de piezas de la vivienda, ¿Cuántas utilizan para dormir?"

* Por hogar cuantas personas trabajan
sort HOGAR, stable
by HOGAR: gen trabajo_hogar = sum(CA501 == 1)
by HOGAR: replace trabajo_hogar = trabajo_hogar[_N]

gen Dependencia = (trabajo_hogar/TOTPER)
label variable Dependencia "# de miembros trabajando la semana pasada / Tamaño del hogar entre"
drop trabajo_hogar

* Jubilaciones y pensiones

* Reemplazamos missings por cero para poder sumarlos
replace OIH01_LPS =0 if OIH01_LPS ==.
replace OIH01_US =0 if OIH01_US==.
replace OIH02_LPS =0 if OIH02_LPS ==.
replace OIH05_LPS=0 if OIH05_LPS==.
replace OIH05_US=0 if OIH05_US==.

* Sumamos jubilaciones o pensiones por hogar
sort HOGAR NPER, stable
by HOGAR: egen hh_OIH01_LPS = total(OIH01_LPS)
by HOGAR: egen hh_OIH01_US = total(OIH01_US)
by HOGAR: egen hh_OIH02_LPS = total(OIH02_LPS)
by HOGAR: egen hh_OIH05_LPS = total(OIH05_LPS)
by HOGAR: egen hh_OIH05_US = total(OIH05_US)

egen pen_jub_monto = rowtotal(hh_OIH01_LPS hh_OIH01_US hh_OIH02_LPS hh_OIH05_LPS hh_OIH05_US) 

gen Pension_bien = (pen_jub_monto>0)
label variable Pension_bien "Reciben pensión o jubilación"

* Alquileres
* Reemplazamos missings por cero para poder sumarlos
replace OIH03_LPS =0 if OIH03_LPS ==.
sort HOGAR NPER, stable
by HOGAR: egen hh_OIH03_LPS = total(OIH03_LPS)

gen Alquileres_bien = (hh_OIH03_LPS>0)
label variable Alquileres_bien "Reciben alquileres"

* Remesas del exterior (cualquier moneda)
* Reemplazamos missings por cero para poder sumarlos
replace OIH12_LPS =0 if OIH12_LPS ==.
replace OIH12_US =0 if OIH12_US==.
replace OIH12_LPS_ESP =0 if OIH12_LPS_ESP ==.
replace OIH12_US_ESP=0 if OIH12_US_ESP==.

sort HOGAR NPER, stable
by HOGAR: egen hh_OIH12_LPS = total(OIH12_LPS)
by HOGAR: egen hh_OIH12_US = total(OIH12_US)
by HOGAR: egen hh_OIH12_LPS_ESP = total(OIH12_LPS_ESP)
by HOGAR: egen hh_OIH12_US_ESP = total(OIH12_US_ESP)

egen remesas_monto = rowtotal(hh_OIH12_LPS hh_OIH12_US hh_OIH12_LPS_ESP hh_OIH12_US_ESP)

gen Remesas_bien = (remesas_monto>0)
label variable Remesas_bien "Reciben remesas del exterior"

*********************************************
**** Generar variables para IPM Honduras ****
*********************************************

*###############################
*######*     SALUD    ##########
*###############################

*#######* AGUA

* En la zona urbana (UR==1) el servicio de agua no es brindado por tubería (V05 == 1) 
* dentro de la vivienda o de la propiedad (inlist(V06, 1, 2))
gen privacion_agua = .
replace privacion_agua = !(V05 == 1 & inlist(V06, 1, 2)) if UR==1 & !mi(V05, V06)

* En la zona rural (UR==2) el servicio de agua no es brindado por tubería o agua
* de pozo protegido de llave comunitaria (inlist(V05, 1, 4)) ubicada a menos de 100 metros
* de la vivienda (inlist(V06, 1, 2, 3)).
replace privacion_agua = !(inlist(V05, 1, 4) & inlist(V06, 1, 2, 3)) if UR==2 & !mi(V05, V06)
egen privacion_agua_h = max(privacion_agua), by(HOGAR)

*#######* SANEAMIENTO

* En la zona urbana el servicio sanitario no es un inodoro conectado a
* alcantarillado o a pozo séptico (inlist(H07, 1, 2)).
gen privacion_saneamiento = .
replace privacion_saneamiento = !(inlist(H07, 1, 2)) if UR==1 & !mi(H07)

* En la zona rural el sistema de saneamiento no es un inodoro conectado
* a alcantarilla o a pozo séptico, o no es una letrina con cierre hidráulico
* o pozo séptico (inlist(H07, 1, 2, 5, 6)).
replace privacion_saneamiento = !(inlist(H07, 1, 2, 5, 6)) if UR==2 & !mi(H07)
egen privacion_saneamiento_h = max(privacion_saneamiento), by(HOGAR)


*#######* COCINA

* El combustible para cocinar es leña
gen privacion_cocina = (H04 == 1) if !mi(H04)
egen privacion_cocina_h = max(privacion_cocina), by(HOGAR)


*###################################
*######*     EDUCACION    ##########
*###################################

*#######* Años de escolaridad
* El Hogar es privado cuando al menos 1 miembro entre 15 y 49
* años (inrange(EDAD, 15, 49)) tiene 6 años o menos de escolaridad (ANOSEST<6).
gen privacion_educ = (inrange(EDAD, 15, 49) & ANOSEST<6) if !mi(EDAD, ANOSEST)
egen privacion_educ_h = max(privacion_educ), by(HOGAR)


*#######* Asistencia escolar 
* Al menos un miembro del hogar entre 3 y 14 años (inrange(EDAD, 3, 14) no asiste a la
* escuela ( ED03==2).
gen privacion_asistencia = (inrange(EDAD, 3, 14) & ED03==2) if !mi(EDAD, ED03)
egen privacion_asistencia_h = max(privacion_asistencia), by(HOGAR)


*#######* Analfabetismo
* Al menos un miembro del hogar mayor de 15 años no sabe leer y
* escribir.
gen privacion_alfab = (EDAD>15 & ED01==2) if !mi(EDAD, ED01)
egen privacion_alfab_h = max(privacion_alfab), by(HOGAR)

*###################################
*######*      TRABAJO     ##########
*###################################

egen horas = rowtotal(OC_605*)

*#######* Seguridad social 

* Al menos una persona ocupada en edad laboral (18 a 65 años), no
* está cotizando a un sistema de seguridad social (INJUPEMP o
* INPREMA o IPM o IHSS o fondo privado de pensiones o seguro
* médico privado).
egen cotiza = rowmin(OC620 OC626 OC6201 OC6261) 
gen privacion_segsoc = !(cotiza==1) if inrange(EDAD, 18, 65)
egen privacion_segsoc_h = max(privacion_segsoc), by(HOGAR)

* Son privados todos los hogares donde al menos 1 de sus
* miembros en edad productiva es desocupado
gen privacion_desocup = (CONDACT==2 & inrange(EDAD, 14, 65))
egen privacion_desocup_h = max(privacion_desocup), by(HOGAR)


*#######* Sub-empleo 

* Al menos una persona ocupada del hogar que trabaja 40 horas por
* semana gana menos de un salario mínimo.
gen privacion_subemp = (horas>40 & YTRAB<SALMIN) if !mi(horas, YTRAB, SALMIN)
egen privacion_subemp_h = max(privacion_subemp), by(HOGAR)

* todos los miembros del hogar en edad productiva SON desocupados (CONDACT==2),
* excepto que se trate de personas en condición de inactividad (CONDACT==3).
gen privacion_ocup = (CONDACT==2 | CONDACT==3)
egen q_no_ocup = total(privacion_ocup), by(HOGAR)
gen privacion_ocup_h = (q_no_ocup / TOTPER == 1)

*#######* Trabajo infantil

* Existe al menos un niño de 5 a 13 años de edad que trabaja.
gen privacion_trabinf = (inrange(EDAD, 5, 13) & CA501==1) if !mi(EDAD, CA501)
egen privacion_trabinf_h = max(privacion_trabinf), by(HOGAR)

* Existe al menos un niño de 14 o 15 años de edad que trabaja más
* de 20 horas por semana y no estudia.
gen privacion_trabadol1 = (inrange(EDAD, 14, 15) & horas>20 & ED03==2) if !mi(EDAD, ED03, horas)
egen privacion_trabadol1_h = max(privacion_trabadol1), by(HOGAR)

* Existe al menos un niño de 16 o 17 años de edad que trabaja más
* de 30 horas por semana y no estudia.
gen privacion_trabadol2 = (inrange(EDAD, 16, 17) & horas>30 & ED03==2) if !mi(EDAD, ED03, horas)
egen privacion_trabadol2_h = max(privacion_trabadol2), by(HOGAR)


*###################################
*######*     VIVIENDA     ##########
*###################################

*######* Acceso a electricidad
* No tiene acceso a electricidad por servicio público, servicio
* privado colectivo, plata propia o energía solar (inlist(V007, 1, 2, 3, 4))
gen privacion_elec = (!inlist(V07, 1, 2, 3, 4)) if !mi(V07)
egen privacion_elec_h = max(privacion_elec), by(HOGAR)

*######*  Material Pisos
* La vivienda tiene pisos de tierra u otro material
gen privacion_piso = (V03 == 7) if !mi(V03)
egen privacion_piso_h = max(privacion_piso), by(HOGAR)

*######*  Material techos
* La vivienda tiene techo de Paja, palma o similar o material de
* desecho u otro
gen privacion_techo = (inlist(V04, 7, 8)) if !mi(V04)
egen privacion_techo_h = max(privacion_techo), by(HOGAR)


*######*  Material Paredes
* La vivienda tiene pared de Bahareque, vara o caña o material de
* desecho
gen privacion_pared = (inlist(V02, 6, 7)) if !mi(V02)
egen privacion_pared_h = max(privacion_pared), by(HOGAR)

*######*  Hacinamiento
* La vivienda tiene 3 personas (TOTPER) o más por cuarto, excluyendo cocina,
* baño y garaje (V09)
gen personas_por_cuartos = TOTPER / V09
gen privacion_hacina = (personas_por_cuartos>=3) & !mi(personas_por_cuartos)
egen privacion_hacina_h = max(privacion_hacina), by(HOGAR)

*********************************************
****        Base a nivel hogar           ****
*********************************************


* Generamos ponderador a nivel de hogar (personal * cantidad de miembros)
*	Esto nos permite replicar las estadisticas de pobreza de personas, 
*	con una base que solo tiene miembros del hogar.
keep if NPER==1
gen FACTOR_P = FACTOR * TOTPER
egen hogar = tag(HOGAR)
keep if hogar==1

*********************************************
****           Cálculo del IPM           ****
*********************************************

gen indice_pobreza_multi = 1/12 * privacion_agua_h +  1/12 * privacion_saneamiento_h + 1/12 * privacion_cocina_h + 1/12 *  privacion_educ_h + 1/12 * privacion_asistencia_h + 1/12 * privacion_alfab_h + 1/24 * privacion_segsoc_h + 1/24 * privacion_desocup_h + 1/24 * privacion_subemp_h + 1/24 * privacion_ocup_h + 1/36 * privacion_trabinf_h + 1/36 * privacion_trabadol1_h + 1/36 * privacion_trabadol2_h + 1/24 * privacion_elec_h + 1/24 * privacion_piso_h + 1/24 * privacion_techo_h + 1/24 * privacion_pared_h + 1/24 * privacion_hacina_h


drop if indice_pobreza_multi == .

gen pobreza_multidim = (indice_pobreza_multi>=0.25)
gen no_pob_multidim = 1 - pobreza_multidim


**************************************************
**** Estimación del ingreso en función de PMT ****
**************************************************

* Este codigo busca reconstruir el ingreso estimado para las familias en Honduras en función del documento metodológico del WB
* Documento de referencia: "ESTIMACIÓN DE INGRESOS DE LOS HOGARES URBANOS POR MEDIO DE UNA REGRESIÓN MULTIVARIADA, HONDURAS" Carlos E. Sobrado, Banco Mundial, 22 de febrero, 2023

/* 
Estimación del Ingreso de los Hogares del documento WB:
- Constante: 7.0556
- Basura recolectada domicilio Pública, Privada o la Deposita en contenedores: 0.1236
- La vivienda que tiene es Propia, Propia pagándola o Alquilada: 0.4290
- NBI_CAPS Sin capacidad de subsistencia: -0.6508
- Paredes de ladrillo, piedra o bloque: 0.1013
- Alumbrado público: 0.2017
- Cocina con gas propano o electricidad: 0.1126
- Sin incluir cocina, baño y garaje ¿# piezas tiene esta vivienda?: 0.0438
- No tiene refrigeradora: -0.1565
- No tiene estufa: -0.0963
- No tiene carro: -0.1373
- No tiene computadora: -0.1725
- No tiene aire acondicionado: -0.1585
- Jefe completó ciclo común: 0.0705
- Jefe completó diversificado, técnico superior o superior no universitaria: 0.1474
- Jefe completó educación universitaria: 0.3999
- Jefe es Empleado u obrero público, Empleador, patrón o socio: 0.2402
- # que trabajaron la semana pasada / Tamaño del hogar: 0.9922
- Reciben pensión o jubilación: 0.3570
- Reciben alquileres: 0.3503
- Reciben remesas del exterior: 0.1530
- No se preocupó por comer en 3 meses: 0.1747
- No dejó de comer un día entero en 3 meses: 0.1417
- Número de miembros de 0 a 5 años: -0.0712
- Número de miembros de 6 a 14 años: -0.1111
- Número de miembros de 15 a 21 años: -0.0415
- Número de miembros de más de 60 años: -0.0193
*/

gen log_ingreso_est = 7.0556 + 0.1236 * Basura_bien + 0.4290 * Vivienda2_bien + 0.1013 * Paredes_bien + 0.2017 * Alumbrado_bien + 0.1126 * Cocina2_bien - 0.1565 * Refri_mal - 0.0963 * Estufa_mal - 0.1373 * Carro_mal - 0.1725 * Compu_mal - 0.1585 * Aire_mal + 0.1474 * Ed_diversif_bien + 0.3999 * Ed_univer_bien + 0.2402 * Ocupacion_bien + 0.9922 * Dependencia+ 0.3570 * Pension_bien + 0.3503 * Alquileres_bien + 0.1530 * Remesas_bien - 0.0712 * edad_0_5 - 0.1111 * edad_6_14 - 0.0415 * edad_15_21 - 0.0193 * edad_60_120 + 0.0438 * dv111

/* Variables que no pudimos incluir: 
- No se preocupó por comer en 3 meses: 0.1747
- No dejó de comer un día entero en 3 meses: 0.1417
*/

* Estimamos el ingreso
gen ingreso_est = exp(log_ingreso_est)

sort ingreso_est YTOTHG, stable


***************** Asigna grupo de test

gen random_num = runiform()
gen test_set = (random_num<0.3)

******** Ajuste de winsor para las colas **************
winsor logingreso, gen(logingreso_w) p(0.01)
replace logingreso = logingreso_w
drop logingreso_w

***** ESTADISTICAS DE POBREZA
sort UR, stable
by UR: sum pobreza [w=FACTOR_P]

* Elimina obs con missings en variables del conjunto 2 (3 observaciones)
drop if mi(privacion_saneamiento_h, privacion_cocina_h, privacion_educ_h, privacion_asistencia_h, privacion_alfab_h, Piso_mal, Paredes_bien, EqSonido_mal, HaySanitario_bien, Sanitario_bien, Cocina2_bien, Hacinamiento, Cable_mal, Moto_mal, Bici_mal, Dominio_1, Dominio_2, Dominio_3, Pension_bien, Refri_mal, Aire_mal, Carro_mal, Compu_mal, dv111, Ed_diversif_bien, Ed_univer_bien, edad_0_5, edad_15_21, edad_60_120, edad_6_14, Estufa_mal, Agua2_bien, Dependencia)

save "$PATH\Data_out\CONSOLIDADA_2023_clean.dta", replace
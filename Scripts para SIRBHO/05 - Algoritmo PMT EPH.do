************************************************
******** Estimación de ingresos con PMT ********
************************************************

* Este codigo busca reconstruir el ingreso estimado para las familias en Honduras en función del documento metodológico del WB

* Documetno de referencia: "ESTIMACIÓN DE INGRESOS DE LOS HOGARES URBANOS POR MEDIO DE UNA REGRESIÓN MULTIVARIADA, HONDURAS" Carlos E. Sobrado, Banco Mundial, 22 de febrero, 2023

import spss "D:\Datasets\EPH-PM Honduras\Consolidada 2023\CONSOLIDADA_2023.sav", clear
drop if QUINTILH==6

*********************************************
**** Generar variables para PMT Honduras ****
*********************************************

** Seccion 1: Variables usadas en la regresión inicial**

gen Dominio_1 = (DOMINIO == 1)
label variable Dominio_1 "Distrito Central"

gen Dominio_2 = (DOMINIO == 2)
label variable Dominio_2 "San Pedro Sula"

gen Dominio_3 = (DOMINIO == 3)
label variable Dominio_3 "Ciudades medianas"

gen Dominio_4 = (DOMINIO == 4)
label variable Dominio_4 "Ciudades pequeñas"

gen Vivienda_bien = inlist(V01, 1, 4)
label variable Vivienda_bien "Casa individual o Apartamento"

gen Paredes_bien = (V02 == 1)
label variable Paredes_bien "Paredes de ladrillo, piedra o bloque"

gen Piso_mal = inlist(V03, 4, 5, 7)
label variable Piso_mal "Pisos de Ladrillo de barro, plancha de cemento o de tierra"

gen Agua_bien = (V05 == 1)
label variable Agua_bien "Agua de tubería instalada"

gen Agua2_bien = (V06 == 1)
label variable Agua2_bien "Agua dentro de la vivienda"

gen Alumbrado_bien = (V07 == 1)
label variable Agua2_bien "Alumbrado público"

* Asumo que la 3 va, pero no se
gen Basura_bien = inlist(V08, 1, 2, 3)
label variable Basura_bien "Basura la recogen o la pone en contenedores"

gen Vivienda2_bien = inlist(V10, 1, 2, 3)
label variable Vivienda2_bien "Vivienda alquilada o propietario pagando o pagada"

gen Hacinamiento = (TOTPER / H09)
label variable Hacinamiento  "Personas por dormitorio"

gen Cocina_bien = (H02 == 1)
label variable Cocina_bien "Cocina alimentos en una pieza dedica solo a cocinar"

gen Cocina2_bien = inlist(H04, 3, 4)
label variable Cocina2_bien "Cocina con gas propano o electricidad"

gen Estufa_bien = (H05 == 1)
label variable Estufa_bien "Cocina en estufa eléctrica"

gen HaySanitario_bien = (H06 == 1)
label variable HaySanitario_bien "Tiene servicio sanitario o letrina"

gen Sanitario_bien = (H07 == 1)
label variable Sanitario_bien "Tiene inodoro conectado a alcantarilla"

gen Refri_mal = (H01_1 == 0)
label variable Refri_mal "No tiene refrigeradora"

gen Estufa_mal = (H01_2 == 0)
label variable Estufa_mal "No tiene estufa"

gen TV_mal = (H01_3 == 0)
label variable TV_mal "No tiene televisor"

gen Cable_mal = (H01_4 == 0)
label variable Cable_mal "No tiene servicio de cable"

gen Radio_mal = (H01_5 == 0)
label variable Radio_mal "No tiene radio"

gen EqSonido_mal = (H01_6 == 0)
label variable EqSonido_mal "No tiene equipo de sonido"

gen Telefono_mal = (H01_7 == 0)
label variable Telefono_mal "No tiene teléfono fijo"

gen Carro_mal = (H01_8 == 0)
label variable Carro_mal "No tiene carro"

gen Moto_mal = (H01_9 == 0)
label variable Moto_mal "No tiene motocicleta"

gen Bici_mal = (H01_10 == 0)
label variable Bici_mal "No tiene bicicleta"

gen Compu_mal = (H01_11 == 0)
label variable Compu_mal "No tiene computadora"

gen Aire_mal = (H01_12 == 0)
label variable Aire_mal "No tiene aire acondicionado"

gen Exterior_bien = (ME01 == 1)
label variable Exterior_bien "Alguien del hogar vive en el exterior"

gen Civil_mal = inlist(CIVIL, 2, 5, 6)
label variable Civil_mal "Jefe es viudo, soltero o en unión libre"

* LAS DE EDUCACION ME GENERAN DUDAS, porque no se si se refiere al nivel alcanzado como ultimo nivel o si cuenta si tiene aun mas educación

gen Ed_basica_bien = (ED05 == 4)
label variable Ed_basica_bien "Jefe completó educación básica"

* Asumo que es el 5
gen Ed_comun_bien = (ED05 == 5)
label variable Ed_comun_bien "Jefe completó ciclo común"

gen Ed_diversif_bien = inlist(ED05, 5, 6, 7)
label variable Ed_diversif_bien "Jefe completó diversificado, técnico superior o superior No universitaria"

gen Ed_univer_bien = (ED05 == 8)
label variable Ed_univer_bien "Jefe completó educación universitaria"

* Proxy, no tenemos el dato
gen Compu_bien = (Compu_mal == 1)
label variable Compu_bien "Jefe uso computadora el mes pasado" 

// gen Internet_bien = (TIC03 == 1)
// label variable Internet_bien "Jefe  tuvo acceso a internet en los últimos 3 meses"

// gen Celular_bien = (TIC09 == 1)
// label variable Celular_bien "Jefe tiene celular"

gen Trabajo_bien = (CA501 == 1)
label variable Trabajo_bien "Trabajó la semana pasada"

gen Ocupacion_bien = inlist(OC609, 1, 6)
label variable Ocupacion_bien "Ocupación: Empleado u obrero público, Empleados, patrón o socio"

* Edad del jefe
gen edad = EDAD if NPER == 1
label variable edad "Edad"

gen edad_jefe2 = EDAD^2 if NPER == 1
label variable edad_jefe2 "Edad del jefe al cuadrado"

* Genero variables intermedias para la edad
gen temp_edad_0_5 = (EDAD >= 0 & EDAD <= 5)
gen temp_edad_6_14 = (EDAD >= 6 & EDAD <= 14)
gen temp_edad_15_21 = (EDAD >= 15 & EDAD <= 21)
gen temp_edad_22_60 = (EDAD >= 22 & EDAD <= 60)
gen temp_edad_60_120 = (EDAD >60)

* Sumo variable edad por hogar
bysort HOGAR: gen num_edad_0_5 = sum(temp_edad_0_5)
bysort HOGAR: gen num_edad_6_14 = sum(temp_edad_6_14)
bysort HOGAR: gen num_edad_15_21 = sum(temp_edad_15_21)
bysort HOGAR: gen num_edad_22_60 = sum(temp_edad_22_60)
bysort HOGAR: gen num_edad_60_120 = sum(temp_edad_60_120)

* Me quedo con el valor máximo
bysort HOGAR: replace num_edad_0_5 = num_edad_0_5[_N]
bysort HOGAR: replace num_edad_6_14 = num_edad_6_14[_N]
bysort HOGAR: replace num_edad_15_21 = num_edad_15_21[_N]
bysort HOGAR: replace num_edad_22_60 = num_edad_22_60[_N]
bysort HOGAR: replace num_edad_60_120 = num_edad_60_120[_N]

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

* Dropeo variables intermedias
drop num_edad_0_5 num_edad_6_14 num_edad_15_21 num_edad_22_60 num_edad_60_120 temp_edad_0_5 temp_edad_6_14 temp_edad_15_21 temp_edad_22_60 temp_edad_60_120 

gen dv111 = V09
label variable dv111 "Sin incluir   la cocina, el baño y garaje ¿Cuántas piezas tiene esta viv"

gen dv112 = H09
label variable dv112 "Del total de piezas de la vivienda, ¿Cuántas utilizan para dormir?"

* Miro por hogar cuantas personas trabajan
bysort HOGAR: gen trabajo_hogar = sum(CA501 == 1)
bysort HOGAR: replace trabajo_hogar = trabajo_hogar[_N]
* Ahora uso esa variable para el calculo
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
sort HOGAR NPER
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
sort HOGAR NPER
by HOGAR: egen hh_OIH03_LPS = total(OIH03_LPS)

gen Alquileres_bien = (hh_OIH03_LPS>0)
label variable Alquileres_bien "Reciben alquileres"

* Remesas del exterior (cualquier moneda)
* Reemplazamos missings por cero para poder sumarlos
replace OIH12_LPS =0 if OIH12_LPS ==.
replace OIH12_US =0 if OIH12_US==.
replace OIH12_LPS_ESP =0 if OIH12_LPS_ESP ==.
replace OIH12_US_ESP=0 if OIH12_US_ESP==.

sort HOGAR NPER
by HOGAR: egen hh_OIH12_LPS = total(OIH12_LPS)
by HOGAR: egen hh_OIH12_US = total(OIH12_US)
by HOGAR: egen hh_OIH12_LPS_ESP = total(OIH12_LPS_ESP)
by HOGAR: egen hh_OIH12_US_ESP = total(OIH12_US_ESP)

egen remesas_monto = rowtotal(hh_OIH12_LPS hh_OIH12_US hh_OIH12_LPS_ESP hh_OIH12_US_ESP)

gen Remesas_bien = (remesas_monto>0)
label variable Remesas_bien "Reciben remesas del exterior"


**************************************************
**** Estimación del ingreso en función de PMT ****
**************************************************

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

sort NPER
egen hogar = tag(HOGAR)
keep if hogar==1

gen log_ingreso_est = 7.0556 + 0.1236 * Basura_bien + 0.4290 * Vivienda2_bien + 0.1013 * Paredes_bien + 0.2017 * Alumbrado_bien + 0.1126 * Cocina2_bien - 0.1565 * Refri_mal - 0.0963 * Estufa_mal - 0.1373 * Carro_mal - 0.1725 * Compu_mal - 0.1585 * Aire_mal + 0.0705 * Ed_comun_bien + 0.1474 * Ed_diversif_bien + 0.3999 * Ed_univer_bien + 0.2402 * Ocupacion_bien + 0.9922 * Dependencia+ 0.3570 * Pension_bien + 0.3503 * Alquileres_bien + 0.1530 * Remesas_bien - 0.0712 * edad_0_5 - 0.1111 * edad_6_14 - 0.0415 * edad_15_21 - 0.0193 * edad_60_120 + 0.0438 * dv111

/* Variables que no pudimos incluir: 
- No se preocupó por comer en 3 meses: 0.1747
- No dejó de comer un día entero en 3 meses: 0.1417
*/

* Estimamos el ingreso
gen ingreso_est = exp(log_ingreso_est)

sort ingreso_est
* Dropeamos las observaciones que no son de jefes de hogar
drop if ingreso_est ==.

* Generamos variable que indica la posición relativa del hogar en la distribución de ingresos
gen pos = _n/_N

* Graficamos ingreso y posición
twoway line pos ingreso_est if ingreso_est<4000

*2834 deja al 50% por debajo del corte

* Variable que indica si es pobre segun la estimacion
gen pobre = (ingreso_est<2834)

** Estas líneas de código nos dan los datos que usamos para gráfico PPT**
tab pobre QUINTILH
*Separo rural y urbano
 tab pobre QUINTILH if UR==2, col
 tab pobre QUINTILH if UR==1, col
 
save "D:\World Bank\Honduras PMT benchmark\Data_out\basepmt_eph.dta", replace

************************************************************************************************** 
******* Las que siguen son variables que se nombran en el documento pero no pude generar *********
* Igual son variables que no se usaban, salvo las 2 que están mencionadas arriba
* Tiene que ver con que cambió la encuesta del 2019 en relacion a esta
//
// gen Escritura_mal = ()
// label variable Escritura_mal "No tiene escritura de la vivienda"
//
// gen DerechoTrabajo_mal = ()
// label variable DerechoTrabajo_mal "En la ocupación principal no tiene derecho a: 1-Pensión, 2-Días pagados por enfermedad ….. 11-Seguro de vida"
//
// gen Alimenticia_bien = ()
// label variable Alimenticia_bien "Reciben descuentos por adulto mayor o pensión alimenticia/divorcio"
//
// gen Ayudas_bien = ()
// label variable Ayudas_bien "Reciben ayudas familiares o particulares"
//
// gen NoComer1_bien = ()
// label variable NoComer1_bien "No se preocupó por comer en 3 meses"
//
// gen NoComer2_bien = ()
// label variable NoComer2_bien "No le faltó dinero para comer en 3 meses"
//
// gen NoComer3_bien = ()
// label variable NoComer3_bien "No le faltó variedad al comer en 3 meses"
//
// gen NoComer4_bien = ()
// label variable NoComer4_bien "No dejó de comer en 3 meses"
//
// gen NoComer5_bien = ()
// label variable NoComer5_bien "No comió menos en 3 meses"
//
// gen NoComer6_bien = ()
// label variable NoComer6_bien "No se quedaron sin alimentos en 3 meses"
//
// gen NoComer7_bien = ()
// label variable NoComer7_bien "No sintió hambre en 3 meses"
//
// gen NoComer8_bien = ()
// label variable NoComer8_bien "No dejó de comer un día entero en 3 meses"
//
// gen Compu2_bien = ()
// label variable  "Jefe uso computadora una vez por día"
//
// * No me queda nada claro como construir esta variale
// gen Ocupacion2_bien = inlist(OC609, 1, 6)
// label variable Ocupacion2_bien "Ocupación: empleado doméstico, cooperativa o asentamiento, cuenta propia que no contrata mano de obra temporal"
************************************************
******** Estimación de ingresos con PMT ********
************************************************

* Este codigo busca reconstruir el ingreso estimado para las familias en Honduras en función del documento metodológico del WB

* Documetno de referencia: "ESTIMACIÓN DE INGRESOS DE LOS HOGARES URBANOS POR MEDIO DE UNA REGRESIÓN MULTIVARIADA, HONDURAS" Carlos E. Sobrado, Banco Mundial, 22 de febrero, 2023



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
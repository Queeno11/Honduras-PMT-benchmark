************************************************
******** estimación de ingresos con PMT ********
************************************************

* este codigo busca reconstruir el ingreso estimado para las familias en honduras en función del documento metodológico del Wb

* documetno de referencia: "eSTiMaciÓN de iNGReSOS de LOS hOGaReS URbaNOS POR MediO de UNa ReGReSiÓN MULTivaRiada, hONdURaS" carlos e. Sobrado, banco Mundial, 22 de febrero, 2023

// import delimited using "d:\datasets\data honduras Red Solidaria\OdS - SiRbhO\OdS3_hogares.csv", clear delimiter(";")
// save "hogares.dta", replace
// import delimited using "d:\datasets\data honduras Red Solidaria\OdS - SiRbhO\OdS3_Poblacion.csv", clear delimiter(";")
// save "Personas.dta", replace


use "D:\Datasets\Data Honduras Red Solidaria\ODS - SIRBHO\ODS3_Poblacion_stata.dta", replace
merge m:1 level1id using "D:\Datasets\Data Honduras Red Solidaria\ODS - SIRBHO\ODS3_Hogares_stata.dta", force

egen hogid = group(level1id numhog)
bysort hogid: egen orden_min = min(x_00)
replace x_00 = 1 if orden_min!=1 & x_00==orden_min

*********************************************
**** Generar variables para PMT honduras ****
*********************************************

** Seccion 1: variables usadas en la regresión inicial**

** hasta aca

gen vivienda_bien = inlist(iii_01, "5", "6")
label variable vivienda_bien "casa individual o apartamento"

gen Paredes_bien = inlist(iii_03, "6")
label variable Paredes_bien "Paredes de ladrillo, piedra o bloque"

gen Piso_mal = inlist(iii_05, "1", "3", "4")
label variable Piso_mal "Pisos de Ladrillo de barro, plancha de cemento o de tierra"

gen agua_bien = inlist(iii_08, "1", "2")
label variable agua_bien "agua de tubería instalada"

* la otra distinguia entre dentro y fuera, cualquier forma de agua. dejé solo la que especifica adentro
gen agua2_bien = (iii_08 == "1")
label variable agua2_bien "agua dentro de la vivienda"

gen alumbrado_bien = (iii_06 == "1")
label variable alumbrado_bien "alumbrado público"

* asumo que la "3" va, pero no se
gen basura_bien = inlist(v_09, "1", "2", "3")
label variable basura_bien "basura la recogen o la pone en contenedores"

gen vivienda2_bien = inlist(iii_02, "1", "2", "3")
label variable vivienda2_bien "vivienda alquilada o propietario pagando o pagada"

destring v_02c, gen(tot_personas) force
rename v_01 tot_piezas
gen hacinamiento = (tot_personas / tot_piezas)
label variable hacinamiento  "Personas por dormitorio"

gen cocina_bien = (v_07 == "1")
label variable cocina_bien "cocina alimentos en una pieza dedica solo a cocinar"

gen cocina2_bien = inlist(v_05, "4", "5")
label variable cocina2_bien "cocina con gas propano o electricidad"

gen estufa_bien = (v_10 == "2")
label variable estufa_bien "cocina en estufa eléctrica"

gen haySanitario_bien = (iii_10 !="9")
label variable haySanitario_bien "Tiene servicio sanitario o letrina"

gen Sanitario_bien = (iii_10== "1")
label variable Sanitario_bien "Tiene inodoro conectado a alcantarilla"

*armo dummies, chequear que funcione!
split v_10, parse(;) gen(value) destring force

egen Refri = anycount(value*), values(3)
gen Refri_mal = Refri==0
label variable Refri_mal "No tiene refrigeradora"

egen estufa = anycount(value*), values(1, 2)
gen estufa_mal = (estufa == 0)
label variable estufa_mal "No tiene estufa"

egen tv = anycount(value*), values(7)
gen Tv_mal = (tv == 0)
label variable Tv_mal "No tiene televisor"

egen cable = anycount(value*), values(12)
gen cable_mal = (cable == 0)
label variable cable_mal "No tiene servicio de cable"

egen radio = anycount(value*), values(15)
gen Radio_mal = (radio == 0)
label variable Radio_mal "No tiene radio"

egen eqSonido = anycount(value*), values(9)
gen eqSonido_mal = (eqSonido == 0)
label variable eqSonido_mal "No tiene equipo de sonido"

egen Telefono = anycount(value*), values(4)
gen Telefono_mal = (Telefono == 0)
label variable Telefono_mal "No tiene teléfono fijo"

egen carro = anycount(value*), values(19)
gen carro_mal = (carro == 0)
label variable carro_mal "No tiene carro"

egen moto = anycount(value*), values(20)
gen Moto_mal = (moto == 0)
label variable Moto_mal "No tiene motocicleta"

egen bici = anycount(value*), values(17)
gen bici_mal = (bici == 0)
label variable bici_mal "No tiene bicicleta"

egen compu = anycount(value*), values(10)
gen compu_mal = (compu == 0)
label variable compu_mal "No tiene computadora"

egen aire = anycount(value*), values(18)
gen aire_mal = (aire == 0)
label variable aire_mal "No tiene aire acondicionado"


*No tenemos esto, pongo tenencia de computadora.
gen compu_bien = (compu_mal==1)
label variable compu_bien "hogar tiene computadora"

*No tenemos esto, pongo tenencia del hogar.
egen celular = anycount(value*), values(21)
gen celular_bien = (celular >= 1)
label variable celular_bien "hogar tiene celular"

drop value*

gen exterior_bien = (v_04 == "1")
label variable exterior_bien "alguien del hogar vive en el exterior"


**** datos base individuales ****
* No incluian divorciado en el de carlos, separado tampoco. viudo no está como opción
gen civil_mal = inlist(x_10, "1", "3") if x_00==1
label variable civil_mal "Jefe es viudo, soltero o en unión libre"

* LaS de edUcaciON Me GeNeRaN dUdaS, porque no se si se refiere al nivel alcanzado como ultimo nivel o si cuenta si tiene aun mas educación
gen ed_basica_bien = (x_30 == "4")  if x_00==1
label variable ed_basica_bien "Jefe completó educación básica"

* asumo que es el 5
gen ed_comun_bien = (x_30 == "5") if x_00==1
label variable ed_comun_bien "Jefe completó ciclo común"

gen ed_diversif_bien = inlist(x_30, "6", "7", "8")  if x_00==1
label variable ed_diversif_bien "Jefe completó diversificado, técnico superior o superior No universitaria"

gen ed_univer_bien = inlist(x_30, "9", "10")  if x_00==1
label variable ed_univer_bien "Jefe completó educación universitaria"

gen escritura_mal = inlist(viii_02a, "9", "10")
label variable escritura_mal "No tiene escritura de la vivienda"

* No especificaba si era binaria o si contaba a cuantas cosas no tenía derecho, me parece bien contar.

gen Nocomer1_bien = (vii_01=="1")
label variable Nocomer1_bien "No se preocupó por comer en 3 meses"

gen Nocomer2_bien = (vii_02=="1")
label variable Nocomer2_bien "No le faltó dinero para comer en 3 meses"

gen Nocomer3_bien = (vii_03=="1")
label variable Nocomer3_bien "No le faltó variedad al comer en 3 meses"

gen Nocomer4_bien = (vii_04=="1")
label variable Nocomer4_bien "No dejó de comer en 3 meses"

gen Nocomer5_bien = (vii_05=="1")
label variable Nocomer5_bien "No comió menos en 3 meses"

gen Nocomer6_bien = (vii_06=="1")
label variable Nocomer6_bien "No se quedaron sin alimentos en 3 meses"

gen Nocomer7_bien = (vii_07=="1")
label variable Nocomer7_bien "No sintió hambre en 3 meses"

gen Nocomer8_bien = (vii_08=="1")
label variable Nocomer8_bien "No dejó de comer un día entero en 3 meses"

*idem arriba. "¿el hogar tiene acceoso a internet?"
gen internet_bien = (ix_01 == "1") if x_00==1
label variable internet_bien "hogar  tuvo acceso a internet"

gen Trabajo_bien = (x_32 == "2") if x_00==1
label variable Trabajo_bien "Trabajó la semana pasada"

*Recontra proxy esto. No encuentro como mejorarla
gen Ocupacion_bien = inlist(x_33, "1", "2", "3", "4", "5", "7", "8", "10") if x_00==1
label variable Ocupacion_bien "Ocupación: empleado u obrero público, empleados, patrón o socio"

* edad del jefe
destring x_06, gen(edad) force
label variable edad "edad"

gen edad_jefe=edad if x_00==1
gen edad_jefe2 = edad^2 if x_00==1
label variable edad_jefe2 "edad del jefe al cuadrado"

* Genero variables intermedias para la edad
gen temp_edad_0_5 = (edad >= 0 & edad <= 5)
gen temp_edad_6_14 = (edad >= 6 & edad <= 14)
gen temp_edad_15_21 = (edad >= 15 & edad <= 21)
gen temp_edad_22_60 = (edad >= 22 & edad <= 60)
gen temp_edad_60_120 = (edad >60)

* Sumo variable edad por hogar
bysort hogid: gen num_edad_0_5 = sum(temp_edad_0_5)
bysort hogid: gen num_edad_6_14 = sum(temp_edad_6_14)
bysort hogid: gen num_edad_15_21 = sum(temp_edad_15_21)
bysort hogid: gen num_edad_22_60 = sum(temp_edad_22_60)
bysort hogid: gen num_edad_60_120 = sum(temp_edad_60_120)

* Me quedo con el valor máximo
bysort hogid: replace num_edad_0_5 = num_edad_0_5[_N]
bysort hogid: replace num_edad_6_14 = num_edad_6_14[_N]
bysort hogid: replace num_edad_15_21 = num_edad_15_21[_N]
bysort hogid: replace num_edad_22_60 = num_edad_22_60[_N]
bysort hogid: replace num_edad_60_120 = num_edad_60_120[_N]

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

* dropeo variables intermedias
drop num_edad_0_5 num_edad_6_14 num_edad_15_21 num_edad_22_60 num_edad_60_120 temp_edad_0_5 temp_edad_6_14 temp_edad_15_21 temp_edad_22_60 temp_edad_60_120 

destring iii_11, replace force
gen dv111 = iii_11
label variable dv111 "Sin incluir la cocina, el baño y garaje ¿cuántas piezas tiene esta viv"

gen dv112 = tot_piezas
label variable dv112 "del total de piezas de la vivienda, ¿cuántas utilizan para dormir?"

* Miro por hogar cuantas personas trabajan
destring x_32, replace force
bysort hogid: gen trabajo_hogar = sum(x_32 == 2)
bysort hogid: replace trabajo_hogar = trabajo_hogar[_N]
* ahora uso esa variable para el calculo
gen dependencia = (trabajo_hogar/tot_personas)
label variable dependencia "# de miembros trabajando la semana pasada / Tamaño del hogar entre"
drop trabajo_hogar

* Jubilaciones y pensiones
destring v_13*, replace force
foreach var of varlist v_13* {
    replace `var' = . if `var' == 999999998.00 | `var' == 999999999.00
}
egen pensiones = rowtotal(v_13e v_13h)
gen Pension_bien = pensiones>0
label variable Pension_bien "Reciben pensión o jubilación"

* alquileres
* asumo que otros es alquileres porque no hay nada de info
gen alquileres_bien = (v_13i>0)
label variable alquileres_bien "Reciben alquileres"

* Remesas del exterior (cualquier moneda)
gen Remesas_bien = (v_13d>0)
label variable Remesas_bien "Reciben remesas del exterior"

**************************************************
**** estimación del ingreso en función de PMT ****
**************************************************

/* 
estimación del ingreso de los hogares del documento Wb:
- constante: 7.0556
- basura recolectada domicilio Pública, Privada o la deposita en contenedores: 0.1236
- La vivienda que tiene es Propia, Propia pagándola o alquilada: 0.4290
- Nbi_caPS Sin capacidad de subsistencia: -0.6508
- Paredes de ladrillo, piedra o bloque: 0.1013
- alumbrado público: 0.2017
- cocina con gas propano o electricidad: 0.1126
- Sin incluir cocina, baño y garaje ¿# piezas tiene esta vivienda?: 0.0438
- No tiene refrigeradora: -0.1565
- No tiene estufa: -0.0963
- No tiene carro: -0.1373
- No tiene computadora: -0.1725
- No tiene aire acondicionado: -0.1585
- Jefe completó ciclo común: 0.0705
- Jefe completó diversificado, técnico superior o superior no universitaria: 0.1474
- Jefe completó educación universitaria: 0.3999
- Jefe es empleado u obrero público, empleador, patrón o socio: 0.2402
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
sum basura_bien vivienda2_bien Paredes_bien alumbrado_bien cocina2_bien dv111 Refri_mal estufa_mal carro_mal compu_mal aire_mal ed_comun_bien ed_diversif_bien ed_univer_bien Ocupacion_bien dependencia Pension_bien alquileres_bien Remesas_bien edad_0_5 edad_6_14 edad_15_21 edad_60_120 Nocomer1_bien Nocomer8_bien if x_00 == 1

gen log_ingreso_est = 7.0556 + 0.1236 * basura_bien + 0.4290 * vivienda2_bien + 0.1013 * Paredes_bien + 0.2017 * alumbrado_bien + 0.1126 * cocina2_bien + 0.0438 * dv111 - 0.1565 * Refri_mal - 0.0963 * estufa_mal - 0.1373 * carro_mal - 0.1725 * compu_mal - 0.1585 * aire_mal + 0.0705 * ed_comun_bien + 0.1474 * ed_diversif_bien + 0.3999 * ed_univer_bien + 0.2402 * Ocupacion_bien + 0.9922 * dependencia+ 0.3570 * Pension_bien + 0.3503 * alquileres_bien + 0.1530 * Remesas_bien - 0.0712 * edad_0_5 - 0.1111 * edad_6_14 - 0.0415 * edad_15_21 - 0.0193 * edad_60_120 + 0.1747 * Nocomer1_bien + 0.1417 * Nocomer8_bien if x_00 == 1

/* variables que no pudimos incluir: 
- No se preocupó por comer en 3 meses: 0.1747
- No dejó de comer un día entero en 3 meses: 0.1417
*/

* estimamos el ingreso
gen ingreso_est = exp(log_ingreso_est)

sort ingreso_est
* dropeamos las observaciones que no son de jefes de hogar
drop if ingreso_est ==.

* Generamos variable que indica la posición relativa del hogar en la distribución de ingresos
gen pos = _n/_N

* Graficamos ingreso y posición
twoway line pos ingreso_est if ingreso_est<4000

*2834 deja al 50% por debajo del corte

* variable que indica si es pobre segun la estimacion
gen pobre = (ingreso_est<2960)

// ** estas líneas de código nos dan los datos que usamos para gráfico PPT**
// tab pobre QUiNTiLh
// *Separo rural y urbano
//  tab pobre QUiNTiLh if UR==2, col
//  tab pobre QUiNTiLh if UR==1, col
 
save "D:\World Bank\Honduras PMT benchmark\Data_out\basepmt_sirbho.dta", replace

keep level1id numhog ingreso_est

save "D:\World Bank\Honduras PMT benchmark\Data_out\pmt.dta", replace

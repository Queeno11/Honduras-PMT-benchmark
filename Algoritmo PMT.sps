* Encoding: UTF-8.
************************************************
* Estimación de ingresos con PMT 
************************************************

* Este código busca reconstruir el ingreso estimado para las familias en Honduras en función del documento metodológico del WB

* Documento de referencia: "eSTiMaciÓN de iNGReSOS de LOS hOGaReS URbaNOS POR MediO de UNa ReGReSiÓN MULTivaRiada, hONdURaS" carlos e. Sobrado, banco Mundial, 22 de febrero, 2023

GET DATA /TYPE=TXT 
 /FILE='D:\Datasets\Data honduras Red Solidaria\ODS - SIRBHO\ODS3_Hogares.csv'
 /DELCASE=LINE
 /DELIMITERS=";"
 /ARRANGEMENT=DELIMITED
 /FIRSTCASE=2
 /IMPORTCASE=ALL
 /VARIABLES=ALL
 /MAP.
SAVE OUTFILE='hogares.sav'.

GET DATA /TYPE=TXT 
 /FILE='D:\Datasets\Data honduras Red Solidaria\ODS - SIRBHO\OdS3_Poblacion.csv'
 /DELCASE=LINE
 /DELIMITERS=";"
 /ARRANGEMENT=DELIMITED
 /FIRSTCASE=2
 /IMPORTCASE=ALL
 /VARIABLES=ALL
 /MAP.
SAVE OUTFILE='Personas.sav'.

MATCH FILES FILE='Personas.sav' /TABLE='hogares.sav' /BY level1id.
EXECUTE.

SORT CASES BY level1id numhog.
AGGREGATE
  /OUTFILE=* MODE=ADDVARIABLES
  /BREAK=level1id
  /hogid=N.

SORT CASES BY hogid.
IF (x_00=1) x_00=1.
EXECUTE.

*********************************************
* Generar variables para PMT Honduras 
*********************************************

* Sección 1: variables usadas en la regresión inicial

IF (iii_01="5" OR iii_01="6") vivienda_bien=1.
ELSE vivienda_bien=0.
VARIABLE LABELS vivienda_bien 'casa individual o apartamento'.

IF (iii_03="6") Paredes_bien=1.
ELSE Paredes_bien=0.
VARIABLE LABELS Paredes_bien 'Paredes de ladrillo, piedra o bloque'.

IF (iii_05="1" OR iii_05="3" OR iii_05="4") Piso_mal=1.
ELSE Piso_mal=0.
VARIABLE LABELS Piso_mal 'Pisos de Ladrillo de barro, plancha de cemento o de tierra'.

IF (iii_08="1" OR iii_08="2") agua_bien=1.
ELSE agua_bien=0.
VARIABLE LABELS agua_bien 'agua de tubería instalada'.

IF (iii_08="1") agua2_bien=1.
ELSE agua2_bien=0.
VARIABLE LABELS agua2_bien 'agua dentro de la vivienda'.

IF (iii_06="1") alumbrado_bien=1.
ELSE alumbrado_bien=0.
VARIABLE LABELS alumbrado_bien 'alumbrado público'.

IF (v_09="1" OR v_09="2" OR v_09="3") basura_bien=1.
ELSE basura_bien=0.
VARIABLE LABELS basura_bien 'basura la recogen o la pone en contenedores'.

IF (iii_02="1" OR iii_02="2" OR iii_02="3") vivienda2_bien=1.
ELSE vivienda2_bien=0.
VARIABLE LABELS vivienda2_bien 'vivienda alquilada o propietario pagando o pagada'.

COMPUTE tot_personas=NUMBER(v_02c, F8).
VARIABLE LABELS tot_personas 'Total de personas en el hogar'.

RECODE v_01 (CONVERT) INTO tot_piezas.
VARIABLE LABELS tot_piezas 'Total de piezas en la vivienda'.

COMPUTE hacinamiento=tot_personas / tot_piezas.
VARIABLE LABELS hacinamiento 'Personas por dormitorio'.

IF (v_07="1") cocina_bien=1.
ELSE cocina_bien=0.
VARIABLE LABELS cocina_bien 'cocina alimentos en una pieza dedica solo a cocinar'.

IF (v_05="4" OR v_05="5") cocina2_bien=1.
ELSE cocina2_bien=0.
VARIABLE LABELS cocina2_bien 'cocina con gas propano o electricidad'.

IF (v_10="2") estufa_bien=1.
ELSE estufa_bien=0.
VARIABLE LABELS estufa_bien 'cocina en estufa eléctrica'.

IF (iii_10<>"9") haySanitario_bien=1.
ELSE haySanitario_bien=0.
VARIABLE LABELS haySanitario_bien 'Tiene servicio sanitario o letrina'.

IF (iii_10="1") Sanitario_bien=1.
ELSE Sanitario_bien=0.
VARIABLE LABELS Sanitario_bien 'Tiene inodoro conectado a alcantarilla'.

STRING value1 value2 value3 (A10).
RECODE v_10 (CONVERT) INTO value1, value2, value3.

DO IF value1="3" OR value2="3" OR value3="3".
  COMPUTE Refri_mal=0.
ELSE.
  COMPUTE Refri_mal=1.
END IF.
VARIABLE LABELS Refri_mal 'No tiene refrigeradora'.

DO IF value1="1" OR value1="2" OR value2="1" OR value2="2" OR value3="1" OR value3="2".
  COMPUTE estufa_mal=0.
ELSE.
  COMPUTE estufa_mal=1.
END IF.
VARIABLE LABELS estufa_mal 'No tiene estufa'.

DO IF value1="7" OR value2="7" OR value3="7".
  COMPUTE Tv_mal=0.
ELSE.
  COMPUTE Tv_mal=1.
END IF.
VARIABLE LABELS Tv_mal 'No tiene televisor'.

DO IF value1="12" OR value2="12" OR value3="12".
  COMPUTE cable_mal=0.
ELSE.
  COMPUTE cable_mal=1.
END IF.
VARIABLE LABELS cable_mal 'No tiene servicio de cable'.

DO IF value1="15" OR value2="15" OR value3="15".
  COMPUTE Radio_mal=0.
ELSE.
  COMPUTE Radio_mal=1.
END IF.
VARIABLE LABELS Radio_mal 'No tiene radio'.

DO IF value1="9" OR value2="9" OR value3="9".
  COMPUTE eqSonido_mal=0.
ELSE.
  COMPUTE eqSonido_mal=1.
END IF.
VARIABLE LABELS eqSonido_mal 'No tiene equipo de sonido'.

DO IF value1="4" OR value2="4" OR value3="4".
  COMPUTE Telefono_mal=0.
ELSE.
  COMPUTE Telefono_mal=1.
END IF.
VARIABLE LABELS Telefono_mal 'No tiene teléfono fijo'.

DO IF value1="19" OR value2="19" OR value3="19".
  COMPUTE carro_mal=0.
ELSE.
  COMPUTE carro_mal=1.
END IF.
VARIABLE LABELS carro_mal 'No tiene carro'.

DO IF value1="20" OR value2="20" OR value3="20".
  COMPUTE Moto_mal=0.
ELSE.
  COMPUTE Moto_mal=1.
END IF.
VARIABLE LABELS Moto_mal 'No tiene motocicleta'.

DO IF value1="17" OR value2="17" OR value3="17".
  COMPUTE bici_mal=0.
ELSE.
  COMPUTE bici_mal=1.
END IF.
VARIABLE LABELS bici_mal 'No tiene bicicleta'.

DO IF value1="10" OR value2="10" OR value3="10".
  COMPUTE compu_mal=0.
ELSE.
  COMPUTE compu_mal=1.
END IF.
VARIABLE LABELS compu_mal 'No tiene computadora'.

DO IF value1="18" OR value2="18" OR value3="18".
  COMPUTE aire_mal=0.
ELSE.
  COMPUTE aire_mal=1.
END IF.
VARIABLE LABELS aire_mal 'No tiene aire acondicionado'.

COMPUTE compu_bien=compu_mal=1.
VARIABLE LABELS compu_bien 'Hogar tiene computadora'.

DO IF value1="21" OR value2="21" OR value3="21".
  COMPUTE celular_bien=1.
ELSE.
  COMPUTE celular_bien=0.
END IF.
VARIABLE LABELS celular_bien 'Hogar tiene celular'.

EXECUTE.

IF (v_04="1") exterior_bien=1.
ELSE exterior_bien=0.
VARIABLE LABELS exterior_bien 'Alguien del hogar vive en el exterior'.

IF (x_10="1" OR x_10="3" AND x_00=1) civil_mal=1.
ELSE civil_mal=0.
VARIABLE LABELS civil_mal 'Jefe es viudo, soltero o en unión libre'.

IF (x_30="4" AND x_00=1) ed_basica_bien=1.
ELSE ed_basica_bien=0.
VARIABLE LABELS ed_basica_bien 'Jefe completó educación básica'.

IF (x_30="5" AND x_00=1) ed_comun_bien=1.
ELSE ed_comun_bien=0.
VARIABLE LABELS ed_comun_bien 'Jefe completó ciclo común'.

IF (x_30="6" OR x_30="7" OR x_30="8" AND x_00=1) ed_diversif_bien=1.
ELSE ed_diversif_bien=0.
VARIABLE LABELS ed_diversif_bien 'Jefe completó diversificado, técnico superior o superior no universitaria'.

IF (x_30="9" OR x_30="10" AND x_00=1) ed_univer_bien=1.
ELSE ed_univer_bien=0.
VARIABLE LABELS ed_univer_bien 'Jefe completó educación universitaria'.

IF (viii_02a="9" OR viii_02a="10") escritura_mal=1.
ELSE escritura_mal=0.
VARIABLE LABELS escritura_mal 'No tiene escritura de la vivienda'.

IF (vii_01="1") Nocomer1_bien=1.
ELSE Nocomer1_bien=0.
VARIABLE LABELS Nocomer1_bien 'No se preocupó por comer en 3 meses'.

IF (vii_02="1") Nocomer2_bien=1.
ELSE Nocomer2_bien=0.
VARIABLE LABELS Nocomer2_bien 'No le faltó dinero para comer en 3 meses'.

IF (vii_03="1") Nocomer3_bien=1.
ELSE Nocomer3_bien=0.
VARIABLE LABELS Nocomer3_bien 'No le faltó variedad al comer en 3 meses'.

IF (vii_04="1") Nocomer4_bien=1.
ELSE Nocomer4_bien=0.
VARIABLE LABELS Nocomer4_bien 'No dejó de comer en 3 meses'.

IF (vii_05="1") Nocomer5_bien=1.
ELSE Nocomer5_bien=0.
VARIABLE LABELS Nocomer5_bien 'No comió menos en 3 meses'.

IF (vii_06="1") Nocomer6_bien=1.
ELSE Nocomer6_bien=0.
VARIABLE LABELS Nocomer6_bien 'No se quedaron sin alimentos en 3 meses'.

IF (vii_07="1") Nocomer7_bien=1.
ELSE Nocomer7_bien=0.
VARIABLE LABELS Nocomer7_bien 'No sintió hambre en 3 meses'.

IF (vii_08="1") Nocomer8_bien=1.
ELSE Nocomer8_bien=0.
VARIABLE LABELS Nocomer8_bien 'No dejó de comer un día entero en 3 meses'.

IF (ix_01="1" AND x_00=1) internet_bien=1.
ELSE internet_bien=0.
VARIABLE LABELS internet_bien 'Hogar tuvo acceso a internet'.

IF (x_32="2" AND x_00=1) Trabajo_bien=1.
ELSE Trabajo_bien=0.
VARIABLE LABELS Trabajo_bien 'Trabajó la semana pasada'.

IF (x_33="1" OR x_33="2" OR x_33="3" OR x_33="4" OR x_33="5" OR x_33="7" OR x_33="8" OR x_33="10" AND x_00=1) Ocupacion_bien=1.
ELSE Ocupacion_bien=0.
VARIABLE LABELS Ocupacion_bien 'Ocupación: empleado u obrero público, empleados, patrón o socio'.

COMPUTE edad=NUMBER(x_06, F8).
VARIABLE LABELS edad 'edad'.

IF (x_00=1) edad_jefe=edad.
COMPUTE edad_jefe2=edad_jefe**2.
VARIABLE LABELS edad_jefe2 'edad del jefe al cuadrado'.

IF (edad >= 0 AND edad <= 5) temp_edad_0_5=1.
ELSE temp_edad_0_5=0.

IF (edad >= 6 AND edad <= 14) temp_edad_6_14=1.
ELSE temp_edad_6_14=0.

IF (edad >= 15 AND edad <= 21) temp_edad_15_21=1.
ELSE temp_edad_15_21=0.

IF (edad >= 22 AND edad <= 60) temp_edad_22_60=1.
ELSE temp_edad_22_60=0.

IF (edad > 60) temp_edad_60_120=1.
ELSE temp_edad_60_120=0.

AGGREGATE
  /OUTFILE=* MODE=ADDVARIABLES
  /BREAK=hogid
  /num_edad_0_5=SUM(temp_edad_0_5)
  /num_edad_6_14=SUM(temp_edad_6_14)
  /num_edad_15_21=SUM(temp_edad_15_21)
  /num_edad_22_60=SUM(temp_edad_22_60)
  /num_edad_60_120=SUM(temp_edad_60_120).

IF (num_edad_0_5=_N) num_edad_0_5=num_edad_0_5.
IF (num_edad_6_14=_N) num_edad_6_14=num_edad_6_14.
IF (num_edad_15_21=_N) num_edad_15_21=num_edad_15_21.
IF (num_edad_22_60=_N) num_edad_22_60=num_edad_22_60.
IF (num_edad_60_120=_N) num_edad_60_120=num_edad_60_120.

RECODE num_edad_0_5 (COPY) INTO edad_0_5.
VARIABLE LABELS edad_0_5 '# de personas de 0 a 5'.

RECODE num_edad_6_14 (COPY) INTO edad_6_14.
VARIABLE LABELS edad_6_14 '# de personas de 6 a 14'.

RECODE num_edad_15_21 (COPY) INTO edad_15_21.
VARIABLE LABELS edad_15_21 '# de personas de 15 a 21'.

RECODE num_edad_22_60 (COPY) INTO edad_22_60.
VARIABLE LABELS edad_22_60 '# de personas de 22 a 60'.

RECODE num_edad_60_120 (COPY) INTO edad_60_120.
VARIABLE LABELS edad_60_120 '# de personas de más de 60'.

DELETE VARIABLES num_edad_0_5 num_edad_6_14 num_edad_15_21 num_edad_22_60 num_edad_60_120 temp_edad_0_5 temp_edad_6_14 temp_edad_15_21 temp_edad_22_60 temp_edad_60_120.

COMPUTE dv111=NUMBER(iii_11, F8).
VARIABLE LABELS dv111 'Sin incluir la cocina, el baño y garaje ¿cuántas piezas tiene esta viv'.

COMPUTE dv112=tot_piezas.
VARIABLE LABELS dv112 'del total de piezas de la vivienda, ¿cuántas utilizan para dormir?'.

AGGREGATE
  /OUTFILE=* MODE=ADDVARIABLES
  /BREAK=hogid
  /trabajo_hogar=SUM(x_32 = 2).
COMPUTE dependencia=trabajo_hogar/tot_personas.
VARIABLE LABELS dependencia '# de miembros trabajando la semana pasada / Tamaño del hogar entre'.
DELETE VARIABLES trabajo_hogar.

COMPUTE pensiones=SUM(v_13e, v_13h).
IF (pensiones>0) Pension_bien=1.
ELSE Pension_bien=0.
VARIABLE LABELS Pension_bien 'Reciben pensión o jubilación'.

IF (v_13i>0) alquileres_bien=1.
ELSE alquileres_bien=0.
VARIABLE LABELS alquileres_bien 'Reciben alquileres'.

IF (v_13d>0) Remesas_bien=1.
ELSE Remesas_bien=0.
VARIABLE LABELS Remesas_bien 'Reciben remesas del exterior'.

**************************************************
* Estimación del ingreso en función de PMT 
**************************************************

COMPUTE log_ingreso_est = 7.0556 + 0.1236 * basura_bien + 0.4290 * vivienda2_bien + 0.1013 * Paredes_bien + 0.2017 * alumbrado_bien + 0.1126 * cocina2_bien + 0.0438 * dv111 - 0.1565 * Refri_mal - 0.0963 * estufa_mal - 0.1373 * carro_mal - 0.1725 * compu_mal - 0.1585 * aire_mal + 0.0705 * ed_comun_bien + 0.1474 * ed_diversif_bien + 0.3999 * ed_univer_bien + 0.2402 * Ocupacion_bien + 0.9922 * dependencia + 0.3570 * Pension_bien + 0.3503 * alquileres_bien + 0.1530 * Remesas_bien - 0.0712 * edad_0_5 - 0.1111 * edad_6_14 - 0.0415 * edad_15_21 - 0.0193 * edad_60_120 + 0.1747 * Nocomer1_bien + 0.1417 * Nocomer8_bien.
COMPUTE ingreso_est=EXP(log_ingreso_est).

SORT CASES BY ingreso_est (A).
DELETE VARIABLES IF (x_00==0).

COMPUTE pos=RANK(ingreso_est)/RANK(ALL).
GRAPH /LINE=LINE(pos BY ingreso_est) /MISSING=INCLUDE /DISPLAY=REFERENCE.

IF (ingreso_est < 2960) pobre=1.
ELSE pobre=0.
SAVE OUTFILE='D:\World Bank\Honduras PMT benchmark\basepmt_sirbho.sav'.

SELECT IF (x_00=1).
SAVE OUTFILE='D:\World Bank\Honduras PMT benchmark\pmt.sav'.


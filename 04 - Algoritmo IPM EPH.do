import spss "D:\Datasets\EPH-PM Honduras\Encuesta de Hogares junio 2023\Data de la Encuesta de Hogares junio 2023.sav", clear


drop if QUINTILH==6

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
egen privacion_agua_h = max(privacion_agua), by(ID)

*#######* SANEAMIENTO

* En la zona urbana el servicio sanitario no es un inodoro conectado a
* alcantarillado o a pozo séptico (inlist(H07, 1, 2)).
gen privacion_saneamiento = .
replace privacion_saneamiento = !(inlist(H07, 1, 2)) if UR==1 & !mi(H07)

* En la zona rural el sistema de saneamiento no es un inodoro conectado
* a alcantarilla o a pozo séptico, o no es una letrina con cierre hidráulico
* o pozo séptico (inlist(H07, 1, 2, 5, 6)).
replace privacion_saneamiento = !(inlist(H07, 1, 2, 5, 6)) if UR==2 & !mi(H07)
egen privacion_saneamiento_h = max(privacion_saneamiento), by(ID)


*#######* COCINA

* El combustible para cocinar es leña
gen privacion_cocina = (H04 == 1) if !mi(H04)
egen privacion_cocina_h = max(privacion_cocina), by(ID)


*###################################
*######*     EDUCACION    ##########
*###################################

*#######* Años de escolaridad
* El Hogar es privado cuando al menos 1 miembro entre 15 y 49
* años (inrange(EDAD, 15, 49)) tiene 6 años o menos de escolaridad (ANOSEST<6).
gen privacion_educ = (inrange(EDAD, 15, 49) & ANOSEST<6) if !mi(EDAD, ANOSEST)
egen privacion_educ_h = max(privacion_educ), by(ID)


*#######* Asistencia escolar 
* Al menos un miembro del hogar entre 3 y 14 años (inrange(EDAD, 3, 14) no asiste a la
* escuela ( ED03==2).
gen privacion_asistencia = (inrange(EDAD, 3, 14) & ED03==2) if !mi(EDAD, ED03)
egen privacion_asistencia_h = max(privacion_asistencia), by(ID)


*#######* Analfabetismo
* Al menos un miembro del hogar mayor de 15 años no sabe leer y
* escribir.
gen privacion_alfab = (EDAD>15 & ED01==2) if !mi(EDAD, ED01)
egen privacion_alfab_h = max(privacion_alfab), by(ID)

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
egen privacion_segsoc_h = max(privacion_segsoc), by(ID)

* Son privados todos los hogares donde al menos 1 de sus
* miembros en edad productiva es desocupado
gen privacion_desocup = (CONDACT==2 & inrange(EDAD, 14, 65))
egen privacion_desocup_h = max(privacion_desocup), by(ID)


*#######* Sub-empleo 

* Al menos una persona ocupada del hogar que trabaja 40 horas por
* semana gana menos de un salario mínimo.
gen privacion_subemp = (horas>40 & YTAB<SALMIN) if !mi(horas, YTAB, SALMIN)
egen privacion_subemp_h = max(privacion_subemp), by(ID)

* todos los miembros del hogar en edad productiva SON desocupados (CONDACT==2),
* excepto que se trate de personas en condición de inactividad (CONDACT==3).
gen privacion_ocup = (CONDACT==2 | CONDACT==3)
egen q_no_ocup = total(privacion_ocup), by(ID)
gen privacion_ocup_h = (q_no_ocup / TOTPER == 1)

*#######* Trabajo infantil

* Existe al menos un niño de 5 a 13 años de edad que trabaja.
gen privacion_trabinf = (inrange(EDAD, 5, 13) & CA501==1) if !mi(EDAD, CA501)
egen privacion_trabinf_h = max(privacion_trabinf), by(ID)

* Existe al menos un niño de 14 o 15 años de edad que trabaja más
* de 20 horas por semana y no estudia.
gen privacion_trabadol1 = (inrange(EDAD, 14, 15) & horas>20 & ED03==2) if !mi(EDAD, ED03, horas)
egen privacion_trabadol1_h = max(privacion_trabadol1), by(ID)

* Existe al menos un niño de 16 o 17 años de edad que trabaja más
* de 30 horas por semana y no estudia.
gen privacion_trabadol2 = (inrange(EDAD, 16, 17) & horas>30 & ED03==2) if !mi(EDAD, ED03, horas)
egen privacion_trabadol2_h = max(privacion_trabadol2), by(ID)


*###################################
*######*     VIVIENDA     ##########
*###################################

*######* Acceso a electricidad
* No tiene acceso a electricidad por servicio público, servicio
* privado colectivo, plata propia o energía solar (inlist(V007, 1, 2, 3, 4))
gen privacion_elec = (!inlist(V07, 1, 2, 3, 4)) if !mi(V07)
egen privacion_elec_h = max(privacion_elec), by(ID)

*######*  Material Pisos
* La vivienda tiene pisos de tierra u otro material
gen privacion_piso = (V03 == 7) if !mi(V03)
egen privacion_piso_h = max(privacion_piso), by(ID)

*######*  Material techos
* La vivienda tiene techo de Paja, palma o similar o material de
* desecho u otro
gen privacion_techo = (inlist(V04, 7, 8)) if !mi(V04)
egen privacion_techo_h = max(privacion_techo), by(ID)


*######*  Material Paredes
* La vivienda tiene pared de Bahareque, vara o caña o material de
* desecho
gen privacion_pared = (inlist(V02, 6, 7)) if !mi(V02)
egen privacion_pared_h = max(privacion_pared), by(ID)

*######*  Hacinamiento
* La vivienda tiene 3 personas (TOTPER) o más por cuarto, excluyendo cocina,
* baño y garaje (V09)
gen personas_por_cuartos = TOTPER / V09
gen privacion_hacina = (personas_por_cuartos>=3)
egen privacion_hacina_h = max(privacion_hacina), by(ID)

egen hogar = tag(ID)
keep if hogar==1

gen indice_pobreza_multi = 1/12 * privacion_agua_h +  1/12 * privacion_saneamiento_h + 1/12 * privacion_cocina_h + 1/12 *  privacion_educ_h + 1/12 * privacion_asistencia_h + 1/12 * privacion_alfab_h + 1/24 * privacion_segsoc_h + 1/24 * privacion_desocup_h + 1/24 * privacion_subemp_h + 1/24 * privacion_ocup_h + 1/36 * privacion_trabinf_h + 1/36 * privacion_trabadol1_h + 1/36 * privacion_trabadol2_h + 1/24 * privacion_elec_h + 1/24 * privacion_piso_h + 1/24 * privacion_techo_h + 1/24 * privacion_pared_h + 1/24 * privacion_hacina_h

drop if indice_pobreza_multi == .
gen pobreza_multidim = (indice_pobreza_multi>=0.25)
gen no_pob_multidim = 1 - pobreza_multidim

gen pobreza = inlist(POBREZA, 1, 2)
gen no_pobreza = 1-pobreza
gen pobreza_ext = inlist(POBREZA, 1)
gen no_pobreza_ext = 1-pobreza_ext

save data_indice_multidimensional, replace


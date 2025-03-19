* Encoding: UTF-8.
GET STATA FILE='D:\World Bank\Honduras PMT benchmark\Data_out\Personas_clean.dts'.
FILE LABEL .

Compute Ped1=(range(X_06,15,49) and X_30*10+X_31<46). /*Escolaridad.
Compute Ped2=(range(X_06,3,14) and X_29=2). /*Asistencia.
Compute Ped3=(X_06>15 and X_28=2). /*Analfabetismo.

Compute Ptr1=range(X_06,18,65) and  
                        ((X_32=2 and sum(CHAR.INDEX(X_55,"01")>0, CHAR.INDEX(X_55,"02")>0, CHAR.INDEX(X_55,"03")>0, CHAR.INDEX(X_55,"04")>0, CHAR.INDEX(X_55,"05")>0, CHAR.INDEX(X_55,"06")>0, 
                                                   CHAR.INDEX(X_55,"07")>0, CHAR.INDEX(X_55,"08")>0, CHAR.INDEX(X_55,"09")>0)=0) 
                        or X_32=1).
Compute Ptr2=X_37>=40 and X_37<4.  /*Desempleo.
Compute Ptr2n=range(X_06,18,65) and X_32=1.
Compute Ptr2d=range(X_06,18,65).
Compute Ptr3=((range(X_06,5,13) and X_32=2) or (range(X_06,14,15) and X_37>=20) or (range(X_06,16,17) and X_37>=30)).   /*TrabInf.
Compute Pm18=X_06<18.
Execute.

AGGREGATE  /OUTFILE='D:\World Bank\Honduras PMT benchmark\Indper.sav'   /BREAK=level1id
                      /Ped1=MAX(Ped1) /Ped2=MAX(Ped2) /Ped3=MAX(Ped3) /Ptr1=MAX(Ptr1) /Ptr2=MAX(Ptr2) /Ptr2n=Sum(Ptr2n) /Ptr2d=Sum(Ptr2d) /Ptr3=MAX(Ptr3) /Pm18=Max(Pm18) /SexoJefe=First(X_11).


GET STATA FILE='D:\World Bank\Honduras PMT benchmark\Data_out\Hogares_clean.dts'.
FILE LABEL .

SORT CASES by level1id.
MATCH FILES /FILE=*  /TABLE='D:\World Bank\Honduras PMT benchmark\Indper.sav'   /BY level1id.
EXECUTE.
RECODE   Ped1 Ped2 Ped3 Ptr1 Ptr2 Ptr2n Ptr2d Ptr3 Pm18 SexoJefe (SYSMIS=0).
USE ALL.
FILTER BY III_07.
EXECUTE.

*CALCULO DEL INDICE DE POBREZA MULTIDIMIMENCIONAL.
*salud.
Compute sa1=(III_08>2 ). /*Agua.
If III_08b=2 sa1=1.
Compute sa2=any(III_10,4,7,9,10). /*saneamiento.
Compute sa3=(V_05=1). /*combustible.
*Educacion.
Compute ed1=(Ped1=1). /*Escolaridad.
Compute ed2=(Ped2=1). /*Asistencia.
Compute ed3=(Ped3=1). /*Analfabetismo.
*Empleo.
Compute Tr1=(Ptr1=1). /*Seguridad.
Compute Tr2=(Ptr2=1 or (Ptr2n=Ptr2d)). /*Desempleo.
Compute Tr3=(Ptr3=1). /*Infantil.
*Vivienda.
Compute Vi1=(any(III_06,2,3,4,7,8,9)).  /*Electricidad.
Compute Vi2=(any(III_05,1,10)).  /*Pisos.
Compute Vi3=(any(III_04,1,2,12)).  /*Techo.
Compute Vi4=(any(III_03,1,2,10)).  /*Pared.
IF V_01>0  Vi5=((Tot_per/V_01)>=3). /*Hacinamiento.
Compute Vi6=(sum( CHAR.INDEX(V_10,"15")>0, CHAR.INDEX(V_10,"07")>0, CHAR.INDEX(V_10,"15")>0, CHAR.INDEX(V_10,"01")>0, CHAR.INDEX(V_10,"02")>0, CHAR.INDEX(V_10,"17")>0,
                                CHAR.INDEX(V_10,"20")>0, CHAR.INDEX(V_10,"03")>0, CHAR.INDEX(V_10,"19")>0 )<3). /*Bienes.

RECODE  sa1 sa2 sa3 ed1 ed2 ed3 Tr1 Tr2 Tr3 Vi1 Vi2 Vi3 Vi4 Vi5 Vi6 (SYSMIS=0).
Execute.
Compute Salud=Sum(sa1*(1/3),sa2*(1/3),sa3*(1/3)).
Compute Educa=Sum(ed1*(1/3),ed2*(1/3),ed3*(1/3)).
Compute Trabaj=Sum(Tr1*(1/3),Tr2*(1/3),Tr3*(1/3)).
Compute Vivien=Sum(Vi1*(1/6),Vi2*(1/6),Vi3*(1/6),Vi4*(1/6),Vi5*(1/6),Vi6*(1/6)).
EXECUTE.
Compute SumIPM=Sum(Salud*(1/4),Educa*(1/4),Trabaj*(1/4),Vivien*(1/4)).
VARIABLE LABELS  SumIPM "suma ponderada del valor de sus indicadores" .

Recode SumIPM (LO THRU 0.25 =3)(LO THRU 0.50=2)(LO THRU HI=1) INTO IPM.
EXECUTE.

***  Pobreza por Ingreso*****

MISSING VALUES V_13A V_13B V_13C V_13D V_13E V_13F V_13G V_13H V_13I (999999998,999999999).
COMPUTE Ytothog=sum(V_13A, V_13B, V_13C, V_13D, V_13E, V_13F, V_13G, V_13H, V_13I).
IF Tot_per>0 Yperhg=Ytothog/Tot_per.
RECODE Yperhg (LO THRU 1656.1=1)(LO THRU 2210.9=2)(LO THRU HI=3) into IPMO.

***  Pobreza por gasto*****.
RECODE V_14A V_14B V_14C V_14D V_14E V_14F V_14G V_14H V_14I (999999.00=99999999.00)(999999999.00=99999999.00)(9999999998.00=999999998.00)(ELSE = COPY).
MISSING VALUES V_14A V_14B V_14C V_14D V_14E V_14F V_14G V_14H V_14I (999999998.00, 99999999.00).
COMPUTE Gtothog=sum(V_14A, V_14B, V_14C, V_14D, V_14E, V_14F, V_14G, V_14H, V_14I).
If Tot_per>0 Gperhg=Gtothog/Tot_per.
RECODE Gperhg (LO THRU 1656.1=1)(LO THRU 2210.9=2)(LO THRU HI=3) into IPG.
VARIABLE LABELS Ipm "Indice de Pobreza Multidimencional" IPMO "Indice de Pobreza Monetaria" IPG "Indice de pobreza por el Gasto".
VALUE LABELS IPMO IPG 1"Pobreza Extrema" 2"Pobreza Relativa" 3"No Pobres".
VALUE LABELS IPM 1"Pobreza Severa" 2"Pobreza Moderada" 3"No Pobres".
EXECUTE.

SAVE TRANSLATE OUTFILE='D:\World Bank\Honduras PMT benchmark\Data_out\IndicePobrezaMultidimensional.dta'
  /TYPE=STATA
  /VERSION=14.


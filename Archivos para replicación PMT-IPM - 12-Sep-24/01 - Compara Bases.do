*##########################################################
*#####         Script para Comparar Bases             #####
*##########################################################

* Compara dos bases de datos con diferencias pequeñas, por ejemplo, extracciones distintas de un
* mismo SQL. Compara las siguientes cosas:
*	1) Nombres de variables entre ambas bases
*	2) Cantidad de observaciones entre ambas bases
*	3) Si las variables coinciden, compara las observaciones de las dos bases y reporta diferencias.
* Nota: si hay diferencias 

* Requerimientos: instalar el siguiente paquete. Correr una sola vez!
// ssc install cfout

* Definir la ruta y verificar nombres de ids
global DATA_PERSONAS_new = "D:\Datasets\Data Honduras Red Solidaria\ODS - SIRBHO\ODS3_Poblacion.csv"
global DATA_PERSONAS_old = "D:\World Bank\Honduras PMT benchmark\Data_in\Personas.dta"
global DATA_HOGARES_new = "D:\Datasets\Data Honduras Red Solidaria\ODS - SIRBHO\ODS3_Hogares.csv"
global DATA_HOGARES_old = "D:\World Bank\Honduras PMT benchmark\Data_in\Hogares.dta"
global OUTPUTS = "D:\World Bank\Honduras PMT benchmark\Para IT Honduras\Outputs"

global ID_PERSONAS = "level1id x_00"
global ID_HOGARES = "level1id"


foreach global in "DATA_PERSONAS_new" "DATA_PERSONAS_old" "DATA_HOGARES_new" "DATA_HOGARES_old" {

	local original_file = "$`global'"
	local ext = substr("`original_file '", strrpos("`original_file '", "."), .)
	
	* Chequea si la extension es dta, csv, or sav
	if "`ext'" == ".dta" {
		display "File is a Stata dataset (.dta)"
	}
	* Si es csv (o sav) importa el archivo original y guarda en dta. Actualiza la global para que apunte al dta en vez del archivo original.
	else if "`ext'" == ".csv" {
		display "File is a CSV file (.csv)"
		local dta_file = substr("`original_file '", 1, strrpos("`original_file '", ".")-1) + "_stata.dta"
		global `global' = "`dta_file'" 
		
		import delimited "`original_file'", delimiter(";") clear stripquotes(yes) 
		save "$`global'", replace
	}
	else if "`ext'" == ".sav" {
		display "File is an SPSS file (.sav)"
		local dta_file = substr("`original_file '", 1, strrpos("`original_file '", ".")-1) + "_stata.dta"
		global `global' = "`dta_file'" 
		
		import delimited "`original_file'", clear
		save "$`global'", replace
	}
	else {
		display "File has an unknown extension. Verify data selection."
		error
	}

}


*** 1) Variables
cfvars "$DATA_HOGARES_old" "$DATA_HOGARES_new"
local hay_vars_diffs_HOGARES = r(same)
local vars_compartidas_HOGARES = r(both)

cfvars "$DATA_PERSONAS_old" "$DATA_PERSONAS_new"
local hay_vars_diffs_PERSONAS = r(same)
local vars_compartidas_PERSONAS = r(both)


*** 2) Cantidad de observaciones
qui{
	foreach unidades in "HOGARES" "PERSONAS" {
		use "${DATA_`unidades'_new}", replace
 		count
		local obs_new = r(N)
		
		use "${DATA_`unidades'_old}", replace
 		count
		local obs_old = r(N)
		local diff = `obs_new' - `obs_old'
		
		noi display "****************************************"
		noi display "**********    `unidades'     ***********"
		noi display "****************************************"

		if `diff'>0 {
			noi display "Las dos bases tienen la misma cantidad de observaciones!"
		}
		else {
			noi display "***   Número de observaciones en `unidades' base OLD: `obs_old'"
			noi display "***   Número de observaciones en `unidades' base NEW: `obs_new'"
			noi display "***   Número de nuevas observaciones `unidades' base NEW: `obs_new'"
		}
	}
}


*** 3) Diferencias entre observaciones
* Asegurar que no haya duplicados por ID_PERSONAS 
foreach unidades in "HOGARES" "PERSONAS" {
	display "Verificando que no haya duplicados por ID_`unidades'  ($ID_`unidades')..."
	qui {
		use "${DATA_`unidades'_new}", clear
		duplicates report ${ID_`unidades'}
		capture assert r(unique_value)==r(N)
		if (_rc) {
			noi display as error "Hay duplicados por ID_`unidades' ($ID_`unidades')... Verificar base!"
			error
		}
		else {
			noi display "Todo ok!"
		}
	}

	* Si tiene diferencias en algunas de las columnas, mantener solo las cols que comparten
	if r(same)!=1 {
		keep r(both)
	}

	cfout * using "${DATA_`unidades'_old}", id(${ID_`unidades'}) lower nopunct dropdiff saving("$OUTPUTS\diferencias_`unidades'", replace)
}
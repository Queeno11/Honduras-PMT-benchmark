*------------------------------------------------------------------------------*
*					 RUN ALL - SCRIPT for FULL PROCESSING					   
*------------------------------------------------------------------------------*
cls
set more off

*----------------------------------Globals---------------------------------*
global PATH = "D:\World Bank\Honduras PMT benchmark"
global DATA_OUT = "$PATH\Data_out"
global OUTPUTS = "$PATH\Outputs"
global EPHPM_PATH = "D:\Datasets\EPH-PM Honduras\Consolidada 2023\CONSOLIDADA_2023.sav" 

*-------------------------------Create Folders-------------------------------*
foreach path in "$DATA_OUT" "$OUTPUTS" {
    display "`path'"
    capture local list: dir "`path'" dir "*" // Finds all (*) dirs matching the local path
    display _rc
    if _rc!=0 shell mkdir "`path'"
}

*----------------------------------Scripts---------------------------------*

** 01 - Limpia base
do "$PATH\Scripts\01 - Limpia base.do"

** 02 - Estima modelos en STATA
do "$PATH\Scripts\02 - Modelos lineales y Lasso.do"

** 03 - Estima modelo XGBoost (correr desde Python)
/* do "$root\03_clean_metadata" */

** 06 - Genera bases con simulaciones de errores de inclusion y exclusion
/* do "$PATH\Scripts\06 - Analisis EPH inclusion y exclusion.do" */

** 07 - Simulación en el impacto en pobreza
do "$PATH\Scripts\07 - Simulación EPH pobreza.do"

** 08 - Simulación en la redistribucion por deciles
do "$PATH\Scripts\08 - Quintiles EPH.do"

** 09 - Parte de los gráficos del doc
do "$PATH\Scripts\09 - Gráficos.do"

display "Done!"
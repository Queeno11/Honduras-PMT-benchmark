*** Grafico de comparacion de medidas de pobreza***

use "C:\Users\pilih\Documents\World Bank\Honduras\Replication PMT IPM\2. Data\Data_out\CONSOLIDADA_2023_clean.dta"

** Pobreza
* Nacional
mean pobreza [pw = FACTOR_P]
* Urbana
mean pobreza [pw = FACTOR_P] if UR==1
*  Rural
mean pobreza [pw = FACTOR_P] if UR==2


** Pobreza extrema
* Nacional
mean pobreza_ext [pw = FACTOR_P]
* Urbana
mean pobreza_ext [pw = FACTOR_P] if UR==1
*  Rural
mean pobreza_ext [pw = FACTOR_P] if UR==2


* Pobreza multidimensional
* Nacional
mean pobreza_multidim [pw = FACTOR_P]
* Urbana
mean pobreza_multidim [pw = FACTOR_P] if UR==1
*  Rural
mean pobreza_multidim [pw = FACTOR_P] if UR==2
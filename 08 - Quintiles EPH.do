clear all

use "Data_out/basepmt_eph.dta", replace
gen pobreza = inlist(POBREZA, 1, 2)
gen no_pobreza = 1 - pobreza
gen pobreza_ext = inlist(POBREZA, 1)
gen no_pobreza_ext = 1 - pobreza_ext
drop pos
drop if ingreso_est == .
	
merge 1:1 HOGAR NPER using "Data_out/data_indice_multidimensional_consolidada.dta", keep(3)
drop if indice_pobreza_multi == .

gsort -indice_pobreza_multi
gen pos_IPM = _n / _N

gsort ingreso_est
gen pos_PMT = _n / _N

gsort YPERHG
gen pos_YPERHG = _n / _N

gen PMT_d = ceil(pos_PMT*10)
gen PMT_q = ceil(pos_PMT*5)	
gen IPM_d = ceil(pos_IPM*10)
gen IPM_q = ceil(pos_IPM*5)
gen decil_ingreso = ceil(pos_YPERHG*10)
gen quintil_ingreso = ceil(pos_YPERHG*5)


gen pobre_IPM = (indice_pobreza_multi>=0.25)
qui sum pobre_IPM
gen pobre_PMT = (pos_PMT<=r(mean))

sum pobre_PMT pobre_IPM


preserve
collapse (mean) pobre_PMT pobre_IPM, by(decil_ingreso)
gen no_pobre_PMT = 1 - pobre_PMT
gen no_pobre_IPM = 1 - pobre_IPM
export excel using "Outputs/targeting_deciles.xlsx", replace firstrow(variables)
restore

preserve
keep if UR==1
collapse (mean) pobre_PMT pobre_IPM, by(decil_ingreso)
gen no_pobre_PMT = 1 - pobre_PMT
gen no_pobre_IPM = 1 - pobre_IPM
export excel using "Outputs/targeting_deciles_urbano.xlsx", replace firstrow(variables)
restore

preserve
keep if UR==2
collapse (mean) pobre_PMT pobre_IPM, by(decil_ingreso)
gen no_pobre_PMT = 1 - pobre_PMT
gen no_pobre_IPM = 1 - pobre_IPM
export excel using "Outputs/targeting_deciles_rural.xlsx", replace firstrow(variables)

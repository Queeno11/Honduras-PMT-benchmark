cd "D:\World Bank\Honduras PMT benchmark"

set scheme s1color
use "Data_out\IndicePobrezaMultidimensional", replace

merge 1:1 level1id using "Data_out\pmt.dta", keep(3)

*** PMT
* Ranking PMT
sort ingreso_est
gen ln_ingreso_est = ln(ingreso_est)
gen ranking_PMT = _n/_N

* Deciles
gen decil_PMT = ceil(ranking_PMT * 10)
gen quintil_PMT = ceil(ranking_PMT * 5)


*** MPI
* Ranking MPI
gsort -SumIPM
gen ranking_IPM = _n/_N

* Deciles
gen decil_IPM = ceil(ranking_IPM * 10)
gen quintil_IPM = ceil(ranking_IPM * 5)


// scatter ranking_IPM ranking_PMT
// heatplot ranking_IPM ranking_PMT


*** Gasto
gen ln_gasto = ln(Gperhg)

* Ranking PMT
gen has_expenditure = (Gperhg>0 & Gperhg!=.)
sort has_expenditure Gperhg
by has_expenditure: gen ranking_GPC = _n/_N if Gperhg!=0
replace ranking_GPC = . if has_expenditure==0

* Deciles
gen decil_GPC = ceil(ranking_GPC * 10)
gen quintil_GPC = ceil(ranking_GPC * 5)

*** Ingreso
gen ln_ingreso = ln(Yperhg)

* Ranking PMT
gen has_income = (Yperhg>0 & Yperhg!=.)
sort has_income Yperhg
by has_income: gen ranking_YPC = _n/_N if Yperhg!=0
replace ranking_YPC = . if has_income==0

* Deciles
gen decil_YPC = ceil(ranking_YPC * 10)
gen quintil_YPC = ceil(ranking_YPC * 5)

correlate ranking_IPM ranking_PMT ranking_GPC ranking_YPC

heatplot decil_IPM decil_PMT, bins(10)
capture graph drop a b c d
heatplot decil_IPM decil_GPC, bins(10) name(a) cuts(0 .25 .5 .75 1 1.25 1.5 1.75 2 2.25 2.5)
heatplot decil_IPM decil_YPC, bins(10) name(b) cuts(0 .25 .5 .75 1 1.25 1.5 1.75 2 2.25 2.5)
heatplot decil_PMT decil_GPC, bins(10) name(c) cuts(0 .25 .5 .75 1 1.25 1.5 1.75 2 2.25 2.5)
heatplot decil_PMT decil_YPC, bins(10) name(d) cuts(0 .25 .5 .75 1 1.25 1.5 1.75 2 2.25 2.5)
graph combine a b c d
graph export "Outputs\heatplots_sirbho_combined.png", width(1500) height(1500) replace

// sample 5

// save "data.dta"
// scatter ranking_IPM ranking_PMT
// heatplot ranking_IPM ranking_PMT
heatplot decil_IPM decil_PMT, bins(10)
graph export "Outputs\heatplots_sirbho_PMT_vs_IPM_deciles.png", width(1500) height(1500) replace

heatplot quintil_IPM quintil_PMT, bins(5)
graph export "Outputs\heatplots_sirbho_PMT_vs_IPM_quintiles.png", width(1500) height(1500) replace




*** German
correlate ranking_IPM ranking_PMT
spearman ingreso_est SumIPM
stop
hist ln_ingreso_est
graph export "Outputs\histogram_PMT.png", width(1500) height(1500) replace

hist SumIPM
graph export "Outputs\histogram_IPM.png", width(1500) height(1500) replace

sample 1
scatter ranking_IPM ranking_PMT
graph export "Outputs\scatter_1percent.png", width(1500) height(1500) replace

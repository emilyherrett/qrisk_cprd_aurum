cap prog drop pr_getlast_bmi_aurum

program define pr_getlast_bmi_aurum 
syntax , clinicalfile(string) clinfilenum(string) index(string) runin(integer) bmi_cutoff(integer)

preserve

display in red "*******************Observation file number: 1*******************"
use "$QRiskCodelistdir\cr_codelist_qof_cod_aurum.dta", clear
keep if variable=="bmi"
merge 1:m medcodeid using "`clinicalfile'_1", keep(match) keepusing(patid obsdate value) nogen
drop if obsdate==.
tempfile bmirecs
save `bmirecs' , replace


forvalues n=2/`clinfilenum' {
display in red "*******************Observation file number: `n'*******************"
use "$QRiskCodelistdir\cr_codelist_qof_cod_aurum.dta", clear
keep if variable=="bmi"
merge 1:m medcodeid using "`clinicalfile'_`n'", keep(match) keepusing(patid obsdate value) nogen
drop if obsdate==.
append using "`bmirecs'"
save `bmirecs' , replace
}

rename value bmi
destring bmi, replace
replace bmi=. if bmi>`bmi_cutoff'
replace bmi=. if bmi<10
drop if bmi==.

*use average bmi if more than one measurement on same day and <= 5kg/m2 difference
duplicates tag patid obsdate, gen(dup)
sort patid obsdate
by patid obsdate: egen minbmi = min(bmi)
by patid obsdate: egen maxbmi = max(bmi)
by patid obsdate: egen avbmi = mean(bmi)
gen diff = maxbmi - minbmi
drop if diff > 5
replace bmi = avbmi if dup > 0

keep patid obsdate bmi

save `bmirecs' , replace

restore
merge 1:m patid using `bmirecs' ,  keep(match master)
sort patid obsdate
by patid: replace bmi=. if _merge==3 & obsdate>`index' & _n==1
by patid: replace obsdate=. if _merge==3 & obsdate>`index' & _n==1
drop if obsdate>`index' & _merge==3 & obsdate!=.

by patid: replace bmi=. if _merge==3 & obsdate<`index'-365.25*`runin' & _n==_N
by patid: replace obsdate=. if _merge==3 & obsdate<`index'-365.25*`runin' & _n==_N
drop if obsdate<`index'-365.25*`runin' &  _merge==3
gsort patid obsdate bmi
by patid: keep if _n==_N
rename obsdate bmidate

drop _merge

end


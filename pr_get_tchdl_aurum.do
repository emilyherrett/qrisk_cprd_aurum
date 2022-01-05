cap prog drop pr_get_tchdl_aurum
program define pr_get_tchdl_aurum
syntax, clinicalfile(string) clinfilenum(string) begin(string) end(string) runin(integer) [cutoff(string)]

if "`cutoff'"=="" {
	local cutoff "."
}

preserve

display in red "*******************Observation file number: 1*******************"
use "`clinicalfile'_1" , clear
keep if medcodeid=="279462018" | medcodeid=="458249011" | medcodeid=="259250015" | medcodeid=="8396611000006112" 
// these are the codes used in read version (44PG.00, 44lF.00, 44PF.00) + an equivalent EMIS version
// other terms which are similar but not total/serum cholesterol : HDL not included
keep if numunitid=="" | numunitid=="1" | numunitid=="65" | numunitid=="260" | numunitid=="292" | numunitid=="405" | numunitid=="421"
drop if obsdate==.
tempfile tempura
save `tempura' , replace

forvalues n=2/`clinfilenum' {
display in red "*******************Observation file number: `n'*******************"
use "`clinicalfile'_`n'" , clear
keep if medcodeid=="279462018" | medcodeid=="458249011" | medcodeid=="259250015" | medcodeid=="8396611000006112" 
// these are the codes used in read version (44PG.00, 44lF.00, 44PF.00) + an equivalent EMIS version
// other terms which are similar but not total/serum cholesterol : HDL not included
keep if numunitid=="" | numunitid=="1" | numunitid=="65" | numunitid=="260" | numunitid=="292" | numunitid=="405" | numunitid=="421"
drop if obsdate==.
append using "`tempura'"
save `tempura' , replace
}

destring value, replace

drop if value>`cutoff'
drop if value==0
rename value TC_HDLratio
rename obsdate TC_HDLdate
drop if TC_HDLdate==.

*HDL:LDL ratios recorded on same date
keep patid TC_HDLratio TC_HDLdate
duplicates drop
duplicates tag patid TC_HDLdate, gen(dup)
drop if dup>0 /*Different lab tests on same day indicative of error?*/

keep patid TC_HDLratio TC_HDLdate
save `tempura' , replace

restore
merge 1:m patid using `tempura' , nogen keep(match master)

drop if (TC_HDLdate<`begin'-365.25*`runin' | TC_HDLdate>`end') & TC_HDLdate!=.
gsort patid -TC_HDLdate
duplicates drop patid if TC_HDLdate<`begin', force

sort patid TC_HDLdate TC_HDLratio
expand 2 if TC_HDLdate>`begin' & TC_HDLdate!=. & patid[_n]!=patid[_n-1]
sort patid TC_HDLdate
by patid: replace TC_HDLratio=. if _n==1 & TC_HDLdate>`begin'
by patid: replace TC_HDLdate=`begin' if _n==1 & TC_HDLdate>`begin'

end



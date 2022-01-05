cap prog drop pr_get_smokingupdates_aurum

program define pr_get_smokingupdates_aurum 
syntax, clinicalfile(string) clinfilenum(string) smokingstatusvar(string) begin(string) end(string) runin(integer) 

preserve

display in red "*******************Observation file number: 1*******************"
use "$QRiskCodelistdir\cr_codelist_qof_cod_aurum", clear
keep if variable=="smoke_cat"
*NOTE: MEDCODE 102921000006112, Read code 137..00 "Tobacco consumption" is being removed from the code list as it does not indicate smoking status.
drop if medcodeid=="102921000006112"
merge 1:m medcodeid using  "`clinicalfile'_1" , keep(match) keepusing(patid obsdate value numunitid) nogen

tempfile smokrecs
save `smokrecs', replace


forvalues n=2/`clinfilenum' {
display in red "*******************Observation file number: `n'*******************"
use "$QRiskCodelistdir\cr_codelist_qof_cod_aurum", clear
keep if variable=="smoke_cat"
drop if medcodeid=="102921000006112"
merge 1:m medcodeid using  "`clinicalfile'_`n'" , keep(match) keepusing(patid obsdate value numunitid) nogen

append using "`smokrecs'"
save `smokrecs', replace
}

drop if obsdate==.

rename qofvalue status
label define statuslab 0 "non-smoker" 1 "ex-smoker" 2 "light smoker" 3 "moderate smoker" 4 "heavy smoker" 234 "smoker amount unknown", replace
label values status statuslab

destring value, replace
gen cigsperday=.

foreach x in 38 39 43 54 55 98 118 120 128 237 247 395 478 703 1050 1202 1316 1394 1496 3362 3391 4286 7144 { // values from numunit lookup which correspond to per day intake (excludes those which are specified weight [grams or ounces])
replace cigsperday=value if numunitid=="`x'"
}

replace cigsperday = 0 if cigsperday==0
replace cigsperday = 2 if cigsperday<10 & cigsperday>0
replace cigsperday = 3 if cigsperday<20 & cigsperday>9
replace cigsperday = 4 if cigsperday>19 & cigsperday!=.
label values cigsperday statuslab

replace status=0 if cigsperday==0 & status==234
replace status=2 if cigsperday==2 & status==234
replace status=3 if cigsperday==3 & status==234
replace status=4 if cigsperday==4 & status==234

gen s234=1 if status==234
replace status=3 if status==234 /*assume moderate smoker if no info*/

*duplicates
duplicates drop patid obsdate status, force
duplicates tag patid obsdate, gen(dup)
sort patid obsdate
by patid obsdate: egen counts234 = count(s234)
by patid obsdate: egen minstatus = min(status)
by patid obsdate: egen maxstatus = max(status)
drop if s234==1 & counts234<=dup & dup>0 & maxstatus>2 & minstatus>1 /*keep specified amount if imputed amount on same day*/
drop dup
duplicates tag patid obsdate, gen(dup)
drop if dup>0 /*drop all remaining records with at least two different smoking status records on the same day*/
assert status!=.

keep patid obsdate status

save `smokrecs', replace

restore
merge 1:m patid using `smokrecs',  keep(match master)

rename obsdate smoke_update
drop if (smoke_update<`begin'-365.25*`runin' | smoke_update>`end') & _merge==3
gsort patid -smoke_update
duplicates drop patid if smoke_update<`begin', force

sort patid smoke_update
by patid: drop if status[_n-1]==status & _n>1

expand 2 if smoke_update>`begin' & smoke_update!=. & patid[_n]!=patid[_n-1]
sort patid smoke_update
by patid: replace status=. if _n==1 & smoke_update>`begin'
by patid: replace smoke_update=`begin' if _n==1 & smoke_update>`begin'

rename status `smokingstatusvar'
drop _merge
if "`wide'"=="wide" {
by patid: gen smok_rec_num=_n

reshape wide `smokingstatusvar' smoke_update, i(patid) j(smok_rec_num)
}

end


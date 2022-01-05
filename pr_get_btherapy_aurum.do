cap prog drop pr_get_btherapy_aurum

prog define pr_get_btherapy_aurum
syntax , variable(string) therapyfile(string) therapyfilenum(string) begin(string) end(string) runin(integer) time(string) 

/*Time = current: at least two prescriptions, with the most recent one being no more than 28 days
before the date of entry to the cohort
Time = ever: at least one prescription before index*/

tempfile dataathand
save `dataathand' , replace

display in red "*******************Drug issue file number: 1*******************"
/*identify all prescriptions of specified drugs*/
use  "$QRiskCodelistdir\cr_codelist_`variable'_aurum" , clear 
keep prodcodeid
merge 1:m prodcodeid using "`therapyfile'_1" , nogen keep(match) keepusing(patid issuedate enterdate)

tempfile treated
save `treated' , replace

forvalues n=2/`therapyfilenum' {
display in red "*******************Drug issue file number: `n'*******************"
use  "$QRiskCodelistdir\cr_codelist_`variable'_aurum" , clear 
keep prodcodeid
merge 1:m prodcodeid using "`therapyfile'_`n'" , nogen keep(match) keepusing(patid issuedate enterdate)

append using "`treated'"
save `treated' , replace
}

replace issuedate=enterdate if issuedate==.
drop if issuedate==.
keep patid issuedate 
duplicates drop

gen b_`variable'=1

save `treated' , replace

/*merge with patient file, keep events within follow-up period*/
use `dataathand', clear

merge 1:m patid using `treated', keep(match master)

drop if _merge==3 & issuedate>`end'
drop if _merge==3 & issuedate<`begin'-365.25*`runin'

sort patid issuedate

if "`time'" == "ever" {
	/*first eventdate for ever prescriptions*/
	by patid: keep if _n==1
	
	/*create additional records for patients first prescribed treatment
	after the index date, set eventdate to start of follow-up and variable to 0*/ 
	sort patid issuedate
	expand 2 if issuedate>`begin' & issuedate!=. & patid[_n]!=patid[_n-1]
	sort patid issuedate
	by patid: replace b_`variable'=0 if _n==1 & issuedate>`begin'
	by patid: replace issuedate = `begin' if _n==1 & issuedate>`begin'
	}

if "`time'" == "current" {
	/*only keep one pre-baseline record, marked as whether or not 
	meets criteria of current treatment (at least 2 prior prescriptions 
	with most recent no more than 28 days)*/
	gen _28daywindow=1 if issuedate<=`begin' & (`begin'-issuedate) <=28
	by patid: egen _count28daywindow = count(_28daywindow)
	gen _everbeforeindex=1 if issuedate<=`begin'
	by patid: egen _counteverbeforeindex=count(_everbeforeindex)
	replace b_`variable'=0 if (_counteverbeforeindex<2 | _count28daywindow<1) & issuedate<=`begin'
	gen before=1 if issuedate<`begin'
	sort patid before
	by patid before: drop if _n!=_N & before==1
	drop _28daywindow _count28daywindow _everbeforeindex _counteverbeforeindex
	preserve
	keep if before==1
	drop before
	tempfile treatbefore
	save `treatbefore' , replace
	restore

	/*all records for current prescriptions after baseline*/
	drop if before==1
	drop before
	gen runoutdate=issuedate+28
	format runoutdate %td
	sort patid issuedate
	gen order = _n
	/*create an additional record for time between prescriptions where eventdate is 
	the runout date of the previous record and b_`variable' is 0*/
	expand 2 if runoutdate<issuedate[_n+1] & patid==patid[_n+1] 
	sort order
	by order: replace issuedate=runoutdate if _n==2
	by order: replace b_`variable'=0 if _n==2
	drop runoutdate order 
	
	/*add in records for patients first prescribed treatment before index date*/
	append using "`treatbefore'"
	
	/*create additional records for patients first prescribed treatment
	after the index date, set eventdate to start of follow-up and b_hyp_diag to 0*/ 
	sort patid issuedate
	expand 2 if issuedate>`begin' & issuedate!=. & patid[_n]!=patid[_n-1]
	sort patid issuedate
	by patid: replace b_`variable'=0 if _n==1 & issuedate>`begin'
	by patid: replace issuedate = `begin' if _n==1 & issuedate>`begin'
	}
	
drop _merge 
rename issuedate `variable'date

replace b_`variable'=0 if b_`variable'==.
sort patid `variable'date
	
end



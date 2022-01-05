cap prog drop pr_getlast_btherapy_aurum

prog define pr_getlast_btherapy_aurum
syntax , variable(string) therapyfile(string) therapyfilenum(string) index(string) time(string) runin(integer)

/*Time = current: at least two prescriptions, with the most recent one being no more than 28 days
before the date of entry to the cohort
Time = ever: at least one prescription before index*/

preserve

display in red "*******************Drug issue file number: 1*******************"
*create temporary file with patids / event dates for all prescriptions of the specified drugs
use  "$QRiskCodelistdir\cr_codelist_`variable'_aurum" , clear
keep prodcodeid
merge 1:m prodcodeid using `therapyfile'_1 , nogen keep(match) keepusing(patid issuedate enterdate)

tempfile ther_data
save `ther_data' , replace


forvalues n=2/`therapyfilenum' {
display in red "*******************Drug issue file number: `n'*******************"
use  "$QRiskCodelistdir\cr_codelist_`variable'_aurum" , clear
keep prodcodeid
merge 1:m prodcodeid using "`therapyfile'_`n'" , nogen keep(match) keepusing(patid issuedate enterdate)

append using "`ther_data'"
save `ther_data' , replace
}

replace issuedate=enterdate if issuedate==.
drop if issuedate==.
keep patid issuedate 
duplicates drop

save `ther_data' , replace

*restore patient file to date and merge with prescription records
restore

merge 1:m patid using `ther_data', keep(match master)
sort patid issuedate

replace issuedate=. if _merge==3 & issuedate<`index'-365.25*`runin' 

gen _everbeforeindex = 1 if issuedate <= `index'
by patid: egen _counteverbeforeindex = count(_everbeforeindex)

gen _28daywindow = 1 if issuedate <= `index' & (`index' - issuedate) <= 28
bysort patid: egen _count28daywindow = count(_28daywindow)

gen b_`variable' = 0
if "`time'" == "current" {
	replace b_`variable' = 1 if _counteverbeforeindex >= 2 & _count28daywindow >= 1
	}
if "`time'" == "ever" {
	replace b_`variable' = 1 if _counteverbeforeindex >= 1
	}
	
drop _* issuedate
duplicates drop


end



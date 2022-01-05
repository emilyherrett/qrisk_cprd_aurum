cap prog drop pr_get_ED_aurum

prog define pr_get_ED_aurum
syntax , clinicalfile(string) clinfilenum(string) therapyfile(string) therapyfilenum(string) begin(string) end(string) runin(integer) 

preserve
*first ever diagnosis code
pr_get_bclin_aurum, variable(ED) qof(notqof) clinicalfile(`clinicalfile') clinfilenum(`clinfilenum') begin(`begin') end(`end') runin(`runin')

tempfile b_ED
save `b_ED', replace

restore
*first ever treatment
pr_get_btherapy_aurum, variable(ED_drugs) therapyfile(`therapyfile') therapyfilenum(`therapyfilenum') begin(`begin') end(`end') runin(`runin') time(ever)

append using `b_ED'

*combine results in single set of variables
replace EDdate = ED_drugsdate if EDdate == .
assert EDdate !=.
replace b_ED = b_ED_drugs if b_ED == .
assert b_ED !=.
drop ED_drugs b_ED_drugs

*keep only one record per date
gsort patid EDdate -b_ED
bysort patid EDdate: keep if _n==1

*keep only one result before baseline, which needs to overwrite the expanded baseline results created
by patid: replace b_ED=1 if b_ED[_n-1]==1 & EDdate<=`begin'
duplicates drop patid if EDdate<=`begin', force

end

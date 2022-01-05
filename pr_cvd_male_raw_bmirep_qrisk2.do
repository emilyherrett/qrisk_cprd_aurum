*use a dataset including 
cap prog drop cvd_male_raw_qrisk2
program define cvd_male_raw_qrisk2

noi di "Variables you need:"
noi di "age -- age as integer"
noi di	"b_AF -- atrial fibrilation as binary 01"
noi di "b_ra -- rheumatoid arthritis as binary 01"
noi di "b_renal -- rename disease as binary 01"
noi di "b_treatedhyp -- hypertension treatment as binary 01"
noi di "b_type1 -- type 1 diabetes as binary 01"
noi di "b_type2 -- type 2 diabetes as binary 01"
noi di "bmi -- bmi as continuous numeric"
noi di "ethrisk -- ethnicity as categorical integer (0-9)"
noi di "fh_cvd -- family history as binary 01"
noi di "rati -- HDL LDL cholesterol ratio as continuous numeric"
noi di "sbp -- systolic blood pressure as continuous numeric"
noi di "smoke_cat -- smoking as integer category (0-4)"
noi di "town -- townsend deprivation score as continuous numeric -- not clear how this is provided, as score or quintile"
noi di "sex  -- sex as 1=male 2=female"

cap gen score=.
gen double rec_num=_n
preserve
keep if sex==1
*replace bmi=20 if bmi<20


local surv=10
forvalues i = 0/15 {
	gen survivor`i'=0
}
replace survivor10=0.978794217109680
*this part is added in incase they want to do risk scores over a different number of years but they haven't actually done the groundwork yet.

gen Iethrisk0 = 0
gen Iethrisk1 = 0 /*5*/
gen Iethrisk2 = 0.3173321430481919100000000 /*3*/
gen Iethrisk3 = 0.4738590786081115500000000 /*2*/
gen Iethrisk4 = 0.5171314655968145500000000 /*1*/
gen Iethrisk5 = 0.1370301157366419200000000 /*4*/
gen Iethrisk6 = -0.3885522304972663900000000 /*8*/
gen Iethrisk7 = -0.3812495485312194500000000 /*7*/
gen Iethrisk8 = -0.4064461381650994500000000 /*9*/ 
gen Iethrisk9 = -0.2285715521377336100000000 /*6*/

gen Ismoke0=0
gen Ismoke1=0.2684479158158020200000000
gen Ismoke2=0.6307674973877591700000000
gen Ismoke3=0.7178078883378695700000000
gen Ismoke4=0.8704172533465485100000000

gen double dage = age
replace dage=dage/10
gen double age_1 = dage^(-1)
gen double age_2 = dage^2
gen double dbmi = bmi
replace dbmi=dbmi/10
gen double bmi_2 = ln(dbmi)*dbmi^(-2)
gen double bmi_1 = dbmi^(-2)

replace age_1 = age_1 - 0.233734160661697
replace age_2 = age_2 - 18.304403305053711
replace bmi_1 = bmi_1 - 0.146269768476486
replace bmi_2 = bmi_2 - 0.140587374567986
replace rati = rati - 4.321151256561279
replace sbp = sbp - 130.589752197265620
replace town = town - 0.551009356975555
	


gen double a=0

/* The conditional sums */
forvalues i=1/9 {
replace a = a+ Iethrisk`i' if ethrisk==`i'
} 
forvalues i=0/4 {
replace a = a+ Ismoke`i' if smoke_cat==`i' 
}


 replace a = a+ age_1 * -18.0437312550377270000000000 
	 replace a = a+ age_2 * 0.0236486454254306940000000 
	 replace a = a+ bmi_1 * 2.5388084343581578000000000 
	 replace a = a+ bmi_2 * -9.1034725871528597000000000 
	 replace a = a+ rati * 0.1684397636136909500000000 
	 replace a = a+ sbp * 0.0105003089380754820000000 
	 replace a = a+ town * 0.0323801637634487590000000 



	/* Sum from boolean values */


	 replace a = a+ b_AF * 1.0363048000259454000000000 
	 replace a = a+ b_ra * 0.2519953134791012600000000 
	 replace a = a+ b_renal * 0.8359352886995286000000000 
	 replace a = a+ b_treatedhyp * 0.6603459695917862600000000 
	 replace a = a+ b_type1 * 1.3309170433446138000000000 
	 replace a = a+ b_type2 * 0.9454348892774417900000000 
	 replace a = a+ fh_cvd * 0.5986037897136281500000000 



	/* Sum from interaction terms */


	 replace a = a+ age_1 * 1 * 0.6186864699379683900000000 if smoke_cat==1
	 replace a = a+ age_1 * 1 * 1.5522017055600055000000000 if smoke_cat==2
	 replace a = a+ age_1 * 1 * 2.4407210657517648000000000 if smoke_cat==3
	 replace a = a+ age_1 * 1 * 3.5140494491884624000000000 if smoke_cat==4
	 replace a = a+ age_1 * b_AF * 8.0382925558108482000000000 
	 replace a = a+ age_1 * b_renal * -1.6389521229064483000000000 
	 replace a = a+ age_1 * b_treatedhyp * 8.4621771382346651000000000 
	 replace a = a+ age_1 * b_type1 * 5.4977016563835504000000000 
	 replace a = a+ age_1 * b_type2 * 3.3974747488766690000000000 
	 replace a = a+ age_1 * bmi_1 * 33.8489881012767600000000000 
	 replace a = a+ age_1 * bmi_2 * -140.6707025404897100000000000 
	 replace a = a+ age_1 * fh_cvd * 2.0858333154353321000000000 
	 replace a = a+ age_1 * sbp * 0.0501283668830720540000000 
	 replace a = a+ age_1 * town * -0.1988268217186850700000000 
	 replace a = a+ age_2 * 1 * -0.0040893975066796338000000 if smoke_cat==1
	 replace a = a+ age_2 * 1 * -0.0056065852346001768000000 if smoke_cat==2
	 replace a = a+ age_2 * 1 * -0.0018261006189440492000000 if smoke_cat==3
	 replace a = a+ age_2 * 1 * -0.0014997157296173290000000 if smoke_cat==4
	 replace a = a+ age_2 * b_AF * 0.0052471594895864343000000 
	 replace a = a+ age_2 * b_renal * -0.0179663586193546390000000 
	 replace a = a+ age_2 * b_treatedhyp * 0.0092088445323379176000000 
	 replace a = a+ age_2 * b_type1 * 0.0047493510223424558000000 
	 replace a = a+ age_2 * b_type2 * -0.0048113775783491563000000 
	 replace a = a+ age_2 * bmi_1 * 0.0627410757513945650000000 
	 replace a = a+ age_2 * bmi_2 * -0.2382914909385732100000000 
	 replace a = a+ age_2 * fh_cvd * -0.0049971149213281010000000 
	 replace a = a+ age_2 * sbp * -0.0000523700987951435090000 
	 replace a = a+ age_2 * town * -0.0012518116569283104000000 





	/* Sum from continuous values */


 gen double scorem = exp(a)
 replace  scorem=survivor`surv'^scorem
 replace  scorem = 1-scorem
 replace scorem=100*scorem
 *gen double scorem = 100.0 * (1 - survivor`surv'^(exp(a)))
 
keep scorem patid rec_num

tempfile temper
save `temper' , replace
restore
merge 1:1 patid rec_num using `temper' , nogen
drop rec_num

replace score=scorem if scorem!=.
drop scorem

end
 

 
 
 
 
 
 
 
 
 
 
 

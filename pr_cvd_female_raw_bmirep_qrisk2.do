*use a dataset including 
cap prog drop cvd_female_raw_qrisk2
program define cvd_female_raw_qrisk2

noi di "Variables you need:"
noi di "age -- age as integer"
noi di	"b_AF -- atrial fibrilation as binary 01"
noi di "b_ra -- rheumatoid arthritis as binary 01"
noi di "b_renal -- rename disease as binary 01"
noi di "b_treatedhyp -- hypertension treatment as binary 01"
noi di "b_type1 -- type 1 diabetes as binary 01"
noi di "b_type2 -- type 2 diabetes as binary 01"
noi di "bmi -- bmi as continuous numeric, replaced with 20 if below 20"
noi di "ethrisk -- ethnicity as categorical integer (0-9)"
noi di "fh_cvd -- family history as binary 01"
noi di "rati -- HDL LDL cholesterol ratio as continuous numeric"
noi di "sbp -- systolic blood pressure as continuous numeric"
noi di "smoke_cat -- smoking as integer category (0-4)"
noi di "sex  -- sex as 1=male 2=female"



cap gen score=.
gen double rec_num = _n
preserve

keep if sex==2
*replace bmi=20 if bmi<20


local surv=10
forvalues i = 0/15 {
	gen survivor`i'=0
}
replace survivor10=0.989747583866119
*this part is added in incase they want to do risk scores over a different number of years but they haven't actually done the groundwork yet.

gen Iethrisk0 = 0
gen Iethrisk1 = 0 /*5*/
gen Iethrisk2 = 0.2574099349831925900000000 /*3*/
gen Iethrisk3 = 0.6129795430571779400000000 /*1*/
gen Iethrisk4 = 0.3362159841669621300000000 /*2*/
gen Iethrisk5 = 0.1512517303224336400000000 /*4*/
gen Iethrisk6 = -0.1794156259657768100000000 /*7*/
gen Iethrisk7 = -0.3503423610057745400000000 /*9*/
gen Iethrisk8 = -0.2778372483233216800000000 /*8*/
gen Iethrisk9 = -0.1592734122665366000000000 /*6*/

gen Ismoke0=0
gen Ismoke1=0.2119377108760385200000000
gen Ismoke2=0.6618634379685941500000000
gen Ismoke3=0.7570714587132305600000000
gen Ismoke4=0.9496298251457036000000000

gen double dage = age
replace dage=dage/10
gen double age_2 = dage
gen double age_1 = dage^0.5
gen double dbmi = bmi
replace dbmi=dbmi/10
gen double bmi_2 = ln(dbmi)*dbmi^(-2)
gen double bmi_1 = dbmi^(-2)

replace age_1 = age_1 - 2.086397409439087
replace age_2 = age_2 - 4.353054523468018
replace bmi_1 = bmi_1 - 0.152244374155998
replace bmi_2 = bmi_2 - 0.143282383680344
replace rati = rati - 3.506655454635620
replace sbp = sbp - 125.040039062500000
replace town = town - 0.416743695735931

gen double a=0






/* The conditional sums */
forvalues i=1/9 {
replace a = a+ Iethrisk`i' if ethrisk==`i'
} 
forvalues i=0/4{
replace a = a+ Ismoke`i' if smoke_cat==`i' 
}

	/* Sum from continuous values */


 replace a = a+ age_1 * 4.4417863976316578000000000 
 replace a = a+ age_2 * 0.0281637210672999180000000 
 replace a = a+ bmi_1 * 0.8942365304710663300000000 
 replace a = a+ bmi_2 * -6.5748047596104335000000000 
 replace a = a+ rati * 0.1433900561621420900000000 
 replace a = a+ sbp * 0.0128971795843613720000000 
 replace a = a+ town * 0.0664772630011438850000000 



	/* Sum from boolean values */

 replace a = a+ b_AF * 1.6284780236484424000000000 
 replace a = a+ b_ra * 0.2901233104088770700000000 
 replace a = a+ b_renal * 1.0043796680368302000000000 
 replace a = a+ b_treatedhyp * 0.6180430562788129500000000 
 replace a = a+ b_type1 * 1.8400348250874599000000000 
 replace a = a+ b_type2 * 1.1711626412196512000000000 
 replace a = a+ fh_cvd * 0.5147261203665195500000000 

	/* Sum from interaction terms */

 replace a = a+ age_1 * 1 * 0.7464406144391666500000000 if smoke_cat==1 
 replace a = a+ age_1 * 1 * 0.2568541711879666600000000 if smoke_cat==2
 replace a = a+ age_1 * 1 * -1.5452226707866523000000000 if smoke_cat==3
 replace a = a+ age_1 * 1 * -1.7113013709043405000000000 if smoke_cat==4
 replace a = a+ age_1 * b_AF * -7.0177986441269269000000000 
 replace a = a+ age_1 * b_renal * -2.9684019256454390000000000 
 replace a = a+ age_1 * b_treatedhyp * -4.2219906452967848000000000 
 replace a = a+ age_1 * b_type1 * 1.6835769546040080000000000 
 replace a = a+ age_1 * b_type2 * -2.9371798540034648000000000 
 replace a = a+ age_1 * bmi_1 * 0.1797196207044682300000000 
 replace a = a+ age_1 * bmi_2 * 40.2428166760658140000000000 
 replace a = a+ age_1 * fh_cvd * 0.1439979240753906700000000 
 replace a = a+ age_1 * sbp * -0.0362575233899774460000000 
 replace a = a+ age_1 * town * 0.3735138031433442600000000 
 replace a = a+ age_2 * 1 * -0.1927057741748231000000000 if smoke_cat==1
 replace a = a+ age_2 * 1 * -0.1526965063458932700000000 if smoke_cat==2
 replace a = a+ age_2 * 1 * 0.2313563976521429400000000 if smoke_cat==3
 replace a = a+ age_2 * 1 * 0.2307165013868296700000000 if smoke_cat==4
 replace a = a+ age_2 * b_AF * 1.1395776028337732000000000 
 replace a = a+ age_2 * b_renal * 0.4356963208330940600000000 
 replace a = a+ age_2 * b_treatedhyp * 0.7265947108887239600000000 
 replace a = a+ age_2 * b_type1 * -0.6320977766275653900000000 
 replace a = a+ age_2 * b_type2 * 0.4023270434871086800000000 
 replace a = a+ age_2 * bmi_1 * 0.1319276622711877700000000 
 replace a = a+ age_2 * bmi_2 * -7.3211322435546409000000000 
 replace a = a+ age_2 * fh_cvd * -0.1330260018273720400000000 
 replace a = a+ age_2 * sbp * 0.0045842850495397955000000 
 replace a = a+ age_2 * town * -0.0952370300845990780000000 

 
 gen double scoref = exp(a)
 replace scoref=survivor`surv'^scoref
 replace  scoref = 1-scoref
 replace  scoref=100*scoref
 *gen double scoref = 100.0 * (1 - survivor`surv'^(exp(a)))
 
keep scoref patid rec_num

tempfile temper
save `temper' , replace
restore
merge 1:1 patid rec_num using `temper' , nogen
drop rec_num

replace score=scoref if scoref!=.
drop scoref
 
end
 
 
 
 
 
 
 
 
 
 
 
 
 

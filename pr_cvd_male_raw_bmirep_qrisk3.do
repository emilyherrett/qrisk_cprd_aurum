*use a dataset including 
cap prog drop cvd_male_raw_qrisk3
program define cvd_male_raw_qrisk3

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

noi di "b_atypicalantipsy -- atypical antipsychotic prescribing as binary 01"
noi di "b_semi - severe mental illness as binary 01"
noi di "sbp_s5 - systolic blood pressure variability as continuous numeric"
noi di "b_impotence2 - erectile dysfunction as binary 01"
noi di "b_sle - systemic lupus erythematosus as binary 01"
noi di "b_corticosteroids - corticosteroid prescribing as binary 01"

cap gen score=.
gen double rec_num=_n
preserve
keep if sex==1
*replace bmi=20 if bmi<20


local surv=10
forvalues i = 0/15 {
	gen survivor`i'=0
}
replace survivor10=0.977268040180206
*this part is added in incase they want to do risk scores over a different number of years but they haven't actually done the groundwork yet.

gen Iethrisk0 = 0
gen Iethrisk1 = 0 /*5*/
gen Iethrisk2 = 0.2771924876030827900000000 /*3*/
gen Iethrisk3 = 0.4744636071493126800000000 /*2*/
gen Iethrisk4 = 0.5296172991968937100000000 /*1*/
gen Iethrisk5 = 0.0351001591862990170000000 /*4*/
gen Iethrisk6 = -0.3580789966932791900000000 /*8*/
gen Iethrisk7 = -0.4005648523216514000000000 /*7*/
gen Iethrisk8 = -0.4152279288983017300000000 /*9*/ 
gen Iethrisk9 = -0.2632134813474996700000000 /*6*/

gen Ismoke0=0
gen Ismoke1=0.1912822286338898300000000
gen Ismoke2=0.5524158819264555200000000
gen Ismoke3=0.6383505302750607200000000
gen Ismoke4=0.7898381988185801900000000

gen double dage = age
replace dage=dage/10
gen double age_1 = dage^(-1)
gen double age_2 = dage^3
gen double dbmi = bmi
replace dbmi=dbmi/10
gen double bmi_2 = ln(dbmi)*dbmi^(-2)
gen double bmi_1 = dbmi^(-2)

replace age_1 = age_1 - 0.234766781330109
replace age_2 = age_2 - 77.284080505371094
replace bmi_1 = bmi_1 - 0.149176135659218
replace bmi_2 = bmi_2 - 0.141913309693336
replace rati = rati - 4.300998687744141
replace sbp = sbp - 128.571578979492190
replace sbps5 = sbps5 - 8.756621360778809
replace town = town - 0.526304900646210
	


gen double a=0

/* The conditional sums */
forvalues i=1/9 {
replace a = a+ Iethrisk`i' if ethrisk==`i'
} 
forvalues i=0/4 {
replace a = a+ Ismoke`i' if smoke_cat==`i' 
}


 replace a = a+ age_1 * -17.8397816660055750000000000 
	 replace a = a+ age_2 * 0.0022964880605765492000000 
	 replace a = a+ bmi_1 * 2.4562776660536358000000000 
	 replace a = a+ bmi_2 * -8.3011122314711354000000000 
	 replace a = a+ rati * 0.1734019685632711100000000 
	 replace a = a+ sbp * 0.0129101265425533050000000
	 replace a = a+ sbps5 * 0.0102519142912904560000000 if sbps5 != .
	 replace a = a+ town * 0.0332682012772872950000000 

	/* Sum from boolean values */


	 replace a = a+ b_AF * 0.8820923692805465700000000
	 replace a = a+ b_atypicalantipsy * 0.1304687985517351300000000
	 replace a = a+ b_corticosteroids * 0.4548539975044554300000000
	 replace a = a+ b_impotence2 * 0.2225185908670538300000000
	 replace a = a+ b_migraine * 0.2558417807415991300000000
	 replace a = a+ b_ra * 0.2097065801395656700000000 
	 replace a = a+ b_renal * 0.7185326128827438400000000
	 replace a = a+ b_semi * 0.1213303988204716400000000
	 replace a = a+ b_sle * 0.4401572174457522000000000
	 replace a = a+ b_treatedhyp * 0.5165987108269547400000000 
	 replace a = a+ b_type1 * 1.2343425521675175000000000 
	 replace a = a+ b_type2 * 0.8594207143093222100000000 
	 replace a = a+ fh_cvd * 0.5405546900939015600000000 



	/* Sum from interaction terms */


	 replace a = a+ age_1 * 1 * -0.2101113393351634600000000 if smoke_cat==1
	 replace a = a+ age_1 * 1 * 0.7526867644750319100000000 if smoke_cat==2
	 replace a = a+ age_1 * 1 * 0.9931588755640579100000000 if smoke_cat==3
	 replace a = a+ age_1 * 1 * 2.1331163414389076000000000 if smoke_cat==4
	 replace a = a+ age_1 * b_AF * 3.4896675530623207000000000 
	 replace a = a+ age_1 * b_corticosteroids * 1.1708133653489108000000000
	 replace a = a+ age_1 * b_impotence2 * -1.5064009857454310000000000
	 replace a = a+ age_1 * b_migraine * 2.3491159871402441000000000
	 replace a = a+ age_1 * b_renal * -0.5065671632722369400000000 
	 replace a = a+ age_1 * b_treatedhyp * 6.5114581098532671000000000 
	 replace a = a+ age_1 * b_type1 * 5.3379864878006531000000000 
	 replace a = a+ age_1 * b_type2 * 3.6461817406221311000000000 
	 replace a = a+ age_1 * bmi_1 * 31.0049529560338860000000000 
	 replace a = a+ age_1 * bmi_2 * -111.2915718439164300000000000 
	 replace a = a+ age_1 * fh_cvd * 2.7808628508531887000000000 
	 replace a = a+ age_1 * sbp * 0.0188585244698658530000000 
	 replace a = a+ age_1 * town * -0.1007554870063731000000000
	 replace a = a+ age_2 * -0.0004985487027532612100000 if smoke_cat==1
	 replace a = a+ age_2 * -0.0007987563331738541400000 if smoke_cat==2
	 replace a = a+ age_2 * -0.0008370618426625129600000 if smoke_cat==3
	 replace a = a+ age_2 * -0.0007840031915563728900000 if smoke_cat==4
	 replace a = a+ age_2 * b_AF * -0.0003499560834063604900000
	 replace a = a+ age_2 * b_corticosteroids * -0.0002496045095297166000000
	 replace a = a+ age_2 * b_impotence2 * -0.0011058218441227373000000
	 replace a = a+ age_2 * b_migraine * 0.0001989644604147863100000
	 replace a = a+ age_2 * b_renal * -0.0018325930166498813000000 
	 replace a = a+ age_2 * b_treatedhyp * 0.0006383805310416501300000 
	 replace a = a+ age_2 * b_type1 * 0.0006409780808752897000000 
	 replace a = a+ age_2 * b_type2 * -0.0002469569558886831500000 
	 replace a = a+ age_2 * bmi_1 * 0.0050380102356322029000000 
	 replace a = a+ age_2 * bmi_2 * -0.0130744830025243190000000 
	 replace a = a+ age_2 * fh_cvd * -0.0002479180990739603700000 
	 replace a = a+ age_2 * sbp * -0.0000127187419158845700000 
	 replace a = a+ age_2 * town * -0.0000932996423232728880000 





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
 

 
 
 
 
 
 
 
 
 
 
 

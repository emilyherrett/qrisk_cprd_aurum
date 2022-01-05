*use a dataset including 
cap prog drop cvd_female_raw_qrisk3
program define cvd_female_raw_qrisk3

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

noi di "b_atypicalantipsy -- atypical antipsychotic prescribing as binary 01"
noi di "b_semi - severe mental illness as binary 01"
noi di "sbp_s5 - systolic blood pressure variability as continuous numeric"
noi di "b_impotence2 - erectile dysfunction as binary 01"
noi di "b_sle - systemic lupus erythematosus as binary 01"
noi di "b_corticosteroids - corticosteroid prescribing as binary 01"


cap gen score=.
gen double rec_num = _n
preserve

keep if sex==2
*replace bmi=20 if bmi<20


local surv=10
forvalues i = 0/15 { 
	gen survivor`i'=0
}
replace survivor10=0.988876402378082
*this part is added in incase they want to do risk scores over a different number of years but they haven't actually done the groundwork yet.

gen Iethrisk0 = 0
gen Iethrisk1 = 0
gen Iethrisk2 = 0.2804031433299542500000000
gen Iethrisk3 = 0.5629899414207539800000000
gen Iethrisk4 = 0.2959000085111651600000000
gen Iethrisk5 = 0.0727853798779825450000000
gen Iethrisk6 = -0.1707213550885731700000000
gen Iethrisk7 = -0.3937104331487497100000000
gen Iethrisk8 = -0.3263249528353027200000000 
gen Iethrisk9 = -0.1712705688324178400000000

gen Ismoke0=0
gen Ismoke1=0.1338683378654626200000000
gen Ismoke2=0.5620085801243853700000000
gen Ismoke3=0.6674959337750254700000000
gen Ismoke4=0.8494817764483084700000000

gen double dage = age
replace dage=dage/10
gen double age_1 = dage^(-2)
gen double age_2 = dage
gen double dbmi = bmi
replace dbmi=dbmi/10
gen double bmi_1 = dbmi^(-2)
gen double bmi_2 = ln(dbmi)*dbmi^(-2)

replace age_1 = age_1 - 0.053274843841791
replace age_2 = age_2 - 4.332503318786621
replace bmi_1 = bmi_1 - 0.154946178197861
replace bmi_2 = bmi_2 - 0.144462317228317
replace rati = rati - 3.476326465606690
replace sbp = sbp - 123.130012512207030
replace sbps5 = sbps5 - 9.002537727355957
replace town = town - 0.392308831214905

/* Start of Sum */
gen double a=0


/* The conditional sums */
forvalues i=1/9 {
replace a = a+ Iethrisk`i' if ethrisk==`i'
} 
forvalues i=0/4{
replace a = a+ Ismoke`i' if smoke_cat==`i' 
}

	/* Sum from continuous values */


 replace a = a+ age_1 * -8.1388109247726188000000000 
 replace a = a+ age_2 * 0.7973337668969909800000000 
 replace a = a+ bmi_1 * 0.2923609227546005200000000 
 replace a = a+ bmi_2 * -4.1513300213837665000000000 
 replace a = a+ rati * 0.1533803582080255400000000 
 replace a = a+ sbp * 0.0131314884071034240000000
 replace a = a+ sbps5 * 0.0078894541014586095000000 if sbps5 != .
 replace a = a+ town * 0.0772237905885901080000000 



	/* Sum from boolean values */

 replace a = a+ b_AF * 1.5923354969269663000000000
 replace a = a+ b_atypicalantipsy * 0.2523764207011555700000000
 replace a = a+ b_corticosteroids * 0.5952072530460185100000000
 replace a = a+ b_migraine * 0.3012672608703450000000000
 replace a = a+ b_ra * 0.2136480343518194200000000 
 replace a = a+ b_renal * 0.6519456949384583300000000
 replace a = a+ b_semi * 0.1255530805882017800000000
 replace a = a+ b_sle * 0.7588093865426769300000000
 replace a = a+ b_treatedhyp * 0.5093159368342300400000000 
 replace a = a+ b_type1 * 1.7267977510537347000000000 
 replace a = a+ b_type2 * 1.0688773244615468000000000 
 replace a = a+ fh_cvd * 0.4544531902089621300000000 

	/* Sum from interaction terms */

 replace a = a+ age_1 * -4.7057161785851891000000000 if smoke_cat==1 
 replace a = a+ age_1 * -2.7430383403573337000000000 if smoke_cat==2
 replace a = a+ age_1 * -0.8660808882939218200000000 if smoke_cat==3
 replace a = a+ age_1 * 0.9024156236971064800000000 if smoke_cat==4
 replace a = a+ age_1 * b_AF * 19.9380348895465610000000000
 replace a = a+ age_1 * b_corticosteroids * -0.9840804523593628100000000
 replace a = a+ age_1 * b_migraine * 1.7634979587872999000000000
 replace a = a+ age_1 * b_renal * -3.5874047731694114000000000
 replace a = a+ age_1 * b_sle * 19.6903037386382920000000000
 replace a = a+ age_1 * b_treatedhyp * 11.8728097339218120000000000 
 replace a = a+ age_1 * b_type1 * -1.2444332714320747000000000 
 replace a = a+ age_1 * b_type2 * 6.8652342000009599000000000 
 replace a = a+ age_1 * bmi_1 * 23.8026234121417420000000000 
 replace a = a+ age_1 * bmi_2 * -71.1849476920870070000000000 
 replace a = a+ age_1 * fh_cvd * 0.9946780794043512700000000 
 replace a = a+ age_1 * sbp * 0.0341318423386154850000000 
 replace a = a+ age_1 * town * -1.0301180802035639000000000 
 replace a = a+ age_2 * -0.0755892446431930260000000 if smoke_cat==1
 replace a = a+ age_2 * -0.1195119287486707400000000 if smoke_cat==2
 replace a = a+ age_2 * -0.1036630639757192300000000 if smoke_cat==3
 replace a = a+ age_2 * -0.1399185359171838900000000 if smoke_cat==4
 replace a = a+ age_2 * b_AF * -0.0761826510111625050000000
 replace a = a+ age_2 * b_corticosteroids * -0.1200536494674247200000000
 replace a = a+ age_2 * b_migraine * -0.0655869178986998590000000
 replace a = a+ age_2 * b_renal * -0.2268887308644250700000000
 replace a = a+ age_2 * b_sle * 0.0773479496790162730000000
 replace a = a+ age_2 * b_treatedhyp * 0.0009685782358817443600000 
 replace a = a+ age_2 * b_type1 * -0.2872406462448894900000000 
 replace a = a+ age_2 * b_type2 * -0.0971122525906954890000000 
 replace a = a+ age_2 * bmi_1 * 0.5236995893366442900000000 
 replace a = a+ age_2 * bmi_2 * 0.0457441901223237590000000 
 replace a = a+ age_2 * fh_cvd * -0.0768850516984230380000000 
 replace a = a+ age_2 * sbp * -0.0015082501423272358000000 
 replace a = a+ age_2 * town * -0.0315934146749623290000000 

 
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
 
 
 
 
 
 
 
 
 
 
 
 
 

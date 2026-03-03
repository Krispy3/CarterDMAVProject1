/*
Harrison Carter
2/17/2026
Project 1
DMAV 2026
*/

*clear data
clear

*load data
use "C:\Users\harri\Documents\Spring 2026\DMAV\ansur2allV2.dta"

*preliminary viewing
describe
codebook

*explore missing
misstable summarize
misstable patterns

*summarize
summarize

*generate unique key ids
gen row_id = _n

*explore extreme values
ds, has(type numeric)
local numvars `r(varlist)'

foreach v of local numvars {
    
    egen z_`v' = std(`v')
    gen out_`v' = (abs(z_`v') > 3) if !missing(`v')
    
    display "Outliers found in variable: `v'"
    tab out_`v'
}

*flag extreme values
gen any_outlier = 0

foreach v of local numvars {
    replace any_outlier = 1 if abs(z_`v') > 3 & !missing(`v')
}

tab any_outlier

*drop outliers
drop if any_outlier == 1

*report duplicates (come back to this)
duplicates report

*drop participants under 18
drop if age < 18 & age >= 0

*convert mm to cm
foreach var of varlist heightin-hipbreadth {
    gen `var'_cm = `var'/10
}
gen height_cm = heightin * 2.54
label variable height_cm "Height in centimeters"

*create bmi variable
gen bmi = weightkg / ((heightin * 0.0254)^2)

*categorize bmi
gen bmi_cat = .
replace bmi_cat = 1 if bmi < 18.5
replace bmi_cat = 2 if bmi >= 18.5 & bmi < 25
replace bmi_cat = 3 if bmi >= 25 & bmi < 30
replace bmi_cat = 4 if bmi >= 30
label define bmi_lbl 1 "Underweight" ///
                     2 "Normal weight" ///
                     3 "Overweight" ///
                     4 "Obese"
label values bmi_cat bmi_lbl
label variable bmi_cat "BMI Weight Category"

*determine season measurements were made
gen month = month(date)
gen season = .
replace season = 1 if inlist(month, 12, 1, 2)
replace season = 2 if inlist(month, 3, 4, 5)
replace season = 3 if inlist(month, 6, 7, 8)
replace season = 4 if inlist(month, 9, 10, 11)
label define season_lbl 1 "Winter" ///
                        2 "Spring" ///
                        3 "Summer" ///
                        4 "Fall"

label values season season_lbl
label variable season "Season of Measurement"

*encode strings to numerical values
encode gender, gen(sex)
label define sexlbl 2 "Male" 1 "Female"
label values sex sexlbl

encode writingpreference, gen(hand)
label define handlbl 4 "Right Handed" 3 "Left Handed" 1 "Either Hand" 2 "Either Hand"
label values hand handlbl

gen branch_num = .
replace branch_num = 1 if branch == "Combat Arms"
replace branch_num = 2 if branch == "Combat Service Support"
replace branch_num = 3 if branch == "Combat Support"
label define branchlbl 1 "Combat Arms" 2 "Combat Service Support" 3 "Combat Support"
label values branch_num branchlbl

gen inst_num = .
replace inst_num = 1 if installation == "Camp Shel"
replace inst_num = 2 if installation == "Fort Blis"
replace inst_num = 3 if installation == "Fort Drum"
replace inst_num = 4 if installation == "Fort Huac"
label define instlbl 1 "Camp Shel" 2 "Fort Blis" 3 "Fort Drum" 4 "Fort Huac"
label values inst_num instlbl

*generate anthropometric values
gen height_cat = .
replace height_cat = 1 if stature_cm < 165
replace height_cat = 2 if stature_cm >= 165 & stature_cm <= 180
replace height_cat = 3 if stature_cm > 180
label define heightlbl 1 "Short" 2 "Medium" 3 "Tall"
label values height_cat heightlbl
gen over = .
replace over = 0 if bmi <= 25
replace over = 1 if bmi > 25
label define overlbl 0 "Healthy" 1 "At Risk"
label values over overlbl
egen height_over = group(height_cat over)
label variable height_over "Height Category by Overweight Status"
label define holbl 1 "Short and Healthy" 2 "Short and At Risk" 3 "Medium and Healthy" 4 "Medium and At Risk" 5 "Tall and Healthy" 6 "Tall and At Risk"
label values height_over holbl
tab height_over sex

/* The rationale behind this is to stratify the people who have are overweight and not overweight as it relates to how tall they are. As a tall person, it is interesting to see the distribution of how tall people are and how it relates to overweight. it is interesting to see there are a higher percentage of short females, It should also be noted as a proportion across all heights, women have a more even distribution between healthy and at risk, where men tend to have a higher percentage of overweight individuals. */

*t shirt sizing
gen tshirt_size = .
replace tshirt_size = 1 if chestcircumference_cm < 94
replace tshirt_size = 2 if chestcircumference_cm >= 94 & chestcircumference_cm <= 102
replace tshirt_size = 3 if chestcircumference_cm > 102 & chestcircumference_cm <= 110
replace tshirt_size = 4 if chestcircumference_cm > 110
label define sizelbl 1 "Small" 2 "Medium" 3 "Large" 4 "X-Large"
label values tshirt_size sizelbl
label variable tshirt_size "T-shirt Size Category"

*create a table 1
dtable i.sex age i.branch_num i.bmi_cat i.season i.inst_num i.height_over i.tshirt_size, title("Table 1") note("Basic measurement parameters")
collect style putdocx, layout(autofitcontents)
collect export extable1.docx, replace

*height to hip by sex
gen hip_pct_height = (trochanterionheight_cm / stature) * 100
label variable hip_pct_height "% of total height attributable to hip height"
graph box hip_pct_height, over(sex) ytitle("Percent of Total Height (%)") title("Percent of Height Attributable to Hip Height by Sex")
/* It seems as though hip height is a higher proportion of the total body height for women than it is for men. This means men have a lower waist in general as part of their body plan. In my experience this also shifts the center of mass of the individual and can change what sort of tasks they can perform.*/

*data quality issues
/* So far the data quality issues all look intentionally and methodically placed, and it is an additional puzzle to figure out how he did what he did in order to root out the problems. There are few outliers and only one straight up duplicate. I found some additional outliers when making graphs later, but i found there are few of them that they could still be included in statistical analysis. I did drop them for ease of visual clarity in some graphs.*/

*stature correlation
corr stature_cm chestcircumference_cm hipbreadth_cm functionalleglength_cm span_cm if sex == 2
corr stature_cm chestcircumference_cm hipbreadth_cm functionalleglength_cm span_cm if sex == 1
/* Here we see in these matrices that differences between men and women in stature are small but pronounced. This is paricularly evident in the correlation between hipbreadth_cm and chestcircumference_cm. span_cm and functionalleglength_cm are highly correlated with overall stature. It follows that leg length would contribute to overall height, but it is also true that taller people have longer arms.*/
twoway (scatter span_cm stature_cm, colorvar(sex) colorkeysrange)

*self reported vs measured weight
/* going to have to assume the height in inches and the wieght in lbs is the self reported portion*/
gen srweight = weightlbs * 0.45359237
gen weight_diff = srweight - weightkg
summarize weight_diff, detail
histogram weight_diff if weight_diff >= -30
*I omitted an observation that was too far out of range to be considered in the figure
ttest srweight = weightkg
/* according to this t test, the null hypothesis that the difference between means of self reported weight and measured weight is not zero. In fact, it is clear there is a tendency to overreport weight in the self reported section.*/

*self reported weight by sex
by sex, sort: summarize weight_diff
graph box weight_diff, over(sex)

*self reported height vs measured height
gen srheight = heightin * 2.54
gen height_diff = srheight - stature_cm
summarize height_diff, detail
histogram height_diff

*summarize
/*It looks as though the preconcieved notion that poeople would consistently underreport their weight was off base. There seems to be a bias with people tending to overreport their weight, as we see a prevalence of positive numbers from the difference between self reported and measured weight. This is not reflected by the means however, which show that women tend to underreport their weight more drastically or more often.*/

*compare to created body types
graph box weightkg, over(height_over, label(angle(90)))
/* It should be clear that as height goes up, so does weight. what is striking is that the healthy people from the next height class up tend to weigh less even than the at risk people from the previous height class. this shows that the weight of the individual is more closely ties to their status as overweight than does their height, which speaks positively of bmi as a unit of measure. I am aware that BMI is notoriously a bad unit of measure, but here we see that it is actually doing its job in controlling for height.*/
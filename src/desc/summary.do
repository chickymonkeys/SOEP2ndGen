********************************************************************************
*                                                                              *
* Filename: summary.do                                                         *
* Description: summary statistics from the created dataset of household with   *
*   second-generation migrants.
*                                                                              *
********************************************************************************

* start with summary of head of household demo
u "${DATA_PATH}/hh2genv34soep_hh.dta", clear

label variable female   "\% Female"
label variable married  "\% Married"
label variable employed "\% Employed"
label variable selfemp  "\% Self-Employed"
label variable college  "\% College"
label variable hsdegree "\% High School Degree"
label variable voceduc  "\% Vocational Education"

gen yesrefexp = (arefback == 3) if !missing(arefback)
label variable yesrefexp "\% With Indirect Refugee Experience"
gen r_catholic = (religion == 1) if !missing(religion)
label variable r_catholic "\% Catholic"
gen r_lutheran = (religion == 2) if !missing(religion)
label variable r_lutheran "\% Protestant"
gen r_orthodox = (religion == 3) if !missing(religion)
label variable r_orthodox "\% Orthodox"
gen r_muslim   = (religion == 5) if !missing(religion)
label variable r_muslim "\% Muslim"
gen r_noreli   = (religion == 7) if !missing(religion)
label variable r_noreli "\% No Religious Denomination"

* Household Head Demographics
eststo out1: estpost tabstat age female married employed college ///
    hsdegree voceduc yeduc etecon egp finjob foreignid langspoken ///
    yesrefexp r_* nsibs [aw=phrf], s(mean sd min max count) c(s)

* Household Characteristics
g hnetinc = hghinc
egen aux = rowtotal(hgi?hinc), missing
replace hnetinc = aux if missing(hnetinc)
label variable hnetinc "Monthly Net Household Income, euro"

drop p100h0 e100h0 
egen p010h = rowtotal(p010h?), missing
label variable p010h "HH Prop. Prim. Resid. Market Value (Imputed), euro"
egen p001h = rowtotal(p001h?), missing
label variable p001h "HH Prop. Prim. Resid. Debts (Imputed), euro"
egen e010h = rowtotal(e010h?), missing
label variable e010h "HH Other Real Estate Market Value (Imputed), euro"
egen e001h = rowtotal(e001h?), missing
label variable e001h "HH Other Real Estate Debts (Imputed), euro"
egen w010h = rowtotal(w010h?), missing
label variable w010h "HH Gross Overall Wealth (Imputed), euro"
egen w011h = rowtotal(w011h?), missing
label variable w011h "HH Net Overall Wealth (Imputed), euro"

* Main Household Summary
eststo out3: estpost tabstat hsize nchild owner tenant hgsize hgrent hnetinc ///
    p010h p001h e010h e001h w010h w011h ///
    hasloan_pr mloan_pr hasloan_ot mloan_ot hasloans mloans [aw=hhrf], ///
    s(mean sd min max count) c(s)

* Summary Statistics for the Household Head Demographics
esttab out1 using "${OUT_PATH}/summary/tabs/summary_hh1.tex", replace ///
    cells("mean(fmt(a2)) sd(fmt(a3)) min(fmt(a2)) max(fmt(a2)) count") ///
    collabels(none) label nodep nomti noobs nonum nolines fragment booktabs

* Summary Statistics for the Main Household
esttab out3 using "${OUT_PATH}/summary/tabs/summary_hh3.tex", replace ///
    cells("mean(fmt(a2)) sd(fmt(a3)) min(fmt(a2)) max(fmt(a2)) count") ///
    collabels(none) label nodep nomti noobs nonum nolines fragment booktabs

u "${DATA_PATH}/hh2genv34soep_hp.dta", clear

label variable female_s   "\% Female"
label variable employed_s "\% Employed"
label variable selfemp_s  "\% Self-Employed"
label variable ineduc_s   "\% In Education"
label variable retired_s  "\% Retired"
label variable college_s  "\% College"
label variable hsdegree_s "\% High School"
label variable voceduc_s  "\% Vocational Education"

gen r_catholic_s = (religion_s == 1) if !missing(religion_s)
label variable r_catholic_s "\% Catholic"
gen r_lutheran_s = (religion_s == 2) if !missing(religion_s)
label variable r_lutheran_s "\% Protestant"
gen r_orthodox_s = (religion_s == 3) if !missing(religion_s)
label variable r_orthodox_s "\% Orthodox"
gen r_muslim_s   = (religion_s == 5) if !missing(religion_s)
label variable r_muslim_s "\% Muslim"
gen r_noreli_s   = (religion_s == 7) if !missing(religion_s)
label variable r_noreli_s "\% No Religious Denomination"

g dmig_s  = (migback_s == 2) if !missing(migback_s)
label variable dmig_s "\% Direct Migrants"
g imig_s  = (migback_s == 3) if !missing(migback_s)
label variable imig_s "\% Second-Generation Immigrant"

g stay_s = syear - immiyear_s
label variable stay_s "Length of Stay in Germany, years"

* Household Partner Demographics
eststo out2: estpost tabstat age_s female_s employed_s college_s hsdegree_s ///
    voceduc_s yeduc_s etecon_s egp_s finjob_s ?mig_s stay_s foreignid_s ///
    langspoken_s r_*_s nsibs_s [aw=phrf_s], s(mean sd min max count) c(s)

* Summary Statistics for the Head of Household Partner's Demographics
esttab out2 using "${OUT_PATH}/summary/tabs/summary_hh2.tex", replace ///
    cells("mean(fmt(a2)) sd(fmt(a3)) min(fmt(a2)) max(fmt(a2)) count") ///
    collabels(none) label nodep nomti noobs nonum nolines fragment booktabs

* Head of Household Parents
u "${DATA_PATH}/hh2genv34soep_fathers.dta", clear

label variable fnative   "\% German"
label variable fcollege  "\% College"
label variable fhsdegree "\% High School"

gen r_catholic = (freligion == 1) if !missing(freligion)
label variable r_catholic "\% Catholic"
gen r_lutheran = (freligion == 2) if !missing(freligion)
label variable r_lutheran "\% Protestant"
gen r_orthodox = (freligion == 3) if !missing(freligion)
label variable r_orthodox "\% Orthodox"
gen r_muslim   = (freligion == 5) if !missing(freligion)
label variable r_muslim "\% Muslim"
gen r_noreli   = (freligion == 7) if !missing(freligion)
label variable r_noreli "\% No Religious Denomination"

* Head of Household Father's Demographics
eststo out4: estpost tabstat falive fage fnative fsecgen fcollege ///
    fhsdegree fstay fegp fhsize ffight fhnetinc fhnetwth fhnetincavg ///
    fhnetwthavg r_* [aw=phrf], s(mean sd min max count) c(s)

* Summary Statistics for the Head of Household Partner's Demographics
esttab out4 using "${OUT_PATH}/summary/tabs/summary_hh4.tex", replace ///
    cells("mean(fmt(a2)) sd(fmt(a3)) min(fmt(a2)) max(fmt(a2)) count") ///
    collabels(none) label nodep nomti noobs nonum nolines fragment booktabs

u "${DATA_PATH}/hh2genv34soep_mothers.dta", clear

label variable mnative   "\% German"
label variable mcollege  "\% College"
label variable mhsdegree "\% High School"

gen r_catholic = (mreligion == 1) if !missing(mreligion)
label variable r_catholic "\% Catholic"
gen r_lutheran = (mreligion == 2) if !missing(mreligion)
label variable r_lutheran "\% Protestant"
gen r_orthodox = (mreligion == 3) if !missing(mreligion)
label variable r_orthodox "\% Orthodox"
gen r_muslim   = (mreligion == 5) if !missing(mreligion)
label variable r_muslim "\% Muslim"
gen r_noreli   = (mreligion == 7) if !missing(mreligion)
label variable r_noreli "\% No Religious Denomination"

* Head of Household Mother's Demographics
eststo out5: estpost tabstat malive mage mnative msecgen mcollege ///
    mhsdegree mstay megp mhsize mfight mhnetinc mhnetwth mhnetincavg ///
    mhnetwthavg r_* [aw=phrf], s(mean sd min max count) c(s)

* Summary Statistics for the Head of Household Partner's Demographics
esttab out5 using "${OUT_PATH}/summary/tabs/summary_hh5.tex", replace ///
    cells("mean(fmt(a2)) sd(fmt(a3)) min(fmt(a2)) max(fmt(a2)) count") ///
    collabels(none) label nodep nomti noobs nonum nolines fragment booktabs

* Head of Household Partner Parents
u "${DATA_PATH}/hh2genv34soep_fathers_S.dta", clear

label variable fnative   "\% German"
label variable fcollege  "\% College"
label variable fhsdegree "\% High School"

gen r_catholic = (freligion_s == 1) if !missing(freligion_s)
label variable r_catholic "\% Catholic"
gen r_lutheran = (freligion_s == 2) if !missing(freligion_s)
label variable r_lutheran "\% Protestant"
gen r_orthodox = (freligion_s == 3) if !missing(freligion_s)
label variable r_orthodox "\% Orthodox"
gen r_muslim   = (freligion_s == 5) if !missing(freligion_s)
label variable r_muslim "\% Muslim"
gen r_noreli   = (freligion_s == 7) if !missing(freligion_s)
label variable r_noreli "\% No Religious Denomination"

* Head of Household Partner Father's Demographics
eststo out6: estpost tabstat falive_s fage_s fnative_s fcollege_s ///
    fhsdegree_s fstay_s fegp_s fhsize_s ffight_s fhnetinc_s fhnetwth_s ///
    fhnetincavg_s fhnetwthavg_s r_*  [aw=phrf_s], s(mean sd min max count) c(s)

* Summary Statistics for the Head of Household Partner's Demographics
esttab out6 using "${OUT_PATH}/summary/tabs/summary_hh6.tex", replace ///
    cells("mean(fmt(a2)) sd(fmt(a3)) min(fmt(a2)) max(fmt(a2)) count") ///
    collabels(none) label nodep nomti noobs nonum nolines fragment booktabs

u "${DATA_PATH}/hh2genv34soep_mothers_s.dta", clear

label variable mnative   "\% German"
label variable mcollege  "\% College"
label variable mhsdegree "\% High School"

gen r_catholic = (mreligion_s == 1) if !missing(mreligion_s)
label variable r_catholic "\% Catholic"
gen r_lutheran = (mreligion_s == 2) if !missing(mreligion_s)
label variable r_lutheran "\% Protestant"
gen r_orthodox = (mreligion_s == 3) if !missing(mreligion_s)
label variable r_orthodox "\% Orthodox"
gen r_muslim   = (mreligion_s == 5) if !missing(mreligion_s)
label variable r_muslim "\% Muslim"
gen r_noreli   = (mreligion_s == 7) if !missing(mreligion_s)
label variable r_noreli "\% No Religious Denomination"

* Head of Household Partner Mother's Demographics
eststo out7: estpost tabstat malive_s mage_s mnative_s mcollege_s ///
    mhsdegree_s mstay_s megp_s mhsize_s mfight_s mhnetinc_s mhnetwth_s ///
    mhnetincavg_s mhnetwthavg_s r_*  [aw=phrf_s], s(mean sd min max count) c(s)

* Summary Statistics for the Head of Household Partner's Demographics
esttab out7 using "${OUT_PATH}/summary/tabs/summary_hh7.tex", replace ///
    cells("mean(fmt(a2)) sd(fmt(a3)) min(fmt(a2)) max(fmt(a2)) count") ///
    collabels(none) label nodep nomti noobs nonum nolines fragment booktabs

* Graph?
u "${DATA_PATH}/hh2genv34soep_hh.dta", clear
keep if !missing(hasloans)

preserve
bys ancestry : egen freq = count(hid)
replace ancestry = 1000 if freq < 5
label define ancestry_EN 1000 "[1000] Other", add
levelsof ancestry, local(levels)
foreach l in `levels' {
    local aux : label ancestry_EN `l'
    local aux = subinstr("`aux'", "[`l'] ", "", 1)
    label define ancestry_EN `l' "`aux'", modify
}

bys ancestry : egen aux = total(freq)
replace freq = aux if ancestry == 1000
collapse (mean) freq [pw=phrf], by(ancestry)
graph bar freq, over(ancestry, label(angle(90) labsize(vsmall)) ///
    gap(*.2) sort(freq) descending) blabel(bar, position(outside) ///
    orientation(vertical) format(%9.0g) size(vsmall) gap(*.1)) ///
    yla(#10, labsize(vsmall)) ytitle("Frequency", size(small))
graph export "${OUT_PATH}/summary/graphs/freq_total.pdf", replace
restore

preserve
collapse (count) hid, by(ancestry syear)
xtset ancestry syear
bys ancestry : egen aux = max(hid)
keep if aux > 5

local splot "scatter hid syear"
local opt "mlabel(ancestry) mlabs(tiny) msiz(tiny)"
levelsof ancestry, local(levels)
qui sum ancestry, meanonly
local not = `r(min)'
local levels : list levels - not
local aux "(`splot' if (syear == 2013 & ancestry == `not'), `opt')"
qui sum syear, meanonly
local counter = `r(min)'
foreach i in `levels' {
    local aux = "`aux' (`splot' if (syear==`counter' & ancestry==`i'), `opt')"
    qui sum syear, meanonly
    if `counter' == `r(max)' {
        local counter = `r(min)'
    } 
    else {
        local counter = `counter' + 1
    }
}
qui sum syear, meanonly
xtline hid, overlay legend(off) xla(`r(min)'(2)`r(max)', angle(45) labsize(vsmall)) yla(#20,labsize(vsmall)) xtitle(,size(small)) ytitle(,size(small)) addplot(`aux')
restore

preserve 
bys ancestry syear : egen freq = count(hid)
collapse (mean) freq [pw=phrf], by(ancestry syear)
levelsof ancestry, local(levels)
reshape wide freq, i(syear) j(ancestry)
local not "2"
local levels : list levels - not
egen cumfreq2 = rowtotal(freq2)
local pointer = 2
foreach i in `levels' {
    egen cumfreq`i' = rowtotal(cumfreq`pointer' freq`i')
    local pointer = `i'
}

drop freq*
unab listvars : cumfreq*
local count: word count `listvars'
forvalues i = `count'(-1)1 {
    local aux : word `i' of `listvars'
    if `i' == `count' {
        local stacked = "area `aux' syear"
    } 
    else {
         local stacked = "`stacked' || area `aux' syear"
    }
}

qui sum syear, meanonly
twoway `stacked', yla(#10, labsize(vsmall)) yt("Frequency", size(small)) ///
    xla(`r(min)'(2)`r(max)', labsize(vsmall)) xt("Year", size(small)) ///
    legend(off)
graph export "${OUT_PATH}/summary/graphs/freq_stack_area.pdf", replace
restore

preserve
collapse (count) hid, by(syear)
graph bar hid, over(syear, label(angle(45) labsize(vsmall)) gap(*.1)) ///
    blabel(bar, position(outside) orientation(vertical) format(%9.0g) ///
    size(vsmall) gap(*.1)) yla(#10, labsize(vsmall)) ///
    ytitle("Frequency", size(small))
graph export "${OUT_PATH}/summary/graphs/freq_years.pdf", replace
restore

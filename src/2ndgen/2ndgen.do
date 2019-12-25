********************************************************************************
*                                                                              *
* Filename: 2ndgen.do                                                          *
* Description: .do file to create the longitudinal series of second-generation *
*   migrants at individual level retrieving information from the different     *
*   datasets included in the German Socio-Economic Panel                       *
*                                                                              *
********************************************************************************

loc filename = "2ndgen"

********************************************************************************
* Log Opening and Settings                                                     *
********************************************************************************

* open log file
capture log using "${LOG_PATH}/${DIR_NAME}_`filename'_${T_STRING}", text replace

********************************************************************************
* First Step: Tracking Data in ppathl .dta file and generated dataset (pgen)   *
********************************************************************************

u "${SOEP_PATH}/ppathl.dta", clear
keep pid syear corigin* mig* aref* germborn*

* indirect migration background implies born in Germany from immigrant parents
*   but it does not imply German nationality or citizenship
count if migback == 3 & germborn != 1 & corigin != 1

* keep if and only if indirect migration background is recorded
keep if migback == 3

* retrieve from person generated dataset
mer 1:1 pid syear using "${SOEP_PATH}/pgen.dta", ///
    keepus(pgnation) keep(match) nogen

* retrieve pgnation for indirect migration background
*   excluding German, Ex-Jugoslavian and No-Nationality
g aux1 = pgnation if ///
    pgnation > 1 & ///
    pgnation != 3 & pgnation != 98
    
* get last wave where pgnation is available after controls
bys pid: egen maxyear = max(syear) if !missing(aux1)
* save last available value of pgnation
g aux2 = aux1 if syear == maxyear
* copy mode of pgnation for all waves
bys pid: egen aux3 = mode(aux1)
* copy last available value of pgnation for all waves
bys pid: egen aux4 = mode(aux2)
* subsitute for last available value of pgnation if same frequency
replace aux3 = aux4 if missing(aux3)
* retrieve pgnation when there is Ex-Jugoslavia as the only option
g aux5 = pgnation if pgnation == 3
* copy Ex-Jugoslavia if still missing
bys pid: egen aux6 = mode(aux5)
* replace when Ex-Jugoslavia is the only option
replace aux3 = aux6 if missing(aux3)

g ancestry1 = aux3
keep pid syear ancestry*

********************************************************************************
* Second-Fifth Step: Include Nationality/Citizenship and Country Born In +     *
*   Country of Second Nationality from the long raw dataset (pbrutto)          *
********************************************************************************

mer 1:1 pid syear using "${SOEP_PATH}/pbrutto.dta", ///
    keepus(pnat* pherkft) keep(match) nogen

* create wildcards for the variables of interest
local stubvar = "pnat_v1 pnat_v2 pnat2 pherkft"
local n: word count `stubvar'

tokenize "`stubvar'"
forvalues i = 1/`n' {

    * retrieve variable for indirect migration background
    *   excluding German, Ex-Jugoslavian, No-Nationality, Unknown, ex-GDR
    *   ethnic minorities, Non-German Category (pnat_v2)
    g aux`i'1 = ``i'' if ///
        ``i'' > 1 & ///
        ``i'' != 3 & ``i'' != 98 & ///
        ``i'' != 7 & ``i'' != 9 & ///
        ``i'' != 777 & ``i'' != 999
    
    * get last wave where stubs is available after controls
    bys pid: egen maxyear`i' = max(syear) if !missing(aux`i'1)
    g aux`i'2 = aux`i'1 if syear == maxyear`i'
    
    * count frequencies of the variable by pid
    bys pid: egen aux`i'3 = mode(aux`i'1)
    * copy last recorded value of variable by pid
    bys pid: egen aux`i'4 = mode(aux`i'2)
    * subsitute for last available value if same frequency
    replace aux`i'3 = aux`i'4 if missing(aux`i'3)
    * Ex-Jugoslavia sub-classification not available
    g aux`i'5 = ``i'' if ``i'' == 3
    bys pid: egen aux`i'6 = mode(aux`i'5)
    replace aux`i'3 = aux`i'6 if missing(aux`i'3)
}

g ancestry2 = aux13
replace ancestry2 = aux23 if (ancestry2 == 3 & ///
    (!missing(aux23) & aux23 > 3)) | missing(ancestry2)
g ancestry5 = aux33
keep pid syear ancestry*

********************************************************************************
* Third-Fifth Step: Include Previous Nationality and Country Born In + Country *
*   of Second Nationality from the longitudinal person dataset (pl) and from   *
*   the Wave S Second Nationality variable (sp11702)
********************************************************************************

mer 1:1 pid syear using "${SOEP_PATH}/pl.dta", ///
    keepus(plj0018 plf0011 plj0023) keep(match) nogen

* TODO: Finish It!
mer 1:1 pid syear using "${SOEP_PATH_RAW}/sp.dta", ///
    keepus(sp11702) keep(match) nogen

* exclude Other Country labelled for Country Born In in pl.dta
replace plf0011 = -2 if plf0011 == 7
local stubvar = "plj0018 plf0011 plj0023"
local n: word count `stubvar'
tokenize "`stubvar'"

forvalues i = 1/`n' {
    * retrieve variable for indirect migration background
    *   excluding German, Ex-Jugoslavian, No-Nationality, Ex-GDR
    g aux`i'1 = ``i'' if ///
        ``i'' > 1 & ///
        ``i'' != 3 & ``i'' != 7 & ``i'' != 98
    
    * get last wave where stubs is available after controls
    bys pid: egen maxyear`i' = max(syear) if !missing(aux`i'1)
    g aux`i'2 = aux`i'1 if syear == maxyear`i'
    
    * count frequencies of the variable by pid
    bys pid: egen aux`i'3 = mode(aux`i'1)
    * copy last recorded value of variable by pid
    bys pid: egen aux`i'4 = mode(aux`i'2)
    * subsitute for last available value if same frequency
    replace aux`i'3 = aux`i'4 if missing(aux`i'3)
    * Ex-Jugoslavia sub-classification not available
    g aux`i'5 = ``i'' if ``i'' == 3
    bys pid: egen aux`i'6 = mode(aux`i'5)
    replace aux`i'3 = aux`i'6 if missing(aux`i'3)
}

g ancestry3 = aux13
replace ancestry3 = aux23 if (ancestry3 == 3 & ///
    (!missing(aux23) & aux23 > 3)) | missing(ancestry3)
replace ancestry5 = aux33 if (ancestry5 == 3 & ///
    (!missing(aux33) & aux33 > 3)) | missing(ancestry5)
keep pid syear ancestry*

********************************************************************************
* Fourth Step: Information provided by Household Head on the citizenships of   *
*   children that were living in the household from children dataset (kidlong) *
********************************************************************************

* merge 1:1 pid syear using "${SOEP_PATH}/kidlong.dta", ///
*     keepus(k_nat) nogen

* apparently we do not retrieve any additional information from the
* parents' questionnaire on the kids, for the single waves A and E




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
    keepus(pgnation) keep(master match) nogen

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
* substitute for last available value of pgnation if same frequency
replace aux3 = aux4 if missing(aux3)
* retrieve pgnation when there is Ex-Jugoslavia as the only option
g aux5 = pgnation if pgnation == 3
* copy Ex-Jugoslavia if still missing
bys pid: egen aux6 = mode(aux5)
* replace when Ex-Jugoslavia is the only option
replace aux3 = aux6 if missing(aux3)

g ancestry1 = aux3
* also keep corigin for the sixth step and for the label
keep pid syear ancestry*

********************************************************************************
* Second-Fifth Step: Include Nationality/Citizenship and Country Born In +     *
*   Country of Second Nationality from the long raw dataset (pbrutto)          *
********************************************************************************

mer 1:1 pid syear using "${SOEP_PATH}/pbrutto.dta", ///
    keepus(pnat* pherkft) keep(master match) nogen

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
    * substitute for last available value if same frequency
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
*   of Second Nationality from the longitudinal person dataset (pl)            *
*   This step includes the variable sp11702 from SOEP Wave S                   *
********************************************************************************

mer 1:1 pid syear using "${SOEP_PATH}/pl.dta", ///
    keepus(plj0018 plf0011 plj0023) keep(master match) nogen

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
    * substitute for last available value if same frequency
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

merge 1:1 pid syear using "${SOEP_PATH}/kidlong.dta", ///
     keepus(k_nat) keep(master match) nogen

* retrieve variable for indirect migration background
*   excluding German, Ex-Jugoslavian and No-Nationality
g aux1 = k_nat if ///
    k_nat > 1 & ///
    k_nat != 3 & k_nat != 98

* get last wave where k_nat is available after controls
bys pid: egen maxyear = max(syear) if !missing(aux1)
* save last available value of k_nat
g aux2 = aux1 if syear == maxyear

* copy mode of k_nat for all waves
bys pid: egen aux3 = mode(aux1)
* copy last available value of k_nat for all waves
bys pid: egen aux4 = mode(aux2)
* substitute for last available value of k_nat if same frequency
replace aux3 = aux4 if missing(aux3)
* retrieve k_nat when there is Ex-Jugoslavia as the only option
g aux5 = k_nat if k_nat == 3
* copy Ex-Jugoslavia if still missing
bys pid: egen aux6 = mode(aux5)
* replace when Ex-Jugoslavia is the only option
replace aux3 = aux6 if missing(aux3)

g ancestry4 = aux3
keep pid syears ancestry*

********************************************************************************
* Sixth-Seventh Step: Cross-Checking the Countries of Birth and Nationalities. *
*   mentioned in the different waves (from A to J) to see whether they deviate *
*   from the main country of birth corigin and the previous nationalities.     *
********************************************************************************

local stubs = "a b c d e f g h i j"
local vars1 = "ap61 bp89 cp92 dp94 ep87b fp107b gp107 hp107 ip107 jp107"
local vars2 = ///
    "ap62a bp98a cp98ab dp95a ep88a fp105a gp105a hp105a ip105a jp105a"

local n: word count `stubs'

tokenize "`stubs'"
forvalues i = 1/`n' {
    * merge single wave info about nationality
    merge 1:1 pid syear using "${SOEP_PATH_RAW}/``i''p.dta", ///
    keepus(`: word `i' of `vars1'') keep(master match) nogen
    * merge single wave info about country of origin
    merge 1:1 pid syear using "${SOEP_PATH_RAW}/``i''pausl.dta", ///
    keepus(`: word `i' of `vars2'') keep(master match) nogen
}

egen nat_raw = rowtotal(`vars1'), m
* compare with corigin ()
egen cborn_raw = rowtotal(`vars2'), m

local stubs = "nat cborn"
foreach i in `stubs' {
    * retrieve variable for indirect migration background
    *   excluding German, Ex-Jugoslavian, No-Nationality and ex-GDR
    g aux_`i'_1 = `i'_raw if ///
        `i' > 1 & `i' != 3 & `i' != 98 & `i' != 7

    * get last wave where the variable is available after controls
    bys pid: egen maxyear_`i' = max(syear) if !missing(aux_`i'_1)
    * save last available value of the considered variable
    g aux_`i'_2 = aux_`i'_1 if syear == maxyear_`i'

    * count frequencies of the variable by pid
    bys pid: egen aux_`i'_3 = mode(aux_`i'_1)
    * copy last recorded value of variable by pid
    bys pid: egen aux_`i'_4 = mode(aux_`i'_2)
    * substitute for last available value if same frequency
    replace aux_`i'_3 = aux_`i'_4 if missing(aux_`i'_3)
    * Ex-Jugoslavia sub-classification not available
    g aux_`i'_5 = `i'_raw if `i'_raw == 3
    bys pid: egen aux_`i'_6 = mode(aux_`i'_5)
    replace aux_`i'_3 = aux_`i'_6 if missing(aux_`i'_3)

    rename aux_`i'_3 `i'

}
rename (nat cborn) (ancestry6 ancestry7)
keep pid syear ancestry*

********************************************************************************
* Eighth Step: Cross-Generational Linking with the bioparen datasets.          *
********************************************************************************
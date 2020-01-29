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
* Log Opening Programs, and Settings                                           *
********************************************************************************

* open log file
capture log using "${LOG_PATH}/${DIR_NAME}_`filename'_${T_STRING}", text replace

********************************************************************************
* Program: sgenmode                                                            *
* Description: this program allows us to identify from a variable containing   *
*   nationality, citizenship, or other information about ancestry the validity *
*   of the information and to copy it for the different waves starting from    *
*   the information of migration background in ppathl, which is retroactive.   *
*   In particular, we are trying to split Ex-Yugoslavia and Eastern Europe     *
*   from the general information, filtering for non-relevant flags. We         *
*   preserve the most recurrent information between the waves or, in case of   *
*   equivalent frequency, the most recent information.                         *
********************************************************************************
capture program drop sgenmode
program define sgenmode
    version 10
    #delimit ;
    syntax varlist(min=1 max=1), 
        GENerate(name) i(varlist min=1 max=1) t(varlist min=1 max=1);

    capture confirm variable `t';
    if _rc {;
        di as error "the option t() must be the existent wave variable.";
        error 198;
    };

    capture confirm variable `i';
    if _rc {;
        di as error "the option p() must be the existent key variable.";
        error 198;
    };

    confirm new var `generate';
    tempvar aux1 aux2 aux3 aux4 aux5 aux6 maxyear;
    * retrieve variable for indirect migration background;
    *   excluding German, Ex-Yugoslavian, No-Nationality, Unknown, ex-GDR;
    *   ethnic minorities, Non-German Category (pnat_v2);
    g `aux1' = `varlist' if
        `varlist'  > 1   & 
        `varlist' != 3   & `varlist' != 98   &
        `varlist' != 7   & `varlist' != 8    & `varlist' != 9 & 
        `varlist' != 777 & `varlist' != 999; 
    * get last wave where the indicated variable is available (after controls);
    bys `i' : egen `maxyear' = max(`t') if !missing(`aux1');
    g `aux2' = `aux1' if `t' == `maxyear';
    * count frequency of the variable grouping for the key panel component;
    bys `i' : egen `aux3' = mode(`aux1');
    * copy the last recorded value of the indicated variable;
    *   grouping for the key panel component;
    bys `i' : egen `aux4' = mode(`aux2');
    * substitute for the last available value if same frequency;
    replace `aux3' = `aux4' if missing(`aux3');
    * Ex-Yugoslavia sub-classification not available;
    g `aux5' = `varlist' if `varlist' == 3;
    * copy Ex-Yugoslavia if still missing;
    bys `i' : egen `aux6' = mode(`aux5');
    * replace when Ex-Yugoslavia is the only option;
    replace `aux3' = `aux6' if missing(`aux3');

    * output variable;
    g `generate' = `aux3';
    #delimit cr
end

********************************************************************************
* Step 1: Tracking Data in ppathl .dta file and generated dataset (pgen) to    *
*   identify whether individuals with indirect migration background have a     *
*   foreign nationality that points to their country of ancestry.              *
********************************************************************************

u "${SOEP_PATH}/ppathl.dta", clear
keep pid syear corigin* mig* germborn* arefback

* indirect migration background implies born in Germany from immigrant parents
*   but it does not imply German nationality or citizenship
count if migback == 3 & germborn != 1 & corigin != 1

* keep if and only if indirect migration background is recorded
keep if migback == 3

* decode the refugee experience indicator variable
replace arefback = . if arefback < 0

* retrieve from person generated dataset
mer 1:1 pid syear using "${SOEP_PATH}/pgen.dta", ///
    keepus(pgnation) keep(master match) nogen

* run the ad-hoc program on pgnation
sgenmode pgnation, gen(ancestry1) i(pid) t(syear)
keep pid syear ancestry* arefback

********************************************************************************
* Step 2 (5): Include Nationality/Citizenship and Country Born In + Country of *
*   Second Nationality from the long raw dataset (pbrutto).                    *
********************************************************************************

mer 1:1 pid syear using "${SOEP_PATH}/pbrutto.dta", ///
    keepus(pnat* pherkft) keep(master match) nogen

* create wildcards for the variables of interest
local stubvar = "pnat_v1 pnat_v2 pnat2 pherkft"
local n: word count `stubvar'
tokenize "`stubvar'"
forvalues i = 1/`n' {
    * run the ad-hoc program for each variable identifying nationality,
    *   citizenship and country born in from pbrutto
    sgenmode ``i'', gen(temp`i') i(pid) t(syear)
}

g ancestry2 = temp1
replace ancestry2 = temp2 if (ancestry2 == 3) & ///
    (!missing(temp2) & temp2 > 3) | missing(ancestry2)
g ancestry5 = temp3
keep pid syear ancestry* arefback

********************************************************************************
* Step 3 (5): Include Previous Nationality and Country Born In + Country of    *
*   Second Nationality from the longitudinal person dataset (pl).              *
*   This step includes the variable sp11702 from SOEP Wave S.                  *
********************************************************************************

mer 1:1 pid syear using "${SOEP_PATH}/pl.dta", ///
    keepus(plj0018 plf0011 plj0023) keep(master match) nogen

* exclude Other Country labelled for Country Born In in pl.dta
replace plf0011 = -2 if plf0011 == 7
local stubvar = "plj0018 plf0011 plj0023"
local n: word count `stubvar'

tokenize "`stubvar'"
forvalues i = 1/`n' {
    sgenmode ``i'', gen(temp`i') i(pid) t(syear)
}

g ancestry3 = temp1
replace ancestry3 = temp2 if (ancestry3 == 3 & ///
    (!missing(temp2) & temp2 > 3)) | missing(ancestry3)
replace ancestry5 = temp3 if (ancestry5 == 3 & ///
    (!missing(temp3) & temp3 > 3)) | missing(ancestry5)
keep pid syear ancestry* arefback

********************************************************************************
* Step 4: Information provided by Household Head on the citizenships of        *
*   that were living in the household from children dataset (kidlong).         *
********************************************************************************

merge 1:1 pid syear using "${SOEP_PATH}/kidlong.dta", ///
     keepus(k_nat) keep(master match) nogen

sgenmode k_nat, gen(ancestry4) i(pid) t(syear)

********************************************************************************
* Step 6-7: Cross-Checking the Countries of Birth and Nationalities mentioned  *
*   in the different waves (from A to J) to see whether they deviate from the  *
*   main country of birth and the previous nationalities.                      *
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

egen nat = rowtotal(`vars1'), m
egen cborn = rowtotal(`vars2'), m

local counter = 6
foreach var of varlist nat cborn {
    sgenmode `var', gen(ancestry`counter') i(pid) t(syear)
    local counter = `counter' + 1
}

* save the dataset to open bioparen
keep pid syear ancestry* arefback
tempfile temp
save `temp'

********************************************************************************
* Step 8: Cross-Generational Linking with the bioparen datasets in order to    *
*   retrieve the country of origin of the parents from the variable ?origin    *
*   which gives the country of ancestry for the second-generation individual   *
*   (maternal ancestry > paternal ancestry), and same procedure where country  *
*   of origin is not available.                                                *
********************************************************************************

u "${SOEP_PATH}/bioparen.dta", clear
keep persnr bioyear ?nr ?nat ?origin
rename (persnr bioyear) (pid syear)

* merge using the previously assembled dataset
merge 1:m pid syear using `temp', keep(using match) nogen

local stubs = "nr nat origin"
local gender = "f m"
foreach g in `gender' {
    * copy variable records for all the waves available,
    *   before and after the biological survey year (not long)
    foreach var in `stubs' {
        bys pid: egen aux = total(`g'`var'), missing
        drop `g'`var'
        rename aux `g'`var'
    }
    * generate indicator variable for native parent
    g `g'native = (`g'origin == 1 | `g'origin == 7)
    replace `g'native = . if missing(`g'origin)
    *  missing key if parents are not part of the study
    replace `g'nr = . if `g'nr < 1
}

* second-generation immigrants take the country of ancestry from the mother
g ancestry8 = morigin if !missing(morigin) & ///
    morigin > 1 & morigin != 7 & morigin != 8 & morigin != 9 & ///
    morigin != 98 & morigin != 777 & morigin != 999

* if missing, take the country of ancestry from the father
replace ancestry8 = forigin if missing(ancestry8) & ///
    morigin > 1 & morigin != 7 & morigin != 8 & morigin != 9 & ///
    morigin != 98 & morigin != 777 & morigin != 999

keep pid syear ?nr ancestry? ?native arefback

foreach g in `gender' {
    preserve
    * only keep the keys for linkable parent in the SOEP
    rename (pid `g'nr) (kchild pid)
    keep if !missing(pid)
    duplicates drop pid, force
    keep pid

    * merge information from the long key dataset
    mer 1:m pid using "${SOEP_PATH}/ppathl.dta", ///
        keepus(syear corigin migback immiyear) keep(match) nogen

    * if the parent has a direct migration background copy the recorded
    *   country of origin as the country of ancestry 
    g `g'anclink = corigin if !missing(corigin) & ///
        migback == 2 & corigin > 0 
    * prepare a dummy if the parent is second-generation itself
    g `g'secgen = (migback == 3) if !missing(migback)
    * prepare a variable that indicates parent's immigration year
    g `g'immiyear = immiyear if !missing(immiyear) & immiyear > 0
    * replace second-generation indicator if immiyear is not missing
    replace `g'secgen = 0 if !missing(`g'immiyear)

    * First Step : variable pgnation in pgen dataset
    mer 1:1 pid syear using "${SOEP_PATH}/pgen.dta", ///
        keepus(pgnation) keep(master match) nogen

    sgenmode pgnation, gen(temp1) i(pid) t(syear)
    * save linkable parent ancestry from pgnation
    *   in case of indirect migration background of the parent
    replace `g'anclink = temp1 if missing(`g'anclink)
    drop temp*

    * Second-Fifth Step: Nationality/Country Born In + 2nd Nationality
    mer 1:1 pid syear using "${SOEP_PATH}/pbrutto.dta", ///
        keepus(pnat* pherkft) keep(master match) nogen
    
    * create wildcards for the variables of interest
    local stubvar = "pnat_v1 pnat_v2 pnat2 pherkft"
    local n: word count `stubvar'

    tokenize "`stubvar'"
    forvalues i = 1/`n' {
        * run the ad-hoc program for each variable identifying nationality,
        *   citizenship and country born in from pbrutto
        sgenmode ``i'', gen(temp`i') i(pid) t(syear)
    }

    replace `g'anclink = temp1 if missing(`g'anclink)
    replace `g'anclink = temp2 if (`g'anclink == 3 & ///
        (!missing(temp2) & temp2 > 3)) | missing(`g'anclink)
    g save5 = temp3
    drop temp*

    * Third-Fifth Step: Previous Nationality and Country Born In
    *   + Second Nationality from the big longitudinal personal dataset
    mer 1:1 pid syear using "${SOEP_PATH}/pl.dta", ///
    keepus(plj0018 plf0011 plj0023) keep(master match) nogen

    * exclude Other Country labelled for Country Born In in pl
    replace plf0011 = -2 if plf0011 == 7
    local stubvar = "plj0018 plf0011 plj0023"
    local n: word count `stubvar'

    tokenize "`stubvar'"
    forvalues i = 1/`n' {
        * run the ad-hoc program for each variable identifying
        *   previous nationality and country born in + second nationality
        sgenmode ``i'', gen(temp`i') i(pid) t(syear)
    }

    replace `g'anclink = temp1 if missing(`g'anclink)
    replace `g'anclink = temp2 if (`g'anclink == 3 & ///
        (!missing(temp2) & temp2 > 3)) | missing(`g'anclink)
    replace save5 = temp3 if (temp3 == 3 & ///
        (!missing(temp3) & temp3 > 3)) | missing(save5)
    replace `g'anclink = temp3 if missing(`g'anclink)
    drop temp*

    * Skip Step Fourth (not plausible) and go to Step Sixth
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

    egen nat = rowtotal(`vars1'), m
    egen cborn = rowtotal(`vars2'), m

    local stubvar = "nat cborn"
    local n: word count `stubvar'

    tokenize "`stubvar'"
    forvalues i = 1/`n' {
        sgenmode ``i'', gen(temp`i') i(pid) t(syear)
    }

    replace `g'anclink = temp2 if missing(`g'anclink)
    replace `g'anclink = temp1 if missing(`g'anclink)

    duplicates drop pid, force
    rename (pid) (`g'nr)
    keep `g'nr `g'anclink `g'secgen `g'immiyear
    tempfile `g'postbio
    save ``g'postbio'
    restore
    
}

* merging the linking information and sort
merge m:1 fnr using `fpostbio', keep(master match) nogen
merge m:1 mnr using `mpostbio', keep(master match) nogen
sort pid syear
* replace parental information about ancestry with mother's
*   country of origin from the linking where missing
replace ancestry8 = manclink if (ancestry8 == 3 & ///
    !missing(manclink) & manclink > 3) | (ancestry8 == 222 & ///
    (!missing(manclink) & manclink != 222)) | missing(ancestry8)
* replace parental information about ancestry with father's when
*   mother's information is also missing from the linking
replace ancestry8 = fanclink if (ancestry8 == 3 & ///
    !missing(fanclink) & fanclink > 3) | (ancestry8 == 222 & ///
    (!missing(fanclink) & fanclink != 222)) | missing(ancestry8)

* correct native indicator if there is an immigration year
replace fnative = 0 if !missing(fimmiyear)
replace mnative = 0 if !missing(mimmiyear)

* Start Merging of the different steps
g ancestry = ancestry1

forvalues i = 2/8 {
    * replace in sequence from the information we found before
    replace ancestry = ancestry`i' if (ancestry == 3 & ///
        (!missing(ancestry) & ancestry > 3)) | (ancestry == 222 & ///
        (!missing(ancestry) & ancestry != 222)) | missing(ancestry)
}

* Final corrections Ex-Yugoslavia = Serbia, Eastern Europe = Poland
replace ancestry = 165 if ancestry == 3
replace ancestry = 22  if ancestry == 222

* Merge Benelux with Belgium
replace ancestry = 117 if ancestry == 12
* Merge Chechnya with Mother Russia
replace ancestry = 32  if ancestry == 188

* correct for no nationality residuals eventually
drop if ancestry == 98

* retrieve pgnation to copy the label
merge 1:1 pid syear using "${SOEP_PATH}/pgen.dta", ///
    keepus(pgnation) keep(master match) nogen
label copy pgnation ancestry
label values ancestry ancestry
label language EN
label copy pgnation_EN ancestry_EN
label values ancestry ancestry_EN

label variable ancestry  "Country of Ancestry"
label variable fnative   "Father is German"
label variable mnative   "Mother is German"
label variable fsecgen   "Father is Second-Generation Immigrant"
label variable msecgen   "Mother is Second Generation Immigrant"
label variable fimmiyear "Last Year of Immigration to Germnay of Father"
label variable mimmiyear "Last year of Immigration to Germany of Mother"

label language DE

* There are some intra-regions like Kurdistan, Chechnya
order pid syear ancestry arefback ?native ?secgen ?immiyear
keep  pid syear ancestry arefback ?native ?secgen ?immiyear
drop if missing(ancestry)

label data "SOEP v34 Panel of Second-Generation Individuals with Ancestry"
compress
save "${DATA_PATH}/2ndgenindv34soep.dta", replace

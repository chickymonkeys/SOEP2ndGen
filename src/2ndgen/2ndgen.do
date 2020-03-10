********************************************************************************
*                                                                              *
* Filename: 2ndgen.do                                                          *
* Description: .do file to create the longitudinal series of second-generation *
*   migrants at individual level retrieving information from the different     *
*   datasets included in the German Socio-Economic Panel.                      *
*                                                                              *
********************************************************************************

loc filename = "2ndgen"

********************************************************************************
* Log Opening, Programs, and Settings                                          *
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
    keepus(plj0018 plf0011_v1 plf0011_v2 plj0023) keep(master match) nogen

egen plf0011 = rowtotal(plf0011_v1 plf0011_v2)
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

mer 1:1 pid syear using "${SOEP_PATH}/kidlong.dta", ///
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
    mer 1:1 pid syear using "${SOEP_PATH_RAW}/``i''p.dta", ///
    keepus(`: word `i' of `vars1'') keep(master match) nogen
    * merge single wave info about country of origin
    mer 1:1 pid syear using "${SOEP_PATH_RAW}/``i''pausl.dta", ///
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
mer 1:m pid syear using `temp', keep(using match) nogen

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
    keepus(plj0018 plf0011_v1 plf0011_v2 plj0023) keep(master match) nogen

    egen plf0011 = rowtotal(plf0011_v1 plf0011_v2)
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
        mer 1:1 pid syear using "${SOEP_PATH_RAW}/``i''p.dta", ///
        keepus(`: word `i' of `vars1'') keep(master match) nogen
        * merge single wave info about country of origin
        mer 1:1 pid syear using "${SOEP_PATH_RAW}/``i''pausl.dta", ///
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
mer m:1 fnr using `fpostbio', keep(master match) nogen
mer m:1 mnr using `mpostbio', keep(master match) nogen
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

tempfile temp
save `temp'

********************************************************************************
* Retrieve the parents' length of stay in Germany and their age, using the     *
*   spell dataset of migration for 2013-2015 Waves, the latest year of         *
*   immigration, the year of birth and death from the biographical dataset and *
*   some correction using the year of birth in the tracking dataset.           *
********************************************************************************

* analyse the migration spell data containing the migration history of a 
*   subset of 2013-2015 Wave individuals, to find out whether the parent has
*   been in Germany before the recorded immigration year in the tracking dataset
u "${SOEP_PATH}/migspell.dta", clear
* recode missing flags for the variables of interest
mvdecode starty move nspells mignr, mv(-8/-1 = .)
* copy the year after the current line, overlapping does not matter
g yearafter = starty[_n+1]
* calculate the difference between the starting year of the spell and
*   the consecutive move if parent has move to Germany from another country
*   (in n years format)
bys pid : g aux1 = yearafter - starty if move == 1
* generate index of number of total moves
g aux2 = nspells - 1
* shift the number of years in aux1 if it is not the last move to Germany
g aux3 = aux1 if aux2 != mignr
* calculate the total years of stay in Germany before settling
bys pid : egen addyears = total(aux3)
keep pid addyears
duplicates drop pid, force
* merge with the exit dataset to see whether some people are still alive
*   but they have migrated from Germany to recover the last spell year
mer 1:m pid using "${SOEP_PATH}/pbr_exit.dta", keepus(yperg ylint syear)
mvdecode yperg ylint, mv(-8/-1 = .)
g lastyear = ylint if yperg == 5 & ylint != 0
* assume that last year is the survey year if no ylint
replace lastyear = syear if yperg == 5 & missing(lastyear) 
* it is safe to keep one observation of the identifier to
*   preserve the last available year before moving from Germany
duplicates drop pid if _m == 2, force
keep pid addyears lastyear
tempfile migspell_exit
save `migspell_exit', replace

local gender = "f m"
foreach g in `gender' {
    u "${SOEP_PATH}/bioparen.dta", clear
    * retrieve year of birth and death for the parent
    local varlist = "`g'nr `g'ybirth `g'ydeath"
    * clean missing values
    mvdecode `varlist', mv(-8/-1 = .)
    keep persnr `varlist'
    rename persnr pid

    preserve
    * save parents year of birth, death and child identifier
    *   when there is no link with the survey
    keep if missing(`g'nr)
    tempfile `g'nopid
    save ``g'nopid'
    restore
   
    * drop parent with no key
    drop if missing(`g'nr)
    drop pid
    rename `g'nr pid
    * keep parent key, year of birth and death
    duplicates drop pid, force

    * look for matches with the created migration and exit history dataset
    mer 1:1 pid using `migspell_exit', keep(master match) nogen
    
    * correct inconsistencies in year of birth using the tracking dataset
    mer 1:m pid using "${SOEP_PATH}/ppathl.dta", ///
        keepus(gebjahr) keep(master match) nogen
    mvdecode gebjahr, mv(-8/-1 = .)
    * year of birth in the tracking dataset is preferred
    replace `g'ybirth = gebjahr ///
        if missing(`g'ybirth) | (`g'ybirth != gebjahr & !missing(gebjahr))
    * collapse to keep all the variables for pid
    collapse (mean) `g'ybirth `g'ydeath addyears lastyear, by(pid)
    rename pid `g'nr
    * merge back to the biographical dataset to get the child identifier
    *   one parent may correspond to more children
    mer 1:m `g'nr using "${SOEP_PATH}/bioparen.dta", ///
        keepus(persnr) keep(match) nogen
    rename persnr pid

    * append back the parents not in the survey with biographical information
    append using ``g'nopid'
    * merge back to the children dataset
    mer 1:m pid using `temp', keep(using match) nogen

    ****************************************************************************
    *    parent's age : missing if parent is dead or missing year of birth     *
    ****************************************************************************

    * age is survey year minus year of birth, when the parent is not dead
    *   in case he is not dead the value is missing, so +inf
    g `g'age = syear - `g'ybirth if syear <= `g'ydeath
    * generate a dummy equal to one whether the parent is alive
    g `g'alive = (!missing(`g'age)) & (!missing(`g'ybirth))

    ****************************************************************************
    *                    parent's length of stay calculation                   *
    ****************************************************************************

    sort pid syear
    * find first and last year in the survey for the children
    bys pid : egen maxyear = max(syear)
    bys pid : egen minyear = min(syear)
    * if there is no ending year from the migration spell data, the last year
    *   is simply given by the survey year of the last wave of the children
    replace lastyear = maxyear if missing(lastyear)
    * if the parent is dead before the last year, replace the date
    replace lastyear = `g'ydeath if `g'ydeath < lastyear
    * replace missing additional years to zero for the summation
    replace addyears = 0 if missing(addyears)
    * counter starting from zero that increases the length of stay
    bys pid : g counter1 = syear - minyear
    * incremental counter for the presence in the survey
    bys pid : g counter2 = _n
    * starting length of stay in Germany, which is given by the difference 
    *   between the year of exit/death and the immigration year if the former
    *   happens to be before the first survey year of the children, otherwise
    *   the difference between the first survey year and immigration year
    g styear  = cond(lastyear <= minyear, ///
        lastyear - `g'immiyear, minyear - `g'immiyear)
    * create the pointer at which the counting of additional years of stay
    *   should stop: a) save the array cell at which the survey year is the
    *   year of exit/death or the first cell if the year of exit/death is
    *   before the entrance of the children in the panel; b) check that the
    *   pointer exists, otherwise check whether there is a jump in the panel;
    *   c) copy the pointer for each survey year of the children.
    g aux = counter2 ///
        if lastyear == syear | (syear == minyear & lastyear <= minyear)
    bys pid : replace aux = counter2 if missing(aux) & ///
        (lastyear[_n] < syear[_n] & lastyear[_n-1] > syear[_n-1])
    bys pid : egen pointer = total(aux)
    * calculate length of stay = years before last migration to Germany +
    *   + starting length of stay + additional years when children in survey
    g `g'stay = addyears + styear + counter1
    * stop counting at the pointed cell of the pid array
    bys pid : replace `g'stay = `g'stay[pointer] if syear > lastyear | ///
        (!missing(pointer) & (syear == minyear & lastyear <= minyear))
    drop counter* pointer aux addyears lastyear styear minyear maxyear
    tempfile temp
    save `temp'
}

********************************************************************************
* Final Corrections, Nationality Approximation and Labeling Steps              *
********************************************************************************

* Final corrections Ex-Yugoslavia = Serbia, Eastern Europe = Poland
replace ancestry = 165 if ancestry == 3
replace ancestry = 22  if ancestry == 222

* merge Benelux with Belgium
replace ancestry = 117 if ancestry == 12
* merge Chechnya with Mother Russia
replace ancestry = 32  if ancestry == 188
* merge Albania with Kosovo-Albania
replace ancestry = 140 if ancestry == 75

* correct for no nationality residuals eventually
drop if ancestry == 98

* retrieve pgnation to copy the label
mer 1:1 pid syear using "${SOEP_PATH}/pgen.dta", ///
    keepus(pgnation) keep(master match) nogen
label copy pgnation ancestry
label values ancestry ancestry
label language EN
label copy pgnation_EN ancestry_EN
label values ancestry ancestry_EN

label variable ancestry  "Country of Ancestry"
label variable fnative   "1 = Father is German"
label variable mnative   "1 = Mother is German"
label variable fsecgen   "1 = Father is Second-Generation Immigrant"
label variable msecgen   "1 = Mother is Second Generation Immigrant"
label variable fimmiyear "Last Year of Immigration to Germnay of Father"
label variable mimmiyear "Last year of Immigration to Germany of Mother"
label variable fstay     "Father Length of Stay in Germany, years"
label variable mstay     "Mother Length of Stay in Germany, years"
label variable fage      "Father's Current Age"
label variable mage      "Mother's Current Age"
label variable falive    "1 = Father is still alive"
label variable malive    "1 = Mother is still alive"
label variable fybirth   "Father's Year of Birth"
label variable mybirth   "Mother's Year of Birth"
label variable fydeath   "Father's Year of Death"
label variable mydeath   "Mother's Year of Death"
label language DE

* There are some intra-regions like Kurdistan, Chechnya
order pid syear ancestry arefback ?native ?secgen ///
    ?immiyear ?stay ?age ?alive ?ybirth ?ydeath
keep  pid syear ancestry arefback ?native ?secgen ///
    ?immiyear ?stay ?age ?alive ?ybirth ?ydeath
drop if missing(ancestry)

label data "SOEP Panel of Second-Generation Individuals with Ancestry"
compress
save "${DATA_PATH}/SOEP2ndGen.dta", replace

********************************************************************************
* Closing Commands                                                             *
********************************************************************************

capture log close

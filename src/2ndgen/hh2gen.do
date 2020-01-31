********************************************************************************
*                                                                              *
* Filename: hh2gen.do                                                          *
* Decription: .do file to generate all the demographics and relevant variables *
*   both at household level and at individual level when possible of the       *
*   identified second-generation head of household (as assigned), indicated    *
*   partner and the immigrant parents of the head of household from the        *
*   different datasets included in the German Socio-Economic Panel.            *
*                                                                              *
********************************************************************************

loc filename = "hh2gen"

********************************************************************************
* Log Opening Programs, and Settings                                           *
********************************************************************************

* open log file
capture log using "${LOG_PATH}/${DIR_NAME}_`filename'_${T_STRING}", text replace

********************************************************************************
* Step 1: starting from the second-generation panel, we want to retrieve the   *
*   household identifier for each individual in this panel, to identify all    *
*   the individuals belonging to that household.                               *
********************************************************************************

* use the second-generation panel
u "${DATA_PATH}/2ndgenindv34soep.dta", clear
merge 1:1 pid syear using "${SOEP_PATH}/ppathl.dta", ///
    keepus(hid) keep(match) nogen
duplicates drop hid, force
keep hid

* filter the tracking dataset by hid retrieving the unique identifiers
*   and retrieve refugee background
merge 1:m hid using "${SOEP_PATH}/ppathl.dta",                               ///
    keepus(                                                                  ///
        pid syear hid cid parid     /* unique identifiers and survey year */ ///
        sex gebjahr gebmonat piyear /* gender and variables for age       */ ///
     ) keep(match) nogen

* add information of indirect ancestry for whom in the household is
*   second-generation, later we will record it also for direct migrants
merge 1:1 pid syear using "${DATA_PATH}/2ndgenindv34soep.dta", ///
    keep(master match) nogen

********************************************************************************
* Step 2: calculate age. From pgen we get the month of the interview, we use   *
*   it to compare with month of birth and, together with year of interview and *
*   year of birth, we obtain the actual age at time of interview. Where month  *
*   is missing, we just use the year of survey or year of interview.           *
********************************************************************************

* from pgen we get the month of the interview, but we cannot match 
*   all the individuals in the sample
merge 1:1 pid syear using "${SOEP_PATH}/pgen.dta", ///
    keepus(pgmonth) keep(master match) nogen    
* replace negative flags in the variables indicating month and year of birth
*   and month and year of interview + substitute year of interview with
*   survey year when missing
replace gebjahr  = .     if gebjahr  < 0
replace gebmonat = .     if gebmonat < 0
replace pgmonth  = .     if pgmonth  < 0
replace piyear   = .     if piyear   < 0
replace piyear   = syear if missing(piyear)
* generate age using interview timing and year and month of birth
g age = piyear - gebjahr if gebmonat < pgmonth
replace age = piyear - gebjahr - 1 if gebmonat >= pgmonth
replace age = piyear - gebjahr     if missing(pgmonth) | missing(gebmonat)

* fix gender
g female = (sex == 2) if !missing(sex) | !inlist(sex, -1, -3)

********************************************************************************
* Step 3: some demographics. Marital Status, Occupation, Education, Religion.  *
********************************************************************************

* retrieve some information about employment and education from the pgen
merge 1:1 pid syear using "${SOEP_PATH}/pgen.dta",                         ///
    keepus(                                                                ///
        pgfamstd  /* marital status in survey year                      */ ///
        pgstib    /* occupational position                              */ ///
        pgemplst  /* employment status                                  */ ///
        pglfs     /* labour force status                                */ ///
        pgbilzeit /* amount of education or training in years (see tab) */ ///
        pgisced97 /* ISCED-1997 classification of education             */ ///
        pgpsbil   /* school-leaving degree level                        */ ///
        pgpsbila  /* school-leaving degree level outside DE             */ ///
        pgpsbilo  /* school-leaving degree level GDR                    */ ///
        pgpbbila  /* vocational degree outside DE                       */ ///
        pgpbbil01 /* type of vocational degree (if any)                 */ ///
        pgpbbil02 /* type of college degree (if any)                    */ ///
        pgpbbil03 /* type of non vocational degree                      */ ///
        pgfield   /* field of tertiary degree (if any)                  */ ///
        pgdegree  /* type of tertiary degree (if any)                   */ ///
        pgtraina  /* apprenticeship - two-digit occupation (KLDB92)     */ ///
        pgtrainb  /* vocational school - two-digit occupation (KLDB92)  */ ///
        pgtrainc  /* higher voc. school - two-digit occupation (KLDB92) */ ///
        pgtraind  /* civ. servant train - two-digit occupation (KLDB92) */ ///
        pgisco?8  /* ISCO-88(08) Industry Classification                */ ///
        pgegp88   /* Last Reached EGP Value (Erikson et al. 1979, 1983) */ ///
        pgnace    /* industry occupation (NACE 1.1)                     */ ///
    ) keep(master match) nogen

* married and not separated, or registered same-sex relationship
* there is some lack of information about marriage status
g married = (pgfamstd == 1 | pgfamstd > 5) ///
    if !missing(pgfamstd) | (pgfamstd < 0 & pgfamstd != 2)

* employment indicator variable from employment and labour force status
g employed = (pgemplst != 5) ///
    if !missing(pgemplst) & !inlist(pgemplst, -1, -3)
* self-employed indicator variable
g selfemp = inrange(pgstib, 410, 433) ///
    if !missing(pgstib) & !inlist(pgstib, -1, -3)
* civil servant indicator variable 
g civserv = inrange(pgstib, 550, 640) ///
    if !missing(pgstib) & !inlist(pgstib, -1, -3)
* in education indicator variable from occupational position
g ineduc = (pgstib == 11) ///
    if !missing(pgstib) & !inlist(pgstib, -1, -3)
* retirement indicator, some individuals are pre-65 retired
g retired = (pgstib == 13) ///
    if !missing(pgstib) & !inlist(pgstib, -1, -3)

* education in years is available only for those who studied in Germany (?)
g yeduc = pgbilzeit if !inlist(pgbilzeit, -1, -2) & !missing(pgbilzeit)

* college degree information for Germany is messy, so I am using the
*   clear ISCED97 classification provided in the dataset
g college = (inlist(pgisced97, 5, 6)) if !missing(pgisced97)
* abitur is high school degree at the end of gymnasium
g hsdegree = (college == 1 | pgisced97 == 4) if !missing(pgisced97)
* vocational education for Germany is also messy, so I am using ISCED97
*   including middle vocational and higher vocational education
g voceduc = (inlist(pgisced97, 3, 4)) if !missing(pgisced97)
* business and economics related education or training, we use the different
*   categories in apprenticeship, vocational training and civil service training
*   together with the type of tertiary education
local stubvar = "a b c d"
foreach i in `stubvar' {
    g aux`i' = (                                                            ///
        inrange(pgtrain`i', 6700, 6709) | inrange(pgtrain`i', 6910, 6919) | ///
        inrange(pgtrain`i', 7040, 7049) | inrange(pgtrain`i', 7530, 7545) | ///
        inrange(pgtrain`i', 7711, 7739) | inrange(pgtrain`i', 8810, 8819) | ///
        inlist(pgtrain`i', 7501, 7502, 7503, 7511, 7512,                    ///
            7513, 7572, 7854, 7855, 7856)                                   ///
    ) if !missing(pgtrain`i') & !inlist(pgtrain`i', -1, -3)
}

g aux0 = inlist(pgfield, 29, 30, 31) ///
    if !missing(pgfield) & !inlist(pgfield, -1, -3)
* education or training in financial-related subjects
egen etecon = rowmax(aux0 auxa auxb auxc auxd)
drop aux?

* job prestige classification : the lower the better (?)
*   we use EGP Scale (Erikson et al. 1983) because it is the most complete info
g egp = pgegp88 if !missing(pgegp88) & pgegp88 > 0

* finance-related job based on ISCO codes
g finjob = (inlist(pgisco88, 1231, 2410, 2411, 2419, 2441, 3429, 4121, ///
    4122, 4214, 4215) | inrange(pgisco88, 3410, 3413) | inrange(pgisco88, ///
    3419, 3421) | inlist(pgisco08, 1211, 1346, 2631, 3311, ///
    3312, 3334, 4213, 4214, 4312) | inlist(pgnace, 65, 66, 67, 70))

* keep just the generated variables and the refugee background
drop pg* sex gebmonat piyear

* open the individual long dataset to retrieve some variables
merge 1:1 pid syear using "${SOEP_PATH}/pl.dta",                     ///
    keepus(                                                          ///
        plh0258_h /* religion background of the individual        */ ///
        plj0078   /* feeling german 1 to 5                        */ ///
        plj0080   /* connected with the country of origin 1 to 5  */ ///
        plj0082   /* feeling of not belonging 1 to 5              */ ///
        plj0083   /* feel at home in the country of origin 1 to 5 */ ///
        plj0085   /* wish to remain in Germany permanently 1 to 5 */ ///
        plj0077   /* usual language spoken three levels           */ ///
    ) keep(master match) nogen

* religion is available only for some waves, assume it is religion background
gen aux1 = plh0258_h if plh0258_h > 0 | plh0258_h == 11
bys pid : egen maxyear = max(syear) if !missing(aux1)
g aux2 = aux1 if syear == maxyear
bys pid : egen aux3 = mode(aux1)
bys pid : egen aux4 = mode(aux2)
replace aux3 = aux4 if missing(aux3)

g religion = 1 if aux3 == 1
replace religion = 2 if aux3 == 2
replace religion = 3 if aux3 == 7
replace religion = 4 if aux3 == 3
replace religion = 5 if inlist(aux3, 4, 8, 9, 10)
replace religion = 6 if aux3 == 5
replace religion = 7 if aux3 == 6

label language EN
label define religion_EN 1 "Catholic" 2 "Protestant" 3 "Orthodox" ///
  4 "Christian Others" 5 "Muslim" 6 "Other Religion" 7 "No Denomination"
label values religion religion_EN
label variable religion "Religious Group"
label language DE

drop aux* maxyear plh0258_h

* recode missing values in the qualitative german identity variables
local varlist = "plj0078 plj0080 plj0082 plj0083 plj0085 plj0077"
mvdecode `varlist', mv(-8/-1 = .)

* the variables are scaled from one to five, the higher the less german
egen foreignid = rowmedian(plj0078 plj0080 plj0082 plj0083 plj0085)
* copy the usual language spoken in another variable
g langspoken = plj0077

drop plj*

********************************************************************************
* Step 4: Identification of the head of household as defined in the GSOEP,     *
*   household information from the individual level for relevant members in    *
*   the households (excluding kids, still in education or retired).            *
********************************************************************************

* the head of the household is defined as the person who knows best about
*   the general conditions under which the household acts and is supposed
*   to answer this questionnaire in each given year
merge 1:1 pid syear using "${SOEP_PATH}/pbrutto.dta", ///
    keepus(stell_h) keep(master match) nogen

* we do have a problem here that also comes from the previous step: missing
*   individuals in pgen are also missing in pbrutto, we are going to drop them
*   since we do not have useful information to exploit
drop if missing(stell_h)

* exclude if household head is not second-generation
g flag_h = (stell_h == 0 & !missing(ancestry))
bys hid syear : egen aux = total(flag_h)
keep if aux == 1
drop flag_h aux

* exclude if household head is underage, still in education or retired
g flag_h = (stell_h == 0 & (ineduc == 1 | retired == 1))
bys hid syear : egen aux = total(flag_h)
keep if aux == 0
drop flag_h aux

* calculate the number of household members
bys hid syear : egen hsize = count(pid)
* calculate the number of underage in the household
g aux = (age < 18)
bys hid syear : egen nchild = total(aux)
drop aux

********************************************************************************
* Step 5: Information of current parents' household, splitting between mother  *
*   and father for each individual, in terms of size of current parent's       *
*   household, current net labour income and current net wealth (available     *
*   inputed only for waves 2002, 2007, and 2012).                              *
*   Note: it is possible to gain those information just for parents that are   *
*   still in the survey, where for net income and wealth of dead households we *
*   consider the average over the available years.                             *
********************************************************************************

* we save the current dataset to avoid the memory leak that we have to solve
*   in Linux when running the whole script coming to pl

preserve

keep pid
duplicates drop pid, force
tempfile temp
save `temp', replace

local stubvar = "f m"
foreach i in `stubvar' {
    * open parents' biographical dataset
    u "${SOEP_PATH}/bioparen.dta", clear

    * keep only if it is possible to link the parent
    keep persnr `i'nr
    keep if `i'nr > 0 & !missing(`i'nr)
    rename persnr pid

    * keep parent identifier just for  the relevant households
    merge 1:1 pid using `temp', keep(match) nogen
    keep `i'nr
    rename `i'nr pid
    duplicates drop pid, force

    * retrieve current household identifier for the parent
    merge 1:m pid using "${SOEP_PATH}/ppathl.dta", ///
        keepus(hid syear) keep(match) nogen
    drop if hid < 0
    duplicates drop hid syear, force
    rename pid `i'nr

    * calculate parent's current household size
    merge 1:m hid syear using "${SOEP_PATH}/ppathl.dta", ///
        keepus(pid) keep(match) nogen
    bys hid syear : egen `i'hsize = count(pid)
    collapse (mean) `i'hsize `i'nr, by(hid syear) 

    * retrieve household weights
    merge 1:1 hid syear using "${SOEP_PATH}/hpathl.dta", ///
        keepus(hhrf) keep(master match) nogen
    * retrieve imputations of parent's current household net income
    merge 1:1 hid syear using "${SOEP_PATH}/hgen.dta", ///
        keepus(hghinc hgi?hinc) keep(master match) nogen
    * retrieve imputations of parent's current household net wealth
    merge 1:1 hid syear using "${SOEP_PATH}/hwealth.dta", ///
        keepus(w011h?) keep(master match) nogen
    * fix imputation names
    rename hgi?hinc hgihinc?
    rename (w011h?) (w011h1 w011h2 w011h3 w011h4 w011h5)

    * reshape for the five imputations
    reshape long hgihinc w011h, i(hid syear) j(imp)
    * part of the net income is imputed, the other part is not
    *   and correct for flagged implausible values of net income 
    mvdecode hgihinc hghinc w011h, mv(-8/-1 = .)
    * apply household weights and average for imputations
    collapse (mean) `i'nr `i'hsize hghinc hgihinc w011h ///
        [pw=hhrf], by(hid syear imp)
    collapse `i'nr `i'hsize hghinc hgihinc w011h, by(hid syear)

    g `i'hnetinc = hgihinc
    replace `i'hnetinc = hghinc if missing(`i'hnetinc) 
    g `i'hnetwth = w011h

    * averaging household net income and net wealth
    bys hid : egen `i'hnetincavg = mean(`i'hnetinc)
    bys hid : egen `i'hnetwthavg = mean(`i'hnetwth)

    rename hid `i'hid
    keep `i'nr syear `i'hsize `i'hnetinc* `i'hnetwth* `i'hid
    tempfile `i'temp
    save ``i'temp', replace
}

restore

rename pid persnr
* retrieve parents' identifiers from biographical information
merge m:1 persnr using "${SOEP_PATH}/bioparen.dta", ///
    keepus(fnr mnr) keep(master match) nogen
mvdecode ?nr, mv(-8/-1 = .)

* for each parent, merge the household information
local stubvar = "f m"
foreach i in `stubvar' {
    preserve
    keep if missing(`i'nr)
    tempfile `i'nopid
    save ``i'nopid', replace
    restore

    drop if missing(`i'nr)

    * it is many-to-many because one parent can have multiple children in the
    *   survey and his household exists years before the children's household
    merge m:m `i'nr syear using ``i'temp', keep(master match) nogen
    * re-attach individuals without parent in the survey
    append using ``i'nopid' 
} 

rename persnr pid

* create identifier if there are both parents and are in the same household
g psamehh = (fhid == mhid) if !missing(fhid) & !missing(mhid)

********************************************************************************
* Step 6: Retrieve the remaining information about parents from the biographical *
*   dataset, where information about parents is generated from parents within  *
*   the survey and self-reported information by the interviewed individuals.   *
********************************************************************************

preserve
* retrieve the number of siblings for each individual 
u "${SOEP_PATH}/bioparen.dta", clear
keep persnr sibl nums numb

* count siblings in the parental information
g auxs = nums if nums >= 0
replace auxs = 0 if sibl == 0
g auxb = numb if numb >= 0
replace auxb = 0 if sibl == 0
egen nsibs = rowtotal(auxs auxb), missing

keep persnr nsibs
rename persnr pid
tempfile temp
save `temp', replace
restore

* merge back the siblings information
merge m:1 pid using `temp', keep(master match) nogen
tempfile temp
save `temp', replace

local stubvar = "f m"
foreach i in `stubvar' {
    * open the biographical dataset to save the parent's demographics
    u "${SOEP_PATH}/bioparen.dta", clear
    local varlist = "`i'ybirth `i'nr `i'ydeath `i'reli `i'sedu `i'egp `i'fight"
    mvdecode `varlist', mv(-8/-1 = .)
    keep persnr `varlist'
    * create a religion categorical variable like the other
    *   and copy the variable label just later
    g `i'religion = 1 if `i'reli == 1
    replace `i'religion = 2 if `i'reli == 2
    replace `i'religion = 3 if `i'reli == 3
    replace `i'religion = 4 if `i'reli == 7
    replace `i'religion = 5 if `i'reli == 4
    replace `i'religion = 6 if `i'reli == 5
    replace `i'religion = 7 if `i'reli == 6
    * initialise the parent's college and high school degree indicators
    g `i'college = (`i'sedu == 4) if !missing(`i'sedu)
    g `i'hsdegree = (`i'college == 1 | `i'sedu == 3) if !missing(`i'sedu)

    preserve
    * we save the not linkable parents in a separate tempfile
    keep if missing(`i'nr)
    rename persnr pid
    tempfile `i'nopid
    save ``i'nopid', replace
    restore

    * drop the previously saved parents without the identifier
    drop if missing(`i'nr)
    * keep just the parent identifier
    duplicates drop `i'nr, force
    rename `i'nr pid

    * retrieve education if parent is in the survey
    merge 1:m pid using "${SOEP_PATH}/ppathl.dta", ///
        keepus(syear) keep(match) nogen
    merge 1:1 pid syear using "${SOEP_PATH}/pgen.dta", ///
        keepus(pgisced97 pgpsbil) keep(match) nogen
    * cleanup missing flags
    mvdecode pgisced97 pgpsbil, mv(-8/-1 = .)

    * find the highest level of education achieved and save it
    bys pid : egen maxyear1 = max(syear) if !missing(pgisced97)
    bys pid : egen maxyear2 = max(syear) if !missing(pgpsbil)
    g aux1 = pgisced97 if syear == maxyear1
    g aux2 = pgpsbil   if syear == maxyear2
    bys pid : egen aux3 = total(aux1)
    bys pid : egen aux4 = total(aux2)
    * compare the last education level with the one in the biographical dataset
    replace `i'college  = ///
        (inlist(aux3, 5, 6) | aux4 == 4) if missing(`i'college)
    replace `i'hsdegree = ///
        (`i'college == 1 | aux3 == 4 | aux4 == 3) if missing(`i'hsdegree)
    drop aux? maxyear? pgisced97 pgpsbil syear
    * all information recorded is supposed to be time-constant
    *   or the latest updated information at least, so we can drop duplicates
    duplicates drop pid, force
    rename (pid persnr) (`i'nr pid)

    preserve
    * analyse the migration spell data containing the migration history of a
    *   subset of individuals to find out whether the parent has been in
    *   Germany before the recorded immigration year in the tracking dataset
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
    merge 1:m pid using "${SOEP_PATH}/pbr_exit.dta", keepus(yperg ylint syear)
    mvdecode yperg ylint, mv(-8/-1 = .)
    g lastyear = ylint if yperg == 5 & ylint != 0
    * assume that last year is the survey year if no ylint
    replace lastyear = syear if yperg == 5 & missing(lastyear) 
    * it is safe to keep one observation of the identifier to
    *   preserve the last available year before moving from Germany
    duplicates drop pid if _m == 2, force
    keep pid addyears lastyear
    rename pid `i'nr
    tempfile migspell_exit
    save `migspell_exit', replace
    restore

    * look for matches with the created migration and exit history dataset
    merge 1:1 `i'nr using `migspell_exit', keep(master match) nogen
    * append back the parents not in the survey with biographical information
    append using ``i'nopid'

    * merge back to the big dataset using children identifiers
    merge 1:m pid using `temp', keep(using match) nogen

    * calculate approximative parent age using year of birth,
    *   year of death (if any) and current survey year
    g `i'age = syear - `i'ybirth ///
        if (!missing(`i'ydeath) & syear <= `i'ydeath) | missing(`i'ydeath)

    *********************************************************************
    * parent length of stay calculation when the parent is an immigrant *
    *********************************************************************
    sort pid syear
    * find first and last year in the survey for the children
    bys pid : egen maxyear = max(syear)
    bys pid : egen minyear = min(syear)
    * if there is no ending year from the migration spell data, the last year
    *   is simply given by the survey year of the last wave of the children
    replace lastyear = maxyear if missing(lastyear)
    * if the parent is dead before the last year, replace the date
    replace lastyear = `i'ydeath if `i'ydeath < lastyear
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
        lastyear - `i'immiyear, minyear - `i'immiyear)
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
    g `i'stay = addyears + styear + counter1
    * stop counting at the pointed cell of the pid array
    bys pid : replace `i'stay = `i'stay[pointer] if syear > lastyear | ///
        (!missing(pointer) & (syear == minyear & lastyear <= minyear))

    drop counter* pointer aux addyears lastyear styear minyear maxyear
    
    save `temp', replace
}

* generate a dummy if the parent is alive
g falive = (!missing(fage))
g malive = (!missing(mage))

order pid syear *hid cid parid ?nr *age gebjahr female ancestry arefback ///
    ineduc civserv selfemp employed retired *religion *college *hsdegree ///
    yeduc voceduc finjob etecon married foreignid langspoken stell_h ///
    nchild ?stay *hsize psamehh *hnetinc *hnetwth *hnetincavg *hnetwthavg ///
    nsibs ?alive ?native ?secgen *egp ?fight
keep pid syear *hid cid parid ?nr *age gebjahr female ancestry arefback ///
    ineduc civserv selfemp employed retired *religion *college *hsdegree ///
    yeduc voceduc finjob etecon married foreignid langspoken stell_h ///
    nchild ?stay *hsize psamehh *hnetinc *hnetwth *hnetincavg *hnetwthavg ///
    nsibs ?alive ?native ?secgen *egp ?fight

********************************************************************************
* Step 7: Reverse all the information in one household row in order to merge   *
*   the current household informaiton given the second-generation head of      *
*   household from the aggregated datasets. (we keep just the partner)         *
********************************************************************************

* TODO: I put the corigin and migback at the beginning, so you already
* have them at this point, remember to remove them for the head of household

preserve
* temporary save the variables we want to keep from the partner
rename (*age gebjahr female ancestry arefback ineduc civserv selfemp ///
    employed retired *religion *college *hsdegree yeduc voceduc finjob ///
    etecon foreignid langspoken ?stay ?hsize psamehh ?hnetinc ?hnetwth ///
    ?hnetincavg nsibs ?alive ?native ?secgen *egp ?fight) (*age_s gebjahr_s ///
    female_s ancestry_s arefback_s ineduc_s civserv_s selfemp_s ///
    employed_s retired_s *religion_s *college_s *hsdegree_s yeduc_s ///
    voceduc_s finjob_s etecon_s foreignid_s langspoken_s ?stay_s ?hsize_s ///
    psamehh_s ?hnetinc_s ?hnetwth_s ?hnetincavg_s nsibs_s ?alive_s ///
    ?native_s ?secgen_s *egp_s ?fight_s)
keep pid syear *_s
tempfile partners
save `partners'
restore

* keep only the head of household
keep if stell_h == 0
* replace partner identifier when there is no partner
mvdecode parid, mv(-8/-1 = .)
drop stell_h

preserve
* save households with no partners
keep if missing(parid)
tempfile nopartners
save `nopartners'
restore

* rename partner id for the merge
rename (pid parid) (pid_h pid)
* we keep only heads of household with the partner
drop if missing(pid)

* retrieve country of origin and migration background for the partner
merge 1:1 pid syear using "${SOEP_PATH}/ppathl.dta", ///
    keepus(corigin migback immiyear) keep(match) nogen
* include all the demographics for the spouse from the big dataset
merge 1:1 pid syear using `partners', keep(match) nogen

* integrate ancestry when the spouse is not a second-generation
mvdecode immiyear corigin migback 
replace ancestry_s = corigin if migback != 3
rename (migback immiyear pid_h pid) (migback_s immiyear_s pid parid)

* reintegrate households where there is not a partner
append using `nopartners'

sort pid syear

********************************************************************************
* Step 8: Obtain the key household level data of debt, income and wealth.      *
********************************************************************************

* what if we try to look at the intergenerational transmission of debt?

* obtain specific household weights
merge 1:1 hid syear using "${SOEP_PATH}/hpathl.dta", ///
    keepus(hhrf) keep(match) nogen
* obtain household generated variables
merge 1:1 hid syear using "${SOEP_PATH}/hgen.dta",          ///
    keepus(                                                 ///
        hgnuts1  /* NUTS1 Federal State Level            */ ///
        hgowner  /* Houseowner or Tenant 5 Levels        */ ///
        hghinc   /* Monthly Net Household Income         */ ///
        hgi?hinc /* Monthly Net Household Income Imputed */ ///
        hgrent   /* Amount of Rent minus Heating Costs   */ ///
        hgsize   /* Size of Housing Unit in m2           */ ///
    ) keep(master match) nogen

* clean missing values, keep income imputed
mvdecode hgnuts1 hghinc hgi?hinc hgowner hgrent hgsize, mv(-8/-1 = .)
* house owner or tenant dummies
g owner  = (hgowner == 1) if !missing(hgowner)
g tenant = (hgowner != 1) if !missing(hgowner)

merge 1:1 hid syear using "${SOEP_PATH}/hwealth.dta",    ///
    keepus(                                              ///
        p100h0 /* HH Prop. Prim. Resid. Filter Yes/No */ ///
        p010h? /* HH Prop. Prim. Resid. Mkt. Value    */ ///
        p001h? /* HH Prop. Prim. Resid. Debts         */ ///
        e100h0 /* HH Other Real Estate Filter Yes/No  */ ///
        e010h? /* HH Other Real Estate Market Value   */ ///
        e001h? /* HH Other Real Estate Debts          */ ///
        w011h? /* HH Net Overall Wealth               */ ///
        w010h? /* HH Gross Overall Wealth             */ ///
    ) keep(master match) nogen

* hl/hlf0085_h mortgage, interest previous year until 1994?
merge 1:1 hid syear using "${SOEP_PATH}/hl.dta",                             ///
    keepus(                                                                  ///
        hlf0087_h /* HH Still Owes Money on Loan/Mortgage Prim. Resid.    */ ///
        hlf0088_h /* HH Monthly Mortgage and Interest Payment Prim. Resid */ ///
        hlc0177   /* Loan, Mortgage or Interest Payments on Leased Prop.  */ ///
        hlc0112_h /* Amount of Loan or Mortgage on Leased Property        */ ///
        hlc0113   /* Loan Payoff for Big Expenses other than Real Estate  */ ///
        hlc0114_h /* Monthly Repayment for Loans other than Real Estate   */ ///
        hlc0126   /* Monthly Repayment of the previous in Germany         */ ///
        hlc0128   /* Amount of Monthly Repayment in Germany               */ ///
        hlc0127   /* Monthly Repayment of the previous Abroad             */ ///
        hlc0129   /* Amount of Monthly Repayment Abroad                   */ ///
    ) keep(master match) nogen

g hasloan_pr = (owner == 1 & hlf0087_h == 1) if !missing(hlf0087_h)
g mloan_pr = hlf0088_h
mvdecode mloan_pr, mv(-8/-1 = .)

g hasloan_ot = 1 if hlc0113 == 1
g hasloan_ot = 0 if hlc0113 == 0
g mloan_ot = hlc0114_h
mvdecode mloan_ot, mv(-8/-1 = .)

g mloans 

* hlc0177 is crap in our dataset, we have poor information
* same for monthly repayments in or outside Germany
drop hlf* hlc*

********************************************************************************

compress
save "${DATA_PATH}/hh2genv34soep.dta", replace

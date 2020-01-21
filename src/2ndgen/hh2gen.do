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
merge 1:m hid using "${SOEP_PATH}/ppathl.dta", ///
    keepus(pid syear parid sex gebjahr hid cid gebmonat piyear) ///
    keep(match) nogen

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
merge 1:1 pid syear using "${SOEP_PATH}/pgen.dta", ///
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
    g aux`i' = ( ///
        inrange(pgtrain`i', 6700, 6709) | inrange(pgtrain`i', 6910, 6919) | ///
        inrange(pgtrain`i', 7040, 7049) | inrange(pgtrain`i', 7530, 7545) | ///
        inrange(pgtrain`i', 7711, 7739) | inrange(pgtrain`i', 8810, 8819) | ///
        inlist(pgtrain`i', 7501, 7502, 7503, 7511, 7512, ///
            7513, 7572, 7854, 7855, 7856) ///
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

* keep just the generated variables
drop pg* sex gebmonat piyear

* acquire religion or church for the single individuals (harmonised) from pl
merge 1:1 pid syear using "${SOEP_PATH}/pl.dta", ///
   keepus(plh0258_h) keep(master match) nogen
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

drop aux* plh0258_h

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

save "${DATA_PATH}/temp.dta", replace


* parents demographics trial
* start to retrieve information about the parents' current household

* temporary to avoid the mess in Linux with pl
use "${DATA_PATH}/temp.dta", clear

* work only on fathers
preserve
keep pid
duplicates drop pid, force
tempfile temp
save `temp'
* open parents' biographical dataset
u "${SOEP_PATH}/bioparen.dta", clear

* keep only if it is possible to link the parent
keep persnr fnr
keep if fnr > 0
rename persnr pid
merge 1:1 pid using `temp', keep(match) nogen
keep fnr
rename fnr pid
* multiple pid because you have multiple children so?
* work only with fathers id
duplicates drop pid, force
* save household identifier for the parent
merge 1:m pid using "${SOEP_PATH}/ppathl.dta", keepus(hid syear) keep(match) nogen
drop syear
drop if hid < 0
duplicates drop hid, force
rename pid fnr
* calculate parent's current household size
merge 1:m hid using "${SOEP_PATH}/ppathl.dta", keepus(pid syear) keep(match) nogen
bys hid syear : egen fhsize = count(pid)
collapse (mean) fnr fhsize, by(hid syear)

* retrieve household weights
merge 1:1 hid syear using "${SOEP_PATH}/hpathl.dta",  keepus(hhrf) keep(master match) nogen
* retrieve imputations of parent's current household net income
merge 1:1 hid syear using "${SOEP_PATH}/hgen.dta", keepus(hghinc hgi?hinc) keep(master match) nogen
* retrieve imputations of parent's current household net wealth
merge 1:1 hid syear using "${SOEP_PATH}/hwealth.dta", keepus(w011h?) keep(master match) nogen

rename hgi?hinc hgihinc?
rename (w011h?) (w011h1 w011h2 w011h3 w011h4 w011h5)

* reshape for the five imputations
reshape long hgihinc w011h, i(hid syear) j(imp)

* part of the net income is imputed, the other part is not
replace hgihinc = . if hgihinc < 0
replace hghinc =  . if hghinc  < 0

* apply household weights and average for imputations
collapse (mean) fnr fhsize hghinc hgihinc w011h [pw=hhrf], by(hid syear imp)
collapse fnr fhsize hghinc hgihinc w011h, by(hid syear)

g fhnetinc = hgihinc
replace fhnetinc = hghinc if missing(fhnetinc)
g fhnetwth = w011h

* averaging household net income and net wealth
bys hid : egen fhnetincavg = mean(fhnetinc)
bys hid : egen fhnetwthavg = mean(fhnetwth)

rename hid fhid
keep fhid syear fnr fhsize fhnetinc* fhnetwth*
tempfile ftemp
save `ftemp'
restore

rename pid persnr
merge m:1 persnr using "${SOEP_PATH}/bioparen.dta", keepus(fnr) keep(master match) nogen
preserve
drop if fnr < 0 | missing(fnr)
tempfile fnopid
save `fnopid'
restore
keep if fnr > 0 & !missing(fnr)
merge m:m fnr syear using `ftemp', keep(master match) nogen









preserve

keep pid
duplicates drop pid, force
tempfile temp
save `temp'

local stubvar = "f m"
foreach i in `stubvar' {
    * open parents' biographical dataset
    u "${SOEP_PATH}/bioparen.dta", clear

    * keep only if it is possible to link the parent
    keep persnr `i'nr
    keep if `i'nr > 0
    rename persnr pid

    * keep just individuals in the relevant households
    merge 1:1 pid using `temp', keep(match) nogen
    rename (pid `i'nr) (kchild pid)

    * retrieve current household identifier for the parent
    merge 1:m pid using "${SOEP_PATH}/ppathl.dta", ///
        keepus(hid syear) keep(match) nogen
    drop pid syear
    drop if hid < 0
    duplicates drop hid, force
    
    * calculate parent's current household size
    merge 1:m hid using "${SOEP_PATH}/ppathl.dta", ///
        keepus(pid syear) keep(match) nogen
    bys hid syear : egen `i'hsize = count(pid)
    collapse (mean) `i'hsize kchild, by(hid syear) 

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
    replace hgihinc = . if hgihinc < 0
    * apply household weights and average for imputations
    collapse (mean) `i'hsize kchild hghinc hgihinc w011h ///
        [pw=hhrf], by(hid syear imp)
    collapse `i'hsize kchild hghinc hgihinc w011h, by(hid syear)

    g `i'hnetinc = hgihinc
    replace `i'hnetinc = hghinc if missing(`i'hnetinc) 
    g `i'hnetwth = w011h

    rename (hid kchild) (`i'hid pid)
    keep pid syear `i'hsize `i'hnetinc `i'hnetwth `i'hid
    tempfile `i'temp
    save ``i'temp'
}

restore

* merge everything together
merge 1:1 pid syear using `ftemp', keep(master match) nogen
merge 1:1 pid syear using `mtemp', keep(master match) nogen
* generate indicator if parents still belong to the same household
g psamehh = (fhid == mhid) if !missing(fhid) | !missing(mhid)
drop ?hid

save "${DATA_PATH}/temp.dta", replace


*********************


u "${SOEP_PATH}/bioparen.dta", clear
keep persnr bioyear ?birth ?nr ?ydeath ?reli ?sedu living? ?currloc ?egp ///
    sibl numbs numb ?fight

* count siblings in the parental information
g auxs = nums if nums >= 0
replace auxs = 0 if sibl == 0
g auxb = numb if numb >= 0
replace auxb = 0 if sibl == 0
egen nsibs = rowtotal(auxs auxb), missing
drop aux*

drop pid
rename bioyear syear
local stubvar = "f m"
foreach i in `stubvar' {
    rename `i'nr pid
    preserve
    replace pid = . if pid < 0
    drop if missing(pid)
    tempfile `i'nopid
    save ``i'nopid'
    restore
    merge 1:m pid syear using "${SOEP_PATH}/pgen.dta", ///
        keepus(pglabnet) keep(master match) nogen
    tempfile `i'yespid
    save `i'yespid
}












preserve
* temporary save the variables we want to keep from the partner
keep pid syear age ancestry ?native ?secgen female employed selfemp ///
    yeduc college hsdegree etecon finjob egp
rename (age ancestry ?native ?secgen female employed selfemp yeduc ///
    college hsdegree etecon finjob egp) (age_s ancestry_s ?native_s /// 
    ?secgen_s female_s employed_s selfemp_s yeduc_s college_s /// 
    hsdegree_s etecon_s finjob_s egp_s)
tempfile partners
save `partners'
restore

* keep only the head of household
keep if stell_h == 0
* rename partner id for the merge
rename (pid parid) (pid_h pid)
* replace identifier when there is no partner
replace pid = . if pid == -2
drop stell_h

preserve
* save households with no partners
keep if missing(pid)
rename  (pid_h pid) (pid parid)
tempfile nopartners
save `nopartners'
restore

* we keep only heads of household with the partner
drop if missing(pid)

* retrieve country of origin and migration background of the partner
merge 1:1 pid syear using "${SOEP_PATH}/ppathl.dta", ///
    keepus(corigin migback) keep(match) nogen
* include all the demographics for the spouse
merge 1:1 pid syear using `partners', keep(match) nogen

* integrate ancestry when the spouse is not a second-generation
replace ancestry_s = corigin if migback != 3
rename (migback pid_h pid) (migback_s pid parid)

* reintegrate households where there is not a partner
append using `nopartners'

keep hid pid syear cid gebjahr parid ancestry* ?native* ?secgen* age* ///
    female* married* employed* selfemp* civserv* ineduc* retired* yeduc* ///
    hsdegree* voceduc* etecon* egp* finjob* hsize nchild migback_s

********************************************************************************
* Step 5: Information about head of household and partner's parents.           *
********************************************************************************

* we need to use bioparen here


********************************************************************************
* Step 6: Household level variables.                                           *
********************************************************************************





* drop if still in education?
* drop if pgstib == 11

* number of adults in the household
* number of children in the household (count after indicator variable)

* prima finisci a tirare fuori demographics dell'head of household
* poi fai quelle della sposa e quelle di eventuali figli nel nucleo aventi un
* ruolo negli asset della famiglia
* non sappiamo ancora chi è head of household, tiriamo su tutti
* droppiamo quelli che sono ancora in education eventualmente?

* poi fai bioparen length of stay 

* poi household level in riga con assets e liabilities

* poi household level con le cose messe in riga assets e liabilities
* I don't really care about marital status as long as there is a partner
* I care more about how many figli a carico

* trovare un codice per le demo di husband, spouse e figli eventuali 

* parents time of immigration, length of stay in Germany

******


* retrieve relationship with the head of household from pbrutto dataset
* the head of the household is defined as the person who knows best about
*   the general conditions under which the household acts and is supposed
*   to answer this questionnaire in each given year
merge 1:1 pid syear using "${SOEP_PATH}/pbrutto.dta", ///
    keepus(stell_h) keep(master match) nogen
keep if stell_h == 0 
rename (pid parid ancestry) (hpid pid hancestry)
replace pid = . if pid == -2
drop stell_h

preserve
keep if missing(pid)
tempfile subset
save `subset'
restore

drop if missing(pid)

merge 1:1 pid syear using "${SOEP_PATH}/ppathl.dta", ///
    keepus(corigin migback) keep(master match) nogen

merge 1:1 pid syear using "${DATA_PATH}/2ndgenindv34soep.dta", ///
    keepus(ancestry) keep(master match) nogen

replace ancestry = corigin if migback != 3
rename (ancestry migback pid) (sancestry smigback spid)

keep hpid syear ?ancestry ?native ?secgen gebjahr age smigback

* retrieve demographics for the head of household

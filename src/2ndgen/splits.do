********************************************************************************
*                                                                              *
* Filename: splits.do                                                          *
* Description: a little snippet to create separate datasets for the household  *
*   head, his/her father and mother and their household information, his       *
*   partner and partner's father and mother information.                       *
*                                                                              *
********************************************************************************

use "${DATA_PATH}/hh2genv34soep.dta", clear

drop *_s
preserve
keep hid syear f*
drop female foreignid finjob
save "${DATA_PATH}/hh2genv34soep_fathers.dta", replace
restore

preserve
keep hid syear m*
drop married mloan*
save "${DATA_PATH}/hh2genv34soep_mothers.dta", replace
restore

unab fvars : f*
local dropvars = "female foreignid finjob"
local fvars : list fvars - dropvars
unab mvars : m*
local dropvars = "married"
local mvars : list mvars - dropvars
unab dropvars : mloan*
local mvars : list mvars - dropvars
drop `mvars' `fvars'

save "${DATA_PATH}/hh2genv34soep_hh.dta", replace

use "${DATA_PATH}/hh2genv34soep.dta", clear
keep hid syear *_s

preserve
keep hid syear f*_s
drop female_s foreignid finjob_s
save "${DATA_PATH}/hh2genv34soep_fathers_s.dta", replace
restore

preserve
keep hid syear m*_s
save "${DATA_PATH}/hh2genv34soep_mothers_s.dta", replace
restore

unab fvars : f*_s
local dropvars = "female_s foreignid_s finjob_s"
local fvars : list fvars - dropvars
unab mvars : m*_s
drop `mvars' `fvars'

save "${DATA_PATH}/hh2genv34soep_hp.dta", replace

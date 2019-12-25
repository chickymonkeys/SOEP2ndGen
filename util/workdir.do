********************************************************************************
*                                                                              *
* Filename: workdir.do                                                         *
* Description: .do file to create the directories' environment                 *
*                                                                              *
********************************************************************************

local base   = "${BASE_PATH}"
local stubs  = "res tests log src util data"
local gnames = "OUT TEST LOG SRC UTIL DATA"
local n: word count `gnames'

tokenize "`gnames'"
forvalues i = 1/`n' {
    gl ``i''_PATH = "`base'/`: word `i' of `stubs''"
    if ${MAKE_DIR} {
        !mkdir "${``i''_PATH}"
    }
}

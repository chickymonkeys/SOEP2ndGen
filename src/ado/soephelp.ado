****************************** SOEPhelp ****************************************
*
* Ein ado zum auslesen von im Datensatz integrierte Metadatendokumentation
*
********************************************************************************

* save temp
global dir = "`c(tmpdir)'" 

cap program drop soephelp 
program define soephelp, rclass
  syntax [varname(default=none)][,de en]
  local variable = "`varlist'"
  local lang = ""
  
  * Versionkontrolle...wenn current date smaller than set date, ask for update
  local V = "1.0"
  
  local date: display %td_CCYY_NN_DD date(c(current_date), "DMY")
  local date = subinstr(trim("`date'"), " " s, "-", .)
  loc yyyy = substr("`date'",1,4)
  loc md   = substr("`date'",6,2)
  loc dd   = substr("`date'",-2,.)
  loc date2 = "`md'-`dd'-`yyyy'"
  loc cdate=date("`date2'", "MDY")
  // SAME: loc date3 = substr("`date'",6,2) + "-" + substr("`date'",-2,.) + "-" + substr("`date'",1,4) 
  local update = "01-05-2020" // WHEN TO UPDATE!!!
  loc update = date("`update'","MDY")
  if `cdate' > `update' {  //21489 { // nov-01-2018
    n dis "Please check for soephelp updates..."
  }
  
* Option de | en
  if "`de'" == "" & "`en'" == "" {
    qui label language
    local lang = lower("`r(language)'") 
    if !inlist("`lang'","de","en","default") {
      dis in red "Language `lang' not supperted. Fallback to default (de)"
      local lang = "de"
    }
	else if "`r(language)'" == "default" {
	  local lang = "de"
	}
  }
  else if "`de'" != ""{
    local lang = "de"
  }
  else if "`en'" != "" {
    local lang = "en"
  }
  
* Sprachversion der Hilfedatei (überschirften)
if "`lang'" == "en" {
  local Content 		= "Sources"
  local Beschreibung	= "Description"
  local Stichproben 	= "Samples"
  local Kontakt			= "Contact"
  local Keyvars	 		= "Keyvariables"
  local Frage 			= "Question text"
  local Fragenummer 	= "Question"
  local Vartext 		= "Variabletext"
  local Varlabel 		= "Variablelabel"
  local Integration 	= "Sources"
  local VarKontakt 		= "Expert"
  local DataKontakt 	= "Contact"
  local Inputdata 		= "Input datasets"
  local Inputvar 		= "Input variables"
  local Type 			= "Generated Variable"
  local Fragebogen		= "Questionnaire"
  local Year			= "Years"
  /*...*/
}
if "`lang'" == "de" {
  local Content 		= "Quellen"
  local Beschreibung 	= "Beschreibung"
  local Stichproben 	= "Stichproben"
  local Kontakt 		= "Kontakt"
  local Keyvars 		= "Keyvariablen"
  local Frage 			= "Fragetext"
  local Fragenummer 	= "Frage"
  local Vartext 		= "Variablentext"
  local Varlabel 		= "Variablenlabel"
  local Integration 	= "Quellen"
  local VarKontakt 		= "Experte/in"
  local DataKontakt 	= "Kontakt"
  local Inputdata 		= "Ursprungsdaten"
  local Inputvar 		= "Ursprungsvariablen"
  local Type 			= "Generierte Variable"
  local Fragebogen		= "Fragebogen"
  local Year			= "Jahre"
  /*...*/
}

* _dta charecterisitics  
  local _dta 		: char _dta[]
  local dataset 	: char _dta[dataset]
  local study		: char _dta[study]
  local date		: char _dta[date]
  local version 	: char _dta[version]
  local data_contact: char _dta[contact]
  local intro		: char _dta[description_`lang']
  local pkey		: char _dta[pkeys]
  local skey		: char _dta[skeys]
  local nsources	: char _dta[nsources]
  local topics		: char _dta[topics]
  local type		: char _dta[type]
  local nvars		: char _dta[N]
  local codebook	: char _dta[codebook]
  
* error wenn keine _dta[] chars vorhanden  
  local error 0
  if "`dataset'" == "" {
    local error 1
  }
  if `error' == 0 {
  *some hardlinks...
  local link2 "https://paneldata.org/`study'/data/`dataset'"
  
* Multipunches (z.b. frageboegen pro datensatz)
  local questionnaire_all = ""
  local notes = 0
  * wenn mal wieder was fehlt...
  if missing(`nsources') {
    local nsources = 1
   }
* je ein neuer local 
  forvalues x=1/`nsources'  {
    local link_`x'  			: char _dta[surveypaper_`x']
	local frabo_`x' 			: char _dta[instrument_`lang'_`x']
	local inputdata_`x' 		: char _dta[input_dataset_`x']
	local questionnaire_`x' 	: char _dta[questionnaire_`x']	
	local value_`x'				: char _dta[value_`x']	
	local mode_`x' 				: char _dta[mode_`x']
	local language_`lang'_`x' 	: char _dta[lang_`lang'_`x']
    local codebook_`x'			: char _dta[codebook_`x']
	local samplegrp_`x'			: char _dta[samplegrp_`x']
	local year_`x'				: char _dta[years_`x']
    local references_`x'		: char _dta[references_`x']

	// uniq questionnairs
	local questionnaire_all = "`questionnaire_all'" + " `questionnaire_`x''"
	local questionnaire_all : list uniq questionnaire_all
  }
  
   * ERROR  again wenn keine dta_chars vorhanden sind...
if `"`intro'"'=="" & "`pkey'" == "" & "`references_1'" == "" & `"`topics'"' == "" ///
   & "`study'" == "" & "`data_contact'" == "" {

   local error = 1
}
  
cap file close soephelp // failsave
qui file open soephelp using $dir/soephelp.sthlp, write replace
   
********************************************************************************   
********************** SOEPHELP  -  DATASET ************************************
********************************************************************************   
if "`variable'" == ""  {
*** Dataset information (charecteristics) 
file write soephelp "{smcl}" _n
file write soephelp "{* *! version `V'}{...}" _n
file write soephelp "SOEPhelp `V' {right:`study' | `version' | `date' }" _n
file write soephelp "{hline}" _n
file write soephelp "{center: {bf:`dataset' - Version `version'}}" _n
file write soephelp "{p2colset 2 20 20 0}{...}" _n
file write soephelp "{p2line}" _n 

* Warning for merged datasets
if c(k) != `nvars' {
  file write soephelp "{center:{ul:{error:ATTENTION!}}}" _n
  file write soephelp "{center:{ul:{error:You seemed to have alterd this dataset. Assurence of metadata can not be guaranteed.}}}" _n
  file write soephelp "{p2line}" _n _n
  }
if `"`intro'"' != "" {
  local intro = subinstr("`intro'",char(10),"{break}",.)
  local intro = subinstr("`intro'",char(13),"{break}",.)
  file write soephelp _n  
  file write soephelp `"{synopt:{opt `Beschreibung': }}`intro' {p_end}"' _n _n  
}

* Key-Variables
if "`pkey'" != "" {
  file write soephelp "{synopt:{opt Keyvariabels: }} Primary Keys: `pkey' {p_end}" _n 
  if "`skey'" != "" {
    file write soephelp "{synopt: } Secondary Keys: `skey' {p_end}" _n _n
  }
  else {
   file write soephelp "{synopt:  } {p_end}" _n 
  }
}

* Codebook
if "`codebook'" != "" {
 dis "`codebook'"
  file write soephelp `"{synopt:{opt Codebook: }} {browse "`codebook'":{ul:Codebook - `dataset'}}{p_end}"' _n _n
}

* Content & links
if "`references_1'" != "" | "`frabo_1'" !="" | "`inputdata_1'"!="" {
  file write soephelp "{synopt:{opt `Content': }}{p_end}"
  forvalues x=1/`nsources' {
  * PDF-Link  
    if "`references_`x''" != "" {
	  if  "`frabo_`x''" != "" {
        file write soephelp `"{p 20 20 2} • {browse "`references_`x''":{ul:`frabo_`x''}}{p_end}"' _n
      }
	  else {
	    file write soephelp `"{p 20 20 2}{browse "`references_`x''":{ul: Dokumentation - `dataset'}}{p_end}"' _n _n
	  }
	}
  * Instrument label (de/en)
    if "`frabo_`x''" != "" & "`references_`x''" == "" {
      file write soephelp "{p 20 20 2} • `frabo_`x''{p_end}" _n
    }
  * Instrument-var Value?
    if "`value_`x''" != "" {
      file write soephelp "{p 25 20 2} instrument-value: _q`value_`x''{p_end}" _n
    }
  * Mode?
    if "`mode_`x''" != "" {
      file write soephelp "{p 25 20 2} Mode: `mode_`x''{p_end}" _n 
    }
  * Rohdaten?
    if "`inputdata_`x''" != "" & !regexm("`type'","org|raw") {
      file write soephelp "{p 25 20 2} `Inputdata': `inputdata_`x''{p_end}" _n
    } 
  * Years?
	if "`year_`x''" != ""{
      file write soephelp "{p 25 20 2} `Year': `year_`x''{p_end}" _n
    }
  }
  file write soephelp _n
  file write soephelp "{p2colreset}{...}" _n
  file write soephelp "{p2colset 2 20 20 0}{...}" _n
}

* Panaldata?
if "`study'" != "" {
  file write soephelp `"{synopt:{opt Paneldata: }}{browse "`link2'":{ul:`dataset'}}{p_end}"' _n _n
}

* DTC / Companion? (gib metadata ༼ つ ◕_◕ ༽つ)
file write soephelp _n _n
file write soephelp "{synoptline}" _n
file write soephelp "{p2colreset}{...}" _n _n _n 

* Datasetkontakt
if "`data_contact'" != "" {
  local email = regexm("`data_contact'","[A-Za-z0-9\.]*@[a-z]*.[0-9a-z\.]*")
  local email = regexs(0)
  local contact = regexr("`data_contact'","[A-Za-z0-9\.]*@[a-z]*.[0-9a-z\.]*",`"{browse "mailto:`email'":`email'}"')
  file write soephelp "{title:`DataKontakt'}" _n _n
  file write soephelp "{pstd}"
  file write soephelp `"`contact'"' _n _n
}

* Further Remarks
file write soephelp "{title:Remarks}" _n _n
file write soephelp "{pstd}" 
file write soephelp `"For further information please visit: {browse "https://data.soep.de/":SoepInfo}, {browse "http://companion.soep.de/":SOEPcompanion} or {browse "http://soep.de":soep.de}{p_end}"'_n _n

} // error
}
*************************** END DATASET ****************************************


********************************************************************************
*
******************************* VARIABLES **************************************
*
********************************************************************************
if "`variable'" != "" {

local error 0
local var_chars : char `variable'[]
* error capture *
if "`var_chars'" == "" {
  local error = 2
}

* variable charecteristics
if `error' == 0 {
local q_text 		: char `variable'[q_text_`lang']
local var_text		: char `variable'[text_`lang']
local var_contact	: char `variable'[contact]
local mail			: char `variable'[mail]
local description	: char `variable'[description_`lang']
local syntax		: char `variable'[syntax]
local long			: char `variable'[soeplong]
local integrate 	: char `variable'[integrate]
local N				: char `variable'[N]
local topic			: char `variable'[topic]
local type			: char `variable'[type]
local years			: char `variable'[years]  		
local input_vars	: char `variable'[input_vars]	
local references	: char `variable'[references] 
local dtc			: char `variable'[dtc]
local q_txt			: char `variable'[questiontxt_`lang']
local v_txt			: char `variable'[variabletxt_`lang']
local goto    		: char `variable'[goto]
local filter 		: char `variable'[filter]  

local nr = subinstr("`qnr'","q","",.)
local samples = subinstr("`samples'"," "," | ",.)

local out = 0 // flag for goto
local in  = 0 // flag for filter 
* multipunches
forvalues x=1/`N'  {
  local inputdata_`x'		: char `variable'[input_dataset_`x']
  local qnr_`x'				: char `variable'[question_`x']
  local inputvar_`x'		: char `variable'[input_variable_`x']
  local longdataset_`x'		: char `variable'[longdataset_`x']
  local instrument_`x'		: char `variable'[instrument_`lang'_`x']
  local year_`x'			: char `variable'[years_`x'] 
  local syntax_`x'			: char `variable'[syntax_`x']
  local filter_`x'			: char `variable'[filter_`x']
  local goto_`x'			: char `variable'[goto_`x']
}	

* ERROR wenn keine var_chars vorhanden sind...
if mi("`q_text'")&mi("`var_text'")&mi("`var_contact'")&mi("`mail'") & ///
   mi("`description'")&mi("`syntax'")&mi("`long'")&mi("`integrate'")& ///
   mi("`topic'")&mi("`input_vars'")&mi("`years'")&mi("`references'")& ///
   mi("`dtc'")&mi("`q_txt'")&mi("`v_txt'")&mi("`goto'")&mi("`filter'") & ///
   mi("`inputdata_1'")& mi("`qnr_1'")& mi("`inputvar_1'")& mi("`longdataset_1'")& ///
   mi("`instrument_1'")&mi("`year_1'")&mi("`syntax_1'") {
     local error = 2
}

***************************** Start of file  ***********************************
file write soephelp "{smcl}" _n
file write soephelp "{* *! version `V'}{...}" _n
file write soephelp "SOEPhelp `V': `variable' {right:`study' | `version' | `date'}" _n
file write soephelp "{hline}" _n
file write soephelp "{center: {bf:`dataset' - `variable'}}" _n
file write soephelp "{p2colset 2 20 20 0}{...}" _n

* Warning for merged datasets
if c(k) != `nvars' {
  file write soephelp _n
  file write soephelp "{center:{ul:{error:ATTENTION!}}}" _n
  file write soephelp "{center:{ul:{error:You seemed to have alterd this dataset. Assurence of metadata can not be guaranteed.}}}" _n
  }

file write soephelp "{dlgtab 0 0:`variable'}" _n _n
* dynamics: Teile verbergen wenn keine Info vorhanden

* Fragetext
if "`q_txt'" != ""  {
  file write soephelp "{synopt:{opt `Frage': }}`q_txt'{p_end}" _n _n
}

* Itemtext oder Variablenlabel
if "`q_txt'" != "`v_txt'" & "`v_txt'" != "" {
  file write soephelp "{synopt:{opt `Vartext': }}`v_txt' {p_end}" _n _n
}
else {
  local v_txt: var label `variable'
  file write soephelp "{synopt:{opt `Varlabel': }}`v_txt' {p_end}" _n _n
}

* Description
if "`description'" != "" {
* WIP: Variablenerkennung **********************
* suche in description nach variable im Datensatz und ersetze diese Variable
* mit stata soephelp `var' command
* TODO
* noch probleme bei ähnlichen vars: abc01 & abc01B werden als abc01 gefunden (trotz exact Oo)
* aus allen chars raussuchen
* carriage returns und line breaks in {break} umwandeln (einfacher Zeilenumbruch)
*		doppelter leider noch nicht möglich ...-.-
foreach x in `"`description'"' {
  cap conf var `x', exact
  if !_rc {
	 local description = subinstr("`description'","`x'","{stata qui soephelp `x': `x'}",.)
    }
  }
  local description = subinstr("`description'",char(10),"{break}",.)
  local description = subinstr("`description'",char(13),"{break}",.)
  file write soephelp `"{synopt:{opt `Beschreibung': }}`description'{p_end}"' _n _n
}

* Rohvariablen / Input-vars / Integration / Quellen
* 5-Column Tabelle: A=Fragebogen | B=Fragenummer | C=Rohdatensatz | D=Fixname | E=Syear
* Spalten werden nur angezeit, wenn mind. eine Info vorhanden ist
if "`inputvar_1'" != "" | "`instrument_1'" != "" | "`inputdata_1'" != "" | "`syear_1'" != ""   {
  if "`lang'" == "de" {
    file write soephelp "{synopt:{opt `Integration': }}{it: Variable hat folgenden Quellen:} {p_end}"_n _n
  }
  else if "`lang'" == "en" { 
    file write soephelp "{synopt:{opt `Integration': }}{it: Variable has following sources:} {p_end}"_n _n
  }
   * Dimensionen der Tabelle (dynamically)  
   * Spaltenbreite
  *loc a = strlen("`Fragebogen'") +5 	// Col A
  loc a = 40
  *loc b = strlen("`Fragenummer'") +2	// Col B
  loc b = 8
  loc c = strlen("`Inputvar'") +2		// Col C
  loc d = strlen("`Inputdata'") +2		// Col D 
  loc e = strlen("`Year'") +2			// Col E
  *loc f = strlen("Syntax") +1			// COL F
  * Spalte A: Frabo 
  * Breite header = Breite Trenner
  * header zentriert
  forvalues x=1/`N' {
    if "`instrument_`x''" != "" & "`COLA'" == "" {
      loc COLA  {center `a':`Fragebogen'}{c |} 
	  loc LINEA {hline `a'}{c |} 
    }
  * Spalte B: Fragenummer
    if "`qnr_`x''" != "" & "`COLAB'" == "" & regexm("`type'","org|raw") {
      loc COLB  {center `b':`Fragenummer'}{c |}
	  loc LINEB {hline `b'}{c |} 	
    }
  * Spalte C: Eingangsvar
    if "`inputvar_`x''" != "" & !regexm("`type'","org|raw") & "`COLC'" == "" {
      loc COLC  {center `c':`Inputvar'}{c |}
	  loc LINEC {hline `c'}{c |}
    }
  * Spalte D: Eingangsdata
    if "`inputdata_`x''" != "" & !regexm("`type'","org|raw") & "`COLD'" == ""{
      loc COLD  {center `d':`Inputdata'}{c |}
  	  loc LINED {hline `d'}{c |}
    }
  * Spalte E: Jahre
    if "`year_`x''" != ""& "`COLE'" == "" {
      loc COLE  {center `e':`Year'}
	  loc LINEE {hline `e'}
    }
  /* Spalte F: Syntax (Alternativerweise Long-Prozess?)
    if "`syntax_`x''" != "" & "`COLF'" == "" {
      loc COLF  {center `f':"Syntax"}{c |}
	  loc LINEF {hline `f'}{c |}
    }
   */
  } 
  // Korrekur für Frabospalte wenn genug Platz ist...
  if strlen("`COLA'`COLB'`COLC'`COLD'`COLE'`COLF'") < 55 {
    if "`instrument_1'" != "" {
      loc COLA  {center `a':`Fragebogen'}{c |} 
	  loc LINEA {hline `a'}{c |} 
    }
  * Spalte B: Fragenummer
    if "`qnr_1'" != "" {
      loc COLB  {center `b':`Fragenummer'}{c |}
	  loc LINEB {hline `b'}{c |} 	
    }
  }
    * start[table:t1]
  file write soephelp "{col 20}`COLA'`COLB'`COLC'`COLD'`COLE`COLE''" _n			 // head[t1]
  file write soephelp "{col 20}`LINEA'`LINEB'`LINEC'`LINED'`LINEE'`LINEF'" _n	 //	divieder[t1]

  * Table Content
  forvalues x=1/`N' {
  // centered(content_`n'[t1])
    if "`instrument_`x''" != "" {
    // abbrevation of instrument name, cause those are always to long...
	  if `a' < length("`instrument_`x''") {    
	    loc instrument = substr("`instrument_`x''",1,`a'-1)
	    loc instrument = "`instrument'" + "~"
      }
	  else {
	    loc instrument = "`instrument_`x''"
	  }
      loc CONTA {center `a':`instrument'}{c |}
	}
    if "`qnr_`x''" != ""  & regexm("`type'","org|raw") {
      loc CONTB {center `b':`qnr_`x''}{c |}
    }
	/*
    if "`qnr_`x''" != "" {
	  loc CONTB {center `b':`qnr_`x''}{c |}
	}
	*/
	if "`inputvar_`x''" != "" & !regexm("`type'","org|raw") {
      * soephelp link if variable in dataset!
	  cap conf var `inputvar_`x'', exact
      if !_rc {
	   local inputvar_`x' = subinstr("`inputvar_`x'","`inputvar_`x'","{stata qui soephelp `inputvar_`x'': `inputvar_`x''}",.)
      }
	  loc CONTC {center `c':`inputvar_`x''}{c |}
	}	 
	if "`inputdata_`x''" != "" & !regexm("`type'","org|raw") {
	  loc CONTD {center `d':`inputdata_`x''}{c |}
	}
	if "`year_`x''" != "" {
	  loc CONTE {center `e':`year_`x''}
	}
	/*
	if "`syntax_`x''" != "" {
	  loc CONTF {center `e':`syntax_`x''}{c |}
	}
	*/
    file write soephelp "{col 20}`CONTA'`CONTB'`CONTC'`CONTD'`CONTE'`CONTF'" _n
  }
  file write soephelp _n
}

* SOEP Long
if "`long'" != "" {
   file write soephelp "{synopt:{opt SOEP Long: }}`long'{p_end}" _n _n
}

* Link zu Paneldata.org
if "`study'" != "" {
  file write soephelp `"{synopt:{opt Paneldata: }}{browse "`link2'/`variable'":{ul:`variable'}}{p_end}"' _n _n
}

* Variablenspezialist
if "`var_contact'" != "" & "`type'"!="long" {
  *check for email and replace with mailto:mail
  * @ sign?
  if strmatch("`var_contact'","*@*") {
    local email = regexm("`var_contact'","[A-Za-z0-9\.]*@[a-z]*.[0-9a-z\.]*")
    local email = regexs(0)
    local contact = regexr("`var_contact'","[A-Za-z0-9\.]*@[a-z]*.[0-9a-z\.]*",`"{browse "mailto:`email'":`email'}"')
    file write soephelp `"{synopt:{opt `VarKontakt': }}`contact' {p_end}"' _n 
  }
  else {
    file write soephelp `"{synopt:{opt `VarKontakt': }}`var_contact' {p_end}"' _n 
  }
  * mail extra
  if "`mail'" != "" {
    file write soephelp `"{synopt: }Email: {browse "mailto:`mail'":`mail'}  {p_end}"' _n 
  }
}


* DTC
if "`dtc'" != "" {
  file write soephelp `"{synopt:{opt Companion: }}{browse "`dtc'":{ul:Companion}}{p_end}"' _n _n
}

* references
if "`references'" != "" {
  * autodetect links ....
  local link = regexm("`references'","(http) | (https):\/\/[a-z0-9]*.*")
  local link = regexs(0)
  local references = subinstr("`references'", "`link'", `"{browse "`link'"}"',.)
  file write soephelp `"{synopt:{opt References: }}"`references'"{p_end}"' _n _n
}

file write soephelp _n
file write soephelp "{synoptline}" _n
file write soephelp "{p2colreset}{...}" _n _n _n 

*** Variablenschema 
*  (nur in bh-Datensätzen anzeigen) 
if regexm("`type'","org|raw") & regexm("`variable'","^bh|^bi") {
  local wuqiq `"http://companion.soep.de/Data%20Structure%20of%20SOEPcore/Raw%20Data.html#extended-variable-naming-convention"'
  file write soephelp "{title:Naming Conventions}" _n _n
  file write soephelp "{pstd}"
  if "`lang'" == "de" {
    file write soephelp `"Unser neues Variablennamensschema (gültig ab Welle bh): {browse "`wuqiq'":{ul:WUQIq}}{p_end}"' _n _n  
  }
  if "`lang'" == "en" {
    file write soephelp `"Our new variable names convention (valid from wave bh): {browse "`wuqiq'":{ul:WUQIq}}{p_end}"' _n _n
  }
}

* Datensatz Spezialist
if "`data_contact'" != "" {
  local email = regexm("`data_contact'","[A-Za-z0-9\.]*@[a-z]*.[0-9a-z\.]*")
  local email = regexs(0)
  local contact = regexr("`data_contact'","[A-Za-z0-9\.]*@[a-z]*.[0-9a-z\.]*",`"{browse "mailto:`email'":`email'}"')
  file write soephelp "{title:`DataKontakt'}" _n _n
  file write soephelp "{pstd}"
  file write soephelp `"`contact'"' _n _n
}

* Further Remarks
file write soephelp "{title:Remarks}" _n _n
file write soephelp "{pstd}" 
file write soephelp `"For further information please visit: {browse "https://data.soep.de/":SoepInfo}, {browse "http://companion.soep.de/":SOEPcompanion} or {browse "http://soep.de":soep.de}{p_end}"'_n _n

* previous and next variable (if not end of dataset...)
qui describe, varlist
local varlist = r(varlist)
local x : list posof "`variable'" in varlist
local next = word("`varlist'",`x'+1)
local previous = word("`varlist'",`x'-1)
local statacmd = ""
local statacmd1 = "`statacmd'" + " " + `"{stata qui soephelp `previous',`lang': <<}"'
local statacmd2 = "`statacmd'" + " " + `"{stata qui soephelp `next',`lang': >>}"'

file write soephelp _n "{.-}" _n
file write soephelp `"  `statacmd1'{right:`statacmd2'  }"' _n
file write soephelp "[previous] {right:[next]}" _n _n
} // errorfree
}
****************************** VAR - END ***************************************


*************************** Error Handling ... *********************************
* if no dataset chars | no variable chars are to be found ....

return local error = `"`error'"' // return for checks

if `error' > 0 {
  *dis in red _n"ERROR..."
  cap file close soephelp // failsave
  file open soephelp using $dir/soephelp.sthlp, write replace
  file write soephelp "{smcl}" _n
  file write soephelp "{* *! version v`V'}{...}" _n
  file write soephelp "Soephelp v`V': `dataset' - `variable' {right:`study' | `version' | `date'}" _n
  file write soephelp "{hline}" _n _n
  if c(version) >= 14 {
    file write soephelp "{center:╔═╗╔═╗╔═╗╔═╗┬ ┬┌─┐┬  ┌─┐}" _n
    file write soephelp "{center:╚═╗║ ║║╣ ╠═╝├─┤├┤ │  ├─┘}" _n
    file write soephelp "{center:╚═╝╚═╝╚═╝╩ .┴ ┴└─┘┴─┘┴  }" _n  
  }
  else if c(version) <= 13 {
    file write soephelp "{center:  _____  ____  ______ _____  _          _       }" _n
    file write soephelp "{center: / ____|/ __ \|  ____|  __ \| |        | |      }" _n
    file write soephelp "{center:| (___ | |  | | |__  | |__) | |__   ___| |_ __  }" _n
    file write soephelp "{center: \___ \| |  | |  __| |  ___/| '_ \ / _ \ | '_ \ }" _n
    file write soephelp "{center: ____) | |__| | |____| |    | | | |  __/ | |_) |}" _n
    file write soephelp "{center:|_____/ \____/|______|_|    |_| |_|\___|_| .__/ }" _n
    file write soephelp "{center:                                         | |    }" _n
    file write soephelp "{center:                                         |_|    }" _n
  }
  *file write soephelp _n "{hline}" _n _n
  file write soephelp _n _n
  if `error' == 1 {
    if "`lang'" == "de" {
	  file write soephelp "{center:{ul:{error:{bf:Bisher sind für diesen Datensatz leider keine Meta-Information verfügbar.}}}}" _n _n _n

	}
    if "`lang'" == "en" {
	  file write soephelp "{center:{ul:{error:{bf:No meta-information about this dataset available yet. We are sorry.}}}}" _n _n _n
    }
  }
  else if `error' == 2 {
    if "`lang'" == "de" {
      file write soephelp "{center:{ul:{error:{bf:Bisher sind für diese Variable leider keine Meta-Informationen verfügbar.}}}}" _n _n _n
	}
	if "`lang'" == "en" {
      file write soephelp "{center:{ul:{error:{bf:No Metadata for this variable available yet. We are sorry.}}}}" _n _n _n
	}
  }
  file write soephelp "{right:{c TLC}{hline 33}}"
  file write soephelp `"{right:{c |}soephelp-support: {browse "mailto:Marvin Petrenz":mpetrenz@diw.de}}"' _n _n
  file write soephelp "{pstd}" _n

  file close soephelp 
  view $dir/soephelp.sthlp
  rm $dir/soephelp.sthlp 
  exit   
}
 
 * ado-author / Close helpfile / view / remove from disk
file write soephelp "{right:{c TLC}{hline 33}}"
file write soephelp `"{right:{c |}soephelp-support: {browse "mailto:Marvin Petrenz":mpetrenz@diw.de}}"' _n
file write soephelp "{right:{col 34}{c |}}{right:{stata help soephelp: help soephelp}}" _n _n
file write soephelp "{pstd}" _n

qui file close soephelp 
view $dir/soephelp.sthlp
rm $dir/soephelp.sthlp 

end
*♥*




{smcl}
{* *! version 1.0}{...}
help for {cmd:soephelp} - v34 {right:version 1.0, 4th of March 2019}
{hline}

{title:SOEPhelp}

{phang}
{bf:soephelp} {hline 2} is a convenient way to display basic information and documentation 
of soep datasets.

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:soephelp} [{var}] [{cmd:,} {it:options}]
{p_end}

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt en}}displays information in English (if available) {p_end}
{synopt:{opt de}}displays information in German (if available) {p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}
Standard is defined by label language {manhelp label_language D}.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:soephelp} is used to display documentation of the dataset in use and its variables via the stata viewer.{break}
{var} is optional, if no variable is specified {cmd:soephelp} displays basic 
information about the dataset. For example what instruments or datasets were used 
to assamble this dataset, version of the dataset and its basic contents. {break}

{pstd}
If a variable is specified, the documentation of this variable is displayed. This generally 
includes information about variable origins, e.g. questiontext and/or item text, questionnaires, question number, 
corresponding soep-long variables as well as links to further documentation such as 
{browse "https://paneldata.org/":paneldata.org} or the {browse "http://companion.soep.de/":SOEPcompanion}.{break}{p_end}

{pstd}
{cmd:soephelp} is currently implemented for soep-core and soep-long datasets.{break}{p_end}

{marker examples}{...}
{title:Example}

{pstd}
Open dataset documentation of current dataset.

	{cmd:soephelp}
	
{pstd}
Open variable documentation (in the language of the current labelset).

	{cmd:soephelp {var}}
	
{pstd}
Open variable documentation in English (if labelset language is German).

	{cmd:soephelp {var}, en}
	
{pstd}
Open variable documentation in German (if labelset language is English)

	{cmd:soephelp {var}, de}


{dlgtab 0 0:Remarks}

{marker remarks}{...}
{title:Remarks}

{pstd}
SOEPhelp is currently in beta. You may encounter missing information or documentation. Not all datasets are fully implemented 
at this moment. If you encounter any problems, don't hesitate to contact us and we will try to fix it in future releases.

{pstd}
The source code of the program is licensed under the GNU General Public License version 3 or later. 
The corresponding license text can be found on the Internet at {browse "http://www.gnu.org/licenses/"} 
or in {help gnugpl}.

{marker author}{...}
{title:Author}

{pstd}
Marvin Petrenz ({browse "mailto:mpetrenz@diw.de":mpetrenz@diw.de}), DIW Berlin, German Socio-Economic Panel (SOEP), Germany.
{p_end}


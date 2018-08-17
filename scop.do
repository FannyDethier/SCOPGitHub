cap log close
clear
set more off 
clear matrix
cd "C:\Users\dethi\Documents\GitHub\SCOPGitHub"
version 13.0
log using SCOP.log, replace
log on
 
use scop.dta
ssc install xtoverid
ssc install ranktest 
capt ssc inst estout

// -----------------------------------------------------------------------------
					***PREPARING VARIABLES***
//------------------------------------------------------------------------------
* re-labelling variables
	label variable annee_creation "year of creation"
	label variable type_creation "Type of creation"
	label variable naf10lib "sector"
	label variable catjur "legal form"
	label variable salaries "number of employees"
	label variable societaires_salaries "numbers of employees members of the coop"
	label variable societaires "number of member of the coop"
	label variable effectif_moyen "average workforce"
	label variable capital_social_ou_individuel "capital"
	label variable total_capitaux_propres "equity"
	label variable tota_capital_salaris_associs "capital owned by workers"
	label variable rserves_lgales "legal reserves"
	label variable rserves_lgales "year allocation to legal reserves"
	label variable fonds_de_dveloppement "year allocation to fons de dvp"
	label variable dividende "dividend (only to member)"
	label variable part_travail_non_affect_partic "year distrbituion of profir to worker not for partitipcation"
	label variable part_travail_deuxieme_dot_partic "year distrbituion of profir to worker for partitipcation"
	label variable ca_net_total "ca"
	label variable valeur_ajoutee_bdf "added value"
	rename part_travail_non_affect_partic interessement
	rename part_travail_deuxieme_dot_partic participation


* Building new continuous variables 
	
	*age
	gen age = year - annee_creation
	
	*V: the gross added value of the SCOP, in euro;
	rename valeur_ajoutee_bdf V
	label variable V "gross added value of the SCOP, in euro"
	gen lnV = ln(V)
	
	*L: the average number of employees in the SCOP;
	rename effectif_moyen L
	drop if L == .
	gen lnL = ln(L)
	
	*K: the total equity of the SCOP, i.e. the sum of capital shares, legal and statutory reserves, retained earnings (that is to say, the net surplus from previous years retained and not allocated to reserves) and the profit for the year, in euro;
	rename total_capitaux_propres K
	drop if capital_social_ou_individuel == .
	gen lnK = ln(K)
		*According to the law, the capital can not be less than 30 € in the SARL and 18 500 € in the SA.
		drop if capital_social_ou_individuel < 30 & catjur == "Société à responsabilité limitée (SARL)"
		drop if capital_social_ou_individuel < 18500 & catjur == "Société anonyme à conseil d'administration"
	
	*LS: the proportion of workers who are co-owners/shareholders of the SCOP, in percentage;  
	gen LS =  societaires_salaries / salaries
	drop if LS == .
	label variable LS "the proportion of workers who are co-owners/shareholders of the SCOP, in percentage"
	
	*KLS: the average capital shares held by member-workers, in euro;
	gen KLS = tota_capital_salaris_associs / societaires_salaries  
	replace KLS = . if KLS < 0 
	label variable KLS "the average capital shares held by member-workers, in euro"
		*is it possible to have a scop with no capital held by workers? I would say that it is impossible
		drop if tota_capital_salaris_associs == .
		
	*COKLS: the share of net operating surplus allocated to collective reserves, namely the legal reserve and the development funds, per member-workers, in euro;
	gen CO = rserves_lgales + fonds_de_dveloppement
	replace CO = 0 if CO == .
	gen COKLS = (rserves_lgales + fonds_de_dveloppement)/ societaires_salaries
	replace COKLS = 0 if COKLS == .
	label variable COKLS "the share of net operating surplus allocated to collective reserves, namely the legal reserve and the development funds, per member-workers, in euro"
	
	*PARTL: the share of net operating surplus allocated to workers, members or not, per worker, in euro.
	replace interessement = 0 if interessement == .
	replace participation = 0 if participation == .
	gen PARTL = (interessement + participation)  / societaires_salaries 
	label variable PARTL "the share of net operating surplus allocated to workers, members or not, per worker, in euro"

* Building new binary variables 

	/* Methods of creation
	The following binary variables take the value "1" when the cooperative belongs to this category, "0" otherwise.
	Founding methods
	There are four methods to found a SCOP:
	-	EXNIHILO: the company started under the SCOP form;
	-	REANIM: the company was operating under a different legal form from SCOP, temporarily ceased its activities and restarted under the SCOP form;
	-	TRANSFO: the company was operating under a different legal form from SCOP and has been transformed into a SCOP without a cease of its activities;
	-	TRANSMI: the company was operating under a different legal form from SCOP and has been transformed into a SCOP when the owner passed it down to the workers.*/
	gen exnihilo = 1 if type_creation == "Ex nihilo"
	replace exnihilo = 0 if exnihilo == .
	label variable exnihilo "the company started under the SCOP form"

	gen reanim = 1 if type_creation == "RÂŽanimation"
	replace reanim = 0 if reanim == .
	label variable reanim "the company was operating under a different legal form from SCOP, temporarily ceased its activities and restarted under the SCOP form"

	gen transf = 1 if type_creation == "Transformation"
	replace transf = 0 if transf == .
	label variable transf "the company was operating under a different legal form from SCOP and has been transformed into a SCOP without a cease of its activities"

	gen transmi = 1 if type_creation == "Transmission"
	replace transmi = 0 if transmi == .
	label variable transmi "the company was operating under a different legal form from SCOP and has been transformed into a SCOP when the owner passed it down to the workers"

	/*Regions	
	We chose the Nomenclature of Territorial Units for Statistics (NUTS), 
	Level 1, to classify SCOP according to their region. According to this nomenclature, 
	France is divided between eight spatial planning economic zones and a ninth zone containing the overseas departments. 
	Nine binary variables thus reflect these geographical zones.*/
	gen FR4=1 if region =="ALSACE"
	gen FR6=1 if region =="AQUITAINE"
	gen FR7=1 if region =="AUVERGNE"
	gen FR2=1 if region =="BASSE-NORMANDIE"
	replace FR2=1 if region =="BOURGOGNE"
	gen FR5=1 if region =="BRETAGNE"
	replace FR2=1 if region =="CENTRE"
	replace FR2=1 if region =="CHAMPAGNE-ARDENNE"
	gen FR8=1 if region =="CORSE"
	replace FR4=1 if region =="FRANCHE-COMTE"
	gen FR9=1 if region =="GUADELOUPE"
	replace FR9=1 if region =="GUYANE"
	replace FR2=1 if region =="HAUTE-NORMANDIE"
	gen FR1=1 if region =="ILE-DE-FRANCE"
	replace FR9=1 if region =="LA REUNION"
	replace FR8=1 if region =="LANGUEDOC-ROUSSILLON"
	replace FR6=1 if region =="LIMOUSIN"
	replace FR4=1 if region =="LORRAINE"
	replace FR9=1 if region =="MARTINIQUE"
	replace FR9=1 if region =="MAYOTTE"
	replace FR6=1 if region =="MIDI-PYRENEES"
	 gen FR3=1 if region =="NORD-PAS-DE-CALAIS"
	replace FR5=1 if region =="PAYS DE LA LOIRE"
	replace FR2=1 if region =="PICARDIE"
	replace FR5=1 if region =="POITOU-CHARENTES"
	replace FR8=1 if region =="PROVENCE-ALPES-COTE D'AZUR"
	replace FR7=1 if region =="RHONE-ALPES"

	replace FR1 = 0 if FR1 == .
	replace FR2 = 0 if FR2 == .
	replace FR3 = 0 if FR3 == .
	replace FR4 = 0 if FR4 == .
	replace FR5 = 0 if FR5 == .
	replace FR6 = 0 if FR6 == .
	replace FR7 = 0 if FR7 == .
	replace FR8 = 0 if FR8 == .
	replace FR9 = 0 if FR9 == .


	/* Fields of activity
	We chose to keep the same classification as the one used by the CG-Scop. The latter is based on the French Activities Nomenclature (NAF) rev. 2, 2008 and classifies the SCOP in eight fields of activity/ industries:
	-	AGR: Agriculture, forestry and fishing
	-	INDUEX: Extractive industry, energy, water and waste management
	-	INDUMA: Manufacturing industry
	-	CONSTRU: Construction industry
	-	COM: Trade, automobile and motorcycle repairs
	-	TRANS: Transportation and storage
	-	SERV: Service industry including: Accommodation and restaurant; Information and communication; Financial and insurance activities; Real estate activities; Specialized, scientific and technical services; Administrative services and support activities, Arts, entertainment and recreation activities; Other service activities.
	-	EDU: Education, health and social work sector.*/
	gen AGR = 1 if naf10lib == "Agriculture, sylviculture et pÂche"
	replace AGR = 0 if AGR == .
	gen COM = 1 if naf10lib == "Commerce"
	replace COM = 0 if COM == .
	gen CONSTRU = 1 if naf10lib == "Construction"
	replace CONSTRU = 0 if CONSTRU == .
	gen EDU = 1 if naf10lib == "Education, santÂŽ et action sociale"
	replace EDU = 0 if EDU == .
	gen INDUEX = 1 if naf10lib == "Industrie extractive, ÂŽnergie, eau et dÂŽchets"
	replace INDUEX = 0 if INDUEX == .
	gen INDUMA = 1 if naf10lib == "Industrie manufacturiÂre"
	replace INDUMA = 0 if INDUMA == .
	gen SERV = 1 if naf10lib == "Services"
	replace SERV = 0 if SERV == .
	gen TRANS = 1 if naf10lib == "Transports"
	replace TRANS = 0 if TRANS == .

	label variable AGR "Agriculture, sylviculture et pÂche" 
	label variable COM "Commerce" 
	label variable CONSTRU "Construction" 
	label variable EDU "Education, santÂŽ et action sociale" 
	label variable INDUEX "Industrie extractive, ÂŽnergie, eau et dÂŽchets" 
	label variable INDUMA "Industrie manufacturiÂre" 
	label variable SERV "Services" 
	label variable TRANS "Transports"  

	/* Legal forms
	SCOP can choose between the legal form of Limited Liability Company  or Public Limited Company  (with a board of directors or with an executive board). 
	SARL variable takes the value "1" when the SCOP operates under the legal form of Limited Liability Company and "0" when the SCOP works under the legal form Public Limited Company.*/
	gen SARL = 1 if catjur == "Société à responsabilité limitée (SARL)"
	replace SARL = 0 if SARL == .
	label variable SARL "SARL when 1/ SA when 0"

	*Size
	gen SMALL = 1 if L < 10
	replace SMALL = 0 if SMALL == .

	gen MEDIUM = 1 if L >= 10 & L <50
	replace MEDIUM = 0 if MEDIUM == .

	gen LARGE = 1 if L >= 50
	replace LARGE = 0 if LARGE == .

	*Life of the SCOP*

	gen bankrupt = 1 if (year+1) == annee_radiation |(year+2) == annee_radiation | (year+3) == annee_radiation
	replace bankrupt = 0 if bankrupt == .
	label variable bankrupt "1 if SCOP has known bankruptcy, 0 otherwise"
	
	tostring year, replace
	gen time1 = date(year, "Y") 
	format time1 %td
	
	*snapspan idvar time_var instantaneous_vars, generate(new_begin_date)
	snapspan id time1 bankrupt salaries societaires_salaries societaires capital_social_ou_individuel K tota_capital_salaris_associs dividend age lnK LS KLS CO COKLS SMALL MEDIUM LARGE, generate (time0) replace
	
	stset time1, time0(time0) failure(bankrupt==1) id(id) origin(annee_creation)
	
	gen time = annee_radiation - 2006 if bankrupt == 1
	replace time = 8 if bankrupt == 0
		*should I set time to 0 if no bankruptcy?
		replace time = 8 if time == .
	label variable time "time (in year) before bankruptcy from 2006"

*Total number of observation before dropping extreme observations
	count if year == 2006
	count if year == 2009
	count if year == 2012

*Dropping extreme
	sum V, detail 
	drop if V<r(p1)
	drop if V>r(p99)
	
	sum L, detail
	*drop if L<r(p1): not doing it because it is normal to have a firm with less than one worker
	drop if L>r(p99)

	sum K, detail
	drop if K<r(p1)
	drop if K>r(p99)

	sum KLS, detail
	drop if KLS<r(p1)
	drop if KLS>r(p99)

	sum COKLS, detail
	drop if COKLS<r(p1)
	drop if COKLS>r(p99)

	sum PARTL, detail
	drop if PARTL<r(p1)
	drop if PARTL>r(p99)

* Setting data as panel data
	gen t=1 if year == 2006
	replace t=2 if year == 2009
	replace t=3 if year == 2012
	duplicates report id year
	duplicates list id year
	duplicates tag id year, gen(isdup)
	duplicates drop if isdup == 1 
	drop isdup 
	sort id
	xtset id t

*Final Total number of observations
	count if year == 2006
	count if year == 2009
	count if year == 2012


// -----------------------------------------------------------------------------
					***DESCRIPTIVE STATISTICS***
//------------------------------------------------------------------------------

*** Summary
	*All variables
	xtdes
	tabstat V K L LS KLS COKLS PARTL age time , stat(count mean p1 p50 p99 min max )
	tabstat exnihilo transf transmi reanim FR1 FR2 FR3 FR4 FR5 FR6 FR7 FR8 FR9  AGR COM EDU INDUMA SERV TRANS INDUEX SARL SMALL MEDIUM LARGE bankrupt, stat(mean, sum)
	sum V K L LS KLS COKLS PARTL age exnihilo transf transmi reanim FR1 FR2 FR3 FR4 FR5 FR6 FR7 FR8 FR9  AGR COM EDU INDUMA SERV TRANS INDUEX SARL SMALL MEDIUM LARGE bankrupt time

	* Repartition of the result when result
	gen CO_ben = CO / resultat_exploitation
	replace CO_ben = 0 if CO_ben == .
	sum CO_ben if resultat_exploitation >0
	di in red "24% of the result is allocated to the collective reserves"
	
	gen PART_ben = PART / resultat_exploitation
	replace PART_ben = 0 if PART_ben == .
	sum PART_ben if resultat_exploitation >0
	di in red "8,5% of the result is allocated to the workers"
	
	gen div_ben = dividende / resultat_exploitation
	replace div_ben = 0 if div_ben == .
	sum div_ben if resultat_exploitation >0
	di in red "10% of the result is allocated to the workers"
	
***Some consideration regarding PART TRAVAIL
	gen PART = interessement + participation
	label variable PART "total amount allocated to part travail= interessement + participation" 

	* SCOP gives part travail
	gen PART_BI = 1 if PART>0
	replace PART_BI = 0 if PART_BI == .
	label variable PART_BI "1 if the SCOP distributes a part travail, 0 otherwise" 

	gen PART_NLO = 1 if salaries<50 & PART_BI == 1 	
		count if (PART_BI == 1 & resultat_exploitation < 0)
		count if (CO >0 & resultat_exploitation < 0)
		count if (dividende >0 & resultat_exploitation < 0)
		*How is it possible to distribute divividend or part travail or allocate funds to collective reserve when resultat exploitation is <0 ?
		*drop if (PART_BI == 1 & resultat_exploitation < 0)
		*drop if(CO >0 & resultat_exploitation < 0)
		*dorp if(dividende >0 & resultat_exploitation < 0)
	replace PART_NLO = 0 if PART_NLO ==.
	label variable PART_NLO "1 if SCOP gives part travail even though it is not legally obliged (salaries<50), 0 otherwise" 
		gen PART_NLO_BI=1 if PART_NLO>0
		replace PART_NLO_BI = 0 if PART_NLO_BI == .
		
	gen PART_LO = 1 if salaries >=50 & PART_BI == 1
	replace PART_LO = 0 if PART_LO == . 
	label variable PART_LO "1 if SCOP gives part travail when it is legally obliged, 0 otherwise" 
	
	*SCOP does not give part travail even thought has result >0
	gen NO_PART = 1 if (PART_BI == 0 & resultat_exploitation>0)
	replace NO_PART = 0 if NO_PART == .
	label variable NO_PART "1 if the SCOP does not give part travail even though it has benefit , 0 otherwise" 
	
	gen NO_PART_NLO = 1 if (PART_BI == 0 & salarie<50 & resultat_exploitation>0)
	replace NO_PART_NLO = 0 if NO_PART_NLO == .
	label variable NO_PART_NLO "1 if the SCOP do not give (not legally obliged)part travail even though it has a benefit, 0 otherwise (no benefit or gives)" 

	gen NO_PART_LO = 1 if (PART_BI == 0 & salaries>=50 & resultat_exploitation>0) 
	replace NO_PART_LO = 0 if NO_PART_LO ==.
	label variable NO_PART_LO "1 if the SCOP do not give (legally obliged)part travail even though it has a benefit, 0 otherwise (no benefit or gives)" 

tabstat PART_BI PART_NLO PART_LO NO_PART NO_PART_NLO NO_PART_LO , stat (mean, sum)


*** Correlation
	*Between varriables of interest
		*All SCOP
		qui estpost correlate V K L LS KLS COKLS PARTL age bankrupt, matrix
		esttab . , not unstack compress noobs star(* 0.10 ** 0.05 *** 0.01)
		display in red "LS is negatively correlated with the other forms of participation"
		display in red "V is negatively correlated with LS and banrkupt but positively correlated  with K and L (highly), age, KLS, COKLS and PARTL"
		
		*Making a difference between legal status
 		qui estpost correlate V K L LS KLS COKLS PARTL age bankrupt if SARL == 1, matrix
		esttab . , not unstack compress noobs star(* 0.10 ** 0.05 *** 0.01)
		
 		qui estpost correlate V K L LS KLS COKLS PARTL age bankrupt if SARL == 0, matrix
		esttab . , not unstack compress noobs star(* 0.10 ** 0.05 *** 0.01)
	
		
		*Making a difference between size
 		qui estpost correlate V K L LS KLS COKLS PARTL age bankrupt if SMALL == 1, matrix
		esttab . , not unstack compress noobs star(* 0.10 ** 0.05 *** 0.01)
		
		qui estpost correlate V K L LS KLS COKLS PARTL age bankrupt if MEDIUM == 1, matrix
		esttab . , not unstack compress noobs star(* 0.10 ** 0.05 *** 0.01)
		
		qui estpost correlate V K L LS KLS COKLS PARTL age bankrupt if LARGE == 1, matrix
		esttab . , not unstack compress noobs star(* 0.10 ** 0.05 *** 0.01)
		
		di in red "LS is solely negatively correlated with V and the other form of participation in SMALL SCOP"
		di in red "in MEDIUM SCOP, forms of participation are negatively correlated with L, except LS"
		di in red "bankrupt is solely negatively correlated with LS and KLS in MEDIUM SCOP"

		*Making a difference between bankruptcy 
		qui estpost correlate V K L LS KLS COKLS PARTL age if bankrupt == 1, matrix
		esttab . , not unstack compress noobs star(* 0.10 ** 0.05 *** 0.01)
		
		qui estpost correlate V K L LS KLS COKLS PARTL age if bankrupt == 0, matrix
		esttab . , not unstack compress noobs star(* 0.10 ** 0.05 *** 0.01)
	
		di in red "for SCOP that has known bankrputcy, COKLS and PARTL are negatively correlated with L"
		
		qui estpost correlate V K L LS KLS COKLS PARTL age time, matrix
		esttab . , not unstack compress noobs star(* 0.10 ** 0.05 *** 0.01)
		ttest LS, by (bankrupt)
		di in red "LS is relatively higher for SCOP that has known bankrputcy"
		ttest KLS, by (bankrupt)
		di in red "KLS is relatively higher for SCOP that has not known bankrputcy"
		ttest COKLS, by (bankrupt)
		di in red "COKLS is higher for SCOP that has not known bankrputcy"
		ttest PARTL, by (bankrupt)
		di in red "PARTL is higher for SCOP that has not known bankrputcy"

		
	*Some consideration of PART
	replace dividende = 0 if dividende == .
	gen div_s = dividende/societaires
	sum div_s
		
		* Regarding SCOP that give part travail 
		qui estpost correlate V K L LS KLS COKLS dividende div_s div_ben PART_BI, matrix
		esttab . , not unstack compress noobs star(* 0.10 ** 0.05 *** 0.01)
	
		
			*Regarding SCOP that give part travail even though they are not obliged to (high level of workers participation in benefit)
			qui estpost correlate LS KLS COKLS dividende div_s div_ben PART_NLO, matrix
			esttab . , not unstack compress noobs star(* 0.10 ** 0.05 *** 0.01)
			di in red "level of workers participation (all forms) and dividend are positively correlated with the probability to distribute part travail when not legally obliged"
			
			ttest LS if (resultat_exploitation > 0), by (PART_NLO)
			di in red "higher level of workers participation in management for the SCOP that spontaneously distributes part travail"
			ttest KLS if (resultat_exploitation > 0) , by (PART_NLO)
			di in red "no significant difference in workers participation in individuel property for the SCOP that spontaneously distributes part travail"
			ttest COKLS if (resultat_exploitation > 0), by (PART_NLO)
			di in red "higher level of workers participation in collective property for the SCOP that spontaneously distributes part travail"
			ttest PARTL if (resultat_exploitation > 0), by (PART_NLO)
			di in red "higher level of workers participation in benefit for the SCOP that spontaneously distributes part travail"

			ttest dividende if (resultat_exploitation > 0), by (PART_NLO)
			ttest div_s if (resultat_exploitation > 0), by (PART_NLO)
			ttest div_ben if (resultat_exploitation > 0), by (PART_NLO)
			di in red "higher proportion of the result distributed under the form of dividend for the SCOP that spontaneously distributes part travail"

			*Regarding SCOP that give (legally obliged) part travail
			qui estpost correlate LS KLS COKLS dividende div_s div_ben PART_LO, matrix
			esttab . , not unstack compress noobs star(* 0.10 ** 0.05 *** 0.01)
			
			ttest LS if (resultat_exploitation > 0), by (PART_LO)
			ttest KLS if (resultat_exploitation > 0) , by (PART_LO)
			ttest COKLS if (resultat_exploitation > 0), by (PART_LO)
			ttest PARTL if (resultat_exploitation > 0), by (PART_LO)
			ttest dividende if (resultat_exploitation > 0), by (PART_LO)
			ttest div_s if (resultat_exploitation > 0), by (PART_LO)
			ttest div_ben if (resultat_exploitation > 0), by (PART_LO)			

		* Regarding SCOP that do not give PART TRAVAIL (low level of workers participation in benefit) even though they had benefit: if they don't give to L, is it to give to cie or shareholders?
		qui estpost correlate LS KLS COKLS dividende div_s div_ben NO_PART, matrix
		esttab . , not unstack compress noobs star(* 0.10 ** 0.05 *** 0.01)
			 
		ttest LS if (resultat_exploitation > 0), by (NO_PART)
		di in red "no difference in LS between both group"
		ttest KLS if (resultat_exploitation > 0) , by (NO_PART)
		di in red "higher KLS for the SCOP that distributes part travail"
		ttest COKLS if (resultat_exploitation > 0), by (NO_PART)
		di in red "higher COKLS for the SCOP that distributes part travail"
		ttest dividende if (resultat_exploitation > 0), by (NO_PART)
		ttest div_s if (resultat_exploitation > 0), by (NO_PART)
		ttest div_ben if (resultat_exploitation > 0), by (NO_PART)	
		di in red "higher proportion of the result distributed under the form of dividend for the SCOP that distributes part travail"

		
			* do not give because not legally obliged (salaries <50 ): if they don't give to L, is it to give to cie or shareholders?
			qui estpost correlate LS KLS COKLS dividende div_s div_ben NO_PART_NLO, matrix
			esttab . , not unstack compress noobs star(* 0.10 ** 0.05 *** 0.01)

			ttest LS if (resultat_exploitation > 0), by (NO_PART_NLO)
			di in red "no difference in LS between both group"
			ttest KLS if (resultat_exploitation > 0) , by (NO_PART_NLO)
			di in red "smaller KLS for the SCOP that do not distributes (NLO) part travail"
			ttest COKLS if (resultat_exploitation > 0), by (NO_PART_NLO)
			di in red "smaller COKLS for the SCOP that do not distributes (NLO) part travail"
			ttest dividende if (resultat_exploitation > 0), by (NO_PART_NLO)
			ttest div_s if (resultat_exploitation > 0), by (NO_PART_NLO)
			ttest div_ben if (resultat_exploitation > 0), by (NO_PART_NLO)
			di in red "smaller proportion of the result distributed under the form of dividend for the SCOP that do not distributes (NLO) part travail"

			* do not give because even though is legally obliged (salaries >= 50 )
			qui estpost correlate LS KLS COKLS dividende div_s div_ben NO_PART_LO, matrix
			esttab . , not unstack compress noobs star(* 0.10 ** 0.05 *** 0.01)
			
			ttest LS if (resultat_exploitation > 0), by (NO_PART_LO)
			di in red "smaller LS for the SCOP that do not distributes part travail even though they are obliged"
			ttest KLS if (resultat_exploitation > 0) , by (NO_PART_LO)
			di in red "no difference in KLS for the SCOP that do not distributes part travail even though they are obliged"
			ttest COKLS if (resultat_exploitation > 0), by (NO_PART_LO)
			di in red "smaller COKLS for the SCOP that do not distributes part travail even though they are obliged"
			ttest dividende if (resultat_exploitation > 0), by (NO_PART_LO)
			ttest div_s if (resultat_exploitation > 0), by (NO_PART_LO)
			ttest div_ben if (resultat_exploitation > 0), by (NO_PART_LO)
			di in red "smaller proportion of the result distributed under the form of dividend for the SCOP that do not distributes part travail even though they are obliged"


	* Some consideration of SIZE
		*SMALL
		ttest LS, by (SMALL)
		di in red "higher LS for SMALL SCOP"
		ttest KLS, by (SMALL)
		di in red "lower KLS for SMALL SCOP"
		ttest COKLS, by (SMALL)
		di in red "lower COKLS for SMALL SCOP"
		ttest PARTL, by (SMALL)
		di in red "lower PARTL for SMALL SCOP"
		ttest bankrupt, by (SMALL)
		di in red "higher probability to know bankruptcy for SMALL SCOP"
		ttest time, by (SMALL)
		di in red "no difference in time for SMALL SCOP"

		*MEDIUM
		ttest LS, by (MEDIUM)
		di in red "lower LS for MEDIUM SCOP"
		ttest KLS, by (MEDIUM)
		di in red "higher KLS for MEDIUM SCOP"
		ttest COKLS, by (MEDIUM)
		di in red "higher COKLS for MEDIUM SCOP"
		ttest PARTL, by (MEDIUM)
		di in red "higher PARTL for MEDIUM SCOP"
		ttest bankrupt, by (MEDIUM)
		di in red "lower probability to know bankruptcy for MEDIUM SCOP"
		ttest time, by (MEDIUM)
		di in red "no difference in time for MEDIUM SCOP"
	
		*LARGE
		ttest LS, by (LARGE)
		di in red "lower LS for LARGE SCOP"
		ttest KLS, by (LARGE)
		di in red "higher KLS for LARGE SCOP"
		ttest COKLS, by (LARGE)
		di in red "higher COKLS for LARGE SCOP"
		ttest PARTL, by (LARGE)
		di in red "no difference in PARTL for LARGE SCOP"
		ttest bankrupt, by (LARGE)
		di in red "lower probability to know bankruptcy for LARGE SCOP"
		ttest time, by (LARGE)
		di in red "shorter time for LARGE SCOP"
		
	* Some consideration of interessement vs participation
gen int_part = interessement/PART
replace int_part = 0 if int_part == .

gen parti_part = participation/PART
replace parti_part = 0 if parti_part == .
sum int_part parti_part if PART>0
di in red "10 % of the part travail is allocated under the form of interessement and 90% under the form of participation"
count if int_part == 1
count if parti_part == 1
di in red "183 SCOP distributes the part travail only under the form of interessement"
di in red "1748 SCOP distributes the part travail only under the form of participation"

gen int_L= interessement/L
replace int_L = 0 if int_L == .
* What to do when L == 0?

gen parti_L= participation/L
replace parti_L = 0 if parti_L == .

tabstat interessement participation int_part parti_part int_L parti_L if PART>0, stat(count mean p1 p50 p99 min max )
qui estpost correlate V LS KLS COKLS PARTL interessement participation int_part int_L parti_L if PART >0, matrix
esttab . , not unstack compress noobs star(* 0.10 ** 0.05 *** 0.01)
di in red "when the SCOP favors to distributes the part travail under the form of participation, the level of participation (LS, KLS, COKLS, PARTL) are higher"

/********************************************************************************

								1.ALL SCOP
								
********************************************************************************/
// -----------------------------------------------------------------------------
					***REGRESSIONS: STATIC PANEL DATA***
//------------------------------------------------------------------------------
global id id
global t t
global ylist lnV
global xlist lnL lnK age LS COKLS KLS PARTL PART_NLO_BI
global zlist exnihilo transf transmi reanim FR4 FR6 FR7 FR2 FR5 FR8 FR9 FR3 AGR COM EDU INDUMA SERV TRANS INDUEX SARL 
xtsum $id $t $ylist $xlist $zlist


*** FE within estimator
xtreg $ylist $xlist /*$zlist*/, fe 
estat ic
est store fixed
xtreg $ylist $xlist /*$zlist*/, fe r cluster (id)
estat ic
est store fixedr
*some variables omitted are time invariant 
di in red "relatively high rho : good news because it is not idiosyncratic"
di in red "unobserved hetero (corr(u_i, Xb)  = 0.6009 ): no pooled OLS"
di in red "better AIC and BIC for FE within not cluster"
/*Choice-->xtreg $ylist $xlist, fe */

/** linear prediction (x*beta_hat)
        predict fe_xb, xb
    ** linear prediction including FE component (x*beta_hat + alphai_hat)
        predict fe_xb_alphai, xbu
    ** prediction of FE (alphai_hat)
        predict fe_alphai, u
    ** prediction of idiosyncratic error term (e_hat)
        predict fe_e, e
    ** prediction of FE and idiosyncratic error term (alphai_hat + e_hat)
        predict fe_alphai_e, ue
    list t fe_xb fe_xb_alphai fe_alphai fe_e //in 1/20*/


*** FE First-differences estimator
reg D.($ylist $xlist) $zlist, nocon 
estat ic
reg D.($ylist $xlist) $zlist, nocon r cluster (id)
estat ic
est store fixeddiff

	*to test strict exo in FE within estimator
	xtreg $ylist $xlist $zlist F.($xlist), fe
	di in red "F.lnL and F.lnK significative --> KO --> dynamic model"
	*to test strict exo in FE First-differences estimator
	reg D.($ylist $xlist)$zlist $xlist , noconstant
	di in red "lnL and lnK significative --> KO --> dynamic model"

* Between estimator (should not be used)
xtreg $ylist $xlist $zlist, be
est store between

* Random effects estimator (should not be used because assumption that corr(u_i, Xb) = 0)
xtreg $ylist $xlist $zlist, re 
est store random
xtreg $ylist $xlist $zlist, re cluster (id)

*xtoverid, cluster(id)
*rho still ok but less high--> good news because it is not idiosyncratic

* fixed versus random effects model: Hausman test  
hausman fixed random
*--> significant result (RH0): FE
* an aletrnative is the Sargan-Hansen-Test of overidentifying restrictions: fixed vs random effects 
 ** assuming homoskedastic error terms
    xtreg $ylist $xlist $zlist, re 
    *xtoverid
    di r(j)
	* assuming heteroskedastic error terms  
    xtreg $ylist $xlist $zlist, re r cluster(id)
	//xtoverid, robust cluster(id)
    //xtoverid
    di r(j)
    

* random effects versus OLS: Breusch-Pagan LM test  
quietly xtreg $ylist $xlist $zlist, re
xttest0
quietly xtreg $ylist $xlist $zlist, re r cluster (id)
xttest0

* Recovering individual-specific effects
quietly xtreg $ylist $xlist $zlist, fe
predict alphafehat, u
sum alphafehat
*don't know what cause it but individual specific effect that cause higher or lower

// -----------------------------------------------------------------------------
					***REGRESSIONS: Dynamic linear model***
//------------------------------------------------------------------------------
xtset id t
global id id
global t t
global ylist lnV
global xlist lnL lnK age LS COKLS KLS PARTL PART_NLO_BI
global zlist exnihilo transf transmi reanim FR4 FR6 FR7 FR2 FR5 FR8 FR9 FR3 AGR COM EDU INDUMA SERV TRANS INDUEX SARL

/*-------------------------------------------------------------------------------------------*\
* A. IV estimates
\*-------------------------------------------------------------------------------------------*/

**********************************************************************************************
* A1. IV-AH estimator using yi,t-2 - yi,t-3 as instrument --> not enough period (requires at least 4 period)
**********************************************************************************************
* A2. IV-AH estimator using yi,t-2 as instrument
**********************************************************************************************

** Using ivregress

	ivregress 2sls D.$ylist D.($xlist) $zlist (L.D.$ylist = L.L.$ylist)
	ivregress 2sls D.$ylist D.($xlist) $zlist (L.D.$ylist = L.L.$ylist),  robust 
	estat first //give the bias (F Z) report "first-stage" regression statistics
	est store ivreg	
	estat endogenous
	
/*The Anderson–Hsiao estimator is asymptotically inefficient, as its asymptotic variance is higher than the Arellano–Bond estimator
--> Arellano–Bond estimator: use generalized method of moments estimation rather than instrumental variables estimation.*/
	
	
/*-------------------------------------------------------------------------------------------*\
* B. GMM estimation
\*-------------------------------------------------------------------------------------------*/
/*Though asymptotically more efficient, the two-step estimates of the standard errors tend to be severely downward biased (Arellano and Bond 1991; Blundell and Bond 1998). 
To compensate, xtabond2, unlike xtabond, makes available a finite-sample correction to the two-step covariance matrix derived by Windmeijer (2000).*/
* 1. with strictly exogenous variables
xtabond2 $ylist L.$ylist $xlist  t, gmm($ylist) iv($xlist) noleveleq robust 
xtabond2 $ylist L.$ylist $xlist t, gmm($ylist) iv($xlist) twostep noleveleq robust 
*2. with predetermined variables
xtabond2  $ylist L.$ylist $xlist, gmm(L.$ylist $xlist) iv($xlist)  noleveleq robust
di in red "SARGAN/HANSEN: large p_val --> NRH0 --> correct model specification"
xtabond2  $ylist L.$ylist $xlist, gmm(L.$ylist $xlist) iv($xlist) twostep noleveleq robust
di in red "SARGAN/HANSEN: large p_val --> NRH0 --> correct model specification"

xtabond2  $ylist L.$ylist $xlist, gmm(L.$ylist $xlist) iv(LS KLS)  noleveleq robust

/*“smaller is better”: given two models, the one with the smaller AIC fits the data better
than the one with the larger AIC. As with the AIC, a smaller BIC indicates a better-fitting model*/

*3. with $xlist endogenous
xtabond2 $ylist L.$ylist $xlist, gmm(L.$ylist) gmm($xlist) noleveleq  robust
xtabond2 $ylist L.$ylist $xlist, gmm(L.$ylist) gmm($xlist) noleveleq  twostep robust
di in red "large p_val --> NRH0 --> correct model specification"

*4. with LS, KLS and age are predetermined variables and COKLS, PARTL and PART_NLO_BI are endogenous variables
xtabond2 $ylist L.$ylist $xlist, gmm(L.$ylist) gmm($xlist) iv(age LS KLS) noleveleq  robust
xtabond2 $ylist L.$ylist $xlist, gmm(L.$ylist) gmm($xlist) iv(age LS KLS) noleveleq  twostep robust


 
/* gmm (endo_var, laglimts(# .)) : endo_var is endogenous and that you use # and all further available lags of endo_var as instruments 
* noleveleq :  noleveleq specifies that level equation should be excluded from the estimation, yielding difference rather than system GMM
* collapse: specifies that xtabond2 should create one instrument for each variable and lag distance, rather than one for each time period,
 variable, and lag distance.  In large samples, collapse reduces statistical efficiency.  But in small samples it can avoid the bias that arises as the number of
instruments climbs toward the number of observations.
*iv (str_exo): str_exo are the variables strictly exo
*robust: For one-step estimation, robust specifies that the robust estimator of the covariance matrix of the parameter estimates be calculated. finite-sample correction for
        the two-step covariance matrix
*twostep: the standard covariance
        matrix is already robust in theory--but typically yields standard errors that are downward biased
*/


// -----------------------------------------------------------------------------
					***REGRESSIONS: COX***
//------------------------------------------------------------------------------
***Cox regresion
global time time
global event bankrupt
global xlist age L K LS KLS COKLS PARTL SARL AGR COM CONSTRU EDU INDUEX INDUMA SERV TRANS FR1 FR2 FR3 FR4 FR5 FR6 FR7 FR8 FR9 exnihilo reanim transf transmi
global group PART_NLO_BI
describe $time $event $xlist
tabstat $time $event, stat(mean, sum)
 
* Set data as survival time
stset $time, id(id) failure($event)
stdescribe 
stsum
strate



* Nonparametric estimation
*The hazard rate is the probability that the SCOP goes bankrupt at time t given that the individual is at risk at time t.
* Graph of hazard ratio
sts graph, hazard
*as time goes on, people are less likely to experience the event
* Graph of cumulative hazard ratio (Nelson-Aalen cumulative hazard curve)
sts graph, cumhaz
*Graph of survival function (Kaplan-Meier survival curve)(the probability that the time will be at least t) (at t, porcentage of ht epopulation that remains, not experienced the event)
sts graph, survival
* List of survival function 
sts list, survival
sts graph if resultat_exploitation > 0, by (PART_NLO_BI)
di in red "considering only those with positive results, those whose ditributes part travail even though they are not obliged to knows less bankruptcy"
sts test $group if resultat_exploitation > 0 
di in red "difference in survivor function"


*xtstreg $xlist year, nohr dist(exponential)
* Parametric models
* Exponential regression coefficients and hazard rates
streg $xlist, nohr dist(exponential)
estat ic 
streg $xlist, dist(exponential)
* Weibull regression coefficients and hazard rates
streg $xlist, nohr dist(weibull)
 estat ic 
streg $xlist, dist(weibull)
* Gompertz regression coefficients and hazard rates
streg $xlist, nohr dist(gompertz)
streg $xlist, dist(gompertz)
* Cox proportional hazard model coefficients and hazard rates
stcox $xlist, nohr
stcox $xlist



/********************************************************************************

								2.DROPPING SMALL (L<10) SCOP
								
********************************************************************************/
// -----------------------------------------------------------------------------
					***REGRESSIONS: STATIC PANEL DATA***
//------------------------------------------------------------------------------
global id id
global t t
global ylist lnV
global xlist lnL lnK age LS COKLS KLS PARTL PART_NLO_BI
global zlist exnihilo transf transmi reanim FR4 FR6 FR7 FR2 FR5 FR8 FR9 FR3 AGR COM EDU INDUMA SERV TRANS INDUEX SARL 
xtsum $id $t $ylist $xlist $zlist

*** FE within estimator
xtreg $ylist $xlist, fe, if SMALL == 0
estat ic
est store fixeds
xtreg $ylist $xlist, fe r cluster (id), if SMALL == 0 
estat ic
*some variables omitted are time invariant 
di in red "relatively high rho : good news because it is not idiosyncratic"
di in red "unobserved hetero (corr(u_i, Xb)  =  0.2086  ): no pooled OLS"
di in red "better AIC and BIC for FE within cluster"

*** FE First-differences estimator
reg D.($ylist $xlist) $zlist, nocon, if SMALL == 0
estat ic
est store fixeddiff
reg D.($ylist $xlist) $zlist, nocon r cluster (id), if SMALL == 0 
estat ic

	*to test strict exo in FE within estimator
	xtreg $ylist $xlist F.($xlist), fe r cluster (id), if SMALL == 0
	di in red "F.lnL and F.lnK significative --> KO --> dynamic model"
	*to test strict exo in FE First-differences estimator
	reg D.($ylist $xlist)$xlist $zlist , noconstant r cluster (id), if SMALL == 0
	di in red "lnL and lnK significative --> KO --> dynamic model"

* Between estimator (should not be used)
xtreg $ylist $xlist $zlist, be, if SMALL == 0
est store between

* Random effects estimator
xtreg $ylist $xlist $zlist, re , if SMALL == 0
est store randoms
*rho still ok but less high--> good news because it is not idiosyncratic

* fixed versus random effects model: Hausman test  
xtreg $ylist $xlist $zlist, fe, if SMALL == 0
    est store fe
    xtreg $ylist $xlist $zlist, re, if SMALL == 0
    est store re
    hausman fe re, sigmaless
hausman fe re
*--> significant result (RH0): FE

* random effects versus OLS: Breusch-Pagan LM test  
quietly xtreg $ylist $xlist $zlist, re, if SMALL == 0
xttest0
*--> RH0: RE

* Recovering individual-specific effects
quietly xtreg $ylist $xlist $zlist, fe, if SMALL == 0
predict alphafehatbis, u
sum alphafehat
// -----------------------------------------------------------------------------
					***REGRESSIONS: Dynamic linear model***
//------------------------------------------------------------------------------
/*-------------------------------------------------------------------------------------------*\
* A. IV estimates: IV-AH estimator using yi,t-2 as instrument
\*-------------------------------------------------------------------------------------------*/

** Using ivregress

	ivregress 2sls D.$ylist D.($xlist) $zlist (L.D.$ylist = L.L.$ylist) if SMALL == 0
	estat endogenous
    ivregress 2sls D.$ylist D.($xlist) $zlist (L.D.$ylist = L.L.$ylist) if SMALL == 0, robust 
		estat endogenous

	estat first //give the bias (F Z)
	
/*The Anderson–Hsiao estimator is asymptotically inefficient, as its asymptotic variance is higher than the Arellano–Bond estimator
--> Arellano–Bond estimator: use generalized method of moments estimation rather than instrumental variables estimation.*/
/*-------------------------------------------------------------------------------------------*\
* B. GMM estimation
\*-------------------------------------------------------------------------------------------*/
/* 1. with strictly exogenous variables
xtabond2 $ylist L.$ylist $xlist if SMALL == 0 , gmm($ylist) iv($xlist) noleveleq robust 
xtabond2 $ylist L.$ylist $xlist if SMALL == 0 , gmm($ylist) iv($xlist) twostep noleveleq robust */
*2. with predetermined variables
xtabond2  $ylist L.$ylist $xlist if SMALL == 0, gmm(L.$ylist $xlist) iv($xlist)  noleveleq robust
di in red "SARGAN/HANSEN: large p_val --> NRH0 --> correct model specification"
xtabond2  $ylist L.$ylist $xlist if SMALL == 0, gmm(L.$ylist $xlist) iv($xlist) twostep noleveleq robust
di in red "SARGAN/HANSEN: large p_val --> NRH0 --> correct model specification"
*3. with $xlist endogenous
xtabond2 $ylist L.$ylist $xlist if SMALL == 0, gmm(L.$ylist) gmm($xlist) noleveleq  robust
xtabond2 $ylist L.$ylist $xlist if SMALL == 0, gmm(L.$ylist) gmm($xlist) noleveleq  twostep robust
di in red "large p_val --> NRH0 --> correct model specification"
*4. with LS, KLS and age are predetermined variables and COKLS, PARTL and PART_NLO_BI are endogenous variables
xtabond2 $ylist L.$ylist $xlist if SMALL == 0, gmm(L.$ylist) gmm($xlist) iv(age LS KLS) noleveleq  robust
xtabond2 $ylist L.$ylist $xlist if SMALL == 0, gmm(L.$ylist) gmm($xlist) iv(age LS KLS) noleveleq  twostep robust

// -----------------------------------------------------------------------------
					***REGRESSIONS: COX***
//------------------------------------------------------------------------------
***Cox regresion
global time time
global event bankrupt
global xlist age L K LS PARTL KLS COKLS SARL AGR COM CONSTRU EDU INDUEX INDUMA SERV TRANS FR1 FR2 FR3 FR4 FR5 FR6 FR7 FR8 FR9 exnihilo reanim transf transmi
global group 
describe $time $event $xlist
summarize $time $event $xlist
 
* Set data as survival time
stset $time, id(id) failure($event)
	
	

/********************************************************************************

								3.KEEPING ONLY PART_NLO>0
					
********************************************************************************/
// -----------------------------------------------------------------------------
					***REGRESSIONS: STATIC PANEL DATA***
//------------------------------------------------------------------------------

global id id
global t t
global ylist lnV
global xlist lnL lnK age LS COKLS KLS PARTL
global zlist exnihilo transf transmi reanim FR4 FR6 FR7 FR2 FR5 FR8 FR9 FR3 AGR COM EDU INDUMA SERV TRANS INDUEX SARL 

*** FE within estimator
xtreg $ylist $xlist PART_NLO_BI, fe 
estat ic
xtreg $ylist $xlist PART_NLO_BI, fe r cluster (id)
estat ic

xtreg $ylist $xlist, fe, if PART_NLO>0
estat ic
xtreg $ylist $xlist if PART_NLO>0 , fe r cluster (id)
estat ic
est store fixeds
*some variables omitted are time invariant 
di in red "relatively high rho : good news because it is not idiosyncratic"
di in red "unobserved hetero (corr(u_i, Xb)  =  0.4639   ): no pooled OLS"
di in red "better AIC and BIC for FE within cluster"

*** FE First-differences estimator
reg D.($ylist $xlist) $zlist PART_NLO_BI, nocon 
reg D.($ylist $xlist) $zlist if PART_NLO>0, nocon 
est store fixeddiff
reg D.($ylist $xlist) $zlist if PART_NLO>0, nocon r cluster (id)
estat ic

	*to test strict exo in FE within estimator
	xtreg $ylist $xlist F.($xlist) if PART_NLO>0, fe r cluster (id) 
	di in red "F.lnL significative --> KO --> dynamic model"
	*to test strict exo in FE First-differences estimator
	reg D.($ylist $xlist)$xlist $zlist if PART_NLO>0 , noconstant r cluster (id)
	di in red "lnL and lnK not significative --> ok  --> not dynamic model"

* Between estimator (should not be used)
xtreg $ylist $xlist $zlist if PART_NLO>0, be
est store between

* Random effects estimator
xtreg $ylist $xlist $zlist if PART_NLO>0, re 
est store randoms
*rho still ok but less high--> good news because it is not idiosyncratic

* fixed versus random effects model: Hausman test  
xtreg $ylist $xlist if PART_NLO>0, fe 
    est store fe
    xtreg $ylist $xlist $zlist if PART_NLO>0, re, 
    est store re
    hausman fe re, sigmaless
hausman fe re
*--> significant result (RH0): FE

* random effects versus OLS: Breusch-Pagan LM test  
quietly xtreg $ylist $xlist $zlist if PART_NLO>0, re
xttest0
*--> RH0: RE

* Recovering individual-specific effects
quietly xtreg $ylist $xlist $zlist, fe, if PART_NLO>0
predict alphafehatbis, u
sum alphafehat

// -----------------------------------------------------------------------------
					***REGRESSIONS: Dynamic linear model***
//------------------------------------------------------------------------------

/*-------------------------------------------------------------------------------------------*\
* A. IV estimates: IV-AH estimator using yi,t-2 as instrument
\*-------------------------------------------------------------------------------------------*/

** Using ivregress

	ivregress 2sls D.$ylist D.($xlist) $zlist (L.D.$ylist = L.L.$ylist) if PART_NLO>0
    ivregress 2sls D.$ylist D.($xlist) $zlist (L.D.$ylist = L.L.$ylist) if PART_NLO>0, robust
	estat first //give the bias (F Z)
    ivregress 2sls D.$ylist D.($xlist) $zlist PART_NLO_BI (L.D.$ylist = L.L.$ylist), robust
	
/*The Anderson–Hsiao estimator is asymptotically inefficient, as its asymptotic variance is higher than the Arellano–Bond estimator
--> Arellano–Bond estimator: use generalized method of moments estimation rather than instrumental variables estimation.*/

/*-------------------------------------------------------------------------------------------*\
* B. GMM estimation
\*-------------------------------------------------------------------------------------------*/
* 1. with strictly exogenous variables
/*xtabond2 $ylist L.$ylist $xlist if PART_NLO>0, gmm($ylist) iv($xlist) noleveleq robust 
xtabond2 $ylist L.$ylist $xlist  if PART_NLO>0, gmm($ylist) iv($xlist) twostep noleveleq robust*/ 
*2. with predetermined variables
xtabond2  $ylist L.$ylist $xlist if PART_NLO>0, gmm(L.$ylist $xlist) iv($xlist)  noleveleq robust
di in red "SARGAN/HANSEN: large p_val --> NRH0 --> correct model specification"
xtabond2  $ylist L.$ylist $xlist if PART_NLO>0, gmm(L.$ylist $xlist) iv($xlist) twostep noleveleq robust
di in red "SARGAN/HANSEN: large p_val --> NRH0 --> correct model specification"
*3. with $xlist endogenous
xtabond2 $ylist L.$ylist $xlist if PART_NLO>0, gmm(L.$ylist) gmm($xlist) noleveleq  robust
di in red "large p_val --> NRH0 --> correct model specification"
/*xtabond2 $ylist L.$ylist $xlistif if PART_NLO>0, gmm(L.$ylist) gmm($xlist) noleveleq  twostep robust*/

*2. with predetermined variables
xtabond2  $ylist L.$ylist $xlist PART_NLO_BI, gmm(L.$ylist $xlist) iv($xlist PART_NLO_BI)  noleveleq robust
di in red "SARGAN/HANSEN: large p_val --> NRH0 --> correct model specification"
xtabond2  $ylist L.$ylist $xlist PART_NLO_BI, gmm(L.$ylist $xlist) iv($xlist PART_NLO_BI) twostep noleveleq robust
di in red "SARGAN/HANSEN: large p_val --> NRH0 --> correct model specification"
*3. with $xlist endogenous
xtabond2 $ylist L.$ylist $xlist PART_NLO_BI, gmm(L.$ylist) gmm($xlist PART_NLO_BI) noleveleq  robust
di in red "large p_val --> NRH0 --> correct model specification"
xtabond2 $ylist L.$ylist $xlistif PART_NLO_BI, gmm(L.$ylist) gmm($xlist PART_NLO_BI) noleveleq  twostep robust


// -----------------------------------------------------------------------------
					***REGRESSIONS: COX***
//------------------------------------------------------------------------------
***Cox regresion
global time time
global event bankrupt
global xlist age L K LS PARTL KLS COKLS SARL AGR COM CONSTRU EDU INDUEX INDUMA SERV TRANS FR1 FR2 FR3 FR4 FR5 FR6 FR7 FR8 FR9 exnihilo reanim transf transmi
global group 
describe $time $event $xlist
summarize $time $event $xlist
 
* Set data as survival time
stset $time, id(id) failure($event)

/********************************************************************************

								4.SEPARATING INT FROM PARTI IN PARTL
					
********************************************************************************/

// -----------------------------------------------------------------------------
					***REGRESSIONS: STATIC PANEL DATA***
//------------------------------------------------------------------------------
global id id
global t t
global ylist lnV
global xlist lnK lnL age LS KLS COKLS int_L parti_L PART_NLO_BI
global zlist exnihilo transf transmi reanim FR4 FR6 FR7 FR2 FR5 FR8 FR9 FR3 AGR COM EDU INDUMA SERV TRANS INDUEX SARL 

ivregress 2sls D.$ylist D.($xlist) $zlist (L.D.$ylist = L.L.$ylist), robust
estat endogenous
ivregress 2sls D.$ylist D.($xlist) $zlist (L.D.$ylist = L.L.$ylist) if SMALL == 0, robust
estat endogenous

xtabond2 $ylist L.$ylist $xlist, gmm(L.$ylist) gmm($xlist) iv(age LS KLS) noleveleq  robust
xtabond2 $ylist L.$ylist $xlist, gmm(L.$ylist) gmm($xlist) iv(age LS KLS) noleveleq  twostep robust
xtabond2 $ylist L.$ylist $xlist if SMALL == 0, gmm(L.$ylist) gmm($xlist) iv(age LS KLS) noleveleq  robust
xtabond2 $ylist L.$ylist $xlist if SMALL == 0, gmm(L.$ylist) gmm($xlist) iv(age LS KLS) noleveleq  twostep robust
***FE within
xtreg $ylist $xlist, fe
estat ic
xtreg $ylist $xlist, fe r cluster (id)
estat ic
est store fixeds
*some variables omitted are time invariant 
di in red "relatively high rho : good news because it is not idiosyncratic"
di in red "unobserved hetero (corr(u_i, Xb)  = 0.5885 ): no pooled OLS"
di in red "better AIC and BIC for FE within cluster"

*** FE First-differences estimator
reg D.($ylist $xlist) $zlist, nocon 
est store fixeddiff
reg D.($ylist $xlist) $zlist, nocon r cluster (id)
estat ic

	*to test strict exo in FE within estimator
	xtreg $ylist $xlist F.($xlist), fe r cluster (id) 
	di in red "F.lnL significative --> KO --> dynamic model"
	*to test strict exo in FE First-differences estimator
	reg D.($ylist $xlist)$xlist $zlist, noconstant r cluster (id)
	di in red "lnL and lnK not significative --> KO --> dynamic model"

* Between estimator (should not be used)
xtreg $ylist $xlist $zlist, be
est store between

* Random effects estimator
xtreg $ylist $xlist $zlist, re 
est store randoms
*rho still ok but less high--> good news because it is not idiosyncratic

* fixed versus random effects model: Hausman test  
xtreg $ylist $xlist, fe 
    est store fe
    xtreg $ylist $xlist $zlist, re 
    est store re
    hausman fe re, sigmaless
hausman fe re
*--> significant result (RH0): FE

* random effects versus OLS: Breusch-Pagan LM test  
quietly xtreg $ylist $xlist $zlist, re
xttest0
*--> RH0: RE

* Recovering individual-specific effects
quietly xtreg $ylist $xlist $zlist, fe
predict alphafehatbis, u
sum alphafehat

// -----------------------------------------------------------------------------
					***REGRESSIONS: Dynamic linear model***
//------------------------------------------------------------------------------
/*-------------------------------------------------------------------------------------------*\
* A. IV estimates: IV-AH estimator using yi,t-2 as instrument
\*-------------------------------------------------------------------------------------------*/

** Using ivregress

	ivregress 2sls D.$ylist D.($xlist) $zlist (L.D.$ylist = L.L.$ylist)
    ivregress 2sls D.$ylist D.($xlist) $zlist (L.D.$ylist = L.L.$ylist), robust
	estat first //give the bias (F Z)
	
/*The Anderson–Hsiao estimator is asymptotically inefficient, as its asymptotic variance is higher than the Arellano–Bond estimator
--> Arellano–Bond estimator: use generalized method of moments estimation rather than instrumental variables estimation.*/

/*-------------------------------------------------------------------------------------------*\
* B. GMM estimation
\*-------------------------------------------------------------------------------------------*/
* 1. with strictly exogenous variables
xtabond2 $ylist L.$ylist $xlist , gmm($ylist) iv($xlist) noleveleq robust 
xtabond2 $ylist L.$ylist $xlist , gmm($ylist) iv($xlist) twostep noleveleq robust 
*2. with predetermined variables
xtabond2  $ylist L.$ylist $xlist, gmm(L.$ylist $xlist) iv($xlist)  noleveleq robust
di in red "SARGAN/HANSEN: large p_val --> NRH0 --> correct model specification"
xtabond2  $ylist L.$ylist $xlist, gmm(L.$ylist $xlist) iv($xlist) twostep noleveleq robust
di in red "SARGAN/HANSEN: large p_val --> NRH0 --> correct model specification"
*3. with $xlist endogenous
xtabond2 $ylist L.$ylist $xlist, gmm(L.$ylist) gmm($xlist) noleveleq  robust
xtabond2 $ylist L.$ylist $xlist, gmm(L.$ylist) gmm($xlist) noleveleq  twostep robust
di in red "large p_val --> NRH0 --> correct model specification"

// -----------------------------------------------------------------------------
					***REGRESSIONS: COX***
//------------------------------------------------------------------------------
***Cox regresion
global time time
global event bankrupt
global xlist age L K LS PARTL KLS COKLS SARL AGR COM CONSTRU EDU INDUEX INDUMA SERV TRANS FR1 FR2 FR3 FR4 FR5 FR6 FR7 FR8 FR9 exnihilo reanim transf transmi
global group 
describe $time $event $xlist
summarize $time $event $xlist
 
* Set data as survival time
stset $time, id(id) failure($event)



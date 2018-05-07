/***********************
* IMPORT DATASET       *
***********************/
ods graphics on;
PROC IMPORT OUT= WORK.diabetes DATAFILE= "C:\Users\Aubhik\Desktop\MS\spring2018\CS 593 - Data Mining 2\finalProject\diabetes.csv" 
            DBMS=CSV REPLACE;
     		GETNAMES=YES;
     		DATAROW=2; 
RUN;
/**********************************
* IMPORT DATASET WITH 10 LEVERAGE *
*  AND INFLUENCE POINTS REMOVED   *
**********************************/
PROC IMPORT OUT= WORK.diabeteslevinf DATAFILE= "C:\Users\Aubhik\Desktop\MS\spring2018\CS 593 - Data Mining 2\finalProject\dblevinf.csv" 
            DBMS=CSV REPLACE;
     		GETNAMES=YES;
     		DATAROW=2; 
RUN;
/*********************
*	SPLIT DATASET    *
*********************/

data trainset;
	set diabeteslevinf;
	if _n_>600 then delete;
run;

data testset;
	set diabeteslevinf;
	if _n_<601 then delete;
run;
/***********************
* INITIAL ANALYSIS     *
***********************/
proc univariate data=trainset;
	var pregnancies glucose bloodpressure skinthickness insulin bmi diabetespedigreefunction age;
run;
quit;

/***********************
* STANDARDIZE DATASET  *
***********************/
proc standard data=diabeteslevinf mean=0 std=1 out=diabetes_z;
	var pregnancies glucose bloodpressure skinthickness insulin bmi diabetespedigreefunction age;
run;



/***********************
*CALCULATE CORRELATION *
***********************/
proc corr data=trainset_z; 
	var pregnancies glucose bloodpressure skinthickness insulin bmi diabetespedigreefunction age;
run;

/****************************
* FIND PRINCIPAL COMPONENTS *
****************************/
proc princomp data=diabetes_z out=diabetes_z_pca;
	var skinthickness insulin bmi diabetespedigreefunction age pregnancies glucose bloodpressure;
run;
quit;
data trainset_z_pca;
	set diabetes_z_pca;
	if _n_>600 then delete;
run;

data testset_z_pca;
	set diabetes_z_pca;
	if _n_<601 then delete;
run;
/******************************
* ADD IDs to dataset for ease *
******************************/
data diabetes;
	set diabetes;
	id = _n_;
run;

/***********************
* LINEAR REGRESSION TO *
* CALCULATE	THE DPF	   *
* NOT POSSIBLE AS      *
* MSE=0.1025(too high) *		
***********************/

proc reg data=trainset OUTEST=test1;
	model diabetespedigreefunction= skinthickness insulin bmi age pregnancies glucose bloodpressure outcome /STB SELECTION=STEPWISE STB vif; 
	OUTPUT h=lev cookd=Cookd  dffits=dffit L95M=C_l95m  U95M=C_u95m  L95=C_l95 U95=C_u95
         ; 
run;
quit;

/*****************************
*	NULL HYPOTHESIS TESTS    *
*****************************/
proc sql;
	create table correct as
	select count(*) as correct from
	trainset where outcome=1;
	create table total_obs as
	select count(*) as denom from
	trainset;
	create table null1 as
	select a.correct * 100/b.denom as accuracy
	from correct a, total_obs b;
quit;
proc sql;
	create table correct as
	select count(*) as correct from
	trainset where outcome=0;
	create table total_obs as
	select count(*) as denom from
	predictions;
	create table null0 as
	select a.correct * 100/b.denom as accuracy
	from correct a, total_obs b;
quit;

*_______MODEL1____________________;
/**********************************
* RUN LINEAR REGRESSION      	  *
* USING ONLY ORIGINAL VARIABLES   *
**********************************/
proc reg data=trainset OUTEST=test;
	model outcome=  skinthickness insulin bmi diabetespedigreefunction age pregnancies glucose bloodpressure / STB SELECTION=STEPWISE vif; 
	OUTPUT OUT=modeldata h=lev cookd=Cookd  dffits=dffit L95M=C_l95m  U95M=C_u95m  L95=C_l95 U95=C_u95
         ; 
run;
quit;
*Remove age as it is not significant;

proc reg data=trainset OUTEST=test;
	model outcome=  skinthickness insulin bmi diabetespedigreefunction age pregnancies glucose bloodpressure / STB SELECTION=STEPWISE vif; 
	OUTPUT OUT=modeldata h=lev cookd=Cookd  dffits=dffit L95M=C_l95m  U95M=C_u95m  L95=C_l95 U95=C_u95
         ; 
run;
quit;
/*****************************************
* USE SCORE TO FIND PREDICTED CONTINUOUS *
* VALUES FOR OUTCOME                     *
*****************************************/ 
proc score data=testset score=test out=RScoreP type=parms;
   var glucose bmi pregnancies diabetespedigreefunction bloodpressure age;
run;
/******************************************
* 	USE 0.6 AS THRESHOLD TO SET OUTCOME   *
*	TO 0 or 1							  *
******************************************/
data Predictions;
	set Rscorep;
	outcome = outcome;
	if model1>=0.6 then prediction=1;
	else prediction=0;
run;

/**************************************************************************
*CALCULATE SCORE USING ACCURACY CALCULATOR (below) => ACCURACY = 76.667%  *
**************************************************************************/
*------------------------------------------------------------------------;
*_________MODEL2__________________;	
/**********************************
* RUN LINEAR REGRESSION      	  *
* USING ALL PRINCIPAL 			  *
* COMPONENTS  					  *
**********************************/
proc reg data=trainset_z_pca OUTEST=test;
	model outcome= prin1--prin8 /STB SELECTION=stepwise; 
	OUTPUT h=lev cookd=Cookd  dffits=dffit L95M=C_l95m  U95M=C_u95m  L95=C_l95 U95=C_u95
         ; 
run;
quit;


/*****************************************
* USE SCORE TO FIND PREDICTED CONTINUOUS *
* VALUES FOR OUTCOME                     *
*****************************************/ 
proc score data=testset_z_pca score=test out=RScoreP type=parms;
   var prin1 prin2 prin3 prin5 prin6 prin8;
run;
/******************************************
* 	USE 0.6 AS THRESHOLD TO SET OUTCOME   *
*	TO 0 or 1							  *
******************************************/
data Predictions;
	set Rscorep;
	outcome = outcome;
	if model1>=0.6 then prediction=1;
	else prediction=0;
run;
/*************************************************************************
*CALCULATE SCORE USING ACCURACY CALCULATOR (below) => ACCURACY = 76% *
*************************************************************************/ 
*------------------------------------------------------------------------;
*__________MODEL3_______________________;
/****************************************
* RUN LINEAR REGRESSION          		*
* USING EXTRACTED PRINCIPAL COMPONENTS 	*
* AND STEPWISE SELECTION		 		*		
* ACCURACY = 75.911%			 		*
****************************************/
proc reg data=trainset_z_pca OUTEST=test;
	model outcome= prin1--prin6 /STB;
	OUTPUT h=lev cookd=Cookd  dffits=dffit L95M=C_l95m  U95M=C_u95m  L95=C_l95 U95=C_u95
         ; 
run;
quit;


*REMOVE PRIN4 BECAUSE IT IS NOT SIGNIFICANT;
proc reg data=trainset_z_pca OUTEST=test;
	model outcome= prin1 prin2 prin3 prin5 prin6; 
	OUTPUT h=lev cookd=Cookd  dffits=dffit L95M=C_l95m  U95M=C_u95m  L95=C_l95 U95=C_u95
         ; 
run;
quit;
/*****************************************
* USE SCORE TO FIND PREDICTED CONTINUOUS *
* VALUES FOR OUTCOME                     *
*****************************************/ 
proc score data=testset_z_pca score=test out=RScoreP type=parms;
   var prin1 prin2 prin3 prin5 prin6;
run;
/******************************************
* 	USE 0.6 AS THRESHOLD TO SET OUTCOME   *
*	TO 0 or 1							  *
******************************************/
data Predictions;
	set Rscorep;
	outcome = outcome;
	if model1>=0.6 then prediction=1;
	else prediction=0;
run;
/*************************************************************************
*CALCULATE SCORE USING ACCURACY CALCULATOR (below) => ACCURACY = 74% *
*************************************************************************/
*------------------------------------------------------------------------;

/****************************
* 	ACCURACY CALCULATOR     *
****************************/
proc sql;
	create table correct as
	select count(*) as correct from
	Predictions where outcome=prediction;
	create table total_obs as
	select count(*) as denom from
	predictions;
	create table accuracy as
	select a.correct * 100/b.denom as accuracy
	from correct a, total_obs b;
quit;

/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/

/***********************
* LOGISTIC REGRESSION  *
***********************/

/**********************
* MODEL1: No change   *
**********************/

proc logistic data=trainset descending;
	model outcome=pregnancies glucose bloodpressure skinthickness insulin bmi DiabetesPedigreefunction age;
quit;
/**********************
* TEST2: +V_insulin   *
**********************/
data diabetes2;
	set diabeteslevinf;
	if insulin>0 then V_insulin=1;
	else V_insulin=0;
run;
data trainset2;
	set diabetes2;
	if _n_>600 then delete;
run;

data testset2;
	set diabetes2;
	if _n_<601 then delete;
run;
proc freq data=diabetes2;
	tables outcome*V_insulin;
run;
proc logistic data=trainset2 desc;
	class V_insulin(ref='0')/param=ref;
	model outcome=pregnancies glucose bloodpressure skinthickness V_insulin bmi DiabetesPedigreefunction age /SELECTION=STEPWISE;
run;
quit;

/**********************
* TEST3: +V_bmi    *
**********************/
	
data diabetes2;
	set diabetes2;
	if bmi>=35 then V_bmi=1;
	else V_bmi=0;	
run;
data trainset2;
	set diabetes2;
	if _n_>600 then delete;
run;

data testset2;
	set diabetes2;
	if _n_<601 then delete;
run;

proc freq data=diabetes2;
	tables outcome*V_bmi;
run;

proc logistic data=trainset2 desc;
	class V_bmi(ref='0') V_insulin(ref='0')/param=ref;
	model outcome=pregnancies glucose bloodpressure skinthickness V_insulin V_bmi DiabetesPedigreefunction age /SELECTION=STEPWISE;
run;
quit;

*WITHOUT STEPWISE;
proc logistic data=trainset2 desc;
	class V_bmi(ref='0') V_insulin(ref='0')/param=ref;
	model outcome=pregnancies glucose bloodpressure skinthickness V_insulin V_bmi DiabetesPedigreefunction age;
run;
quit;

/************************
* TEST4:+PREGNANCY x AGE *
************************/
proc logistic data=trainset2 desc;
	class V_bmi(ref='0') V_insulin(ref='0')/param=ref;
	model outcome=glucose bloodpressure skinthickness V_insulin V_bmi DiabetesPedigreefunction pregnancies*age /SELECTION=STEPWISE;
run;
quit;

*WITHOUT STEPWISE;
proc logistic data=trainset2 desc;
	class V_bmi(ref='0') V_insulin(ref='0')/param=ref;
	model outcome=glucose bloodpressure skinthickness V_insulin V_bmi DiabetesPedigreefunction pregnancies*age;
run;
quit;
ods graphics off;

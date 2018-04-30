/***********************
* IMPORT DATASET       *
***********************/
ods graphics on;
PROC IMPORT OUT= WORK.diabetes DATAFILE= "C:\Users\Aubhik\Desktop\MS\spring2018\CS 593 - Data Mining 2\finalProject\diabetes.csv" 
            DBMS=CSV REPLACE;
     		GETNAMES=YES;
     		DATAROW=2; 
RUN;

/***********************
* INITIAL ANALYSIS     *
***********************/
proc univariate data=diabetes;
	var pregnancies glucose bloodpressure skinthickness insulin bmi diabetespedigreefunction age;
run;
quit;

/***********************
* STANDARDIZE DATASET  *
***********************/
proc standard data=diabetes mean=0 std=1 out=diabetes_z;
	var pregnancies glucose bloodpressure skinthickness insulin bmi diabetespedigreefunction age;
run;


/***********************
*CALCULATE CORRELATION *
***********************/
proc corr data=diabetes_z; 
	var pregnancies glucose bloodpressure skinthickness insulin bmi diabetespedigreefunction age;
run;

/****************************
* FIND PRINCIPAL COMPONENTS *
****************************/
proc princomp data=diabetes_z out=diabetes_z_pca;
	var skinthickness insulin bmi diabetespedigreefunction age pregnancies glucose bloodpressure;
run;
quit;
/**********************************
* RUN LINEAR REGRESSION      	  *
* USING ONLY ORIGINAL VARIABLES   *
* ACCURACY = 77.083%			  *
**********************************/
proc reg data=diabetes OUTEST=test;
	model outcome=  skinthickness insulin bmi diabetespedigreefunction age pregnancies glucose bloodpressure / SELECTION=STEPWISE vif; 
	OUTPUT h=lev cookd=Cookd  dffits=dffit L95M=C_l95m  U95M=C_u95m  L95=C_l95 U95=C_u95
         ; 
run;
quit;
/*****************************************
* USE SCORE TO FIND PREDICTED CONTINUOUS *
* VALUES FOR OUTCOME                     *
*****************************************/ 
proc score data=diabetes score=test out=RScoreP type=parms;
   var bmi diabetespedigreefunction age pregnancies glucose bloodpressure;
run;
/******************************************
* 	USE 0.4 AS THRESHOLD TO SET OUTCOME   *
*	TO 0 or 1							  *
******************************************/
data Predictions;
	set Rscorep;
	if model1>0.4 then prediction=1;
	else prediction=0;
run;

/**********************************
* RUN LINEAR REGRESSION      	  *
* USING ONLY PRINCIPAL 			  *
* COMPONENTS THAT ARE SIGNIFICANT *
* ACCURACY = 75.911%			  *
**********************************/
proc reg data=diabetes_z_pca OUTEST=test;
	model outcome= prin1 prin2 prin3 prin5 prin6 /vif; 
	OUTPUT h=lev cookd=Cookd  dffits=dffit L95M=C_l95m  U95M=C_u95m  L95=C_l95 U95=C_u95
         ; 
run;
quit;


/*****************************************
* USE SCORE TO FIND PREDICTED CONTINUOUS *
* VALUES FOR OUTCOME                     *
*****************************************/ 
proc score data=diabetes_z_pca score=test out=RScoreP type=parms;
   var prin1 prin2 prin3 prin5 prin6;
run;
/******************************************
* 	USE 0.4 AS THRESHOLD TO SET OUTCOME   *
*	TO 0 or 1							  *
******************************************/
data Predictions;
	set Rscorep;
	if model1>0.4 then prediction=1;
	else prediction=0;
run;

/**************************
* RUN PYTHON TO CALCULATE *
* ACCURACY				  *
**************************/
/*_______________________________________________________________________________________________________________________*/
/*********************************
* RUN LINEAR REGRESSION          *
* USING ALL PRINCIPAL COMPONENTS *
* AND STEPWISE SELECTION		 *
* ACCURACY = 76.432%			 *
*********************************/
proc reg data=diabetes_z_pca OUTEST=test;
	model outcome= prin1--prin8 /SELECTION=STEPWISE vif; 
	OUTPUT h=lev cookd=Cookd  dffits=dffit L95M=C_l95m  U95M=C_u95m  L95=C_l95 U95=C_u95
         ; 
run;
quit;

/*****************************************
* USE SCORE TO FIND PREDICTED CONTINUOUS *
* VALUES FOR OUTCOME                     *
*****************************************/ 
proc score data=diabetes_z_pca score=test out=RScoreP type=parms;
   var prin1--prin8;
run;

/***********************
* LINEAR REGRESSION TO *
* CALCULATE	THE DPF	   *		
***********************/
proc standard data=diabetes mean=0 std=1 out=diabetes_z1;
	var pregnancies glucose bloodpressure skinthickness insulin bmi age outcome;
run;

proc princomp data=diabetes_z1 out=diabetes_z_pca1; *plots=all;
	var skinthickness insulin bmi age pregnancies glucose bloodpressure outcome;
run;
quit;

proc reg data=diabetes_z_pca1 OUTEST=test1;
	model diabetespedigreefunction= prin1 prin2 prin3 prin5 prin6 prin7 prin8 /SELECTION=STEPWISE vif; 
	OUTPUT h=lev cookd=Cookd  dffits=dffit L95M=C_l95m  U95M=C_u95m  L95=C_l95 U95=C_u95
         ; 
run;
quit;

proc score data=diabetes_z_pca1 score=test1 out=RScoreP2 type=parms;
   var prin1 prin2 prin3 prin7;
run;
/**************************
* RUN PYTHON TO CALCULATE *
* RMSError				  *
**************************/

/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/

/***********************
* LOGISTIC REGRESSION  *
***********************/

/**********************
* TEST1: No change    *
**********************/

proc logistic data=diabetes descending;
	model outcome=pregnancies glucose bloodpressure skinthickness insulin bmi DiabetesPedigreefunction age;
quit;
/**********************
* TEST2: +V_insulin    *
**********************/
data diabetes2;
	set diabetes;
	if insulin>0 then V_insulin=1;
	else V_insulin=0;
run;
proc freq data=diabetes2;
	tables outcome*V_insulin;
run;
proc logistic data=diabetes2 desc;
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

proc freq data=diabetes2;
	tables outcome*V_bmi;
run;

proc logistic data=diabetes2 desc;
	class V_bmi(ref='0') V_insulin(ref='0')/param=ref;
	model outcome=pregnancies glucose bloodpressure skinthickness V_insulin V_bmi DiabetesPedigreefunction age /SELECTION=STEPWISE;
run;
quit;

*WITHOUT STEPWISE;
proc logistic data=diabetes2 desc;
	class V_bmi(ref='0') V_insulin(ref='0')/param=ref;
	model outcome=pregnancies glucose bloodpressure skinthickness V_insulin V_bmi DiabetesPedigreefunction age;
run;
quit;

/************************
* TEST4:+PREGNANCY x AGE *
************************/
proc logistic data=diabetes2 desc;
	class V_bmi(ref='0') V_insulin(ref='0')/param=ref;
	model outcome=glucose bloodpressure skinthickness V_insulin V_bmi DiabetesPedigreefunction pregnancies*age /SELECTION=STEPWISE;
run;
quit;

*WITHOUT STEPWISE;
proc logistic data=diabetes2 desc;
	class V_bmi(ref='0') V_insulin(ref='0')/param=ref;
	model outcome=glucose bloodpressure skinthickness V_insulin V_bmi DiabetesPedigreefunction pregnancies*age;
run;
quit;
ods graphics off;
class V_bmi(ref='0') V_insulin(ref='0')/param=ref;
if bmi<=20 then V_bmi=1;
	else if bmi>20 and bmi<=30 then V_bmi=2;
	else V_bmi=3;

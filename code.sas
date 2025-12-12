/*********************************************************
Subject: EPID 640 
Assignment: Final Exam 
Name: Prathibha M Prasanna
Date: December 12, 2025
*********************************************************/

/* Question 1a: Import ACTV_E.csv file */

proc import datafile= "C:\Users\prathii\Desktop\EPID640 - SAS for Epidemiological Research\final\ACTV_E.csv"
    out=work.actv_raw
    dbms=csv
    replace;
    guessingrows=max;
run;

/* Question 1b: Create BMI, BMI category, and low physical activity */

data actv_clean;
    set actv_raw;

    /* Convert height to meters */
    height_m = bmxht / 100;

    /* BMI = weight (kg) / height (m)^2 */
    bmi = bmxwt / (height_m * height_m);

    /* BMI category:
       1 = underweight (<18.5)
       2 = healthy (18.5?24.9)
       3 = overweight (25?29.9)
       4 = obese (?30)
    */
    if bmi ne . then do;
        if bmi < 18.5 then bmi_cat = 1;
        else if 18.5 <= bmi < 25 then bmi_cat = 2;
        else if 25 <= bmi < 30 then bmi_cat = 3;
        else if bmi >= 30 then bmi_cat = 4;
    end;

    /* Low physical activity:
       = 1 if PAQ650 = 2 AND PAQ665 = 2
       = 0 if either question = 1
       = . otherwise (missing/refused/donÅft know)
    */
    if paq650 = 2 and paq665 = 2 then low_pa = 1;
    else if paq650 = 1 or paq665 = 1 then low_pa = 0;
    else low_pa = .;

run;

/* Count missingness for new variables */
proc freq data=actv_clean;
    tables bmi bmi_cat low_pa / missing;
run;

/* Drop records with missing BMI or activity variables */
data actv_final;
    set actv_clean;
    if bmi ne . and bmi_cat ne . and low_pa ne .;
run;

/* Count remaining observations */
proc sql;
    select count(*) as final_obs from actv_final;
quit;

/* Question 1c: Drop original non-recoded variables (retain SEQN) */

data actv_final2;
    set actv_final;
    drop bmxwt bmxht paq650 paq665 height_m;
run;

/* Question 1c: Create and apply formats for BMI category and low PA */

/* Define formats */
proc format;
    value bmi_cat_fmt
        1 = "Underweight (<18.5)"
        2 = "Healthy weight (18.5-24.9)"
        3 = "Overweight (25.0-29.9)"
        4 = "Obese (>=30)";
    value lowpa_fmt
        0 = "Not low activity (Yes to either question)"
        1 = "Low physical activity (No to both questions)";
run;

/* Apply formats */
data actv_final3;
    set actv_final2;
    format bmi_cat bmi_cat_fmt.
           low_pa  lowpa_fmt.;
run;

/* Confirm formats applied */
proc contents data=actv_final3;
run;

/* Question 2a: Import LBX_E.txt using DATA step */
filename lbxfile "C:\Users\prathii\Desktop\EPID640 - SAS for Epidemiological Research\final\LBX_E.txt";
data lbx_raw;
    infile lbxfile
		dlm= '/' 
        dsd
        missover
        firstobs=2
        lrecl=32767;
    input
        SEQN
        LBXTC
        LBXCOT
        LBXSUA
        LBXPFOA
    ;
run;

/* Question 2b: Add variable labels using LBX_E data dictionary */
data lbx_labeled;
    set lbx_raw;
    label
        SEQN    = "Respondent Sequence Number"
        LBXTC   = "Total Cholesterol (mg/dL)"
        LBXCOT  = "Serum Cotinine (ng/mL)"
        LBXSUA  = "Uric Acid (mg/dL)"
        LBXPFOA = "Perfluorooctanoic Acid (ng/mL)";
run;

/* Question 2c: Delete records with missing PFOA and assess remaining missingness */
data lbx_no_pfoa;
    set lbx_labeled;
    if LBXPFOA ne .;   /* Keep only records with non-missing PFOA */
run;

/* Count remaining number of observations */
proc sql;
    select count(*) as n_after_pfoa_delete
    from lbx_no_pfoa;
quit;

/* Assess missingness for the other variables */
proc freq data=lbx_no_pfoa;
    tables SEQN LBXTC LBXCOT LBXSUA / missing;
run;


/* Question 2d: Create hyperuricemia indicator (LBXSUA >= 7 mg/dL) */
data lbx_hyper;
    set lbx_no_pfoa;

    /* Hyperuricemia definition */
    if LBXSUA ne . then do;
        if LBXSUA >= 7 then hyper = 1;
        else hyper = 0;
    end;
    else hyper = .;
run;

/* Check coding */
proc freq data=lbx_hyper;
    tables hyper / missing;
run;

proc freq data=lbx_hyper;
    tables LBXSUA*hyper / missing list;
run;


/* Question 3: Merge DEMO_E, ACTV_E, and LBX_E datasets */
libname final "C:\Users\prathii\Desktop\EPID640 - SAS for Epidemiological Research\final";
options fmtsearch=(final);
data demo_e;
    set final.demo_e;
run;
proc sort data=demo_e;   by SEQN; run;
proc sort data=actv_final3; by SEQN; run;
proc sort data=lbx_hyper; by SEQN; run;
data final.merged;
    merge demo_e (in=a)
          actv_final3 (in=b)
          lbx_hyper  (in=c);
    by SEQN;

    /* Keep only those present in ALL datasets */
    if a and b and c;
run;
proc contents data=final.merged;
run;

/* Question 4a: Assess normality of Uric Acid and PFOA */
proc univariate data=final.merged normal;
    var LBXSUA;
    histogram LBXSUA / normal kernel;
run;

proc univariate data=final.merged normal;
    var LBXPFOA;
    histogram LBXPFOA / normal kernel;
run;

/* Question 4b: Create log-transformed PFOA and assess normality */
data final.merged_log;
    set final.merged;  
    /* Create log-transformed PFOA */
    if LBXPFOA ne . and LBXPFOA > 0 then LOGPFOA = log(LBXPFOA);
    else LOGPFOA = .;
run;

/* Assess normality of log-transformed PFOA */
proc univariate data=final.merged_log normal;
    var LOGPFOA;
    histogram LOGPFOA / normal kernel;
run;

/* Question 5: Test if hyperuricemia varies by categorical variables */
proc freq data=final.merged;
    tables RIDRETH*hyper / chisq;
run;

proc freq data=final.merged;
    tables INDHHIN*hyper / chisq;
run;

proc freq data=final.merged;
    tables low_pa*hyper / chisq;
run;

proc freq data=final.merged;
    tables bmi_cat*hyper / chisq;
run;

/* Question 6a: Scatter plots with regression lines */
/* Scatterplot: Uric Acid vs Age */
proc sgplot data=final.merged;
    scatter x=RIDAGEYR y=LBXSUA;
    reg x=RIDAGEYR y=LBXSUA / lineattrs=(color=red thickness=2);
run;

/* Scatterplot: Uric Acid vs Total Cholesterol */
proc sgplot data=final.merged;
    scatter x=LBXTC y=LBXSUA;
    reg x=LBXTC y=LBXSUA / lineattrs=(color=red thickness=2);
run;

/* Scatterplot: Uric Acid vs Serum Cotinine */
proc sgplot data=final.merged;
    scatter x=LBXCOT y=LBXSUA;
    reg x=LBXCOT y=LBXSUA / lineattrs=(color=red thickness=2);
run;

/* Question 6b: Correlation coefficients */
proc corr data=final.merged pearson;
    var RIDAGEYR LBXTC LBXCOT;
    with LBXSUA;
run;

/* Question 7: T-test comparing PFOA levels by hyperuricemia status */
proc univariate data=final.merged_log normal;
    class hyper;
    var LBXPFOA LOGPFOA;
    histogram LBXPFOA LOGPFOA / normal;
run;
/* Check variance equality using PROC TTEST with both variables */
/* T-test with UNTRANSFORMED PFOA */
proc ttest data=final.merged_log;
    class hyper;
    var LBXPFOA;
run;

/* T-test with LOG-TRANSFORMED PFOA */
proc ttest data=final.merged_log;
    class hyper;
    var LOGPFOA;
run;

/* Question 8a: Crude linear regression - Uric Acid vs PFOA */
proc reg data=final.merged_log;
    model LBXSUA = LOGPFOA;
run;
quit;

/* Question 8c: Adjusted linear regression - Uric Acid vs PFOA */
/* Adjusted model using PROC GLM */
proc glm data=final.merged_log;
    class RIAGENDR RIDRETH INDHHIN bmi_cat low_pa;
    model LBXSUA = LOGPFOA RIDAGEYR RIAGENDR RIDRETH INDHHIN 
                   bmi_cat low_pa LBXTC LBXCOT / solution clparm;
run;
quit;

/* Question 8d: Logistic regression - Hyperuricemia vs PFOA */
proc logistic data=final.merged_log descending;
    class 
        RIAGENDR(ref=FIRST)
        RIDRETH(ref=FIRST)
        INDHHIN(ref=FIRST)
        bmi_cat(ref=FIRST)
        low_pa(ref=FIRST)
        / param=ref;
    
    model hyper = LOGPFOA RIDAGEYR RIAGENDR RIDRETH INDHHIN
                  bmi_cat low_pa LBXTC LBXCOT
                  / clodds=pl;
    
    oddsratio LOGPFOA;
run;

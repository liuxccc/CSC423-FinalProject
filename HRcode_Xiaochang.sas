data HRDataFinal;
infile "HRfile_Xiaochang.csv" firstobs=2 delimiter=',';
input Obs satisfaction_level last_evaluation number_project	average_montly_hours time_spend_company	Work_accident left promotion_last_5years job_type $ salary $;
dacct=(job_type="accounti");
dhr=(job_type="hr");
dit=(job_type="IT");
dmgmt=(job_type="manageme");
dmkt=(job_type="marketin");
dprmg=(job_type="product_");
drand=(job_type="RandD");
dsup=(job_type="support");
dtech=(job_type="technica");
dmed=(salary="medium");
dhigh=(salary="high");
run;
title "The original dataset";
proc print;
run;

*step 2: do the surveyselect to split data in to train/test;
title "split dataset into train/test";
proc surveyselect data=HRDataFinal out=HRtrain seed=102300
samprate=0.6 outall;
run;
proc print data = HRtrain;
run;
*step 3: explore the data - boxplot;
proc sort;
by left;
run;
title " Boxplot - satisfaction_level*left";
proc boxplot;
plot satisfaction_level*left;
run;
title " Boxplot - last_evaluation*left";
proc boxplot;
plot last_evaluation*left;
run;
title " Boxplot - number_project*left";
proc boxplot;
plot number_project*left;
run;
title " Boxplot - average_montly_hours*left";
proc boxplot;
plot average_montly_hours*left;
run;
title " Boxplot - time_spend_company*left";
proc boxplot;
plot time_spend_company*left;
run;

*step 4: create train_y for further using;
data HRtrain;
set HRtrain;
if selected then train_y=left;
run;
title " dataset with train_y";
proc print data = HRtrain;
run;

*step5: fit model and model selection;
title "full model";
proc logistic;
model train_y(event='1') = satisfaction_level last_evaluation number_project average_montly_hours time_spend_company
Work_accident promotion_last_5years dacct dhr dit dmgmt dmkt dprmg drand dsup dtech dmed dhigh/corrb influence iplots;
run;

*stepwise selection;
proc logistic;
model train_y(event='1') = satisfaction_level last_evaluation number_project average_montly_hours time_spend_company
Work_accident promotion_last_5years dacct dhr dit dmgmt dmkt dprmg drand dsup dtech dmed dhigh/selection = stepwise;
run;

*backward selection;
proc logistic;
model train_y(event='1')=satisfaction_level last_evaluation number_project average_montly_hours time_spend_company
Work_accident promotion_last_5years dacct dhr dit dmgmt dmkt dprmg drand dsup dtech dmed dhigh/selection = backward;
run;

*fit the final model;
*step 6: final model diagnostics - based on backward method;
proc logistic;
model train_y(event='1')=satisfaction_level last_evaluation number_project average_montly_hours time_spend_company
Work_accident promotion_last_5years drand dmed dhigh/corrb influence iplots;
run;


*step 7: remove the outliers - based on pearson residual;
data HRDatanew;
set HRtrain;
if _n_=4189 then delete;
if _n_=4428 then delete;
if _n_=3830 then delete;
if _n_=4217 then delete;
if _n_=3747 then delete;
if _n_=4028 then delete;
if _n_=4035 then delete;
if _n_=4319 then delete;
if _n_=4471 then delete;
if _n_=4388 then delete;
if _n_=4947 then delete;
if _n_=3905 then delete;
if _n_=4560 then delete;
if _n_=4142 then delete;
if _n_=4213 then delete;
if _n_=4016 then delete;
if _n_=4385 then delete;
if _n_=4049 then delete;
if _n_=4765 then delete;
if _n_=4097 then delete;
if _n_=4440 then delete;
if _n_=3918 then delete;
if _n_=4572 then delete;
if _n_=4863 then delete;
if _n_=4775 then delete;
if _n_=4181 then delete;
run;
*check multilinearity-based on Estimated Correlation Matrix - it's good;
*check the final model;
proc logistic data = HRDatanew;
model train_y(event='1')=satisfaction_level last_evaluation number_project average_montly_hours time_spend_company
Work_accident promotion_last_5years drand dmed dhigh/corrb influence iplots;
run;
proc print data = HRDatanew;
run;
*finish fitting the final model;

*step 8: model validation and test data;
*create the classification table to identify the cut-off value;
*compute the predicted probability for test set (train_y = .);

title " fit model and compute cut-off value";
proc logistic data=HRDatanew; 
model train_y(event='1')= satisfaction_level last_evaluation number_project average_montly_hours time_spend_company
Work_accident promotion_last_5years drand dmed dhigh /ctable pprob= (0.1 to 0.9 by 0.05);
*save predictions in dataset "pred";
output out=pred(where=(train_y=.))  p=phat lower=lcl upper=ucl;
run;

* compute predicted Y in testing set;
title "compute predict Y";
data probs;
set pred;
cutoff = 0.35;
pred_y = 0;
if phat>cutoff then pred_y=1;
run;
proc print;
run;

*create classification table;
proc freq data=probs;
tables left*pred_y/norow nocol nopercent;
run;

*try cutoff=0.30 check the TF;
title "compute predict Y";
data probs;
set pred;
cutoff = 0.3;
pred_y = 0;
if phat>cutoff then pred_y=1;
run;
proc freq data=probs;
tables left*pred_y/norow nocol nopercent;
run;
*use he cutoff = 0.35

*step 9 : predction
*An employee who has been promoted last year, has 5 projects and didn't have any work accident;
data new;
input selected Obs satisfaction_level last_evaluation number_project average_montly_hours time_spend_company
Work_accident promotion_last_5years dacct dhr dit dmgmt dmkt dprmg drand dsup dtech dmed dhigh;
datalines;
. . .0 0 5 0 0 0 1 . . . . . . 0 . . 0 0
;
proc print data = new;
run;
*merge two dataset;
data pred;
set new HRDatanew;
run;
proc print data = pred;
run;
*use final model for prediction;
proc logistic data = pred;
model train_y(event='1')= satisfaction_level last_evaluation number_project average_montly_hours time_spend_company
Work_accident promotion_last_5years drand dmed dhigh;
output out=fp p=phat lower=lcl upper=ucl predprob=(individual);
run;
proc print data=fp;
run;

LIBNAME Project 'H:\GroupProject';

PROC IMPORT OUT= Project.fifanonzero
            DATAFILE= "H:\GroupProject\FifaNonZero.csv" 
            DBMS=CSV REPLACE;
     GETNAMES=YES;
     DATAROW=2; 
RUN;

PROC IMPORT OUT= Project.fifazerotest
            DATAFILE= "H:\GroupProject\Fifazerotest.csv" 
            DBMS=CSV REPLACE;
     GETNAMES=YES;
     DATAROW=2; 
RUN;

/* generating the working dataset in Work library */
data Fifanonzero;
 set Project.Fifanonzero;
run; 

data Fifazerotest;
 set Project.Fifazerotest;
run; 




/* -------------------------------- Part 2 : Market Value Prediction ---------------------------- */ 
/*MVP model*/

/* Removing the outliers */

/*Create Potential value */
data Fifanonzero;
set Fifanonzero;
if  80<= Potential <=84 then classPotential=3;
else if 84<= Potential <=89 then classPotential=2;
else if Potential>=90 then classPotential=1;
else if Potential<80 then classPotential=4;
run;

data Fifanonzero;
 set Fifanonzero;
run; 

data Fifazerotest;
set Fifazerotest;
if  80<= Potential <=84 then classPotential=3;
else if 84<= Potential <=89 then classPotential=2;
else if Potential>=90 then classPotential=1;
else if Potential<80 then classPotential=4;
run;

data Fifazerotest;
 set Fifazerotest;
run; 

/* Creating Dummy Varialbes for Top 10 Nations*/
data Fifanonzero;
set Fifanonzero;
if  Nationality="England" then England=1;
else if Nationality~="England" then England = 0;
if  Nationality="Germany" then Germany=1;
else if Nationality~="Germany" then Germany = 0;
if  Nationality="Spain" then Spain=1;
else if Nationality~="Spain" then Spain = 0;
if  Nationality="Argentina" then Argentina=1;
else if Nationality~="Argentina" then Argentina = 0;
if  Nationality="France" then France=1;
else if Nationality~="France" then France = 0;
if  Nationality="Brazil" then Brazil=1;
else if Nationality~="Brazil" then Brazil = 0;
if  Nationality="Italy" then Italy=1;
else if Nationality~="Italy" then Italy = 0;
if  Nationality="Colombia" then Colombia=1;
else if Nationality~="Colombia" then Colombia = 0;
if  Nationality="Japan" then Japan=1;
else if Nationality~="Japan" then Japan = 0;
if  Nationality="Netherlan" then Netherlan=1;
else if Nationality~="Netherlan" then Netherlan = 0;
run;

data Fifanonzero;
 set Fifanonzero;
run;

proc glm data=Fifanonzero plots = all;
class Attacking_Work_Rate(ref='Low') Defensive_Work_Rate(ref='Low') Position(ref='Full Back') international_reputation(ref='1') classPotential(ref='4');
model Value=age Position overall international_reputation  Weak_Foot classPotential Attacking_Work_Rate Defensive_Work_Rate  /solution ;
title 'MVP model with top predictors';
output out=fifaglmdata cookd=cookd student=residuals;
run;

/*Market Value =0 is being modelled as test_data, others are training data*/
/* Create training and test datasets. 80% of sample in training  */
proc surveyselect data=Fifanonzero out=fifa_sampled outall samprate=0.8 seed=2;
title 
run;

data fifa_training fifa_validation;
 set fifa_sampled;
 if selected then output fifa_training; /* Tell SAS that only keep the 80% selected one in sample. The rest will be in test data */
 else output fifa_validation;
run;

/* Stepwise Selection with AIC as criteria */
proc glmselect data = fifa_training testdata = fifa_validation  plots = all;
 class Skill_Moves  Preferred_Foot Attacking_Work_Rate(ref='Low') Defensive_Work_Rate(ref='Low') Position(ref='Full Back') international_reputation(ref='1') classPotential(ref='4');
model Value=Position  age | classPotential  | international_reputation | overall  | Preferred_Foot | Skill_Moves |Weak_Foot | Attacking_Work_Rate | Defensive_Work_Rate @2
/selection = stepwise(select = aic) hierarchy = single showpvalues;
 performance buildsscp = incremental;
 title 'Best MVP model using Stepwise Selection with AIC as criteria';
run;

/*Forward selection with AIC as criteria */
proc glmselect data = fifa_training testdata = fifa_validation  plots = all;
 class Skill_Moves Preferred_Foot Attacking_Work_Rate(ref='Low') Defensive_Work_Rate(ref='Low') Position(ref='Full Back') international_reputation(ref='1') classPotential(ref='4');
model Value=Position  age | classPotential  | international_reputation | overall | Preferred_Foot | Skill_Moves | Weak_Foot | Attacking_Work_Rate | Defensive_Work_Rate@2
/selection = forward(select = aic) hierarchy = single showpvalues;
 performance buildsscp = incremental;
 title 'Best MVP model using Forward Selection with AIC as criteria';
run;


/*Backward selection with AIC as criteria */
proc glmselect data = fifa_training testdata = fifa_validation  plots = all;
 class  Skill_Moves  Preferred_Foot Attacking_Work_Rate(ref='Low') Defensive_Work_Rate(ref='Low') Position(ref='Full Back') international_reputation(ref='1') classPotential(ref='4');
model Value=Position  age | classPotential  | international_reputation | overall | Preferred_Foot | Skill_Moves | Weak_Foot | Attacking_Work_Rate | Defensive_Work_Rate@2
/selection = backward(select = aic) hierarchy = single showpvalues;
 performance buildsscp = incremental;
 title 'Best MVP model using Backward Selection with AIC as criteria';
run;

data Fifanonzero;
set Fifanonzero;
if  80<= Potential <=84 then classPotential=3;
else if 84<= Potential <=89 then classPotential=2;
else if Potential>=90 then classPotential=1;
else if Potential<80 then classPotential=4;
run;

data Fifanonzero;
 set Fifanonzero;
run;

/*Now finding the best youngest player */
/*Create a new dataset called fifabelow22 and find the best market value */

proc sql;
create table  fifabelow22 as 
select *
from Fifanonzero
where age<22
order by Value desc;
quit;

data fifabelow22;
 set fifabelow22;
run; 


/*Now using this dataset to predict the youngest player with highest market value */
proc glmselect data = Fifanonzero testdata = fifabelow22  plots = all;
 class  Skill_Moves  Preferred_Foot Attacking_Work_Rate(ref='Low') Defensive_Work_Rate(ref='Low') Position(ref='Full Back') international_reputation(ref='1') classPotential(ref='4');
model Value=Position  age | classPotential  | international_reputation | overall | Preferred_Foot | Skill_Moves | Weak_Foot | Attacking_Work_Rate | Defensive_Work_Rate@2
/selection = backward(select = aic) hierarchy = single showpvalues;
 performance buildsscp = incremental;
 title 'Best MVP model using Backward Selection with AIC to predict the youngest player';
 output out=fifabelow22output;
run;


proc sql;
create table  fifabelow22result as 
select *
from fifabelow22output
where age<22
order by p_Value desc;
quit;


data fifabelow22result;
 set fifabelow22result;
run; 

data fifabelow22bestplayer;
set fifabelow22result (obs=1);
run;

data fifabelow22bestplayer;
 set fifabelow22bestplayer;
run; 



/*Best Young player stats */
proc sql;
create table bestyoungplayer as 
select Name,Age,Nationality,Overall,Potential,classPotential,Club,Value,p_Value,Wage,Special,International_Reputation
from fifabelow22bestplayer
quit;


/*Find predictions for top 10 clubs*/

proc glmselect data = fifa_training testdata = Fifanonzero  plots = all;
 class  Skill_Moves  Preferred_Foot Attacking_Work_Rate(ref='Low') Defensive_Work_Rate(ref='Low') Position(ref='Full Back') international_reputation(ref='1') classPotential(ref='4');
model Value=Position  age | classPotential  | international_reputation | overall | Preferred_Foot | Skill_Moves | Weak_Foot | Attacking_Work_Rate | Defensive_Work_Rate@2
/selection = backward(select = aic) hierarchy = single showpvalues;
 performance buildsscp = incremental;
 title 'Best MVP model using Backward Selection with AIC to predict the youngest player';
 output out=fifabest10clubsallpredictions;
run;

/*Compare the Predicted values and Actual Values for top 10 clubs */
proc sql;
create table  total_value_by_club as
select club as Club, sum(value) as Actualtotalclub_value,sum(p_Value) as Predictedtotalclub_Value
from fifabest10clubsallpredictions
where club in ('FC Bayern München','Borussia Dortmund','Liverpool','FC Barcelona','Juventus','Paris Saint-Germain','Manchester United','Manchester City','Chelsea','Real Madrid')
group by club
order by Actualtotalclub_value;
quit;


/*Predicting Market value for those players whose value was zero */
proc glmselect data = Fifanonzero testdata = Fifazerotest  plots = all;
 class  Skill_Moves  Preferred_Foot Attacking_Work_Rate(ref='Low') Defensive_Work_Rate(ref='Low') Position(ref='Full Back') international_reputation(ref='1') classPotential(ref='4');
model Value=Position  age | classPotential  | international_reputation | overall | Preferred_Foot | Skill_Moves | Weak_Foot | Attacking_Work_Rate | Defensive_Work_Rate@2
/selection = backward(select = aic) hierarchy = single showpvalues;
 performance buildsscp = incremental;
 title 'Best MVP model using Backward Selection with AIC to predict MVP of zero valued players';
 output out=fifazerovaluedMVPpredictions;
run;

/*---------------------------------------------------Top 10 Ballondor Players--------------------------------------------------*/

/*Create top 10 Ballon dor players dataset */
proc sql;
create table  fifatop10ballondor as 
select *
from Fifanonzero
where Name in ('L. Messi','L. Modri?','Cristiano Ronaldo','A. Griezmann','K. Mbappé','M. Salah','R. Varane','E. Hazard','K. De Bruyne','H. Kane') and Overall>80
order by Value desc;
quit;

/*Predict the values for top 10 players */

proc glmselect data = Fifanonzero testdata = fifatop10ballondor plots = all;
 class  Skill_Moves  Preferred_Foot Attacking_Work_Rate(ref='Low') Defensive_Work_Rate(ref='Low') Position(ref='Full Back') international_reputation(ref='1') classPotential(ref='4');
model Value=Position age | classPotential  | international_reputation | overall | Preferred_Foot | Skill_Moves | Weak_Foot | Attacking_Work_Rate | Defensive_Work_Rate @2
/selection = backward(select = aic) hierarchy = single showpvalues;
 performance buildsscp = incremental;
 title 'Best MVP model using Backward Selection with AIC to predict MVP of top 10 ballondor players';
 output out=fifaballondorMVPpredictions;
run;


/*Compare the Predicted values and Actual Values for top 10 Ballondor players*/
proc sql;
create table Fifaballondorcomparison as
select name as Name, Value as Actual_value,p_Value as Predicted_Value
from fifaballondorMVPpredictions
where Name in ('L. Messi','L. Modri?','Cristiano Ronaldo','A. Griezmann','K. Mbappé','M. Salah','R. Varane','E. Hazard','K. De Bruyne','H. Kane') and Overall>80
order by Value desc;
quit;

/*----------------------------------------Top 10 Ballondor Players with Nationality Bias---------------------------------------*/

proc sql;
create table  fifatop10ballondorwithbias as 
select *
from Fifanonzero
where Name in ('L. Messi','L. Modri?','Cristiano Ronaldo','A. Griezmann','K. Mbappé','M. Salah','R. Varane','E. Hazard','K. De Bruyne','H. Kane') and Overall>80
order by Value desc;
quit;

/*Predict the values for top 10 players With Nationality Bias*/

proc glmselect data = Fifanonzero testdata = fifatop10ballondorwithbias plots = all;
 class  Skill_Moves  Preferred_Foot Attacking_Work_Rate(ref='Low') Defensive_Work_Rate(ref='Low') Position(ref='Full Back') international_reputation(ref='1') classPotential(ref='4');
model Value=Position England Germany Spain Argentina France Brazil Italy Colombia Japan Netherlan age | classPotential  | international_reputation | overall | Preferred_Foot | Skill_Moves | Weak_Foot | Attacking_Work_Rate | Defensive_Work_Rate @2
/selection = backward(select = aic) hierarchy = single showpvalues;
 performance buildsscp = incremental;
 title 'Best MVP model using Backward Selection with AIC to predict MVP of top 10 ballondor players with Bias';
 output out=fifaballondorMVPpredictionsBias;
run;


/*Compare the Predicted values and Actual Values for top 10 Ballondor players With Nationality Bias*/
proc sql;
create table FifaballondorcomparisonBias1 as
select name as Name, Value as Actual_value,p_Value as Predicted_Value
from fifaballondorMVPpredictionsBias
where Name in ('L. Messi','L. Modri?','Cristiano Ronaldo','A. Griezmann','K. Mbappé','M. Salah','R. Varane','E. Hazard','K. De Bruyne','H. Kane') and Overall>80
order by Value desc;
quit;

PROC IMPORT OUT= Work.Data
            DATAFILE= "H:\GroupProject\data.csv" 
            DBMS=CSV REPLACE;
     GETNAMES=YES;
     DATAROW=2; 
RUN;
Data Data1;
set Data;
IF Position in ('CB','RCB','LCB') then Position='Center Back';
else IF Position in ('LB','RB') then Position='Full Back';
else IF Position in ('RWB','LWB') then Position='Wing Back';
else IF Position in ('LAM','RAM','CAM') then Position='Attacking Midfielder';
else IF Position in ('LCM','RCM','CM') then Position='Center Midfielder';
else IF Position in ('LM','RM') then Position='Wide Midfielder';
else IF Position in ('RDM','LDM','CDM') then Position='Defensive Midfielder';
else IF Position in ('CF','LF','RF') then Position='Center Forward';
else IF Position in ('LS','ST','RS') then Position='Striker';
else IF Position in ('LW','RW') then Position='Winger';
else Position='Goal Keeper';
run;
/*creating a class column for potential rating*/
data Fifanonzero;
set Data1;
if Potential>=90 then class=1;
else if 85<= Potential <=89 then class=2;
else if 80<=Potential<=84 then class=3;
else class=4;
run;
ods graphics / width=7in height=7in;
/*scatter matrix*/
proc sgscatter data=Fifanonzero;
 title "Scatterplot Matrix for Data";
 matrix Value Overall  age Potential / group=class diagonal=(histogram normal);
run;
ods graphics off;
/*1)age table*/
proc sql;
create table age_table as
select age as age, count(ID) as p_count, median(Value) as value 
from Fifanonzero group by age order by p_count desc;
quit;
ods graphics / width=5in height=5in;
/*1)barplot for p_count vs age*/
proc sgplot data=age_table;
format age ;
vbar age/ response= p_count datalabel  nostatlabel;
title 'p_count vs age';
run;
ods graphics off;
/*1)scatter plot of med Value vs age */
proc sgplot data=age_table;
title 'age vs value';
scatter x= age y= Value;
run;
/*1)creating a subset for class 1*/
DATA subset1;
   SET Fifanonzero;
   IF class =1;
RUN;
/*1)creating a table for class 1 with age and value columns*/
proc sql;
create table class1 as
select age as age , value as value
from subset1 order by Value;
quit;
/*1)how Value varies with age  of class 1 players*/
proc sgplot data=class1;
title 'Value vs age  in class1';
scatter x= age y= Value;
run;
/*1) Model with the best Rsquare to see the trend of value by age in class 1*/
proc glm data=class1;
model Value= age age*age age*age*age  /solution;
run;
quit;
/*1)creating a subset for class 2*/
DATA subset2;
   SET Fifanonzero;
   IF class =2;
RUN;
/*1)creating a table for class 2 with age and value columns*/
proc sql;
create table class2 as
select age as age , value as value
from subset2 order by Value;
quit;
/*1)how Value varies with age  of class 2 players*/
proc sgplot data=class2;
title 'Value vs age  in class2';
scatter x= age y= Value;
run;
/*1)Model with the best Rsquare to see the trend of value by age in class 2*/
proc glm data=class2;
model Value= age age*age age*age*age  /solution;
run;
quit;
/*1)creating a subset for class 3*/
DATA subset3;
   SET Fifanonzero;
   IF class =3;
RUN;
/*1)creating a table for class 3 with age and value columns*/
proc sql;
create table class3 as
select age as age , value as value
from subset1 order by Value;
quit;
/*1)how Value varies with age  of class 3 players*/
proc sgplot data=class3;
title 'Value vs age  in class1';
scatter x= age y= Value;
run;
/*1)Model with the best Rsquare to see the trend of value by age in class 3*/
proc glm data=class3;
model Value= age age*age age*age*age  /solution;
run;
quit;
/*1)creating a subset for class 4*/
DATA subset4;
   SET Fifanonzero;
   IF class =4;
RUN;
/*1)creating a table for class 4 with age and value columns*/
proc sql;
create table class4 as
select age as age , value as value
from subset1 order by Value;
quit;
/*1)how Value varies with age  of class 4 players*/
proc sgplot data=class4;
title 'Value vs age  in class1';
scatter x= age y= Value;
run;
/*1)Model with the best Rsquare to see the trend of value by age in class 4*/
proc glm data=class4;
model Value= age age*age age*age*age  /solution;
run;
quit;
ods graphics / width=30in height=5in;
/*2)creating a table for player count by nattionality*/
proc sql;
create table Player_count as 
select Nationality,count(ID) as player_count 
from Fifanonzero group by Nationality order by player_count desc;
quit;
ods graphics off;
/*2)barplot of player count vs nationality*/
proc sgplot data=Player_count;
vbar Nationality / response= player_count datalabel categoryorder=respdesc nostatlabel;
title 'Player_count by nationality';
run;
/*2)creating a sepearte dataset for countries with top 10 player counts*/
DATA Nationality;
   SET Fifanonzero;
   IF Nationality in ('England','Germany','Spain','Argentina','France','Brazil','Italy','Colombia','Japan','Netherlands');
RUN;
/*2)are players being discriminated by nationality*/
proc glm data=Nationality;
class Nationality(ref='England') International_Reputation Attacking_Work_Rate Defensive_Work_Rate skill_moves weak_foot class ;
model Value = Nationality Overall International_Reputation Attacking_Work_Rate Defensive_Work_Rate skill_moves class /solution;
title 'how the players are discriminated based on nationality';
run;
quit;
/*3)Are players being discriminated based on positions? */
proc glm data = Fifanonzero;
class Position(ref='Centre Back') international_reputation(ref='1');
 model Value = Position|overall age age_2 international_reputation /solution;
 output out = regdata cookd = cookd student=sresiduals; 
run;
ods graphics on;

/*3)848 outliers found*/
proc print data=regdata ;
 var _ALL_;
 where Cookd > 4 / 18207;
run;


/*3)After outlier's removal*/
ods output ParameterEstimates = position_estimates;
proc glm data=regdata;
class Position(ref='Centre Back') international_reputation(ref='1');
model Value = Position|overall age age_2 international_reputation/solution;
where Cookd < 4 / 18207 and sresiduals<3;
run;

/*3)Distribution of overall rating*/
proc sgplot data= Fifanonzero;
 histogram overall / binstart = 10 binwidth = 5 ; 
 density overall / type = kernel; 
 density overall/type = normal;
 title 'Overall Report';
run;

/*3)Dataset (Position_value) with Marktet Value calculation for each position at constant overall rating */
data position_value;
 set Project.position_value;
run; 

/*3)Value based on position and overall*/
proc sgplot data = position_value;
 scatter X=position Y=value_90;
 scatter X=position Y=value_85;
 scatter X=position Y=value_80;
 scatter X=position Y=value_75;
 scatter X=position Y=value_65;
 scatter X=position Y=value_55; 
 title 'Value based on position and overall ';
run;

/*4)creating a table for player count for attacking work rate*/
proc sql;
create table attackingwr_pcount as
select Attacking_Work_Rate as awr, count(ID) as player_count
from Fifanonzero group by Attacking_Work_Rate order by player_count;
quit; 
/*4)barplot for player count by attacking work rate to confirm weather we have sufficient observations in each category*/
proc sgplot data=attackingwr_pcount;
vbar awr / response= player_count datalabel categoryorder=respdesc nostatlabel;
title 'Player_count by attacking work rate';
run;
/*4)hypothesis testing to see if the market value differes by attacking work rate*/
proc glm data=Fifanonzero;
class Attacking_Work_Rate International_Reputation Defensive_Work_Rate skill_moves Nationality class;
model Value = Attacking_Work_Rate Nationality Overall International_Reputation Overall Defensive_Work_Rate skill_moves class/solution;
means Attacking_Work_Rate / tukey;
title 'how market value of the players is affected by attacking work rate';
run;
quit;
/*4)creating table for player count for defensive work rate */
proc sql;
create table dfwr_pcount as
select Defensive_Work_Rate as dwr, count(ID) as player_count
from Data group by Defensive_Work_Rate order by player_count;
quit;
/*4)barplot for player count by defensive work rate*/
proc sgplot data=dfwr_pcount;
vbar dwr / response= player_count datalabel categoryorder=respdesc nostatlabel;
title 'Player_count by defensive work rate';
run;
/*4)hypothesis testing to see if the market value is being affected by defensive work rate*/
proc glm data=Fifanonzero;
class Defensive_Work_Rate International_Reputation Defensive_Work_Rate skill_moves Nationality Attacking_Work_Rate class;
model Value = Attacking_Work_Rate|Defensive_Work_Rate Nationality Overall International_Reputation Overall  skill_moves class/solution;
means Defensive_Work_Rate*Attacking_Work_Rate / tukey;
title ' how market values of the players is affected by defensive work rate';
run;
quit;

/*5)Model on Overall. How skills are related to overall. Important skills that the manager should be looking for that position*/
ods output ParameterEstimates = overall_significant;
proc glm data=Fifanonzero;
class position(ref='Centre Back') ;
model overall = position position|Marking position|StandingTackle position|SlidingTackle position|Vision position|Interceptions position|Composure position|Reactions position|Aggression position|Positioning
position|LongShots position|Penalties position|ShotPower position|Finishing position|HeadingAccuracy position|Volleys position|Curve position|FKAccuracy position|Crossing position|ShortPassing position|LongPassing
position|Dribbling position|BallControl position|GKDiving position|GKHandling position|GKKicking position|GKPositioning position|GKReflexes
/solution ;
run;
/*R-squared 97%*/

/*5)Significant results from the overall model*/
proc print data=overall_significant;
where probt < 0.05;
run;


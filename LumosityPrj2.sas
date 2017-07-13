FILENAME REFFILE '/home/ptilak0/sasuser.v94/Jacob Stats 2/DataFiles/SampleLumosity.csv';
PROC IMPORT DATAFILE=REFFILE DBMS=CSV OUT=LumosityData replace; 
GETNAMES=YES;

/*basic scatterplot check for scaled and non-scaled and delta values*/
proc sgscatter data=LumosityData;
matrix  AR_1 TTS_1 GNG_1 GR_1 MS_1 PM_1 RMS_1 GI_1;
run;
proc sgscatter data=LumosityData;
matrix  AR_2 TTS_2 GNG_2 GR_2 MS_2 PM_2 RMS_2 GI_2;
run;
proc sgscatter data=LumosityData;
matrix  AR_d TTS_d GNG_d GR_d MS_d PM_d RMS_d GI_d;
run;

/*validate linearity analysis*/ 
proc means data=LumosityData;
class group;
run; 
proc ttest data=LumosityData;
paired AR_pre* AR_post;
run;
proc univariate data=LumosityData;
class group;
histogram;
run;
/*est_hours column doesnt look normally distributed, may need transformation*/

/*data cleanup for removing 'NAs', replacing it with '.'*/
/*not all fields will be used in final analysis*/
data LumosityCleaned ;
set LumosityData ;
if lost_track_details_d='NA' then lost_track_details_d=.;
if misplaced_items_d='NA' then misplaced_items_d=.;
if lost_concentration_d='NA' then lost_concentration_d=.;
if remembered_names_d='NA' then remembered_names_d=.;
if felt_creative_d='NA' then felt_creative_d=.;
if good_concentration_d='NA' then good_concentration_d=.;
if felt_anxious_d='NA' then felt_anxious_d=.;
if in_bad_mood_d='NA' then in_bad_mood_d=.;
if felt_sad_d='NA' then felt_sad_d=.;
if felt_training_benefits_d='NA' then felt_training_benefits_d=.;
if rwc_ave_d='NA' then rwc_ave_d=.;
felt_creative_d_n = input(felt_creative_d, 2.);
felt_anxious_d_n = input(felt_anxious_d, 2.);
remembered_names_d_n = input(remembered_names_d, 2.);
rwc_ave_d_n = input(rwc_ave_d, 2.);
/*taking a log of 'est_hours' based on the univariate result on a initial data check, since data 
looks skewed for est_hours */
log_est_hours=log(est_hours+1);
where exclude=0; /*not including participants which are marked as exclude=1*/ 
run;

/*consider all possible variables in the regression analysis to identify the significance level*/
proc reg data=LumosityCleaned plots=ALL;
model GI_d = AR_d	TTS_d	GNG_d	GR_d	MS_d	PM_d	RMS_d			
lost_track_details_d	misplaced_items_d	lost_concentration_d	remembered_names_d_n	
felt_creative_d_n	good_concentration_d	felt_anxious_d_n	in_bad_mood_d	felt_sad_d	
rwc_ave_d_n	active_days	log_est_hours / aic tol collin vif;
run;

/*Ignoring the insignificant variables*/
/*univariate result shows the normalized result for all the variables specially log_est_hours*/
proc univariate data=LumosityCleaned;
class group;
var GI_d AR_d	TTS_d	GNG_d	GR_d	MS_d	PM_d	RMS_d	log_est_hours;
histogram;
run;

proc reg data=LumosityCleaned  plots(label) = (rstudentbyleverage cooksd);
model GI_d = AR_d	TTS_d	GNG_d	GR_d	MS_d	PM_d	RMS_d	log_est_hours /aic tol collin vif;
run;

/*checking for corelation between variables*/
proc corr data=LumosityCleaned;
var  GI_d AR_d	TTS_d	GNG_d	GR_d	MS_d	PM_d	RMS_d	log_est_hours;
run; 
/*GI_d is corelated to other variables,since it's derived variable, hence dropping it*/
/*it appears that log_est hours should be used for final analysis*/

/*check MANOVA assumptions*/
Proc GLM Data=LumosityCleaned plot=diagnostics;
 Class group;
 Model AR_d	TTS_d	GNG_d	GR_d	MS_d	PM_d	RMS_d	log_est_hours =group;
 Manova H=_all_ / PrintE PrintH;
Run;


/*LDA without dimensionality reduction*/
proc discrim data=LumosityCleaned pool=test crossvalidate;
class group;
var AR_d	TTS_d	GNG_d	GR_d	MS_d	PM_d	RMS_d	log_est_hours;
priors "crosswords"=0.5  "lumosity"=0.5; 
run;

proc sgscatter data=LumosityCleaned;
matrix  AR_d TTS_d GNG_d GR_d MS_d PM_d RMS_d log_est_hours;
run;


/*PCA to reduce the dimensions*/
ods graphics on;
proc princomp data=LumosityCleaned plots=all out=pca;
var AR_d	TTS_d	GNG_d	GR_d	MS_d	PM_d	RMS_d	log_est_hours;
run;
ods graphics off;

/* Using principal components rather than actual variables. I chose 6 pcomps
because that amounts to almost 80% of variance*/
proc discrim data=pca pool=test crossvalidate;
class group;
var Prin1 Prin2 Prin3 Prin4 Prin5 Prin6;
priors "crosswords"=0.5  "lumosity"=0.5; 
run;
# Early Warning Tool for prioritizing individuals for CKD screenings (based on risk of CKD)

## Formulation
For every patient 
1. who has *had a visit*  in the past *x* years (using x=2 for now and defining *been seen* as having had a clinical visit)
2. has not been diagnosed with CKD yet (using diagnosis for now but extend to medications and abnormal egfrs)
3. and has not had an eGFR in the past *y* months

Predict the top k individuals (based on intervention capacity) who are risk of having an abnormal eGFR in the next z months


## Analysis to be done
- Predict risk of CKD stage 3 or above in the next 12 months (we can vary this)
- Baselines: 
  1. current practice
  2. clinical guidelines
  3. [CDC adopted screening tool](https://nccd.cdc.gov/ckd/Calculators.aspx#tab-Bang)
- Metric: Precision (PPV) at top k (:warning: need to determine k based on capacity)
- Fairness metric: TPR disparity by Race, Gender, SES, access, etc.


## Methodology
1. Define Cohort based on formulation
2. Define Outcome/Label based on formulation (will get diagnosed with X in the next z months)
3. Define Training and Validation sets over time
4. Define and generate predictors 
5. Train Models on each training set and score all patients in the corresponding validation set 
6. Evaluate all models for each validation time according to metric (PPV at top k)
7. Select "Best" model based on results over time
8. Explore the model to understand who it flags, how they compare to the cohort, important predictors
9. Check and/or correct for bias issues

## Triage background
We are using [Triage](https://github.com/dssg/triage) to build and select models. Some background and tutorials on Triage:
- [Tutorial on Google Colab](https://colab.research.google.com/github/dssg/triage/blob/master/example/colab/colab_triage.ipynb) - Are you completely new to Triage? Run through a quick tutorial hosted on google colab (no setup necessary) to see what triage can do!
- [Dirty Duck Tutorial](https://dssg.github.io/triage/dirtyduck/) - Want a more in-depth walk through of triage's functionality and concepts? Go through the dirty duck tutorial here with sample data
- [QuickStart Guide](https://dssg.github.io/triage/quickstart/) - Try Triage out with your own project and data
- [Suggested workflow](https://dssg.github.io/triage/triage_project_workflow/)
- [Understanding the configuration file](https://dssg.github.io/triage/experiments/experiment-config/#experiment-configuration)

## Running models and triage
Assuming Triage is installed and the data is in a postgres database. To run,
1. activate virtual environment source env/bin/activate
2. python run.py -c configfilename

**Choices to Make**
1. replace flag (set to false until we want to nuke everything)
2. save predictions (don't for the beginning)
3. number of processors to use

## Config files, Model Selection, and Bias Analysis 
1. cohort:All
- cohort: all patients who've had a visit in the past 2 years and do not have CKD yet
- label: will get diagnosed with CKD in the next 12 months
- [config file](), [notebook with model selection]()

2. [cohort:No previous abnormnal eGFRs]()
- cohort: all patients who've who've had a visit in the past 2 years, do not have CKD yet, and no previous abnormal eGFRs
- label: will get diagnosed with CKD in the next 12 months
- [config file](), [notebook with model selection]()



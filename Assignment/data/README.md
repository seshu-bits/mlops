# 🏥 Heart Disease Dataset

## Overview

This directory contains the UCI Heart Disease dataset used for training and evaluating machine learning models to predict heart disease presence.

---

## Dataset Information

**Source**: UCI Machine Learning Repository  
**URL**: https://archive.ics.uci.edu/dataset/45/heart+disease  
**Date Donated**: July 1, 1988  
**Instances**: 303 (Cleveland), 294 (Hungarian), 123 (Switzerland), 200 (Long Beach VA)  
**Features**: 76 raw attributes (14 commonly used)

### Citation

If you use this dataset, please cite:

```
Janosi, A., Steinbrunn, W., Pfisterer, M., & Detrano, R. (1988). 
Heart Disease. UCI Machine Learning Repository. 
https://doi.org/10.24432/C52P4X
```

**Principal Investigators**:
- Hungarian Institute of Cardiology, Budapest: Andras Janosi, M.D.
- University Hospital, Zurich, Switzerland: William Steinbrunn, M.D.
- University Hospital, Basel, Switzerland: Matthias Pfisterer, M.D.
- V.A. Medical Center, Long Beach and Cleveland Clinic Foundation: Robert Detrano, M.D., Ph.D.

---

## Files in This Directory

### Primary Dataset
- **`processed.cleveland.data`** - Cleveland Clinic data (303 instances) - **PRIMARY FILE USED**
- **`processed.hungarian.data`** - Hungarian Institute data (294 instances)
- **`processed.switzerland.data`** - University Hospital Zurich data (123 instances)
- **`processed.va.data`** - Long Beach VA data (200 instances)

### Documentation
- **`heart-disease.names`** - Original dataset documentation from UCI
- **`Index`** - File index from UCI repository
- **`WARNING`** - Important notes about the dataset

### Raw Data (76 attributes)
- `cleveland.data`, `hungarian.data`, `switzerland.data`, `new.data` - Unprocessed versions

---

## Feature Description

The dataset uses **14 attributes** (13 features + 1 target):

| Column # | Name | Type | Description | Values/Range |
|----------|------|------|-------------|--------------|
| 1 | **age** | Numeric | Age in years | 29-77 |
| 2 | **sex** | Categorical | Sex | 1 = male, 0 = female |
| 3 | **cp** | Categorical | Chest pain type | 1: typical angina<br>2: atypical angina<br>3: non-anginal pain<br>4: asymptomatic |
| 4 | **trestbps** | Numeric | Resting blood pressure (mm Hg) | 94-200 |
| 5 | **chol** | Numeric | Serum cholesterol (mg/dl) | 126-564 |
| 6 | **fbs** | Categorical | Fasting blood sugar > 120 mg/dl | 1 = true, 0 = false |
| 7 | **restecg** | Categorical | Resting ECG results | 0: normal<br>1: ST-T wave abnormality<br>2: left ventricular hypertrophy |
| 8 | **thalach** | Numeric | Maximum heart rate achieved | 71-202 |
| 9 | **exang** | Categorical | Exercise induced angina | 1 = yes, 0 = no |
| 10 | **oldpeak** | Numeric | ST depression induced by exercise | 0.0-6.2 |
| 11 | **slope** | Categorical | Slope of peak exercise ST segment | 1: upsloping<br>2: flat<br>3: downsloping |
| 12 | **ca** | Numeric | Number of major vessels colored by fluoroscopy | 0-3 |
| 13 | **thal** | Categorical | Thalassemia | 3: normal<br>6: fixed defect<br>7: reversible defect |
| 14 | **target** | Categorical | Diagnosis of heart disease | **Original**: 0-4<br>**Binarized**: 0 = no disease<br>1 = disease present |

### Missing Values

Missing values are indicated by `?` in the original data. Our preprocessing pipeline:
1. Replaces `?` with `NaN`
2. Drops rows with missing values (simple strategy)
3. ~6 rows affected in Cleveland dataset

---

## Data Statistics

### Cleveland Dataset (Primary)

```
Total Instances: 303
After cleaning: ~297 (6 rows with missing values removed)

Class Distribution:
- Class 0 (No disease): 164 instances (54.4%)
- Class 1 (Disease):    139 instances (45.6%)

Feature Ranges:
- Age: 29-77 years (mean: 54.4)
- Resting BP: 94-200 mmHg (mean: 131.6)
- Cholesterol: 126-564 mg/dl (mean: 246.7)
- Max Heart Rate: 71-202 bpm (mean: 149.6)
- ST Depression: 0.0-6.2 (mean: 1.04)
```

---

## Preprocessing Steps

Our production pipeline (`MLOps_Assignment.py`) performs:

### 1. Data Loading
```python
from MLOps_Assignment import load_raw_heart_data
raw_df = load_raw_heart_data(data_dir="./data")
```
- Loads `processed.cleveland.data`
- Assigns column names
- Returns pandas DataFrame

### 2. Data Validation
```python
from MLOps_Assignment import validate_heart_data
validation_results = validate_heart_data(raw_df)
```
- Schema validation (expected columns)
- Range validation (age, BP, cholesterol, etc.)
- Outlier detection (IQR method)
- Quality metrics (missing values, duplicates)

### 3. Data Cleaning
```python
from MLOps_Assignment import clean_and_preprocess_heart_data
cleaned_df = clean_and_preprocess_heart_data(raw_df)
```
- Replace `?` with `NaN`
- Convert columns to numeric types
- Drop rows with missing values
- **Target binarization**: Convert multi-class (0-4) to binary (0/1)
  - 0 remains 0 (no disease)
  - 1, 2, 3, 4 become 1 (disease present)

### 4. Feature Engineering
```python
from MLOps_Assignment import prepare_ml_features
X, y, scaler = prepare_ml_features(cleaned_df)
```
- One-hot encoding for categorical features
- StandardScaler for numeric features
- Returns feature matrix (X), target (y), fitted scaler

### 5. Train-Test Split
```python
from MLOps_Assignment import train_test_split_features
X_train, X_test, y_train, y_test = train_test_split_features(X, y, test_size=0.2)
```
- 80/20 split
- Stratified sampling (maintains class balance)
- Random state = 42 (reproducible)

---

## Exploratory Data Analysis

### Running EDA

```python
from MLOps_Assignment import perform_eda_heart_data

eda_results = perform_eda_heart_data(
    cleaned_df,
    output_dir="./artifacts/eda",
    save_plots=True
)

# EDA generates:
# - histograms_numerical_features.png
# - correlation_heatmap.png
# - class_balance.png
# - boxplots_by_target.png
# - outlier_detection.png
```

### Key Insights

**Correlation Findings**:
- `thalach` (max heart rate) negatively correlates with disease (-0.42)
- `oldpeak` (ST depression) positively correlates with disease (0.43)
- `cp` (chest pain type) strongly correlates with disease (0.43)

**Class Balance**:
- Reasonably balanced: 54.4% no disease, 45.6% disease
- No need for SMOTE or class weighting (though Random Forest uses balanced weights)

**Outliers** (IQR method):
- `oldpeak`: 15 outliers
- `chol`: 8 outliers
- `trestbps`: 6 outliers
- Outliers retained (may contain diagnostic information)

---

## Usage in CI/CD Pipeline

The CI pipeline (`ci_train.py`) automatically:
1. Loads data
2. Validates data quality
3. Performs EDA (saves plots)
4. Cleans and preprocesses
5. Trains models
6. Logs all artifacts to MLflow

```bash
cd Assignment
python ci_train.py
```

EDA plots are logged to MLflow under the `eda` artifact directory.

---

## Data Quality Checks

### Automated Validation

Run validation independently:

```python
from MLOps_Assignment import validate_heart_data

validation = validate_heart_data(raw_df)

print(f"Valid: {validation['is_valid']}")
print(f"Errors: {validation['errors']}")
print(f"Warnings: {validation['warnings']}")
print(f"Metrics: {validation['metrics']}")
```

**Checks Include**:
- ✅ Expected 14 columns present
- ✅ Age between 0-120
- ✅ Blood pressure between 50-250 mmHg
- ✅ Cholesterol between 100-600 mg/dl
- ✅ Max heart rate between 50-250 bpm
- ✅ ST depression between 0-10
- ✅ Missing value detection
- ✅ Duplicate row detection
- ✅ Outlier identification

---

## References

1. Detrano, R., Janosi, A., Steinbrunn, W., Pfisterer, M., Schmid, J., Sandhu, S., ... & Froelicher, V. (1989). International application of a new probability algorithm for the diagnosis of coronary artery disease. *American Journal of Cardiology*, 64(5), 304-310.

2. UCI Machine Learning Repository: https://archive.ics.uci.edu/dataset/45/heart+disease

3. Cleveland Clinic Foundation Heart Disease Database

---

## Contact

For questions about this dataset or its usage in this project, please refer to:
- UCI Repository: https://archive.ics.uci.edu/dataset/45/heart+disease
- Project Issues: https://github.com/seshu-bits/mlops/issues

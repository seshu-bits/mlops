# 🏥 Heart Disease Prediction MLOps Project

Complete MLOps implementation with FastAPI, Kubernetes deployment, Prometheus monitoring, and Grafana visualization.

---

## 📋 Table of Contents

- [Quick Start](#-quick-start)
- [Data Acquisition & EDA](#-data-acquisition--eda)
- [Feature Engineering & Model Training](#-feature-engineering--model-training)
- [Experiment Tracking with MLflow](#-experiment-tracking-with-mlflow)
- [Project Overview](#-project-overview)
- [Architecture](#-architecture)
- [Deployment](#-deployment)
- [Monitoring](#-monitoring)
- [API Usage](#-api-usage)
- [Testing](#-testing)
- [Remote Access](#-remote-access)
- [Troubleshooting](#-troubleshooting)

---

## 🚀 Quick Start

### Prerequisites
- AlmaLinux 8 / RHEL 8
- Minikube with Docker driver
- kubectl and Helm 3.x
- Python 3.11+

### Deploy Everything (3 Commands)

```bash
# 1. Clone and navigate
git clone https://github.com/seshu-bits/mlops.git
cd mlops/Assignment

# 2. Setup monitoring and deploy
cd monitoring
./setup-complete-monitoring.sh

# 3. Setup remote access (optional)
cd ..
./setup-nginx-proxy.sh
```

**Access URLs:**
- **API**: http://\<server-ip\>/health
- **API Docs**: http://\<server-ip\>/docs
- **Prometheus**: http://\<server-ip\>:9090
- **Grafana**: http://\<server-ip\>:3000 (admin/admin)

---

## � Data Acquisition & EDA

### Dataset Information

**Source**: UCI Machine Learning Repository - Heart Disease Dataset  
**URL**: https://archive.ics.uci.edu/dataset/45/heart+disease  
**Citation**: 
- Hungarian Institute of Cardiology. Budapest: Andras Janosi, M.D.
- University Hospital, Zurich, Switzerland: William Steinbrunn, M.D.
- University Hospital, Basel, Switzerland: Matthias Pfisterer, M.D.
- V.A. Medical Center, Long Beach and Cleveland Clinic Foundation: Robert Detrano, M.D., Ph.D.

### Dataset Statistics

- **Instances**: 303 (Cleveland dataset)
- **Features**: 14 attributes (age, sex, cp, trestbps, chol, fbs, restecg, thalach, exang, oldpeak, slope, ca, thal, target)
- **Target**: Binary classification (0 = no disease, 1 = disease present)
- **Missing Values**: Present (marked as '?'), handled during preprocessing

### Download Dataset

**Option 1: Automated Download (Recommended)**

Use the Jupyter notebook which includes automated download:

```python
from pathlib import Path
from MLOps_Assignment import download_heart_disease_dataset

# Downloads from UCI and extracts to ./data
dataset_path = download_heart_disease_dataset(save_dir="./data")
```

**Option 2: Manual Download**

```bash
cd Assignment/data
wget https://archive.ics.uci.edu/static/public/45/heart+disease.zip
unzip heart+disease.zip
```

The dataset is already included in this repository at `Assignment/data/processed.cleveland.data`.

### Data Preprocessing Pipeline

Our preprocessing includes:

1. **Missing Value Handling**: Replace '?' markers with NaN and drop rows
2. **Type Conversion**: Convert numeric columns to proper dtypes
3. **Target Binarization**: Convert multi-class target (0-4) to binary (0/1)
4. **Feature Encoding**: One-hot encoding for categorical features
5. **Feature Scaling**: StandardScaler for numeric features
6. **Stratified Split**: 80/20 train-test split maintaining class balance

### Exploratory Data Analysis

The project includes comprehensive EDA with:

- **Distribution Analysis**: Histograms with KDE for all numeric features
- **Correlation Analysis**: Heatmap showing feature relationships
- **Class Balance**: Visualization of target distribution
- **Outlier Detection**: IQR-based outlier identification
- **Feature Comparison**: Box plots comparing features by target class

**Run EDA**:

```python
from MLOps_Assignment import load_raw_heart_data, clean_and_preprocess_heart_data, perform_eda_heart_data

# Load and clean data
raw_df = load_raw_heart_data("./data")
cleaned_df = clean_and_preprocess_heart_data(raw_df)

# Generate EDA visualizations
eda_results = perform_eda_heart_data(cleaned_df, output_dir="./artifacts/eda")
print(f"EDA plots saved: {eda_results['plots']}")
```

**EDA Artifacts in MLflow**:

All EDA visualizations are automatically logged to MLflow during training:
- Histograms of feature distributions
- Correlation heatmap
- Class balance plot
- Box plots by target
- Outlier detection plots

### Data Validation

Automated data validation includes:

- **Schema Validation**: Ensures expected columns are present
- **Range Validation**: Checks numeric features are within expected ranges
  - Age: 0-120 years
  - Blood Pressure: 50-250 mmHg
  - Cholesterol: 100-600 mg/dl
  - Max Heart Rate: 50-250 bpm
- **Quality Metrics**: Missing values, duplicates, outliers
- **Class Distribution**: Target class balance

**Run Validation**:

```python
from MLOps_Assignment import validate_heart_data

validation_results = validate_heart_data(raw_df)
print(f"Valid: {validation_results['is_valid']}")
print(f"Errors: {validation_results['errors']}")
print(f"Warnings: {validation_results['warnings']}")
```

---

## 🤖 Feature Engineering & Model Training

### Feature Engineering Pipeline

Our feature engineering transforms raw data into ML-ready features:

**1. One-Hot Encoding**
- Categorical features encoded with `drop_first=True` to avoid multicollinearity
- Creates binary indicator columns for each category

**2. Feature Scaling**
- `StandardScaler` applied to numeric features
- Standardizes features to zero mean and unit variance
- Essential for distance-based algorithms (Logistic Regression)

**3. Feature Transformation**
```python
from MLOps_Assignment import prepare_ml_features

X, y, scaler = prepare_ml_features(cleaned_df)
# Input: 13 raw features
# Output: 20+ features after one-hot encoding
```

---

### Models Implemented

We train and evaluate **three classification algorithms**:

#### **1. Logistic Regression**
- **Algorithm**: Linear classifier with L2 regularization
- **Best for**: Interpretable baseline, fast training
- **Hyperparameters tuned**:
  - `C`: Regularization strength [0.001, 0.01, 0.1, 1, 10, 100]
  - `solver`: Optimization algorithm ['lbfgs', 'liblinear', 'saga']
  - `max_iter`: Maximum iterations [500, 1000, 2000]
  - `class_weight`: Handles class imbalance [None, 'balanced']

#### **2. Random Forest**
- **Algorithm**: Ensemble of decision trees with bagging
- **Best for**: High accuracy, handles non-linear relationships
- **Hyperparameters tuned**:
  - `n_estimators`: Number of trees [50, 100, 200, 300]
  - `max_depth`: Tree depth [None, 10, 20, 30, 40]
  - `min_samples_split`: Min samples to split [2, 5, 10]
  - `min_samples_leaf`: Min samples per leaf [1, 2, 4]
  - `max_features`: Features per split ['sqrt', 'log2', None]
  - `class_weight`: ['balanced', 'balanced_subsample', None]

#### **3. Decision Tree**
- **Algorithm**: Single decision tree classifier
- **Best for**: Fast predictions, interpretable
- **Hyperparameters tuned**:
  - `max_depth`: Tree depth [None, 5, 10, 15, 20, 25, 30]
  - `min_samples_split`: Min samples to split [2, 5, 10, 20]
  - `min_samples_leaf`: Min samples per leaf [1, 2, 4, 8]
  - `max_features`: Features per split ['sqrt', 'log2', None]
  - `criterion`: Split criterion ['gini', 'entropy']
  - `class_weight`: [' balanced', None]

---

### Hyperparameter Tuning

**Method**: `RandomizedSearchCV`
- **Cross-Validation**: 5-fold StratifiedKFold (maintains class balance)
- **Scoring Metric**: ROC-AUC (handles class imbalance better than accuracy)
- **Search Strategy**: Random search with 20 iterations
- **Parallelization**: `n_jobs=-1` (uses all CPU cores)

**Tuning Functions**:
```python
from MLOps_Assignment import (
    tune_logistic_regression,
    tune_random_forest,
    tune_decision_tree
)

# Tune Logistic Regression
best_lr, best_params_lr, cv_summary_lr = tune_logistic_regression(
    X_train, y_train, cv_splits=5, n_iter=20, method='randomized'
)

print(f"Best CV ROC-AUC: {cv_summary_lr['best_score']:.4f}")
print(f"Best Parameters: {best_params_lr}")
```

**Why RandomizedSearchCV?**
- ✅ Faster than GridSearchCV (samples parameter space)
- ✅ Good for large parameter grids
- ✅ Often finds near-optimal solutions
- ✅ Efficient for Random Forest (many hyperparameters)

---

### Model Evaluation

**Metrics Tracked**:

| Metric | Purpose | Interpretation |
|--------|---------|----------------|
| **Accuracy** | Overall correctness | (TP+TN)/(TP+TN+FP+FN) |
| **Precision** | Positive prediction accuracy | TP/(TP+FP) - How many predicted diseases are actual |
| **Recall** | True positive capture rate | TP/(TP+FN) - How many actual diseases are detected |
| **F1-Score** | Harmonic mean of precision/recall | Balances precision and recall |
| **ROC-AUC** | Discrimination ability | Area under ROC curve (0.5-1.0) |

**Evaluation Strategy**:
1. **Cross-Validation** (5-fold): Estimates generalization performance
2. **Train/Test Split** (80/20): Final evaluation on holdout set
3. **Stratified Sampling**: Maintains 54/46 class balance in each fold

**Evaluation Code**:
```python
from MLOps_Assignment import evaluate_classification_model

metrics = evaluate_classification_model(
    model, X_train, y_train, X_test, y_test, model_name="Random Forest"
)

print(f"Test Accuracy: {metrics['test_accuracy']:.4f}")
print(f"Test ROC-AUC: {metrics['test_roc_auc']:.4f}")
print(f"Test F1-Score: {metrics['test_f1']:.4f}")
```

---

### Cross-Validation Results

**Function**: `cross_validate_models()`

Compares all three models using 5-fold cross-validation:

```python
from MLOps_Assignment import cross_validate_models

cv_results = cross_validate_models(X, y, cv_splits=5)
print(cv_results)
```

**Example Output**:
```
              model  accuracy_mean  accuracy_std  precision_mean  ...
 Logistic Regression         0.8485        0.0321          0.8421  ...
       Random Forest         0.8652        0.0289          0.8734  ...
       Decision Tree         0.7983        0.0412          0.7856  ...
```

**Interpretation**:
- **Mean**: Average performance across 5 folds
- **Std**: Performance variability (lower is more stable)
- Random Forest typically achieves highest ROC-AUC (~0.87-0.90)

---

### Feature Importance

**Extraction** (Random Forest & Decision Tree only):
```python
from MLOps_Assignment import extract_feature_importance

importance_df = extract_feature_importance(
    model=best_random_forest,
    feature_names=X_train.columns.tolist(),
    top_n=15,
    output_dir="./artifacts/feature_importance",
    save_plot=True
)

print(importance_df.head(10))
```

**Top Features** (typical results):
1. `ca` (number of major vessels) - ~25% importance
2. `thal` (thalassemia) - ~15% importance
3. `oldpeak` (ST depression) - ~12% importance
4. `thalach` (max heart rate) - ~10% importance
5. `age` - ~8% importance

**Visualization**: Horizontal bar chart of top 15 features saved to MLflow

---

### Model Selection Criteria

**Primary Metric**: ROC-AUC (handles class imbalance)

**Selection Process**:
1. Tune hyperparameters for all 3 models
2. Evaluate on test set with all metrics
3. Compare test ROC-AUC scores
4. Consider precision/recall tradeoff for medical domain
5. Select best performing model

**Typical Winner**: Random Forest
- ✅ Highest ROC-AUC (~0.88-0.92 on test set)
- ✅ Good precision and recall balance
- ✅ Handles non-linear relationships
- ✅ Robust to outliers

**Deployment**: Best model saved as pickle and logged to MLflow

---

## 📦 Model Packaging & Reproducibility

### Ensuring Full Reproducibility

This project implements **complete reproducibility** by saving not just the trained model, but the entire preprocessing pipeline required for inference.

#### **What Gets Saved**

For each trained model, we save:

1. **📊 Trained Model** (`model_name.pkl`)
   - Serialized scikit-learn model
   - Ready for immediate inference

2. **🔧 Preprocessing Scaler** (`model_name_scaler.pkl`)
   - StandardScaler fitted on training data
   - **CRITICAL**: Must be applied to all new inputs
   - Contains mean/std for each feature

3. **📁 MLflow Artifacts** (`mlruns/`)
   - Model metadata and parameters
   - Training metrics and plots
   - Experiment tracking

4. **🔬 ONNX Export** (Optional)
   - Cross-platform model format
   - For production deployment

#### **Why Preprocessing Matters**

**❌ WITHOUT PREPROCESSING (INCORRECT)**:
```python
# BAD: Direct prediction on raw data
prediction = model.predict(raw_patient_data)  # ❌ WRONG!
# Result: Incorrect predictions, degraded accuracy
```

**✅ WITH PREPROCESSING (CORRECT)**:
```python
# GOOD: Apply same preprocessing as training
scaler = pickle.load(open("logistic_regression_scaler.pkl", "rb"))
scaled_data = scaler.transform(raw_patient_data)
prediction = model.predict(scaled_data)  # ✅ CORRECT!
# Result: Accurate predictions matching training performance
```

#### **How It Works**

**During Training** (`ci_train.py`):
```python
# 1. Prepare features and create scaler
X, y, scaler = prepare_ml_features(cleaned_df)
# scaler is fitted on training data

# 2. Train model on scaled features
model.fit(X_train, y_train)

# 3. Save BOTH model and scaler
save_final_model(
    model,
    model_name="Logistic Regression",
    output_dir="artifacts",
    scaler=scaler,  # ⭐ Save preprocessing pipeline
    save_pickle=True
)
# Creates:
# - artifacts/logistic_regression.pkl
# - artifacts/logistic_regression_scaler.pkl
```

**During Inference** (`api_server.py`):
```python
# 1. Load both model and scaler
model = pickle.load(open("logistic_regression.pkl", "rb"))
scaler = pickle.load(open("logistic_regression_scaler.pkl", "rb"))

# 2. Apply preprocessing before prediction
input_data = pd.DataFrame([patient.dict()])
numeric_cols = input_data.select_dtypes(include=['int64', 'float64']).columns
input_data[numeric_cols] = scaler.transform(input_data[numeric_cols])

# 3. Make prediction
prediction = model.predict(input_data)
```

#### **Artifacts Directory Structure**

```
artifacts/
├── logistic_regression.pkl          # Trained model
├── logistic_regression_scaler.pkl   # ⭐ Preprocessing scaler
├── random_forest.pkl
├── random_forest_scaler.pkl         # ⭐ Preprocessing scaler
├── decision_tree.pkl
└── decision_tree_scaler.pkl         # ⭐ Preprocessing scaler
```

#### **Generating Scaler Files**

If you have existing models without scalers, regenerate them:

```bash
cd Assignment
python3 generate_scalers.py
```

This script:
1. Loads the original training data
2. Recreates the preprocessing pipeline
3. Saves scaler files for all existing models

#### **Preprocessing Steps**

The `prepare_ml_features()` function applies:

1. **Feature Scaling**: StandardScaler
   - Normalizes numeric features to mean=0, std=1
   - Ensures consistent feature magnitude
   - Critical for distance-based algorithms

2. **One-Hot Encoding**: pd.get_dummies
   - Converts categorical features to binary columns
   - Applied automatically during preprocessing

3. **Feature Alignment**:
   - Ensures test data has same features as training
   - Handles missing columns gracefully

#### **Deployment Checklist**

✅ **Model Packaging**:
- [x] Model saved in pickle format
- [x] Scaler saved alongside model
- [x] MLflow artifacts logged
- [x] ONNX export (optional)

✅ **Inference Pipeline**:
- [x] API loads both model + scaler
- [x] Preprocessing applied before prediction
- [x] Feature alignment verified
- [x] Error handling for missing scalers

✅ **Docker/Kubernetes**:
- [x] Dockerfile copies artifacts/ directory
- [x] Container includes scaler files
- [x] Health checks verify model loading

#### **Reproducibility Best Practices**

1. **Always Save Preprocessing Artifacts**
   - Scalers, encoders, feature selectors
   - Any transformation applied during training

2. **Version Your Data**
   - Log data checksums in MLflow
   - Track data version/date

3. **Pin Dependencies**
   - Use exact versions in requirements.txt
   - Current: `scikit-learn==1.3.0`

4. **Document Feature Engineering**
   - Keep preprocessing code modular
   - Test preprocessing pipeline separately

5. **Validate Predictions**
   - Test API predictions match training metrics
   - Monitor prediction distribution in production

---

### Training Pipeline

**Complete Training Workflow**:

```bash
# Run CI training with hyperparameter tuning
cd Assignment
python ci_train.py
```

**Pipeline Steps**:
1. Data validation
2. EDA generation
3. Feature engineering
4. Hyperparameter tuning (3 models)
5. Model evaluation
6. Feature importance extraction
7. MLflow logging
8. Model saving

**MLflow Tracking**:
- All hyperparameters logged
- All metrics logged (train + test)
- Best parameters logged
- EDA plots logged
- Feature importance plots logged
- Models versioned and registered

---

### Tuning Results (Example)

**Logistic Regression**:
```
Best CV ROC-AUC: 0.8721
Best Parameters: {'C': 0.1, 'solver': 'lbfgs', 'max_iter': 1000, 'class_weight': 'balanced'}
Test ROC-AUC: 0.8654
```

**Random Forest**:
```
Best CV ROC-AUC: 0.9012
Best Parameters: {'n_estimators': 200, 'max_depth': 20, 'min_samples_split': 5, 'class_weight': 'balanced'}
Test ROC-AUC: 0.8945
```

**Decision Tree**:
```
Best CV ROC-AUC: 0.8234
Best Parameters: {'max_depth': 10, 'min_samples_split': 10, 'criterion': 'gini', 'class_weight': 'balanced'}
Test ROC-AUC: 0.8156
```

**Winner**: Random Forest (highest test ROC-AUC)

---

## 📊 Experiment Tracking with MLflow

### Overview

All model training experiments are automatically tracked using **MLflow 2.9.2**, providing comprehensive logging of parameters, metrics, artifacts, and model versions for reproducibility and comparison.

### What Gets Tracked

#### **Parameters Logged**
- **Data validation metrics**: total_rows, missing_values, duplicate_rows, data_validation_passed
- **Hyperparameter tuning config**: tuning_method, tuning_cv_splits, tuning_n_iter
- **Best hyperparameters**: All optimized parameters with `best_` prefix (e.g., `best_C`, `best_n_estimators`)
- **Model metadata**: model_name, scaler_mean_len, train_rows, test_rows

#### **Metrics Logged**
- **Cross-validation**: best_cv_roc_auc, n_candidates_evaluated
- **Test set performance**: test_accuracy, test_roc_auc, test_f1, test_precision, test_recall, train_accuracy
- **Data distribution**: class_0_count, class_1_count

#### **Artifacts Logged**
- **EDA visualizations**: 5 plots (feature distributions, correlations, class balance, box plots, outliers)
- **Feature importance plots**: For Random Forest and Decision Tree models
- **Model files**: Serialized sklearn models in MLflow format
- **Confusion matrices**: Classification confusion matrix plots
- **Model comparison table**: CSV with all models' performance metrics
- **ROC curves**: ROC-AUC curves for all models
- **Precision-Recall curves**: PR curves for imbalanced classification

#### **Model Registry**
- Best model automatically registered with version control
- Models tagged with environment, purpose, and performance metrics
- Staging transitions (None → Staging → Production)

---

### Starting MLflow UI

#### **Method 1: From Assignment Directory (Recommended)**

```bash
cd Assignment
mlflow ui --host 0.0.0.0 --port 5000
```

Then open: **http://localhost:5000**

#### **Method 2: From Project Root**

```bash
cd mlops
mlflow ui --backend-store-uri file:///absolute/path/to/Assignment/mlruns --host 0.0.0.0 --port 5000
```

#### **Method 3: Background Process**

```bash
cd Assignment
nohup mlflow ui --host 0.0.0.0 --port 5000 > mlflow.log 2>&1 &
echo $! > mlflow.pid  # Save PID for later shutdown
```

**Stop MLflow UI**:
```bash
kill $(cat mlflow.pid)
rm mlflow.pid
```

---

### MLflow UI Features

#### **1. Experiments Page**
- **Location**: Main dashboard at http://localhost:5000
- **View**: All experiments and runs in table format
- **Features**:
  - Filter runs by metrics, parameters, or tags
  - Sort by any metric (e.g., test_roc_auc)
  - Compare multiple runs side-by-side
  - Search by run name or ID

**Example Filters**:
```
metrics.test_roc_auc > 0.85
params.tuning_method = "RandomizedSearchCV"
tags.environment = "ci"
```

#### **2. Run Details Page**
- **Location**: Click any run name
- **Sections**:
  - **Parameters**: All hyperparameters and configuration
  - **Metrics**: Performance metrics with history
  - **Artifacts**: EDA plots, models, confusion matrices
  - **Tags**: Run metadata and labels
  - **Notes**: Custom descriptions and observations

#### **3. Compare Runs**
- **How**: Select multiple runs → Click "Compare"
- **Features**:
  - Side-by-side parameter comparison
  - Metric trends across runs
  - Scatter plots (e.g., test_roc_auc vs n_estimators)
  - Parallel coordinates plot for hyperparameter analysis

**Example Use Case**:
Compare all 3 models (Logistic Regression, Random Forest, Decision Tree) to see which hyperparameters correlate with better performance.

#### **4. Model Registry**
- **Location**: http://localhost:5000/#/models
- **Features**:
  - View all registered models with versions
  - Promote models through stages (None → Staging → Production)
  - Add descriptions and tags to model versions
  - Track which runs produced which model versions

**Model Lifecycle**:
```
Training Run → Register Model → Version 1 (None)
    ↓
Validation Pass → Transition to Staging
    ↓
Production Approval → Transition to Production
```

#### **5. Visualizations**
- **Artifacts Browser**: View all logged plots inline
- **Metric History**: Track metric evolution across epochs/iterations
- **Parallel Coordinates**: Visualize high-dimensional hyperparameter space
- **Scatter Plots**: Compare two metrics or parameters

---

### Accessing MLflow UI Remotely

#### **From Remote Machine (e.g., AlmaLinux Server)**

**Step 1: Start MLflow UI with Public IP**
```bash
cd Assignment
mlflow ui --host 0.0.0.0 --port 5000
```

**Step 2: Configure Firewall**
```bash
# Open port 5000
sudo firewall-cmd --permanent --add-port=5000/tcp
sudo firewall-cmd --reload
```

**Step 3: Access from Remote Client**
```
http://<server-ip>:5000
```

**Example**:
```
http://192.168.1.100:5000
```

#### **SSH Tunneling (Secure Alternative)**

**From local machine**:
```bash
ssh -L 5000:localhost:5000 user@<server-ip>
```

Then access: http://localhost:5000

---

### Experiment Organization

#### **Experiment Structure**
```
mlruns/
├── 1/                                    # Experiment ID 1
│   ├── 0ed89bfe.../                      # Run: ci_logistic_regression
│   │   ├── artifacts/
│   │   │   ├── eda/                      # EDA plots
│   │   │   ├── plots/                    # Confusion matrix
│   │   │   ├── logistic_regression_ci_mlflow_model/  # Model
│   │   │   └── model_comparison.csv      # Comparison table
│   │   ├── metrics/
│   │   │   ├── test_roc_auc              # Metric values
│   │   │   ├── test_accuracy
│   │   │   └── best_cv_roc_auc
│   │   ├── params/
│   │   │   ├── best_C                    # Best hyperparameters
│   │   │   ├── tuning_method
│   │   │   └── model_name
│   │   └── tags/
│   │       ├── mlflow.runName
│   │       ├── environment
│   │       └── purpose
│   ├── 1ec813ae.../                      # Run: ci_random_forest
│   └── 22da23bc.../                      # Run: ci_decision_tree
└── models/                               # Model Registry
    └── heart-disease-classifier/
        ├── version-1/                    # Logistic Regression
        ├── version-2/                    # Random Forest
        └── version-3/                    # Decision Tree
```

#### **Experiment Naming Convention**
- **Experiment Name**: `ci_heart_disease_classification`
- **Run Names**: `ci_<model_name>` (e.g., `ci_random_forest`)
- **Model Name**: `heart-disease-classifier`

---

### Common MLflow Commands

#### **Query Experiments**
```bash
# List all experiments
mlflow experiments list

# Search runs
mlflow runs list --experiment-id 1

# Get best run
mlflow runs list --experiment-id 1 --order-by "metrics.test_roc_auc DESC" --max-results 1
```

#### **Load Model Programmatically**
```python
import mlflow

# Load latest production model
model = mlflow.pyfunc.load_model("models:/heart-disease-classifier/Production")

# Load specific run's model
model = mlflow.sklearn.load_model("runs:/<run-id>/logistic_regression_ci_mlflow_model")

# Make predictions
predictions = model.predict(X_test)
```

#### **Register Model from Run**
```python
import mlflow

# Register model from specific run
mlflow.register_model(
    model_uri="runs:/<run-id>/random_forest_ci_mlflow_model",
    name="heart-disease-classifier"
)

# Transition to production
client = mlflow.tracking.MlflowClient()
client.transition_model_version_stage(
    name="heart-disease-classifier",
    version=2,
    stage="Production"
)
```

---

### Viewing Experiment Results

#### **Via MLflow UI (Recommended)**
1. Start MLflow UI: `mlflow ui`
2. Open http://localhost:5000
3. Navigate to experiment: `ci_heart_disease_classification`
4. View runs, compare metrics, download artifacts

#### **Via Python API**
```python
import mlflow
import pandas as pd

# Get experiment
experiment = mlflow.get_experiment_by_name("ci_heart_disease_classification")

# Search runs
runs = mlflow.search_runs(
    experiment_ids=[experiment.experiment_id],
    order_by=["metrics.test_roc_auc DESC"]
)

# Display results
print(runs[['run_id', 'metrics.test_roc_auc', 'metrics.test_accuracy', 'params.model_name']])
```

#### **Via CLI**
```bash
# Get best run by ROC-AUC
mlflow runs list \
    --experiment-id 1 \
    --order-by "metrics.test_roc_auc DESC" \
    --max-results 1 \
    --view all
```

---

### Best Practices

#### **1. Consistent Naming**
- Use descriptive run names: `ci_logistic_regression` not `run_1`
- Tag runs with metadata: `environment=ci`, `purpose=hyperparameter_tuning`

#### **2. Log Everything**
- Parameters: All hyperparameters and configuration
- Metrics: All evaluation metrics (train + test)
- Artifacts: Plots, models, data samples, config files

#### **3. Model Registry**
- Register production-worthy models only
- Use semantic versioning in descriptions
- Document model performance in version notes

#### **4. Experiment Organization**
- One experiment per project/use case
- Use run tags to group related runs
- Archive old experiments periodically

#### **5. Reproducibility**
- Log random seeds and environment info
- Log data versions or checksums
- Save preprocessing artifacts (scalers, encoders)

---

## 🚀 Project Overview

### What This Project Does

1. **Machine Learning**: Trains models to predict heart disease
2. **API Service**: FastAPI server for predictions
3. **Containerization**: Docker image with all dependencies
4. **Orchestration**: Kubernetes deployment with Helm
5. **Monitoring**: Prometheus metrics + Grafana dashboards
6. **CI/CD**: Automated testing and deployment

### Key Features

✅ **Production-Ready API** - FastAPI with automatic documentation  
✅ **Kubernetes Native** - Helm charts for easy deployment  
✅ **Full Observability** - Prometheus + Grafana monitoring  
✅ **Automated Testing** - Unit and integration tests  
✅ **Remote Access** - NGINX reverse proxy for external access  
✅ **Fixed Ports** - Consistent access across deployments  

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Remote Clients                        │
└──────────────────────┬──────────────────────────────────┘
                       │
                       ↓
            ┌──────────────────────┐
            │   NGINX Reverse Proxy │
            │   (Port 80, 3000,    │
            │    9090)             │
            └──────────┬───────────┘
                       │
                       ↓
            ┌──────────────────────┐
            │   Kubernetes Ingress  │
            │   (NGINX Controller)  │
            └──────────┬───────────┘
                       │
       ┌───────────────┼───────────────┐
       │               │               │
       ↓               ↓               ↓
┌─────────────┐ ┌──────────┐ ┌──────────┐
│ API Service │ │Prometheus│ │ Grafana  │
│  (ClusterIP)│ │(NodePort)│ │(NodePort)│
│  Port: 80   │ │Port: 9090│ │Port: 3000│
└──────┬──────┘ └────┬─────┘ └────┬─────┘
       │             │            │
       ↓             ↓            ↓
┌─────────────┐ ┌──────────┐ ┌──────────┐
│   API Pods  │ │Prometheus│ │ Grafana  │
│  (2 replicas│ │   Pod    │ │   Pod    │
│   Port 8000)│ └──────────┘ └──────────┘
└─────────────┘
       │
       ↓
┌─────────────┐
│ ML Model    │
│ (Logistic   │
│  Regression)│
└─────────────┘
```

### Technology Stack

- **ML**: scikit-learn, pandas, numpy
- **API**: FastAPI, Uvicorn
- **Containerization**: Docker
- **Orchestration**: Kubernetes (Minikube)
- **Package Management**: Helm
- **Monitoring**: Prometheus, Grafana
- **CI/CD**: GitHub Actions
- **Reverse Proxy**: NGINX

---

## 🚀 Deployment

### Option 1: Automated Deployment (Recommended)

```bash
cd Assignment/monitoring
./setup-complete-monitoring.sh
```

This script:
1. Checks prerequisites
2. Rebuilds Docker image with monitoring
3. Deploys Prometheus and Grafana
4. Upgrades API deployment
5. Verifies everything is working

### Option 2: Manual Deployment

#### Step 1: Start Minikube

```bash
minikube start --driver=docker --cpus=2 --memory=4096
minikube addons enable ingress
```

#### Step 2: Build Docker Image

```bash
cd Assignment
eval $(minikube docker-env)
docker build -t heart-disease-api:latest .
```

#### Step 3: Deploy with Helm

```bash
cd helm-charts
helm upgrade --install heart-disease-api ./heart-disease-api \
  --namespace mlops \
  --create-namespace \
  --set image.pullPolicy=Never \
  --set image.tag=latest
```

#### Step 4: Deploy Monitoring

```bash
cd ../monitoring
kubectl apply -f prometheus-deployment.yaml
kubectl apply -f grafana-deployment.yaml
```

#### Step 5: Verify Deployment

```bash
kubectl get pods -n mlops
kubectl get svc -n mlops
```

### Fixed Port Assignments

All services use fixed ports for consistency:

| Service | NodePort | Internal Port |
|---------|----------|---------------|
| API | 30080 | 8000 |
| Prometheus | 30090 | 9090 |
| Grafana | 30030 | 3000 |

---

## 📊 Monitoring

### Prometheus Metrics

The API exposes these metrics at `/metrics`:

- `api_requests_total` - Total API requests by endpoint and status
- `api_request_duration_seconds` - Request latency histogram
- `predictions_total` - Total predictions by result
- `prediction_duration_seconds` - Prediction latency
- `prediction_confidence_score` - Confidence score distribution
- `active_requests` - Current active requests
- `model_loaded` - Model health status
- `api_errors_total` - Error count by type

### Grafana Dashboard

Pre-configured dashboard with 11 panels:
1. Total API Requests (graph)
2. Request Duration p95 (graph)
3. Predictions by Result (pie chart)
4. Prediction Latency (graph)
5. Confidence Distribution (heatmap)
6. Total Predictions (stat)
7. Total Errors (stat)
8. Model Status (stat)
9. Success Rate (gauge)
10. Active Requests (graph)
11. Error Rate (graph)

**Import Dashboard:**
1. Access Grafana: http://\<server-ip\>:3000
2. Login: admin/admin
3. Click "+" → "Import"
4. Upload `monitoring/grafana-dashboard.json`
5. Select Prometheus datasource

### Generate Test Traffic

```bash
cd monitoring
./test-metrics.sh
```

---

## 🔌 API Usage

### Health Check

```bash
curl http://<server-ip>/health

# Response:
# {
#   "status": "healthy",
#   "model_loaded": true,
#   "model_name": "logistic_regression"
# }
```

### Single Prediction

```bash
curl -X POST http://<server-ip>/predict \
  -H "Content-Type: application/json" \
  -d '{
    "age": 63,
    "sex": 1,
    "cp": 3,
    "trestbps": 145,
    "chol": 233,
    "fbs": 1,
    "restecg": 0,
    "thalach": 150,
    "exang": 0,
    "oldpeak": 2.3,
    "slope": 0,
    "ca": 0,
    "thal": 1
  }'

# Response:
# {
#   "prediction": 1,
#   "confidence": 0.85,
#   "model_name": "logistic_regression"
# }
```

### Batch Prediction

```bash
curl -X POST http://<server-ip>/predict/batch \
  -H "Content-Type: application/json" \
  -d @sample_batch_input.json
```

### API Documentation

Interactive API docs available at:
- **Swagger UI**: http://\<server-ip\>/docs
- **ReDoc**: http://\<server-ip\>/redoc

---

## 🧪 Testing

### Run Unit Tests

```bash
cd Assignment
pytest tests/ -v
```

Unit tests run automatically in CI/CD.

### Run Integration Tests

Requires running API server:

```bash
# Terminal 1: Start API
uvicorn api_server:app --host 0.0.0.0 --port 8000

# Terminal 2: Run tests
./run_integration_tests.sh
```

### Test CI/CD Locally

```bash
cd Assignment
./test_ci_locally.sh
```

This simulates the entire CI/CD pipeline locally.

---

## 🌐 Remote Access

### Problem
Minikube IP (192.168.49.2) is internal and not accessible from remote machines.

### Solution: NGINX Reverse Proxy

```bash
cd Assignment
./setup-nginx-proxy.sh
```

This script:
1. Installs NGINX
2. Configures reverse proxy to Minikube services
3. Opens firewall ports
4. Starts NGINX

**After setup, access from anywhere:**
- API: http://\<almalinux-server-ip\>/
- Prometheus: http://\<almalinux-server-ip\>:9090
- Grafana: http://\<almalinux-server-ip\>:3000

---

## 🔧 Troubleshooting

### Pods Not Starting

```bash
# Check pod status
kubectl get pods -n mlops

# Describe pod for details
kubectl describe pod <pod-name> -n mlops

# Check logs
kubectl logs -n mlops <pod-name>
```

### Cannot Access Services

```bash
# Check services
kubectl get svc -n mlops

# Verify firewall
sudo firewall-cmd --list-ports

# Check NGINX status (if using reverse proxy)
sudo systemctl status nginx
sudo tail -f /var/log/nginx/error.log
```

### Docker Build Fails

```bash
# Ensure using Minikube's Docker
eval $(minikube docker-env)
docker info | grep Name  # Should show "minikube"

# Build with no cache
docker build --no-cache -t heart-disease-api:latest .
```

### Integration Tests Failing

Integration tests require running API server. They are automatically skipped if server is not available.

```bash
# Start API first
uvicorn api_server:app --host 0.0.0.0 --port 8000

# Then run tests
python integration_tests/test_api.py
```

### CI/CD Failing

Check the GitHub Actions log for specific errors:
1. Go to GitHub repository
2. Click "Actions" tab
3. Click on failing workflow
4. Review error logs

Common issues:
- Import errors → Check PYTHONPATH
- Collection errors → Ensure pytest finds correct tests
- Integration test errors → Should be skipped automatically

---

## 📁 Project Structure

```
Assignment/
├── MLOps_Assignment.py          # Core ML pipeline
├── api_server.py                # FastAPI server
├── ci_train.py                  # CI/CD training script
├── Dockerfile                   # Container image
├── requirements.txt             # Python dependencies
├── requirements-dev.txt         # Dev dependencies
│
├── tests/                       # Unit tests
│   ├── test_models.py
│   └── test_data_pipeline.py
│
├── integration_tests/           # Integration tests
│   ├── test_api.py
│   └── conftest.py
│
├── helm-charts/                 # Kubernetes deployment
│   └── heart-disease-api/
│       ├── Chart.yaml
│       ├── values.yaml
│       ├── values-dev.yaml
│       └── templates/
│
├── monitoring/                  # Monitoring stack
│   ├── prometheus-config.yaml
│   ├── prometheus-deployment.yaml
│   ├── grafana-deployment.yaml
│   ├── grafana-dashboard.json
│   ├── setup-complete-monitoring.sh
│   ├── deploy-monitoring.sh
│   ├── test-metrics.sh
│   └── README.md
│
├── data/                        # Training data
├── artifacts/                   # Model artifacts
├── mlruns/                      # MLflow tracking
│
├── setup-nginx-proxy.sh         # Remote access setup
├── run_integration_tests.sh     # Integration test runner
├── test_ci_locally.sh           # Local CI/CD simulator
└── README.md                    # This file
```

---

## 📚 Additional Resources

### Configuration Files
- `pytest.ini` - Test configuration
- `Dockerfile` - Container build instructions
- `.dockerignore` - Docker build exclusions
- `.github/workflows/ci.yml` - CI/CD pipeline

### Sample Files
- `sample_input.json` - Single prediction example
- `sample_batch_input.json` - Batch prediction example

### Scripts
- `run_docker.sh` - Docker container management
- `helm-charts/deploy.sh` - Helm deployment
- `helm-charts/cleanup.sh` - Remove deployment
- `monitoring/cleanup-monitoring.sh` - Remove monitoring

---

## 🔄 Update Workflow

When code changes:

```bash
# 1. Pull latest code
git pull origin main

# 2. Rebuild Docker image
eval $(minikube docker-env)
docker build -t heart-disease-api:latest .

# 3. Restart deployment
kubectl rollout restart deployment/heart-disease-api -n mlops

# 4. Verify
kubectl rollout status deployment/heart-disease-api -n mlops
curl http://$(minikube ip):30080/health
```

---

## 🎯 Production Checklist

Before going to production:

- [ ] Configure SSL/TLS for HTTPS
- [ ] Set up proper authentication
- [ ] Configure resource limits
- [ ] Enable horizontal pod autoscaling
- [ ] Set up proper logging
- [ ] Configure backup for persistent data
- [ ] Set up alerting rules in Prometheus
- [ ] Configure network policies
- [ ] Set up pod disruption budgets
- [ ] Use production values (values-prod.yaml)

---

## 📊 Metrics Summary

- **Endpoint**: `/metrics`
- **Format**: Prometheus exposition format
- **Scrape Interval**: 15 seconds
- **Retention**: 15 days (Prometheus default)

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make changes with tests
4. Run local CI/CD: `./test_ci_locally.sh`
5. Submit pull request

---

## 📄 License

This project is for educational purposes as part of BITS MLOps course.

---

## 🆘 Support

For issues or questions:
1. Check troubleshooting section above
2. Review GitHub Issues
3. Check CI/CD logs
4. Review Kubernetes logs: `kubectl logs -n mlops <pod-name>`

---

## 🎉 Quick Commands Reference

```bash
# Deployment
minikube start
./monitoring/setup-complete-monitoring.sh
./setup-nginx-proxy.sh

# Access
curl http://<ip>/health
open http://<ip>/docs

# Monitoring
curl http://<ip>/metrics
open http://<ip>:9090          # Prometheus
open http://<ip>:3000          # Grafana

# Testing
pytest tests/
./run_integration_tests.sh
./test_ci_locally.sh

# Troubleshooting
kubectl get pods -n mlops
kubectl logs -n mlops <pod-name>
kubectl describe pod <pod-name> -n mlops

# Updates
git pull
eval $(minikube docker-env)
docker build -t heart-disease-api:latest .
kubectl rollout restart deployment/heart-disease-api -n mlops
```

---

**Ready to deploy? Start with the [Quick Start](#-quick-start) section!** 🚀

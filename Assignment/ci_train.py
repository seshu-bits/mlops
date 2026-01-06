from pathlib import Path
import pandas as pd
import numpy as np
from datetime import datetime

import mlflow
import mlflow.sklearn
from sklearn.metrics import roc_curve, auc, precision_recall_curve, average_precision_score

from MLOps_Assignment import (
    load_raw_heart_data,
    clean_and_preprocess_heart_data,
    validate_heart_data,
    perform_eda_heart_data,
    prepare_ml_features,
    train_test_split_features,
    tune_logistic_regression,
    tune_random_forest,
    tune_decision_tree,
    extract_feature_importance,
    evaluate_classification_model,
    save_final_model,
)


def plot_roc_curve(y_test, y_pred_proba, model_name: str, output_path: Path):
    """Generate and save ROC curve plot."""
    import matplotlib.pyplot as plt
    
    fpr, tpr, _ = roc_curve(y_test, y_pred_proba)
    roc_auc = auc(fpr, tpr)
    
    plt.figure(figsize=(8, 6))
    plt.plot(fpr, tpr, color='darkorange', lw=2, label=f'ROC curve (AUC = {roc_auc:.4f})')
    plt.plot([0, 1], [0, 1], color='navy', lw=2, linestyle='--', label='Random Classifier')
    plt.xlim([0.0, 1.0])
    plt.ylim([0.0, 1.05])
    plt.xlabel('False Positive Rate')
    plt.ylabel('True Positive Rate')
    plt.title(f'ROC Curve - {model_name}')
    plt.legend(loc="lower right")
    plt.grid(alpha=0.3)
    plt.tight_layout()
    plt.savefig(output_path, dpi=150)
    plt.close()
    
    return roc_auc


def plot_precision_recall_curve(y_test, y_pred_proba, model_name: str, output_path: Path):
    """Generate and save Precision-Recall curve plot."""
    import matplotlib.pyplot as plt
    
    precision, recall, _ = precision_recall_curve(y_test, y_pred_proba)
    avg_precision = average_precision_score(y_test, y_pred_proba)
    
    plt.figure(figsize=(8, 6))
    plt.plot(recall, precision, color='blue', lw=2, label=f'PR curve (AP = {avg_precision:.4f})')
    plt.xlabel('Recall')
    plt.ylabel('Precision')
    plt.title(f'Precision-Recall Curve - {model_name}')
    plt.legend(loc="lower left")
    plt.grid(alpha=0.3)
    plt.tight_layout()
    plt.savefig(output_path, dpi=150)
    plt.close()
    
    return avg_precision


def plot_confusion_matrix(y_test, y_pred, model_name: str, output_path: Path):
    """Generate and save confusion matrix heatmap."""
    import matplotlib.pyplot as plt
    import seaborn as sns
    from sklearn.metrics import confusion_matrix
    
    cm = confusion_matrix(y_test, y_pred)
    
    plt.figure(figsize=(6, 5))
    sns.heatmap(cm, annot=True, fmt='d', cmap='Blues', cbar=True,
                xticklabels=['No Disease', 'Disease'],
                yticklabels=['No Disease', 'Disease'])
    plt.title(f'Confusion Matrix - {model_name}')
    plt.ylabel('True Label')
    plt.xlabel('Predicted Label')
    plt.tight_layout()
    plt.savefig(output_path, dpi=150)
    plt.close()


def main():
    data_dir = Path("./data")
    artifacts_dir = Path("./artifacts_ci")
    artifacts_dir.mkdir(parents=True, exist_ok=True)
    
    # Create subdirectories for plots
    plots_dir = artifacts_dir / "plots"
    plots_dir.mkdir(exist_ok=True)

    # Minimal: assume data is already downloaded as processed.cleveland.data
    # In CI, you can either commit a small sample or add a download step here.

    raw_df = load_raw_heart_data(data_dir=data_dir)

    # Validate data quality
    print("\n" + "=" * 60)
    print("DATA VALIDATION")
    print("=" * 60)
    validation_results = validate_heart_data(raw_df)
    print(f"Valid: {validation_results['is_valid']}")
    if validation_results['errors']:
        print(f"Errors: {validation_results['errors']}")
    if validation_results['warnings']:
        print(f"Warnings: {validation_results['warnings']}")
    print(f"Metrics: {validation_results['metrics']}")

    cleaned_df = clean_and_preprocess_heart_data(raw_df)

    # Perform EDA and save artifacts
    print("\n" + "=" * 60)
    print("EXPLORATORY DATA ANALYSIS")
    print("=" * 60)
    eda_results = perform_eda_heart_data(
        cleaned_df,
        output_dir=artifacts_dir / "eda",
        save_plots=True
    )
    print(f"EDA plots saved: {len(eda_results['plots'])} plots")
    for plot in eda_results['plots']:
        print(f"  - {plot}")

    X, y, scaler = prepare_ml_features(cleaned_df)
    X_train, X_test, y_train, y_test = train_test_split_features(X, y)

    mlflow.set_experiment("ci_heart_disease_classification")

    # Hyperparameter Tuning and Model Training
    print("\n" + "=" * 60)
    print("HYPERPARAMETER TUNING & MODEL TRAINING")
    print("=" * 60)

    models_to_tune = {
        "Logistic Regression": tune_logistic_regression,
        "Random Forest": tune_random_forest,
        "Decision Tree": tune_decision_tree,
    }

    best_models = {}
    all_results = []
    
    # Create parent run to group all model runs
    with mlflow.start_run(run_name=f"model_comparison_{datetime.now().strftime('%Y%m%d_%H%M%S')}") as parent_run:
        # Log parent run tags
        mlflow.set_tag("environment", "ci")
        mlflow.set_tag("purpose", "model_comparison")
        mlflow.set_tag("mlflow.note.content", "Comparing 3 models with hyperparameter tuning")
        
        # Log dataset info at parent level
        mlflow.log_params({
            "dataset_rows": len(cleaned_df),
            "dataset_features": X.shape[1],
            "train_size": len(X_train),
            "test_size": len(X_test),
            "target_classes": len(np.unique(y)),
        })

        for model_name, tune_func in models_to_tune.items():
            print(f"\nTuning {model_name}...")

            # Nested run for each model
            with mlflow.start_run(run_name=f"ci_{model_name.lower().replace(' ', '_')}", nested=True) as child_run:
                # Set run tags
                mlflow.set_tag("model_type", model_name.lower().replace(' ', '_'))
                mlflow.set_tag("environment", "ci")
                mlflow.set_tag("purpose", "hyperparameter_tuning")
                mlflow.set_tag("mlflow.runName", f"ci_{model_name.lower().replace(' ', '_')}")
                
                # Log validation metrics
                mlflow.log_params({
                    "data_validation_passed": validation_results['is_valid'],
                    "total_rows": validation_results['metrics'].get('total_rows', 0),
                    "missing_values": validation_results['metrics'].get('missing_values', 0),
                    "duplicate_rows": validation_results['metrics'].get('duplicate_rows', 0),
                })

                # Log EDA artifacts to MLflow (only for first model to avoid duplication)
                if model_name == "Logistic Regression":
                    for plot_path in eda_results['plots']:
                        mlflow.log_artifact(plot_path, artifact_path="eda")

                # Log class distribution
                if 'class_distribution' in eda_results['statistics']:
                    for cls, count in eda_results['statistics']['class_distribution'].items():
                        mlflow.log_metric(f"class_{cls}_count", count)

                # Hyperparameter tuning
                best_model, best_params, cv_summary = tune_func(
                    X_train, y_train, cv_splits=5, n_iter=20, method="randomized"
                )

                print(f"  Best CV Score (ROC-AUC): {cv_summary['best_score']:.4f}")
                print(f"  Best Parameters: {best_params}")
                print(f"  Candidates evaluated: {cv_summary['n_candidates']}")

                # Log tuning results
                mlflow.log_param("tuning_method", "RandomizedSearchCV")
                mlflow.log_param("tuning_cv_splits", 5)
                mlflow.log_param("tuning_n_iter", 20)
                mlflow.log_metric("best_cv_roc_auc", cv_summary['best_score'])
                mlflow.log_metric("n_candidates_evaluated", cv_summary['n_candidates'])

                # Log best parameters
                for param_name, param_value in best_params.items():
                    mlflow.log_param(f"best_{param_name}", param_value)

                # Evaluate on test set
                metrics = evaluate_classification_model(
                    best_model, X_train, y_train, X_test, y_test, model_name=model_name
                )

                # Log test metrics
                for k, v in metrics.items():
                    mlflow.log_metric(k, float(v))

                # Generate predictions for visualization
                y_pred = best_model.predict(X_test)
                y_pred_proba = best_model.predict_proba(X_test)[:, 1]
                
                # Generate and log ROC curve
                roc_plot_path = plots_dir / f"roc_curve_{model_name.lower().replace(' ', '_')}.png"
                roc_auc = plot_roc_curve(y_test, y_pred_proba, model_name, roc_plot_path)
                mlflow.log_artifact(str(roc_plot_path), artifact_path="plots")
                print(f"  ROC-AUC: {roc_auc:.4f}")
                
                # Generate and log Precision-Recall curve
                pr_plot_path = plots_dir / f"pr_curve_{model_name.lower().replace(' ', '_')}.png"
                avg_precision = plot_precision_recall_curve(y_test, y_pred_proba, model_name, pr_plot_path)
                mlflow.log_artifact(str(pr_plot_path), artifact_path="plots")
                mlflow.log_metric("average_precision_score", avg_precision)
                print(f"  Average Precision: {avg_precision:.4f}")
                
                # Generate and log Confusion Matrix
                cm_plot_path = plots_dir / f"confusion_matrix_{model_name.lower().replace(' ', '_')}.png"
                plot_confusion_matrix(y_test, y_pred, model_name, cm_plot_path)
                mlflow.log_artifact(str(cm_plot_path), artifact_path="plots")

                # Extract feature importance (if applicable)
                if hasattr(best_model, "feature_importances_"):
                    importance_df = extract_feature_importance(
                        best_model,
                        feature_names=X_train.columns.tolist(),
                        top_n=15,
                        output_dir=artifacts_dir / "feature_importance",
                        save_plot=True,
                    )
                    # Log feature importance plot
                    importance_plot = (
                        artifacts_dir
                        / "feature_importance"
                        / f"feature_importance_{type(best_model).__name__.lower()}.png"
                    )
                    if importance_plot.exists():
                        mlflow.log_artifact(str(importance_plot), artifact_path="feature_importance")

                # Save model
                save_final_model(
                    best_model,
                    model_name=f"{model_name} CI",
                    output_dir="artifacts_ci",
                    save_pickle=True,
                    save_mlflow=True,
                    save_onnx=False,
                    X_sample=X_train.iloc[:10],
                )

                # Also log scaler parameters
                mlflow.log_param("scaler_mean_len", len(scaler.mean_))
                mlflow.log_param("train_rows", len(X_train))
                mlflow.log_param("test_rows", len(X_test))

                best_models[model_name] = best_model
                all_results.append({
                    "model": model_name,
                    "run_id": child_run.info.run_id,
                    "cv_roc_auc": cv_summary['best_score'],
                    "test_accuracy": metrics['test_accuracy'],
                    "test_roc_auc": metrics['test_roc_auc'],
                    "test_f1": metrics['test_f1'],
                    "test_precision": metrics['test_precision'],
                    "test_recall": metrics['test_recall'],
                    "average_precision": avg_precision,
                })

        # Print final comparison
        print("\n" + "=" * 60)
        print("MODEL COMPARISON SUMMARY")
        print("=" * 60)
        results_df = pd.DataFrame(all_results)
        print(results_df[['model', 'cv_roc_auc', 'test_accuracy', 'test_roc_auc', 'test_f1']].to_string(index=False))

        # Save and log comparison table
        comparison_path = artifacts_dir / "model_comparison.csv"
        results_df.to_csv(comparison_path, index=False)
        mlflow.log_artifact(str(comparison_path), artifact_path="results")
        print(f"\n✓ Model comparison saved to: {comparison_path}")

        # Identify best model
        best_idx = results_df['test_roc_auc'].idxmax()
        best_model_name = results_df.loc[best_idx, 'model']
        best_run_id = results_df.loc[best_idx, 'run_id']
        best_roc_auc = results_df.loc[best_idx, 'test_roc_auc']
        
        print(f"\n🏆 Best Model: {best_model_name}")
        print(f"   Test ROC-AUC: {best_roc_auc:.4f}")
        print(f"   Run ID: {best_run_id}")
        
        # Log best model info to parent run
        mlflow.log_param("best_model_name", best_model_name)
        mlflow.log_metric("best_model_test_roc_auc", best_roc_auc)
        
        # Register best model to Model Registry
        try:
            model_uri = f"runs:/{best_run_id}/{best_model_name.lower().replace(' ', '_')}_ci_mlflow_model"
            registered_model = mlflow.register_model(
                model_uri=model_uri,
                name="heart-disease-classifier"
            )
            print(f"\n✓ Best model registered: heart-disease-classifier (version {registered_model.version})")
            
            # Add tags and description to registered model
            client = mlflow.tracking.MlflowClient()
            client.set_model_version_tag(
                name="heart-disease-classifier",
                version=registered_model.version,
                key="model_type",
                value=best_model_name
            )
            client.set_model_version_tag(
                name="heart-disease-classifier",
                version=registered_model.version,
                key="test_roc_auc",
                value=f"{best_roc_auc:.4f}"
            )
            client.update_model_version(
                name="heart-disease-classifier",
                version=registered_model.version,
                description=f"Best performing model: {best_model_name} with ROC-AUC={best_roc_auc:.4f}. "
                           f"Trained with hyperparameter tuning using RandomizedSearchCV."
            )
            
            # Transition to Staging (production deployment would transition to Production)
            client.transition_model_version_stage(
                name="heart-disease-classifier",
                version=registered_model.version,
                stage="Staging"
            )
            print(f"✓ Model transitioned to Staging")
            
        except Exception as e:
            print(f"\n⚠️  Could not register model: {e}")
            print("   This is normal if model registry is not configured")

    print("\n" + "=" * 60)
    print("TRAINING COMPLETE")
    print("=" * 60)
    print(f"\n📊 View results in MLflow UI:")
    print(f"   mlflow ui")
    print(f"   Open: http://localhost:5000")


if __name__ == "__main__":
    main()

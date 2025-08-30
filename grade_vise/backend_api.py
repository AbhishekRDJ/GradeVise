from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import pandas as pd
import pickle
import os
from typing import List, Optional

# Load the saved model, scaler, one-hot encoder, and training columns
model_path = "model/random_forest_model.pkl"
scaler_path = "model/scaler.pkl"
encoder_path = "model/onehot_encoder.pkl"
training_columns_path = "model/training_columns.pkl"

# Check if model files exist
if not all(os.path.exists(path) for path in [model_path, scaler_path, encoder_path, training_columns_path]):
    raise FileNotFoundError("Model files not found. Please ensure all model files are in the 'model' directory.")

with open(model_path, 'rb') as f:
    model = pickle.load(f)

with open(scaler_path, 'rb') as f:
    scaler = pickle.load(f)

with open(encoder_path, 'rb') as f:
    encoder = pickle.load(f)

with open(training_columns_path, 'rb') as f:
    training_columns = pickle.load(f)

app = FastAPI(title="Student Dropout Prediction API", version="1.0.0")

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, restrict this to your Flutter app's domain
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Pydantic models for request/response
class StudentData(BaseModel):
    marital_status: int
    application_mode: int
    application_order: int
    course: int
    daytime_evening_attendance: int
    previous_qualification: int
    previous_qualification_grade: float
    nationality: int
    mothers_qualification: int
    fathers_qualification: int
    mothers_occupation: int
    fathers_occupation: int
    admission_grade: float
    displaced: int
    educational_special_needs: int
    debtor: int
    tuition_fees_up_to_date: int
    gender: int
    scholarship_holder: int
    age_at_enrollment: int
    international: int
    curricular_units_1st_sem_credited: int
    curricular_units_1st_sem_enrolled: int
    curricular_units_1st_sem_evaluations: int
    curricular_units_1st_sem_approved: int

class PredictionResponse(BaseModel):
    prediction: int
    prediction_label: str
    confidence: float
    risk_level: str

@app.get("/")
async def root():
    return {"message": "Student Dropout Prediction API", "status": "running"}

@app.get("/health")
async def health_check():
    return {"status": "healthy", "model_loaded": model is not None}

@app.post("/predict", response_model=PredictionResponse)
async def predict_dropout(student_data: StudentData):
    try:
        # Convert to DataFrame
        input_data = {
            'Marital_status': student_data.marital_status,
            'Application_mode': student_data.application_mode,
            'Application_order': student_data.application_order,
            'Course': student_data.course,
            'Daytime_evening_attendance': student_data.daytime_evening_attendance,
            'Previous_qualification': student_data.previous_qualification,
            'Previous_qualification_grade': student_data.previous_qualification_grade,
            'Nacionality': student_data.nationality,
            'Mothers_qualification': student_data.mothers_qualification,
            'Fathers_qualification': student_data.fathers_qualification,
            'Mothers_occupation': student_data.mothers_occupation,
            'Fathers_occupation': student_data.fathers_occupation,
            'Admission_grade': student_data.admission_grade,
            'Displaced': student_data.displaced,
            'Educational_special_needs': student_data.educational_special_needs,
            'Debtor': student_data.debtor,
            'Tuition_fees_up_to_date': student_data.tuition_fees_up_to_date,
            'Gender': student_data.gender,
            'Scholarship_holder': student_data.scholarship_holder,
            'Age_at_enrollment': student_data.age_at_enrollment,
            'International': student_data.international,
            'Curricular_units_1st_sem_credited': student_data.curricular_units_1st_sem_credited,
            'Curricular_units_1st_sem_enrolled': student_data.curricular_units_1st_sem_enrolled,
            'Curricular_units_1st_sem_evaluations': student_data.curricular_units_1st_sem_evaluations,
            'Curricular_units_1st_sem_approved': student_data.curricular_units_1st_sem_approved
        }
        
        input_df = pd.DataFrame([input_data])
        
        # One-Hot Encoding for categorical features
        categorical_cols = [
            'Application_mode', 'Course', 'Marital_status', 'Nacionality',
            'Mothers_qualification', 'Fathers_qualification',
            'Mothers_occupation', 'Fathers_occupation'
        ]
        
        input_encoded = encoder.transform(input_df[categorical_cols])
        input_encoded_df = pd.DataFrame(input_encoded, columns=encoder.get_feature_names_out(categorical_cols))
        
        # Drop original categorical columns and concatenate encoded columns
        input_df = input_df.drop(columns=categorical_cols)
        input_df = pd.concat([input_df.reset_index(drop=True), input_encoded_df.reset_index(drop=True)], axis=1)
        
        # Scale the numerical features
        numerical_cols = [
            'Previous_qualification_grade', 'Admission_grade',
            'Curricular_units_1st_sem_credited', 'Curricular_units_1st_sem_enrolled',
            'Curricular_units_1st_sem_evaluations', 'Curricular_units_1st_sem_approved',
            'Age_at_enrollment'
        ]
        
        input_df[numerical_cols] = scaler.transform(input_df[numerical_cols])
        
        # Ensure the columns are in the same order as the training set
        input_df = input_df[training_columns]
        
        # Predict
        prediction = model.predict(input_df)[0]
        prediction_proba = model.predict_proba(input_df)[0]
        
        # Get confidence (probability of predicted class)
        confidence = max(prediction_proba)
        
        # Determine risk level
        if prediction == 0:  # Dropout
            if confidence > 0.8:
                risk_level = "High Risk"
            elif confidence > 0.6:
                risk_level = "Medium Risk"
            else:
                risk_level = "Low Risk"
        else:  # Not Dropout
            if confidence > 0.8:
                risk_level = "Low Risk"
            elif confidence > 0.6:
                risk_level = "Medium Risk"
            else:
                risk_level = "Some Risk"
        
        return PredictionResponse(
            prediction=prediction,
            prediction_label="Dropout" if prediction == 0 else "Not Dropout",
            confidence=round(confidence, 3),
            risk_level=risk_level
        )
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Prediction failed: {str(e)}")

@app.get("/model-info")
async def get_model_info():
    return {
        "model_type": "Random Forest",
        "features_count": len(training_columns),
        "categorical_features": [
            'Application_mode', 'Course', 'Marital_status', 'Nacionality',
            'Mothers_qualification', 'Fathers_qualification',
            'Mothers_occupation', 'Fathers_occupation'
        ],
        "numerical_features": [
            'Previous_qualification_grade', 'Admission_grade',
            'Curricular_units_1st_sem_credited', 'Curricular_units_1st_sem_enrolled',
            'Curricular_units_1st_sem_evaluations', 'Curricular_units_1st_sem_approved',
            'Age_at_enrollment'
        ]
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)

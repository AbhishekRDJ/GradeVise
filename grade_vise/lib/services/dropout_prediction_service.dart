import 'dart:convert';
import 'package:http/http.dart' as http;

class DropoutPredictionService {
  static const String baseUrl = 'http://localhost:8000'; // Change this to your backend URL
  
  // Student data model for prediction
  static Map<String, dynamic> createStudentData({
    required int maritalStatus,
    required int applicationMode,
    required int applicationOrder,
    required int course,
    required int daytimeEveningAttendance,
    required int previousQualification,
    required double previousQualificationGrade,
    required int nationality,
    required int mothersQualification,
    required int fathersQualification,
    required int mothersOccupation,
    required int fathersOccupation,
    required double admissionGrade,
    required int displaced,
    required int educationalSpecialNeeds,
    required int debtor,
    required int tuitionFeesUpToDate,
    required int gender,
    required int scholarshipHolder,
    required int ageAtEnrollment,
    required int international,
    required int curricularUnits1stSemCredited,
    required int curricularUnits1stSemEnrolled,
    required int curricularUnits1stSemEvaluations,
    required int curricularUnits1stSemApproved,
  }) {
    return {
      'marital_status': maritalStatus,
      'application_mode': applicationMode,
      'application_order': applicationOrder,
      'course': course,
      'daytime_evening_attendance': daytimeEveningAttendance,
      'previous_qualification': previousQualification,
      'previous_qualification_grade': previousQualificationGrade,
      'nationality': nationality,
      'mothers_qualification': mothersQualification,
      'fathers_qualification': fathersQualification,
      'mothers_occupation': mothersOccupation,
      'fathers_occupation': fathersOccupation,
      'admission_grade': admissionGrade,
      'displaced': displaced,
      'educational_special_needs': educationalSpecialNeeds,
      'debtor': debtor,
      'tuition_fees_up_to_date': tuitionFeesUpToDate,
      'gender': gender,
      'scholarship_holder': scholarshipHolder,
      'age_at_enrollment': ageAtEnrollment,
      'international': international,
      'curricular_units_1st_sem_credited': curricularUnits1stSemCredited,
      'curricular_units_1st_sem_enrolled': curricularUnits1stSemEnrolled,
      'curricular_units_1st_sem_evaluations': curricularUnits1stSemEvaluations,
      'curricular_units_1st_sem_approved': curricularUnits1stSemApproved,
    };
  }

  // Get dropout prediction
  static Future<DropoutPrediction> predictDropout(Map<String, dynamic> studentData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/predict'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(studentData),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return DropoutPrediction.fromJson(data);
      } else {
        throw Exception('Failed to get prediction: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error connecting to prediction service: $e');
    }
  }

  // Check API health
  static Future<bool> checkApiHealth() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/health'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Get model information
  static Future<Map<String, dynamic>> getModelInfo() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/model-info'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get model info: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting model info: $e');
    }
  }
}

// Dropout prediction result model
class DropoutPrediction {
  final int prediction;
  final String predictionLabel;
  final double confidence;
  final String riskLevel;

  DropoutPrediction({
    required this.prediction,
    required this.predictionLabel,
    required this.confidence,
    required this.riskLevel,
  });

  factory DropoutPrediction.fromJson(Map<String, dynamic> json) {
    return DropoutPrediction(
      prediction: json['prediction'],
      predictionLabel: json['prediction_label'],
      confidence: json['confidence'].toDouble(),
      riskLevel: json['risk_level'],
    );
  }

  bool get isDropout => prediction == 0;
  bool get isNotDropout => prediction == 1;
  
  String get riskColor {
    switch (riskLevel) {
      case 'High Risk':
        return '#FF4444';
      case 'Medium Risk':
        return '#FF8800';
      case 'Low Risk':
        return '#00C851';
      case 'Some Risk':
        return '#FFBB33';
      default:
        return '#666666';
    }
  }
}

// Predefined options for form fields
class DropoutPredictionOptions {
  static const List<Map<String, dynamic>> maritalStatus = [
    {'value': 1, 'label': 'Single'},
    {'value': 2, 'label': 'Married'},
    {'value': 3, 'label': 'Widower'},
    {'value': 4, 'label': 'Divorced'},
    {'value': 5, 'label': 'Facto Union'},
    {'value': 6, 'label': 'Legally Separated'},
  ];

  static const List<Map<String, dynamic>> nationality = [
    {'value': 1, 'label': 'Portuguese'},
    {'value': 2, 'label': 'German'},
    {'value': 6, 'label': 'Spanish'},
    {'value': 11, 'label': 'Italian'},
    {'value': 13, 'label': 'Dutch'},
    {'value': 14, 'label': 'English'},
    {'value': 17, 'label': 'Lithuanian'},
    {'value': 21, 'label': 'Angolan'},
    {'value': 22, 'label': 'Cape Verdean'},
    {'value': 24, 'label': 'Guinean'},
    {'value': 25, 'label': 'Mozambican'},
    {'value': 26, 'label': 'Santomean'},
    {'value': 32, 'label': 'Turkish'},
    {'value': 41, 'label': 'Brazilian'},
    {'value': 62, 'label': 'Romanian'},
    {'value': 100, 'label': 'Moldova (Republic of)'},
    {'value': 101, 'label': 'Mexican'},
    {'value': 103, 'label': 'Ukrainian'},
    {'value': 105, 'label': 'Russian'},
    {'value': 108, 'label': 'Cuban'},
    {'value': 109, 'label': 'Colombian'},
  ];

  static const List<Map<String, dynamic>> gender = [
    {'value': 1, 'label': 'Male'},
    {'value': 0, 'label': 'Female'},
  ];

  static const List<Map<String, dynamic>> yesNo = [
    {'value': 1, 'label': 'Yes'},
    {'value': 0, 'label': 'No'},
  ];

  static const List<Map<String, dynamic>> courses = [
    {'value': 33, 'label': 'Biofuel Production Technologies'},
    {'value': 171, 'label': 'Animation and Multimedia Design'},
    {'value': 8014, 'label': 'Social Service (evening attendance)'},
    {'value': 9003, 'label': 'Agronomy'},
    {'value': 9070, 'label': 'Communication Design'},
    {'value': 9085, 'label': 'Veterinary Nursing'},
    {'value': 9119, 'label': 'Informatics Engineering'},
    {'value': 9130, 'label': 'Equinculture'},
    {'value': 9147, 'label': 'Management'},
    {'value': 9238, 'label': 'Social Service'},
    {'value': 9254, 'label': 'Tourism'},
    {'value': 9500, 'label': 'Nursing'},
    {'value': 9556, 'label': 'Oral Hygiene'},
    {'value': 9670, 'label': 'Advertising and Marketing Management'},
    {'value': 9773, 'label': 'Journalism and Communication'},
    {'value': 9853, 'label': 'Basic Education'},
    {'value': 9991, 'label': 'Management (evening attendance)'},
  ];

  static const List<Map<String, dynamic>> attendance = [
    {'value': 1, 'label': 'Daytime'},
    {'value': 0, 'label': 'Evening'},
  ];
}

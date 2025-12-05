import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

/// FIXED: Use your actual API key directly (or use proper environment variable setup)
String GEMINI_API_KEY = dotenv.env['GEMINI_API_KEY'] ?? "";

/// Base endpoint for Gemini API
String geminiEndpoint(String model) =>
    'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$GEMINI_API_KEY';

/// FIXED: Corrected response parsing to match actual Gemini API structure
Future<String?> callGemini(
  String model,
  String prompt, {
  int? maxOutputTokens,
  double? temperature,
}) async {
  final uri = Uri.parse(geminiEndpoint(model));

  final body = <String, dynamic>{
    'contents': [
      {
        'parts': [
          {'text': prompt},
        ],
      },
    ],
    if (maxOutputTokens != null || temperature != null)
      'generationConfig': {
        if (maxOutputTokens != null) 'maxOutputTokens': maxOutputTokens,
        if (temperature != null) 'temperature': temperature,
      },
  };

  try {
    final resp = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    print('Gemini Response Status: ${resp.statusCode}');

    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      print('Gemini HTTP error: ${resp.statusCode}');
      print('Response body: ${resp.body}');
      // Throw an exception with the error details so it can be caught and displayed
      throw Exception('Gemini API Error: ${resp.statusCode} - ${resp.body}');
    }

    final Map<String, dynamic> jsonResp = jsonDecode(resp.body);
    print('Gemini Response: $jsonResp');

    // FIXED: Correct extraction of text from Gemini's response structure
    if (jsonResp.containsKey('candidates') && jsonResp['candidates'] is List) {
      final candidates = jsonResp['candidates'] as List;
      if (candidates.isNotEmpty && candidates[0] is Map) {
        final candidate = candidates[0] as Map<String, dynamic>;

        // Navigate: candidate -> content -> parts -> text
        if (candidate.containsKey('content') && candidate['content'] is Map) {
          final content = candidate['content'] as Map<String, dynamic>;
          if (content.containsKey('parts') && content['parts'] is List) {
            final parts = content['parts'] as List;
            final textParts =
                parts
                    .where((p) => p is Map && p.containsKey('text'))
                    .map((p) => (p as Map)['text'].toString())
                    .toList();

            if (textParts.isNotEmpty) {
              return textParts.join('\n');
            }
          }
        }
      }
    }

    // Fallback
    print('Warning: Unexpected response structure');
    return null;
  } catch (e) {
    print('Error calling Gemini: $e');
    rethrow; // Rethrow to be handled by caller
  }
}

/// Parses the evaluator response
Map<String, dynamic> parseResponse(String responseText) {
  print('Parsing response: $responseText');

  final RegExp markRegex = RegExp(r"Mark:\s*(\d+)");
  final RegExp feedbackRegex = RegExp(
    r"Feedback:\s*(.+?)(?=Summary Report:|\z)",
    dotAll: true,
  );
  final RegExp summaryRegex = RegExp(r"Summary Report:\s*(.+)", dotAll: true);

  int mark = 0;
  final markMatch = markRegex.firstMatch(responseText);
  if (markMatch != null && markMatch.group(1) != null) {
    mark = int.parse(markMatch.group(1)!);
  }

  final feedback =
      feedbackRegex.firstMatch(responseText)?.group(1)?.trim() ??
      "No feedback provided.";
  final summaryReport =
      summaryRegex.firstMatch(responseText)?.group(1)?.trim() ??
      "No summary provided.";

  return {"mark": mark, "feedback": feedback, "summaryReport": summaryReport};
}

/// Evaluate student solutions using Gemini
Future<List<Map<String, dynamic>>> evaluateSolutions(
  List<Map<String, String>> solutions,
  String assignmentContent, {
  String model = 'gemini-2.0-flash-exp',
}) async {
  List<Map<String, dynamic>> results = [];

  for (var solution in solutions) {
    print('Evaluating solution for UID: ${solution["uid"]}');

    final prompt = '''
You are an experienced teacher evaluating a student's assignment. Your job is to fairly assess their submission based on the given instructions, provide constructive feedback, and offer a brief performance summary.

---

### **Assignment Details:**  
$assignmentContent  

### **Student's Submission:**  
${solution["solution"]}  

---

### **Evaluation Criteria (Score out of 10):**  
- **Accuracy (4 points):** Does the response follow the instructions precisely?  
- **Completeness (3 points):** Does it fully answer all parts of the question?  
- **Clarity (2 points):** Is the explanation well-structured and easy to understand?  
- **Originality (1 point):** Does it show independent thinking?  

---

### **Your Task:**  
1. Assign a **fair mark out of 10**, ensuring that different levels of correctness get different marks.  
2. Provide **specific feedback** on what the student did well and what can be improved.  
3. Write a **brief summary report** (2-3 sentences) highlighting strengths and areas of improvement.  

---

### **Response Format (Follow Strictly):**  
Mark: [Numeric value out of 10]  
Feedback: [Detailed but concise feedback about the student's submission]  
Summary Report: [Brief overall performance review in 2-3 sentences]  
''';

    try {
      final generated = await callGemini(
        model,
        prompt,
        maxOutputTokens: 800,
        temperature: 0.0,
      );

      if (generated != null && generated.isNotEmpty) {
        final extractedData = parseResponse(generated);
        results.add({
          "uid": solution["uid"],
          "assignmentId": solution["assignmentId"],
          "classroomId": solution["classroomId"],
          "mark": extractedData["mark"],
          "feedback": extractedData["feedback"],
          "summaryReport": extractedData["summaryReport"],
          'submissionId': solution['submissionId'],
        });
        print('Evaluation successful: Mark ${extractedData["mark"]}/10');
      } else {
        throw Exception("Empty response from Gemini");
      }
    } catch (e) {
      print('Evaluation failed for UID: ${solution["uid"]} - $e');
      // In case of failure, include the error message in feedback
      results.add({
        "uid": solution["uid"],
        "assignmentId": solution["assignmentId"],
        "classroomId": solution["classroomId"],
        "mark": 0,
        "feedback": "Evaluation failed: $e",
        "summaryReport": "No summary available due to error.",
        'submissionId': solution['submissionId'],
      });
    }
  }

  return results;
}

/// Generate student report using Gemini
Future<void> generateStudentReport(
  String classroomId,
  String uid, {
  String model = 'gemini-2.0-flash-exp',
}) async {
  var snap =
      await FirebaseFirestore.instance
          .collection('evaluations')
          .where('classroomId', isEqualTo: classroomId)
          .where('uid', isEqualTo: uid)
          .get();

  if (snap.docs.isEmpty) {
    print("No evaluations found for this student.");
    return;
  }

  int totalMarks = 0;
  int numEvaluations = snap.docs.length;
  String summary = "";

  for (var doc in snap.docs) {
    totalMarks += (doc.data()["mark"] ?? 0) as int;
    summary +=
        "${doc.data()["summary"] ?? doc.data()["summaryReport"] ?? ''}\n";
  }

  double percentage = (totalMarks / (numEvaluations * 10)) * 100;
  String grade = getGrade(percentage);
  String result = percentage >= 40 ? "Pass" : "Fail";

  final prompt = '''
You are an AI assistant generating a detailed student performance report based on the given data.

---
### **Student Performance Summary:**
$summary

---
### **Your Task:**
Generate a structured report containing:
- **Total Marks:** $totalMarks
- **Percentage:** ${percentage.toStringAsFixed(2)}%
- **Grade:** $grade
- **Result:** $result
- **Remark:** A brief remark based on the student's overall performance.

---
### **Response Format (Strictly Follow This):**
Total Marks: [Total marks]
Percentage: [Percentage %]
Grade: [Grade]
Result: [Pass/Fail]
Remark: [Brief remark on student's performance]
''';

  try {
    final generated = await callGemini(
      model,
      prompt,
      maxOutputTokens: 300,
      temperature: 0.0,
    );

    if (generated != null && generated.isNotEmpty) {
      final extracted = parseResponse1(generated);
      var uidd = Uuid().v1();
      await FirebaseFirestore.instance.collection('summaryReport').doc(uidd).set({
        "uid": uid,
        "classroomId": classroomId,
        "totalMarks": extracted["totalMarks"],
        "percentage": extracted["percentage"],
        "grade": extracted["grade"],
        "result": extracted["result"],
        "remark": extracted["remark"],
      });
      print('Summary report generated successfully');
    } else {
      print("Gemini returned no response for summary generation.");
    }
  } catch (e) {
    print("Error generating student report: $e");
    // Optionally save an error state to Firestore if needed, or just log it for now
  }
}

String getGrade(double percentage) {
  if (percentage >= 90) return "A+";
  if (percentage >= 80) return "A";
  if (percentage >= 70) return "B";
  if (percentage >= 60) return "C";
  if (percentage >= 50) return "D";
  return "F";
}

Map<String, dynamic> parseResponse1(String responseText) {
  final totalMarksRegex = RegExp(r"Total Marks:\s*(\d+)");
  final percentageRegex = RegExp(r"Percentage:\s*([\d.]+)%?");
  final gradeRegex = RegExp(r"Grade:\s*(\w+)");
  final resultRegex = RegExp(r"Result:\s*(\w+)");
  final remarkRegex = RegExp(r"Remark:\s*(.+)", dotAll: true);

  return {
    "totalMarks": int.parse(
      totalMarksRegex.firstMatch(responseText)?.group(1) ?? "0",
    ),
    "percentage": double.parse(
      percentageRegex.firstMatch(responseText)?.group(1) ?? "0.0",
    ),
    "grade": gradeRegex.firstMatch(responseText)?.group(1) ?? "N/A",
    "result": resultRegex.firstMatch(responseText)?.group(1) ?? "N/A",
    "remark":
        remarkRegex.firstMatch(responseText)?.group(1)?.trim() ??
        "No remark provided.",
  };
}

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

/// Place your API key somewhere secure. Don't commit this in source control.
/// For quick testing you can hardcode, but for production call Gemini from a server.
const String GEMINI_API_KEY = String.fromEnvironment('AIzaSyDeXAFQO1eLRUe9dCewgmVnq5gpZRChomc', defaultValue: '');

/// Base endpoint - choose v1beta or v1beta2 depending on docs; adjust if needed.
/// Example endpoint format:
/// https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent
String geminiEndpoint(String model) =>
    'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$GEMINI_API_KEY';

/// Sends the prompt to Gemini and returns the generated text (raw).
/// Tries multiple common paths in the response JSON so it's robust.
Future<String?> callGemini(String model, String prompt,
    {int? maxOutputTokens, double? temperature}) async {
  final uri = Uri.parse(geminiEndpoint(model));

  final body = <String, dynamic>{
    'contents': [
      {
        'parts': [
          {'text': prompt}
        ]
      }
    ],
    if (maxOutputTokens != null || temperature != null)
      'generation_config': {
        if (maxOutputTokens != null) 'max_output_tokens': maxOutputTokens,
        if (temperature != null) 'temperature': temperature,
      },
  };

  final resp = await http.post(
    uri,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(body),
  );

  if (resp.statusCode < 200 || resp.statusCode >= 300) {
    print('Gemini HTTP error: ${resp.statusCode} ${resp.body}');
    return null;
  }

  final Map<String, dynamic> jsonResp = jsonDecode(resp.body);

  // Helper to extract text from likely shapes:
  String? extractFromCandidate(Map<String, dynamic> cand) {
    // Some responses have cand['content'] -> list of { 'text': '...' }
    if (cand.containsKey('content') && cand['content'] is List) {
      final parts = cand['content'] as List;
      return parts.map((p) {
        if (p is Map && p.containsKey('text')) return p['text'].toString();
        return p.toString();
      }).join();
    }
    // Some samples show cand['output'] or cand['text']
    if (cand.containsKey('output')) return cand['output']?.toString();
    if (cand.containsKey('text')) return cand['text']?.toString();
    // fallback: stringify candidate
    return cand.toString();
  }

  // 1) Typical top-level: candidates array
  if (jsonResp.containsKey('candidates') && jsonResp['candidates'] is List) {
    final candidates = jsonResp['candidates'] as List;
    if (candidates.isNotEmpty && candidates[0] is Map) {
      return extractFromCandidate(candidates[0] as Map<String, dynamic>);
    }
  }

  // 2) Some docs return 'output' or other top-level fields:
  if (jsonResp.containsKey('output')) return jsonResp['output']?.toString();
  if (jsonResp.containsKey('text')) return jsonResp['text']?.toString();

  // 3) Fallback: entire JSON as string
  return jsonResp.toString();
}

/// Parses the evaluator response (same logic you had before)
Map<String, dynamic> parseResponse(String responseText) {
  final RegExp markRegex = RegExp(r"Mark:\s*(\d+)");
  final RegExp feedbackRegex =
      RegExp(r"Feedback:\s*(.+?)(?=Summary Report:|\z)", dotAll: true);
  final RegExp summaryRegex = RegExp(r"Summary Report:\s*(.+)", dotAll: true);

  int mark = 0;
  final markMatch = markRegex.firstMatch(responseText);
  if (markMatch != null && markMatch.group(1) != null) {
    mark = int.parse(markMatch.group(1)!);
  }

  final feedback =
      feedbackRegex.firstMatch(responseText)?.group(1)?.trim() ?? "No feedback provided.";
  final summaryReport =
      summaryRegex.firstMatch(responseText)?.group(1)?.trim() ?? "No summary provided.";

  return {"mark": mark, "feedback": feedback, "summaryReport": summaryReport};
}

/// EvaluateSolutions: migrates from VertexAI call to Gemini REST call
Future<List<Map<String, dynamic>>> evaluateSolutions(
  List<Map<String, String>> solutions,
  String assignmentContent, {
  String model = 'gemini-2.0-flash',
}) async {
  List<Map<String, dynamic>> results = [];

  for (var solution in solutions) {
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

    final generated = await callGemini(model, prompt, maxOutputTokens: 800, temperature: 0.0);

    if (generated != null) {
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
    } else {
      // In case of failure, include a safe fallback
      results.add({
        "uid": solution["uid"],
        "assignmentId": solution["assignmentId"],
        "classroomId": solution["classroomId"],
        "mark": 0,
        "feedback": "Evaluation failed (no AI response).",
        "summaryReport": "No summary available.",
        'submissionId': solution['submissionId'],
      });
    }
  }

  return results;
}

/// generateStudentReport: uses the same Gemini REST call
Future<void> generateStudentReport(String classroomId, String uid,
    {String model = 'gemini-2.0-flash'}) async {
  var snap = await FirebaseFirestore.instance
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
    summary += "${doc.data()["summary"] ?? doc.data()["summaryReport"] ?? ''}\n";
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

  final generated = await callGemini(model, prompt, maxOutputTokens: 300, temperature: 0.0);

  if (generated != null) {
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
  } else {
    print("Gemini returned no response for summary generation.");
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
  final percentageRegex = RegExp(r"Percentage:\s*([\d.]+)%");
  final gradeRegex = RegExp(r"Grade:\s*(\w+)");
  final resultRegex = RegExp(r"Result:\s*(\w+)");
  final remarkRegex = RegExp(r"Remark:\s*(.+)", dotAll: true);

  return {
    "totalMarks": int.parse(totalMarksRegex.firstMatch(responseText)?.group(1) ?? "0"),
    "percentage": double.parse(percentageRegex.firstMatch(responseText)?.group(1) ?? "0.0"),
    "grade": gradeRegex.firstMatch(responseText)?.group(1) ?? "N/A",
    "result": resultRegex.firstMatch(responseText)?.group(1) ?? "N/A",
    "remark": remarkRegex.firstMatch(responseText)?.group(1)?.trim() ?? "No remark provided.",
  };
}

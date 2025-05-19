import 'package:flutter/material.dart';
import 'package:supabase/supabase.dart';
import 'package:tasklink2/services/ai_services.dart';

class RankingService {
final SupabaseClient _supabaseClient;
final AIService _aiService;

RankingService({
required SupabaseClient supabaseClient,
required AIService aiService,
})  : _supabaseClient = supabaseClient,
_aiService = aiService;

// Get resume text for an applicant
Future<String?> getResumeText(String applicantId) async {
try {
final response = await _supabaseClient
    .from('resumes')
    .select('text')
    .eq('applicant_id', applicantId)
    .order('uploaded_date', ascending: false)
    .limit(1);

if (response != null && response.isNotEmpty) {
return response[0]['text'] as String?;
}

// Check jobseeker_profiles table as fallback
final profileResponse = await _supabaseClient
    .from('jobseeker_profiles')
    .select('cv_text')
    .eq('user_id', applicantId)
    .maybeSingle();

if (profileResponse != null && profileResponse['cv_text'] != null) {
return profileResponse['cv_text'] as String?;
}

debugPrint('No resume text found for applicant ID: $applicantId');
return null;
} catch (e) {
debugPrint('Error fetching resume text: $e');
return null;
}
}

Future<List<Map<String, dynamic>>> _getApplicationsForJob(String jobId) async {
try {
debugPrint('Getting applications for job ID: $jobId');

// Get applications without joining
final response = await _supabaseClient
    .from('applications')
    .select('*')
    .eq('job_id', int.tryParse(jobId) ?? jobId);

final applications = List<Map<String, dynamic>>.from(response);
debugPrint('Found ${applications.length} applications');

// Enrich with applicant information
List<Map<String, dynamic>> enrichedApplications = [];

for (final app in applications) {
try {
final applicantId = app['applicant_id'];
if (applicantId != null) {
// Try to get user profile
final userResponse = await _supabaseClient
    .from('users')
    .select('name, email')
    .eq('user_id', applicantId)
    .maybeSingle();

if (userResponse != null) {
app['applicant'] = {
'name': userResponse['name'],
'email': userResponse['email']
};
} else {
// Fallback profile info
app['applicant'] = {
'name': 'Applicant ${applicantId.toString().substring(0, 8)}',
'email': 'N/A'
};
}
}
} catch (e) {
debugPrint('Error fetching profile for application: $e');
app['applicant'] = {'name': 'Unknown Applicant', 'email': 'N/A'};
}

enrichedApplications.add(app);
}

return enrichedApplications;
} catch (e) {
debugPrint('Error getting applications: $e');
return [];
}
}

// Improved rank applications method with better scoring logic
Future<List<Map<String, dynamic>>> rankApplications(String jobId, String jobDescription) async {
try {
// Get application data
final applications = await _getApplicationsForJob(jobId);

if (applications.isEmpty) {
debugPrint('No applications found for job: $jobId');
return [];
}

List<Map<String, dynamic>> rankedApplications = [];

// Define enhanced skill categories with synonyms and related terms
final technicalSkillsMap = {
'programming': ['python', 'java', 'javascript', 'typescript', 'c++', 'c#', 'ruby', 'php', 'coding', 'programming', 'development', 'software'],
'web': ['html', 'css', 'javascript', 'web', 'frontend', 'react', 'angular', 'vue', 'node', 'express', 'responsive', 'spa'],
'mobile': ['flutter', 'dart', 'react native', 'swift', 'kotlin', 'android', 'ios', 'mobile', 'app development'],
'backend': ['django', 'flask', 'spring', 'node', 'express', 'backend', 'server', 'api', 'rest', 'graphql'],
'database': ['sql', 'nosql', 'mongodb', 'postgresql', 'mysql', 'oracle', 'database', 'data modeling', 'schema'],
'devops': ['git', 'docker', 'kubernetes', 'ci/cd', 'jenkins', 'github', 'gitlab', 'aws', 'azure', 'gcp', 'cloud', 'devops'],
'ai': ['machine learning', 'data science', 'ai', 'deep learning', 'neural networks', 'nlp', 'computer vision', 'tensorflow', 'pytorch']
};

final softSkillsMap = {
'communication': ['communication', 'written', 'verbal', 'presentation', 'public speaking', 'documentation'],
'teamwork': ['teamwork', 'collaboration', 'team player', 'cooperative', 'cross-functional'],
'leadership': ['leadership', 'management', 'mentoring', 'supervision', 'team lead', 'project lead'],
'problem-solving': ['problem-solving', 'analytical', 'critical thinking', 'debugging', 'troubleshooting', 'root cause analysis'],
'time-management': ['time management', 'prioritization', 'deadline', 'scheduling', 'planning', 'organization'],
'adaptability': ['adaptability', 'flexibility', 'learning', 'versatile', 'agile']
};

// Extract all skills into flat lists for easier checking
final allTechnicalSkills = technicalSkillsMap.values.expand((i) => i).toList();
final allSoftSkills = softSkillsMap.values.expand((i) => i).toList();

// Analyze job description first to determine job type and required skills
final jobCategoryCounts = <String, int>{};
int totalTechSkillsInJob = 0;

// Count occurrences of skill categories in job description
final jobDescLower = jobDescription.toLowerCase();
technicalSkillsMap.forEach((category, skills) {
int count = 0;
for (final skill in skills) {
if (jobDescLower.contains(skill)) {
count++;
totalTechSkillsInJob++;
}
}
if (count > 0) {
jobCategoryCounts[category] = count;
}
});

// Create weighted category importance based on job description
final categoryWeights = <String, double>{};
jobCategoryCounts.forEach((category, count) {
categoryWeights[category] = totalTechSkillsInJob > 0 ? count / totalTechSkillsInJob : 0;
});

debugPrint('Job category weights: $categoryWeights');

// Determine if job is more technical or soft-skills oriented
final bool isTechnicalJob = totalTechSkillsInJob > 5;
final techSkillWeight = isTechnicalJob ? 0.8 : 0.6;
final softSkillWeight = 1.0 - techSkillWeight;

debugPrint('Job type: ${isTechnicalJob ? "Technical" : "Soft-skills"} focused');
debugPrint('Tech/Soft skill weights: $techSkillWeight/$softSkillWeight');

for (final app in applications) {
try {
final applicantId = app['applicant_id'] as String?;
if (applicantId == null) continue;

// Get resume text
final resumeText = await getResumeText(applicantId) ?? '';
if (resumeText.isEmpty) {
debugPrint('No resume text available for $applicantId');
continue;
}

final resumeTextLower = resumeText.toLowerCase();

// Technical skills evaluation with category weighting
Map<String, List<String>> matchingTechSkillsByCategory = {};
Map<String, List<String>> missingTechSkillsByCategory = {};

// Calculate weighted technical score based on job requirements
double weightedTechScore = 0;
double maxPossibleTechScore = 0;

technicalSkillsMap.forEach((category, skills) {
final categoryWeight = categoryWeights[category] ?? 0;
if (categoryWeight > 0) {
maxPossibleTechScore += categoryWeight;

// Find skills in this category that match
final matchingSkills = skills.where(
(skill) => resumeTextLower.contains(skill)
).toList();

// Find important skills in this category that are missing
final missingSkills = skills.where(
(skill) => jobDescLower.contains(skill) && !resumeTextLower.contains(skill)
).toList();

// Store for later use
if (matchingSkills.isNotEmpty) {
matchingTechSkillsByCategory[category] = matchingSkills;
}

if (missingSkills.isNotEmpty) {
missingTechSkillsByCategory[category] = missingSkills;
}

// Calculate score for this category
final categoryMatchScore = matchingSkills.length / skills.length.clamp(1, double.infinity);
weightedTechScore += categoryWeight * categoryMatchScore;
}
});

// Normalize technical score
final normalizedTechScore = maxPossibleTechScore > 0
? weightedTechScore / maxPossibleTechScore
    : 0.5; // Default to 0.5 if no tech skills in job description

// Soft skills evaluation
final matchingSoftSkills = <String>[];
softSkillsMap.forEach((category, skills) {
for (final skill in skills) {
if (resumeTextLower.contains(skill)) {
matchingSoftSkills.add(skill);
break; // Only count one match per category
}
}
});

// Calculate soft skills score (0-1)
final softScore = matchingSoftSkills.length / softSkillsMap.length;

// Combined weighted score
final combinedScore = (normalizedTechScore * techSkillWeight) +
(softScore * softSkillWeight);

// Add slight grade adjustment for experience level if mentioned in resume
double experienceBonus = 0;

if (resumeTextLower.contains('senior') ||
resumeTextLower.contains('lead') ||
resumeTextLower.contains('5+ years')) {
experienceBonus = 0.05;
} else if (resumeTextLower.contains('3+ years') ||
resumeTextLower.contains('mid-level')) {
experienceBonus = 0.03;
}

// Final score with experience adjustment, clamped between 0.1 and 0.98
final finalScore = (combinedScore + experienceBonus).clamp(0.1, 0.98);

// Flatten matching/missing skills for display
final allMatchingTech = matchingTechSkillsByCategory.values.expand((i) => i).toSet().toList();
final allMissingTech = missingTechSkillsByCategory.values.expand((i) => i).toSet().toList();

// Generate decision and suggestion
String decision = "No Match";
String suggestion;

if (finalScore >= 0.80) {
decision = "Strong Match";
suggestion = "Excellent candidate with all key skills and experience required.";
} else if (finalScore >= 0.65) {
decision = "Good Match";
suggestion = "Good candidate with most key skills. ${allMissingTech.isNotEmpty ? 'Could improve by adding: ${allMissingTech.take(3).join(', ')}.' : ''}";
} else if (finalScore >= 0.50) {
decision = "Potential Match";
suggestion = "Has some relevant skills but lacks key requirements. Consider adding: ${allMissingTech.take(4).join(', ')}.";
} else {
suggestion = "Not a good match for this role. Missing critical skills: ${allMissingTech.take(5).join(', ')}.";
}

// Store detailed ranking data
rankedApplications.add({
'application': app,
'score': finalScore,
'tech_score': normalizedTechScore,
'soft_score': softScore,
'matching_skills': allMatchingTech,
'missing_skills': allMissingTech,
'matching_soft_skills': matchingSoftSkills,
'decision': decision,
'improvement_suggestions': suggestion,
'application_status': app['application_status'] ?? 'Pending',
'applicant_name': _getApplicantName(app),
});
} catch (e) {
debugPrint('Error processing application: $e');
}
}

// Sort by score in descending order
rankedApplications.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));

// Log ranking results for debugging
for (final app in rankedApplications) {
final score = app['score'] as double;
debugPrint('Ranked ${app['applicant_name']} with score: ${(score * 100).toStringAsFixed(1)}%');
}

// Store ranking results in database
try {
await _storeRankingResults(jobId, rankedApplications);
} catch (e) {
debugPrint('Error storing ranking results: $e');
}

return rankedApplications;
} catch (e) {
debugPrint('Error in rankApplications: $e');
return [];
}
}

// Helper to get applicant name
String _getApplicantName(Map<String, dynamic> application) {
try {
if (application['applicant'] != null) {
final applicant = application['applicant'] as Map<String, dynamic>;
if (applicant['name'] != null) return applicant['name'];
}

if (application['applicant_id'] != null) {
final id = application['applicant_id'].toString();
return 'Applicant ${id.substring(0, id.length > 8 ? 8 : id.length)}';
}

return 'Unknown Applicant';
} catch (e) {
return 'Unknown Applicant';
}
}

// Store ranking results
Future<void> _storeRankingResults(String jobId, List<Map<String, dynamic>> rankedApplications) async {
try {
// Delete existing ranking results
await _supabaseClient
    .from('ranking_results')
    .delete()
    .eq('job_id', jobId);

// Prepare batch insert data
final List<Map<String, dynamic>> rankingsToInsert = [];

for (var app in rankedApplications) {
final appData = app['application'] as Map<String, dynamic>;
rankingsToInsert.add({
'job_id': jobId,
'application_id': appData['application_id'],
'applicant_id': appData['applicant_id'],
'score': app['score'],
'matching_skills': app['matching_skills'],
'missing_skills': app['missing_skills'],
'decision': app['decision'],
'created_at': DateTime.now().toIso8601String(),
});
}

// Insert in batches to avoid request size limitations
const batchSize = 10;
for (int i = 0; i < rankingsToInsert.length; i += batchSize) {
final end = (i + batchSize < rankingsToInsert.length)
? i + batchSize
    : rankingsToInsert.length;

final batch = rankingsToInsert.sublist(i, end);
await _supabaseClient.from('ranking_results').insert(batch);
}

debugPrint('Successfully stored ${rankingsToInsert.length} ranking results');
} catch (e) {
debugPrint('Error storing ranking results: $e');
// Continue even if storing fails
}
}
}

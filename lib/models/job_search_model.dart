
class JobSearchFilters {
  String? query;
  String? location;
  List<String>? jobTypes;
  double? minSalary;
  double? maxSalary;
  List<String>? skills;
  bool? isRemote;

  JobSearchFilters({
    this.query,
    this.location,
    this.jobTypes,
    this.minSalary,
    this.maxSalary,
    this.skills,
    this.isRemote,
  });

  bool isEmpty() {
    return (query == null || query!.isEmpty) &&
        (location == null || location!.isEmpty) &&
        (jobTypes == null || jobTypes!.isEmpty) &&
        minSalary == null &&
        maxSalary == null &&
        (skills == null || skills!.isEmpty) &&
        isRemote == null;
  }

  Map<String, dynamic> toJson() {
    return {
      'query': query,
      'location': location,
      'job_types': jobTypes,
      'min_salary': minSalary,
      'max_salary': maxSalary,
      'skills': skills,
      'is_remote': isRemote,
    };
  }
}

// Modify the JobService class to add an advanced search method

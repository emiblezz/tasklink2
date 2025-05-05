import 'package:flutter/foundation.dart';
import 'package:postgrest/postgrest.dart';
import 'package:tasklink2/models/job_model.dart';
import 'package:tasklink2/services/supabase_service.dart';

class SearchService extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();
  List<JobModel> _searchResults = [];
  bool _isLoading = false;
  String _lastQuery = '';
  Map<String, dynamic> _lastFilters = {};

  List<JobModel> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  String get lastQuery => _lastQuery;

  Future<List<JobModel>> searchJobs({
    String query = '',
    Map<String, dynamic> filters = const {},
  }) async {
    _isLoading = true;
    _lastQuery = query;
    _lastFilters = filters;
    notifyListeners();

    try {
      // Start with base query
      PostgrestFilterBuilder request = _supabaseService.supabase
          .from('job_postings')
          .select()
          .eq('status', 'Open');

      // Apply text search
      if (query.isNotEmpty) {
        request = request.or(
            'job_title.ilike.%$query%,description.ilike.%$query%,requirements.ilike.%$query%');
      }

      // Apply job type filter
      if (filters.containsKey('jobType') && filters['jobType'] != 'All') {
        request = request.eq('job_type', filters['jobType']);
      }

      // Apply date filter
      if (filters.containsKey('datePosted') && filters['datePosted'] != 'Any time') {
        final now = DateTime.now();
        DateTime filterDate;

        switch (filters['datePosted']) {
          case 'Past 24 hours':
            filterDate = now.subtract(const Duration(days: 1));
            break;
          case 'Past week':
            filterDate = now.subtract(const Duration(days: 7));
            break;
          case 'Past month':
            filterDate = now.subtract(const Duration(days: 30));
            break;
          default:
            filterDate = now.subtract(const Duration(days: 365));
        }

        request = request.gte('date_posted', filterDate.toIso8601String());
      }

      // Only apply order AFTER all filters
      final PostgrestTransformBuilder finalRequest = request.order('date_posted', ascending: false);

      // Fetch data
      final response = await finalRequest;

      // Parse into models
      _searchResults = response.map<JobModel>((json) => JobModel.fromJson(json)).toList();

      _isLoading = false;
      notifyListeners();
      return _searchResults;
    } catch (e) {
      print('Error searching jobs: $e');
      _isLoading = false;
      _searchResults = [];
      notifyListeners();
      return [];
    }
  }

  Future<List<JobModel>> refreshSearch() async {
    return searchJobs(query: _lastQuery, filters: _lastFilters);
  }

  Future<List<String>> getJobTypes() async {
    try {
      final response = await _supabaseService.supabase
          .from('job_postings')
          .select('job_type')
          .eq('status', 'Open')
          .order('job_type');

      final Set<String> jobTypes = {'All'};
      for (final item in response) {
        if (item['job_type'] != null && item['job_type'].isNotEmpty) {
          jobTypes.add(item['job_type']);
        }
      }

      return jobTypes.toList();
    } catch (e) {
      print('Error getting job types: $e');
      return ['All'];
    }
  }

  Future<List<String>> getSuggestedSearches() async {
    try {
      final response = await _supabaseService.supabase
          .from('job_postings')
          .select('job_title')
          .eq('status', 'Open')
          .order('job_title');

      final Set<String> suggestions = {};
      for (final item in response) {
        if (item['job_title'] != null && item['job_title'].isNotEmpty) {
          suggestions.add(item['job_title']);
          final words = item['job_title'].toString().split(' ');
          for (final word in words) {
            if (word.length > 5 && !_isCommonWord(word)) {
              suggestions.add(word);
            }
          }
        }
      }

      final List<String> result = suggestions.toList();
      return result.length > 10 ? result.sublist(0, 10) : result;
    } catch (e) {
      print('Error getting suggested searches: $e');
      return [];
    }
  }

  bool _isCommonWord(String word) {
    const commonWords = {
      'position', 'required', 'opportunity', 'available', 'looking',
      'hiring', 'urgently', 'needed', 'opening', 'vacancy',
    };
    return commonWords.contains(word.toLowerCase());
  }
}

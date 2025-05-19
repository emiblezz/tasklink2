// Let's implement a search history feature to make it easier for users to reuse previous searches
// Add this to your services folder

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:tasklink2/services/job_service.dart';

import '../models/job_search_model.dart';

class SearchHistoryService extends ChangeNotifier {
  List<JobSearchFilters> _searchHistory = [];
  static const String _prefsKey = 'search_history';
  static const int _maxHistoryItems = 10;

  List<JobSearchFilters> get searchHistory => _searchHistory;

  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = prefs.getStringList(_prefsKey);

      if (history != null) {
        _searchHistory = history.map((item) {
          final Map<String, dynamic> data = jsonDecode(item);
          return _deserializeFilters(data);
        }).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading search history: $e');
    }
  }

  Future<void> addSearch(JobSearchFilters filters) async {
    try {
      // Don't add empty searches
      if (filters.isEmpty()) {
        return;
      }

      // Check if this search already exists
      final existing = _searchHistory.indexWhere((item) => _areFiltersEqual(item, filters));
      if (existing != -1) {
        // Move to top if already exists
        final item = _searchHistory.removeAt(existing);
        _searchHistory.insert(0, item);
      } else {
        // Add to beginning of list
        _searchHistory.insert(0, filters);

        // Trim list if needed
        if (_searchHistory.length > _maxHistoryItems) {
          _searchHistory = _searchHistory.sublist(0, _maxHistoryItems);
        }
      }

      await _saveHistory();
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding search to history: $e');
    }
  }

  Future<void> clearHistory() async {
    try {
      _searchHistory.clear();
      await _saveHistory();
      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing search history: $e');
    }
  }

  Future<void> removeSearch(int index) async {
    try {
      if (index >= 0 && index < _searchHistory.length) {
        _searchHistory.removeAt(index);
        await _saveHistory();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error removing search from history: $e');
    }
  }

  Future<void> _saveHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = _searchHistory.map((item) {
        return jsonEncode(_serializeFilters(item));
      }).toList();

      await prefs.setStringList(_prefsKey, history);
    } catch (e) {
      debugPrint('Error saving search history: $e');
    }
  }

  // Helper to serialize filters for storage
  Map<String, dynamic> _serializeFilters(JobSearchFilters filters) {
    return filters.toJson();
  }

  // Helper to deserialize filters from storage
  JobSearchFilters _deserializeFilters(Map<String, dynamic> data) {
    return JobSearchFilters(
      query: data['query'],
      location: data['location'],
      jobTypes: data['job_types'] != null
          ? List<String>.from(data['job_types'])
          : null,
      minSalary: data['min_salary'] != null
          ? double.parse(data['min_salary'].toString())
          : null,
      maxSalary: data['max_salary'] != null
          ? double.parse(data['max_salary'].toString())
          : null,
      skills: data['skills'] != null
          ? List<String>.from(data['skills'])
          : null,
      isRemote: data['is_remote'],
    );
  }

  // Helper to check if two filter sets are equal
  bool _areFiltersEqual(JobSearchFilters a, JobSearchFilters b) {
    return a.query == b.query &&
        a.location == b.location &&
        _areListsEqual(a.jobTypes, b.jobTypes) &&
        a.minSalary == b.minSalary &&
        a.maxSalary == b.maxSalary &&
        _areListsEqual(a.skills, b.skills) &&
        a.isRemote == b.isRemote;
  }

  // Helper to compare lists
  bool _areListsEqual(List<String>? a, List<String>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;

    for (int i = 0; i < a.length; i++) {
      if (!b.contains(a[i])) return false;
    }

    return true;
  }
}
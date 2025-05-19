// Let's create a component to display search history and recent searches
// Add this to your widgets folder

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tasklink2/services/job_service.dart';
import 'package:tasklink2/services/search_history_service.dart';

import '../models/job_search_model.dart';

class SearchHistoryWidget extends StatelessWidget {
  final Function(JobSearchFilters) onSelectSearch;

  const SearchHistoryWidget({
    Key? key,
    required this.onSelectSearch,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final searchHistoryService = Provider.of<SearchHistoryService>(context);
    final history = searchHistoryService.searchHistory;

    if (history.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.history,
                size: 64,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                'No recent searches',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Your search history will appear here',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              const Text(
                'Recent Searches',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => searchHistoryService.clearHistory(),
                child: const Text('Clear All'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: history.length,
            itemBuilder: (context, index) {
              final filters = history[index];
              return Dismissible(
                key: Key('search-history-$index'),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20.0),
                  color: Colors.red,
                  child: const Icon(
                    Icons.delete,
                    color: Colors.white,
                  ),
                ),
                onDismissed: (direction) {
                  searchHistoryService.removeSearch(index);
                },
                child: ListTile(
                  leading: const Icon(Icons.history),
                  title: Text(
                    _getSearchDisplayText(filters),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    _getSearchFiltersText(filters),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => onSelectSearch(filters),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _getSearchDisplayText(JobSearchFilters filters) {
    if (filters.query != null && filters.query!.isNotEmpty) {
      return filters.query!;
    } else if (filters.location != null && filters.location!.isNotEmpty) {
      return 'Jobs in ${filters.location}';
    } else if (filters.jobTypes != null && filters.jobTypes!.isNotEmpty) {
      return filters.jobTypes!.join(', ');
    } else if (filters.skills != null && filters.skills!.isNotEmpty) {
      return filters.skills!.join(', ');
    } else if (filters.isRemote == true) {
      return 'Remote jobs';
    } else {
      return 'Job search';
    }
  }

  String _getSearchFiltersText(JobSearchFilters filters) {
    List<String> parts = [];

    if (filters.location != null && filters.location!.isNotEmpty) {
      parts.add(filters.location!);
    }

    if (filters.jobTypes != null && filters.jobTypes!.isNotEmpty) {
      if (filters.jobTypes!.length == 1) {
        parts.add(filters.jobTypes!.first);
      } else {
        parts.add('${filters.jobTypes!.length} job types');
      }
    }

    if (filters.skills != null && filters.skills!.isNotEmpty) {
      if (filters.skills!.length == 1) {
        parts.add(filters.skills!.first);
      } else {
        parts.add('${filters.skills!.length} skills');
      }
    }

    if (filters.minSalary != null || filters.maxSalary != null) {
      parts.add('Salary filter');
    }

    if (filters.isRemote == true) {
      parts.add('Remote');
    }

    return parts.isEmpty ? 'No filters applied' : parts.join(' · ');
  }
}
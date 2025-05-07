// lib/widgets/job_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tasklink2/models/job_model.dart';

class JobCard extends StatelessWidget {
  final JobModel job;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;
  final bool isDismissible;

  const JobCard({
    Key? key,
    required this.job,
    this.onTap,
    this.onDismiss,
    this.isDismissible = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget cardContent = Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Company logo and title row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Company logo
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: job.companyLogo != null && job.companyLogo!.isNotEmpty
                        ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        job.companyLogo!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.business,
                          size: 30,
                          color: Colors.grey,
                        ),
                      ),
                    )
                        : const Icon(
                      Icons.business,
                      size: 30,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Title and company details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          job.jobTitle,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          job.companyName,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          job.location,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Salary (if available)
              if (job.salary != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Salary: ${NumberFormat.currency(symbol: '\$').format(job.salary)}',
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
              ],

              const SizedBox(height: 12),

              // Job type and deadline row
              Row(
                children: [
                  Chip(
                    label: Text(job.jobType),
                    backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    labelStyle: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.calendar_today, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'Deadline: ${DateFormat('MMM dd').format(job.deadline)}',
                    style: TextStyle(
                      color: DateTime.now().isAfter(job.deadline.subtract(const Duration(days: 3)))
                          ? Colors.red
                          : Colors.grey[600],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Short description
              Text(
                job.description.length > 100
                    ? '${job.description.substring(0, 100)}...'
                    : job.description,
                style: TextStyle(color: Colors.grey[700]),
              ),

              const SizedBox(height: 8),

              // Posted date
              if (job.datePosted != null)
                Text(
                  'Posted ${_getTimeAgo(job.datePosted!)}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    // Add company logo
    if (job.companyLogo != null && job.companyLogo!.isNotEmpty)
      Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            job.companyLogo!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.business, color: Colors.grey),
            ),
          ),
        ),
      );

// Add company name
    Text(job.companyName);

// Add salary if available
    if (job.salary != null)[
    const Icon(Icons.attach_money, size: 16),
    Text(
    NumberFormat.currency(symbol: '\$', decimalDigits: 0).format(job.salary),
    style: TextStyle(color: Colors.green.shade700),
    ),
    ];

    // If dismissible is requested, wrap the card in a Dismissible widget
    if (isDismissible && onDismiss != null) {
      return Dismissible(
        key: Key('job-${job.id}'),
        background: Container(
          color: Colors.red,
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        direction: DismissDirection.endToStart,
        confirmDismiss: (direction) async {
          return await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Remove Job'),
              content: const Text('Do you want to remove this job from your list?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Remove'),
                ),
              ],
            ),
          ) ?? false;
        },
        onDismissed: (direction) {
          onDismiss!();
        },
        child: cardContent,
      );
    }

    return cardContent;
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);

    if (difference.inDays > 7) {
      return DateFormat('MMM dd, yyyy').format(dateTime);
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'just now';
    }
  }
}
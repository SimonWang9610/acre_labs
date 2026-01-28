import 'package:flutter/material.dart';

class TimelineEventAlarmTile extends StatelessWidget {
  final String event;
  final void Function()? onDismissed;

  const TimelineEventAlarmTile({
    super.key,
    required this.event,
    this.onDismissed,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Row(
          spacing: 8,
          children: [
            CircleAvatar(
              radius: 12,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: const Icon(Icons.alarm, size: 16, color: Colors.red),
            ),
            Expanded(child: Text(event, overflow: TextOverflow.ellipsis)),
            Column(
              spacing: 12,
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () {
                    onDismissed?.call();
                    // todo: show video review dialog
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'View Clip',
                    style: TextStyle(fontSize: 10),
                  ),
                ),
              ],
            ),

            if (onDismissed != null)
              InkWell(
                onTap: onDismissed,
                child: const Icon(Icons.close, size: 14),
              ),
          ],
        ),
      ),
    );
  }
}

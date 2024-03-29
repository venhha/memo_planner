import 'package:flutter/material.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/utils/helpers.dart';

class PriorityTable extends StatelessWidget {
  const PriorityTable({super.key, required this.callBack, required this.priority});

  final ValueChanged<int?> callBack;
  final int? priority;

  @override
  Widget build(BuildContext context) {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(0.2),
        1: FlexColumnWidth(1),
        2: FlexColumnWidth(1),
      },
      border: TableBorder.all(color: Colors.grey),
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        const TableRow(
          children: [
            SizedBox.shrink(),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Center(child: Text('Urgent')),
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Center(child: Text('Not Urgent')),
            ),
          ],
        ),
        // Important Line
        TableRow(
          children: [
            RotatedBox(
              quarterTurns: 3,
              child: Container(
                padding: const EdgeInsets.all(8.0),
                alignment: Alignment.center,
                child: const Text('Important'),
              ),
            ),
            // Important & Urgent
            ChoiceChip(
              label: Text(AppConstant.getPriorityLabel(3)),
              selected: priority == 3,
              selectedColor: AppColors.getColorByPriority(3, isDark(context)),
              onSelected: (value) {
                if (value) {
                  callBack(3);
                } else {
                  callBack(null);
                }
              },
            ),
            // Important & Not Urgent
            ChoiceChip(
              label: Text(AppConstant.getPriorityLabel(2)),
              selected: priority == 2,
              selectedColor: AppColors.getColorByPriority(2, isDark(context)),
              onSelected: (value) {
                if (value) {
                  callBack(2);
                } else {
                  callBack(null);
                }
              },
            ),
          ],
        ),
        // Not Important Line
        TableRow(
          children: [
            RotatedBox(
              quarterTurns: 3,
              child: Container(
                padding: const EdgeInsets.all(8.0),
                alignment: Alignment.center,
                child: const Text('Not Important'),
              ),
            ),
            // Not Important & Urgent
            ChoiceChip(
              label: Text(AppConstant.getPriorityLabel(1)),
              selected: priority == 1,
              selectedColor: AppColors.getColorByPriority(1, isDark(context)),
              onSelected: (value) {
                if (value) {
                  callBack(1);
                } else {
                  callBack(null);
                }
              },
            ),
            // Not Important & Not Urgent
            ChoiceChip(
              label: Text(AppConstant.getPriorityLabel(0)),
              selected: priority == 0,
              selectedColor: AppColors.getColorByPriority(0, isDark(context)),
              onSelected: (value) {
                if (value) {
                  callBack(0);
                } else {
                  callBack(null);
                }
              },
            ),
          ],
        ),
      ],
    );
  }
}

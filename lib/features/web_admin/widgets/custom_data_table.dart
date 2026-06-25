import 'package:flutter/material.dart';
import 'package:baidoxe/core/theme.dart';

class CustomDataTable extends StatelessWidget {
  final List<String> columns;
  final List<List<Widget>> rows;

  const CustomDataTable({
    Key? key,
    required this.columns,
    required this.rows,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: MaterialStateProperty.all(AppTheme.primaryWhite),
            dataRowHeight: 65,
            headingTextStyle: const TextStyle(
              color: AppTheme.textDark,
              fontWeight: FontWeight.bold,
            ),
            columns: columns
                .map((col) => DataColumn(label: Text(col)))
                .toList(),
            rows: rows
                .map((row) => DataRow(
                      cells: row.map((cell) => DataCell(cell)).toList(),
                    ))
                .toList(),
          ),
        ),
      ),
    );
  }
}

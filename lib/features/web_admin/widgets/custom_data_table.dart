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
      height: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: DataTable(
                    headingRowColor: MaterialStateProperty.all(AppTheme.primaryWhite),
                    dataRowHeight: 75,
                    headingTextStyle: const TextStyle(
                      color: AppTheme.textDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    columnSpacing: 24,
                    horizontalMargin: 24,
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
          },
        ),
      ),
    );
  }
}

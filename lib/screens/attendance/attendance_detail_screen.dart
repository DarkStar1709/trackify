import 'package:f_star/controllers/attendance_list_controller.dart';
import 'package:f_star/models/attendance_model.dart';
import 'package:f_star/models/log_model.dart';
import 'package:f_star/screens/attendance/attendance_calendar_screen.dart';
import 'package:flutter/material.dart';
import 'package:pie_chart/pie_chart.dart';
import 'package:get/get.dart';
import '../../controllers/attendance_controller.dart';

class AttendanceDetailScreen extends StatefulWidget {
  final AttendanceModel attendanceModel;

  const AttendanceDetailScreen({
    super.key,
    required this.attendanceModel,
  });

  @override
  State<AttendanceDetailScreen> createState() => _AttendanceDetailScreenState();
}

class _AttendanceDetailScreenState extends State<AttendanceDetailScreen> {
  final attendanceController = Get.put(AttendanceController());
  final RxBool isSelectionMode = false.obs;
  final RxSet<String> selectedLogs = <String>{}.obs;

  @override
  void initState() {
    super.initState();
    attendanceController.initAttendance(widget.attendanceModel);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.attendanceModel.subject),
        actions: [
          Obx(() => isSelectionMode.value
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: () => selectedLogs.clear(),
                      child: const Text('Clear',
                          style: TextStyle(color: Colors.white)),
                    ),
                    TextButton(
                      onPressed: _deleteSelectedLogs,
                      child: const Text('Delete',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ],
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.calendar_month),
                      onPressed: () => Get.to(() => AttendanceCalendarScreen(
                          controller: attendanceController)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _showDeleteConfirmation(context),
                    ),
                  ],
                )),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Obx(() {
          final attendance = attendanceController.attendance.value;
          if (attendance == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final dataMap = {
            "Present": attendance.presentClasses.toDouble(),
            "Absent": attendance.absentClasses.toDouble(),
            "Leaves": attendance.leaveClasses.toDouble(),
          };

          final colorMap = <String, Color>{
            "Present": Colors.green,
            "Absent": Colors.red,
            "Leaves": Colors.yellow,
          };

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Subject Details',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const Divider(),
                        Text('Subject Name: ${attendance.subject}'),
                        Text(
                            'Required Attendance: ${attendance.requiredPercentage}%'),
                        Text(
                            'Current Attendance: ${attendance.attendancePercentage.toStringAsFixed(1)}%'),
                        if (!attendance.isPassing)
                          Text(
                            'Classes needed to pass: ${attendance.classesNeededToPass()}',
                            style: TextStyle(
                              color: Colors.red[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Attendance Statistics',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const Divider(),
                        _buildStatRow('Total Classes', attendance.totalClasses),
                        _buildStatRow(
                            'Present', attendance.presentClasses, Colors.green),
                        _buildStatRow(
                            'Absent', attendance.absentClasses, Colors.red),
                        _buildStatRow(
                            'Leaves', attendance.leaveClasses, Colors.yellow),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 300,
                  child: PieChart(
                    dataMap: dataMap,
                    colorList: colorMap.values.toList(),
                    chartType: ChartType.ring,
                    ringStrokeWidth: 32,
                    chartValuesOptions: const ChartValuesOptions(
                      showChartValuesInPercentage: true,
                    ),
                    legendOptions: const LegendOptions(
                      showLegendsInRow: true,
                      legendPosition: LegendPosition.bottom,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _btn(
                  onTap: () async {
                    final result = await _showReasonDialog(context, 'Present');
                    if (result != null) {
                      final parts = result.split('|');
                      final date = DateTime.parse(parts[0]);
                      attendanceController.markAttendance(
                        AttendanceType.present,
                        '',
                        date,
                      );
                    }
                  },
                  color: Colors.green,
                  text: "Mark Present",
                ),
                const SizedBox(
                  height: 8,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: _btn(
                        onTap: () async {
                          final reason =
                              await _showReasonDialog(context, 'Absent');
                          if (reason != null) {
                            final parts = reason.split('|');
                            final date = DateTime.parse(parts[0]);
                            final reasonText = parts[1];
                            attendanceController.markAttendance(
                              AttendanceType.absent,
                              reasonText,
                              date,
                            );
                          }
                        },
                        color: Colors.red,
                        text: "Mark Absent",
                      ),
                    ),
                    const SizedBox(
                      width: 4,
                    ),
                    Expanded(
                      child: _btn(
                        onTap: () async {
                          final reason =
                              await _showReasonDialog(context, 'Leave');
                          if (reason != null) {
                            final parts = reason.split('|');
                            final date = DateTime.parse(parts[0]);
                            final reasonText = parts[1];
                            attendanceController.markAttendance(
                              AttendanceType.leave,
                              reasonText,
                              date,
                            );
                          }
                        },
                        color: const Color.fromARGB(255, 62, 59, 17),
                        text: "Mark Leave",
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Attendance History',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Divider(),
                SizedBox(
                  height: 200,
                  child: Obx(
                    () => ListView.builder(
                      itemCount: attendanceController.history.length,
                      itemBuilder: (context, index) {
                        final log = attendanceController.history[index];
                        final isSelected = selectedLogs.contains(log.id);
                        return ListTile(
                          leading: isSelectionMode.value
                              ? Checkbox(
                                  value: isSelected,
                                  onChanged: (bool? value) {
                                    if (value == true) {
                                      selectedLogs.add(log.id);
                                    } else {
                                      selectedLogs.remove(log.id);
                                    }
                                    setState(() {});
                                  },
                                )
                              : Icon(
                                  log.type == AttendanceType.present
                                      ? Icons.check_circle
                                      : log.type == AttendanceType.absent
                                          ? Icons.cancel
                                          : Icons.calendar_today,
                                  color: log.type == AttendanceType.present
                                      ? Colors.green
                                      : log.type == AttendanceType.absent
                                          ? Colors.red
                                          : Colors.yellow,
                                ),
                          title: Text(log.reason ?? "No Reasons"),
                          subtitle: Text(log.getType()),
                          trailing: Text(log.date.toString().substring(0, 10)),
                          onLongPress: () {
                            if (!isSelectionMode.value) {
                              isSelectionMode.value = true;
                              selectedLogs.add(log.id);
                            }
                            setState(() {});
                          },
                          onTap: () {
                            if (isSelectionMode.value) {
                              if (isSelected) {
                                selectedLogs.remove(log.id);
                                if (selectedLogs.isEmpty) {
                                  isSelectionMode.value = false;
                                }
                              } else {
                                selectedLogs.add(log.id);
                              }
                            }
                          },
                          selected: isSelected,
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _btn(
      {required Function()? onTap,
      required Color color,
      required String text}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        width: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, int value, [Color? color]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Row(
            children: [
              Text(
                value.toString(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              if (label != 'Total Classes') // Don't show edit for total
                IconButton(
                  icon: const Icon(Icons.edit, size: 16),
                  onPressed: () => _showEditDialog(context, label, value),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showEditDialog(
      BuildContext context, String type, int currentValue) async {
    final controller = TextEditingController(text: currentValue.toString());

    return Get.dialog(
      AlertDialog(
        title: Text('Edit $type'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: type,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final newValue = int.tryParse(controller.text);
              if (newValue != null && newValue >= 0) {
                final attendance = attendanceController.attendance.value!;

                int present = attendance.presentClasses;
                int absent = attendance.absentClasses;
                int leaves = attendance.leaveClasses;

                switch (type) {
                  case 'Present':
                    present = newValue;
                    break;
                  case 'Absent':
                    absent = newValue;
                    break;
                  case 'Leaves':
                    leaves = newValue;
                    break;
                }

                attendanceController.updateAttendanceCounts(
                  present: present,
                  absent: absent,
                  leaves: leaves,
                );
                Get.back();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<String?> _showReasonDialog(BuildContext context, String type) async {
    TextEditingController reasonController = TextEditingController();
    final selectedDate = DateTime.now().obs;

    return Get.dialog<String>(
      AlertDialog(
        title: Text('Mark $type'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Obx(() => ListTile(
                  title: const Text('Date'),
                  subtitle: Text(
                    '${selectedDate.value.day}/${selectedDate.value.month}/${selectedDate.value.year}',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate.value,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      selectedDate.value = picked;
                    }
                  },
                )),
            const Divider(),
            const SizedBox(height: 4),
            TextField(
              controller: reasonController,
              maxLength: 80,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Enter reason (optional)',
                counterText: '${reasonController.text.length}/80',
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(
              result:
                  '${selectedDate.value.toIso8601String()}|${reasonController.text}',
            ),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete Subject'),
        content: Text(
            'Are you sure you want to delete ${widget.attendanceModel.subject}?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final listController = Get.find<AttendanceListController>();
              listController.deleteSubject(widget.attendanceModel.subject);
              Get.back();
              Get.back(); // Return to home screen
              Get.snackbar(
                'Success',
                'Subject deleted successfully',
                backgroundColor: Colors.red,
                colorText: Colors.white,
                dismissDirection: DismissDirection.horizontal,
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _deleteSelectedLogs() {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete Logs'),
        content: Text(
            'Are you sure you want to delete ${selectedLogs.length} logs?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              attendanceController.deleteLogs(selectedLogs.toList());
              selectedLogs.clear();
              isSelectionMode.value = false;
              Get.back();
              Get.snackbar(
                'Success',
                'Logs deleted successfully',
                backgroundColor: Colors.red,
                colorText: Colors.white,
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

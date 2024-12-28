import 'package:f_star/controllers/log_controller.dart';
import 'package:f_star/screens/attendance/attendance_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/attendance_list_controller.dart';
import '../../components/attendance_card.dart';
import '../../models/attendance_model.dart';
import '../subject/add_subject_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final attendanceListController = Get.put(AttendanceListController());
    Get.put(LogController());
    final isSelectionMode = false.obs;
    final selectedSubjects = <String>{}.obs;

    return Scaffold(
      appBar: AppBar(
        title: const Text('F* Attendance Tracker'),
        actions: [
          Obx(() => isSelectionMode.value
              ? Row(
                  children: [
                    Text('${selectedSubjects.length} selected'),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        isSelectionMode.value = false;
                        selectedSubjects.clear();
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _showDeleteConfirmation(
                        context,
                        attendanceListController,
                        selectedSubjects,
                        isSelectionMode,
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.select_all),
                      onPressed: () => isSelectionMode.value = true,
                    ),
                    IconButton(
                      icon: const Icon(Icons.settings),
                      onPressed: () {
                        // TODO: Navigate to settings screen
                      },
                    ),
                  ],
                )),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: attendanceListController.updateSearchQuery,
              decoration: InputDecoration(
                hintText: 'Search subjects...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Obx(() {
                    final overallAttendance = _calculateOverallAttendance(
                        attendanceListController.attendanceList);

                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.blue.shade400,
                                Colors.green.shade400,
                              ],
                            ),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'Overall Attendance',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  _buildStatistic(
                                    'Average',
                                    '${overallAttendance.toStringAsFixed(1)}%',
                                    Icons.timeline,
                                  ),
                                  _buildStatistic(
                                    'Subjects',
                                    attendanceListController
                                        .attendanceList.length
                                        .toString(),
                                    Icons.book,
                                  ),
                                  _buildStatistic(
                                    'Status',
                                    overallAttendance >= 75
                                        ? 'Good'
                                        : 'At Risk',
                                    overallAttendance >= 75
                                        ? Icons.thumb_up
                                        : Icons.warning,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(16.0),
                  sliver: Obx(() => SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final subject = attendanceListController
                                .filteredAttendanceList[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Obx(() => InkWell(
                                    onLongPress: () {
                                      if (!isSelectionMode.value) {
                                        isSelectionMode.value = true;
                                        selectedSubjects.add(subject.uid!);
                                      }
                                    },
                                    onTap: () {
                                      if (isSelectionMode.value) {
                                        if (selectedSubjects
                                            .contains(subject.uid)) {
                                          selectedSubjects.remove(subject.uid);
                                          if (selectedSubjects.isEmpty) {
                                            isSelectionMode.value = false;
                                          }
                                        } else {
                                          selectedSubjects.add(subject.uid!);
                                        }
                                      } else {
                                        Get.to(
                                          () => AttendanceDetailScreen(
                                            attendanceModel: subject,
                                          ),
                                        );
                                      }
                                    },
                                    child: Stack(
                                      children: [
                                        AttendanceCard(attendance: subject),
                                        if (isSelectionMode.value)
                                          Positioned(
                                            right: 8,
                                            top: 8,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: Colors.grey,
                                                ),
                                              ),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(2.0),
                                                child: Icon(
                                                  selectedSubjects
                                                          .contains(subject.uid)
                                                      ? Icons.check_circle
                                                      : Icons.circle_outlined,
                                                  color: Colors.blue,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  )),
                            );
                          },
                          childCount: attendanceListController
                              .filteredAttendanceList.length,
                        ),
                      )),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.to(() => AddSubjectScreen()),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    AttendanceListController controller,
    Set<String> selectedSubjects,
    RxBool isSelectionMode,
  ) {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete Subjects'),
        content: Text(
            'Are you sure you want to delete ${selectedSubjects.length} subjects?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              for (var uid in selectedSubjects) {
                controller.deleteSubject(uid);
              }
              isSelectionMode.value = false;
              selectedSubjects.clear();
              Get.back();
              Get.snackbar(
                'Success',
                'Subjects deleted successfully',
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

  Widget _buildStatistic(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 30),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  double _calculateOverallAttendance(List<AttendanceModel> attendanceList) {
    if (attendanceList.isEmpty) return 0;

    double totalPercentage = attendanceList.fold(
      0,
      (sum, attendance) => sum + attendance.attendancePercentage,
    );

    return totalPercentage / attendanceList.length;
  }
}

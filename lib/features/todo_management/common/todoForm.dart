import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_realtime_workspace/features/todo_management/model/todo_model.dart';
import 'package:flutter_realtime_workspace/features/todo_management/provider/date_time_provider.dart';
import 'package:flutter_realtime_workspace/features/todo_management/provider/service_provider.dart';
import 'package:intl/intl.dart';
import '../constants/appStyle.dart';
import '../provider/radioProvider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/date_time_widget.dart';
import '../widgets/radio_widget.dart';
import '../widgets/text_field_widget.dart';

class AddNewTask extends ConsumerWidget {
    AddNewTask({
    super.key,
  });

  final titleController = TextEditingController();
  final descriptionController = TextEditingController();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateProv = ref.watch(dateProvider);
    return Container(
      padding: const EdgeInsets.all(30),
      height: MediaQuery.of(context).size.height*0.78,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child:  Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(
            width: double.infinity,
            child: Text(
                "New Task Todo",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          Divider(
            thickness: 1.2,
            color: Colors.grey.shade200,
          ),
          const SizedBox(height: 12,),
          const Text(
              "Title Task",
            style: AppStyle.headingOne,
          ),
          const SizedBox(height: 6,),
           TextFieldWidget(
              hintText: "Add Task Name",
              maxLine: 1,
             txtController: titleController,
          ),
          const SizedBox(height: 12,),
          const Text(
            "Description",
            style: AppStyle.headingOne,
          ),
          const SizedBox(height: 6,),
          TextFieldWidget(
            hintText: "Add Description",
            maxLine: 4,
            txtController: descriptionController,
          ),
          const SizedBox(height: 12,),

          const Text(
            "Category",
            style: AppStyle.headingOne,
          ),
          Row(
            children: [
              Expanded(
                  child: RadioWidget(
                    categColor: Colors.green,
                    titleRadio: "LNR",
                    valueInput: 1,
                    onChangedValue: () => ref.read(radioProvider.notifier).update
                      ((state) => 1),
                  ),
              ),

              Expanded(
                child: RadioWidget(
                  categColor: Colors.blue.shade700,
                  titleRadio: "WRK",
                  valueInput: 2,
                  onChangedValue: () => ref.read(radioProvider.notifier).update
                    ((state) => 2),
                ),
              ),

              Expanded(
                child: RadioWidget(
                  categColor: Colors.amberAccent.shade700,
                  titleRadio: "GEN",
                  valueInput: 3,
                  onChangedValue: () => ref.read(radioProvider.notifier).update
                    ((state) => 3),
                ),
              ),
            ],
          ),

          // Date and Time Section

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              DateTimeWidget(
                  titleText: "Date",
                  valueText: dateProv,
                  iconSection: CupertinoIcons.calendar,
                  onTap:() async{
                    final getValue = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2021),
                    lastDate: DateTime(2029)
                  );
                    if (getValue != null) {
                      final format = DateFormat.yMd();
                      ref.read(dateProvider.notifier)
                      .update((state) => format.format(getValue));
                    }
                  },
              ),
              const SizedBox(width: 22,),
              DateTimeWidget(
                titleText: "Time",
                  valueText: ref.watch(timeProvider),
                  iconSection: CupertinoIcons.clock,
                  onTap: () async {
                    final getTime = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                  );

                    if (getTime != null) {
                      ref.read(timeProvider.notifier)
                          .update((state) => getTime.format(context));
                    }
                  },
              ),
            ],
          ),
          const SizedBox(height: 12,),
          //Button Section

          Row(
            children: [
              Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.blue.shade800,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      side: BorderSide(
                        color: Colors.blue.shade800,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancel"),
                  ) ,
              ),

              const SizedBox(width: 20,),

              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade800,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    final getRadioValue = ref.read(radioProvider);
                    String category = "";

                    switch (getRadioValue) {
                      case 1:
                        category = "Learning";
                        break;
                      case 2:
                        category = "Working";
                        break;
                      case 3:
                        category = "General";
                        break;
                    }

                    ref.read(serviceProvider).addNewTask(
                      TodoModel(
                          titleTask: titleController.text,
                          description: descriptionController.text,
                          category: category,
                          dateTask: ref.read(dateProvider),
                          timeTask: ref.read(timeProvider),
                          isDone: false,
                      ),
                    );
                    print("Data is saving");
                    
                    titleController.clear();
                    descriptionController.clear();
                    ref.read(radioProvider.notifier).update((state) => 0);
                    Navigator.pop(context);
                  },
                  child: const Text("Create"),
                ) ,
              ),
            ],
          )
        ],
      ),
    );
  }
}





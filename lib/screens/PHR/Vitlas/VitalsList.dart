import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fyp/models/Vitals.dart';
import 'package:fyp/models/VitalObservedValue.dart';
import 'package:fyp/Services/config.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../CustomWidgets/AddVitalsPopUp.dart';
import '../../../CustomWidgets/CustomAppBarIconButton.dart';
import '../../../CustomWidgets/CustomEditVitalPopup.dart';
import '../../../models/Vital.dart';
import 'package:fyp/test.dart';


class VitalsScreen extends StatefulWidget {
  @override
  _VitalsScreenState createState() => _VitalsScreenState();
}

class _VitalsScreenState extends State<VitalsScreen> {
  late List<Vital> vitals = [];
  String selectedFilter = 'All';
  DateTime? fromDate;
  DateTime? toDate;
  Map<int, bool> checkboxValues = {};
  bool outerCheckboxValue = false;
  bool _isPlusClicked = false;


  String token='';

  @override
  void initState() {
    super.initState();
    fetchData();

  }

    Future<void> fetchData() async {
    final String baseURL = Config.baseUrl;
    final prefs = await SharedPreferences.getInstance();
    final int? patientId = prefs.getInt('userId');
    token = prefs.getString('token')!;
    // Replace with your patient ID


    try {
      final response = await http.get(
        Uri.parse('$baseURL/measures/patient/$patientId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> responseData = jsonDecode(response.body)['data'];
        setState(() {
          vitals = responseData.map((data) => Vital.fromJson(data)).toList();
          checkboxValues = {for (var v in vitals) v.id: false};
        });
      } else {
        throw Exception('Failed to fetch Measures of Patient: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch Measures of Patient: $e');
    }
  }
  List<DateTime> _getDistinctDates(List<Vital> vitals) {
    Set<DateTime> datesSet = vitals.map((vital) => DateTime(vital.time.year, vital.time.month, vital.time.day)).toSet();
    List<DateTime> sortedDates = datesSet.toList()..sort((a, b) => b.compareTo(a)); // Sort dates in descending order
    return sortedDates;
  }

  List<Vital> _getVitalsByDate(DateTime date, List<Vital> vitals) {
    List<Vital> vitalsByDate = vitals.where((vital) => DateTime(vital.time.year, vital.time.month, vital.time.day) == date).toList();
    vitalsByDate.sort((a, b) => b.time.compareTo(a.time)); // Sort vitals by time in descending order
    return vitalsByDate;
  }


  List<Vital> _filterVitals() {
    List<Vital> filteredVitals = vitals;

    // Apply category filter
    if (selectedFilter != 'All') {
      filteredVitals = filteredVitals.where((vital) {
        if (selectedFilter == 'BP') {
          return vital.vitals.name == 'Blood Pressure';
        } else if (selectedFilter == 'Sugar') {
          return vital.vitals.name == 'Sugar';
        } else if (selectedFilter == 'Temp') {
          return vital.vitals.name == 'Temperature';
        }
        return true;
      }).toList();
    }

    // Apply date filter
    if (fromDate != null) {
      filteredVitals = filteredVitals.where((vital) => vital.time.isAfter(fromDate!) || vital.time.isAtSameMomentAs(fromDate!)).toList();
    }
    if (toDate != null) {
      filteredVitals = filteredVitals.where((vital) => vital.time.isBefore(toDate!) || vital.time.isAtSameMomentAs(toDate!)).toList();
    }

    return filteredVitals;
  }

  void _toggleAllCheckboxes(bool? value) {
    setState(() {
      outerCheckboxValue = value ?? false;
      checkboxValues.updateAll((key, _) => outerCheckboxValue);
    });
  }
  void _togglePlusClicked() {
    setState(() {
      _isPlusClicked = !_isPlusClicked;
    });
    if (_isPlusClicked) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            child: CustomAddVitalsPopUp(
              onClose: () {
                setState(() {
                  _isPlusClicked = false;
                });
              },
            ),
          );
        },
      ).then((_) {
        setState(() {
          _isPlusClicked = false;
        });
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    List<Vital> filteredVitals = _filterVitals();

    return Scaffold(



      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [

            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => UploadDataScreen()),
                      );
                    },
                    child: Text(
                      'Add New Vital',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  CustomAppBarIconButton(
                    isPlusClicked: _isPlusClicked,
                    onTap: _togglePlusClicked,
                    icon: _isPlusClicked ? Icons.close : Icons.add,
                  ),

                ],
              ),
            ),
          ],
        ),
      ),

    body: SingleChildScrollView(
    child: Padding(
    padding: const EdgeInsets.all(16.0),
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    SizedBox(height: 10),
    Row(
    mainAxisAlignment: MainAxisAlignment.spaceAround,
    children: [
    _buildNavButton('All'),
    _buildNavButton('BP'),
    _buildNavButton('Sugar'),
    _buildNavButton('Temp'),
    ],
    ),
    SizedBox(height: 10),
    _buildDateSelector('From', fromDate, (pickedDate) {
    setState(() {
    fromDate = pickedDate;
    });
    }),
    SizedBox(height: 10),
    _buildDateSelector('To', toDate, (pickedDate) {
    setState(() {
    toDate= pickedDate;
    });
    }),
      SizedBox(height: 20),
      _buildDataList(filteredVitals),
    ],
    ),
    ),
    ),
    );
  }

  Widget _buildNavButton(String title) {
    bool isSelected = selectedFilter == title;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedFilter = title;
        });
      },
      child: Container(
        width: 80,
        height: 40,
        decoration: BoxDecoration(
          color: isSelected ? Colors.grey : Color(0xFF199A8E),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildDateSelector(String label, DateTime? selectedDate, ValueChanged<DateTime?> onDatePicked) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          ' $label',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Stack(
          children: [
            Container(
              width: 290,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: TextField(
                  enabled: false,
                  decoration: InputDecoration(
                    hintText: selectedDate == null ? '' : '${selectedDate.month}/${selectedDate.day}/${selectedDate.year}',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 10),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: IconButton(
                icon: Icon(Icons.calendar_today),
                onPressed: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: selectedDate ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (pickedDate != null) {
                    onDatePicked(pickedDate);
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDataList(List<Vital> filteredVitals) {
    return ListView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
    itemCount: _getDistinctDates(filteredVitals).length,
    itemBuilder: (context, index) {
          final date = _getDistinctDates(filteredVitals).toList()[index];

    final vitalsByDate = _getVitalsByDate(date, filteredVitals);
    bool allChecked = vitalsByDate.every((vital) => checkboxValues[vital.id] == true);
    bool someChecked = vitalsByDate.any((vital) => checkboxValues[vital.id] == true);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          title: Text(
            DateFormat('d MMMM, yyyy').format(date),
            style: TextStyle(fontWeight: FontWeight.bold),
          ),

          trailing: Checkbox(
            value: allChecked ? true : (someChecked ? null : false),
            onChanged: (bool? newValue) {
              setState(() {
                for (var vital in vitalsByDate) {
                  checkboxValues[vital.id] = newValue ?? false;
                }
              });
            },
            checkColor: Colors.white,
            activeColor: Colors.blue,
            tristate: true,
          ),
        ),
        SizedBox(height: 10),
        _buildExpensesList(vitalsByDate),
        SizedBox(height: 10),
      ],
    );
    },
    );
  }
  Widget _buildExpensesList(List<Vital> vitalsByDate) {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: vitalsByDate.length,
      itemBuilder: (context, index) {
        final vital = vitalsByDate[index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 9.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  offset: Offset(0, 2),
                  blurRadius: 4.0,
                ),
              ],
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, left: 18.0),
                  child: Text(
                    DateFormat.jm().format(vital.time),
                    style: TextStyle(
                      fontWeight: FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                ),
                Transform.translate(
                  offset: Offset(0, 9), // Adjust the value to position ListTile over the text
                  child: ListTile(
                    contentPadding: EdgeInsets.symmetric(horizontal: 4.0),
                    leading: Checkbox(
                      value: checkboxValues[vital.id] ?? false,
                      onChanged: (bool? value) {
                        setState(() {
                          checkboxValues[vital.id] = value!;
                          bool allChecked = vitalsByDate.every((v) => checkboxValues[v.id] == true);
                          outerCheckboxValue = allChecked;
                        });
                      },
                    ),
                    title: Text(
                      vital.vitals.name,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      vital.vitalObservedValue.map((value) => '${value.readingType}: ${value.observedValue}').join(", "),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return Dialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20.0),
                                  ),
                                  elevation: 0.0,
                                  backgroundColor: Colors.transparent,
                                  child: CustomEditVitalsPopUp(
                                    onClose: () {
                                      Navigator.of(context).pop(); // Close the dialog
                                    },
                                    vitaltoedit: vital, // Pass the vital object to edit
                                  ),
                                );
                              },
                            );
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () {
                            _showDeleteConfirmationDialog(vital); // Call delete confirmation dialog
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }


  void _showDeleteConfirmationDialog(Vital vital) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Vital'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Are you sure you want to delete this vital record?'),
              SizedBox(height: 10),
              Text('Vital ID: ${vital.id}'),
              Text('Time: ${vital.time}'),
              Text('Vitals: ${vital.vitals.name}'),
              Text('Observed Values: ${vital.vitalObservedValue.map((value) => '${value.readingType}: ${value.observedValue}').join(", ")}'),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('CANCEL'),
            ),
            TextButton(
              onPressed: () {
// Call delete API and handle response
// After successful deletion, update UI accordingly
                _deleteVital(vital);
                Navigator.of(context).pop();
              },
              child: Text('DELETE'),
            ),
          ],
        );
      },
    );
  }

  void _deleteVital(Vital vital) async {
    final String baseURL = Config.baseUrl;
    final String token = 'YOUR_TOKEN_HERE'; // Replace with your authentication token
    try {
      final response = await http.delete(
        Uri.parse('$baseURL/measures/${vital.id}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          vitals.removeWhere((item) => item.id == vital.id);
          checkboxValues.remove(vital.id);
        });
      } else {
        throw Exception('Failed to delete Vital: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to delete Vital: $e');
    }
  }
}
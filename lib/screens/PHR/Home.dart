import 'package:flutter/material.dart';
import 'package:fyp/CustomWidgets/CustomBottomNavBar.dart';
import 'package:fyp/CustomWidgets/CustomAppBarIconButton.dart';
import 'package:fyp/CustomWidgets/AddVitalsPopUp.dart';
import 'package:fyp/screens/PHR/Vitlas/VitalsList.dart';
import 'package:fyp/screens/PHR/Reports/OCR.dart';
import 'package:fyp/screens/PHR/patientProfile.dart';
import 'package:fyp/Services/API/AuthAPI.dart';
import 'package:fyp/screens/splash.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../CustomWidgets/CutomReportGraph.dart';
import '../../ThemeSettings/ThemeSettings.dart';
import '../../test.dart';
import '../Login.dart';
import 'package:fyp/CustomWidgets/GraphsForVitals.dart';
import 'Reports/AllReports.dart';
import 'Vitlas/VitalGrahps.dart';

class HomeScreen extends StatefulWidget {
  final String token; // Pass the token from login
  HomeScreen({required this.token});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _isPlusClicked = false;

  PageController _pageController = PageController();
  late SharedPreferences _prefs; // Define _prefs here

  @override
  void initState() {
    super.initState();
    _initPreferences(); // Initialize _prefs
  }

  void _initPreferences() async {
    _prefs = await SharedPreferences.getInstance(); // Initialize _prefs

  }

  void _onItemSelected(int index) {
    setState(() {
      _selectedIndex = index;
      _pageController.jumpToPage(index);
    });
  }



  Future<void> _logout() async {
    // Check if _prefs is initialized
    if (_prefs != null) {
      // Clear all data from shared preferences
      await _prefs.clear();

      // Navigate to SplashScreen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => SplashScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Image.asset(
              'assets/images/logo2.png',
              width: 32,
              height: 32,
            ),
            SizedBox(width: 8),
            Text(
              'PHR',
              style: TextStyle(
                color: ThemeSettings.labelColor,
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),

            ),
            SizedBox(width: 16.0),
            IconButton(
              icon: Icon(Icons.logout),
              onPressed: _logout,
            ),

          ],
        ),
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: [
          TestListScreen(),
          VitalsScreen(),
          VitalsGraphScreen(),
          PatientProfileScreen(),
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        icons: [
          Icons.home,
          Icons.favorite,
          Icons.bar_chart,
          Icons.person,
        ],
        selectedIndex: _selectedIndex,
        onItemSelected: _onItemSelected,
      ),
    );
  }
}

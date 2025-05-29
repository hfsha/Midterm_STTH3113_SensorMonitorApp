import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import '../providers/sensor_provider.dart';
import '../models/sensor_data.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';
import '../services/api_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  Timer? _refreshTimer;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  bool _isFetchingInitialData = false;
  final TextEditingController _tempThresholdController =
      TextEditingController();
  final TextEditingController _humThresholdController = TextEditingController();
  bool _isUpdatingThreshold = false;

  // Custom colors (Matching Login/Register screens)
  final Color primaryBlue = const Color(0xFF2B6CB0);
  final Color accentBlue = const Color(0xFF4299E1);
  final Color inputFill = const Color(0xFFF7FAFF);
  final Color errorRed = const Color(0xFFE53E3E);
  final Color darkText = const Color(0xFF1A365D);
  final Color lightGrey = const Color(0xFFE0E0E0);
  final Color backgroundColor =
      const Color(0xFFE0F2F7); // Lighter background blue
  final Color successColor =
      const Color(0xFF00B894); // Define success color as class member
  final Color warningColor =
      const Color(0xFFFDCB6E); // Define warning color as class member

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    _scaleController = AnimationController(
      duration: const Duration(
          milliseconds: 300), // Slightly faster for quicker feedback
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted && !_isFetchingInitialData) {
        _isFetchingInitialData = true;
        // Fetch initial data and thresholds
        await Provider.of<SensorProvider>(context, listen: false).fetchData();
        // Assuming fetch data also gets latest thresholds, otherwise add a separate call
        // await Provider.of<SensorProvider>(context, listen: false).fetchThresholds();

        if (mounted) {
          _fadeController.forward();
          _scaleController.forward();
          _startPeriodicRefresh();
          // Populate threshold fields with current values after fetching
          final provider = Provider.of<SensorProvider>(context, listen: false);
          _tempThresholdController.text =
              provider.tempThreshold.toStringAsFixed(1);
          _humThresholdController.text =
              provider.humThreshold.toStringAsFixed(1);
        }
        _isFetchingInitialData = false;
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    if (_fadeController.isAnimating) {
      _fadeController.stop();
    }
    if (_scaleController.isAnimating) {
      _scaleController.stop();
    }
    _fadeController.dispose();
    _scaleController.dispose();
    _tempThresholdController.dispose();
    _humThresholdController.dispose();
    super.dispose();
  }

  void _startPeriodicRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        // Fetch data and thresholds periodically
        Provider.of<SensorProvider>(context, listen: false).fetchData();
        // Provider.of<SensorProvider>(context, listen: false).fetchThresholds();
      } else {
        _refreshTimer?.cancel(); // Cancel timer if widget is unmounted
      }
    });
  }

  // Custom styled container (Matching Login/Register screens)
  BoxDecoration _getContainerDecoration() {
    return BoxDecoration(
      color: Colors.white.withOpacity(0.95),
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: Colors.blueGrey.withOpacity(0.15),
          blurRadius: 25,
          offset: const Offset(0, 15),
        ),
      ],
    );
  }

  // Custom styled input decoration (Matching Login/Register screens)
  InputDecoration _getTextFieldDecoration(
      String labelText, IconData prefixIcon) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: TextStyle(color: darkText.withOpacity(0.6)),
      prefixIcon: Icon(prefixIcon, color: primaryBlue),
      filled: true,
      fillColor: inputFill,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: lightGrey, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: lightGrey, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: accentBlue, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: errorRed, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: errorRed, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
    );
  }

  void _logout() async {
    await Provider.of<AuthProvider>(context, listen: false).logout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }

  // Function to send updated thresholds to the server
  Future<void> _updateThresholds() async {
    if (_tempThresholdController.text.isEmpty ||
        _humThresholdController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both thresholds')),
      );
      return;
    }

    setState(() {
      _isUpdatingThreshold = true;
    });

    try {
      final response = await ApiService().updateThresholds(
        double.parse(_tempThresholdController.text),
        double.parse(_humThresholdController.text),
      ); // Use ApiService to update thresholds

      // Handle server response based on the structure returned by ApiService
      // Assuming ApiService returns a Map<String, dynamic> with 'status' and 'message'
      if (response['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Thresholds updated: ${response['message'] ?? 'Success'}')),
        );
        // Optionally fetch updated thresholds to refresh UI
        // await Provider.of<SensorProvider>(context, listen: false).fetchThresholds();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Failed to update thresholds: ${response['message'] ?? 'Unknown error'}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating thresholds: ${e.toString()}')),
      );
    }

    setState(() {
      _isUpdatingThreshold = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor, // Use the new background color
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFE0F2F7),
              Color(0xFFB3E5FC)
            ], // Lighter, more inviting gradient
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom Top Bar
              _buildTopBar(context), // Call a new helper method for the top bar
              Expanded(
                child: _buildDashboardContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // New helper method for the custom top bar
  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // App Title
          Text(
            'Sensor Dashboard',
            style: GoogleFonts.poppins(
              color: darkText,
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ).animate().fadeIn(duration: 600.ms, delay: 300.ms),
          // Action Icons (Logout and Filter)
          Row(
            children: [
              // Filter Button (Implement later)
              Tooltip(
                message: 'Filter Data',
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    // TODO: Implement filter functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Filter functionality coming soon!')),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8), // Adjust padding
                    decoration: _getContainerDecoration().copyWith(
                        // Use the common container style
                        borderRadius: BorderRadius.circular(
                            12), // Adjust border radius for icon button
                        boxShadow: [
                          // Lighter shadow for icon buttons
                          BoxShadow(
                            color: Colors.blueGrey.withOpacity(0.1),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ]),
                    child: Icon(
                      Icons.filter_list,
                      color: primaryBlue,
                      size: 24,
                    ),
                  ).animate().scale(
                      duration: 600.ms,
                      delay: 400.ms,
                      curve: Curves.easeOutBack),
                ),
              ),
              const SizedBox(width: 16), // Spacing between icons
              // Logout Button
              Tooltip(
                message: 'Logout',
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _logout,
                  child: Container(
                    padding: const EdgeInsets.all(8), // Adjust padding
                    decoration: _getContainerDecoration().copyWith(
                        // Use the common container style
                        borderRadius: BorderRadius.circular(
                            12), // Adjust border radius for icon button
                        boxShadow: [
                          // Lighter shadow for icon buttons
                          BoxShadow(
                            color: Colors.blueGrey.withOpacity(0.1),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ]),
                    child: Icon(
                      Icons.logout,
                      color: errorRed, // Use error color for logout
                      size: 24,
                    ),
                  ).animate().scale(
                      duration: 600.ms,
                      delay: 500.ms,
                      curve: Curves.easeOutBack),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Refactored _buildDashboardContent to use styled containers and animations
  Widget _buildDashboardContent() {
    return Consumer<SensorProvider>(
      builder: (context, sensorProvider, child) {
        if (sensorProvider.isLoading && sensorProvider.sensorData.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: CircularProgressIndicator(
                    color: accentBlue, // Use accent color
                    strokeWidth: 3,
                  ),
                ),
                const SizedBox(height: 16),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    'Loading sensor data...',
                    style: GoogleFonts.poppins(
                      color: darkText,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        if (sensorProvider.errorMessage.isNotEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Icon(
                      Icons.error_outline,
                      color: errorRed, // Use error color
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Text(
                      'Error: ${sensorProvider.errorMessage}',
                      style: GoogleFonts.poppins(
                        color: errorRed,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue, // Use primary blue
                      foregroundColor: Colors.white,
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    onPressed: () {
                      sensorProvider.clearError();
                      sensorProvider.fetchData();
                    },
                    child: Text(
                      'Retry Connection',
                      style: GoogleFonts.poppins(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final latestData = sensorProvider.sensorData.isNotEmpty
            ? sensorProvider.sensorData.last
            : null;

        return RefreshIndicator(
          onRefresh: () async {
            await sensorProvider.fetchData();
          },
          color: accentBlue, // Use accent color
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Message Card with Animation
                _buildWelcomeMessage()
                    .animate()
                    .fadeIn(duration: 600.ms, delay: 200.ms)
                    .slideY(begin: 0.2, curve: Curves.easeOutCubic),
                const SizedBox(height: 16), // Spacing
                // Status Message Card with Animation
                _buildStatusMessage(latestData, sensorProvider.tempThreshold,
                        sensorProvider.humThreshold)
                    .animate()
                    .fadeIn(duration: 600.ms, delay: 300.ms)
                    .slideY(begin: 0.2, curve: Curves.easeOutCubic),
                const SizedBox(height: 24), // Spacing
                // Current Sensor Status (Gauges) Section with Animation
                _buildCurrentSensorStatus(latestData)
                    .animate()
                    .fadeIn(duration: 600.ms, delay: 400.ms)
                    .slideY(begin: 0.2, curve: Curves.easeOutCubic),
                const SizedBox(height: 32), // Spacing
                // Relay Status Section with Animation
                if (latestData != null)
                  Center(
                      child: _buildRelayStatus(latestData.relayStatus)
                          .animate()
                          .fadeIn(duration: 600.ms, delay: 500.ms)
                          .slideY(begin: 0.2, curve: Curves.easeOutCubic)),
                const SizedBox(height: 32), // Spacing

                // Set Thresholds Section with Animation
                _buildSetThresholdsSection(sensorProvider.tempThreshold,
                        sensorProvider.humThreshold)
                    .animate()
                    .fadeIn(duration: 600.ms, delay: 600.ms)
                    .slideY(begin: 0.2, curve: Curves.easeOutCubic),
                const SizedBox(height: 32), // Spacing

                // Statistics Section (Charts) with Animation
                _buildStatisticsSection(sensorProvider)
                    .animate()
                    .fadeIn(duration: 600.ms, delay: 700.ms)
                    .slideY(begin: 0.2, curve: Curves.easeOutCubic),
                const SizedBox(height: 32), // Spacing
                // Data Table Section with Animation
                _buildDataTableSection(sensorProvider)
                    .animate()
                    .fadeIn(duration: 600.ms, delay: 800.ms)
                    .slideY(begin: 0.2, curve: Curves.easeOutCubic),
                const SizedBox(height: 24), // Spacing
              ],
            ),
          ),
        );
      },
    );
  }

  // Refactored Welcome Message Widget
  Widget _buildWelcomeMessage() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final username = authProvider.username ?? 'Guest';
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: _getContainerDecoration().copyWith(boxShadow: [
            // Use common container style
            BoxShadow(
              color: accentBlue.withOpacity(0.4), // Accent color shadow
              offset: const Offset(0, 8),
              blurRadius: 15,
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.white.withOpacity(0.7),
              offset: const Offset(-5, -5),
              blurRadius: 10,
              spreadRadius: 1,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              offset: const Offset(5, 5),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ]),
          child: Row(
            children: [
              Icon(
                Icons.waving_hand_rounded,
                color: accentBlue, // Use accent color
                size: 32,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Good morning, $username!',
                  style: GoogleFonts.poppins(
                    // Use GoogleFonts
                    color: darkText, // Use dark text color
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Refactored Status Message Widget
  Widget _buildStatusMessage(
      SensorData? data, double tempThreshold, double humThreshold) {
    String message = 'Fetching data...';
    Color messageColor = darkText.withOpacity(0.8); // Default color
    IconData messageIcon = Icons.info_outline;

    if (data != null) {
      bool tempExceeded = data.temperature > tempThreshold;
      bool humExceeded = data.humidity > humThreshold;

      if (tempExceeded && humExceeded) {
        message = 'Alert: High Temp & Humidity!';
        messageColor = errorRed; // Use error color
        messageIcon = Icons.warning_amber_rounded;
      } else if (tempExceeded) {
        message = 'Alert: High Temperature!';
        messageColor = errorRed; // Use error color
        messageIcon = Icons.warning_amber_rounded;
      } else if (humExceeded) {
        message = 'Alert: High Humidity!';
        messageColor = errorRed; // Use error color
        messageIcon = Icons.warning_amber_rounded;
      } else {
        message = 'Status: Normal';
        messageColor = successColor; // Use success color
        messageIcon = Icons.check_circle_outline;
      }
    }
    // Define successColor here or as a class member

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: _getContainerDecoration(), // Use common container style
      child: Row(
        children: [
          Icon(messageIcon, color: messageColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.poppins(
                // Use GoogleFonts
                color: messageColor,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // Refactored Current Sensor Status Widget (using styled cards)
  Widget _buildCurrentSensorStatus(SensorData? data) {
    if (data == null) {
      return Center(
        child: Text(
          'No current data available',
          style: GoogleFonts.poppins(
            color: darkText.withOpacity(0.7),
          ),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(
          child: _buildSensorStatusCard(
            title: 'Temperature',
            value: data.temperature,
            unit: '°C',
            minValue: 0,
            maxValue: 50,
            ranges: [
              GaugeRange(
                  startValue: 0,
                  endValue: 20,
                  color: accentBlue.withOpacity(0.7)), // Use accentBlue
              GaugeRange(
                  startValue: 20,
                  endValue: 30,
                  color: successColor.withOpacity(0.7)), // Use successColor
              GaugeRange(
                  startValue: 30,
                  endValue: 50,
                  color: errorRed.withOpacity(0.7)), // Use errorRed
            ],
            interval: 10,
            pointerColor: primaryBlue, // Use primaryBlue
            icon: Icons.thermostat,
          ),
        ),
        Expanded(
          child: _buildSensorStatusCard(
            title: 'Humidity',
            value: data.humidity,
            unit: '%', // Corrected unit
            minValue: 0,
            maxValue: 100,
            ranges: [
              GaugeRange(
                  startValue: 0,
                  endValue: 40,
                  color: errorRed.withOpacity(0.7)), // Use errorRed
              GaugeRange(
                  startValue: 40,
                  endValue: 70,
                  color: successColor.withOpacity(0.7)), // Use successColor
              GaugeRange(
                  startValue: 70,
                  endValue: 100,
                  color: accentBlue.withOpacity(0.7)), // Use accentBlue
            ],
            interval: 20,
            pointerColor: primaryBlue, // Use primaryBlue
            icon: Icons.water_drop,
          ),
        ),
      ],
    );
  }

  // Refactored Sensor Status Card Widget
  Widget _buildSensorStatusCard({
    required String title,
    required double value,
    required String unit,
    required double minValue,
    required double maxValue,
    required List<GaugeRange> ranges,
    required double interval,
    required Color pointerColor,
    required IconData icon,
  }) {
    // Determine text color based on threshold for current value
    Color valueTextColor = darkText; // Default to dark text
    final provider = Provider.of<SensorProvider>(context, listen: false);

    if (title.contains('Temperature')) {
      if (value > provider.tempThreshold) {
        valueTextColor = errorRed; // Use error color
      } else {
        valueTextColor = primaryBlue; // Use primaryBlue color
      }
    } else if (title.contains('Humidity')) {
      if (value > provider.humThreshold) {
        valueTextColor = errorRed; // Use error color
      } else {
        valueTextColor = primaryBlue; // Use primaryBlue color
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
      decoration: _getContainerDecoration(), // Use common container style
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  color: primaryBlue.withOpacity(0.8),
                  size: 18), // Use primaryBlue
              const SizedBox(width: 6),
              Text(
                title,
                style: GoogleFonts.poppins(
                  // Use GoogleFonts
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: darkText, // Use dark text color
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value.toStringAsFixed(1),
            style: GoogleFonts.poppins(
              // Use GoogleFonts
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: valueTextColor,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: 50,
            height: 1,
            color: darkText.withOpacity(0.3), // Use dark text color
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: SfRadialGauge(
              axes: <RadialAxis>[
                RadialAxis(
                  minimum: minValue,
                  maximum: maxValue,
                  ranges: ranges,
                  pointers: <GaugePointer>[
                    NeedlePointer(
                      value: value,
                      enableAnimation: true,
                      animationDuration: 1200,
                      knobStyle:
                          KnobStyle(color: pointerColor), // Use pointerColor
                      tailStyle:
                          const TailStyle(color: Colors.grey), // Keep grey
                      needleColor: pointerColor, // Use pointerColor
                    ),
                  ],
                  majorTickStyle: const MajorTickStyle(
                    color: Colors.grey, // Keep grey
                    length: 6,
                    thickness: 1.5,
                  ),
                  minorTickStyle: const MinorTickStyle(
                    color: Colors.grey, // Keep grey
                    length: 3,
                    thickness: 1,
                  ),
                  axisLineStyle: const AxisLineStyle(
                    thickness: 10,
                    color: Colors.black12, // Keep black12 for subtlety
                  ),
                  canScaleToFit: true,
                  interval: interval,
                  showLastLabel: true,
                  labelOffset: 15,
                  labelsPosition: ElementsPosition.outside,
                  axisLabelStyle: GaugeTextStyle(
                    fontSize: 10,
                    color: darkText.withOpacity(0.7), // Use dark text color
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Refactored Relay Status Widget
  Widget _buildRelayStatus(String status) {
    Color statusColor =
        status == 'On' ? successColor : errorRed; // Use success/error colors
    IconData statusIcon = status == 'On'
        ? Icons.power_settings_new
        : Icons.power_off; // Use power icons
    // Define successColor here or as a class member if not already done

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
      decoration: _getContainerDecoration(), // Use common container style
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, color: statusColor, size: 24), // Use statusColor
          const SizedBox(width: 12),
          Text(
            'Relay Status: ',
            style: GoogleFonts.poppins(
              // Use GoogleFonts
              color: darkText.withOpacity(0.7), // Use dark text color
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            status,
            style: GoogleFonts.poppins(
              // Use GoogleFonts
              color: statusColor, // Use statusColor
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // New widget for the Set Thresholds section
  Widget _buildSetThresholdsSection(
      double currentTempThreshold, double currentHumThreshold) {
    // Initialize controllers with current threshold values if they are not already set
    if (_tempThresholdController.text.isEmpty) {
      _tempThresholdController.text = currentTempThreshold.toStringAsFixed(1);
    }
    if (_humThresholdController.text.isEmpty) {
      _humThresholdController.text = currentHumThreshold.toStringAsFixed(1);
    }

    return Container(
      padding: const EdgeInsets.all(20), // Adjusted padding
      decoration: _getContainerDecoration(), // Use common container style
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Set Thresholds',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: darkText,
            ),
          ).animate().fadeIn(duration: 600.ms, delay: 200.ms),
          const SizedBox(height: 24), // Spacing

          // Temperature Threshold Field with animation
          TextFormField(
            controller: _tempThresholdController,
            keyboardType: TextInputType.numberWithOptions(
                decimal: true), // Allow decimals
            decoration: _getTextFieldDecoration('Temperature Threshold (°C)',
                Icons.thermostat_outlined), // Use common decoration
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter temperature threshold';
              }
              if (double.tryParse(value) == null) {
                return 'Please enter a valid number';
              }
              return null;
            },
          )
              .animate()
              .fadeIn(duration: 600.ms, delay: 300.ms)
              .slideX(begin: -0.1, curve: Curves.easeOutCubic),
          const SizedBox(height: 20), // Spacing

          // Humidity Threshold Field with animation
          TextFormField(
            controller: _humThresholdController,
            keyboardType: TextInputType.numberWithOptions(
                decimal: true), // Allow decimals
            decoration: _getTextFieldDecoration('Humidity Threshold (%)',
                Icons.cloud_outlined), // Use common decoration
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter humidity threshold';
              }
              if (double.tryParse(value) == null) {
                return 'Please enter a valid number';
              }
              return null;
            },
          )
              .animate()
              .fadeIn(duration: 600.ms, delay: 400.ms)
              .slideX(begin: 0.1, curve: Curves.easeOutCubic),
          const SizedBox(height: 30), // Spacing

          // Save Thresholds Button with animation
          _isUpdatingThreshold
              ? const Center(
                  child: CircularProgressIndicator()) // Center the loader
              : SizedBox(
                  width: double.infinity,
                  height: 60, // Match login button height
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 8,
                      shadowColor: primaryBlue.withOpacity(0.4),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    onPressed: _updateThresholds,
                    child: Text(
                      'Save Thresholds',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 600.ms, delay: 500.ms)
                      .slideY(begin: 0.5, curve: Curves.easeOutCubic)
                      .shimmer(
                          duration: 1000.ms, delay: 1100.ms), // Add shimmer
                ),
        ],
      ),
    );
  }

  // Refactored Statistics Section (Charts) - Use styled container
  Widget _buildStatisticsSection(SensorProvider sensorProvider) {
    return Container(
      padding: const EdgeInsets.all(20), // Adjusted padding
      decoration: _getContainerDecoration(), // Use common container style
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Daily Statistics',
            style: GoogleFonts.poppins(
              // Use GoogleFonts
              color: darkText, // Use dark text color
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ).animate().fadeIn(duration: 600.ms, delay: 200.ms),
          const SizedBox(height: 20), // Spacing
          SizedBox(
            height: 400, // Fixed height for charts container
            child: Column(
              children: [
                Expanded(
                    child: _buildTemperatureChart(sensorProvider.sensorData)),
                const SizedBox(height: 16), // Spacing between charts
                Expanded(child: _buildHumidityChart(sensorProvider.sensorData)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Refactored Data Table Section - Use styled container
  Widget _buildDataTableSection(SensorProvider sensorProvider) {
    return Container(
      padding: const EdgeInsets.all(20), // Adjusted padding
      decoration: _getContainerDecoration(), // Use common container style
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Recent Readings',
            textAlign: TextAlign.center, // Center align title
            style: GoogleFonts.poppins(
              // Use GoogleFonts
              color: darkText, // Use dark text color
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ).animate().fadeIn(duration: 600.ms, delay: 200.ms),
          const SizedBox(height: 20), // Spacing
          // Removed TweenAnimationBuilder here and applied animation to the container instead
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 20,
              dataRowColor: MaterialStateProperty.resolveWith<Color?>(
                (Set<MaterialState> states) {
                  if (states.contains(MaterialState.selected)) {
                    return accentBlue.withOpacity(0.08); // Use accentBlue
                  }
                  return null;
                },
              ),
              headingRowColor: MaterialStateProperty.all(
                accentBlue.withOpacity(0.12), // Use accentBlue
              ),
              headingTextStyle: GoogleFonts.poppins(
                color: accentBlue, // Use accentBlue
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              dataTextStyle: GoogleFonts.poppins(
                color: darkText, // Use dark text color
                fontSize: 13,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: accentBlue.withOpacity(0.08), // Use accentBlue
                ),
              ),
              columns: const [
                DataColumn(
                  label: Expanded(
                    child: Text(
                      'Time',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                DataColumn(
                  label: Expanded(
                    child: Text(
                      'Temp (°C)',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                DataColumn(
                  label: Expanded(
                    child: Text(
                      'Hum (%)',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                DataColumn(
                  label: Expanded(
                    child: Text(
                      'Relay',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
              rows: List<DataRow>.generate(
                sensorProvider.sensorData.reversed.take(10).length,
                (index) {
                  final reading = sensorProvider.sensorData.reversed
                      .take(10)
                      .toList()[index];
                  final provider =
                      Provider.of<SensorProvider>(context, listen: false);
                  final isEven = index % 2 == 0;
                  return DataRow(
                    color: MaterialStateProperty.all(
                      isEven
                          ? accentBlue.withOpacity(0.04) // Use accentBlue
                          : Colors.transparent,
                    ),
                    cells: [
                      DataCell(
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              _formatTime(reading.createdAt), // Keep formatting
                              style: GoogleFonts.poppins(
                                // Use GoogleFonts
                                color: darkText.withOpacity(0.8),
                              ),
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              reading.temperature.toStringAsFixed(1),
                              style: GoogleFonts.poppins(
                                // Use GoogleFonts
                                color:
                                    reading.temperature > provider.tempThreshold
                                        ? errorRed // Use errorRed
                                        : darkText, // Use darkText
                                fontWeight:
                                    reading.temperature > provider.tempThreshold
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              reading.humidity.toStringAsFixed(1),
                              style: GoogleFonts.poppins(
                                // Use GoogleFonts
                                color: reading.humidity > provider.humThreshold
                                    ? errorRed // Use errorRed
                                    : darkText, // Use darkText
                                fontWeight:
                                    reading.humidity > provider.humThreshold
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Icon(
                              reading.relayStatus == 'On'
                                  ? Icons.power_settings_new // Use power icon
                                  : Icons.power_off, // Use power icon
                              color: reading.relayStatus == 'On'
                                  ? successColor // Use successColor
                                  : darkText.withOpacity(0.7), // Use darkText
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper for time formatting (Keep existing)
  String _formatTime(DateTime time, {bool short = false}) {
    if (short) {
      return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    }
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
  }

  Widget _buildTemperatureChart(List<SensorData> data) {
    if (data.isEmpty) return const SizedBox();

    final provider = Provider.of<SensorProvider>(context, listen: false);

    return SfCartesianChart(
      title: ChartTitle(
        text: 'Temperature Trend (°C)',
        textStyle: GoogleFonts.poppins(
          color: darkText, // Use dark text color
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      primaryXAxis: CategoryAxis(
        labelRotation: 45,
        labelStyle: GoogleFonts.poppins(
          fontSize: 10,
          color: darkText.withOpacity(0.7), // Use dark text color
        ),
        majorGridLines: const MajorGridLines(width: 0),
        axisLine: const AxisLine(width: 0),
        majorTickLines: const MajorTickLines(width: 0),
      ),
      primaryYAxis: NumericAxis(
        minimum: 0,
        maximum: 50,
        interval: 10,
        labelFormat: '{value}°C',
        labelStyle: GoogleFonts.poppins(
          fontSize: 10,
          color: darkText.withOpacity(0.7), // Use dark text color
        ),
        majorGridLines: MajorGridLines(
          color: darkText.withOpacity(0.1), // Use dark text color
        ),
        axisLine: const AxisLine(width: 0),
        majorTickLines: const MajorTickLines(width: 0),
      ),
      tooltipBehavior: TooltipBehavior(
        enable: true,
        format: 'point.y°C\npoint.x',
        textStyle: GoogleFonts.poppins(color: darkText), // Use dark text color
        color: backgroundColor, // Use background color
        borderColor: darkText.withOpacity(0.1), // Use dark text color
        duration: 2000,
        builder: (data, point, series, pointIndex, seriesIndex) {
          // Ensure 'data' here is the SensorData object
          if (data is SensorData) {
            return Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: backgroundColor, // Use background color
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Text(
                '${data.temperature}°C at ${_formatTime(data.createdAt)}',
                style:
                    GoogleFonts.poppins(color: darkText), // Use dark text color
              ),
            );
          }
          return const SizedBox
              .shrink(); // Return empty widget if data is not SensorData
        },
      ),
      series: <ChartSeries>[
        SplineSeries<SensorData, String>(
          dataSource: data,
          xValueMapper: (SensorData data, _) =>
              _formatTime(data.createdAt, short: true),
          yValueMapper: (SensorData data, _) => data.temperature,
          name: 'Temperature',
          color: accentBlue, // Use accentBlue
          width: 3,
          markerSettings:
              MarkerSettings(isVisible: true, color: errorRed), // Use errorRed
          dataLabelSettings: const DataLabelSettings(isVisible: false),
        ),
        LineSeries<SensorData, String>(
          dataSource: data.isNotEmpty ? [data.first, data.last] : [],
          xValueMapper: (SensorData data, _) =>
              _formatTime(data.createdAt, short: true),
          yValueMapper: (_, __) => provider.tempThreshold,
          name: 'Threshold',
          color: warningColor, // Use warningColor
          width: 2,
          dashArray: const [8, 4],
          markerSettings: const MarkerSettings(isVisible: false),
          dataLabelSettings: const DataLabelSettings(isVisible: false),
        ),
        ScatterSeries<SensorData, String>(
          dataSource: data
              .where((d) => d.temperature > provider.tempThreshold)
              .toList(),
          xValueMapper: (SensorData data, _) =>
              _formatTime(data.createdAt, short: true),
          yValueMapper: (SensorData data, _) => data.temperature,
          markerSettings: MarkerSettings(
              isVisible: true,
              color: errorRed, // Use errorRed
              shape: DataMarkerType.circle,
              borderWidth: 2,
              borderColor: backgroundColor, // Use background color
              height: 10,
              width: 10),
        ),
      ],
    );
  }

  Widget _buildHumidityChart(List<SensorData> data) {
    if (data.isEmpty) return const SizedBox();

    final provider = Provider.of<SensorProvider>(context, listen: false);

    return SfCartesianChart(
      title: ChartTitle(
        text: 'Humidity Trend (%)',
        textStyle: GoogleFonts.poppins(
          color: darkText, // Use dark text color
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      primaryXAxis: CategoryAxis(
        labelRotation: 45,
        labelStyle: GoogleFonts.poppins(
          fontSize: 10,
          color: darkText.withOpacity(0.7), // Use dark text color
        ),
        majorGridLines: const MajorGridLines(width: 0),
        axisLine: const AxisLine(width: 0),
        majorTickLines: const MajorTickLines(width: 0),
      ),
      primaryYAxis: NumericAxis(
        minimum: 0,
        maximum: 100,
        interval: 20,
        labelFormat: '{value}%',
        labelStyle: GoogleFonts.poppins(
          fontSize: 10,
          color: darkText.withOpacity(0.7), // Use dark text color
        ),
        majorGridLines: MajorGridLines(
          color: darkText.withOpacity(0.1), // Use dark text color
        ),
        axisLine: const AxisLine(width: 0),
        majorTickLines: const MajorTickLines(width: 0),
      ),
      tooltipBehavior: TooltipBehavior(
        enable: true,
        format: 'point.y%\npoint.x',
        textStyle: GoogleFonts.poppins(color: darkText), // Use dark text color
        color: backgroundColor, // Use background color
        borderColor: darkText.withOpacity(0.1), // Use dark text color
        duration: 2000,
        builder: (data, point, series, pointIndex, seriesIndex) {
          // Ensure 'data' here is the SensorData object
          if (data is SensorData) {
            return Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: backgroundColor, // Use background color
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Text(
                '${data.humidity}% at ${_formatTime(data.createdAt)}',
                style:
                    GoogleFonts.poppins(color: darkText), // Use dark text color
              ),
            );
          }
          return const SizedBox
              .shrink(); // Return empty widget if data is not SensorData
        },
      ),
      series: <ChartSeries>[
        SplineSeries<SensorData, String>(
          dataSource: data,
          xValueMapper: (SensorData data, _) =>
              _formatTime(data.createdAt, short: true),
          yValueMapper: (SensorData data, _) => data.humidity,
          name: 'Humidity',
          color: warningColor, // Use warningColor
          width: 3,
          markerSettings:
              MarkerSettings(isVisible: true, color: errorRed), // Use errorRed
          dataLabelSettings: const DataLabelSettings(isVisible: false),
        ),
        LineSeries<SensorData, String>(
          dataSource: data.isNotEmpty ? [data.first, data.last] : [],
          xValueMapper: (SensorData data, _) =>
              _formatTime(data.createdAt, short: true),
          yValueMapper: (_, __) => provider.humThreshold,
          name: 'Threshold',
          color: warningColor, // Use warningColor
          width: 2,
          dashArray: const [8, 4],
          markerSettings: const MarkerSettings(isVisible: false),
          dataLabelSettings: const DataLabelSettings(isVisible: false),
        ),
        ScatterSeries<SensorData, String>(
          dataSource:
              data.where((d) => d.humidity > provider.humThreshold).toList(),
          xValueMapper: (SensorData data, _) =>
              _formatTime(data.createdAt, short: true),
          yValueMapper: (SensorData data, _) => data.humidity,
          markerSettings: MarkerSettings(
              isVisible: true,
              color: errorRed, // Use errorRed
              shape: DataMarkerType.circle,
              borderWidth: 2,
              borderColor: backgroundColor, // Use background color
              height: 10,
              width: 10),
        ),
      ],
    );
  }

  Widget _buildDataTable(List<SensorData> data) {
    if (data.isEmpty) return const SizedBox();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 20,
        dataRowColor: MaterialStateProperty.resolveWith<Color?>(
          (Set<MaterialState> states) {
            if (states.contains(MaterialState.selected)) {
              return accentBlue.withOpacity(0.08);
            }
            return null;
          },
        ),
        headingRowColor: MaterialStateProperty.all(
          accentBlue.withOpacity(0.12),
        ),
        headingTextStyle: GoogleFonts.poppins(
          color: accentBlue,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
        dataTextStyle: GoogleFonts.poppins(
          color: darkText,
          fontSize: 13,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: accentBlue.withOpacity(0.08),
          ),
        ),
        columns: const [
          DataColumn(
            label: Expanded(
              child: Text(
                'Time',
                textAlign: TextAlign.center,
              ),
            ),
          ),
          DataColumn(
            label: Expanded(
              child: Text(
                'Temp (°C)',
                textAlign: TextAlign.center,
              ),
            ),
          ),
          DataColumn(
            label: Expanded(
              child: Text(
                'Hum (%)',
                textAlign: TextAlign.center,
              ),
            ),
          ),
          DataColumn(
            label: Expanded(
              child: Text(
                'Relay',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
        rows: List<DataRow>.generate(
          data.reversed.take(10).length,
          (index) {
            final reading = data.reversed.take(10).toList()[index];
            final provider =
                Provider.of<SensorProvider>(context, listen: false);
            final isEven = index % 2 == 0;
            return DataRow(
              color: MaterialStateProperty.all(
                isEven ? accentBlue.withOpacity(0.04) : Colors.transparent,
              ),
              cells: [
                DataCell(
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        _formatTime(reading.createdAt),
                        style: GoogleFonts.poppins(
                          color: darkText.withOpacity(0.8),
                        ),
                      ),
                    ),
                  ),
                ),
                DataCell(
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        reading.temperature.toStringAsFixed(1),
                        style: GoogleFonts.poppins(
                          color: reading.temperature > provider.tempThreshold
                              ? errorRed
                              : darkText,
                          fontWeight:
                              reading.temperature > provider.tempThreshold
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                ),
                DataCell(
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        reading.humidity.toStringAsFixed(1),
                        style: GoogleFonts.poppins(
                          color: reading.humidity > provider.humThreshold
                              ? errorRed
                              : darkText,
                          fontWeight: reading.humidity > provider.humThreshold
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                ),
                DataCell(
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Icon(
                        reading.relayStatus == 'On'
                            ? Icons.power_settings_new
                            : Icons.power_off,
                        color: reading.relayStatus == 'On'
                            ? successColor
                            : darkText.withOpacity(0.7),
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

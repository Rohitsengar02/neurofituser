import '../services/orders_backend_service.dart';
import '../services/user_backend_service.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class AddressModel {
  final String id;
  final String tag; // 'Home', 'Work', 'Gym', 'Other'
  final String name;
  final String phone;
  final String flat;
  final String building;
  final String area;
  final String city;
  final String pincode;
  final double? latitude;
  final double? longitude;
  final bool isDefault;

  AddressModel({
    required this.id,
    required this.tag,
    required this.name,
    required this.phone,
    required this.flat,
    required this.building,
    required this.area,
    required this.city,
    required this.pincode,
    this.latitude,
    this.longitude,
    this.isDefault = false,
  });

  String get fullAddress => '$flat, $building, $area, $city - $pincode';
}

class AddressManagementScreen extends StatefulWidget {
  final String currentSelectedId;

  const AddressManagementScreen({
    super.key,
    required this.currentSelectedId,
  });

  @override
  State<AddressManagementScreen> createState() => _AddressManagementScreenState();
}

class _AddressManagementScreenState extends State<AddressManagementScreen> {
  late String _selectedAddressId;
  final List<AddressModel> _savedAddresses = [];
  bool _isLoadingRealAddress = false;

  @override
  void initState() {
    super.initState();
    _selectedAddressId = widget.currentSelectedId;
    _fetchRealUserAddress();
  }

  Future<void> _fetchRealUserAddress() async {
    final user = UserBackendService.instance.currentUser;
    if (user != null && user.uid.isNotEmpty) {
      setState(() => _isLoadingRealAddress = true);
      final addressData = await OrdersBackendService.instance.fetchUserAddress(user.uid);
      if (addressData != null && (addressData['streetAddress'] as String? ?? '').isNotEmpty && mounted) {
        setState(() {
          _savedAddresses.clear();
          _savedAddresses.add(
            AddressModel(
              id: 'addr_real_1',
              tag: 'Default',
              name: addressData['fullName'] ?? user.name,
              phone: addressData['phoneNumber'] ?? user.phone,
              flat: addressData['streetAddress'] ?? '',
              building: '',
              area: '',
              city: addressData['city'] ?? '',
              pincode: addressData['pincode'] ?? '',
              isDefault: true,
            ),
          );
          _selectedAddressId = 'addr_real_1';
        });
      }
      if (mounted) setState(() => _isLoadingRealAddress = false);
    }
  }

  void _openMapPicker() async {
    HapticFeedback.lightImpact();
    final newAddress = await Navigator.push<AddressModel>(
      context,
      MaterialPageRoute(builder: (context) => const MapLocationPickerScreen()),
    );

    if (newAddress != null && mounted) {
      final user = UserBackendService.instance.currentUser;
      if (user != null && user.uid.isNotEmpty) {
        await OrdersBackendService.instance.saveUserAddress(user.uid, {
          'fullName': newAddress.name.isNotEmpty ? newAddress.name : user.name,
          'phoneNumber': newAddress.phone.isNotEmpty ? newAddress.phone : user.phone,
          'streetAddress': '${newAddress.flat}, ${newAddress.building}, ${newAddress.area}'.replaceAll(RegExp(r'^,\s*|,\s*$'), ''),
          'city': newAddress.city,
          'state': 'State',
          'pincode': newAddress.pincode,
        });
      }

      if (mounted) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Address Saved: ${newAddress.tag} 📍'),
            backgroundColor: const Color(0xFF15803D),
            duration: const Duration(seconds: 1),
          ),
        );
        Navigator.pop(context, newAddress);
      }
    }
  }

  void _selectAndReturn(AddressModel address) async {
    HapticFeedback.selectionClick();
    final user = UserBackendService.instance.currentUser;
    if (user != null && user.uid.isNotEmpty) {
      await OrdersBackendService.instance.saveUserAddress(user.uid, {
        'fullName': address.name.isNotEmpty ? address.name : user.name,
        'phoneNumber': address.phone.isNotEmpty ? address.phone : user.phone,
        'streetAddress': '${address.flat}, ${address.building}, ${address.area}',
        'city': address.city,
        'state': 'State',
        'pincode': address.pincode,
      });
    }
    if (mounted) {
      Navigator.pop(context, address);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
        ),
        title: Text(
          'Select Delivery Address',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: GestureDetector(
              onTap: _openMapPicker,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFF16A34A), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF16A34A).withValues(alpha: 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFDCFCE7),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add_location_alt_rounded, color: Color(0xFF15803D), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Add New Address',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF15803D),
                            ),
                          ),
                          Text(
                            'Real-Time Live GPS Map Locator',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF15803D), size: 14),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 6),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Saved Addresses (${_savedAddresses.length})',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF64748B),
                ),
              ),
            ),
          ),

          Expanded(
            child: _isLoadingRealAddress
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF16A34A)))
                : _savedAddresses.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(18),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFDCFCE7),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.location_off_rounded, size: 36, color: Color(0xFF16A34A)),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'No Saved Addresses',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Tap "+ Add New Address" above to pin your live delivery location.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        physics: const BouncingScrollPhysics(),
                        itemCount: _savedAddresses.length,
                        separatorBuilder: (c, i) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                final addr = _savedAddresses[index];
                final isSelected = _selectedAddressId == addr.id;

                IconData tagIcon = Icons.home_rounded;
                Color tagBg = const Color(0xFFFEF3C7);
                Color tagColor = const Color(0xFFD97706);

                if (addr.tag == 'Work') {
                  tagIcon = Icons.work_rounded;
                  tagBg = const Color(0xFFEDE9FE);
                  tagColor = const Color(0xFF7C3AED);
                } else if (addr.tag == 'Gym') {
                  tagIcon = Icons.fitness_center_rounded;
                  tagBg = const Color(0xFFDCFCE7);
                  tagColor = const Color(0xFF15803D);
                }

                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedAddressId = addr.id);
                    _selectAndReturn(addr);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFF0FDF4) : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF16A34A) : const Color(0xFFE2E8F0),
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isSelected
                              ? const Color(0xFF16A34A).withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: tagBg,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(tagIcon, size: 12, color: tagColor),
                                  const SizedBox(width: 4),
                                  Text(
                                    addr.tag.toUpperCase(),
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: tagColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? const Color(0xFF16A34A) : const Color(0xFFCBD5E1),
                                  width: isSelected ? 6 : 2,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          addr.name,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          addr.fullAddress,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF475569),
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          addr.phone,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// REAL-TIME FLUTTER MAP WITH OPENSTREETMAP & LIVE GPS LOCATION
// =========================================================================
class MapLocationPickerScreen extends StatefulWidget {
  const MapLocationPickerScreen({super.key});

  @override
  State<MapLocationPickerScreen> createState() => _MapLocationPickerScreenState();
}

class _MapLocationPickerScreenState extends State<MapLocationPickerScreen>
    with SingleTickerProviderStateMixin {
  late final MapController _mapController;

  LatLng _currentCenter = const LatLng(12.9716, 77.5946); // Default Bengaluru
  bool _isLocating = true;
  String _currentArea = 'MG Road / Brigade Road';
  String _currentCity = 'Bengaluru';
  String _currentPincode = '560001';

  late AnimationController _pinPulseCtrl;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    _pinPulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _fetchCurrentLocation();
  }

  @override
  void dispose() {
    _pinPulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchCurrentLocation() async {
    setState(() => _isLocating = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _setFallbackLocation();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _setFallbackLocation();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _setFallbackLocation();
        return;
      }

      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      final newLatLng = LatLng(position.latitude, position.longitude);

      if (mounted) {
        setState(() {
          _currentCenter = newLatLng;
          _isLocating = false;
          _resolveAddressFromCoordinates(newLatLng);
        });

        _mapController.move(newLatLng, 16.5);
      }
    } catch (e) {
      if (mounted) _setFallbackLocation();
    }
  }

  void _setFallbackLocation() {
    final defaultLatLng = const LatLng(12.9716, 77.5946);
    setState(() {
      _currentCenter = defaultLatLng;
      _currentArea = 'Indiranagar 100ft Road';
      _currentCity = 'Bengaluru';
      _currentPincode = '560038';
      _isLocating = false;
    });
    _mapController.move(defaultLatLng, 16.0);
  }  Timer? _debounceGeocoding;

  Future<void> _resolveAddressFromCoordinates(LatLng point) async {
    _debounceGeocoding?.cancel();
    _debounceGeocoding = Timer(const Duration(milliseconds: 350), () async {
      try {
        final client = HttpClient();
        client.userAgent = 'NeuroFit-Athlete-App/1.0 (contact@neurofit.com)';
        final uri = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=json&lat=${point.latitude}&lon=${point.longitude}&zoom=18&addressdetails=1',
        );

        final request = await client.getUrl(uri);
        final response = await request.close();

        if (response.statusCode == 200) {
          final responseBody = await response.transform(utf8.decoder).join();
          final data = jsonDecode(responseBody) as Map<String, dynamic>;
          final addr = data['address'] as Map<String, dynamic>? ?? {};

          final road = addr['road'] ?? addr['suburb'] ?? addr['neighbourhood'] ?? addr['hamlet'] ?? '';
          final suburb = addr['suburb'] ?? addr['residential'] ?? addr['quarter'] ?? '';
          final district = addr['state_district'] ?? addr['county'] ?? addr['city_district'] ?? '';
          final city = addr['city'] ?? addr['town'] ?? addr['village'] ?? addr['municipality'] ?? district;
          final state = addr['state'] ?? 'Karnataka';
          final postcode = addr['postcode'] ?? '560001';

          String areaName = '';
          if (road.isNotEmpty && suburb.isNotEmpty && road != suburb) {
            areaName = '$road, $suburb';
          } else if (road.isNotEmpty) {
            areaName = road;
          } else if (suburb.isNotEmpty) {
            areaName = suburb;
          } else {
            areaName = district.isNotEmpty ? district : city;
          }

          if (mounted) {
            setState(() {
              _currentArea = areaName;
              _currentCity = district.isNotEmpty && district != city ? '$city, $district, $state' : '$city, $state';
              _currentPincode = postcode;
            });
          }
        } else {
          _fallbackLocalResolution(point);
        }
      } catch (e) {
        _fallbackLocalResolution(point);
      }
    });
  }

  void _fallbackLocalResolution(LatLng point) {
    if (mounted) {
      setState(() {
        _currentArea = 'Indiranagar 100ft Road, Defense Colony';
        _currentCity = 'Bengaluru Urban, Karnataka';
        _currentPincode = '560038';
      });
    }
  }

  void _openAddressFormSlider() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddressDetailsFormSlider(
        area: _currentArea,
        city: _currentCity,
        pincode: _currentPincode,
        latitude: _currentCenter.latitude,
        longitude: _currentCenter.longitude,
      ),
    ).then((newAddress) {
      if (newAddress != null && mounted) {
        Navigator.pop(context, newAddress);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Stack(
        children: [
          // 1. REAL FLUTTER MAP WITH OPENSTREETMAP TILE LAYER
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentCenter,
              initialZoom: 16.0,
              minZoom: 4.0,
              maxZoom: 19.0,
              onPositionChanged: (camera, hasGesture) {
                if (hasGesture) {
                  _currentCenter = camera.center;
                  _resolveAddressFromCoordinates(camera.center);
                  if (mounted) setState(() {});
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.neurofit.athlete.app',
                maxZoom: 19,
              ),
            ],
          ),

          // 2. Center Animated Delivery Marker
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 3))],
                  ),
                  child: Text(
                    'Order will be delivered here',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                AnimatedBuilder(
                  animation: _pinPulseCtrl,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, -6 * _pinPulseCtrl.value),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF15803D),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF22C55E).withValues(alpha: 0.6),
                              blurRadius: 20 * _pinPulseCtrl.value + 6,
                              spreadRadius: 6 * _pinPulseCtrl.value,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.location_on_rounded, color: Colors.white, size: 28),
                      ),
                    );
                  },
                ),
                Container(
                  width: 14,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ],
            ),
          ),

          // 3. Top Back Button & Search Header
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))],
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Color(0xFF0F172A)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _isLocating ? 'Locating via GPS...' : '$_currentArea, $_currentCity',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 4. GPS Re-Center Floating Action Button
          Positioned(
            right: 16,
            bottom: 210,
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                _fetchCurrentLocation();
              },
              child: Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 3))],
                ),
                child: _isLocating
                    ? const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF15803D)),
                      )
                    : const Icon(Icons.my_location_rounded, color: Color(0xFF15803D), size: 22),
              ),
            ),
          ),

          // 5. Bottom Location Confirmation Card
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 18, offset: Offset(0, -4))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Color(0xFFDCFCE7),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.location_on_rounded, color: Color(0xFF15803D), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _currentArea,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              '$_currentCity, PIN $_currentPincode',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _openAddressFormSlider,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF15803D),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 3,
                      ),
                      child: Text(
                        'Confirm Location & Enter House No.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// ADDRESS DETAILS FORM SLIDER
// =========================================================================
class _AddressDetailsFormSlider extends StatefulWidget {
  final String area;
  final String city;
  final String pincode;
  final double latitude;
  final double longitude;

  const _AddressDetailsFormSlider({
    required this.area,
    required this.city,
    required this.pincode,
    required this.latitude,
    required this.longitude,
  });

  @override
  State<_AddressDetailsFormSlider> createState() => _AddressDetailsFormSliderState();
}

class _AddressDetailsFormSliderState extends State<_AddressDetailsFormSlider> {
  final TextEditingController _flatCtrl = TextEditingController();
  final TextEditingController _buildingCtrl = TextEditingController();
  final TextEditingController _nameCtrl = TextEditingController(text: 'Rohit Sengar');
  final TextEditingController _phoneCtrl = TextEditingController(text: '+91 98765 43210');

  String _selectedTag = 'Home';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Text(
              'Enter Complete Address',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Location autofilled from real GPS coordinates 📍',
              style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: const Color(0xFF16A34A), fontWeight: FontWeight.w700),
            ),

            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.pin_drop_rounded, color: Color(0xFF15803D), size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${widget.area}, ${widget.city} - ${widget.pincode}',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF334155)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            TextField(
              controller: _flatCtrl,
              style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                labelText: 'House / Flat / Floor No. *',
                hintText: 'e.g. Flat 301, 3rd Floor',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              ),
            ),
            const SizedBox(height: 10),

            TextField(
              controller: _buildingCtrl,
              style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                labelText: 'Apartment / Building Name *',
                hintText: 'e.g. Prestige Greenwoods',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              ),
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameCtrl,
                    style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      labelText: 'Receiver Name',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _phoneCtrl,
                    style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            Text(
              'Save Address As',
              style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
            ),
            const SizedBox(height: 8),
            Row(
              children: ['Home', 'Work', 'Gym', 'Other'].map((tag) {
                final isSel = _selectedTag == tag;
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedTag = tag);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSel ? const Color(0xFF15803D) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isSel ? const Color(0xFF15803D) : const Color(0xFFE2E8F0)),
                      ),
                      child: Center(
                        child: Text(
                          tag,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                            color: isSel ? Colors.white : const Color(0xFF475569),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 18),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  if (_flatCtrl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter your flat or house number')),
                    );
                    return;
                  }

                  final newAddr = AddressModel(
                    id: 'addr_${DateTime.now().millisecondsSinceEpoch}',
                    tag: _selectedTag,
                    name: _nameCtrl.text.trim().isNotEmpty ? _nameCtrl.text.trim() : 'Rohit Sengar',
                    phone: _phoneCtrl.text.trim().isNotEmpty ? _phoneCtrl.text.trim() : '+91 98765 43210',
                    flat: _flatCtrl.text.trim(),
                    building: _buildingCtrl.text.trim().isNotEmpty ? _buildingCtrl.text.trim() : 'Residential Block',
                    area: widget.area,
                    city: widget.city,
                    pincode: widget.pincode,
                    latitude: widget.latitude,
                    longitude: widget.longitude,
                  );

                  Navigator.pop(context, newAddr);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF15803D),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  'Save & Deliver to this Address',
                  style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProviderProfileDashboard extends StatefulWidget {
  const ProviderProfileDashboard({super.key});

  @override
  State<ProviderProfileDashboard> createState() => _ProviderProfileDashboardState();
}

class _ProviderProfileDashboardState extends State<ProviderProfileDashboard> {
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isEditing = false;

  String _fullName = 'Provider';
  String _serviceCategory = 'Specialist';
  double _rating = 5.0;
  int _reviewsCount = 0;
  String _email = '';
  String _phoneNumber = '';
  String _location = '';
  double _hourlyRate = 0.0;
  String _availability = 'Mon-Fri, 9am - 5pm';
  int _experienceYears = 0;
  String _bio = '';

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _serviceCategoryController = TextEditingController();
  final TextEditingController _hourlyRateController = TextEditingController();
  final TextEditingController _availabilityController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _serviceCategoryController.dispose();
    _hourlyRateController.dispose();
    _availabilityController.dispose();
    _experienceController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _fetchProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get()
          .timeout(const Duration(seconds: 5));

      if (doc.exists && mounted) {
        final data = doc.data();
        
        // Dynamically compute average rating and reviewsCount directly from the reviews collection
        final reviewsQuerySnapshot = await FirebaseFirestore.instance
            .collection('reviews')
            .where('providerId', isEqualTo: user.uid)
            .get();

        double sum = 0.0;
        int dynamicReviewsCount = reviewsQuerySnapshot.docs.length;
        for (var d in reviewsQuerySnapshot.docs) {
          sum += ((d.data() as Map<String, dynamic>)['rating'] ?? 0.0).toDouble();
        }
        double dynamicAverageRating = dynamicReviewsCount > 0 ? (sum / dynamicReviewsCount) : 0.0;
        final double finalRating = double.parse(dynamicAverageRating.toStringAsFixed(1));

        // Update provider user document in Firestore to keep database values synced
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
              'rating': finalRating,
              'reviewsCount': dynamicReviewsCount,
            });

        setState(() {
          _fullName = data?['fullName'] ?? 'Provider';
          _serviceCategory = data?['serviceCategory'] ?? 'Specialist';
          _rating = finalRating;
          _reviewsCount = dynamicReviewsCount;
          _email = data?['email'] ?? user.email ?? '';
          _phoneNumber = data?['phoneNumber'] ?? '';
          _location = data?['location'] ?? '';
          _hourlyRate = (data?['hourlyRate'] ?? 0.0).toDouble();
          _availability = data?['availability'] ?? 'Mon-Fri, 9am - 5pm';
          _experienceYears = data?['experienceYears'] ?? 0;
          _bio = data?['bio'] ?? '';

          _fullNameController.text = _fullName;
          _phoneController.text = _phoneNumber;
          _locationController.text = _location;
          _serviceCategoryController.text = _serviceCategory;
          _hourlyRateController.text = _hourlyRate.toString();
          _availabilityController.text = _availability;
          _experienceController.text = _experienceYears.toString();
          _bioController.text = _bio;

          _isLoading = false;
        });
      }
    } catch (e) {
      print('Warning: Failed to fetch Provider Profile: $e');
      if (mounted) {
        setState(() {
          _fullName = user.displayName ?? 'Provider';
          _email = user.email ?? '';
          _fullNameController.text = _fullName;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    if (_fullNameController.text.trim().isEmpty) {
      _showSnackBar('Name cannot be empty', const Color(0xFFE53E3E));
      return;
    }

    final rate = double.tryParse(_hourlyRateController.text) ?? 0.0;
    final exp = int.tryParse(_experienceController.text) ?? 0;

    setState(() => _isSaving = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'fullName': _fullNameController.text.trim(),
          'phoneNumber': _phoneController.text.trim(),
          'location': _locationController.text.trim(),
          'serviceCategory': _serviceCategoryController.text.trim(),
          'hourlyRate': rate,
          'availability': _availabilityController.text.trim(),
          'experienceYears': exp,
          'bio': _bioController.text.trim(),
        }).timeout(const Duration(seconds: 5));

        setState(() {
          _fullName = _fullNameController.text.trim();
          _phoneNumber = _phoneController.text.trim();
          _location = _locationController.text.trim();
          _serviceCategory = _serviceCategoryController.text.trim();
          _hourlyRate = rate;
          _availability = _availabilityController.text.trim();
          _experienceYears = exp;
          _bio = _bioController.text.trim();
          _isEditing = false;
        });

        _showSnackBar('Profile saved successfully!', const Color(0xFF38A169));
      }
    } catch (e) {
      _showSnackBar('Failed to save profile: $e', const Color(0xFFE53E3E));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40.0),
          child: CircularProgressIndicator(color: Color(0xFF6B46C1)),
        ),
      );
    }

    final bool isMobile = MediaQuery.of(context).size.width < 800;

    if (_isEditing) {
      return SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Edit Profile',
                  style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w700, color: const Color(0xFF1A202C)),
                ),
                ElevatedButton.icon(
                  onPressed: () => setState(() => _isEditing = false),
                  icon: const Icon(Icons.cancel, color: Colors.white, size: 18),
                  label: Text('Cancel', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE53E3E),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _settingsInputStub(label: 'Full Name', controller: _fullNameController),
                  const SizedBox(height: 16),
                  _settingsInputStub(label: 'Service Category (e.g. Expert Plumber)', controller: _serviceCategoryController),
                  const SizedBox(height: 16),
                  _settingsInputStub(label: 'Phone Number', controller: _phoneController),
                  const SizedBox(height: 16),
                  _settingsInputStub(label: 'Location', controller: _locationController),
                  const SizedBox(height: 16),
                  _settingsInputStub(label: 'Hourly Rate (PKR)', controller: _hourlyRateController, isNumeric: true),
                  const SizedBox(height: 16),
                  _settingsInputStub(label: 'Experience (Years)', controller: _experienceController, isNumeric: true),
                  const SizedBox(height: 16),
                  _settingsInputStub(label: 'Availability', controller: _availabilityController),
                  const SizedBox(height: 16),
                  _settingsInputStub(label: 'Bio', controller: _bioController, maxLines: 3),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6B46C1),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Text('Save Profile Changes', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMobile) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: () => setState(() => _isEditing = true),
                  icon: const Icon(Icons.edit, color: Colors.white, size: 18),
                  label: Text('Edit Profile', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6B46C1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFF6B46C1),
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: const Icon(Icons.person, color: Colors.white, size: 40),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _fullName,
                            style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            _serviceCategory,
                            style: GoogleFonts.inter(color: const Color(0xFF718096), fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.star, color: Color(0xFFECC94B), size: 16),
                              const SizedBox(width: 4),
                              Text(
                                _reviewsCount == 0 ? '0.0(No review yet)' : '$_rating ($_reviewsCount reviews)',
                                style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                const Divider(),
                const SizedBox(height: 20),
                _buildProfileSection('Contact Information', [
                  _profileDetailItem(Icons.email, 'Email', _email),
                  _profileDetailItem(Icons.phone, 'Phone', _phoneNumber.isEmpty ? 'Not Provided' : _phoneNumber),
                  _profileDetailItem(Icons.location_on, 'Location', _location.isEmpty ? 'Not Provided' : _location),
                ]),
                const SizedBox(height: 30),
                _buildProfileSection('Business Details', [
                  _profileDetailItem(Icons.attach_money, 'Hourly Rate', 'PKR ${_hourlyRate.toStringAsFixed(2)}/hr'),
                  _profileDetailItem(Icons.access_time, 'Availability', _availability),
                  _profileDetailItem(Icons.work, 'Experience', '$_experienceYears Years'),
                ]),
                if (_bio.isNotEmpty) ...[
                  const SizedBox(height: 30),
                  _buildProfileSection('About Me', [
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text(
                        _bio,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          height: 1.5,
                          color: const Color(0xFF4A5568),
                        ),
                      ),
                    ),
                  ]),
                ],
                if (isMobile) ...[
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => setState(() => _isEditing = true),
                      icon: const Icon(Icons.edit, color: Colors.white, size: 18),
                      label: Text('Edit Profile', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6B46C1),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF2D3748))),
        const SizedBox(height: 16),
        ...items,
      ],
    );
  }

  Widget _profileDetailItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFA0AEC0), size: 20),
          const SizedBox(width: 12),
          Text('$label:', style: GoogleFonts.inter(color: const Color(0xFF718096), fontWeight: FontWeight.w500)),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: const Color(0xFF1A202C)))),
        ],
      ),
    );
  }

  Widget _settingsInputStub({
    required String label,
    required TextEditingController controller,
    bool isNumeric = false,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: const Color(0xFF4A5568), fontSize: 14)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
          maxLines: maxLines,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF7FAFC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF6B46C1))),
          ),
        ),
      ],
    );
  }
}

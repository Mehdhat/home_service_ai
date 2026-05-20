import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'forgot_password_screen.dart';
import 'email_verification_screen.dart';
import '../repositories/auth_repository.dart';

class AuthScreen extends StatefulWidget {
  final String role; // 'Seeker' or 'Provider'
  final Widget destination;

  const AuthScreen({super.key, required this.role, required this.destination});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true;
  bool _isEmailAuthLoading = false;
  bool _obscurePassword = true;
  final _formKey = GlobalKey<FormState>();

  // Repositories
  final AuthRepository _authRepository = AuthRepository();

  // Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  // Registration-only controllers
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  
  // Provider-only controllers
  final _skillsController = TextEditingController();
  final _hourlyRateController = TextEditingController();
  final _experienceController = TextEditingController();
  final _bioController = TextEditingController();

  // Dropdown states
  String? _selectedCategory;
  String? _selectedAvailability;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _skillsController.dispose();
    _hourlyRateController.dispose();
    _experienceController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_isEmailAuthLoading) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isEmailAuthLoading = true);

    try {
      if (isLogin) {
        print('Attempting login for ${widget.role} with email: ${_emailController.text.trim()}');
        // Authenticate User
        final user = await _authRepository.login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          expectedRole: widget.role.toLowerCase(),
        );

        if (user != null && mounted) {
          print('Login successful for ${widget.role}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Successfully logged in as a ${widget.role}!',
                style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600),
              ),
              backgroundColor: const Color(0xFF38A169),
              behavior: SnackBarBehavior.floating,
            ),
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => widget.destination),
          );
        }
      } else {
        print('Attempting registration for ${widget.role} with email: ${_emailController.text.trim()}');
        // Register User
        if (widget.role == 'Seeker') {
          await _authRepository.registerAsSeeker(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            fullName: _fullNameController.text.trim(),
            phoneNumber: _phoneController.text.trim(),
            location: _locationController.text.trim(),
          );
        } else {
          await _authRepository.registerAsProvider(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            fullName: _fullNameController.text.trim(),
            phoneNumber: _phoneController.text.trim(),
            location: _locationController.text.trim(),
            serviceCategory: _selectedCategory ?? '',
            skills: _skillsController.text.trim().split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
            hourlyRate: double.tryParse(_hourlyRateController.text.trim()) ?? 0.0,
            availability: _selectedAvailability ?? '',
            experienceYears: int.tryParse(_experienceController.text.trim()) ?? 0,
            bio: _bioController.text.trim(),
          );
        }

        print('Registration successful for ${widget.role}, navigating to email verification screen');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Registration successful! Verification email sent.',
                style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600),
              ),
              backgroundColor: const Color(0xFF38A169),
              behavior: SnackBarBehavior.floating,
            ),
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => EmailVerificationScreen(
                email: _emailController.text.trim(),
                destination: widget.destination,
              ),
            ),
          );
        }
      }
    } on EmailNotVerifiedException catch (e) {
      print('EmailNotVerifiedException caught: ${e.message}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.message,
              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600),
            ),
            backgroundColor: const Color(0xFFED8936),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => EmailVerificationScreen(
              email: _emailController.text.trim(),
              destination: widget.destination,
            ),
          ),
        );
      }
    } catch (e) {
      print('ERROR: Auth failed: $e');
      print('Error type: ${e.runtimeType}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceAll('Exception: ', ''),
              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600),
            ),
            backgroundColor: const Color(0xFFE53E3E),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isEmailAuthLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isAnyLoading = _isEmailAuthLoading;
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A202C)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 800) {
            return Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Container(
                    color: const Color(0xFF6B46C1),
                    padding: const EdgeInsets.all(64),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.star_rounded, color: Colors.white, size: 36),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          'Home Service AI',
                          style: GoogleFonts.inter(
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -1.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'AI-powered platform bridging service providers and seekers in the informal economy. We build trust through technology.',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            color: const Color(0xFFE9D8FD),
                            height: 1.6,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 6,
                  child: Container(
                    color: Colors.white,
                    height: double.infinity,
                    child: SafeArea(
                      child: Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 40),
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 480),
                            child: Form(
                              key: _formKey,
                              child: _buildFormContent(isAnyLoading),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          } else {
            return SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 450),
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: _buildFormContent(isAnyLoading),
                    ),
                  ),
                ),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildFormContent(bool isAnyLoading) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          isLogin ? 'Welcome Back!' : 'Create Account',
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1A202C),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'As a ${widget.role}',
          style: GoogleFonts.inter(
            fontSize: 16,
            color: const Color(0xFF6B46C1),
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        if (!isLogin) ...[
          _buildTextField(
            label: 'Full Name *',
            hint: 'Enter your full name',
            icon: Icons.person_outline,
            controller: _fullNameController,
            validator: (val) => val == null || val.trim().isEmpty ? 'Full name is required' : null,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Phone Number *',
            hint: 'Enter your phone number',
            icon: Icons.phone_outlined,
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            validator: (val) {
              if (val == null || val.trim().isEmpty) return 'Phone number is required';
              if (val.trim().length < 8) return 'Please enter a valid phone number';
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Location *',
            hint: 'Enter your location',
            icon: Icons.location_on_outlined,
            controller: _locationController,
            validator: (val) => val == null || val.trim().isEmpty ? 'Location is required' : null,
          ),
          if (widget.role == 'Provider') ...[
            const SizedBox(height: 16),
            _buildDropdownField(
              label: 'Service Category *',
              hint: 'Select your service category',
              icon: Icons.category_outlined,
              value: _selectedCategory,
              items: const [
                'Electrician',
                'Plumber',
                'AC Technician',
                'Carpenter',
                'Home Appliances Repair',
                'Deep Cleaning',
                'Water Tank Cleaning',
                'Pest Control',
                'Gardener',
                'Laundry & Dry Cleaning',
                'Home Tutor',
                'Generator Mechanic',
                'Painter',
                'Solar Panel Cleaning',
                'Home Maid',
                'Home beauticians',
                'Others',
              ],
              onChanged: (val) => setState(() => _selectedCategory = val),
              validator: (val) => val == null || val.isEmpty ? 'Service category is required' : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: 'Skills *',
              hint: 'Describe your skills (e.g. Plumbing, Electrical)',
              icon: Icons.build_outlined,
              controller: _skillsController,
              validator: (val) => val == null || val.trim().isEmpty ? 'Skills are required' : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: 'Hourly Rate (PKR) *',
              hint: 'Enter your hourly rate',
              icon: Icons.attach_money_outlined,
              controller: _hourlyRateController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (val) {
                if (val == null || val.trim().isEmpty) return 'Hourly rate is required';
                final rate = double.tryParse(val.trim());
                if (rate == null || rate <= 0) return 'Enter a valid hourly rate > 0';
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildDropdownField(
              label: 'Availability *',
              hint: 'Select your availability',
              icon: Icons.access_time_outlined,
              value: _selectedAvailability,
              items: const [
                'Full-time',
                'Part-time',
                'Weekends',
                'Evenings',
                'Flexible',
              ],
              onChanged: (val) => setState(() => _selectedAvailability = val),
              validator: (val) => val == null || val.isEmpty ? 'Availability is required' : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: 'Experience (years) *',
              hint: 'Years of experience',
              icon: Icons.work_outline,
              controller: _experienceController,
              keyboardType: TextInputType.number,
              validator: (val) {
                if (val == null || val.trim().isEmpty) return 'Experience is required';
                final exp = int.tryParse(val.trim());
                if (exp == null || exp < 0) return 'Enter a valid experience > 0';
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: 'Bio *',
              hint: 'Tell us about yourself',
              icon: Icons.description_outlined,
              controller: _bioController,
              maxLines: 2,
              validator: (val) => val == null || val.trim().isEmpty ? 'Short bio is required' : null,
            ),
          ],
          const SizedBox(height: 16),
        ],
        _buildTextField(
          label: 'Email Address *',
          hint: 'name@example.com',
          icon: Icons.email_outlined,
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          validator: (val) {
            if (val == null || val.trim().isEmpty) return 'Email is required';
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val.trim())) {
              return 'Enter a valid email address';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          label: 'Password *',
          hint: 'Enter your password',
          icon: Icons.lock_outline,
          controller: _passwordController,
          isPassword: true,
          showPasswordToggle: true,
          validator: (val) {
            if (val == null || val.isEmpty) return 'Password is required';
            if (val.length < 6) return 'Password must be at least 6 characters';
            return null;
          },
        ),
        if (isLogin)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
                );
              },
              child: Text(
                'Forgot Password?',
                style: GoogleFonts.inter(
                  color: const Color(0xFF6B46C1),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: isAnyLoading ? null : _handleSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6B46C1),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: _isEmailAuthLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Text(
                  isLogin ? 'Login' : 'Sign Up',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
        ),

        const SizedBox(height: 24),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              isLogin ? "Don't have an account? " : "Already have an account? ",
              style: GoogleFonts.inter(color: const Color(0xFF718096)),
            ),
            TextButton(
              onPressed: () {
                if (isAnyLoading) return;
                setState(() => isLogin = !isLogin);
              },
              child: Text(
                isLogin ? 'Sign Up' : 'Login',
                style: GoogleFonts.inter(
                  color: const Color(0xFF6B46C1),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    String? Function(String?)? validator,
    bool isPassword = false,
    bool showPasswordToggle = false,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF4A5568),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: isPassword && _obscurePassword,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          style: GoogleFonts.inter(fontSize: 15, color: const Color(0xFF1A202C)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(color: const Color(0xFFA0AEC0), fontSize: 14),
            prefixIcon: Icon(icon, color: const Color(0xFFA0AEC0), size: 20),
            suffixIcon: showPasswordToggle
                ? IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: const Color(0xFFA0AEC0),
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  )
                : null,
            filled: true,
            fillColor: const Color(0xFFF7FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF6B46C1), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String hint,
    required IconData icon,
    required List<String> items,
    required String? value,
    required ValueChanged<String?> onChanged,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF4A5568),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          isExpanded: true,
          value: value,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(color: const Color(0xFFA0AEC0), fontSize: 14),
            prefixIcon: Icon(icon, color: const Color(0xFFA0AEC0), size: 20),
            filled: true,
            fillColor: const Color(0xFFF7FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF6B46C1), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                style: GoogleFonts.inter(fontSize: 15, color: const Color(0xFF1A202C)),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
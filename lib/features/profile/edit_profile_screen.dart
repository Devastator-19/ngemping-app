import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../auth/providers/auth_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameCtrl;
  late TextEditingController _alamatCtrl;
  late TextEditingController _provinsiCtrl;
  late TextEditingController _districtCtrl;
  String? _selectedGender;

  // label → backend enum value
  static const _genderOptions = {
    'Laki-laki': 'MALE',
    'Perempuan': 'FEMALE',
    'Lainnya': 'OTHER',
  };

  @override
  void initState() {
    super.initState();
    final user = context.read<AppAuthProvider>().user;
    _nameCtrl = TextEditingController(text: user?.displayName ?? '');
    _alamatCtrl = TextEditingController(text: user?.alamat ?? '');
    _provinsiCtrl = TextEditingController(text: user?.provinsi ?? '');
    _districtCtrl = TextEditingController(text: user?.district ?? '');
    _selectedGender = user?.gender;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _alamatCtrl.dispose();
    _provinsiCtrl.dispose();
    _districtCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AppAuthProvider>();
    final ok = await auth.updateProfile(
      displayName: _nameCtrl.text.trim().isNotEmpty ? _nameCtrl.text.trim() : null,
      alamat: _alamatCtrl.text.trim().isNotEmpty ? _alamatCtrl.text.trim() : null,
      gender: _selectedGender,
      provinsi: _provinsiCtrl.text.trim().isNotEmpty ? _provinsiCtrl.text.trim() : null,
      district: _districtCtrl.text.trim().isNotEmpty ? _districtCtrl.text.trim() : null,
    );

    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profil berhasil disimpan', style: GoogleFonts.nunito()),
          backgroundColor: AppColors.primaryDark,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      Navigator.of(context).pop();
    } else {
      final err = context.read<AppAuthProvider>().error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err ?? 'Gagal menyimpan profil', style: GoogleFonts.nunito()),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AppAuthProvider>().isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Edit Profil',
          style: GoogleFonts.comfortaa(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: isLoading
                ? const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.primary),
                    ),
                  )
                : TextButton(
                    onPressed: _save,
                    child: Text(
                      'Simpan',
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionLabel(label: 'Informasi Dasar'),
              const SizedBox(height: 12),

              // Nama
              _buildField(
                controller: _nameCtrl,
                label: 'Nama Lengkap',
                hint: 'Masukkan nama lengkap',
                icon: Icons.person_outline_rounded,
              ),
              const SizedBox(height: 14),

              // Gender
              _buildGenderPicker(),
              const SizedBox(height: 28),

              _SectionLabel(label: 'Alamat'),
              const SizedBox(height: 12),

              // Provinsi
              _buildField(
                controller: _provinsiCtrl,
                label: 'Provinsi',
                hint: 'Contoh: Jawa Barat',
                icon: Icons.map_outlined,
              ),
              const SizedBox(height: 14),

              // District / Kota/Kabupaten
              _buildField(
                controller: _districtCtrl,
                label: 'Kota / Kabupaten',
                hint: 'Contoh: Bandung',
                icon: Icons.location_city_outlined,
              ),
              const SizedBox(height: 14),

              // Alamat lengkap
              _buildField(
                controller: _alamatCtrl,
                label: 'Alamat Lengkap',
                hint: 'Jalan, nomor rumah, RT/RW, dll.',
                icon: Icons.home_outlined,
                maxLines: 3,
              ),
              const SizedBox(height: 32),

              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.white),
                        )
                      : Text(
                          'Simpan Perubahan',
                          style: GoogleFonts.nunito(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.nunito(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textMedium,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: GoogleFonts.nunito(fontSize: 14, color: AppColors.textDark),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                GoogleFonts.nunito(fontSize: 14, color: AppColors.textLight),
            prefixIcon: Icon(icon, size: 20, color: AppColors.textLight),
            filled: true,
            fillColor: AppColors.surface,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Jenis Kelamin',
          style: GoogleFonts.nunito(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textMedium,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: _genderOptions.entries.toList().asMap().entries.map((e) {
            final idx = e.key;
            final label = e.value.key;
            final enumVal = e.value.value;
            final selected = _selectedGender == enumVal;
            final isLast = idx == _genderOptions.length - 1;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedGender = enumVal),
                child: Container(
                  margin: EdgeInsets.only(right: isLast ? 0 : 8),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primarySurface : AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected ? AppColors.primary : AppColors.border,
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      label,
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                        color: selected ? AppColors.primary : AppColors.textMedium,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.comfortaa(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: AppColors.textDark,
      ),
    );
  }
}

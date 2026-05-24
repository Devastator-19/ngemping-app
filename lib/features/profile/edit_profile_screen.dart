import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/api_client.dart';
import '../auth/providers/auth_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameCtrl;
  late TextEditingController _nickNameCtrl;
  late TextEditingController _placeOfBirthCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _alamatCtrl;

  DateTime? _dateOfBirth;
  String? _selectedGender;
  String? _selectedProvinsi;
  String? _selectedDistrict;

  List<Map<String, String>> _provinces = [];
  List<Map<String, String>> _regencies = [];

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
    _nickNameCtrl = TextEditingController(text: user?.nickName ?? '');
    _placeOfBirthCtrl = TextEditingController(text: user?.placeOfBirth ?? '');
    _phoneCtrl = TextEditingController(text: user?.phoneNumber ?? '');
    _alamatCtrl = TextEditingController(text: user?.alamat ?? '');
    _dateOfBirth = user?.dateOfBirth;
    _selectedGender = user?.gender;
    _selectedProvinsi = user?.provinsi?.isNotEmpty == true ? user!.provinsi : null;
    _selectedDistrict = user?.district?.isNotEmpty == true ? user!.district : null;
    _loadProvinces();
  }

  Future<void> _loadProvinces() async {
    try {
      final res = await ApiClient.instance.get('/wilayah/provinces');
      final list = (res.data['data'] as List).cast<Map<String, dynamic>>();
      if (mounted) {
        setState(() => _provinces = list.map((e) => {'code': e['code'] as String, 'name': e['name'] as String}).toList());
      }
      if (_selectedProvinsi != null) _loadRegencies(_selectedProvinsi!);
    } catch (_) {}
  }

  Future<void> _loadRegencies(String provinceName) async {
    final p = _provinces.firstWhere((e) => e['name'] == provinceName, orElse: () => {});
    if (p.isEmpty) return;
    try {
      final res = await ApiClient.instance.get('/wilayah/provinces/${p['code']}/regencies');
      final list = (res.data['data'] as List).cast<Map<String, dynamic>>();
      if (mounted) {
        setState(() => _regencies = list.map((e) => {'code': e['code'] as String, 'name': e['name'] as String}).toList());
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _nickNameCtrl.dispose();
    _placeOfBirthCtrl.dispose();
    _phoneCtrl.dispose();
    _alamatCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(now.year - 20),
      firstDate: DateTime(1940),
      lastDate: now,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dateOfBirth = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AppAuthProvider>();
    final ok = await auth.updateProfile(
      displayName: _nameCtrl.text.trim().isNotEmpty ? _nameCtrl.text.trim() : null,
      nickName: _nickNameCtrl.text.trim().isNotEmpty ? _nickNameCtrl.text.trim() : null,
      placeOfBirth: _placeOfBirthCtrl.text.trim().isNotEmpty ? _placeOfBirthCtrl.text.trim() : null,
      dateOfBirth: _dateOfBirth,
      phoneNumber: _phoneCtrl.text.trim().isNotEmpty ? _phoneCtrl.text.trim() : null,
      alamat: _alamatCtrl.text.trim().isNotEmpty ? _alamatCtrl.text.trim() : null,
      gender: _selectedGender,
      provinsi: _selectedProvinsi,
      district: _selectedDistrict,
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

              _buildField(
                controller: _nameCtrl,
                label: 'Nama Lengkap',
                hint: 'Masukkan nama lengkap',
                icon: Icons.person_outline_rounded,
              ),
              const SizedBox(height: 14),

              _buildField(
                controller: _nickNameCtrl,
                label: 'Nama Panggilan',
                hint: 'Contoh: Budi',
                icon: Icons.badge_outlined,
              ),
              const SizedBox(height: 14),

              _buildField(
                controller: _phoneCtrl,
                label: 'No. HP / WA (Info Kontak)',
                hint: 'Contoh: 08123456789',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  'Untuk menggunakan nomor HP sebagai metode login, gunakan menu "Metode Login Terhubung" di halaman profil.',
                  style: GoogleFonts.nunito(
                    fontSize: 11,
                    color: AppColors.textLight,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              _buildGenderPicker(),
              const SizedBox(height: 28),

              _SectionLabel(label: 'Data Kelahiran'),
              const SizedBox(height: 12),

              _buildField(
                controller: _placeOfBirthCtrl,
                label: 'Tempat Lahir',
                hint: 'Contoh: Bandung',
                icon: Icons.location_on_outlined,
              ),
              const SizedBox(height: 14),

              _buildDatePicker(),
              const SizedBox(height: 28),

              _SectionLabel(label: 'Alamat'),
              const SizedBox(height: 12),

              _buildLocationPicker(
                label: 'Provinsi',
                value: _selectedProvinsi,
                hint: 'Pilih provinsi',
                icon: Icons.map_outlined,
                items: _provinces.map((e) => e['name']!).toList(),
                onSelected: (val) {
                  setState(() {
                    _selectedProvinsi = val;
                    _selectedDistrict = null;
                    _regencies = [];
                  });
                  _loadRegencies(val);
                },
              ),
              const SizedBox(height: 14),

              _buildLocationPicker(
                label: 'Kota / Kabupaten',
                value: _selectedDistrict,
                hint: _selectedProvinsi == null ? 'Pilih provinsi dulu' : 'Pilih kota / kabupaten',
                icon: Icons.location_city_outlined,
                items: _regencies.map((e) => e['name']!).toList(),
                enabled: _selectedProvinsi != null,
                onSelected: (val) => setState(() => _selectedDistrict = val),
              ),
              const SizedBox(height: 14),

              _buildField(
                controller: _alamatCtrl,
                label: 'Alamat Lengkap',
                hint: 'Jalan, nomor rumah, RT/RW, dll.',
                icon: Icons.home_outlined,
                maxLines: 3,
              ),
              const SizedBox(height: 32),

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

  Widget _buildDatePicker() {
    final label = _dateOfBirth != null
        ? DateFormat('dd MMMM yyyy', 'id').format(_dateOfBirth!)
        : 'Pilih tanggal lahir';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tanggal Lahir',
          style: GoogleFonts.nunito(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textMedium,
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: _pickDate,
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined,
                    size: 20, color: AppColors.textLight),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    color: _dateOfBirth != null
                        ? AppColors.textDark
                        : AppColors.textLight,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
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
          keyboardType: keyboardType,
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

  Widget _buildLocationPicker({
    required String label,
    required String? value,
    required String hint,
    required IconData icon,
    required List<String> items,
    required void Function(String) onSelected,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textMedium)),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: enabled && items.isNotEmpty
              ? () => _showLocationSheet(label: label, items: items, selected: value, onSelected: onSelected)
              : null,
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: enabled ? AppColors.surface : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Icon(icon, size: 20, color: AppColors.textLight),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    value ?? hint,
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      color: value != null ? AppColors.textDark : AppColors.textLight,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (enabled) const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: AppColors.textLight),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showLocationSheet({
    required String label,
    required List<String> items,
    required String? selected,
    required void Function(String) onSelected,
  }) {
    final searchCtrl = TextEditingController();
    List<String> filtered = List.from(items);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            void onSearch(String q) {
              setSheetState(() {
                filtered = q.isEmpty
                    ? List.from(items)
                    : items.where((e) => e.toLowerCase().contains(q.toLowerCase())).toList();
              });
            }

            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.7,
              maxChildSize: 0.92,
              builder: (_, scrollCtrl) => Column(
                children: [
                  const SizedBox(height: 12),
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(label, style: GoogleFonts.comfortaa(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: searchCtrl,
                      onChanged: onSearch,
                      autofocus: true,
                      style: GoogleFonts.nunito(fontSize: 14, color: AppColors.textDark),
                      decoration: InputDecoration(
                        hintText: 'Cari...',
                        hintStyle: GoogleFonts.nunito(fontSize: 14, color: AppColors.textLight),
                        prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.textLight),
                        filled: true,
                        fillColor: AppColors.surfaceVariant,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollCtrl,
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final item = filtered[i];
                        final isSelected = item == selected;
                        return ListTile(
                          title: Text(item, style: GoogleFonts.nunito(fontSize: 14, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500, color: isSelected ? AppColors.primary : AppColors.textDark)),
                          trailing: isSelected ? const Icon(Icons.check_rounded, color: AppColors.primary, size: 20) : null,
                          onTap: () {
                            onSelected(item);
                            Navigator.pop(ctx);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
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

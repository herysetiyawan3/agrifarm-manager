import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/storage_service.dart';
import 'auth_providers.dart';
import '../data/user_model.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  bool _isEditing = false;
  bool _isUploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initControllers();
    });
  }

  void _initControllers() {
    final profile = ref.read(userProfileProvider).value;
    if (profile != null) {
      _nameController.text = profile.displayName;
      _phoneController.text = profile.phoneNumber;
      _addressController.text = profile.address;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage(AppUser profile) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 400,
    );

    if (pickedFile == null) return;

    setState(() {
      _isUploadingPhoto = true;
    });

    try {
      final downloadUrl = await StorageService.uploadImage(
        localPath: pickedFile.path,
        folder: 'profiles',
        fileName: '${profile.uid}.jpg',
      );

      final updatedProfile = profile.copyWith(photoUrl: downloadUrl);
      await ref.read(authControllerProvider.notifier).updateProfile(updatedProfile);
      
      // Refresh user profile
      ref.invalidate(userProfileProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto profil berhasil diperbarui!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload gagal: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingPhoto = false;
        });
      }
    }
  }

  void _saveProfile(AppUser profile) async {
    if (!_formKey.currentState!.validate()) return;

    final updated = profile.copyWith(
      displayName: _nameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      address: _addressController.text.trim(),
    );

    await ref.read(authControllerProvider.notifier).updateProfile(updated);
    
    // Refresh user profile
    ref.invalidate(userProfileProvider);

    setState(() {
      _isEditing = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil berhasil disimpan!'), backgroundColor: Colors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(userProfileProvider);
    final authState = ref.watch(authControllerProvider);
    final isDarkMode = ref.watch(isDarkModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Saya'),
        actions: [
          if (profileState.value != null && !_isEditing)
            IconButton(
              icon: const Icon(Icons.edit_note),
              onPressed: () {
                _initControllers();
                setState(() {
                  _isEditing = true;
                });
              },
            ),
        ],
      ),
      body: profileState.when(
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('Profil tidak ditemukan.'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Profile picture upload
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 64,
                          backgroundColor: Colors.green[100],
                          backgroundImage: profile.photoUrl.isNotEmpty
                              ? NetworkImage(profile.photoUrl)
                              : null,
                          child: profile.photoUrl.isEmpty
                              ? Icon(Icons.person, size: 64, color: Colors.green[800])
                              : null,
                        ),
                        if (_isUploadingPhoto)
                          const Positioned.fill(
                            child: CircleAvatar(
                              radius: 64,
                              backgroundColor: Colors.black45,
                              child: CircularProgressIndicator(color: Colors.white),
                            ),
                          ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () => _pickAndUploadImage(profile),
                            child: const CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.orange,
                              child: Icon(Icons.camera_alt, color: Colors.white, size: 18),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      'Peran: ${profile.role == 'Owner' ? 'Pemilik Lahan' : profile.role == 'Mandor' ? 'Mandor Lapangan' : 'Pekerja Kebun'}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange, fontSize: 15),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Fields
                  TextFormField(
                    controller: _nameController,
                    enabled: _isEditing,
                    decoration: const InputDecoration(
                      labelText: 'Nama Lengkap',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Nama wajib diisi';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _phoneController,
                    enabled: _isEditing,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Nomor HP',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Nomor HP wajib diisi';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    initialValue: profile.email,
                    enabled: false, // Email cannot be changed
                    decoration: const InputDecoration(
                      labelText: 'Email (Tidak dapat diubah)',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _addressController,
                    enabled: _isEditing,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Alamat Lahan/Rumah',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Edit Actions
                  if (_isEditing)
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _isEditing = false;
                              });
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Batal'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: authState.isLoading ? null : () => _saveProfile(profile),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[800],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Simpan'),
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 12),

                  // App Settings (Theme & Logout)
                  ListTile(
                    leading: const Icon(Icons.dark_mode_outlined),
                    title: const Text('Mode Gelap (Dark Mode)'),
                    trailing: Switch(
                      value: isDarkMode,
                      onChanged: (val) {
                        ref.read(isDarkModeProvider.notifier).state = val;
                      },
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text('Keluar Akun (Log Out)', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    onTap: () async {
                      await ref.read(authControllerProvider.notifier).logout();
                      if (mounted) {
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

import 'dart:convert';

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:musify/services/profile_customization_service.dart';
import 'package:musify/utilities/playlist_image_picker.dart';

class ProfileCustomizationPage extends StatefulWidget {
  const ProfileCustomizationPage({super.key});

  @override
  State<ProfileCustomizationPage> createState() =>
      _ProfileCustomizationPageState();
}

class _ProfileCustomizationPageState extends State<ProfileCustomizationPage> {
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  String? _avatar;
  String _accent = 'electric-violet';
  bool _saving = false;

  static const _accentOptions = <String, Color>{
    'electric-violet': Color(0xff9d7cff),
    'cyber-blue': Color(0xff4cc9ff),
    'signal-green': Color(0xff7dffb2),
    'infrared': Color(0xffff6f91),
  };

  @override
  void initState() {
    super.initState();
    final profile = KryptProfileCustomizationService.instance;
    _nameController.text = profile.displayName;
    _bioController.text = profile.bio;
    _avatar = profile.avatar;
    _accent = profile.accent;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final image = await pickImage();
    if (image != null && mounted) setState(() => _avatar = image);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await KryptProfileCustomizationService.instance.save(
      displayName: _nameController.text,
      bio: _bioController.text,
      avatar: _avatar,
      accent: _accent,
    );
    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('KRYPT profile updated')));
      Navigator.of(context).pop();
    }
  }

  Widget _avatarView() {
    if (_avatar == null || !_avatar!.startsWith('data:')) {
      return const Icon(FluentIcons.person_24_regular, size: 42);
    }
    try {
      return ClipOval(
        child: Image.memory(
          base64Decode(_avatar!.split(',').last),
          width: 104,
          height: 104,
          fit: BoxFit.cover,
        ),
      );
    } catch (_) {
      return const Icon(FluentIcons.person_24_regular, size: 42);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Customize profile')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 54,
                  backgroundColor: _accentOptions[_accent]!.withValues(
                    alpha: .2,
                  ),
                  child: _avatarView(),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: IconButton.filled(
                    onPressed: _pickAvatar,
                    icon: const Icon(FluentIcons.camera_add_24_regular),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _nameController,
            maxLength: 32,
            decoration: const InputDecoration(
              labelText: 'Display name',
              hintText: 'Your KRYPT identity',
              prefixIcon: Icon(FluentIcons.person_24_regular),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _bioController,
            maxLength: 120,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Bio',
              hintText: 'Tell the frequency who you are',
              prefixIcon: Icon(FluentIcons.text_description_24_regular),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Profile accent',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            children: _accentOptions.entries.map((entry) {
              final selected = entry.key == _accent;
              return ChoiceChip(
                label: Text(entry.key.replaceAll('-', ' ')),
                selected: selected,
                avatar: CircleAvatar(backgroundColor: entry.value, radius: 8),
                onSelected: (_) => setState(() => _accent = entry.key),
                selectedColor: entry.value.withValues(alpha: .3),
              );
            }).toList(),
          ),
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(FluentIcons.save_24_regular),
            label: const Text('Save profile'),
          ),
          const SizedBox(height: 8),
          Text(
            'Your custom profile stays on this device. Google account details remain available for sign-in and sync.',
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

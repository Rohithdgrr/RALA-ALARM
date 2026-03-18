import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AlarmWallpaperService {
  static const String _wallpaperKey = 'alarm_wallpaper_path';
  static const String _wallpaperTypeKey = 'alarm_wallpaper_type';

  static Future<void> setWallpaper(String path, WallpaperType type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_wallpaperKey, path);
    await prefs.setString(_wallpaperTypeKey, type.name);
  }

  static Future<AlarmWallpaper?> getWallpaper() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString(_wallpaperKey);
    final typeStr = prefs.getString(_wallpaperTypeKey);
    
    if (path == null || path.isEmpty) return null;
    
    return AlarmWallpaper(
      path: path,
      type: WallpaperType.values.firstWhere(
        (t) => t.name == typeStr,
        orElse: () => WallpaperType.solid,
      ),
    );
  }

  static Future<void> clearWallpaper() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_wallpaperKey);
    await prefs.remove(_wallpaperTypeKey);
  }

  static Future<WallpaperResult?> showWallpaperPicker(BuildContext context) async {
    return showModalBottomSheet<WallpaperResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _WallpaperPickerSheet(),
    );
  }
}

enum WallpaperType {
  solid,
  gradient,
  image,
  animated,
}

class AlarmWallpaper {
  final String path;
  final WallpaperType type;

  AlarmWallpaper({required this.path, required this.type});
}

class WallpaperResult {
  final String path;
  final WallpaperType type;
  final String name;

  WallpaperResult({
    required this.path,
    required this.type,
    required this.name,
  });
}

class _WallpaperPickerSheet extends StatefulWidget {
  const _WallpaperPickerSheet();

  @override
  State<_WallpaperPickerSheet> createState() => _WallpaperPickerSheetState();
}

class _WallpaperPickerSheetState extends State<_WallpaperPickerSheet> {
  WallpaperType _selectedType = WallpaperType.gradient;
  Color _selectedColor = Colors.white;
  List<Color> _selectedGradient = const [Color(0xFF667eea), Color(0xFF764ba2)];

  final List<Map<String, dynamic>> _presetGradients = [
    {'name': 'Sunrise', 'colors': [const Color(0xFFf093fb), const Color(0xFFf5576c)]},
    {'name': 'Ocean', 'colors': [const Color(0xFF4facfe), const Color(0xFF00f2fe)]},
    {'name': 'Forest', 'colors': [const Color(0xFF43e97b), const Color(0xFF38f9d7)]},
    {'name': 'Sunset', 'colors': [const Color(0xFFfa709a), const Color(0xFFfee140)]},
    {'name': 'Purple Dream', 'colors': [const Color(0xFF30cfd0), const Color(0xFF330867)]},
    {'name': 'Peach', 'colors': [const Color(0xFFffecd2), const Color(0xFFfcb69f)]},
    {'name': 'Night Sky', 'colors': [const Color(0xFF0f0c29), const Color(0xFF302b63)]},
    {'name': 'Rose Gold', 'colors': [const Color(0xFFf4c4f3), const Color(0xFFfc67fa)]},
    {'name': 'Mint', 'colors': [const Color(0xFFa8edea), const Color(0xFFfed6e3)]},
    {'name': 'Fire', 'colors': [const Color(0xFFff6b6b), const Color(0xFFFF8E53)]},
  ];

  final List<Color> _presetColors = [
    Colors.white,
    Colors.black,
    const Color(0xFFF5F5F5),
    const Color(0xFFE8F5E9),
    const Color(0xFFE3F2FD),
    const Color(0xFFFFF3E0),
    const Color(0xFFFCE4EC),
    const Color(0xFFF3E5F5),
    const Color(0xFFE0F7FA),
    const Color(0xFFF1F8E9),
  ];

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );
      
      if (result != null && result.files.isNotEmpty) {
        final path = result.files.first.path;
        if (path != null && mounted) {
          Navigator.pop(
            context,
            WallpaperResult(
              path: path,
              type: WallpaperType.image,
              name: result.files.first.name,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not pick image')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Title
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Text(
              'Alarm Wallpaper',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          
          // Type selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildTypeChip('Solid', WallpaperType.solid, Icons.color_lens),
                const SizedBox(width: 8),
                _buildTypeChip('Gradient', WallpaperType.gradient, Icons.gradient),
                const SizedBox(width: 8),
                _buildTypeChip('Image', WallpaperType.image, Icons.image),
              ],
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_selectedType == WallpaperType.solid) ...[
                    const Text(
                      'Background Color',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: _presetColors.map((color) {
                        final isSelected = _selectedColor.value == color.value;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedColor = color),
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected 
                                    ? const Color(0xFF4A90D9) 
                                    : Colors.grey.shade300,
                                width: isSelected ? 3 : 1,
                              ),
                              boxShadow: color == Colors.white
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 4,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: isSelected
                                ? Icon(
                                    Icons.check,
                                    color: color == Colors.white || color == const Color(0xFFF5F5F5)
                                        ? Colors.black
                                        : Colors.white,
                                    size: 20,
                                  )
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                  
                  if (_selectedType == WallpaperType.gradient) ...[
                    const Text(
                      'Gradient Presets',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.5,
                      ),
                      itemCount: _presetGradients.length,
                      itemBuilder: (context, index) {
                        final preset = _presetGradients[index];
                        final colors = preset['colors'] as List<Color>;
                        final isSelected = _selectedGradient[0].value == colors[0].value;
                        
                        return GestureDetector(
                          onTap: () => setState(() => _selectedGradient = colors),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: colors,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected 
                                    ? const Color(0xFF4A90D9) 
                                    : Colors.transparent,
                                width: 3,
                              ),
                            ),
                            child: Stack(
                              children: [
                                Positioned(
                                  bottom: 8,
                                  left: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black26,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      preset['name'],
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  const Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Icon(
                                      Icons.check_circle,
                                      color: Colors.white,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                  
                  if (_selectedType == WallpaperType.image) ...[
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.grey.shade300,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF4A90D9), Color(0xFF7B68EE)],
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.add_photo_alternate,
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Choose from Gallery',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Select an image for alarm screen',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 24),
                  
                  // Preview
                  const Text(
                    'Preview',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  _buildPreview(),
                  
                  const SizedBox(height: 24),
                  
                  // Apply button
                  SizedBox(
                    width: double.infinity,
                    child: GestureDetector(
                      onTap: () {
                        if (_selectedType == WallpaperType.image) {
                          _pickImage();
                        } else {
                          final name = _selectedType == WallpaperType.solid
                              ? 'Solid ${_selectedColor.value.toRadixString(16).substring(2)}'
                              : 'Gradient ${_selectedGradient[0].value.toRadixString(16).substring(2)}';
                          
                          Navigator.pop(
                            context,
                            WallpaperResult(
                              path: _selectedType == WallpaperType.solid
                                  ? _selectedColor.value.toString()
                                  : '${_selectedGradient[0].value},${_selectedGradient[1].value}',
                              type: _selectedType,
                              name: name,
                            ),
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF4A90D9), Color(0xFF7B68EE)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF4A90D9).withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          _selectedType == WallpaperType.image 
                              ? 'Choose Image' 
                              : 'Apply Wallpaper',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
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

  Widget _buildTypeChip(String label, WallpaperType type, IconData icon) {
    final isSelected = _selectedType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedType = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [Color(0xFF4A90D9), Color(0xFF7B68EE)],
                  )
                : null,
            color: isSelected ? null : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : Colors.black54,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreview() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        gradient: _selectedType == WallpaperType.gradient
            ? LinearGradient(colors: _selectedGradient)
            : null,
        color: _selectedType == WallpaperType.solid ? _selectedColor : null,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.alarm,
              color: Colors.white,
              size: 32,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                '7:30 AM',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

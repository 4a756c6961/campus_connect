import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:campus_connect/models/selected_gif.dart';
import 'package:campus_connect/providers/feed_provider.dart';
import 'package:campus_connect/utils/tag_utils.dart';

import 'package:giphy_flutter_sdk/dto/giphy_media.dart';
import 'package:giphy_flutter_sdk/giphy_dialog.dart';

class PostInput extends StatefulWidget {
  final VoidCallback? onPostCreated;

  const PostInput({super.key, this.onPostCreated});

  @override
  State<PostInput> createState() => _PostInputState();
}

class _PostInputState extends State<PostInput>
    implements GiphyMediaSelectionListener {
  final TextEditingController _tagController = TextEditingController();
  final List<String> _selectedTags = [];

  final ImagePicker _imagePicker = ImagePicker();

  Uint8List? _selectedImageBytes;
  bool _isPickingImage = false;

  @override
  void initState() {
    super.initState();
    GiphyDialog.instance.addListener(this);
  }

  @override
  void dispose() {
    GiphyDialog.instance.removeListener(this);
    _tagController.dispose();
    super.dispose();
  }

  void _openGiphyDialog() {
    GiphyDialog.instance.show();
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_isPickingImage) return;

    setState(() {
      _isPickingImage = true;
    });

    try {
      final image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1600,
      );

      if (image == null) return;

      final imageBytes = await image.readAsBytes();

      if (!mounted) return;

      context.read<FeedProvider>().removeSelectedGif();

      setState(() {
        _selectedImageBytes = imageBytes;
      });
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Das Bild konnte nicht ausgewählt werden: $error'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPickingImage = false;
        });
      }
    }
  }

  void _removeSelectedImage() {
    setState(() {
      _selectedImageBytes = null;
    });
  }

  void _addTag() {
    final tag = normalizeTag(_tagController.text);

    if (tag.isEmpty) return;

    if (_selectedTags.contains(tag)) {
      _tagController.clear();
      return;
    }

    if (_selectedTags.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Du kannst maximal 5 Tags hinzufügen.')),
      );
      return;
    }

    setState(() {
      _selectedTags.add(tag);
      _tagController.clear();
    });
  }

  void _removeTag(String tag) {
    setState(() {
      _selectedTags.remove(tag);
    });
  }

  @override
  void onMediaSelect(GiphyMedia media) {
    final gifUrl = media.images.original?.gifUrl;

    if (gifUrl == null || gifUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Das ausgewählte GIF konnte nicht geladen werden.'),
        ),
      );
      return;
    }

    _removeSelectedImage();

    context.read<FeedProvider>().setSelectedGif(
      SelectedGif(id: media.id, url: gifUrl, title: media.title ?? 'GIPHY GIF'),
    );
  }

  @override
  void onDismiss() {}

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FeedProvider>();
    final selectedGif = provider.selectedGif;

    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              controller: provider.controller,
              onTapOutside: (_) {
                FocusScope.of(context).unfocus();
              },
              maxLines: null,
              decoration: const InputDecoration(
                hintText: 'Was möchtest du teilen?',
                border: OutlineInputBorder(),
              ),
            ),

            if (_selectedImageBytes != null) ...[
              const SizedBox(height: 12),
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      _selectedImageBytes!,
                      width: double.infinity,
                      height: 280,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: CircleAvatar(
                      backgroundColor: Colors.black54,
                      child: IconButton(
                        tooltip: 'Bild entfernen',
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed:
                            provider.isSending ? null : _removeSelectedImage,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            if (selectedGif != null) ...[
              const SizedBox(height: 12),
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      selectedGif.url,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: CircleAvatar(
                      backgroundColor: Colors.black54,
                      child: IconButton(
                        tooltip: 'GIF entfernen',
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed:
                            provider.isSending
                                ? null
                                : provider.removeSelectedGif,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Powered by GIPHY',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ),
            ],

            const SizedBox(height: 12),

            TextField(
              controller: _tagController,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _addTag(),
              onTapOutside: (_) {
                FocusScope.of(context).unfocus();
              },
              decoration: InputDecoration(
                labelText: 'Tags hinzufügen',
                hintText: 'z. B. gruppenarbeit oder lerngruppe gesucht',
                prefixIcon: const Icon(Icons.tag),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addTag,
                ),
                border: const OutlineInputBorder(),
              ),
            ),

            if (_selectedTags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      _selectedTags.map((tag) {
                        return InputChip(
                          label: Text('#$tag'),
                          onDeleted: () => _removeTag(tag),
                        );
                      }).toList(),
                ),
              ),
            ],

            const SizedBox(height: 12),

            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: provider.isSending ? null : _openGiphyDialog,
                  icon: const Icon(Icons.gif_box_outlined),
                  label: const Text('GIF'),
                ),

                const SizedBox(width: 8),

                PopupMenuButton<ImageSource>(
                  tooltip: 'Foto hinzufügen',
                  enabled: !provider.isSending && !_isPickingImage,
                  onSelected: _pickImage,
                  itemBuilder:
                      (context) => const [
                        PopupMenuItem(
                          value: ImageSource.camera,
                          child: ListTile(
                            leading: Icon(Icons.camera_alt_outlined),
                            title: Text('Foto aufnehmen'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        PopupMenuItem(
                          value: ImageSource.gallery,
                          child: ListTile(
                            leading: Icon(Icons.photo_library_outlined),
                            title: Text('Aus Galerie auswählen'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                  child: AbsorbPointer(
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon:
                          _isPickingImage
                              ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : const Icon(Icons.add_a_photo_outlined),
                      label: const Text('Foto'),
                    ),
                  ),
                ),

                const Spacer(),

                ElevatedButton.icon(
                  onPressed:
                      provider.isSending
                          ? null
                          : () async {
                            final error = await provider.sendPost(
                              tags: normalizeTags(_selectedTags),
                              imageBytes: _selectedImageBytes,
                            );

                            if (!context.mounted) return;

                            if (error != null) {
                              ScaffoldMessenger.of(
                                context,
                              ).showSnackBar(SnackBar(content: Text(error)));
                              return;
                            }

                            FocusScope.of(context).unfocus();

                            setState(() {
                              _selectedImageBytes = null;
                              _selectedTags.clear();
                            });

                            widget.onPostCreated?.call();
                          },
                  icon:
                      provider.isSending
                          ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Icon(Icons.send),
                  label: const Text('Posten'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

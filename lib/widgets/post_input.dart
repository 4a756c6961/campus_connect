import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:campus_connect/models/selected_gif.dart';
import 'package:campus_connect/providers/feed_provider.dart';

import 'package:giphy_flutter_sdk/dto/giphy_media.dart';
import 'package:giphy_flutter_sdk/giphy_dialog.dart';

class PostInput extends StatefulWidget {
  const PostInput({super.key});

  @override
  State<PostInput> createState() => _PostInputState();
}

class _PostInputState extends State<PostInput>
    implements GiphyMediaSelectionListener {
  @override
  void initState() {
    super.initState();
    GiphyDialog.instance.addListener(this);
  }

  void _openGiphyDialog() {
    GiphyDialog.instance.show();
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

    context.read<FeedProvider>().setSelectedGif(
      SelectedGif(id: media.id, url: gifUrl, title: media.title ?? 'GIPHY GIF'),
    );
  }

  @override
  void onDismiss() {
  }

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
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: provider.removeSelectedGif,
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

            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: provider.isSending ? null : _openGiphyDialog,
                  icon: const Icon(Icons.gif_box_outlined),
                  label: const Text('GIF'),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed:
                      provider.isSending
                          ? null
                          : () async {
                            final error = await provider.sendPost();

                            if (!context.mounted) return;

                            if (error != null) {
                              ScaffoldMessenger.of(
                                context,
                              ).showSnackBar(SnackBar(content: Text(error)));
                            }
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

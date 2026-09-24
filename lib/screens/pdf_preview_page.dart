import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart' as pdfx;
import 'package:share_plus/share_plus.dart';

import '../l10n/app_localizations.dart';

const double _thumbRailWidth = 92;
const double _thumbItemHeight = 118;
const double _thumbTargetWidth = 64;

/// Toont een PDF-bestand direct in de app, met een miniaturenbalk om snel
/// tussen pagina's te wisselen en een knop om te delen.
class PdfPreviewPage extends StatefulWidget {
  final String path;
  final String title;
  final String? shareText;

  const PdfPreviewPage({
    super.key,
    required this.path,
    required this.title,
    this.shareText,
  });

  @override
  State<PdfPreviewPage> createState() => _PdfPreviewPageState();
}

class _PdfPreviewPageState extends State<PdfPreviewPage> {
  late final pdfx.PdfControllerPinch _controller;
  final _railScrollController = ScrollController();
  pdfx.PdfDocument? _thumbDoc;
  _PdfThumbnailGenerator? _thumbGen;
  int? _pageCount;

  @override
  void initState() {
    super.initState();
    _controller = pdfx.PdfControllerPinch(
      document: pdfx.PdfDocument.openFile(widget.path),
    );
    _controller.pageListenable.addListener(_onPageChanged);
    _loadThumbDoc();
  }

  Future<void> _loadThumbDoc() async {
    try {
      // Eigen documenthandle voor de miniaturen, zodat het renderen ervan
      // niet conflicteert met het renderen van de hoofdweergave.
      final doc = await pdfx.PdfDocument.openFile(widget.path);
      if (!mounted) {
        await doc.close();
        return;
      }
      setState(() {
        _thumbDoc = doc;
        _pageCount = doc.pagesCount;
        _thumbGen = _PdfThumbnailGenerator(doc);
      });
    } catch (_) {}
  }

  Future<void> _saveToFile() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final bytes = await File(widget.path).readAsBytes();
      var fileName = widget.title.trim();
      if (fileName.isEmpty) fileName = 'document';
      if (!fileName.toLowerCase().endsWith('.pdf')) {
        fileName = '$fileName.pdf';
      }
      final uri = await FilePicker.saveFile(
        fileName: fileName,
        bytes: bytes,
        mimeType: 'application/pdf',
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
      );
      if (uri == null || !mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(l10n.pdfSaved)));
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(l10n.pdfSaveFailed(e))));
    }
  }

  void _onPageChanged() {
    final count = _pageCount;
    if (count == null || count <= 0 || !_railScrollController.hasClients) {
      return;
    }
    final page = _controller.pageListenable.value;
    // Houd de geselecteerde miniatuur ongeveer in het midden van de balk.
    final target = (_thumbItemHeight * (page - 1)) - (_thumbItemHeight * 1.5);
    final max = _railScrollController.position.maxScrollExtent;
    _railScrollController.animateTo(
      target.clamp(0, max).toDouble(),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _controller.pageListenable.removeListener(_onPageChanged);
    _controller.dispose();
    _thumbDoc?.close();
    _railScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pageCount = _pageCount;
    final thumbGen = _thumbGen;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_alt),
            tooltip: AppLocalizations.of(context).saveToFile,
            onPressed: _saveToFile,
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () async {
              try {
                await Share.shareXFiles([XFile(widget.path)],
                    text: widget.shareText);
              } catch (_) {}
            },
          ),
        ],
      ),
      body: Row(
        children: [
          SizedBox(
            width: _thumbRailWidth,
            child: Container(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: pageCount == null || thumbGen == null
                  ? const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : ValueListenableBuilder<int>(
                      valueListenable: _controller.pageListenable,
                      builder: (context, currentPage, _) => ListView.builder(
                        controller: _railScrollController,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: pageCount,
                        itemExtent: _thumbItemHeight,
                        itemBuilder: (context, index) {
                          final pageNumber = index + 1;
                          return _PdfThumbnailTile(
                            pageNumber: pageNumber,
                            selected: pageNumber == currentPage,
                            generator: thumbGen,
                            onTap: () => _controller.animateToPage(
                              pageNumber: pageNumber,
                              duration: const Duration(milliseconds: 150),
                              curve: Curves.easeInOut,
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: pdfx.PdfViewPinch(controller: _controller)),
        ],
      ),
    );
  }
}

class _PdfThumbnailTile extends StatelessWidget {
  final int pageNumber;
  final bool selected;
  final _PdfThumbnailGenerator generator;
  final VoidCallback onTap;

  const _PdfThumbnailTile({
    required this.pageNumber,
    required this.selected,
    required this.generator,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(
            color: selected ? primary : Colors.grey.shade400,
            width: selected ? 2 : 1,
          ),
          color: Colors.white,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: FutureBuilder<Uint8List?>(
                future: generator.thumbFor(pageNumber),
                builder: (context, snapshot) {
                  final bytes = snapshot.data;
                  if (bytes == null) {
                    return const Center(
                      child: SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 1.5),
                      ),
                    );
                  }
                  return Image.memory(bytes, fit: BoxFit.contain);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                '$pageNumber',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  color: selected ? primary : Colors.grey.shade700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Rendert PDF-paginas lazy naar kleine miniaturen en cachet het resultaat.
/// De renderer kan op Android maar één pagina tegelijk verwerken, daarom
/// worden aanvragen serieel (op volgorde van opvraging) afgehandeld.
class _PdfThumbnailGenerator {
  _PdfThumbnailGenerator(this._document);

  final pdfx.PdfDocument _document;
  final Map<int, Uint8List?> _cache = {};
  final Map<int, Future<Uint8List?>> _pending = {};
  Future<void> _queue = Future.value();

  Future<Uint8List?> thumbFor(int pageNumber) {
    if (_cache.containsKey(pageNumber)) {
      return SynchronousFuture<Uint8List?>(_cache[pageNumber]);
    }
    final existing = _pending[pageNumber];
    if (existing != null) return existing;

    final completer = Completer<Uint8List?>();
    _pending[pageNumber] = completer.future;
    _queue = _queue.then((_) async {
      if (_document.isClosed) {
        completer.complete(null);
        return;
      }
      try {
        final page = await _document.getPage(pageNumber);
        final ratio = page.height > 0 ? page.width / page.height : 0.75;
        final image = await page.render(
          width: _thumbTargetWidth,
          height: _thumbTargetWidth / ratio,
          format: pdfx.PdfPageImageFormat.jpeg,
          backgroundColor: '#FFFFFF',
        );
        await page.close();
        _cache[pageNumber] = image?.bytes;
        completer.complete(image?.bytes);
      } catch (_) {
        _cache[pageNumber] = null;
        completer.complete(null);
      } finally {
        _pending.remove(pageNumber);
      }
    });
    return completer.future;
  }
}

import 'package:flutter/material.dart';
import 'package:template_app/core/services/downloader/download_service.dart';
import 'package:template_app/core/utilities/logger.dart';
import 'package:template_app/injection/locator.dart';

// ─── Mutable batch-item model ─────────────────────────────────────────────────

class _BatchItem {
  _BatchItem({
    required this.label,
    required this.type,
    required this.url,
    required this.filename,
  });

  final String label;
  final DownloadFileType type;
  final String url;
  final String filename;
  DownloadStatus? status;
}

// ─── Page ─────────────────────────────────────────────────────────────────────

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  static const _tag = 'MainPage';
  final _dl = locator<DownloadService>();

  // single
  DownloadFileType _type = DownloadFileType.image;
  double _singleProgress = 0;
  DownloadStatus? _singleStatus;
  DownloadResult? _singleResult;
  bool _singleBusy = false;

  // batch
  final _batchItems = <_BatchItem>[
    _BatchItem(
      label: 'Foto Alam',
      type: DownloadFileType.image,
      url: 'https://picsum.photos/id/10/1920/1080.jpg',
      filename: 'alam.jpg',
    ),
    _BatchItem(
      label: 'Dokumen PDF',
      type: DownloadFileType.document,
      url: 'https://www.w3.org/WAI/WCAG21/wcag21.pdf',
      filename: 'wcag21.pdf',
    ),
    _BatchItem(
      label: 'Foto Kota',
      type: DownloadFileType.image,
      url: 'https://picsum.photos/id/42/1920/1080.jpg',
      filename: 'kota.jpg',
    ),
  ];
  int _batchOk = 0;
  int _batchFail = 0;
  DownloadBatchResult? _batchResult;
  bool _batchBusy = false;

  static String _urlFor(DownloadFileType t) => switch (t) {
        DownloadFileType.image =>
          'https://picsum.photos/id/20/1920/1080.jpg',
        DownloadFileType.video =>
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
        DownloadFileType.document =>
          'https://journal.unesa.ac.id/index.php/jei/article/download/26405/10085/87963',
      };

  static String _nameFor(DownloadFileType t) => switch (t) {
        DownloadFileType.image => 'foto-sample.jpg',
        DownloadFileType.video => 'elephants-dream.mp4',
        DownloadFileType.document => 'rupiah-menurun.pdf',
      };

  Future<void> _startSingle() async {
    setState(() {
      _singleBusy = true;
      _singleProgress = 0;
      _singleStatus = DownloadStatus.enqueued;
      _singleResult = null;
    });

    final res = await _dl.downloadFile(
      url: _urlFor(_type),
      filename: _nameFor(_type),
      type: _type,
      onProgress: (p) {
        if (!mounted) return;
        setState(() {
          _singleProgress = p;
          _singleStatus = DownloadStatus.running;
        });
      },
      onStatus: (s) {
        if (!mounted) return;
        setState(() => _singleStatus = s);
      },
    );

    if (!mounted) return;
    res.when(
      success: (data) {
        Log.i(data.toJson(), label: _tag);
        setState(() {
          _singleResult = data;
          _singleStatus = DownloadStatus.complete;
          _singleProgress = 1.0;
        });
      },
      failure: (err) {
        Log.e(err.toJson(), label: _tag);
        setState(() => _singleStatus = DownloadStatus.failed);
      },
    );
    if (mounted) setState(() => _singleBusy = false);
  }

  Future<void> _startBatch() async {
    setState(() {
      _batchBusy = true;
      _batchOk = 0;
      _batchFail = 0;
      _batchResult = null;
      for (final it in _batchItems) { it.status = DownloadStatus.enqueued; }
    });

    final res = await _dl.downloadBatch(
      requests: _batchItems
          .map((it) => DownloadFileRequest(
                url: it.url,
                filename: it.filename,
                type: it.type,
              ))
          .toList(),
      onBatchProgress: (ok, fail) {
        if (!mounted) return;
        setState(() {
          _batchOk = ok;
          _batchFail = fail;
        });
      },
    );

    if (!mounted) return;
    res.when(
      success: (data) {
        Log.i(data.toJson(), label: _tag);
        final okNames = data.succeeded.map((r) => r.filename).toSet();
        setState(() {
          _batchResult = data;
          for (final it in _batchItems) {
            it.status = okNames.contains(it.filename)
                ? DownloadStatus.complete
                : DownloadStatus.failed;
          }
        });
      },
      failure: (err) => Log.e(err.toJson(), label: _tag),
    );
    if (mounted) setState(() => _batchBusy = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        titleSpacing: 16,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.indigo.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.cloud_download_rounded,
                  color: Colors.indigo, size: 20),
            ),
            const SizedBox(width: 10),
            const Text(
              'Download Manager',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _SingleCard(
            type: _type,
            url: _urlFor(_type),
            filename: _nameFor(_type),
            progress: _singleProgress,
            status: _singleStatus,
            result: _singleResult,
            isBusy: _singleBusy,
            onTypeChanged: _singleBusy
                ? null
                : (t) => setState(() {
                      _type = t;
                      _singleProgress = 0;
                      _singleStatus = null;
                      _singleResult = null;
                    }),
            onDownload: _singleBusy ? null : _startSingle,
          ),
          const SizedBox(height: 16),
          _BatchCard(
            items: _batchItems,
            succeeded: _batchOk,
            failed: _batchFail,
            result: _batchResult,
            isBusy: _batchBusy,
            onDownload: _batchBusy ? null : _startBatch,
          ),
        ],
      ),
    );
  }
}

// ─── Single Download Card ──────────────────────────────────────────────────────

class _SingleCard extends StatelessWidget {
  const _SingleCard({
    required this.type,
    required this.url,
    required this.filename,
    required this.progress,
    required this.status,
    required this.result,
    required this.isBusy,
    required this.onTypeChanged,
    required this.onDownload,
  });

  final DownloadFileType type;
  final String url;
  final String filename;
  final double progress;
  final DownloadStatus? status;
  final DownloadResult? result;
  final bool isBusy;
  final ValueChanged<DownloadFileType>? onTypeChanged;
  final VoidCallback? onDownload;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Single Download',
      icon: Icons.download_rounded,
      iconColor: Colors.indigo,
      iconBg: Colors.indigo.shade50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            children: DownloadFileType.values.map((t) {
              final selected = t == type;
              return ChoiceChip(
                label: Text(_typeLabel(t)),
                avatar: Icon(_typeIcon(t), size: 15),
                selected: selected,
                onSelected: isBusy ? null : (_) => onTypeChanged?.call(t),
                selectedColor: Colors.indigo.shade100,
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight:
                      selected ? FontWeight.w700 : FontWeight.normal,
                  color: selected ? Colors.indigo : Colors.grey.shade700,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Icon(_typeIcon(type), size: 22, color: Colors.indigo),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        filename,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        url,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (status != null) ...[
            const SizedBox(height: 14),
            _ProgressSection(progress: progress, status: status!),
          ],
          if (result != null) ...[
            const SizedBox(height: 12),
            _ResultTile(result: result!),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: onDownload,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.indigo,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: isBusy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white),
                    )
                  : const Icon(Icons.download_rounded),
              label: Text(isBusy ? 'Mengunduh...' : 'Unduh Sekarang'),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Batch Download Card ───────────────────────────────────────────────────────

class _BatchCard extends StatelessWidget {
  const _BatchCard({
    required this.items,
    required this.succeeded,
    required this.failed,
    required this.result,
    required this.isBusy,
    required this.onDownload,
  });

  final List<_BatchItem> items;
  final int succeeded;
  final int failed;
  final DownloadBatchResult? result;
  final bool isBusy;
  final VoidCallback? onDownload;

  @override
  Widget build(BuildContext context) {
    final total = items.length;
    final done = succeeded + failed;
    final batchProgress = total > 0 ? done / total : 0.0;
    final showProgress = isBusy || done > 0;

    return _SectionCard(
      title: 'Batch Download',
      icon: Icons.layers_rounded,
      iconColor: Colors.teal,
      iconBg: Colors.teal.shade50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...items.map((it) => _BatchItemRow(item: it)),
          if (showProgress) ...[
            const SizedBox(height: 4),
            _BatchProgressBar(
                done: done, total: total, progress: batchProgress),
          ],
          if (result != null) ...[
            const SizedBox(height: 12),
            _BatchResultSummary(result: result!),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: onDownload,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.teal,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: isBusy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white),
                    )
                  : const Icon(Icons.layers_rounded),
              label: Text(
                  isBusy ? 'Mengunduh...' : 'Unduh Semua ($total file)'),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section card shell ────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1),
            ),
            child,
          ],
        ),
      ),
    );
  }
}

// ─── Status badge ──────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final DownloadStatus status;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_statusIcon(status), size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            _statusLabel(status),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Progress bar + status badge ──────────────────────────────────────────────

class _ProgressSection extends StatelessWidget {
  const _ProgressSection({required this.progress, required this.status});
  final double progress;
  final DownloadStatus status;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    final barValue = switch (status) {
      DownloadStatus.enqueued => null,
      DownloadStatus.complete => 1.0,
      _ => progress,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: barValue,
                  minHeight: 10,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '${((barValue ?? 0) * 100).toInt()}%',
              style:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _StatusBadge(status: status),
      ],
    );
  }
}

// ─── Single result tile ───────────────────────────────────────────────────────

class _ResultTile extends StatelessWidget {
  const _ResultTile({required this.result});
  final DownloadResult result;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_rounded,
              color: Colors.green.shade600, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.filename,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13),
                ),
                if (result.filePath != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    result.filePath!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Batch item row ───────────────────────────────────────────────────────────

class _BatchItemRow extends StatelessWidget {
  const _BatchItemRow({required this.item});
  final _BatchItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child:
                Icon(_typeIcon(item.type), size: 18, color: Colors.teal),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13),
                ),
                Text(
                  item.filename,
                  style: TextStyle(
                      fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          if (item.status != null) _StatusBadge(status: item.status!),
        ],
      ),
    );
  }
}

// ─── Batch overall progress bar ───────────────────────────────────────────────

class _BatchProgressBar extends StatelessWidget {
  const _BatchProgressBar({
    required this.done,
    required this.total,
    required this.progress,
  });
  final int done;
  final int total;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progress',
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500),
            ),
            Text(
              '$done / $total file',
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 10,
            backgroundColor: Colors.grey.shade200,
            valueColor:
                const AlwaysStoppedAnimation<Color>(Colors.teal),
          ),
        ),
      ],
    );
  }
}

// ─── Batch result summary ─────────────────────────────────────────────────────

class _BatchResultSummary extends StatelessWidget {
  const _BatchResultSummary({required this.result});
  final DownloadBatchResult result;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            icon: Icons.check_circle_rounded,
            color: Colors.green,
            label: 'Berhasil',
            value: '${result.numSucceeded}',
          ),
          Container(width: 1, height: 40, color: Colors.grey.shade300),
          _StatItem(
            icon: Icons.cancel_rounded,
            color: Colors.red,
            label: 'Gagal',
            value: '${result.numFailed}',
          ),
          Container(width: 1, height: 40, color: Colors.grey.shade300),
          _StatItem(
            icon: Icons.layers_rounded,
            color: Colors.grey.shade600,
            label: 'Total',
            value: '${result.total}',
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.w800, color: color),
        ),
        Text(
          label,
          style:
              TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

IconData _typeIcon(DownloadFileType t) => switch (t) {
      DownloadFileType.image => Icons.image_rounded,
      DownloadFileType.video => Icons.videocam_rounded,
      DownloadFileType.document => Icons.description_rounded,
    };

String _typeLabel(DownloadFileType t) => switch (t) {
      DownloadFileType.image => 'Gambar',
      DownloadFileType.video => 'Video',
      DownloadFileType.document => 'Dokumen',
    };

Color _statusColor(DownloadStatus s) => switch (s) {
      DownloadStatus.enqueued => Colors.grey,
      DownloadStatus.running => Colors.blue,
      DownloadStatus.complete => Colors.green,
      DownloadStatus.notFound => Colors.red,
      DownloadStatus.failed => Colors.red,
      DownloadStatus.canceled => Colors.orange,
      DownloadStatus.paused => Colors.amber.shade700,
      DownloadStatus.waitingToRetry => Colors.purple,
    };

IconData _statusIcon(DownloadStatus s) => switch (s) {
      DownloadStatus.enqueued => Icons.hourglass_empty_rounded,
      DownloadStatus.running => Icons.downloading_rounded,
      DownloadStatus.complete => Icons.check_circle_rounded,
      DownloadStatus.notFound => Icons.search_off_rounded,
      DownloadStatus.failed => Icons.error_rounded,
      DownloadStatus.canceled => Icons.cancel_rounded,
      DownloadStatus.paused => Icons.pause_circle_rounded,
      DownloadStatus.waitingToRetry => Icons.refresh_rounded,
    };

String _statusLabel(DownloadStatus s) => switch (s) {
      DownloadStatus.enqueued => 'Antri',
      DownloadStatus.running => 'Mengunduh',
      DownloadStatus.complete => 'Selesai',
      DownloadStatus.notFound => 'Tidak Ditemukan',
      DownloadStatus.failed => 'Gagal',
      DownloadStatus.canceled => 'Dibatalkan',
      DownloadStatus.paused => 'Dijeda',
      DownloadStatus.waitingToRetry => 'Menunggu Ulang',
    };

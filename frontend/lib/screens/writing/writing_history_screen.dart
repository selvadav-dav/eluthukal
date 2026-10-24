import 'package:flutter/material.dart';
import '../../models/writing_practice_model.dart';
import '../../services/writing_practice_repository.dart';
import '../../widgets/writing_canvas.dart';

class WritingHistoryScreen extends StatefulWidget {
  final String? initialLetter;

  const WritingHistoryScreen({super.key, this.initialLetter});

  @override
  State<WritingHistoryScreen> createState() => _WritingHistoryScreenState();
}

class _WritingHistoryScreenState extends State<WritingHistoryScreen> {
  final WritingPracticeRepository _repo = LocalWritingPracticeRepository();
  List<WritingPractice> _history = [];
  bool _isLoading = true;
  String _selectedFilter = 'அனைத்தும்';

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    final list = await _repo.getPracticeHistory();
    if (mounted) {
      setState(() {
        _history = list;
        _isLoading = false;
      });
    }
  }

  List<WritingPractice> get _filteredList {
    if (widget.initialLetter != null) {
      return _history.where((p) => p.letter == widget.initialLetter).toList();
    }
    if (_selectedFilter == 'உயிர்') {
      return _history.where((p) => p.category == 'uyir').toList();
    } else if (_selectedFilter == 'மெய்') {
      return _history.where((p) => p.category == 'mei').toList();
    } else if (_selectedFilter == 'உயிர்மெய்') {
      return _history.where((p) => p.category == 'uyirmei').toList();
    }
    return _history;
  }

  String _formatDate(DateTime dt) {
    const months = [
      '',
      'ஜனவரி',
      'பிப்ரவரி',
      'மார்ச்',
      'ஏப்ரல்',
      'மே',
      'ஜூன்',
      'ஜூலை',
      'ஆகஸ்ட்',
      'செப்டம்பர்',
      'அக்டோபர்',
      'நவம்பர்',
      'டிசம்பர்'
    ];
    final monthName = months[dt.month];
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final minute = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} $monthName ${dt.year} • $hour:$minute $period';
  }

  void _confirmClearAll() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'பதிவுகளை அழிக்கவா?',
          style: TextStyle(fontFamily: 'Catamaran', fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'அனைத்து கையெழுத்துப் பயிற்சி பதிவுகளும் நீக்கப்படும்.',
          style: TextStyle(fontFamily: 'Catamaran', fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('வேண்டாம்', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B6B),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await _repo.clearHistory();
              _loadHistory();
            },
            child: const Text('ஆம், அழி'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredList;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F7FF),
      appBar: AppBar(
        title: const Text(
          'எழுத்துப் பயிற்சி பதிவுகள்',
          style: TextStyle(
            fontFamily: 'Catamaran',
            fontWeight: FontWeight.w900,
            fontSize: 22,
          ),
        ),
        backgroundColor: const Color(0xFFFF9F1C),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded),
              tooltip: 'பதிவுகளை அழி',
              onPressed: _confirmClearAll,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Column(
                  children: [
                    // Filter Tabs
                    if (widget.initialLetter == null)
                      Container(
                        color: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          'அனைத்தும்',
                          'உயிர்',
                          'மெய்',
                          'உயிர்மெய்',
                        ].map((label) {
                          final isSelected = _selectedFilter == label;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: FilterChip(
                              label: Text(
                                label,
                                style: TextStyle(
                                  fontFamily: 'Catamaran',
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? Colors.white : Colors.black87,
                                ),
                              ),
                              selected: isSelected,
                              selectedColor: const Color(0xFFFF9F1C),
                              backgroundColor: const Color(0xFFF1F5F9),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              onSelected: (_) {
                                setState(() => _selectedFilter = label);
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                // History count banner
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      const Icon(Icons.history_edu_rounded, color: Color(0xFF3A86FF), size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'மொத்தப் பயிற்சிகள்: ${filtered.length}',
                        style: const TextStyle(
                          fontFamily: 'Catamaran',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                ),

                // Records List
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/images/writing.gif',
                                width: 140,
                                height: 140,
                                fit: BoxFit.contain,
                                gaplessPlayback: true,
                                errorBuilder: (context, error, stackTrace) => const Icon(
                                  Icons.edit_note_rounded,
                                  size: 100,
                                  color: Color(0xFFCBD5E1),
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'இன்னும் பயிற்சிகள் எதுவும் இல்லை!',
                                style: TextStyle(
                                  fontFamily: 'Catamaran',
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'எழுதிப் பழகியவுடன் இங்கு பதிவாகும்.',
                                style: TextStyle(
                                  fontFamily: 'Catamaran',
                                  fontSize: 14,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final item = filtered[index];
                            return _buildRecordCard(item);
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
    );
  }

  Widget _buildRecordCard(WritingPractice item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: Color(0xFFFFD166), width: 1.5),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Letter Badge
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF9F1C), Color(0xFFFF6B6B)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF9F1C).withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  item.letter,
                  style: const TextStyle(
                    fontFamily: 'Catamaran',
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Middle Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'எழுத்து: ${item.letter}',
                            style: const TextStyle(
                              fontFamily: 'Catamaran',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0F2FE),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'பயிற்சி #${item.attemptNumber}',
                            style: const TextStyle(
                              fontFamily: 'Catamaran',
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0369A1),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(item.createdAt),
                    style: const TextStyle(
                      fontFamily: 'Catamaran',
                      fontSize: 13,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Status badge
                  Row(
                    children: [
                      const Icon(Icons.stars_rounded, color: Color(0xFFFFD166), size: 18),
                      const SizedBox(width: 4),
                      Text(
                        item.completed ? 'வெற்றிகரமாக முடித்தது' : 'பயிற்சி செய்தது',
                        style: const TextStyle(
                          fontFamily: 'Catamaran',
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Actual Saved Handwriting Preview
            SizedBox(
              width: 80,
              height: 80,
              child: SavedHandwritingPreview(
                strokes: item.strokes,
                ghostLetter: item.letter,
                strokeColor: const Color(0xFF3A86FF),
                strokeWidth: 3.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

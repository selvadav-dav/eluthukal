class VideoItem {
  final String id;
  final String title;
  final String category;
  final String duration;
  final String thumbnailEmoji;
  final String videoUrl;
  final String description;
  final int displayOrder;

  const VideoItem({
    required this.id,
    required this.title,
    required this.category,
    required this.duration,
    required this.thumbnailEmoji,
    required this.videoUrl,
    required this.description,
    this.displayOrder = 0,
  });

  factory VideoItem.fromJson(Map<String, dynamic> json) {
    return VideoItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      category: json['category']?.toString() ?? 'பாடல்',
      duration: json['duration']?.toString() ?? '03:00',
      thumbnailEmoji: json['thumbnail_emoji']?.toString() ?? json['thumbnailEmoji']?.toString() ?? '🎬',
      videoUrl: json['stream_url']?.toString() ?? json['video_url']?.toString() ?? json['videoUrl']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      displayOrder: int.tryParse(json['display_order']?.toString() ?? json['displayOrder']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'duration': duration,
      'thumbnail_emoji': thumbnailEmoji,
      'video_url': videoUrl,
      'description': description,
      'display_order': displayOrder,
    };
  }
}

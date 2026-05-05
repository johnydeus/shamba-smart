import '../models/user_model.dart';

class CommunityReply {
  final String id;
  final String authorId;
  final String authorName;
  final String authorRoleKey;
  final String content;
  final DateTime createdAt;

  const CommunityReply({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.authorRoleKey,
    required this.content,
    required this.createdAt,
  });

  UserRole get role => UserRoleX.fromKey(authorRoleKey);

  factory CommunityReply.fromJson(Map<String, dynamic> j) => CommunityReply(
        id: j['id'] as String,
        authorId: j['authorId'] as String,
        authorName: j['authorName'] as String,
        authorRoleKey: j['authorRoleKey'] as String,
        content: j['content'] as String,
        createdAt: DateTime.parse(j['createdAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'authorId': authorId,
        'authorName': authorName,
        'authorRoleKey': authorRoleKey,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
      };
}

class CommunityPost {
  final String id;
  final String authorId;
  final String authorName;
  final String authorRoleKey;
  final String authorRegion;
  final String topic;
  final String content;
  final String? imageUrl; // Supabase Storage public URL
  final DateTime createdAt;
  List<CommunityReply> replies;
  List<String> likedByIds;

  CommunityPost({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.authorRoleKey,
    required this.authorRegion,
    required this.topic,
    required this.content,
    this.imageUrl,
    required this.createdAt,
    List<CommunityReply>? replies,
    List<String>? likedByIds,
  })  : replies = replies ?? [],
        likedByIds = likedByIds ?? [];

  UserRole get role => UserRoleX.fromKey(authorRoleKey);
  bool isLikedBy(String userId) => likedByIds.contains(userId);

  factory CommunityPost.fromJson(Map<String, dynamic> j) => CommunityPost(
        id: j['id'] as String,
        authorId: j['author_id'] ?? j['authorId'] as String,
        authorName: j['author_name'] ?? j['authorName'] as String,
        authorRoleKey: j['author_role'] ?? j['authorRoleKey'] as String,
        authorRegion: j['author_region'] ?? j['authorRegion'] as String,
        topic: j['topic'] as String,
        content: j['content'] as String,
        imageUrl: j['image_url'] as String?,
        createdAt: DateTime.parse(j['created_at'] ?? j['createdAt'] as String),
        replies: (j['replies'] as List?)
                ?.map((r) =>
                    CommunityReply.fromJson(r as Map<String, dynamic>))
                .toList() ??
            [],
        likedByIds: (j['liked_by_ids'] ?? j['likedByIds'] as List?)
                ?.cast<String>() ??
            [],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'author_id': authorId,
        'author_name': authorName,
        'author_role': authorRoleKey,
        'author_region': authorRegion,
        'topic': topic,
        'content': content,
        if (imageUrl != null) 'image_url': imageUrl,
        'created_at': createdAt.toIso8601String(),
        'replies': replies.map((r) => r.toJson()).toList(),
        'liked_by_ids': likedByIds,
      };
}

// Topic metadata
class PostTopic {
  static const all = [
    {'key': 'zote',       'label': 'Zote',        'emoji': '🌐'},
    {'key': 'mazao',      'label': 'Mazao',        'emoji': '🌿'},
    {'key': 'biashara',   'label': 'Biashara',     'emoji': '💰'},
    {'key': 'ugonjwa',    'label': 'Ugonjwa',      'emoji': '🦠'},
    {'key': 'hewa',       'label': 'Hali ya Hewa', 'emoji': '🌧️'},
    {'key': 'matangazo',  'label': 'Matangazo',    'emoji': '📢'},
    {'key': 'swali',      'label': 'Swali',        'emoji': '❓'},
  ];

  static String emoji(String key) =>
      all.firstWhere((t) => t['key'] == key,
          orElse: () => {'emoji': '💬'})['emoji']!;

  static String label(String key) =>
      all.firstWhere((t) => t['key'] == key,
          orElse: () => {'label': key})['label']!;
}

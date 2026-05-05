import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/community_post.dart';
import '../models/user_model.dart';

class CommunityProvider extends ChangeNotifier {
  List<CommunityPost> _posts = [];
  bool isLoading = false;
  String? error;

  List<CommunityPost> get posts => _posts;

  Future<void> init() async => loadPosts();

  // ── Load posts from Supabase ────────────────────────────────────────────────

  Future<void> loadPosts() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      // Load posts
      final postRows = await Supabase.instance.client
          .from('community_posts')
          .select()
          .order('created_at', ascending: false)
          .limit(100);

      // Load all replies
      final replyRows = await Supabase.instance.client
          .from('community_replies')
          .select()
          .order('created_at');

      // Group replies by post_id
      final replyMap = <String, List<CommunityReply>>{};
      for (final r in replyRows as List) {
        final postId = r['post_id'] as String;
        replyMap.putIfAbsent(postId, () => []).add(CommunityReply(
          id:            r['id'] as String,
          authorId:      r['author_id'] as String,
          authorName:    r['author_name'] as String,
          authorRoleKey: r['author_role'] as String,
          content:       r['content'] as String,
          createdAt:     DateTime.parse(r['created_at'] as String).toLocal(),
        ));
      }

      _posts = (postRows as List).map((p) {
        final id = p['id'] as String;
        return CommunityPost(
          id:           id,
          authorId:     p['author_id'] as String,
          authorName:   p['author_name'] as String,
          authorRoleKey: p['author_role'] as String,
          authorRegion: p['author_region'] as String,
          topic:        p['topic'] as String,
          content:      p['content'] as String,
          createdAt:    DateTime.parse(p['created_at'] as String).toLocal(),
          replies:      replyMap[id] ?? [],
          likedByIds:   (p['liked_by_ids'] as List? ?? []).cast<String>(),
        );
      }).toList();

      error = null;
    } catch (e) {
      error = 'Hitilafu ya mtandao. Angalia intaneti na ujaribu tena.';
      debugPrint('CommunityProvider.loadPosts error: $e');
    }

    isLoading = false;
    notifyListeners();
  }

  // ── Upload image to Supabase Storage ───────────────────────────────────────

  Future<String?> uploadImage(File imageFile) async {
    try {
      final ext  = imageFile.path.split('.').last.toLowerCase();
      final mime = ext == 'png' ? 'image/png' : 'image/jpeg';
      final path = 'posts/${DateTime.now().microsecondsSinceEpoch}.$ext';
      final bytes = await imageFile.readAsBytes();

      await Supabase.instance.client.storage
          .from('community-images')
          .uploadBinary(path, bytes,
              fileOptions: FileOptions(contentType: mime, upsert: false));

      return Supabase.instance.client.storage
          .from('community-images')
          .getPublicUrl(path);
    } catch (e) {
      debugPrint('CommunityProvider.uploadImage error: $e');
      return null; // post without image if upload fails
    }
  }

  // ── Add a new post ──────────────────────────────────────────────────────────

  Future<void> addPost({
    required String authorId,
    required String authorName,
    required UserRole authorRole,
    required String authorRegion,
    required String topic,
    required String content,
    File? imageFile, // optional image attachment
  }) async {
    final id  = DateTime.now().microsecondsSinceEpoch.toString();
    final now = DateTime.now();

    // Upload image first if provided
    String? imageUrl;
    if (imageFile != null) {
      imageUrl = await uploadImage(imageFile);
    }

    // Optimistic update
    _posts.insert(0, CommunityPost(
      id:            id,
      authorId:      authorId,
      authorName:    authorName,
      authorRoleKey: authorRole.key,
      authorRegion:  authorRegion,
      topic:         topic,
      content:       content,
      imageUrl:      imageUrl,
      createdAt:     now,
    ));
    notifyListeners();

    try {
      await Supabase.instance.client.from('community_posts').insert({
        'id':           id,
        'author_id':    authorId,
        'author_name':  authorName,
        'author_role':  authorRole.key,
        'author_region': authorRegion,
        'topic':        topic,
        'content':      content,
        'image_url':    imageUrl,
        'liked_by_ids': <String>[],
      });
    } catch (e) {
      _posts.removeWhere((p) => p.id == id);
      notifyListeners();
      debugPrint('CommunityProvider.addPost error: $e');
      rethrow;
    }
  }

  // ── Add a reply ─────────────────────────────────────────────────────────────

  Future<void> addReply({
    required String postId,
    required String authorId,
    required String authorName,
    required UserRole authorRole,
    required String content,
  }) async {
    final id  = DateTime.now().microsecondsSinceEpoch.toString();
    final now = DateTime.now();
    final reply = CommunityReply(
      id: id, authorId: authorId, authorName: authorName,
      authorRoleKey: authorRole.key, content: content, createdAt: now,
    );

    // Optimistic update
    final idx = _posts.indexWhere((p) => p.id == postId);
    if (idx != -1) {
      _posts[idx].replies.add(reply);
      notifyListeners();
    }

    try {
      await Supabase.instance.client.from('community_replies').insert({
        'id':          id,
        'post_id':     postId,
        'author_id':   authorId,
        'author_name': authorName,
        'author_role': authorRole.key,
        'content':     content,
      });
    } catch (e) {
      // Rollback
      if (idx != -1) {
        _posts[idx].replies.removeWhere((r) => r.id == id);
        notifyListeners();
      }
      debugPrint('CommunityProvider.addReply error: $e');
      rethrow;
    }
  }

  // ── Like / unlike ───────────────────────────────────────────────────────────

  Future<void> toggleLike(String postId, String userId) async {
    final idx = _posts.indexWhere((p) => p.id == postId);
    if (idx == -1) return;
    final post = _posts[idx];

    // Optimistic update
    if (post.likedByIds.contains(userId)) {
      post.likedByIds.remove(userId);
    } else {
      post.likedByIds.add(userId);
    }
    notifyListeners();

    // Persist to Supabase
    try {
      await Supabase.instance.client
          .from('community_posts')
          .update({'liked_by_ids': post.likedByIds})
          .eq('id', postId);
    } catch (e) {
      debugPrint('CommunityProvider.toggleLike error: $e');
    }
  }
}

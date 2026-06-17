import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/utils/image_upload_helper.dart';
import '../models/community_post.dart';
import '../models/user_model.dart';

const _kCachedPosts = 'ss_community_posts_v1';

class CommunityProvider extends ChangeNotifier {
  List<CommunityPost> _posts = [];
  bool isLoading = false;
  String? error;

  List<CommunityPost> get posts => _posts;

  // Offline-first init: load from local cache instantly, then sync in background.
  Future<void> init() async {
    await _loadFromCache();
    // Fire network sync without awaiting — never blocks startup.
    loadPosts().catchError(
      (e) => debugPrint('CommunityProvider background sync error: $e'),
    );
  }

  // ── Load posts from Supabase ────────────────────────────────────────────────

  Future<void> loadPosts() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      // Load posts — 8s timeout so offline never hangs
      final postRows = await Supabase.instance.client
          .from('community_posts')
          .select()
          .order('created_at', ascending: false)
          .limit(100)
          .timeout(const Duration(seconds: 8));

      // Load all replies — 8s timeout
      final replyRows = await Supabase.instance.client
          .from('community_replies')
          .select()
          .order('created_at')
          .timeout(const Duration(seconds: 8));

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
          imageUrl:     p['image_url'] as String?,
          createdAt:    DateTime.parse(p['created_at'] as String).toLocal(),
          replies:      replyMap[id] ?? [],
          likedByIds:   (p['liked_by_ids'] as List? ?? []).cast<String>(),
        );
      }).toList();

      error = null;
      _saveToCache();
    } catch (e) {
      error = _posts.isEmpty
          ? 'Hakuna intaneti. Machapisho ya mwisho yanaonyeshwa.'
          : null;
      debugPrint('CommunityProvider.loadPosts error: $e');
    }

    isLoading = false;
    notifyListeners();
  }

  // ── Local cache ─────────────────────────────────────────────────────────────

  Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kCachedPosts);
      if (raw == null) return;
      final list = jsonDecode(raw) as List;
      _posts = list
          .map((e) => CommunityPost.fromJson(e as Map<String, dynamic>))
          .toList();
      notifyListeners();
    } catch (e) {
      debugPrint('CommunityProvider._loadFromCache error: $e');
    }
  }

  void _saveToCache() {
    SharedPreferences.getInstance().then((prefs) {
      try {
        prefs.setString(_kCachedPosts,
            jsonEncode(_posts.map((p) => p.toJson()).toList()));
      } catch (e) {
        debugPrint('CommunityProvider._saveToCache error: $e');
      }
    });
  }

  // ── Upload image to Supabase Storage ───────────────────────────────────────

  Future<String?> uploadImage(File imageFile) async {
    try {
      // Compress (resize ≤1080px, JPEG ~78%) before upload — critical for
      // farmers on slow networks; a 5 MB photo becomes ~200–400 KB.
      return await ImageUploadHelper.compressAndUpload(
        imageFile,
        bucket: 'community-images',
        folder: 'posts',
      );
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

    // Upload image first if provided. If the upload fails, stop and surface
    // the error so the UI can prompt a retry — the user's typed text is kept
    // (nothing is inserted yet, the compose sheet stays open).
    String? imageUrl;
    if (imageFile != null) {
      imageUrl = await uploadImage(imageFile);
      if (imageUrl == null) {
        throw Exception('Imeshindwa kutuma picha. Jaribu tena.');
      }
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

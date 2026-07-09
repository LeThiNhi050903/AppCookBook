import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/services/firebase_service.dart';
import '../../core/widgets/avatar.dart';

class PublicProfileScreen extends StatefulWidget {
  final String uid;
  const PublicProfileScreen({required this.uid, super.key});

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  final FirebaseService _svc = FirebaseService();
  Map<String, dynamic>? _user;
  bool _isFriend = false;
  bool _isFollowing = false;
  bool _hasOutgoingRequest = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final u = await _svc.getUserByUid(widget.uid);
    final meUid = _svc.auth.currentUser?.uid;
    Map<String, dynamic>? me;
    if (meUid != null) me = await _svc.getUserByUid(meUid);
    final friends = me?['friends'] as List? ?? [];
    final following = me?['following'] as List? ?? [];
    final outgoing = me?['outgoingRequests'] as List? ?? [];
    setState(() {
      _user = u;
      _isFriend = friends.contains(widget.uid);
      _isFollowing = following.contains(widget.uid);
      _hasOutgoingRequest = outgoing.contains(widget.uid);
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    const primaryOrange = Color(0xffF9B21D);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black, size: 28),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _loading || _user == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      UserAvatar(
                        username: _user!['username'] ?? '',
                        isLoading: false,
                        radius: 42,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _user!['username'] ?? '',
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on_outlined,
                                  size: 18,
                                  color: Colors.black38,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _user!['location']?.isEmpty ?? true
                                      ? "Chưa cập nhật địa chỉ"
                                      : _user!['location'],
                                  style: const TextStyle(
                                    color: Colors.black38,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _BioWidget(bio: _user!['bio'] ?? ''),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(color: Colors.black38, fontSize: 16),
                            children: [
                              TextSpan(
                                text: "${(_user!['friends'] as List? ?? []).length} ",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, color: Colors.black, fontSize: 18),
                              ),
                              const TextSpan(text: 'Bạn bếp'),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(color: Colors.black38, fontSize: 16),
                            children: [
                              TextSpan(
                                text: "${(_user!['followers'] as List? ?? []).length} ",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, color: Colors.black, fontSize: 18),
                              ),
                              const TextSpan(text: 'Người quan tâm'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryOrange,
                              elevation: 1,
                              alignment: Alignment.center, 
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 4), 
                            ),
                            onPressed: () async {
                              final messenger = ScaffoldMessenger.of(context);
                              if (_isFriend) {
                                final ok = await _svc.removeFriend(widget.uid);
                                if (ok) {
                                  setState(() {
                                    _isFriend = false;
                                    final friends = List<dynamic>.from(_user?['friends'] ?? []);
                                    friends.remove(widget.uid);
                                    _user = {...?_user, 'friends': friends};
                                  });
                                  messenger.showSnackBar(
                                      const SnackBar(content: Text('Đã hủy kết bạn')));
                                  await _load();
                                }
                              } else {
                                if (_hasOutgoingRequest) return;
                                final ok = await _svc.sendFriendRequest(widget.uid);
                                final msg = ok ? 'Đã gửi lời mời kết bạn' : (_svc.lastError ?? 'Lỗi');
                                messenger.showSnackBar(SnackBar(content: Text(msg)));
                                if (ok) await _load();
                              }
                            },
                            child: Center(
                              child: Text(
                                _isFriend ? 'HỦY KẾT BẠN' : (_hasOutgoingRequest ? 'ĐÃ GỬI' : 'KẾT BẠN'),
                                maxLines: 1,         
                                softWrap: false,     
                                overflow: TextOverflow.fade, 
                                style: const TextStyle(
                                  color: Colors.white, 
                                  fontWeight: FontWeight.bold, 
                                  fontSize: 14, 
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryOrange,
                              elevation: 1,
                              alignment: Alignment.center,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                            ),
                            onPressed: () async {
                              final messenger = ScaffoldMessenger.of(context);
                              if (_isFollowing) {
                                final ok = await _svc.unfollowUser(widget.uid);
                                if (ok) {
                                  await _load();
                                  messenger.showSnackBar(
                                      const SnackBar(content: Text('Đã hủy theo dõi')));
                                }
                              } else {
                                final ok = await _svc.followUser(widget.uid);
                                if (ok) {
                                  await _load();
                                  messenger.showSnackBar(
                                      const SnackBar(content: Text('Đã theo dõi')));
                                }
                              }
                            },
                            child: Center(
                              child: Text(
                                _isFollowing ? 'HỦY THEO DÕI' : 'THEO DÕI',
                                maxLines: 1,        
                                softWrap: false,     
                                overflow: TextOverflow.fade,
                                style: const TextStyle(
                                  color: Colors.white, 
                                  fontWeight: FontWeight.bold, 
                                  fontSize: 14,     
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  FutureBuilder<QuerySnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('recipes')
                        .where('userId', isEqualTo: widget.uid) 
                        .get(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final docs = snapshot.data?.docs ?? [];

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Công thức (${docs.length})",
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (docs.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Center(
                                child: Text(
                                  "Chưa có công thức nào được chia sẻ.",
                                  style: TextStyle(color: Colors.grey, fontSize: 16),
                                ),
                              ),
                            )
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: docs.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 16),
                              itemBuilder: (context, index) {
                                final recipe = docs[index].data() as Map<String, dynamic>;
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.network(
                                            recipe['imageUrl'] ?? 'https://via.placeholder.com/150',
                                            width: 140,
                                            height: 90,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) => Container(
                                              width: 140,
                                              height: 90,
                                              color: Colors.grey.shade300,
                                              child: const Icon(Icons.broken_image, color: Colors.grey),
                                            ),
                                          ),
                                        ),
                                        const Positioned(
                                          top: 4,
                                          left: 4,
                                          child: Icon(
                                            Icons.bookmark_border,
                                            color: Colors.white,
                                            size: 26,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              UserAvatar(
                                                username: _user!['username'] ?? '',
                                                isLoading: false,
                                                radius: 10,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                _user!['username'] ?? '',
                                                style: const TextStyle(color: Colors.black54, fontSize: 13),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            recipe['title'] ?? 'Không có tiêu đề',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              decoration: TextDecoration.underline,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              const Icon(Icons.person_outline, size: 16, color: Colors.black38),
                                              const SizedBox(width: 4),
                                              Text(
                                                recipe['servings'] ?? '1 phần',
                                                style: const TextStyle(color: Colors.black38, fontSize: 13),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}
class _BioWidget extends StatefulWidget {
  final String bio;
  const _BioWidget({required this.bio});

  @override
  State<_BioWidget> createState() => _BioWidgetState();
}

class _BioWidgetState extends State<_BioWidget> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    final bio = widget.bio.isEmpty ? "Chưa cập nhật tiểu sử" : widget.bio;
    final longBio = bio.length > 90;

    return RichText(
      text: TextSpan(
        style: const TextStyle(color: Colors.black, fontSize: 15, height: 1.4),
        children: [
          TextSpan(
            text: expanded || !longBio ? bio : "${bio.substring(0, 90)}...",
          ),
          if (longBio)
            WidgetSpan(
              child: GestureDetector(
                onTap: () => setState(() => expanded = !expanded),
                child: Text(
                  expanded ? " Thu gọn" : " Xem thêm",
                  style: const TextStyle(color: Color(0xffF9B21D), fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
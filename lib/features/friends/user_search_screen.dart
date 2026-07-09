import 'package:flutter/material.dart';
import '../../core/services/firebase_service.dart';
import '../../core/widgets/avatar.dart';
import '../profile/public_profile_screen.dart';

class UserSearchScreen extends StatefulWidget {
  const UserSearchScreen({super.key});

  @override
  State<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends State<UserSearchScreen> {
  final FirebaseService _svc = FirebaseService();
  final TextEditingController _ctrl = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _loading = false;

  Future<void> _search() async {
    setState(() => _loading = true);
    final r = await _svc.searchUsersByUsername(_ctrl.text);
    final meUid = _svc.auth.currentUser?.uid;
    Map<String, dynamic>? me;
    if (meUid != null) me = await _svc.getUserByUid(meUid);

    final following = me?['following'] as List? ?? [];
    final outgoing = me?['outgoingRequests'] as List? ?? [];
    final friends = me?['friends'] as List? ?? [];

    setState(() {
      _results = r.map((u) {
        final uid = u['uid'];
        return {
          ...u,
          'isFollowing': following.contains(uid),
          'hasOutgoingRequest': outgoing.contains(uid),
          'isFriend': friends.contains(uid),
        };
      }).toList();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Tìm người dùng'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    decoration: const InputDecoration(
                      hintText: 'Tìm theo username',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _search,
                )
              ],
            ),
            const SizedBox(height: 8),
            if (_loading)
              const Center(child: CircularProgressIndicator()),
            if (!_loading && _results.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 20),
                child: Text('Không tìm thấy dữ liệu', style: TextStyle(color: Colors.grey)),
              ),
            if (!_loading && _results.isNotEmpty)
              Expanded(
                child: ListView.separated(
                  itemCount: _results.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final user = _results[index];
                    return InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PublicProfileScreen(uid: user['uid']),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            UserAvatar(
                              username: user['username'] ?? '',
                              isLoading: false,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PublicProfileScreen(uid: user['uid']),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user['username'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.location_on_outlined,
                                        color: Colors.grey,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          (user['location']?.toString().isNotEmpty ?? false)
                                              ? user['location']
                                              : 'Chưa cập nhật địa chỉ',
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  Center(
                                    child: Container(
                                      constraints: const BoxConstraints(maxWidth: 240), 
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Expanded(
                                            child: ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.black,
                                                foregroundColor: Colors.white,
                                                padding: const EdgeInsets.symmetric(vertical: 8), 
                                                minimumSize: const Size(0, 38), 
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                              ),
                                              onPressed: () async {
                                                if (user['isFriend'] == true) return;
                                                if (user['hasOutgoingRequest'] == true) return;

                                                final messenger = ScaffoldMessenger.of(context);
                                                final ok = await _svc.sendFriendRequest(user['uid']);
                                                final msg = ok ? 'Đã gửi lời mời kết bạn' : (_svc.lastError ?? 'Lỗi');

                                                if (!mounted) return;
                                                messenger.showSnackBar(
                                                  SnackBar(content: Text(msg)),
                                                );
                                                if (ok) _search();
                                              },
                                              child: FittedBox( 
                                                fit: BoxFit.scaleDown,
                                                child: Text(
                                                  user['hasOutgoingRequest'] == true
                                                      ? 'Đã gửi'
                                                      : (user['isFriend'] == true ? 'Bạn bè' : 'Kết bạn'),
                                                ),
                                              ),
                                            ),
                                          ),
                                          
                                          const SizedBox(width: 10), 
                                          Expanded(
                                            child: ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.black,
                                                foregroundColor: Colors.white,
                                                padding: const EdgeInsets.symmetric(vertical: 8),
                                                minimumSize: const Size(0, 38),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                              ),
                                              onPressed: () async {
                                                final messenger = ScaffoldMessenger.of(context);
                                                if (user['isFollowing'] == true) {
                                                  final ok = await _svc.unfollowUser(user['uid']);
                                                  if (ok && mounted) {
                                                    messenger.showSnackBar(
                                                      const SnackBar(content: Text('Đã hủy theo dõi')),
                                                    );
                                                    _search();
                                                  }
                                                  return;
                                                }
                                                final ok = await _svc.followUser(user['uid']);
                                                final msg = ok ? 'Đã theo dõi' : (_svc.lastError ?? 'Lỗi');

                                                if (!mounted) return;
                                                messenger.showSnackBar(
                                                  SnackBar(content: Text(msg)),
                                                );
                                                if (ok) _search();
                                              },
                                              child: FittedBox(
                                                fit: BoxFit.scaleDown,
                                                child: Text(
                                                  user['isFollowing'] == true ? 'Đang theo dõi' : 'Theo dõi',
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              )
          ],
        ),
      ),
    );
  }
}
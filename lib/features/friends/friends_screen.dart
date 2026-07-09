import 'package:flutter/material.dart';
import '../../core/services/firebase_service.dart';
import 'user_search_screen.dart';
import '../../core/widgets/avatar.dart';
import '../profile/public_profile_screen.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> with SingleTickerProviderStateMixin {
  final FirebaseService _svc = FirebaseService();
  late TabController _tabController;
  List<Map<String, dynamic>> _requests = [];
  List<Map<String, dynamic>> _friends = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final r = await _svc.getFriendRequests();
    final f = await _svc.getFriendsList();
    setState(() {
      _requests = r;
      _friends = f;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    const primaryOrange = Colors.orange;

    return Scaffold(
      backgroundColor: Colors.white, 
      appBar: AppBar(
        title: const Text(
          'Bạn bếp',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0, 
        actions: [
          IconButton(
            icon: const Icon(Icons.search, size: 28),
            onPressed: () => Navigator.push(
              context, 
              MaterialPageRoute(builder: (_) => const UserSearchScreen())
            ),
          )
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: primaryOrange,
          labelColor: primaryOrange, 
          unselectedLabelColor: Colors.black54, 
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          tabs: const [
            Tab(text: 'Danh sách'), 
            Tab(text: 'Lời mời kết bạn')
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: primaryOrange))
          : TabBarView(
              controller: _tabController,
              children: [
                _friends.isEmpty
                    ? const Center(
                        child: Text(
                          'Chưa có bạn bè', 
                          style: TextStyle(color: Colors.grey, fontSize: 16)
                        ),
                      )
                    : ListView.builder(
                        itemCount: _friends.length,
                        itemBuilder: (context, index) {
                          final u = _friends[index];
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            leading: GestureDetector(
                              onTap: () => Navigator.push(
                                context, 
                                MaterialPageRoute(builder: (_) => PublicProfileScreen(uid: u['uid']))
                              ),
                              child: UserAvatar(username: u['username'] ?? '', isLoading: false),
                            ),
                            title: Text(
                              u['username'] ?? '',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                            ),
                            subtitle: Text(
                              u['location']?.isEmpty ?? true ? 'Chưa cập nhật địa chỉ' : u['location'],
                              style: const TextStyle(color: Colors.black38),
                            ),
                          );
                        },
                      ),
                
                _requests.isEmpty
                    ? const Center(
                        child: Text(
                          'Không có lời mời', 
                          style: TextStyle(color: Colors.grey, fontSize: 16)
                        ),
                      )
                    : ListView.separated(
                        itemCount: _requests.length,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        separatorBuilder: (_, _) => const Divider(height: 1, color: Colors.black12),
                        itemBuilder: (context, index) {
                          final u = _requests[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    UserAvatar(username: u['username'] ?? '', isLoading: false),                                    
                                    const SizedBox(width: 16),                                    
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            u['username'] ?? '',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            u['location']?.isEmpty ?? true ? 'Chưa cập nhật địa chỉ' : u['location'],
                                            style: const TextStyle(color: Colors.black38, fontSize: 14),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                
                                const SizedBox(height: 16), 
                                Row(
                                  children: [
                                 
                                    Expanded(
                                      child: SizedBox(
                                        height: 40, // Độ cao vừa vặn cho nút bấm di động
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: primaryOrange,
                                            foregroundColor: Colors.white,
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                          onPressed: () async {
                                            final messenger = ScaffoldMessenger.of(context);
                                            final ok = await _svc.acceptFriendRequest(u['uid']);
                                            if (ok) {
                                              messenger.showSnackBar(
                                                  const SnackBar(content: Text('Đã chấp nhận lời mời')));
                                              await _load();
                                            } else {
                                              messenger.showSnackBar(
                                                  SnackBar(content: Text(_svc.lastError ?? 'Lỗi')));
                                            }
                                          },
                                          child: const Text(
                                            'Xác nhận', 
                                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                          ),
                                        ),
                                      ),
                                    ),
                                    
                                    const SizedBox(width: 12), // Khoảng cách ngang giữa 2 nút
                                    
                                    // Nút Từ chối
                                    Expanded(
                                      child: SizedBox(
                                        height: 40,
                                        child: OutlinedButton(
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.black87,
                                            side: const BorderSide(color: Colors.black12),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                          onPressed: () async {
                                            final messenger = ScaffoldMessenger.of(context);
                                            final ok = await _svc.cancelFriendRequest(u['uid']);
                                            if (ok) {
                                              messenger.showSnackBar(
                                                  const SnackBar(content: Text('Đã từ chối lời mời')));
                                              await _load();
                                            } else {
                                              messenger.showSnackBar(
                                                  SnackBar(content: Text(_svc.lastError ?? 'Lỗi')));
                                            }
                                          },
                                          child: const Text(
                                            'Từ chối', 
                                            style: TextStyle(fontSize: 15),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ],
            ),
    );
  }
}
// lib/screens/profile_screen.dart

import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';
import 'my_post_screen.dart'; // MyPostsScreen 및 PostListType 임포트
import 'wish_list_screen.dart'; // WishListScreen 임포트

// 1. StatefulWidget으로 변경
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // 2. UserModel을 null 허용 변수로 선언
  UserModel? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData(); // 3. 사용자 데이터 로드 함수 호출
  }

  // 4. 사용자 데이터를 비동기로 가져오는 함수
  Future<void> _fetchUserData() async {
    final user = await StorageService.getUser();
    if (mounted) {
      setState(() {
        _currentUser = user;
        _isLoading = false;
      });
    }
  }

  // 5. 임시 변수 대신 실제 사용자 데이터를 참조하는 Getter
  String get _userPhone => _currentUser?.mobile ?? '전화번호 정보 없음';
  String get _userId => _currentUser?.id ?? 'ID 정보 없음';
  String get _userNickname => _currentUser?.nickname ?? '닉네임 정보 없음';

  @override
  Widget build(BuildContext context) {
    // ⭐️ 로딩 중이면 로딩 인디케이터를 표시
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // ⭐️ [추가]: Firestore 쿼리에 사용할 유효한 ID와 닉네임 확인
    final String currentUserId = _userId;
    final String currentNickname = _userNickname;
    final bool isUserLoaded = _currentUser != null;


    // ⭐️ 데이터 로드 완료 후 UI 빌드 시작
    return Scaffold(
      // **********************************************
      // 🚨 PreferredSize 위젯을 사용하여 AppBar를 완전히 제거합니다.
      // **********************************************
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(0.0), // 높이를 0으로 설정
        child: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.white,
          elevation: 0,
          title: null,
          actions: const [],
        ),
      ),

      body: ListView(
        children: <Widget>[
          // ✅ '나의 마켓' 제목과 설정 아이콘을 한 줄에 배치 (Body의 최상단)
          Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween, // 양 끝 정렬
              children: [
                const Text(
                  '나의 마켓',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                // ⚙️ 설정 아이콘
                IconButton(
                  icon: const Icon(Icons.settings_outlined, color: Colors.black),
                  onPressed: () { /* 설정 화면 이동 */ },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // 1. 사용자 정보 영역 (실제 데이터 사용)
          _buildUserInfoHeader(),

          const Divider(height: 10, thickness: 10, color: Color(0xFFF5F5F5)),

          // 2. 나의 거래 영역
          _buildSectionTitle('나의 거래'),
          _buildMenuItem(
            icon: Icons.receipt_long,
            title: '판매 내역',
            onTap: isUserLoaded ? () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MyPostsScreen(
                    userId: currentUserId,
                    nickname: currentNickname,
                    listType: PostListType.salesHistory, // 👈 판매 내역 지정
                  ),
                ),
              );
            } : () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('사용자 정보를 불러올 수 없습니다.')),
              );
            },
          ),
          _buildMenuItem(
            icon: Icons.shopping_bag_outlined,
            title: '구매 내역',
            onTap: () { print('구매 내역 이동'); },
          ),
          _buildMenuItem(
            icon: Icons.favorite_border,
            title: '관심 목록',
            onTap: isUserLoaded ? () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WishListScreen( // WishListScreen으로 이동
                    currentUserId: currentUserId,
                  ),
                ),
              );
            } : () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('사용자 정보를 불러올 수 없습니다.')),
              );
            },
          ),

          const Divider(height: 10, thickness: 10, color: Color(0xFFF5F5F5)),

          // 3. 나의 활동 영역 (최근 본 매물, 받은 후기 제거)
          _buildSectionTitle('나의 활동'),
          // ⚠️ 제거됨: 최근 본 매물
          // ⚠️ 제거됨: 받은 후기
          _buildMenuItem(
            icon: Icons.article_outlined,
            title: '내 게시글',
            onTap: isUserLoaded ? () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MyPostsScreen(
                    userId: currentUserId,
                    nickname: currentNickname,
                    listType: PostListType.myPosts, // 👈 내 게시글 지정
                  ),
                ),
              );
            } : () {
              // 사용자 정보 로드 실패 시
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('사용자 정보를 불러오지 못했습니다.')),
              );
            },
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // --- 헬퍼 위젯: 사용자 데이터 사용으로 수정 ---

  Widget _buildUserInfoHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 30,
                backgroundColor: Colors.grey,
                child: Icon(Icons.person, color: Colors.white, size: 40),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _userNickname, // ⭐️ 실제 닉네임 사용
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                ],
              ),
            ],
          ),
        ),

        const Divider(height: 0, thickness: 0.5, indent: 16, endIndent: 16, color: Color(0xFFF5F5F5)),

        _buildUserInfoField(
          '휴대폰 번호',
          _userPhone, // ⭐️ 실제 휴대폰 번호 사용
        ),
        _buildUserInfoField(
          '아이디',
          _userId, // ⭐️ 실제 ID 사용
        ),
        // ⭐️⭐️⭐️ 닉네임 수정 기능 유지 ⭐️⭐️⭐️
        _buildUserInfoField(
          '닉네임',
          _userNickname, // ⭐️ 실제 닉네임 사용
          onTap: () {
            if (_currentUser != null) {
              _showNicknameEditDialog(context); // 닉네임 수정 다이얼로그 호출
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('사용자 정보를 불러올 수 없습니다.')),
              );
            }
          },
        ),
        // 비밀번호 변경만 onTap 유지
        _buildUserInfoField(
          '비밀번호',
          '••••••••', // 비밀번호는 항상 마스킹
          onTap: () { print('비밀번호 변경'); },
        ),

        const SizedBox(height: 10),
      ],
    );
  }

  // ⭐️ 🚨 핵심 수정: Flexible 대신 SizedBox와 TextOverflow.ellipsis를 사용하여 최대 너비 명시 🚨 ⭐️
  Widget _buildUserInfoField(String title, String value, {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0), // 좌우 패딩만 유지
      child: InkWell(
        onTap: onTap,
        child: Container(
          // dense: true와 contentPadding을 수직 패딩으로 대체
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 1. Title (Expanded로 남은 공간 확보)
              Expanded(
                child: Text(title, style: const TextStyle(fontSize: 13, color: Colors.grey)),
              ),

              // 2. Trailing Row (값 + 화살표)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 🚨 수정된 부분: SizedBox 너비를 120.0으로 조정하여 긴 ID가 잘리도록 명시적으로 제한
                  SizedBox(
                    width: 120.0, // 아이디/전화번호가 표시될 최대 너비를 120.0으로 지정
                    child: Text(
                      value,
                      style: const TextStyle(fontSize: 15, color: Colors.black),
                      overflow: TextOverflow.ellipsis, // 넘치는 텍스트를 ... 처리
                      textAlign: TextAlign.right, // 오른쪽 정렬
                    ),
                  ),
                  const SizedBox(width: 8),
                  // onTap이 있을 때만 화살표 아이콘을 표시 (닉네임, 비밀번호)
                  if (onTap != null) const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 10.0, 16.0, 10.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
      ),
    );
  }

  Widget _buildMenuItem({required IconData icon, required String title, required VoidCallback onTap}) {
    // 나의 거래 및 나의 활동 메뉴는 ListTile을 유지
    return ListTile(
      leading: Icon(icon, color: Colors.black, size: 24),
      title: Text(title, style: const TextStyle(fontSize: 16, color: Colors.black)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }

  // ==========================================
  // ⭐️ 닉네임 수정 다이얼로그 및 로직 (유지)
  // ==========================================

  Future<void> _showNicknameEditDialog(BuildContext context) async {
    final TextEditingController controller = TextEditingController(text: _userNickname);
    String? errorText;
    bool isChecking = false;

    // 다이얼로그를 닫으면 새로운 닉네임이 반환됩니다.
    final newNickname = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder( // 다이얼로그 내부에 상태 관리를 위해 StatefulBuilder 사용
          builder: (context, setState) {

            // 닉네임 중복 확인 로직
            Future<bool> checkAvailability(String nickname) async {
              if (nickname.length < 2 || nickname.length > 10) {
                setState(() => errorText = '닉네임은 2자 이상, 10자 이하입니다.');
                return false;
              }
              if (nickname == _userNickname) {
                setState(() => errorText = '현재 닉네임과 같습니다.');
                return false;
              }
              if (!RegExp(r'^[가-힣a-zA-Z0-9]+$').hasMatch(nickname)) {
                setState(() => errorText = '한글, 영문, 숫자만 사용 가능합니다.');
                return false;
              }

              setState(() {
                isChecking = true;
                errorText = '중복 확인 중...';
              });

              final isAvailable = await FirestoreService.isNicknameAvailable(nickname);

              setState(() {
                isChecking = false;
                if (isAvailable) {
                  errorText = '✅ 사용 가능한 닉네임입니다.';
                } else {
                  errorText = '❌ 이미 사용 중인 닉네임입니다.';
                }
              });
              return isAvailable;
            }

            return AlertDialog(
              title: const Text('닉네임 변경'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      labelText: '새 닉네임 (2~10자)',
                      errorText: errorText,
                      suffixIcon: isChecking
                          ? const Padding(
                        padding: EdgeInsets.all(10.0),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                          : TextButton(
                        onPressed: () async {
                          if (controller.text.trim().isNotEmpty) {
                            await checkAvailability(controller.text.trim());
                          }
                        },
                        child: const Text('중복 확인'),
                      ),
                    ),
                    onChanged: (value) {
                      // 입력이 변경될 때마다 상태 메시지 초기화
                      setState(() {
                        errorText = null;
                      });
                    },
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('취소'),
                  onPressed: () {
                    Navigator.of(context).pop(); // 다이얼로그 닫기 (null 반환)
                  },
                ),
                TextButton(
                  child: isChecking ? const Text('확인 중...') : const Text('저장'),
                  onPressed: isChecking ? null : () async {
                    final trimmedNickname = controller.text.trim();
                    if (trimmedNickname.isEmpty) {
                      setState(() => errorText = '닉네임을 입력해주세요.');
                      return;
                    }

                    final isAvailable = await checkAvailability(trimmedNickname);

                    if (isAvailable || trimmedNickname == _userNickname) {
                      // 중복 확인 통과 또는 기존 닉네임과 같으면 저장 진행
                      Navigator.of(context).pop(trimmedNickname);
                    }
                    // 중복 확인 실패 시 errorText가 표시된 상태로 유지됨
                  },
                ),
              ],
            );
          },
        );
      },
    );

    // 다이얼로그에서 닉네임이 반환되었고, 유효한 경우 업데이트 진행
    if (newNickname != null && newNickname.isNotEmpty && newNickname != _userNickname) {
      if (_currentUser == null) return;

      try {
        final userId = _currentUser!.id;

        // 1. Firestore 업데이트
        await FirestoreService.updateUserInFirestore(userId, {
          'nickname': newNickname,
        });

        // 2. 로컬 세션 업데이트
        final updatedUser = _currentUser!.copyWith(nickname: newNickname);
        await StorageService.saveUser(updatedUser);

        // 3. UI 업데이트
        if (mounted) {
          setState(() {
            _currentUser = updatedUser; // 닉네임 갱신
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('닉네임이 성공적으로 변경되었습니다!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('닉네임 변경 실패: $e')),
          );
        }
      }
    }
  }
}
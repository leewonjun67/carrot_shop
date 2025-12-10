import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // DocumentSnapshot 사용
import '../constants/colors.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import 'location_screen.dart'; // 닉네임 설정 완료 후 최종 목적지
import 'signup_screen.dart';
// ⭐️ 이 import 경로가 정확한지 확인해주세요.
import 'nickname_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  // ==========================================
  // ⭐️ 1. 닉네임 설정 확인 및 다음 페이지 이동 로직 (필수 로직)
  // ==========================================
  Future<void> _navigateToNextScreen(String uid) async {
    // 로딩 상태를 여기서 해제하지 않고, 분기 로직 끝에서 해제합니다.

    // 1. Firestore에서 해당 사용자의 문서 가져오기
    final DocumentSnapshot userDoc = await AuthService.getUserDocument(uid);

    // 2. 닉네임 설정 여부 확인 로직
    final data = userDoc.data() as Map<String, dynamic>?;

    // 'nickname' 필드가 존재하고 비어있지 않은지 확인
    final bool hasNickname = userDoc.exists &&
        data != null &&
        data.containsKey('nickname') &&
        (data['nickname'] as String).isNotEmpty;

    if (mounted) {
      if (hasNickname) {
        // 닉네임이 이미 설정되어 있음 -> 최종 목적지(LocationScreen)로 이동
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LocationScreen()),
        );
      } else {
        // 닉네임이 설정되지 않음 -> 닉네임 설정 페이지로 이동 준비
        final UserModel? userModel = await AuthService.getCurrentUser();

        if (userModel != null) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => NicknameSetupPage(
                userModel: userModel, // UserModel 전달
              ),
            ),
          );
        } else {
          // 세션 정보 로드 실패 시 예외 처리
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('사용자 정보 로드 실패. 다시 로그인 해주세요.')),
          );
          setState(() => _isLoading = false);
        }
      }
    }
  }

  // ==========================================
  // 2. 이메일 로그인 핸들러 (수정됨: _navigateToNextScreen 호출)
  // ==========================================
  Future<void> _handleEmailLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이메일과 비밀번호를 입력해주세요')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final result = await AuthService.loginWithEmail(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (mounted) {
      if (result.isSuccess && result.user != null) {
        // ⭐️ 로그인 성공 -> 닉네임 확인 및 다음 화면으로 분기
        await _navigateToNextScreen(result.user!.id);
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message ?? '로그인 실패')),
        );
      }
    }
  }

  // ==========================================
  // 3. 소셜 로그인 핸들러 (수정됨: _navigateToNextScreen 호출)
  // ==========================================
  Future<void> _handleSocialLogin(Future<AuthResult> Function() loginMethod) async {
    setState(() => _isLoading = true);
    final result = await loginMethod();

    if (mounted) {
      if (result.isSuccess && result.user != null) {
        // ⭐️ 로그인 성공 -> 닉네임 확인 및 다음 화면으로 분기
        await _navigateToNextScreen(result.user!.id);
      } else if (!result.isCancelled) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message ?? '로그인 실패')),
        );
      } else {
        setState(() => _isLoading = false); // 취소된 경우에도 로딩 해제
      }
    }
  }


  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ==========================================
  // 4. UI 빌드 메서드 (로고 패딩 수정됨)
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              '천안마켓과 함께하는',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.normal, color: Colors.black),
            ),
            const Text(
              '안전한 중고거래',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            const SizedBox(height: 8),
            const Text(
              '우리 동네에서 따뜻한 거래를 시작해보세요',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 40),

            // 이메일 입력
            const Text('이메일', style: TextStyle(fontSize: 14, color: Colors.black87)),
            const SizedBox(height: 8),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                hintText: '이메일 입력',
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 10),
              ),
              keyboardType: TextInputType.emailAddress,
              enabled: !_isLoading,
            ),
            const SizedBox(height: 20),

            // 비밀번호 입력
            const Text('비밀번호', style: TextStyle(fontSize: 14, color: Colors.black87)),
            const SizedBox(height: 8),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: '비밀번호 입력',
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 10),
              ),
              enabled: !_isLoading,
              onSubmitted: (_) => _handleEmailLogin(),
            ),
            const SizedBox(height: 40),

            // 로그인 버튼
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleEmailLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE3F2FD),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Colors.blue,
                  ),
                )
                    : const Text(
                  '로그인',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 회원가입 / 비밀번호 찾기
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SignUpScreen()),
                    );
                  },
                  child: const Text('회원가입', style: TextStyle(color: Colors.black54)),
                ),
                const Text('|', style: TextStyle(color: Colors.grey)),
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('비밀번호 찾기 기능은 준비 중입니다')),
                    );
                  },
                  child: const Text('비밀번호 찾기', style: TextStyle(color: Colors.black54)),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // 구분선
            const Center(
              child: Text(
                '또는',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ),

            const SizedBox(height: 20),

            // 소셜 로그인 아이콘 (padding 수정 적용)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildSocialIcon(
                  'assets/img/kakao_logo.png',
                  const Color(0xFFFEE500),
                      () => _handleSocialLogin(AuthService.kakaoLogin),
                  // ⭐️ 첫 번째 코드의 값으로 수정
                  padding: 0.0,
                  fallbackIcon: Icons.chat_bubble,
                  fallbackIconColor: Colors.black87,
                ),
                const SizedBox(width: 20),
                _buildSocialIcon(
                  'assets/img/naver_logo.png',
                  Colors.white,
                      () => _handleSocialLogin(AuthService.naverLogin),
                  // ⭐️ 첫 번째 코드의 값으로 수정
                  padding: 0.0,
                  borderColor: Colors.grey.shade300,
                  fallbackIcon: Icons.notifications,
                  fallbackIconColor: const Color(0xFF03C75A),
                ),
                const SizedBox(width: 20),
                _buildSocialIcon(
                  'assets/img/google_logo.png',
                  Colors.white,
                      () => _handleSocialLogin(AuthService.googleLogin),
                  borderColor: Colors.grey.shade300,
                  // ⭐️ 첫 번째 코드의 값으로 수정
                  padding: 0.0,
                  fallbackIcon: Icons.g_mobiledata,
                  fallbackIconColor: Colors.red,
                ),
              ],
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialIcon(
      String imagePath,
      Color color,
      VoidCallback onTap, {
        Color? borderColor,
        double padding = 8.0,
        required IconData fallbackIcon,
        required Color fallbackIconColor,
      }) {
    return GestureDetector(
      onTap: _isLoading ? null : onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: borderColor != null ? Border.all(color: borderColor, width: 1) : null,
        ),
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Image.asset(
            imagePath,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Icon(fallbackIcon, color: fallbackIconColor, size: 24);
            },
          ),
        ),
      ),
    );
  }
}
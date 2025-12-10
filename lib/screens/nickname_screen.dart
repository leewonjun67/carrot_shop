// lib/screens/nickname_setup_page.dart

import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import 'location_screen.dart';

class NicknameSetupPage extends StatefulWidget {
  // ⭐️ userModel을 필수 매개변수로 받도록 수정
  final UserModel userModel;

  const NicknameSetupPage({
    Key? key,
    required this.userModel,
  }) : super(key: key);

  @override
  State<NicknameSetupPage> createState() => _NicknameSetupPageState();
}

class _NicknameSetupPageState extends State<NicknameSetupPage> {
  final _nicknameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? _nicknameErrorText;
  bool _isChecking = false;
  bool _isSaving = false;
  bool _isNicknameAvailable = false;

  // ==========================================
  // 1. 닉네임 중복 확인 로직
  // ==========================================
  Future<void> _checkNicknameAvailability() async {
    if (_isChecking || _nicknameController.text.isEmpty) return;

    final nickname = _nicknameController.text.trim();
    if (nickname.length < 2 || nickname.length > 10) {
      setState(() {
        _nicknameErrorText = '닉네임은 2자 이상, 10자 이하입니다.';
        _isNicknameAvailable = false;
      });
      return;
    }

    // 특수문자나 공백이 포함되었는지 확인
    if (!RegExp(r'^[가-힣a-zA-Z0-9]+$').hasMatch(nickname)) {
      setState(() {
        _nicknameErrorText = '닉네임은 한글, 영문, 숫자만 사용할 수 있습니다.';
        _isNicknameAvailable = false;
      });
      return;
    }

    setState(() {
      _isChecking = true;
      _nicknameErrorText = '중복 확인 중...';
      _isNicknameAvailable = false;
    });

    try {
      final isAvailable = await FirestoreService.isNicknameAvailable(nickname);

      if (mounted) {
        setState(() {
          _isChecking = false;
          _isNicknameAvailable = isAvailable;
          if (isAvailable) {
            _nicknameErrorText = '✅ 사용 가능한 닉네임입니다.';
          } else {
            _nicknameErrorText = '❌ 이미 사용 중이거나 사용할 수 없는 닉네임입니다.';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isChecking = false;
          _nicknameErrorText = '❌ 중복 확인 중 오류가 발생했습니다.';
          _isNicknameAvailable = false;
        });
      }
    }
  }

  // ==========================================
  // 2. 닉네임 저장 로직
  // ==========================================
  Future<void> _saveNickname() async {
    // 폼 유효성 검사 (길이 등)
    if (!_formKey.currentState!.validate()) return;

    // 중복 확인이 완료되지 않았거나, 사용 불가능한 닉네임인 경우
    if (!_isNicknameAvailable) {
      if (_nicknameErrorText?.contains('사용 가능한 닉네임입니다') != true) {
        setState(() => _nicknameErrorText = '닉네임 중복 확인을 해주세요.');
      }
      return;
    }

    setState(() => _isSaving = true);

    try {
      final newNickname = _nicknameController.text.trim();
      final userId = widget.userModel.id;

      // 1. Firestore에 닉네임 업데이트
      await FirestoreService.updateUserInFirestore(userId, {
        'nickname': newNickname,
      });

      // 2. 로컬 세션의 UserModel 업데이트
      final updatedUser = widget.userModel.copyWith(
        nickname: newNickname,
      );
      await StorageService.saveUser(updatedUser);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('닉네임 설정 완료!')),
        );

        // 3. 다음 화면으로 이동
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LocationScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('닉네임 저장 실패: $e')),
        );
      }
    }
  }

  // 닉네임 입력 필드 변경 감지 리스너
  void _onNicknameChanged() {
    // 사용자가 입력할 때마다 중복 확인 상태 초기화
    if (_isNicknameAvailable) {
      setState(() {
        _isNicknameAvailable = false;
        _nicknameErrorText = null;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    // 초기 닉네임 값을 설정 (소셜로그인 기본 닉네임 등)
    if (widget.userModel.nickname.isNotEmpty) {
      _nicknameController.text = widget.userModel.nickname;
    }
    _nicknameController.addListener(_onNicknameChanged);
  }

  @override
  void dispose() {
    _nicknameController.removeListener(_onNicknameChanged);
    _nicknameController.dispose();
    super.dispose();
  }

  // ==========================================
  // 3. UI 빌드
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('닉네임 설정', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false, // 뒤로가기 버튼 숨김
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Text(
                '천안마켓에서 사용할 닉네임을 설정해주세요.',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                '닉네임은 한글, 영문, 숫자만 사용 가능하며, 2자 이상 10자 이하로 설정할 수 있습니다.',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 30),

              // 닉네임 입력 필드
              TextFormField(
                controller: _nicknameController,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: '닉네임',
                  hintText: '2자 이상 10자 이하',
                  border: const OutlineInputBorder(),
                  suffixIcon: _isChecking
                      ? const Padding(
                    padding: EdgeInsets.all(10.0),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                      : TextButton(
                    onPressed: _checkNicknameAvailability,
                    child: const Text('중복 확인'),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '닉네임을 입력해주세요.';
                  }
                  if (value.length < 2 || value.length > 10) {
                    return '닉네임은 2자 이상, 10자 이하입니다.';
                  }
                  if (!RegExp(r'^[가-힣a-zA-Z0-9]+$').hasMatch(value)) {
                    return '닉네임은 한글, 영문, 숫자만 사용할 수 있습니다.';
                  }
                  return null;
                },
              ),

              // 에러/상태 메시지
              if (_nicknameErrorText != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    _nicknameErrorText!,
                    style: TextStyle(
                      color: _isNicknameAvailable ? Colors.green : Colors.red,
                      fontSize: 14,
                    ),
                  ),
                ),

              const SizedBox(height: 40),

              // 설정 완료 버튼
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveNickname,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isNicknameAvailable ? const Color(0xFFE3F2FD) : Colors.grey.shade300,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5.0),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: Colors.blue,
                    ),
                  )
                      : Text(
                    '설정 완료',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _isNicknameAvailable ? Colors.blue : Colors.grey.shade600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
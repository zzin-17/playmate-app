import 'package:flutter/material.dart';

enum ReportType {
  post,
  comment,
  user,
}

enum ReportReason {
  spam,           // 스팸
  inappropriate,  // 부적절한 내용
  harassment,     // 괴롭힘
  violence,       // 폭력
  copyright,      // 저작권 침해
  other,          // 기타
}

class ReportService {
  static final ReportService _instance = ReportService._internal();
  factory ReportService() => _instance;
  ReportService._internal();

  /// 신고하기
  Future<void> report({
    required ReportType type,
    required int targetId,
    required ReportReason reason,
    String? description,
    required BuildContext context,
  }) async {
    try {
      // 신고 처리
      await _processReport(type, targetId, reason, description);
      
      // 성공 메시지 표시
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('신고가 접수되었습니다. 검토 후 조치하겠습니다.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('신고 실패: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('신고 접수에 실패했습니다.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 신고 처리
  Future<void> _processReport(
    ReportType type,
    int targetId,
    ReportReason reason,
    String? description,
  ) async {
    // TODO: 실제 API 호출로 신고 처리
    await Future.delayed(const Duration(milliseconds: 500));
    
    print('신고 처리됨: $type, ID: $targetId, 이유: $reason');
    if (description != null) {
      print('설명: $description');
    }
  }

  /// 신고 다이얼로그 표시
  Future<void> showReportDialog({
    required BuildContext context,
    required ReportType type,
    required int targetId,
    String? targetTitle,
  }) async {
    ReportReason? selectedReason;
    final descriptionController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${_getReportTypeText(type)} 신고'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (targetTitle != null) ...[
                Text(
                  '신고 대상: $targetTitle',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // 신고 이유 선택
              Text(
                '신고 이유를 선택해주세요:',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              
              ...ReportReason.values.map((reason) => RadioListTile<ReportReason>(
                title: Text(_getReportReasonText(reason)),
                value: reason,
                groupValue: selectedReason,
                onChanged: (value) {
                  setState(() {
                    selectedReason = value;
                  });
                },
              )),
              
              const SizedBox(height: 16),
              
              // 추가 설명 입력
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: '추가 설명 (선택사항)',
                  hintText: '신고에 대한 자세한 설명을 입력해주세요.',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: selectedReason == null ? null : () async {
              Navigator.of(context).pop();
              
              await report(
                type: type,
                targetId: targetId,
                reason: selectedReason!,
                description: descriptionController.text.trim().isEmpty
                    ? null
                    : descriptionController.text.trim(),
                context: context,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('신고하기'),
          ),
        ],
      ),
    );
  }

  /// 신고 타입 텍스트 변환
  String _getReportTypeText(ReportType type) {
    switch (type) {
      case ReportType.post:
        return '게시글';
      case ReportType.comment:
        return '댓글';
      case ReportType.user:
        return '사용자';
    }
  }

  /// 신고 이유 텍스트 변환
  String _getReportReasonText(ReportReason reason) {
    switch (reason) {
      case ReportReason.spam:
        return '스팸';
      case ReportReason.inappropriate:
        return '부적절한 내용';
      case ReportReason.harassment:
        return '괴롭힘';
      case ReportReason.violence:
        return '폭력';
      case ReportReason.copyright:
        return '저작권 침해';
      case ReportReason.other:
        return '기타';
    }
  }
}

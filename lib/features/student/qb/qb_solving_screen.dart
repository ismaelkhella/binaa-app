import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../data/models/qb.dart';
import '../../../providers.dart';
import '../../../widgets/status_views.dart';
import 'qb_result_screen.dart';

class QbSolvingScreen extends ConsumerStatefulWidget {
  final String unitId;
  final String unitName;

  const QbSolvingScreen({
    super.key,
    required this.unitId,
    required this.unitName,
  });

  @override
  ConsumerState<QbSolvingScreen> createState() => _QbSolvingScreenState();
}

class _QbSolvingScreenState extends ConsumerState<QbSolvingScreen> {
  int _currentIndex = 0;
  String? _selectedChoiceId;
  QbAnswerResponse? _answerResult;
  bool _isLoadingAnswer = false;
  int _correctCount = 0;

  @override
  Widget build(BuildContext context) {
    final questionsAsync = ref.watch(qbQuestionsProvider(widget.unitId));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.unitName),
        centerTitle: true,
      ),
      body: questionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: ErrorView(
            title: 'تعذر تحميل الأسئلة',
            onRetry: () => ref.refresh(qbQuestionsProvider(widget.unitId)),
          ),
        ),
        data: (questions) {
          if (questions.isEmpty) {
            return const Center(
              child: EmptyState(
                icon: Icons.question_mark,
                title: 'لا توجد أسئلة',
                message: 'هذه الوحدة لا تحتوي على أسئلة حالياً',
              ),
            );
          }

          final question = questions[_currentIndex];
          final progress = (_currentIndex + 1) / questions.length;

          return Column(
            children: [
              LinearProgressIndicator(
                value: progress,
                backgroundColor: AppColors.surfaceAlt,
                valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                minHeight: 6,
              ),
              Padding(
                padding: const EdgeInsets.all(AppDimensions.lg),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'سؤال ${_currentIndex + 1} من ${questions.length}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                    ),
                    Text(
                      'النتيجة: $_correctCount',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.success),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: AppDimensions.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (question.imageUrl != null) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                          child: Image.network(
                            question.imageUrl!,
                            height: 200,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                          ),
                        ),
                        const SizedBox(height: AppDimensions.lg),
                      ],
                      Text(
                        question.text,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: AppDimensions.xl),
                      ...question.choices.map((choice) => _buildChoiceItem(choice)),
                    ],
                  ),
                ),
              ),
              _buildBottomAction(questions),
            ],
          );
        },
      ),
    );
  }

  Widget _buildChoiceItem(QbChoice choice) {
    final isSelected = _selectedChoiceId == choice.id;
    final isCorrect = _answerResult?.correctChoiceId == choice.id;
    final isWrong = _answerResult != null && isSelected && !_answerResult!.isCorrect;

    Color borderColor = AppColors.outline.withOpacity(0.2);
    Color bgColor = Colors.white;
    Widget? icon;

    if (_answerResult != null) {
      if (isCorrect) {
        borderColor = AppColors.success;
        bgColor = AppColors.success.withOpacity(0.1);
        icon = const Icon(Icons.check_circle, color: AppColors.success);
      } else if (isWrong) {
        borderColor = AppColors.danger;
        bgColor = AppColors.danger.withOpacity(0.1);
        icon = const Icon(Icons.cancel, color: AppColors.danger);
      }
    } else if (isSelected) {
      borderColor = AppColors.primary;
      bgColor = AppColors.primary.withOpacity(0.05);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.md),
      child: InkWell(
        onTap: _answerResult != null || _isLoadingAnswer ? null : () => setState(() => _selectedChoiceId = choice.id),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        child: Container(
          padding: const EdgeInsets.all(AppDimensions.lg),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            border: Border.all(color: borderColor, width: isSelected || isCorrect || isWrong ? 2 : 1),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  choice.text,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isWrong ? AppColors.danger : (isCorrect ? AppColors.success : AppColors.textPrimary),
                  ),
                ),
              ),
              if (icon != null) icon,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomAction(List<QbQuestion> questions) {
    final isLast = _currentIndex == questions.length - 1;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.lg),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -4),
            blurRadius: 10,
          ),
        ],
      ),
      child: SafeArea(
        child: _answerResult == null
            ? ElevatedButton(
                onPressed: _selectedChoiceId == null || _isLoadingAnswer ? null : _submitAnswer,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  backgroundColor: AppColors.primary,
                ),
                child: _isLoadingAnswer
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('تأكيد الإجابة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              )
            : ElevatedButton(
                onPressed: () {
                  if (isLast) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => QbResultScreen(
                          correctCount: _correctCount,
                          totalCount: questions.length,
                          unitId: widget.unitId,
                          unitName: widget.unitName,
                        ),
                      ),
                    );
                  } else {
                    setState(() {
                      _currentIndex++;
                      _selectedChoiceId = null;
                      _answerResult = null;
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  backgroundColor: AppColors.primary,
                ),
                child: Text(
                  isLast ? 'عرض النتيجة' : 'السؤال التالي',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
      ),
    );
  }

  Future<void> _submitAnswer() async {
    setState(() => _isLoadingAnswer = true);
    try {
      final questionId = ref.read(qbQuestionsProvider(widget.unitId)).value![_currentIndex].id;
      final result = await ref.read(qbRepositoryProvider).answerQuestion(questionId, _selectedChoiceId!);
      setState(() {
        _answerResult = result;
        _isLoadingAnswer = false;
        if (result.isCorrect) _correctCount++;
      });
    } catch (e) {
      setState(() => _isLoadingAnswer = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('حدث خطأ: ${e.toString()}')));
    }
  }
}

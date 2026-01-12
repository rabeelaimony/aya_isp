import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/error_handler.dart';
import '../repositories/extend_validity_repository.dart';
import 'extend_validity_state.dart';

class ExtendValidityCubit extends Cubit<ExtendValidityState> {
  final ExtendValidityRepository _repository;

  ExtendValidityCubit(this._repository) : super(ExtendValidityInitial());

  void reset() => emit(ExtendValidityInitial());

  Future<void> extendValidity({
    required String username,
    required String token,
  }) async {
    emit(ExtendValidityLoading());
    try {
      final response = await _repository.extend(
        username: username,
        token: token,
      );

      final message = response.message;
      if (response.status) {
        final localized = _localizeMessage(message, isError: false);
        emit(ExtendValiditySuccess(localized.isNotEmpty ? localized : message));
      } else {
        final normalized = ErrorHandler.extractMessage(message);
        final localized = _localizeMessage(normalized, isError: true);
        emit(
          ExtendValidityError(localized.isNotEmpty ? localized : normalized),
        );
      }
    } catch (e) {
      emit(ExtendValidityError(ErrorHandler.getErrorMessage(e)));
    }
  }

  String _localizeMessage(String message, {required bool isError}) {
    final sanitized = message.trim();
    if (sanitized.isEmpty) return sanitized;
    if (_containsArabic(sanitized)) return sanitized;
    if (!_containsLatin(sanitized)) return sanitized;

    final lowered = sanitized.toLowerCase();
    final translated = _translateEnglishMessage(lowered);
    if (translated != null && translated.isNotEmpty) return translated;

    return isError ? "حدث خطأ، حاول لاحقاً." : "تمت العملية بنجاح.";
  }

  bool _containsArabic(String text) {
    return RegExp(r'[\u0600-\u06FF]').hasMatch(text);
  }

  bool _containsLatin(String text) {
    return RegExp(r'[A-Za-z]').hasMatch(text);
  }

  String? _translateEnglishMessage(String text) {
    if (text.contains('success') ||
        text.contains('ok') ||
        text.contains('done')) {
      return "تمت العملية بنجاح.";
    }
    if (text.contains('already')) {
      return "تمت العملية مسبقاً.";
    }
    if (text.contains('invalid')) {
      return "بيانات غير صحيحة.";
    }
    if (text.contains('expired')) {
      return "انتهت الصلاحية.";
    }
    if (text.contains('unauthorized') || text.contains('unauthorised')) {
      return "يرجى تسجيل الدخول.";
    }
    if (text.contains('forbidden')) {
      return "غير مصرح بهذا الإجراء.";
    }
    if (text.contains('not found')) {
      return "المطلوب غير موجود.";
    }
    if (text.contains('timeout') || text.contains('timed out')) {
      return "انتهت مهلة الاتصال.";
    }
    if (text.contains('rate limit') || text.contains('too many')) {
      return "محاولات كثيرة، حاول لاحقاً.";
    }
    if (text.contains('insufficient') && text.contains('balance')) {
      return "الرصيد غير كافٍ.";
    }
    if (text.contains('insufficient')) {
      return "الموارد غير كافية.";
    }
    if (text.contains('connection') && text.contains('failed')) {
      return "تعذر الاتصال .";
    }
    if (text.contains('server') && text.contains('error')) {
      return "حدث  خطاء .";
    }
    if (text.contains('failed')) {
      return "فشلت العملية.";
    }
    if (text.contains('error')) {
      return "حدث خطأ.";
    }
    if (text.contains('try again')) {
      return "يرجى المحاولة لاحقاً.";
    }
    return null;
  }
}

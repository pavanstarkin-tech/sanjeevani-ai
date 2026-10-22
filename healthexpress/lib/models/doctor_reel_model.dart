import 'medicine_model.dart';
import '../data/production_database.dart';

class ReelComment {
  final String id;
  final String author;
  final String text;
  final DateTime time;
  final String? avatarUrl;

  ReelComment({
    required this.id,
    required this.author,
    required this.text,
    required this.time,
    this.avatarUrl,
  });
}

class DoctorReelModel {
  final String id;
  final String filename;
  final String videoAsset;
  final String videoPath;
  final String doctorName;
  final String doctorSpecialty;
  final String doctorHandle;
  final String doctorAvatar;
  final String title;
  final String caption;
  String? taggedProductId;
  int likesCount;
  int commentsCount;
  int sharesCount;
  bool isLiked;
  bool isSaved;
  final List<String> tags;
  final List<ReelComment> comments;

  DoctorReelModel({
    required this.id,
    required this.filename,
    required this.videoAsset,
    required this.videoPath,
    required this.doctorName,
    required this.doctorSpecialty,
    required this.doctorHandle,
    required this.doctorAvatar,
    required this.title,
    required this.caption,
    this.taggedProductId,
    this.likesCount = 1420,
    this.commentsCount = 86,
    this.sharesCount = 210,
    this.isLiked = false,
    this.isSaved = false,
    this.tags = const ['#HealthTips', '#DoctorAdvice'],
    List<ReelComment>? comments,
  }) : comments = comments ?? [
    ReelComment(
      id: 'c1',
      author: 'Kavitha R.',
      text: 'Very helpful doctor! Will follow this advice.',
      time: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    ReelComment(
      id: 'c2',
      author: 'Suresh Kumar',
      text: 'Thanks for sharing, clear explanation.',
      time: DateTime.now().subtract(const Duration(hours: 5)),
    ),
  ];

  MedicineModel? get taggedProduct {
    if (taggedProductId == null || taggedProductId!.isEmpty) return null;
    try {
      return ProductionDatabase.medicines.firstWhere(
        (m) => m.id.toLowerCase() == taggedProductId!.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  DoctorReelModel copyWith({
    String? taggedProductId,
    int? likesCount,
    int? commentsCount,
    int? sharesCount,
    bool? isLiked,
    bool? isSaved,
  }) {
    return DoctorReelModel(
      id: id,
      filename: filename,
      videoAsset: videoAsset,
      videoPath: videoPath,
      doctorName: doctorName,
      doctorSpecialty: doctorSpecialty,
      doctorHandle: doctorHandle,
      doctorAvatar: doctorAvatar,
      title: title,
      caption: caption,
      taggedProductId: taggedProductId ?? this.taggedProductId,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      sharesCount: sharesCount ?? this.sharesCount,
      isLiked: isLiked ?? this.isLiked,
      isSaved: isSaved ?? this.isSaved,
      tags: tags,
      comments: comments,
    );
  }
}

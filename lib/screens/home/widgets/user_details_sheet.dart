import 'package:flutter/material.dart';

void showUserDetailsSheet(BuildContext context, personal, data) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        padding: const EdgeInsets.all(20),
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "معلومات المشترك",
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildDetailRow(
                      context,
                      Icons.person,
                      "اسم المستخدم",
                      personal?.username ?? "-",
                    ),
                    _buildDetailRow(
                      context,
                      Icons.phone,
                      "الموبايل",
                      personal?.mobile ?? "-",
                    ),
                    _buildDetailRow(
                      context,
                      Icons.phone_in_talk,
                      "الهاتف",
                      personal?.phone ?? "-",
                    ),
                    _buildDetailRow(
                      context,
                      Icons.location_city,
                      "المدينة",
                      personal?.city ?? "-",
                    ),
                    _buildDetailRow(
                      context,
                      Icons.location_on,
                      "المقسم",
                      personal?.central ?? "-",
                    ),

                    ///  معلومات الـ Static IP إذا موجودة
                    if (data?.staticIp != null &&
                        data!.staticIp!.isNotEmpty) ...[
                      _buildDetailRow(
                        context,
                        Icons.public,
                        "الـ Static IP",
                        data.staticIp!,
                      ),
                      if (data.expStaticIp != null &&
                          data.expStaticIp!.isNotEmpty)
                        _buildDetailRow(
                          context,
                          Icons.date_range,
                          "تاريخ انتهاء الـ Static IP",
                          data.expStaticIp!,
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// 🟢 ويدجت: أيقونة + عنوان يمين | القيمة يسار
Widget _buildDetailRow(
  BuildContext context,
  IconData icon,
  String title,
  String value,
) {
  final theme = Theme.of(context);
  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
    decoration: BoxDecoration(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: theme.dividerColor),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        /// 🟢 القسم اليميني (أيقونة + العنوان)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: theme.colorScheme.primary,
            ), // ✅ اللون الرئيسي للأيقونة
            const SizedBox(width: 8),
            Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),

        /// 🟢 القيمة القادمة من السيرفر على اليسار
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.left,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
      ],
    ),
  );
}

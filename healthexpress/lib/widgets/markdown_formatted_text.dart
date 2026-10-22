import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/app_colors.dart';

/// Reusable Enhanced Interactive Clinical & General Markdown Formatter Widget.
/// Supports:
/// 1. Markdown tables with clean borders, zebra striping, and interactive rows
/// 2. Headings (# H1, ## H2, ### H3) with accent typography
/// 3. Bold (**text**), Italics (*text*), Inline code (`code`)
/// 4. Interactive Bullet lists (- item, * item, • item, + item) with tap-to-ask feedback
/// 5. Interactive Numbered lists (1. item, 2. item)
/// 6. Actionable next-step chips (👉 item) with touch ripples
/// 7. Blockquotes (> quote)
class MarkdownFormattedText extends StatelessWidget {
  final String text;
  final TextStyle? baseStyle;
  final void Function(String itemText)? onItemTap;

  const MarkdownFormattedText({
    super.key,
    required this.text,
    this.baseStyle,
    this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    final widgets = <Widget>[];
    final lines = text.split('\n');
    int i = 0;

    while (i < lines.length) {
      final line = lines[i];
      final trimmed = line.trim();

      if (trimmed.isEmpty) {
        widgets.add(const SizedBox(height: 6));
        i++;
        continue;
      }

      // 1. Table Detection: line contains | and has pipe syntax
      if (_isTableLine(trimmed)) {
        final tableLines = <String>[];
        while (i < lines.length && _isTableLine(lines[i].trim())) {
          tableLines.add(lines[i]);
          i++;
        }
        final tableWidget = _buildTableWidget(context, tableLines, onItemTap);
        if (tableWidget != null) {
          widgets.add(tableWidget);
        }
        continue;
      }

      // 2. Heading 3: ### Heading
      if (trimmed.startsWith('### ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 4),
          child: _buildRichInlineText(
            trimmed.substring(4).trim(),
            baseStyle: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
        ));
        i++;
        continue;
      }

      // 3. Heading 2: ## Heading
      if (trimmed.startsWith('## ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 5),
          child: _buildRichInlineText(
            trimmed.substring(3).trim(),
            baseStyle: const TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
        ));
        i++;
        continue;
      }

      // 4. Heading 1: # Heading
      if (trimmed.startsWith('# ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 6),
          child: _buildRichInlineText(
            trimmed.substring(2).trim(),
            baseStyle: const TextStyle(
              fontSize: 16.5,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
        ));
        i++;
        continue;
      }

      // 5. Interactive Next Steps Prompt: lines starting with 👉
      if (trimmed.startsWith('👉 ') || trimmed.startsWith('👉')) {
        final content = trimmed.replaceFirst(RegExp(r'^👉\s*'), '').trim();
        widgets.add(_buildActionPromptCard(context, content, onItemTap));
        i++;
        continue;
      }

      // 6. Bullet list item: - , * , • , +
      if (trimmed.startsWith('- ') ||
          trimmed.startsWith('* ') ||
          trimmed.startsWith('• ') ||
          trimmed.startsWith('+ ')) {
        final itemContent = trimmed.substring(2).trim();
        widgets.add(_buildInteractiveBulletItem(
          context,
          content: itemContent,
          baseStyle: baseStyle,
          onTap: onItemTap,
        ));
        i++;
        continue;
      }

      // 7. Numbered list item: 1. , 2. , etc.
      final numMatch = RegExp(r'^(\d+)\.\s+(.*)$').firstMatch(trimmed);
      if (numMatch != null) {
        final numStr = numMatch.group(1)!;
        final content = numMatch.group(2)!.trim();
        widgets.add(_buildInteractiveNumberedItem(
          context,
          number: numStr,
          content: content,
          baseStyle: baseStyle,
          onTap: onItemTap,
        ));
        i++;
        continue;
      }

      // 8. Blockquote: >
      if (trimmed.startsWith('> ')) {
        widgets.add(Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFC),
            border: Border(left: BorderSide(color: AppColors.primary, width: 3)),
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(6),
              bottomRight: Radius.circular(6),
            ),
          ),
          child: _buildRichInlineText(
            trimmed.substring(2).trim(),
            baseStyle: const TextStyle(
              color: Color(0xFF475569),
              fontSize: 13.0,
              fontStyle: FontStyle.italic,
              height: 1.35,
            ),
          ),
        ));
        i++;
        continue;
      }

      // 9. Plain paragraph line
      widgets.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 2.5),
        child: _buildRichInlineText(trimmed, baseStyle: baseStyle),
      ));
      i++;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: widgets,
    );
  }

  static bool _isTableLine(String line) {
    final t = line.trim();
    return t.contains('|') && (t.startsWith('|') || t.contains(' | '));
  }

  /// Interactive Action Card / Follow-up chip
  static Widget _buildActionPromptCard(
    BuildContext context,
    String content,
    void Function(String itemText)? onTap,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFBFDBFE), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            HapticFeedback.lightImpact();
            final cleanText = content.replaceAll(RegExp(r'\*\*'), '').trim();
            if (onTap != null) {
              onTap(cleanText);
            } else {
              Clipboard.setData(ClipboardData(text: cleanText));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Copied: "$cleanText"'),
                  duration: const Duration(seconds: 1),
                ),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                const Icon(
                  Icons.touch_app_rounded,
                  color: AppColors.primary,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildRichInlineText(
                    content,
                    baseStyle: const TextStyle(
                      fontSize: 13.0,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E40AF),
                      height: 1.35,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Color(0xFF3B82F6),
                  size: 12,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Interactive Bullet List Item with touch feedback
  static Widget _buildInteractiveBulletItem(
    BuildContext context, {
    required String content,
    TextStyle? baseStyle,
    void Function(String itemText)? onTap,
  }) {
    // Check if this bullet looks like an action or question
    final isActionable = content.endsWith('?') ||
        content.startsWith('[') ||
        content.contains('👉') ||
        content.toLowerCase().startsWith('ask') ||
        content.toLowerCase().startsWith('check');

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2.5),
      decoration: BoxDecoration(
        color: isActionable ? const Color(0xFFF8FAFC) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isActionable
            ? Border.all(color: const Color(0xFFE2E8F0), width: 0.8)
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            HapticFeedback.selectionClick();
            final clean = content.replaceAll(RegExp(r'\*\*'), '').trim();
            if (onTap != null) {
              onTap(clean);
            } else {
              Clipboard.setData(ClipboardData(text: clean));
            }
          },
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isActionable ? 8.0 : 4.0,
              vertical: isActionable ? 6.0 : 3.0,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 6, right: 8),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isActionable ? AppColors.primaryAccent : AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: _buildRichInlineText(
                    content,
                    baseStyle: baseStyle ??
                        TextStyle(
                          color: isActionable
                              ? const Color(0xFF0F172A)
                              : AppColors.textPrimary,
                          fontSize: 13.5,
                          fontWeight: isActionable ? FontWeight.w500 : FontWeight.normal,
                          height: 1.4,
                        ),
                  ),
                ),
                if (isActionable) ...[
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.north_east_rounded,
                    color: AppColors.textSecondary,
                    size: 13,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Interactive Numbered List Item
  static Widget _buildInteractiveNumberedItem(
    BuildContext context, {
    required String number,
    required String content,
    TextStyle? baseStyle,
    void Function(String itemText)? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2.5),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: () {
            HapticFeedback.selectionClick();
            final clean = content.replaceAll(RegExp(r'\*\*'), '').trim();
            if (onTap != null) {
              onTap(clean);
            } else {
              Clipboard.setData(ClipboardData(text: clean));
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 3.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    number,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      fontSize: 11.5,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildRichInlineText(
                    content,
                    baseStyle: baseStyle ??
                        const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13.5,
                          height: 1.4,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget? _buildTableWidget(
    BuildContext context,
    List<String> tableLines,
    void Function(String itemText)? onItemTap,
  ) {
    final rows = <List<String>>[];

    for (final l in tableLines) {
      final trimmed = l.trim();
      if (trimmed.isEmpty) continue;

      // Check if it's separator row: e.g. |---|---| or |:---|:---:|
      final isSeparator = trimmed.replaceAll(RegExp(r'[\s|:\-]'), '').isEmpty;
      if (isSeparator) continue;

      var cells = trimmed.split('|');
      if (cells.isNotEmpty && cells.first.trim().isEmpty) cells.removeAt(0);
      if (cells.isNotEmpty && cells.last.trim().isEmpty) cells.removeLast();

      final cleanCells = cells.map((c) => c.trim()).toList();
      if (cleanCells.isNotEmpty) {
        rows.add(cleanCells);
      }
    }

    if (rows.isEmpty) return null;

    int maxCols = 0;
    for (final r in rows) {
      if (r.length > maxCols) maxCols = r.length;
    }
    if (maxCols == 0) return null;

    for (final r in rows) {
      while (r.length < maxCols) {
        r.add('');
      }
    }

    final header = rows.first;
    final dataRows = rows.length > 1 ? rows.sublist(1) : <List<String>>[];

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFCBD5E1), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(9),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Table(
            defaultColumnWidth: const IntrinsicColumnWidth(),
            border: TableBorder(
              horizontalInside: BorderSide(color: Colors.grey.shade200, width: 0.8),
              verticalInside: BorderSide(color: Colors.grey.shade200, width: 0.8),
            ),
            children: [
              // Header Row
              TableRow(
                decoration: const BoxDecoration(
                  color: Color(0xFFEBF2FF), // Soft primary-tinted blue header
                ),
                children: header.map((h) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: _buildRichInlineText(
                      h,
                      baseStyle: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E3A8A),
                        fontSize: 12.5,
                        letterSpacing: 0.2,
                      ),
                    ),
                  );
                }).toList(),
              ),

              // Data Rows with interactive cell tap
              ...dataRows.asMap().entries.map((entry) {
                final idx = entry.key;
                final row = entry.value;
                final isEven = idx % 2 == 0;
                return TableRow(
                  decoration: BoxDecoration(
                    color: isEven ? Colors.white : const Color(0xFFF8FAFC),
                  ),
                  children: row.map((cell) {
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          final clean = cell.replaceAll(RegExp(r'\*\*'), '').trim();
                          if (clean.isNotEmpty) {
                            if (onItemTap != null) {
                              onItemTap(clean);
                            } else {
                              Clipboard.setData(ClipboardData(text: clean));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Copied "$clean"'), duration: const Duration(milliseconds: 900)),
                              );
                            }
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                          child: _buildRichInlineText(
                            cell,
                            baseStyle: const TextStyle(
                              color: Color(0xFF334155),
                              fontSize: 12.5,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildRichInlineText(String text, {TextStyle? baseStyle}) {
    final defaultStyle = baseStyle ??
        const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 13.5,
          height: 1.4,
        );

    final spans = <InlineSpan>[];
    // Match **bold**, *italic*, and `code`
    final regExp = RegExp(r'(\*\*([^*]+)\*\*|\*([^*]+)\*|`([^`]+)`)');
    int lastIndex = 0;

    for (final match in regExp.allMatches(text)) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: text.substring(lastIndex, match.start),
          style: defaultStyle,
        ));
      }

      final matchedStr = match.group(0)!;
      if (matchedStr.startsWith('**') && matchedStr.endsWith('**')) {
        spans.add(TextSpan(
          text: match.group(2),
          style: defaultStyle.copyWith(
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ));
      } else if (matchedStr.startsWith('*') && matchedStr.endsWith('*')) {
        spans.add(TextSpan(
          text: match.group(3),
          style: defaultStyle.copyWith(fontStyle: FontStyle.italic),
        ));
      } else if (matchedStr.startsWith('`') && matchedStr.endsWith('`')) {
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Text(
              match.group(4)!,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: (defaultStyle.fontSize ?? 13.5) * 0.9,
                color: const Color(0xFF0F766E),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ));
      }

      lastIndex = match.end;
    }

    if (lastIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastIndex),
        style: defaultStyle,
      ));
    }

    return Text.rich(TextSpan(children: spans));
  }
}

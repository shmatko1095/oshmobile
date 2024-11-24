import 'package:flutter/material.dart';
import 'package:oshmobile/core/theme/app_palette.dart';
import 'package:oshmobile/core/utils/calculate_reading_time.dart';
import 'package:oshmobile/core/utils/format_date.dart';
import 'package:oshmobile/features/blog/domain/entities/blog.dart';

class BlogViewerPage extends StatelessWidget {
  static route(Blog blog) => MaterialPageRoute(
        builder: (context) => BlogViewerPage(
          blog: blog,
        ),
      );

  final Blog blog;

  const BlogViewerPage({super.key, required this.blog});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Scrollbar(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  blog.title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "Blog ${blog.posterName}",
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  "${formatDateByDDMMYYYY(blog.updatedAt)}, ${calculateReadingTime(blog.content)} min",
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: AppPalette.greyColor,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppPalette.borderColor, width: 2),
                    borderRadius: const BorderRadius.all(Radius.circular(10)),
                  ),
                  width: double.maxFinite,
                  child: Image.network(blog.imageUrl),
                ),
                const SizedBox(height: 15),
                Text(
                  blog.content,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: AppPalette.greyColor,
                    fontSize: 16,
                    height: 2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

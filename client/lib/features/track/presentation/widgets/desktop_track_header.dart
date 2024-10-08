import 'package:flutter/material.dart';

class DesktopTrackHeader extends StatelessWidget {
  final bool displayDateAdded;

  final bool displayAlbum;
  final bool displayLike;

  const DesktopTrackHeader({
    super.key,
    this.displayDateAdded = false,
    this.displayAlbum = true,
    this.displayLike = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: Center(
        child: Container(
          color: Colors.transparent,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const SizedBox(
                width: 28,
                child: Text(
                  "#",
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    fontSize: 14,
                    letterSpacing: 14 * 0.03,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 24),
              const Expanded(
                child: Text(
                  "Title",
                  style: TextStyle(
                    fontSize: 14,
                    letterSpacing: 14 * 0.03,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 24),
              if (displayAlbum)
                const Expanded(
                  child: Text(
                    "Album",
                    style: TextStyle(
                      fontSize: 14,
                      letterSpacing: 14 * 0.03,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              if (displayDateAdded)
                const SizedBox(
                  width: 96,
                  child: Text(
                    "Date added",
                    style: TextStyle(
                      fontSize: 14,
                      letterSpacing: 14 * 0.03,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              if (displayDateAdded) const SizedBox(width: 24),
              const SizedBox(
                width: 60,
                child: Text(
                  "Duration",
                  style: TextStyle(
                    fontSize: 14,
                    letterSpacing: 14 * 0.03,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (displayLike) const SizedBox(width: 52),
              const SizedBox(width: 68),
            ],
          ),
        ),
      ),
    );
  }
}

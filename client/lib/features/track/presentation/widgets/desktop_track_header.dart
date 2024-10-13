import 'package:flutter/material.dart';

class DesktopTrackHeader extends StatelessWidget {
  final bool displayDateAdded;

  final bool displayAlbum;
  final bool displayLike;

  final bool displayLastPlayed;
  final bool displayPlayedCount;
  final bool displayQuality;

  const DesktopTrackHeader({
    super.key,
    this.displayDateAdded = false,
    this.displayAlbum = true,
    this.displayLike = true,
    this.displayLastPlayed = false,
    this.displayPlayedCount = false,
    this.displayQuality = false,
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
              if (displayLastPlayed) const SizedBox(width: 8),
              if (displayLastPlayed)
                const SizedBox(
                  width: 96,
                  child: Text(
                    "Last Played",
                    style: TextStyle(
                      fontSize: 14,
                      letterSpacing: 14 * 0.03,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              if (displayPlayedCount)
                const SizedBox(
                  width: 40,
                  child: Text(
                    "Count",
                    style: TextStyle(
                      fontSize: 14,
                      letterSpacing: 14 * 0.03,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              if (displayPlayedCount) const SizedBox(width: 24),
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
              if (displayDateAdded && !displayQuality)
                const SizedBox(width: 24),
              if (displayQuality)
                const SizedBox(
                  width: 128,
                  child: Text(
                    "Quality",
                    style: TextStyle(
                      fontSize: 14,
                      letterSpacing: 14 * 0.03,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              if (displayQuality) const SizedBox(width: 24),
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

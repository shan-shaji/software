/*
 * Copyright (C) 2022 Canonical Ltd
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 3 as
 * published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:snapd/snapd.dart';
import 'package:software/app/common/app_finding.dart';
import 'package:software/app/common/app_icon.dart';
import 'package:software/app/common/app_rating.dart';
import 'package:software/app/common/constants.dart';
import 'package:software/app/common/packagekit/package_page.dart';
import 'package:software/app/common/rating_model.dart';
import 'package:software/app/common/snap/snap_page.dart';
import 'package:software/l10n/l10n.dart';
import 'package:software/services/appstream/appstream_utils.dart'
    as appstream_icons;
import 'package:software/snapx.dart';
import 'package:yaru_icons/yaru_icons.dart';
import 'package:yaru_widgets/yaru_widgets.dart';

class AppBanner extends StatelessWidget {
  const AppBanner({
    super.key,
    required this.appFinding,
    required this.showSnap,
    required this.showPackageKit,
    this.enableSearch = true,
    this.preferSnap = true,
  });

  final MapEntry<String, AppFinding> appFinding;
  final bool showSnap;
  final bool showPackageKit;
  final bool enableSearch;
  final bool preferSnap;

  @override
  Widget build(BuildContext context) {
    var onTap = appFinding.value.snap != null &&
            appFinding.value.appstream != null &&
            showSnap &&
            showPackageKit
        ? () => preferSnap
            ? SnapPage.push(
                context: context,
                snap: appFinding.value.snap!,
                appstream: appFinding.value.appstream,
                enableSearch: enableSearch,
              )
            : PackagePage.push(
                context,
                appstream: appFinding.value.appstream!,
                snap: appFinding.value.snap,
                enableSearch: enableSearch,
              )
        : () {
            if (appFinding.value.appstream != null && showPackageKit) {
              PackagePage.push(
                context,
                appstream: appFinding.value.appstream!,
                snap: appFinding.value.snap,
                enableSearch: enableSearch,
              );
            }
            if (appFinding.value.snap != null && showSnap) {
              SnapPage.push(
                context: context,
                snap: appFinding.value.snap!,
                appstream: appFinding.value.appstream,
                enableSearch: enableSearch,
              );
            }
          };
    var iconUrl =
        appFinding.value.snap?.iconUrl ?? appFinding.value.appstream?.icon;
    var title = appFinding.key;

    var subtitle = SearchBannerSubtitle(
      appFinding: appFinding.value,
      showSnap: showSnap,
      showPackageKit: showPackageKit,
    );

    var appIcon = Padding(
      padding: const EdgeInsets.only(bottom: 55, right: 5),
      child: AppIcon(
        size: 40,
        iconUrl: iconUrl,
      ),
    );

    return YaruBanner.tile(
      padding: const EdgeInsets.only(
        left: kYaruPagePadding,
        right: kYaruPagePadding,
      ),
      title: Text(
        title,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: subtitle,
      icon: appIcon,
      onTap: onTap,
    );
  }
}

class AppImageBanner extends StatelessWidget {
  const AppImageBanner({super.key, required this.snap});

  final Snap snap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    var light = theme.brightness == Brightness.light;

    final fallBackLoadingIcon = Shimmer.fromColors(
      baseColor: light ? kShimmerBaseLight : kShimmerBaseDark,
      highlightColor: light ? kShimmerHighLightLight : kShimmerHighLightDark,
      child: Container(
        color: light ? kShimmerBaseLight : kShimmerBaseDark,
        height: 300,
        width: 480,
      ),
    );

    return YaruBanner(
      padding: EdgeInsets.zero,
      onTap: () => SnapPage.push(
        context: context,
        snap: snap,
      ),
      child: Column(
        children: [
          SizedBox(
            height: 160,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
              child: CachedNetworkImage(
                imageUrl: snap.bannerUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => fallBackLoadingIcon,
                errorWidget: (context, url, error) => fallBackLoadingIcon,
              ),
            ),
          ),
          const SizedBox(
            height: 5,
          ),
          Expanded(
            child: YaruTile(
              leading: Padding(
                padding: const EdgeInsets.only(bottom: 55, right: 5),
                child: AppIcon(
                  size: 40,
                  iconUrl: snap.iconUrl,
                ),
              ),
              style: YaruTileStyle.banner,
              padding: const EdgeInsets.only(
                left: 15,
                right: 15,
                top: 6,
                bottom: 5,
              ),
              title: Text(
                snap.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: SearchBannerSubtitle(
                appFinding: AppFinding(snap: snap),
              ),
            ),
          )
        ],
      ),
    );
  }
}

class SearchBannerSubtitle extends StatelessWidget {
  const SearchBannerSubtitle({
    super.key,
    required this.appFinding,
    this.showSnap = true,
    this.showPackageKit = true,
  });

  final AppFinding appFinding;
  final bool showSnap, showPackageKit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final light = theme.brightness == Brightness.light;

    String? ratingId =
        appFinding.snap?.ratingId ?? appFinding.appstream?.ratingId;
    final publisherName = appFinding.snap?.publisher?.displayName ??
        appFinding.appstream?.developerName[View.of(context)
            .platformDispatcher
            .locale
            .countryCode
            ?.toLowerCase()] ??
        appFinding.appstream?.developerName['C'] ??
        appFinding.appstream?.localizedName() ??
        context.l10n.unknown;

    final rating = ratingId != null
        ? context.select((RatingModel m) => m.getRating(ratingId))
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 150),
              child: Text(
                publisherName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: theme.hintColor,
                ),
              ),
            ),
            if (appFinding.snap?.verified == true)
              Padding(
                padding: const EdgeInsets.only(left: 5),
                child: Icon(
                  Icons.verified,
                  color: light ? kGreenLight : kGreenDark,
                  size: 12,
                ),
              ),
            if (appFinding.snap?.starredDeveloper == true)
              const Padding(
                padding: EdgeInsets.only(left: 5),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      Icons.circle,
                      color: Colors.white,
                      size: 9,
                    ),
                    Icon(
                      Icons.stars,
                      color: kStarDevColor,
                      size: 12,
                    ),
                  ],
                ),
              )
          ],
        ),
        const SizedBox(
          height: 10,
        ),
        Text(
          appFinding.snap?.summary ??
              appFinding.appstream?.localizedSummary() ??
              '',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        Padding(
          padding: const EdgeInsets.only(top: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  RatingBar.builder(
                    initialRating: rating?.average ?? 0,
                    minRating: 1,
                    direction: Axis.horizontal,
                    allowHalfRating: true,
                    itemCount: 5,
                    itemPadding: EdgeInsets.zero,
                    itemSize: 18,
                    itemBuilder: (context, _) => const Icon(
                      YaruIcons.star_filled,
                      color: kStarColor,
                    ),
                    unratedColor: theme.colorScheme.onSurface.withOpacity(0.2),
                    onRatingUpdate: (rating) {},
                    ignoreGestures: true,
                  ),
                  const SizedBox(width: 5),
                  Text(rating?.total.toString() ?? ''),
                ],
              ),
              PackageIndicator(
                appFinding: appFinding,
                showSnap: showSnap,
                showPackageKit: showPackageKit,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class PackageIndicator extends StatelessWidget {
  const PackageIndicator({
    super.key,
    required this.appFinding,
    this.showSnap = true,
    this.showPackageKit = true,
  });

  final AppFinding appFinding;
  final bool showSnap;
  final bool showPackageKit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        if (appFinding.snap != null && showSnap)
          Icon(
            YaruIcons.snapcraft,
            color: theme.disabledColor,
            size: 20,
          ),
        if (appFinding.appstream != null && showPackageKit)
          Padding(
            padding: const EdgeInsets.only(left: 5),
            child: Icon(
              YaruIcons.debian,
              color: theme.disabledColor,
              size: 20,
            ),
          )
      ],
    );
  }
}

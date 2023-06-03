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
import 'package:shimmer/shimmer.dart';
import 'package:software/app/common/constants.dart';
import 'package:yaru_icons/yaru_icons.dart';

class AppIcon extends StatelessWidget {
  const AppIcon({
    super.key,
    required this.iconUrl,
    this.size = 45,
    this.loadingHighlight,
    this.loadingBaseColor,
  });

  final String? iconUrl;
  final double size;
  final Color? loadingHighlight;
  final Color? loadingBaseColor;

  @override
  Widget build(BuildContext context) {
    final fallBackIcon = YaruPlaceholderIcon(size: Size.square(size));

    final theme = Theme.of(context);
    var light = theme.brightness == Brightness.light;
    final fallBackLoadingIcon = Shimmer.fromColors(
      baseColor:
          loadingBaseColor ?? (light ? kShimmerBaseLight : kShimmerBaseDark),
      highlightColor: loadingHighlight ??
          (light ? kShimmerHighLightLight : kShimmerHighLightDark),
      child: fallBackIcon,
    );

    return RepaintBoundary(
      child: iconUrl == null || iconUrl!.isEmpty
          ? fallBackIcon
          : SizedBox(
              height: size,
              width: size,
              child: CachedNetworkImage(
                imageUrl: iconUrl!,
                imageBuilder: (context, imageProvider) => Image(
                  image: imageProvider,
                  filterQuality: FilterQuality.medium,
                  fit: BoxFit.fitHeight,
                ),
                placeholder: (context, url) => fallBackLoadingIcon,
                errorWidget: (context, url, error) => fallBackIcon,
              ),
            ),
    );
  }
}

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gtk_application/gtk_application.dart';
import 'package:launcher_entry/launcher_entry.dart';
import 'package:mocktail/mocktail.dart';
import 'package:packagekit/packagekit.dart';
import 'package:snapd/snapd.dart';
import 'package:software/app/app.dart';
import 'package:software/app/common/snap/snap_section.dart';
import 'package:software/services/appstream/appstream_service.dart';
import 'package:software/services/packagekit/package_service.dart';
import 'package:software/services/packagekit/updates_state.dart';
import 'package:software/services/snap_service.dart';
import 'package:ubuntu_service/ubuntu_service.dart';
import 'package:badges/badges.dart' as badges;

class MockAppstreamService extends Mock implements AppstreamService {}

class MockConnectivity extends Mock implements Connectivity {}

class MockPackageService extends Mock implements PackageService {}

class MockSnapService extends Mock implements SnapService {}

class MockGtkApplicationNotifier extends Mock
    implements GtkApplicationNotifier {}

class MockLauncherEntryService extends Mock implements LauncherEntryService {}

void main() {
  testWidgets('Software app', (tester) async {
    final connectivityMock = MockConnectivity();
    registerMockService<Connectivity>(connectivityMock);
    final connectivityChangedController =
        StreamController<ConnectivityResult>.broadcast();
    when(() => connectivityMock.onConnectivityChanged)
        .thenAnswer((_) => connectivityChangedController.stream);
    when(connectivityMock.checkConnectivity)
        .thenAnswer((_) async => ConnectivityResult.none);

    final appstreamServiceMock = MockAppstreamService();
    registerMockService<AppstreamService>(appstreamServiceMock);
    when(appstreamServiceMock.init).thenAnswer((_) async {});

    final packageServiceMock = MockPackageService();
    registerMockService<PackageService>(packageServiceMock);
    when(packageServiceMock.init).thenAnswer((_) async {});
    when(() => packageServiceMock.initialized).thenAnswer((_) async {});
    when(() => packageServiceMock.isAvailable).thenReturn(true);
    when(() => packageServiceMock.updates)
        .thenReturn([const PackageKitPackageId(name: 'foo', version: '1')]);
    final updatesChangedController = StreamController<bool>.broadcast();
    when(() => packageServiceMock.updatesChanged)
        .thenAnswer((_) => updatesChangedController.stream);
    final updatesStateController = StreamController<UpdatesState>.broadcast();
    when(() => packageServiceMock.updatesState)
        .thenAnswer((_) => updatesStateController.stream);
    final updatesPercentageController = StreamController<int?>.broadcast();
    when(() => packageServiceMock.updatesPercentage)
        .thenAnswer((_) => updatesPercentageController.stream);

    final snapServiceMock = MockSnapService();
    registerMockService<SnapService>(snapServiceMock);
    when(snapServiceMock.init).thenAnswer((_) async {});

    when(() => snapServiceMock.sectionNameToSnapsMap).thenReturn({});
    final snapSectionsChangedController =
        StreamController<SnapSection>.broadcast();
    when(() => snapServiceMock.sectionsChanged)
        .thenAnswer((_) => snapSectionsChangedController.stream);

    when(() => snapServiceMock.snapChanges).thenReturn({});
    final snapChangesInsertedController = StreamController<bool>.broadcast();
    when(() => snapServiceMock.snapChangesInserted)
        .thenAnswer((_) => snapChangesInsertedController.stream);
    when(
      () => snapServiceMock.findSnapsBySection(
        sectionName: any(named: 'sectionName'),
      ),
    ).thenAnswer((_) async => []);
    when(() => snapServiceMock.snapsWithUpdate).thenReturn(
      UnmodifiableListView([const Snap(name: 'bar'), const Snap(name: 'baz')]),
    );

    final gtkApplicationNotifierMock = MockGtkApplicationNotifier();
    registerMockService<GtkApplicationNotifier>(gtkApplicationNotifierMock);
    when(() => gtkApplicationNotifierMock.commandLine).thenAnswer((_) => []);

    final launcherEntryServiceMock = MockLauncherEntryService();
    registerMockService<LauncherEntryService>(launcherEntryServiceMock);
    when(launcherEntryServiceMock.update).thenAnswer((_) async {});

    await tester.pumpWidget(App.create());
    await tester.pumpAndSettle();

    final badge = find.widgetWithText(badges.Badge, '3');
    expect(badge, findsOneWidget);
  });
}

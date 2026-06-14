import 'package:exptlorer/src/rust/api/disk.dart';
import 'package:exptlorer/src/utils/num.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'drives.g.dart';
part 'drives.freezed.dart';

enum DriveKind {
  hdd,
  sdd;

  static DriveKind fromDiskKind(DiskKind kind) {
    return switch (kind) {
      DiskKind_HDD() => DriveKind.hdd,
      DiskKind_SSD() => DriveKind.sdd,
      DiskKind_Unknown() => throw UnimplementedError(),
    };
  }
}

@unfreezed
abstract class Drive with _$Drive {
  factory Drive({
    required DriveKind kind,
    required String name,
    required String fileSystem,
    required String mountPoint,
    required int totalSpace,
    required int availableSpace,
    required bool isRemovable,
    required bool isReadOnly,
    required DiskUsage usage,
  }) = _Drive;

  factory Drive.fromDiskInfo(DiskInfo info) => _Drive(
    kind: DriveKind.fromDiskKind(info.kind()),
    name: info.name(),
    fileSystem: info.fileSystem(),
    mountPoint: info.mountPoint(),
    totalSpace: (info.totalSpace()).toIntSafe(),
    availableSpace: (info.availableSpace()).toIntSafe(),
    isRemovable: info.isRemovable(),
    isReadOnly: info.isReadOnly(),
    usage: info.usage(),
  );

  Drive._();

  @override
  late final int usedSpace = totalSpace - availableSpace;
}

extension on List<Drive> {
  void sortByMountPoint() {
    sort((a, b) => a.mountPoint.compareTo(b.mountPoint));
  }
}

class Drives {
  List<Drive> drives;
  Drives(this.drives);

  Drives.fromDiskInfo(List<DiskInfo> infos)
    : this(
        infos //
            .map((d) => Drive.fromDiskInfo(d))
            .toList()
          ..sortByMountPoint(),
      );
}

@riverpod
class DrivesController extends _$DrivesController {
  @override
  FutureOr<Drives> build() async {
    final ds = await disks();
    return Drives.fromDiskInfo(ds);
  }
}

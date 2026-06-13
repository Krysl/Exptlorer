pub use sysinfo::{Disk, DiskKind, DiskUsage, Disks, System};

use flutter_rust_bridge::frb;
use doc_from::doc_from;

/// 镜像声明：告诉 FRB 如何序列化 sysinfo::DiskKind
#[doc_from("sysinfo::DiskKind")]
#[frb(mirror(DiskKind))]
pub enum _DiskKind {
    HDD,
    SSD,
    Unknown(isize),
}

#[doc_from("sysinfo::DiskRefreshKind")]
pub struct DiskRefreshKind {
    pub kind: bool,
    pub storage: bool,
    pub io_usage: bool,
}
impl DiskRefreshKind {
    pub fn everything() -> Self {
        Self {
            kind: true,
            storage: true,
            io_usage: true,
        }
    }
}

#[frb(mirror(DiskUsage))]
pub struct _DiskUsage {
    pub total_written_bytes: u64,
    pub written_bytes: u64,
    pub total_read_bytes: u64,
    pub read_bytes: u64,
}

pub fn disks() -> Vec<DiskInfo> {
    disks_info(Disks::new_with_refreshed_list())
}

/// 可被 FRB 序列化的磁盘信息结构体，Dart 侧会生成同名类
pub struct DiskInfo {
    inner: Disk,
}

impl DiskInfo {
    #[doc_from("sysinfo::Disk.kind")]
    pub fn kind(&self) -> DiskKind {
        self.inner.kind()
    }

    #[doc_from("sysinfo::Disk.name")]
    pub fn name(&self) -> String {
        self.inner.name().to_string_lossy().to_string()
    }

    #[doc_from("sysinfo::Disk.file_system")]
    pub fn file_system(&self) -> String {
        self.inner.file_system().to_string_lossy().to_string()
    }

    #[doc_from("sysinfo::Disk.mount_point")]
    pub fn mount_point(&self) -> String {
        self.inner.mount_point().to_string_lossy().to_string()
    }

    #[doc_from("sysinfo::Disk.total_space")]
    pub fn total_space(&self) -> u64 {
        self.inner.total_space()
    }

    #[doc_from("sysinfo::Disk.available_space")]
    pub fn available_space(&self) -> u64 {
        self.inner.available_space()
    }

    #[doc_from("sysinfo::Disk.is_removable")]
    pub fn is_removable(&self) -> bool {
        self.inner.is_removable()
    }

    #[doc_from("sysinfo::Disk.is_read_only")]
    pub fn is_read_only(&self) -> bool {
        self.inner.is_read_only()
    }

    #[doc_from("sysinfo::Disk.refresh")]
    pub fn refresh(&mut self) -> bool {
        self.refresh_specifics(DiskRefreshKind::everything())
    }

    #[doc_from("sysinfo::Disk.refresh_specifics")]
    pub fn refresh_specifics(&mut self, refreshes: DiskRefreshKind) -> bool {
        let mut r = sysinfo::DiskRefreshKind::nothing();
        if refreshes.kind { r = r.with_kind(); }
        if refreshes.storage { r = r.with_storage(); }
        if refreshes.io_usage { r = r.with_io_usage(); }
        self.inner.refresh_specifics(r)
    }

    #[doc_from("sysinfo::Disk.usage")]
    pub fn usage(&self) -> DiskUsage {
        self.inner.usage()
    }
}

/// 从 Disks 不透明对象中提取所有磁盘的详细信息
fn disks_info(disks: Disks) -> Vec<DiskInfo> {
    // Disks 实现了 From<Disks> for Vec<Disk>，可以拿到 owned Disk
    let disks: Vec<Disk> = disks.into();
    disks
        .into_iter()
        .map(|disk| DiskInfo { inner: disk })
        .collect()
}

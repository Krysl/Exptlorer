use std::ffi::OsStr;
use std::mem;
use std::os::windows::ffi::OsStrExt;
use std::sync::Mutex;
use windows_sys::core::PCWSTR;

// SHGetFileInfoW 和 GDI 操作不是线程安全的，全局锁串行化
static ICON_LOCK: Mutex<()> = Mutex::new(());
use windows_sys::Win32::Graphics::Gdi::{
    CreateCompatibleDC, DeleteDC, DeleteObject, GetDIBits, GetObjectW, SelectObject, BITMAP,
    BITMAPINFO, BITMAPINFOHEADER, BI_RGB, DIB_RGB_COLORS, HDC,
};
use windows_sys::Win32::UI::Shell::{
    SHGetFileInfoW, SHFILEINFOW, SHGFI_ICON, SHGFI_LARGEICON, SHGFI_SMALLICON,
};
use windows_sys::Win32::UI::WindowsAndMessaging::{DestroyIcon, GetIconInfo, ICONINFO};

pub struct IconData {
    pub width: i32,
    pub height: i32,
    pub bgra_bytes: Vec<u8>,
}

pub enum IconSize {
    Large,
    Small,
}

pub fn get_icon_rgba(path: String, size: Option<IconSize>) -> Option<IconData> {
    get_file_icon_rgba_full(path, size.unwrap_or(IconSize::Large))
}

fn get_file_icon_rgba_full(path: String, size: IconSize) -> Option<IconData> {
    let wide: Vec<u16> = OsStr::new(&path)
        .encode_wide()
        .chain(std::iter::once(0))
        .collect();
    // 全局锁：SHGetFileInfoW 和 GDI 非线程安全
    let _lock = ICON_LOCK.lock().ok()?;
    unsafe {
        let mut info: SHFILEINFOW = mem::zeroed();
        let size_flag = match size {
            IconSize::Large => SHGFI_LARGEICON,
            IconSize::Small => SHGFI_SMALLICON,
        };

        // 直接访问真实路径，不设 USEFILEATTRIBUTES，驱动器才能返回正确图标
        let ret = SHGetFileInfoW(
            wide.as_ptr() as PCWSTR,
            0,
            &mut info,
            mem::size_of::<SHFILEINFOW>() as u32,
            SHGFI_ICON | size_flag,
        );
        if ret == 0 || info.hIcon.is_null() {
            return None;
        }
        let hicon = info.hIcon;
        let result = icon_to_rgba(hicon);
        DestroyIcon(hicon);
        result
    }
}

unsafe fn icon_to_rgba(hicon: *mut std::ffi::c_void) -> Option<IconData> {
    let mut icon_info: ICONINFO = mem::zeroed();
    if GetIconInfo(hicon, &mut icon_info) == 0 {
        return None;
    }

    let color_bitmap = icon_info.hbmColor;
    let mask_bitmap = icon_info.hbmMask;

    let mut bitmap: BITMAP = mem::zeroed();
    let mut get_bmp = |hbm: *mut std::ffi::c_void| -> bool {
        GetObjectW(
            hbm as _,
            mem::size_of::<BITMAP>() as i32,
            &mut bitmap as *mut _ as *mut _,
        ) != 0
    };

    if !get_bmp(color_bitmap) && !get_bmp(mask_bitmap) {
        DeleteObject(color_bitmap as _);
        DeleteObject(mask_bitmap as _);
        return None;
    }

    let width = bitmap.bmWidth;
    let has_color = !color_bitmap.is_null();
    let height = bitmap.bmHeight / if has_color { 1 } else { 2 };

    let hdc: HDC = CreateCompatibleDC(std::ptr::null_mut());
    if hdc.is_null() {
        DeleteObject(color_bitmap as _);
        DeleteObject(mask_bitmap as _);
        return None;
    }

    let bpp: u16 = 32;
    let mut bmi_header: BITMAPINFOHEADER = mem::zeroed();
    bmi_header.biSize = mem::size_of::<BITMAPINFOHEADER>() as u32;
    bmi_header.biWidth = width;
    bmi_header.biHeight = -height;
    bmi_header.biPlanes = 1;
    bmi_header.biBitCount = bpp;
    bmi_header.biCompression = BI_RGB;

    let bmi = BITMAPINFO {
        bmiHeader: bmi_header,
        bmiColors: [Default::default()],
    };
    let row_size = (width * (bpp as i32) + 31) / 32 * 4;
    let pixel_count = (row_size * height) as usize;
    let mut raw_bgra: Vec<u8> = vec![0u8; pixel_count];

    let old_bmp = SelectObject(hdc, color_bitmap as _);
    if old_bmp.is_null() {
        DeleteDC(hdc);
        DeleteObject(color_bitmap as _);
        DeleteObject(mask_bitmap as _);
        return None;
    }

    let success = GetDIBits(
        hdc,
        color_bitmap as _,
        0,
        height as u32,
        raw_bgra.as_mut_ptr() as _,
        &bmi as *const _ as *mut _,
        DIB_RGB_COLORS,
    );

    SelectObject(hdc, old_bmp);
    DeleteDC(hdc);
    DeleteObject(color_bitmap as _);
    DeleteObject(mask_bitmap as _);

    if success == 0 {
        return None;
    }

    Some(IconData {
        width,
        height,
        bgra_bytes: raw_bgra,
    })
}

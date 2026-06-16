pub fn open_path(path: String) -> Result<(), String> {
    opener::open(path).map_err(|e| e.to_string())
}

pub fn open_url(url: String) -> Result<(), String> {
    opener::open_browser(url).map_err(|e| e.to_string())
}
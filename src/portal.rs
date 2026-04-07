use std::sync::OnceLock;

use gtk4::glib;

static RUNTIME: OnceLock<tokio::runtime::Runtime> = OnceLock::new();

fn runtime() -> &'static tokio::runtime::Runtime {
    RUNTIME.get_or_init(|| {
        tokio::runtime::Builder::new_current_thread()
            .enable_all()
            .build()
            .expect("failed to build tokio runtime")
    })
}

/// Run a closure on a background thread and deliver the result to the GLib main
/// loop via a 16ms polling timer.
pub fn spawn_background<T, F, C>(work: F, callback: C)
where
    T: Send + 'static,
    F: FnOnce() -> T + Send + 'static,
    C: FnOnce(T) + 'static,
{
    let (tx, rx) = std::sync::mpsc::channel::<T>();
    std::thread::spawn(move || {
        let _ = tx.send(work());
    });
    let mut callback = Some(callback);
    glib::timeout_add_local(std::time::Duration::from_millis(16), move || {
        match rx.try_recv() {
            Ok(result) => {
                if let Some(cb) = callback.take() {
                    cb(result);
                }
                glib::ControlFlow::Break
            }
            Err(std::sync::mpsc::TryRecvError::Empty) => glib::ControlFlow::Continue,
            Err(std::sync::mpsc::TryRecvError::Disconnected) => glib::ControlFlow::Break,
        }
    });
}

/// Run an async portal operation on the shared Tokio runtime and deliver the
/// result to the GLib main loop.
pub fn spawn_portal<T, F, C>(future_fn: F, callback: C)
where
    T: Send + 'static,
    F: FnOnce() -> std::pin::Pin<Box<dyn std::future::Future<Output = T> + Send>> + Send + 'static,
    C: FnOnce(T) + 'static,
{
    let (tx, rx) = std::sync::mpsc::channel::<T>();
    runtime().spawn(async move {
        let result = future_fn().await;
        let _ = tx.send(result);
    });
    let mut callback = Some(callback);
    glib::timeout_add_local(std::time::Duration::from_millis(16), move || {
        match rx.try_recv() {
            Ok(result) => {
                if let Some(cb) = callback.take() {
                    cb(result);
                }
                glib::ControlFlow::Break
            }
            Err(std::sync::mpsc::TryRecvError::Empty) => glib::ControlFlow::Continue,
            Err(std::sync::mpsc::TryRecvError::Disconnected) => glib::ControlFlow::Break,
        }
    });
}

/// Capture an interactive screenshot via the XDG Desktop Portal (Linux).
#[cfg(target_os = "linux")]
pub async fn request_screenshot() -> Result<String, String> {
    use ashpd::desktop::screenshot::Screenshot;

    let response = Screenshot::request()
        .interactive(true)
        .modal(false)
        .send()
        .await
        .map_err(|e| e.to_string())?
        .response()
        .map_err(|e| e.to_string())?;

    Ok(response.uri().to_string())
}

/// Capture an interactive screenshot using `screencapture -i` (macOS).
#[cfg(target_os = "macos")]
pub async fn request_screenshot() -> Result<String, String> {
    let path = std::env::temp_dir().join("rustylens_screenshot.png");
    let path_str = path.to_string_lossy().to_string();
    let status = tokio::task::spawn_blocking({
        let path_str = path_str.clone();
        move || {
            std::process::Command::new("screencapture")
                .args(["-i", &path_str])
                .status()
        }
    })
    .await
    .map_err(|e| e.to_string())?
    .map_err(|e| format!("screencapture failed: {e}"))?;

    if status.success() && path.exists() {
        Ok(format!("file://{path_str}"))
    } else {
        Err("Screenshot cancelled".to_owned())
    }
}

/// Screenshot capture is not supported on Windows.
#[cfg(target_os = "windows")]
pub async fn request_screenshot() -> Result<String, String> {
    Err("Screenshot capture is not supported on Windows".to_owned())
}

/// Open a file chooser via the XDG FileChooser Portal (Linux).
#[cfg(target_os = "linux")]
pub async fn pick_file() -> Result<Option<String>, String> {
    use ashpd::desktop::file_chooser::OpenFileRequest;

    let response = OpenFileRequest::default()
        .title("Select an Image")
        .modal(true)
        .send()
        .await
        .map_err(|e| e.to_string())?
        .response()
        .map_err(|e| e.to_string())?;

    let uris = response.uris();
    if uris.is_empty() {
        return Ok(None);
    }

    Ok(Some(uris[0].to_string()))
}

/// Open a native file chooser dialog (macOS / Windows).
/// Returns `None` if the user cancelled.
#[cfg(not(target_os = "linux"))]
pub async fn pick_file() -> Result<Option<String>, String> {
    let path = tokio::task::spawn_blocking(|| {
        rfd::FileDialog::new()
            .add_filter(
                "Images",
                &["png", "jpg", "jpeg", "bmp", "tiff", "tif", "webp", "gif"],
            )
            .pick_file()
    })
    .await
    .map_err(|e| e.to_string())?;

    // Return the raw path string; uri_to_path handles both file:// URIs and plain paths.
    Ok(path.map(|p| p.to_string_lossy().into_owned()))
}

/// Convert a `file://` URI to a filesystem path, decoding percent-encoded
/// characters (e.g. `%20` → space).
pub fn uri_to_path(uri: &str) -> String {
    let path = uri.strip_prefix("file://").unwrap_or(uri);
    percent_decode(path)
}

fn percent_decode(input: &str) -> String {
    let mut out = Vec::with_capacity(input.len());
    let bytes = input.as_bytes();
    let mut i = 0;
    while i < bytes.len() {
        if bytes[i] == b'%' && i + 2 < bytes.len()
            && let Ok(byte) = u8::from_str_radix(&input[i + 1..i + 3], 16)
        {
            out.push(byte);
            i += 3;
            continue;
        }
        out.push(bytes[i]);
        i += 1;
    }
    String::from_utf8(out).unwrap_or_else(|_| input.to_owned())
}

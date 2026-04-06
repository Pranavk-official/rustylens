mod ocr;
mod portal;
mod ui;

use gtk4::prelude::*;
use libadwaita as adw;

fn main() {
    let capture_mode = std::env::args().any(|a| a == "--capture");

    let app = adw::Application::builder()
        .application_id("com.example.RustyLens")
        .build();

    app.connect_activate(move |app| {
        let (window, state) = ui::build_main_window(app);

        if capture_mode {
            let state = state.clone();
            portal::spawn_portal(
                || Box::pin(portal::request_screenshot()),
                move |result| match result {
                    Ok(uri) => {
                        let path = portal::uri_to_path(&uri);
                        ui::load_image_path(&path, &state);
                    }
                    Err(e) => {
                        eprintln!("Screenshot portal error: {e}");
                        state
                            .toast_overlay
                            .add_toast(adw::Toast::new("Screenshot failed"));
                    }
                },
            );
        }

        window.present();
    });

    app.run_with_args::<&str>(&[]);
}

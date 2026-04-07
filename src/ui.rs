use std::{cell::RefCell, collections::BTreeSet, rc::Rc};

use gtk4::{self as gtk, cairo, glib, prelude::*};
use libadwaita as adw;

use crate::ocr::{self, OcrResult};
use crate::portal;

// ---------------------------------------------------------------------------
// AppState
// ---------------------------------------------------------------------------

/// Widgets and mutable state shared between closures in the main window.
#[derive(Clone)]
pub struct AppState {
    pub picture: gtk::Picture,
    pub drawing_area: gtk::DrawingArea,
    pub text_buffer: gtk::TextBuffer,
    pub copy_btn: gtk::Button,
    pub toast_overlay: adw::ToastOverlay,
    pub ocr_result: Rc<RefCell<Option<OcrResult>>>,
    lang_dropdown: gtk::DropDown,
    lang_list: Vec<String>,
    /// Indices of currently selected (highlighted) words.
    selected_words: Rc<RefCell<BTreeSet<usize>>>,
    /// Anchor word index where the drag started (for range selection).
    anchor_index: Rc<RefCell<Option<usize>>>,
}

impl AppState {
    fn selected_lang(&self) -> String {
        let idx = self.lang_dropdown.selected();
        if idx == 0 {
            self.lang_list[1..].join("+")
        } else {
            self.lang_list
                .get(idx as usize)
                .cloned()
                .unwrap_or_else(|| "eng".to_owned())
        }
    }
}

// ---------------------------------------------------------------------------
// Window construction
// ---------------------------------------------------------------------------

pub fn build_main_window(app: &adw::Application) -> (adw::ApplicationWindow, AppState) {
    let header = adw::HeaderBar::new();

    let open_btn = gtk::Button::builder()
        .label("Open Image")
        .css_classes(["suggested-action"])
        .build();

    let copy_btn = gtk::Button::builder()
        .label("Copy All Text")
        .sensitive(false)
        .build();

    // Language selector
    let mut lang_list: Vec<String> = vec!["Auto (all)".to_owned()];
    lang_list.extend(ocr::installed_languages());

    let lang_strings: Vec<&str> = lang_list.iter().map(|s| s.as_str()).collect();
    let lang_dropdown = gtk::DropDown::from_strings(&lang_strings);
    lang_dropdown.set_selected(0);
    lang_dropdown.set_tooltip_text(Some("OCR language"));

    header.pack_start(&open_btn);
    header.pack_start(&lang_dropdown);
    header.pack_end(&copy_btn);

    let picture = gtk::Picture::builder()
        .content_fit(gtk::ContentFit::Contain)
        .hexpand(true)
        .vexpand(true)
        .build();

    let drawing_area = gtk::DrawingArea::builder()
        .hexpand(true)
        .vexpand(true)
        .build();

    let overlay = gtk::Overlay::builder()
        .hexpand(true)
        .vexpand(true)
        .build();
    overlay.set_child(Some(&picture));
    overlay.add_overlay(&drawing_area);

    let text_buffer = gtk::TextBuffer::new(None);
    text_buffer.set_text("Open an image to extract text.");

    let text_view = gtk::TextView::builder()
        .buffer(&text_buffer)
        .editable(false)
        .cursor_visible(true)
        .wrap_mode(gtk::WrapMode::WordChar)
        .top_margin(8)
        .bottom_margin(8)
        .left_margin(12)
        .right_margin(12)
        .build();

    let scrolled = gtk::ScrolledWindow::builder()
        .child(&text_view)
        .hscrollbar_policy(gtk::PolicyType::Never)
        .vscrollbar_policy(gtk::PolicyType::Automatic)
        .height_request(150)
        .build();

    let vbox = gtk::Box::new(gtk::Orientation::Vertical, 0);
    vbox.append(&overlay);
    vbox.append(&gtk::Separator::new(gtk::Orientation::Horizontal));
    vbox.append(&scrolled);

    let toast_overlay = adw::ToastOverlay::new();
    toast_overlay.set_child(Some(&vbox));

    let toolbar_view = adw::ToolbarView::new();
    toolbar_view.add_top_bar(&header);
    toolbar_view.set_content(Some(&toast_overlay));

    let window = adw::ApplicationWindow::builder()
        .application(app)
        .title("RustyLens")
        .default_width(860)
        .default_height(640)
        .content(&toolbar_view)
        .build();

    let state = AppState {
        picture: picture.clone(),
        drawing_area: drawing_area.clone(),
        text_buffer: text_buffer.clone(),
        copy_btn: copy_btn.clone(),
        toast_overlay: toast_overlay.clone(),
        ocr_result: Rc::new(RefCell::new(None)),
        lang_dropdown: lang_dropdown.clone(),
        lang_list: lang_list.clone(),
        selected_words: Rc::new(RefCell::new(BTreeSet::new())),
        anchor_index: Rc::new(RefCell::new(None)),
    };

    // DrawingArea draw callback
    {
        let state = state.clone();
        drawing_area.set_draw_func(move |_da, ctx, _w, _h| {
            let guard = state.ocr_result.borrow();
            if let Some(ocr) = guard.as_ref() {
                let sel = state.selected_words.borrow();
                draw_ocr_boxes(ctx, &state.picture, ocr, &sel);
            }
        });
    }

    // Click/drag on highlighted words to select them (text-editor style range)
    {
        let state = state.clone();
        let drag = gtk::GestureDrag::new();

        // On press: set anchor word, clear previous selection
        drag.connect_drag_begin({
            let state = state.clone();
            move |_, x, y| {
                let anchor = word_index_at(&state, x, y);
                *state.anchor_index.borrow_mut() = anchor;
                state.selected_words.borrow_mut().clear();
                if let Some(i) = anchor {
                    state.selected_words.borrow_mut().insert(i);
                }
                state.drawing_area.queue_draw();
            }
        });

        // While dragging: select range from anchor to current word
        drag.connect_drag_update({
            let state = state.clone();
            move |gesture, off_x, off_y| {
                let Some(anchor) = *state.anchor_index.borrow() else {
                    return;
                };
                if let Some((sx, sy)) = gesture.start_point() {
                    let current = word_index_at(&state, sx + off_x, sy + off_y);
                    let mut sel = state.selected_words.borrow_mut();
                    sel.clear();
                    if let Some(end) = current {
                        let lo = anchor.min(end);
                        let hi = anchor.max(end);
                        for i in lo..=hi {
                            sel.insert(i);
                        }
                    } else {
                        sel.insert(anchor);
                    }
                }
                state.drawing_area.queue_draw();
            }
        });

        drawing_area.add_controller(drag);
    }

    // Ctrl+C: copy selected words to clipboard
    {
        let state = state.clone();
        let ctrl_c = gtk::ShortcutController::new();
        ctrl_c.set_scope(gtk::ShortcutScope::Managed);
        ctrl_c.add_shortcut(
            gtk::Shortcut::new(
                gtk::ShortcutTrigger::parse_string("<Control>c"),
                Some(gtk::CallbackAction::new({
                    let state = state.clone();
                    move |_, _| {
                        let sel = state.selected_words.borrow();
                        if sel.is_empty() {
                            return glib::Propagation::Proceed;
                        }
                        let guard = state.ocr_result.borrow();
                        let Some(ocr) = guard.as_ref() else {
                            return glib::Propagation::Proceed;
                        };
                        let text: Vec<&str> = sel
                            .iter()
                            .filter_map(|&i| ocr.words.get(i).map(|w| w.text.as_str()))
                            .collect();
                        if text.is_empty() {
                            return glib::Propagation::Proceed;
                        }
                        let joined = text.join(" ");
                        if let Some(win) = state.drawing_area.root()
                            && let Some(win) = win.downcast_ref::<adw::ApplicationWindow>()
                        {
                            win.clipboard().set_text(&joined);
                            state.toast_overlay.add_toast(adw::Toast::new(&format!(
                                "Copied {} word{}",
                                text.len(),
                                if text.len() == 1 { "" } else { "s" }
                            )));
                        }
                        glib::Propagation::Stop
                    }
                })),
            ),
        );
        window.add_controller(ctrl_c);
    }

    // Open Image button
    {
        let state = state.clone();
        open_btn.connect_clicked(move |_| {
            let state = state.clone();
            portal::spawn_portal(
                || Box::pin(portal::pick_file()),
                move |result| match result {
                    Ok(Some(uri)) => {
                        let path = portal::uri_to_path(&uri);
                        load_image_path(&path, &state);
                    }
                    Ok(None) => {}
                    Err(e) => {
                        eprintln!("File chooser error: {e}");
                        state
                            .toast_overlay
                            .add_toast(adw::Toast::new("Could not open file chooser"));
                    }
                },
            );
        });
    }

    // Copy All Text button
    {
        let state = state.clone();
        let window_weak = window.downgrade();
        copy_btn.connect_clicked(move |_| {
            let (start, end) = state.text_buffer.bounds();
            let text = state.text_buffer.text(&start, &end, false);
            let win = window_weak.upgrade();
            if let Some(win) = win {
                win.clipboard().set_text(&text);
                state
                    .toast_overlay
                    .add_toast(adw::Toast::new("Text copied to clipboard"));
            }
        });
    }

    (window, state)
}

// ---------------------------------------------------------------------------
// Image loading + OCR trigger
// ---------------------------------------------------------------------------

pub fn load_image_path(path: &str, state: &AppState) {
    state.picture.set_filename(Some(path));
    *state.ocr_result.borrow_mut() = None;
    state.selected_words.borrow_mut().clear();
    state.text_buffer.set_text("Running OCR\u{2026}");
    state.copy_btn.set_sensitive(false);
    state.drawing_area.queue_draw();

    let path_owned = path.to_owned();
    let lang = state.selected_lang();
    let state = state.clone();

    portal::spawn_background(
        move || ocr::ocr_file(&path_owned, &lang),
        move |result| match result {
            Ok(ocr) => {
                state.text_buffer.set_text(&ocr.full_text);
                state
                    .copy_btn
                    .set_sensitive(!ocr.full_text.trim().is_empty());
                *state.ocr_result.borrow_mut() = Some(ocr);
                state.drawing_area.queue_draw();
            }
            Err(e) => {
                state
                    .text_buffer
                    .set_text(&format!("OCR error: {e}"));
                state
                    .toast_overlay
                    .add_toast(adw::Toast::new("OCR failed"));
            }
        },
    );
}

// ---------------------------------------------------------------------------
// Word hit-testing
// ---------------------------------------------------------------------------

/// Return the index of the word at widget coordinates (x, y), if any.
fn word_index_at(state: &AppState, x: f64, y: f64) -> Option<usize> {
    let guard = state.ocr_result.borrow();
    let ocr = guard.as_ref()?;
    let t = image_transform(&state.picture, ocr)?;

    for (i, word) in ocr.words.iter().enumerate() {
        let wx = t.off_x + word.x as f64 * t.scale;
        let wy = t.off_y + word.y as f64 * t.scale;
        let ww = word.w as f64 * t.scale;
        let wh = word.h as f64 * t.scale;

        if x >= wx && x <= wx + ww && y >= wy && y <= wy + wh {
            return Some(i);
        }
    }
    None
}

// ---------------------------------------------------------------------------
// Image coordinate transform
// ---------------------------------------------------------------------------

struct ImageTransform {
    scale: f64,
    off_x: f64,
    off_y: f64,
}

fn image_transform(picture: &gtk::Picture, ocr: &OcrResult) -> Option<ImageTransform> {
    let widget_w = picture.width() as f64;
    let widget_h = picture.height() as f64;
    if widget_w <= 0.0 || widget_h <= 0.0 || ocr.img_w == 0 || ocr.img_h == 0 {
        return None;
    }
    let img_w = ocr.img_w as f64;
    let img_h = ocr.img_h as f64;
    let scale = (widget_w / img_w).min(widget_h / img_h);
    let disp_w = img_w * scale;
    let disp_h = img_h * scale;
    Some(ImageTransform {
        scale,
        off_x: (widget_w - disp_w) / 2.0,
        off_y: (widget_h - disp_h) / 2.0,
    })
}

// ---------------------------------------------------------------------------
// Drawing
// ---------------------------------------------------------------------------

fn draw_ocr_boxes(
    ctx: &cairo::Context,
    picture: &gtk::Picture,
    ocr: &OcrResult,
    selected: &BTreeSet<usize>,
) {
    let Some(t) = image_transform(picture, ocr) else {
        return;
    };

    for (i, word) in ocr.words.iter().enumerate() {
        let x = t.off_x + word.x as f64 * t.scale;
        let y = t.off_y + word.y as f64 * t.scale;
        let w = word.w as f64 * t.scale;
        let h = word.h as f64 * t.scale;

        if selected.contains(&i) {
            ctx.set_source_rgba(0.2, 0.6, 1.0, 0.45);
        } else {
            ctx.set_source_rgba(0.2, 0.6, 1.0, 0.12);
        }
        ctx.rectangle(x, y, w, h);
        let _ = ctx.fill_preserve();

        if selected.contains(&i) {
            ctx.set_source_rgba(0.1, 0.4, 1.0, 0.9);
            ctx.set_line_width(1.5);
        } else {
            ctx.set_source_rgba(0.2, 0.6, 1.0, 0.5);
            ctx.set_line_width(1.0);
        }
        let _ = ctx.stroke();
    }
}

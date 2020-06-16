#![allow(unused_imports)]

// CLI: Representation and processing:
use clap::Shell;

use structopt::StructOpt;

use std::sync::{Arc, RwLock};

use actix::prelude::*;
use candid::{Decode, Encode, Nat};
use delay::Delay;
use icgt::{types::*, updater::*};
use log::*;
use num_traits::cast::ToPrimitive;
use sdl2::event::Event as SysEvent; // not to be confused with our own definition
use sdl2::event::WindowEvent;
use sdl2::keyboard::Keycode;
use std::io;
use std::time::Duration;

fn init_log(level_filter: log::LevelFilter) {
    use env_logger::{Builder, WriteStyle};
    let mut builder = Builder::new();
    builder
        .filter(None, level_filter)
        .write_style(WriteStyle::Always)
        .init();
}

use icgt::types::{
    event,
    render::{self, Elm, Fill},
};
use sdl2::render::{Canvas, RenderTarget};

fn nat_ceil(n: &Nat) -> u32 {
    n.0.to_u32().unwrap()
}

fn byte_ceil(n: &Nat) -> u8 {
    match n.0.to_u8() {
        Some(byte) => byte,
        None => 255,
    }
}

fn translate_color(c: &render::Color) -> sdl2::pixels::Color {
    match c {
        (r, g, b) => sdl2::pixels::Color::RGB(byte_ceil(r), byte_ceil(g), byte_ceil(b)),
    }
}

fn translate_rect(pos: &render::Pos, r: &render::Rect) -> sdl2::rect::Rect {
    // todo -- clip the size of the rect dimension by the bound param
    trace!("translate_rect {:?} {:?}", pos, r);
    sdl2::rect::Rect::new(
        nat_ceil(&Nat(&pos.x.0 + &r.pos.x.0)) as i32,
        nat_ceil(&Nat(&pos.y.0 + &r.pos.y.0)) as i32,
        nat_ceil(&r.dim.width),
        nat_ceil(&r.dim.height),
    )
}

fn draw_rect<T: RenderTarget>(
    canvas: &mut Canvas<T>,
    pos: &render::Pos,
    r: &render::Rect,
    f: &render::Fill,
) {
    match f {
        Fill::None => {
            // no-op.
        }
        Fill::Closed(c) => {
            let r = translate_rect(pos, r);
            let c = translate_color(c);
            canvas.set_draw_color(c);
            canvas.fill_rect(r).unwrap();
        }
        Fill::Open(c, _) => {
            let r = translate_rect(pos, r);
            let c = translate_color(c);
            canvas.set_draw_color(c);
            canvas.draw_rect(r).unwrap();
        }
    }
}

pub fn nat_zero() -> Nat {
    Nat::from(0)
}

pub fn draw_rect_elms<T: RenderTarget>(
    canvas: &mut Canvas<T>,
    pos: &render::Pos,
    dim: &render::Dim,
    fill: &render::Fill,
    elms: &render::Elms,
) -> Result<(), String> {
    draw_rect::<T>(
        canvas,
        &pos,
        &render::Rect::new(
            nat_zero(),
            nat_zero(),
            dim.width.clone(),
            dim.height.clone(),
        ),
        fill,
    );
    for elm in elms.iter() {
        draw_elm(canvas, pos, elm)?
    }
    Ok(())
}

pub fn draw_elm<T: RenderTarget>(
    canvas: &mut Canvas<T>,
    pos: &render::Pos,
    elm: &render::Elm,
) -> Result<(), String> {
    match &elm {
        &Elm::Node(node) => {
            let pos = render::Pos {
                x: Nat(&pos.x.0 + &node.rect.pos.x.0),
                y: Nat(&pos.y.0 + &node.rect.pos.y.0),
            };
            draw_rect_elms(canvas, &pos, &node.rect.dim, &node.fill, &node.elms)
        }
        &Elm::Rect(r, f) => {
            draw_rect(canvas, pos, r, f);
            Ok(())
        }
        &Elm::Text(t, ta) => {
            warn!("to do {:?} {:?}", t, ta);
            Ok(())
        }
    }
}

fn translate_system_event(event: SysEvent) -> Option<event::Event> {
    match &event {
        SysEvent::Window {
            win_event: WindowEvent::SizeChanged(w, h),
            ..
        } => {
            let dim = render::Dim {
                width: Nat::from(*w as u64),
                height: Nat::from(*h as u64),
            };
            Some(event::Event::WindowSizeChange(dim))
        }
        SysEvent::Quit { .. }
        | SysEvent::KeyDown {
            keycode: Some(Keycode::Escape),
            ..
        } => Some(event::Event::Quit),
        SysEvent::KeyDown {
            keycode: Some(ref kc),
            keymod,
            ..
        } => {
            let key = match &kc {
                Keycode::Tab => "Tab".to_string(),
                Keycode::Space => " ".to_string(),
                Keycode::Return => "Enter".to_string(),
                Keycode::Left => "ArrowLeft".to_string(),
                Keycode::Right => "ArrowRight".to_string(),
                Keycode::Up => "ArrowUp".to_string(),
                Keycode::Down => "ArrowDown".to_string(),
                Keycode::Backspace => "Backspace".to_string(),
                Keycode::LShift => "LShift".to_string(),
                keycode => {
                    info!("Unrecognized key code, ignoring event: {:?}", keycode);
                    return None;
                }
            };
            let event = event::Event::KeyDown(event::KeyEventInfo {
                key,
                // to do -- translate modifier keys,
                alt: false,
                ctrl: false,
                meta: false,
                shift: keymod.contains(sdl2::keyboard::Mod::LSHIFTMOD)
                    || keymod.contains(sdl2::keyboard::Mod::RSHIFTMOD),
            });
            Some(event)
        }
        _ => None,
    }
}

pub fn redraw<T: RenderTarget>(
    canvas: &mut Canvas<T>,
    dim: &render::Dim,
    rr: &render::Result,
) -> Result<(), String> {
    let pos = render::Pos {
        x: nat_zero(),
        y: nat_zero(),
    };
    let fill = render::Fill::Closed((nat_zero(), nat_zero(), nat_zero()));
    match rr {
        render::Result::Ok(render::Out::Draw(elm)) => {
            draw_rect_elms(canvas, &pos, dim, &fill, &vec![elm.clone()])?;
        }
        render::Result::Ok(render::Out::Redraw(elms)) => {
            if elms.len() == 1 && elms[0].0 == "screen" {
                draw_rect_elms(canvas, &pos, dim, &fill, &vec![elms[0].1.clone()])?;
            } else {
                warn!("unrecognized redraw elements {:?}", elms);
            }
        }
        render::Result::Err(render::Out::Draw(elm)) => {
            draw_rect_elms(canvas, &pos, dim, &fill, &vec![elm.clone()])?;
        }
        _ => unimplemented!(),
    };
    canvas.present();
    Ok(())
}

pub fn do_event_loop(
    cfg: &ConnectConfig,
    tick_ev: crossbeam::Receiver<render::Result>,
    key_infos: Arc<RwLock<Vec<event::KeyEventInfo>>>,
) -> Result<(), String> {
    use sdl2::event::EventType;

    let mut do_update = true;
    // let mut key_infos = vec![];
    let mut window_dim = render::Dim {
        width: Nat::from(1000),
        height: Nat::from(666),
    };
    let sdl_context = sdl2::init()?;
    let video_subsystem = sdl_context.video()?;
    let window = video_subsystem
        .window(
            "ic-game-terminal",
            nat_ceil(&window_dim.width),
            nat_ceil(&window_dim.height),
        )
        .position_centered()
        .resizable()
        //.input_grabbed()
        //.fullscreen()
        //.fullscreen_desktop()
        .build()
        .map_err(|e| e.to_string())?;

    let mut canvas = window
        .into_canvas()
        .target_texture()
        .present_vsync()
        .build()
        .map_err(|e| e.to_string())?;
    info!("Using SDL_Renderer \"{}\"", canvas.info().name);

    {
        let rr: render::Result =
            server_call(cfg, &ServerCall::WindowSizeChange(window_dim.clone()))?;
        redraw(&mut canvas, &window_dim, &rr)?;
    }

    let mut event_pump = sdl_context.event_pump()?;

    event_pump.disable_event(EventType::FingerUp);
    event_pump.disable_event(EventType::FingerDown);
    event_pump.disable_event(EventType::FingerMotion);
    event_pump.disable_event(EventType::MouseMotion);

    'running: loop {
        // Is it time for an update? Do not block; check for an event.
        let update_event = tick_ev.try_recv();

        match update_event {
            Ok(rr) => {
                // let's query state now and redraw!

                // let rr = server_call(cfg, &ServerCall::UpdateKeyDown(key_infos.clone()))?;
                *key_infos.write().unwrap() = vec![];

                redraw(&mut canvas, &window_dim, &rr)?;
            }
            Err(_) => {
                // No event
            }
        };
        // TODO(): Here we are waiting for events!!! We need to time out perhaps?
        // event_pump.poll_event()

        for event in event_pump.wait_event_timeout(100) {
            let event = translate_system_event(event);
            let event = match event {
                None => continue 'running,
                Some(event) => event,
            };
            // catch window resize event: redraw and loop:

            match event {
                event::Event::WindowSizeChange(new_dim) => {
                    debug!("WindowSizeChange {:?}", new_dim);
                    let rr: render::Result =
                        server_call(cfg, &ServerCall::WindowSizeChange(new_dim.clone()))?;
                    window_dim = new_dim;
                    redraw(&mut canvas, &window_dim, &rr)?;
                    continue 'running;
                }
                event::Event::Quit => {
                    debug!("Quit");
                    return Ok(());
                }
                event::Event::KeyUp(ref ke_info) => debug!("KeyUp {:?}", ke_info.key),
                event::Event::KeyDown(ref ke_info) => {
                    debug!("KeyDown {:?}", ke_info.key);
                    if ke_info.key == "LShift" || ke_info.key == "RShift" {
                        debug!("ignoring bare shift {:?}", ke_info.key);
                        continue 'running;
                    };
                    let rr: render::Result = if ke_info.shift {
                        do_update = false;

                        key_infos.write().unwrap().push(ke_info.clone());

                        server_call(
                            cfg,
                            &ServerCall::QueryKeyDown(key_infos.read().unwrap().clone()),
                        )?
                    } else if !do_update {
                        do_update = true;
                        key_infos.write().unwrap().push(ke_info.clone());
                        let rr = server_call(
                            cfg,
                            &ServerCall::UpdateKeyDown(key_infos.read().unwrap().clone()),
                        )?;
                        *key_infos.write().unwrap() = vec![];
                        rr
                    } else {
                        server_call(cfg, &ServerCall::UpdateKeyDown(vec![ke_info.clone()]))?
                    };

                    redraw(&mut canvas, &window_dim, &rr)?;
                }
            };
        }
    }
}

fn main() {
    let cli_opt = CliOpt::from_args();
    init_log(
        match (cli_opt.log_trace, cli_opt.log_debug, cli_opt.log_quiet) {
            (true, _, _) => log::LevelFilter::Trace,
            (_, true, _) => log::LevelFilter::Debug,
            (_, _, true) => log::LevelFilter::Error,
            (_, _, _) => log::LevelFilter::Info,
        },
    );
    info!("Evaluating CLI command: {:?} ...", &cli_opt.command);
    let c = cli_opt.command.clone();
    match c {
        CliCommand::Completions { shell: s } => {
            // see also: https://clap.rs/effortless-auto-completion/
            CliOpt::clap().gen_completions_to("icgt", s, &mut io::stdout());
            info!("done")
        }
        CliCommand::Connect {
            canister_id,
            replica_url,
            player_id,
        } => {
            let cfg = ConnectConfig {
                canister_id,
                replica_url,
                cli_opt,
                player_id: player_id.unwrap_or(Nat::from(0)),
            };
            info!("Connecting to IC canister: {:?}", cfg);
            let (send_ev, recv_ev) = crossbeam::channel::unbounded();
            let key_infos = Arc::new(RwLock::new(vec![]));
            // Start a timer and query state.
            std::thread::spawn({
                let cfg = cfg.clone();
                let cfg = cfg.clone();
                let key_infos = Arc::clone(&key_infos);
                move || {
                    let sys = System::new("updater");
                    let _trigger =
                        Trigger::create(|_context| Trigger::new(cfg, send_ev, key_infos));

                    sys.run().unwrap();
                }
            });

            do_event_loop(&cfg, recv_ev, key_infos).unwrap()
        }
    }
}

extern crate hashcons;
extern crate sdl2;
extern crate serde;
extern crate tokio;
extern crate icgt;
extern crate delay;
extern crate ic_agent;
extern crate serde_idl;


// Logging:
#[macro_use]
extern crate log;
extern crate env_logger;

// CLI: Representation and processing:
extern crate clap;
use clap::Shell;

extern crate structopt;
use structopt::StructOpt;

use delay::Delay;
use sdl2::event::Event as SysEvent;
use sdl2::event::WindowEvent;
use sdl2::keyboard::Keycode;
use std::io;
use std::time::Duration;
use ic_agent::{Agent, AgentConfig, Blob, CanisterId};
use serde_idl::value::{IDLArgs, IDLField, IDLValue};

/// Internet Computer Game Terminal (icgt)
#[derive(StructOpt, Debug, Clone)]
#[structopt(name = "icgt", raw(setting = "clap::AppSettings::DeriveDisplayOrder"))]
pub struct CliOpt {
    /// Enable tracing -- the most verbose log.
    #[structopt(short = "t", long = "trace-log")]
    log_trace: bool,
    /// Enable logging for debugging.
    #[structopt(short = "d", long = "debug-log")]
    log_debug: bool,
    /// Disable most logging, if not explicitly enabled.
    #[structopt(short = "q", long = "quiet-log")]
    log_quiet: bool,
    #[structopt(subcommand)]
    command: CliCommand,
}

/// Connection configuration
#[derive(Debug, Clone)]
pub struct ConnectConfig {
    cli_opt: CliOpt,
    canister_id: String,
    replica_url: String,
}

#[derive(StructOpt, Debug, Clone)]
enum CliCommand {
    #[structopt(
        name = "completions",
        about = "Generate shell scripts for auto-completions."
    )]
    Completions { shell: Shell },
    #[structopt(
        name = "connect",
        about = "Connect to a canister as an IC game server."
    )]
    Connect {
        replica_url: String,
        canister_id: String
    },
}

fn init_log(level_filter: log::LevelFilter) {
    use env_logger::{Builder, WriteStyle};
    let mut builder = Builder::new();
    builder
        .filter(None, level_filter)
        .write_style(WriteStyle::Always)
        .init();
}

use icgt::types::{event, render::{self, Fill, Elm}};
use sdl2::render::{Canvas, RenderTarget};

const RETRY_PAUSE: Duration = Duration::from_millis(100);
const REQUEST_TIMEOUT: Duration = Duration::from_secs(60);

pub fn agent(url: &str) -> Result<Agent, ic_agent::AgentError> {
    Agent::new(AgentConfig {
        url: format!("http://{}", url).as_str(),
        ..AgentConfig::default()
    })
}

pub fn draw_elms<T: RenderTarget>(
    canvas: &mut Canvas<T>,
    pos: &render::Pos,
    dim: &render::Dim,
    fill: &render::Fill,
    elms: &render::Elms,
) -> Result<(), String> {
    fn translate_color(c: &render::Color) -> sdl2::pixels::Color {
        match c {
            &render::Color::RGB(r, g, b) => sdl2::pixels::Color::RGB(r as u8, g as u8, b as u8),
        }
    };
    fn translate_rect(pos: &render::Pos, r: &render::Rect) -> sdl2::rect::Rect {
        // todo -- clip the size of the rect dimension by the bound param
        sdl2::rect::Rect::new(
            (pos.x + r.pos.x) as i32,
            (pos.y + r.pos.y) as i32,
            r.dim.width as u32,
            r.dim.height as u32,
        )
    };
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
            Fill::Open(c, 1) => {
                let r = translate_rect(pos, r);
                let c = translate_color(c);
                canvas.set_draw_color(c);
                canvas.draw_rect(r).unwrap();
            }
            Fill::Open(_c, _) => unimplemented!(),
        }
    };
    draw_rect::<T>(
        canvas,
        &pos,
        &render::Rect::new(0, 0, dim.width, dim.height),
        fill,
    );
    for elm in elms.iter() {
        match &elm {
            &Elm::Node(node) => {
                let pos = render::Pos {
                    x: pos.x + node.rect.pos.x,
                    y: pos.y + node.rect.pos.y,
                };
                if false {
                    draw_rect::<T>(
                        canvas,
                        &pos,
                        &render::Rect::new(0, 0, node.rect.dim.width, node.rect.dim.height),
                        &node.fill,
                    );
                }
                draw_elms(canvas, &pos, &node.rect.dim, &node.fill, &node.children)?;
            }
            &Elm::Rect(r, f) => draw_rect(canvas, pos, r, f),
        }
    }
    Ok(())
}

fn translate_system_event(event: SysEvent) -> Option<event::Event> {
    match &event {
        SysEvent::Window {
            win_event: WindowEvent::SizeChanged(w, h),
            ..
        } => {
            let dim = render::Dim {
                width: *w as usize,
                height: *h as usize,
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
                keycode => format!("unrecognized({:?})", keycode),
            };
            let event = event::Event::KeyDown(event::KeyEventInfo {
                key: key,
                // to do -- translate modifier keys,
                alt: false,
                ctrl: false,
                meta: false,
                shift: false,
            });
            Some(event)
        }
        _ => None,
    }
}

pub fn redraw<T: RenderTarget>(
    canvas: &mut Canvas<T>,
    dim: &render::Dim,
) -> Result<(), String> {
    let pos = render::Pos { x: 0, y: 0 };
    let fill = render::Fill::Closed(render::Color::RGB(0, 0, 0));
    let elms = unimplemented!("get render elements");
    draw_elms(canvas, &pos, dim, &fill, &elms)?;
    canvas.present();
    drop(elms);
    Ok(())
}

pub fn do_canister_tick(cfg: &ConnectConfig) -> Result<render::Result, String> {
    use ic_agent::{Blob, CanisterId};
    use std::time::Duration;
    use tokio::runtime::Runtime;
    let args_str = "()";
    let args = {
        if let Ok(args) = &args_str.parse::<IDLArgs>() {
            args.clone()
        } else {
            return Err(format!("do_canister_tick() failed to parse args: {:?}", args_str))
        }
    };
    info!(
        "...to canister_id {:?} at replica_url {:?}",
        cfg.canister_id,
        cfg.replica_url
    );
    let mut runtime = Runtime::new().expect("Unable to create a runtime");
    let delay = Delay::builder()
        .throttle(RETRY_PAUSE)
        .timeout(REQUEST_TIMEOUT)
        .build();
    let agent = agent(&cfg.replica_url).unwrap();
    let canister_id =
        CanisterId::from_text(cfg.canister_id.clone()).unwrap();
    let timestamp = std::time::SystemTime::now();
    let blob_res = runtime.block_on(agent.call_and_wait(
        &canister_id,
        &"tick",
        &Blob(args.to_bytes().unwrap()),
        delay,
    ));
    let elapsed = timestamp.elapsed().unwrap();
    if let Ok(blob_res) = blob_res {
        let result =
            serde_idl::IDLArgs::from_bytes(&(*blob_res.unwrap().0));
        let idl_rets = result.unwrap().args;
        //let render_out = candid::find_render_out(&idl_rets);
        //repl.update_display(&render_out);
        let res = format!("{:?}", &idl_rets);
        let mut res_log = res.clone();
        if res_log.len() > 80 {
            res_log.truncate(80);
            res_log.push_str("...(truncated)");
        }
        info!("..successful result {:?}", res_log);
        // to do -- decode and draw the result
        unimplemented!()
    } else {
        let res = format!("{:?}", blob_res);
        info!("..error result {:?}", res);
        Err(format!("do_canister_tick() failed: {:?}", res))
    }
}

pub fn do_event_loop(cfg: &ConnectConfig) -> Result<(), String> {
    use sdl2::event::EventType;
    let mut dim = render::Dim {
        width: 1000,
        height: 666,
    };
    let sdl_context = sdl2::init()?;
    let video_subsystem = sdl_context.video()?;
    let window = video_subsystem
        .window("thin-ic-agent", dim.width as u32, dim.height as u32)
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
        do_canister_tick(cfg)?;

        // draw initial frame, before waiting for any events
        redraw(&mut canvas, &dim);
    }

    let mut event_pump = sdl_context.event_pump()?;

    event_pump.disable_event(EventType::FingerUp);
    event_pump.disable_event(EventType::FingerDown);
    event_pump.disable_event(EventType::FingerMotion);
    event_pump.disable_event(EventType::MouseMotion);

    'running: loop {
        let event = translate_system_event(event_pump.wait_event());
        let event = match event {
            None => continue 'running,
            Some(event) => event,
        };
        // catch window resize event: redraw and loop:
        match event {
            event::Event::WindowSizeChange(new_dim) => {
                dim = new_dim.clone();
                redraw(&mut canvas, &dim)?;
                continue 'running;
            }
            _ => (),
        };
        // to do -- update state
        // to do -- pass state (or elements derived from it) to redraw:
        redraw(&mut canvas, &dim)?;
    };
    Ok(())
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
    // - - - - - - - - - - -
    let c = cli_opt.command.clone();
    match c {
        CliCommand::Completions { shell: s } => {
            // see also: https://clap.rs/effortless-auto-completion/
            //
            CliOpt::clap().gen_completions_to("icgt", s, &mut io::stdout());
            info!("done")
        },
        CliCommand::Connect { canister_id, replica_url } => {
            // see also: https://clap.rs/effortless-auto-completion/
            //
            let cfg = ConnectConfig{
                canister_id,
                replica_url,
                cli_opt,
            };
            info!("Connecting to IC canister: {:?}", cfg);
            do_event_loop(&cfg).unwrap()
        }
    }
}

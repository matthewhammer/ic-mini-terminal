//extern crate hashcons;
extern crate sdl2;
extern crate serde;
extern crate icgt;
extern crate delay;
extern crate ic_agent;
extern crate ic_types;
extern crate num_traits;
extern crate futures;


// Logging:
#[macro_use]
extern crate log;
extern crate env_logger;

// CLI: Representation and processing:
extern crate clap;
use clap::Shell;

extern crate structopt;
use structopt::StructOpt;

use ic_agent::Agent;
use ic_types::Principal;
use candid::{Encode, Decode};


use delay::Delay;
use sdl2::event::Event as SysEvent; // not to be confused with our own definition
use sdl2::event::WindowEvent;
use sdl2::keyboard::Keycode;
use std::io;
use std::time::Duration;
use candid::Nat;
use num_traits::cast::ToPrimitive;

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

/// Connection configuration
#[derive(Debug, Clone)]
pub struct ConnectConfig {
    cli_opt: CliOpt,
    canister_id: String,
    replica_url: String,
}

/// Messages that go from this terminal binary to the server cansiter
#[derive(Debug, Clone)]
pub enum ServerCall {
    // to do -- include the local clock, or a duration since last tick;
    // we don't have time in the server
    Tick,

    WindowSizeChange(render::Dim),

    // to do -- more generally, query msg that projects events' outcome
    QueryKeyDown(Vec<event::KeyEventInfo>),

    // to do -- more generally, update msg that pushes events
    UpdateKeyDown(Vec<event::KeyEventInfo>),
}

/// Errors from the game terminal, or its subcomponents
pub enum IcgtError {
    Agent(ic_agent::AgentError),
    String(String),
    RingKeyRejected(ring::error::KeyRejected),
    RingUnspecified(ring::error::Unspecified),
}
impl std::convert::From<ic_agent::AgentError> for IcgtError {
    fn from(ae: ic_agent::AgentError) -> Self { IcgtError::Agent(ae) }
}
impl std::convert::From<String> for IcgtError {
    fn from(s: String) -> Self { IcgtError::String(s) }
}
impl std::convert::From<ring::error::KeyRejected> for IcgtError {
    fn from(r: ring::error::KeyRejected) -> Self { IcgtError::RingKeyRejected(r) }
}
impl std::convert::From<ring::error::Unspecified> for IcgtError {
    fn from(r: ring::error::Unspecified) -> Self { IcgtError::RingUnspecified(r) }
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


pub fn agent(url: &str) -> Result<Agent, IcgtError> {
    //use ring::signature::Ed25519KeyPair;
    use ic_agent::agent::AgentConfig;
    use ring::rand::SystemRandom;

    let rng = SystemRandom::new();
    let pkcs8_bytes = ring::signature::Ed25519KeyPair::generate_pkcs8(&rng)?;
    let key_pair = ring::signature::Ed25519KeyPair::from_pkcs8(pkcs8_bytes.as_ref())?;
    let ident = ic_agent::identity::BasicIdentity::from_key_pair(key_pair);
    let agent = Agent::new(AgentConfig {
        identity: Box::new(ident),
        url: format!("http://{}", url),
        ..AgentConfig::default()
    })?;
    Ok(agent)
}


fn nat_ceil(n:&Nat) -> u32 {
    n.0.to_u32().unwrap()
}

fn byte_ceil(n:&Nat) -> u8 {
    match n.0.to_u8() {
        Some(byte) => byte,
        None => 255,
    }
}

fn translate_color(c: &render::Color) -> sdl2::pixels::Color {
    match c {
        (r, g, b) => sdl2::pixels::Color::RGB(byte_ceil(r), byte_ceil(g), byte_ceil(b))
    }
}

fn translate_rect(pos: &render::Pos, r: &render::Rect) -> sdl2::rect::Rect {
    // todo -- clip the size of the rect dimension by the bound param
    trace!("translate_rect {:?} {:?}", pos, r);
    sdl2::rect::Rect::new(
        nat_ceil(& Nat(&pos.x.0 + &r.pos.x.0)) as i32,
        nat_ceil(& Nat(&pos.y.0 + &r.pos.y.0)) as i32,
        nat_ceil(& r.dim.width),
        nat_ceil(& r.dim.height),
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
        &render::Rect::new(nat_zero(), nat_zero(), dim.width.clone(), dim.height.clone()),
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

fn translate_system_event(event: &SysEvent) -> Option<event::Event> {
    match event {
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
                    return None
                }
            };
            let event = event::Event::KeyDown(event::KeyEventInfo {
                key: key,
                // to do -- translate modifier keys,
                alt: false,
                ctrl: false,
                meta: false,
                shift: keymod.contains(sdl2::keyboard::Mod::LSHIFTMOD) ||
                    keymod.contains(sdl2::keyboard::Mod::RSHIFTMOD),
            });
            Some(event)
        }
        _ => None,
    }
}


pub async fn redraw<T: RenderTarget>(
    canvas: &mut Canvas<T>,
    dim: &render::Dim,
    rr:&render::Result,
) -> Result<(), String> {
    let pos = render::Pos { x: nat_zero(), y: nat_zero() };
    let fill = render::Fill::Closed((nat_zero(), nat_zero(), nat_zero()));
    match rr {
        render::Result::Ok(render::Out::Draw(elm)) => {
            draw_rect_elms(canvas, &pos, dim, &fill, &vec![elm.clone()])?;
        },
        render::Result::Ok(render::Out::Redraw(elms)) => {
            if elms.len() == 1 && elms[0].0 == "screen" {
                draw_rect_elms(canvas, &pos, dim, &fill, &vec![elms[0].1.clone()])?;
            } else {
                warn!("unrecognized redraw elements {:?}", elms);
            }
        },
        render::Result::Err(render::Out::Draw(elm)) => {
            draw_rect_elms(canvas, &pos, dim, &fill, &vec![elm.clone()])?;
        },
        _ => {
            unimplemented!()
        }
    };
    canvas.present();
    Ok(())
}

pub async fn do_event_loop(cfg: &ConnectConfig) -> Result<(), IcgtError> {
    use sdl2::event::EventType;
    let mut do_update = true;
    let mut key_infos = vec![];
    let mut window_dim = render::Dim {
        width: Nat::from(1000),
        height: Nat::from(666),
    };
    let sdl_context = sdl2::init()?;
    let video_subsystem = sdl_context.video()?;
    let window = video_subsystem
        .window("ic-game-terminal",
                nat_ceil(&window_dim.width),
                nat_ceil(&window_dim.height))
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
    info!("SDL canvas.info().name => \"{}\"", canvas.info().name);

    {
        let rr: render::Result =
            server_call(cfg, &ServerCall::WindowSizeChange(window_dim.clone())).await?;
        redraw(&mut canvas, &window_dim, &rr).await?;
    }

    let mut event_pump = sdl_context.event_pump()?;

    event_pump.disable_event(EventType::FingerUp);
    event_pump.disable_event(EventType::FingerDown);
    event_pump.disable_event(EventType::FingerMotion);
    event_pump.disable_event(EventType::MouseMotion);

    'running: loop {
        let system_event = event_pump.wait_event();
        let event = translate_system_event(&system_event);
        let event = match event {
            None => continue 'running,
            Some(event) => event,
        };
        trace!("SDL event_pump.wait_event() => {:?}", &system_event);
        // catch window resize event: redraw and loop:
        match event {
            event::Event::WindowSizeChange(new_dim) => {
                debug!("WindowSizeChange {:?}", new_dim);
                let rr: render::Result =
                    server_call(cfg, &ServerCall::WindowSizeChange(new_dim.clone())).await?;
                window_dim = new_dim;
                redraw(&mut canvas, &window_dim, &rr).await?;
                continue 'running;
            },
            event::Event::Quit => {
                debug!("Quit");
                return Ok(())
            },
            event::Event::KeyUp(ref ke_info) => {
                debug!("KeyUp {:?}", ke_info.key)
            },
            event::Event::KeyDown(ref ke_info) => {
                debug!("KeyDown {:?}", ke_info.key);
                if ke_info.key == "LShift" || ke_info.key == "RShift" {
                    debug!("ignoring bare shift {:?}", ke_info.key);
                    continue 'running
                };
                let rr: render::Result =
                    if ke_info.shift {
                        do_update = false;
                        key_infos.push(ke_info.clone());
                        server_call(cfg, &ServerCall::QueryKeyDown(key_infos.clone())).await?
                    } else {
                        if do_update == false {
                            do_update = true;
                            key_infos.push(ke_info.clone());
                            let rr = server_call(cfg, &ServerCall::UpdateKeyDown(key_infos.clone())).await?;
                            key_infos = vec![];
                            rr
                        } else {
                            server_call(cfg, &ServerCall::UpdateKeyDown(vec![ke_info.clone()])).await?
                        }
                    };
                redraw(&mut canvas, &window_dim, &rr).await?;
            },
        };
    }
}

pub async fn server_call(cfg: &ConnectConfig, call:&ServerCall) ->
    Result<render::Result, IcgtError>
{
    debug!(
        "server_call: to canister_id {:?} at replica_url {:?}",
        cfg.canister_id,
        cfg.replica_url
    );
    let canister_id = Principal::from_text(cfg.canister_id.clone()).unwrap(); // xxx
    let agent = agent(&cfg.replica_url)?;
    let delay = Delay::builder()
        .throttle(RETRY_PAUSE)
        .timeout(REQUEST_TIMEOUT)
        .build();
    let timestamp = std::time::SystemTime::now();
    info!("server_call: {:?}", call);
    let arg_bytes = match call {
        ServerCall::Tick => { Encode!(&()).unwrap() }
        ServerCall::WindowSizeChange(window_dim) => { Encode!(window_dim).unwrap() }
        ServerCall::QueryKeyDown(keys) => { Encode!(keys).unwrap() }
        ServerCall::UpdateKeyDown(keys) => { Encode!(keys).unwrap() }
    };
    info!("server_call: Encoded argument via Candid; Arg size {:?} bytes", arg_bytes.len());
    info!("server_call: Awaiting response from server...");
    // do an update or query call, based on the ServerCall case:
    let blob_res = match call {
        ServerCall::Tick => {
            /*
            runtime.block_on(agent.update(
                &canister_id,
                &"tick",
                &Blob(arg_bytes),
                delay,
            ))
            */
            unimplemented!()
        },
        ServerCall::WindowSizeChange(_window_dim) => {
            let resp = agent.update(
                &canister_id,
                &"windowSizeChange")
                .with_arg(arg_bytes)
                .call_and_wait(delay)
                .await?;
            Some(resp)
        }
        ServerCall::QueryKeyDown(_keys) => {
            let resp = agent.query(
                &canister_id,
                &"queryKeyDown")
                .with_arg(arg_bytes)
                .call()
                .await?;
            Some(resp)
        },
        ServerCall::UpdateKeyDown(_keys) => {
            let resp = agent.update(
                &canister_id,
                &"updateKeyDown")
                .with_arg(arg_bytes)
                .call_and_wait(delay)
                .await?;
            Some(resp)
        },
    };
    let elapsed = timestamp.elapsed().unwrap();
    if let Some(blob_res) = blob_res {
        info!("server_call: Ok: Response size {:?} bytes; elapsed time {:?}",
              blob_res.len(), elapsed);
        match Decode!(&(*blob_res), render::Result) {
            Ok(res) => {
                if true {
                    let mut res_log = format!("{:?}", &res);
                    if res_log.len() > 1000 {
                        res_log.truncate(1000);
                        res_log.push_str("...(truncated)");
                    }
                    info!("server_call: Successful decoding of graphics output: {:?}", res_log);
                }
                Ok(res)
            },
            Err(candid_err) => {
                error!("Candid decoding error: {:?}", candid_err);
                Err(IcgtError::String("decoding error".to_string()))
            }
        }
    } else {
        let res = format!("{:?}", blob_res);
        info!("..error result {:?}", res);
        Err(IcgtError::String("tick error".to_string()))
    }
}

fn main() {
    use tokio::runtime::Runtime;
    let mut runtime = Runtime::new().expect("Unable to create a runtime");

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
        },
        CliCommand::Connect { canister_id, replica_url } => {
            let cfg = ConnectConfig{
                canister_id,
                replica_url,
                cli_opt,
            };
            info!("Connecting to IC canister: {:?}", cfg);
            runtime.block_on(do_event_loop(&cfg)).ok();
        }
    }
}

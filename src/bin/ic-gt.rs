//extern crate hashcons;
extern crate delay;
extern crate futures;
extern crate ic_agent;
extern crate ic_types;
extern crate icgt;
extern crate num_traits;
extern crate sdl2;
extern crate serde;

// Logging:
#[macro_use]
extern crate log;
extern crate env_logger;

// CLI: Representation and processing:
extern crate clap;
use clap::Shell;

extern crate structopt;
use structopt::StructOpt;

use candid::Decode;
use ic_agent::Agent;
use ic_types::Principal;

use candid::Nat;
use delay::Delay;
use num_traits::cast::ToPrimitive;
use sdl2::event::Event as SysEvent; // not to be confused with our own definition
use sdl2::event::WindowEvent;
use sdl2::keyboard::Keycode;
use std::io;
use std::sync::mpsc;
use std::time::Duration;
use tokio::task;

/// Internet Computer Game Terminal (ic-gt)
#[derive(StructOpt, Debug, Clone)]
#[structopt(name = "ic-gt", raw(setting = "clap::AppSettings::DeriveDisplayOrder"))]
pub struct CliOpt {
    /// No window for graphics output.
    /// Filesystem-based graphics output only.
    #[structopt(short = "W", long = "no-window")]
    no_window: bool,
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
        canister_id: String,
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
    // Query a projected view of the remote canister
    View(render::Dim, Vec<event::Event>),
    // Update the state of the remote canister
    Update(Vec<event::Event>),
    // To process user request to quit interaction
    FlushQuit,
}

/// Errors from the game terminal, or its subcomponents
#[derive(Debug, Clone)]
pub enum IcgtError {
    Agent(), /* Clone => Agent(ic_agent::AgentError) */
    String(String),
    RingKeyRejected(ring::error::KeyRejected),
    RingUnspecified(ring::error::Unspecified),
}
impl std::convert::From<ic_agent::AgentError> for IcgtError {
    fn from(_ae: ic_agent::AgentError) -> Self {
        /*IcgtError::Agent(ae)*/
        IcgtError::Agent()
    }
}
impl std::convert::From<String> for IcgtError {
    fn from(s: String) -> Self {
        IcgtError::String(s)
    }
}
impl std::convert::From<ring::error::KeyRejected> for IcgtError {
    fn from(r: ring::error::KeyRejected) -> Self {
        IcgtError::RingKeyRejected(r)
    }
}
impl std::convert::From<ring::error::Unspecified> for IcgtError {
    fn from(r: ring::error::Unspecified) -> Self {
        IcgtError::RingUnspecified(r)
    }
}

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

const RETRY_PAUSE: Duration = Duration::from_millis(100);
const REQUEST_TIMEOUT: Duration = Duration::from_secs(60);

pub type IcgtResult<X> = Result<X, IcgtError>;

pub fn agent(url: &str) -> IcgtResult<Agent> {
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
            Some(event::Event::WindowSize(dim))
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
            let shift = keymod.contains(sdl2::keyboard::Mod::LSHIFTMOD)
                || keymod.contains(sdl2::keyboard::Mod::RSHIFTMOD);
            let key = match &kc {
                Keycode::Tab => "Tab".to_string(),
                Keycode::Space => " ".to_string(),
                Keycode::Return => "Enter".to_string(),
                Keycode::Left => "ArrowLeft".to_string(),
                Keycode::Right => "ArrowRight".to_string(),
                Keycode::Up => "ArrowUp".to_string(),
                Keycode::Down => "ArrowDown".to_string(),
                Keycode::Backspace => "Backspace".to_string(),
                Keycode::LShift => "Shift".to_string(),
                Keycode::Num0 => (if shift { ")" } else { "0" }).to_string(),
                Keycode::Num1 => (if shift { "!" } else { "1" }).to_string(),
                Keycode::Num2 => (if shift { "@" } else { "2" }).to_string(),
                Keycode::Num3 => (if shift { "#" } else { "3" }).to_string(),
                Keycode::Num4 => (if shift { "$" } else { "4" }).to_string(),
                Keycode::Num5 => (if shift { "%" } else { "5" }).to_string(),
                Keycode::Num6 => (if shift { "^" } else { "6" }).to_string(),
                Keycode::Num7 => (if shift { "&" } else { "7" }).to_string(),
                Keycode::Num8 => (if shift { "*" } else { "8" }).to_string(),
                Keycode::Num9 => (if shift { "(" } else { "9" }).to_string(),
                Keycode::A => (if shift { "A" } else { "a" }).to_string(),
                Keycode::B => (if shift { "B" } else { "b" }).to_string(),
                Keycode::C => (if shift { "C" } else { "c" }).to_string(),
                Keycode::D => (if shift { "D" } else { "d" }).to_string(),
                Keycode::E => (if shift { "E" } else { "e" }).to_string(),
                Keycode::F => (if shift { "F" } else { "f" }).to_string(),
                Keycode::G => (if shift { "G" } else { "g" }).to_string(),
                Keycode::H => (if shift { "H" } else { "h" }).to_string(),
                Keycode::I => (if shift { "I" } else { "i" }).to_string(),
                Keycode::J => (if shift { "J" } else { "j" }).to_string(),
                Keycode::K => (if shift { "K" } else { "k" }).to_string(),
                Keycode::L => (if shift { "L" } else { "l" }).to_string(),
                Keycode::M => (if shift { "M" } else { "m" }).to_string(),
                Keycode::N => (if shift { "N" } else { "n" }).to_string(),
                Keycode::O => (if shift { "O" } else { "o" }).to_string(),
                Keycode::P => (if shift { "P" } else { "p" }).to_string(),
                Keycode::Q => (if shift { "Q" } else { "q" }).to_string(),
                Keycode::R => (if shift { "R" } else { "r" }).to_string(),
                Keycode::S => (if shift { "S" } else { "s" }).to_string(),
                Keycode::T => (if shift { "T" } else { "t" }).to_string(),
                Keycode::U => (if shift { "U" } else { "u" }).to_string(),
                Keycode::V => (if shift { "V" } else { "v" }).to_string(),
                Keycode::W => (if shift { "W" } else { "w" }).to_string(),
                Keycode::X => (if shift { "X" } else { "x" }).to_string(),
                Keycode::Y => (if shift { "Y" } else { "y" }).to_string(),
                Keycode::Equals => (if shift { "+" } else { "=" }).to_string(),
                Keycode::Plus => "+".to_string(),
                Keycode::Slash => (if shift { "?" } else { "/" }).to_string(),
                Keycode::Question => "?".to_string(),
                Keycode::Period => (if shift { ">" } else { "." }).to_string(),
                Keycode::Greater => ">".to_string(),
                Keycode::Comma => (if shift { "<" } else { "," }).to_string(),
                Keycode::Less => "<".to_string(),
                Keycode::Backslash => (if shift { "|" } else { "\\" }).to_string(),
                Keycode::Colon => ":".to_string(),
                Keycode::Semicolon => (if shift { ":" } else { ";" }).to_string(),
                Keycode::At => "@".to_string(),
                Keycode::Minus => (if shift { "_" } else { "-" }).to_string(),
                Keycode::Underscore => "_".to_string(),
                Keycode::Exclaim => "!".to_string(),
                Keycode::Hash => "#".to_string(),
                Keycode::Quote => (if shift { "\"" } else { "'" }).to_string(),
                Keycode::Quotedbl => "\"".to_string(),
                Keycode::LeftBracket => (if shift { "{" } else { "[" }).to_string(),
                Keycode::RightBracket => (if shift { "}" } else { "]" }).to_string(),

                /* More to consider later (among many more that are available, but we will ignore)
                Escape
                Dollar
                Percent
                Ampersand
                LeftParen
                RightParen
                Asterisk
                Plus
                Minus
                Equals
                Caret
                Backquote
                CapsLock
                F1
                F2
                F3
                F4
                F5
                F6
                F7
                F8
                F9
                F10
                F11
                F12
                LCtrl
                LShift
                LAlt
                LGui
                RCtrl
                RShift
                RAlt
                RGui
                */
                keycode => {
                    info!("Unrecognized key code, ignoring event: {:?}", keycode);
                    return None;
                }
            };
            let event = event::Event::KeyDown(vec![event::KeyEventInfo {
                key: key,
                // to do -- translate modifier keys,
                alt: false,
                ctrl: false,
                meta: false,
                shift: shift,
            }]);
            Some(event)
        }
        _ => None,
    }
}

pub async fn redraw<T: RenderTarget>(
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
    // to do -- if enabled, dump canvas as .BMP file to next output image file in the stream that we are producing
    // https://docs.rs/sdl2/0.34.3/sdl2/render/struct.Canvas.html#method.into_surface
    // https://docs.rs/sdl2/0.34.3/sdl2/surface/struct.Surface.html#method.save_bmp
    Ok(())
}

async fn do_update_task(
    cfg: ConnectConfig,
    remote_in: mpsc::Receiver<ServerCall>,
    remote_out: mpsc::Sender<()>,
) -> IcgtResult<()> {
    println!("Update task: Begin.");
    println!("Update task: Pausing (for empty, initial update's response from server).");
    server_call(&cfg, ServerCall::Update(vec![])).await?;
    remote_out.send(()).unwrap();
    loop {
        println!("Update task: Loop head: Waiting for next ServerCall request");
        let sc = remote_in.recv().unwrap();
        println!(
            "Update task: Request for ServerCall:\n{:?}
",
            sc
        );
        if let ServerCall::FlushQuit = sc {
            return Ok(());
        };
        let rr = server_call(&cfg, sc).await?;
        println!("Update task: Response for ServerCall:\n{:?}", rr);
        println!("Update task: Waiting to draw.");
        remote_out.send(()).unwrap();
        println!("Update task: Loop body done. Looping.");
    }
}

async fn event_loop<T: RenderTarget>(
    cfg: ConnectConfig,
    window_dim_: render::Dim,
    sdl: sdl2::Sdl,
    canvas: &mut Canvas<T>,
) -> Result<(), IcgtError> {
    info!("SDL canvas.info().name => \"{}\"", canvas.info().name);

    let cfg2 = cfg.clone();
    let mut window_dim = window_dim_.clone();

    let mut q_key_infos = vec![];
    let mut u_key_infos = vec![];

    // ---------------------------------------------------------------------

    // Interaction cycle as two halves (local/remote); each half is a thread.
    // There are four end points along the cycle's halves:

    let (local_out, remote_in) = mpsc::channel::<ServerCall>();
    let (remote_out, local_in) = mpsc::channel::<()>();

    // 1. Remote interactions via update calls to server.
    // (Consumes remote_in and produces remote_out).

    task::spawn(do_update_task(cfg2, remote_in, remote_out));

    let mut quit_request = false;

    let mut update_requests = Nat::from(1); // count update task requests (already one).
    let mut update_responses = Nat::from(0); // count update task responses (none yet).

    // 2. Local interactions via the SDL Event loop.
    // (Consumes local_in and produces local_out).

    let mut event_pump = {
        use sdl2::event::EventType;
        let mut p = sdl.event_pump()?;
        p.disable_event(EventType::FingerUp);
        p.disable_event(EventType::FingerDown);
        p.disable_event(EventType::FingerMotion);
        p.disable_event(EventType::MouseMotion);
        p
    };

    // initial draw (not really a "redraw" yet):
    {
        let rr = server_call(&cfg, ServerCall::View(window_dim.clone(), vec![])).await?;
        redraw(canvas, &window_dim, &rr.unwrap()).await?;
    };

    // main loop
    'running: loop {
        if let Some(system_event) = event_pump.wait_event_timeout(13) {
            let event = translate_system_event(&system_event);
            let event = match event {
                None => continue 'running,
                Some(event) => event,
            };
            trace!("SDL event_pump.wait_event() => {:?}", &system_event);
            // catch window resize event: redraw and loop:
            match event {
                event::Event::MouseDown(_) => {
                    // ignore (for now)
                }
                event::Event::Quit => {
                    debug!("Quit");
                    println!("Begin: Quitting...");
                    println!("Waiting for next update response...");
                    quit_request = true;
                }
                event::Event::WindowSize(new_dim) => {
                    debug!("WindowSize {:?}", new_dim);
                    window_dim = new_dim;
                    let mut buffer = u_key_infos.clone();
                    buffer.append(&mut (q_key_infos.clone()));
                    let rr =
                        server_call(&cfg, ServerCall::View(window_dim.clone(), buffer.clone()))
                            .await?;
                    redraw(canvas, &window_dim, &rr.unwrap()).await?;
                }
                event::Event::KeyDown(ref keys) => {
                    debug!("KeyDown {:?}", keys);
                    q_key_infos.push(event::Event::KeyDown(keys.clone()));
                    let rr: render::Result = {
                        let mut buffer = u_key_infos.clone();
                        buffer.append(&mut (q_key_infos.clone()));
                        let rr =
                            server_call(&cfg, ServerCall::View(window_dim.clone(), buffer.clone()))
                                .await?;
                        rr.unwrap()
                    };
                    redraw(canvas, &window_dim, &rr).await?;
                }
            }
        };
        // Is update task is ready for input?
        // (Signaled by local_in being ready to read.)
        match local_in.try_recv() {
            Ok(()) => {
                update_responses += 1;
                info!("update_responses = {}", update_responses);
                local_out
                    .send(ServerCall::Update(q_key_infos.clone()))
                    .unwrap();
                if quit_request {
                    println!("Continue: Quitting...");
                    println!("Waiting for final update response.");
                    match local_in.try_recv() {
                        Ok(()) => {
                            local_out.send(ServerCall::FlushQuit).unwrap();
                            println!("Done.");
                            return Ok(());
                        }
                        Err(e) => return Err(IcgtError::String(e.to_string())),
                    }
                };
                update_requests += 1;
                info!("update_requests = {}", update_requests);
                u_key_infos = q_key_infos;
                q_key_infos = vec![];
            }
            Err(mpsc::TryRecvError::Empty) => { /* not ready; do nothing */ }
            Err(e) => error!("{:?}", e),
        };
        continue 'running;
    }
}

async fn start_event_loop(cfg: ConnectConfig) -> Result<(), IcgtError> {
    let window_dim = render::Dim {
        width: Nat::from(1000),
        height: Nat::from(666),
    };
    let sdl = sdl2::init()?;

    if cfg.cli_opt.no_window {
        let surface = sdl2::surface::Surface::new(
            nat_ceil(&window_dim.width),
            nat_ceil(&window_dim.height),
            sdl2::pixels::PixelFormatEnum::RGBA8888,
        )?;
        let mut canvas = surface.into_canvas()?;
        event_loop(cfg, window_dim, sdl, &mut canvas).await?;
    } else {
        let video_subsystem = sdl.video()?;
        let window = video_subsystem
            .window(
                "IC Game Terminal",
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

        event_loop(cfg, window_dim, sdl, &mut canvas).await?;
    };
    Ok(())
}

// to do -- fix hack; refactor to remove Option<_> in return type

pub async fn server_call(
    cfg: &ConnectConfig,
    call: ServerCall,
) -> IcgtResult<Option<render::Result>> {
    if let ServerCall::FlushQuit = call {
        return Ok(None);
    };
    debug!(
        "server_call: to canister_id {:?} at replica_url {:?}",
        cfg.canister_id, cfg.replica_url
    );
    let canister_id = Principal::from_text(cfg.canister_id.clone()).unwrap(); // xxx
    let agent = agent(&cfg.replica_url)?;
    let delay = Delay::builder()
        .throttle(RETRY_PAUSE)
        .timeout(REQUEST_TIMEOUT)
        .build();
    let timestamp = std::time::SystemTime::now();
    info!("server_call: {:?}", call);
    let arg_bytes = match call.clone() {
        ServerCall::FlushQuit => candid::encode_args(()).unwrap(),
        ServerCall::View(window_dim, evs) => candid::encode_args((window_dim, evs)).unwrap(),
        ServerCall::Update(evs) => candid::encode_args((evs,)).unwrap(),
    };
    info!(
        "server_call: Encoded argument via Candid; Arg size {:?} bytes",
        arg_bytes.len()
    );
    info!("server_call: Awaiting response from server...");
    // do an update or query call, based on the ServerCall case:
    let blob_res = match call.clone() {
        ServerCall::FlushQuit => None,
        ServerCall::View(_window_dim, _keys) => {
            let resp = agent
                .query(&canister_id, "view")
                .with_arg(arg_bytes)
                .call()
                .await?;
            Some(resp)
        }
        ServerCall::Update(_keys) => {
            let resp = agent
                .update(&canister_id, "update")
                .with_arg(arg_bytes)
                .call_and_wait(delay)
                .await?;
            Some(resp)
        }
    };
    let elapsed = timestamp.elapsed().unwrap();
    if let Some(blob_res) = blob_res {
        info!(
            "server_call: Ok: Response size {:?} bytes; elapsed time {:?}",
            blob_res.len(),
            elapsed
        );
        match call.clone() {
            ServerCall::FlushQuit => Ok(None),
            ServerCall::Update(_) => Ok(None),
            ServerCall::View(_, _) => match candid::Decode!(&(*blob_res), render::Result) {
                Ok(res) => {
                    if cfg.cli_opt.log_trace {
                        let mut res_log = format!("{:?}", &res);
                        if res_log.len() > 1000 {
                            res_log.truncate(1000);
                            res_log.push_str("...(truncated)");
                        }
                        trace!(
                            "server_call: Successful decoding of graphics output: {:?}",
                            res_log
                        );
                    }
                    Ok(Some(res))
                }
                Err(candid_err) => {
                    error!("Candid decoding error: {:?}", candid_err);
                    Err(IcgtError::String("decoding error".to_string()))
                }
            },
        }
    } else {
        let res = format!("{:?}", blob_res);
        info!("..error result {:?}", res);
        Err(IcgtError::String("ic-gt error".to_string()))
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
        }
        CliCommand::Connect {
            canister_id,
            replica_url,
        } => {
            let cfg = ConnectConfig {
                canister_id,
                replica_url,
                cli_opt,
            };
            info!("Connecting to IC canister: {:?}", cfg);
            runtime.block_on(start_event_loop(cfg)).ok();
        }
    }
}

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
use chrono::prelude::*;
use delay::Delay;
use num_traits::cast::ToPrimitive;
use sdl2::event::Event as SysEvent; // not to be confused with our own definition
use sdl2::event::WindowEvent;
use sdl2::keyboard::Keycode;
use std::io;
use std::sync::mpsc;
use std::time::Duration;
use tokio::task;

use icgt::{
    keyboard,
    types::{
        event,
        render::{self, Elm, Fill},
    },
};
use sdl2::render::{Canvas, RenderTarget};

/// Internet Computer Game Terminal (ic-gt)
#[derive(StructOpt, Debug, Clone)]
#[structopt(name = "ic-gt", raw(setting = "clap::AppSettings::DeriveDisplayOrder"))]
pub struct CliOpt {
    /// No window for graphics output.
    /// Filesystem-based graphics output only.
    #[structopt(short = "W", long = "no-window")]
    no_window: bool,
    /// Trace-level logging (most verbose)
    #[structopt(short = "t", long = "trace-log")]
    log_trace: bool,
    /// Debug-level logging (medium verbose)
    #[structopt(short = "d", long = "debug-log")]
    log_debug: bool,
    /// Coarse logging information (not verbose)
    #[structopt(short = "L", long = "log")]
    log_info: bool,
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
        /// Initialization arguments, as a Candid textual value (default is empty tuple).
        #[structopt(short = "i", long = "user")]
        user_info_text: String,
    },
}

/// Connection context: IC agent object, for server calls, and configuration info.
pub struct ConnectCtx {
    cfg: ConnectCfg,
    agent: Agent,
    canister_id: Principal,
}

/// Connection configuration
#[derive(Debug, Clone)]
pub struct ConnectCfg {
    cli_opt: CliOpt,
    canister_id: String,
    replica_url: String,
    /// temp hack: username and user-chosen color
    user_info: UserInfo,
}

/// temp hack: username and user-chosen color
pub type UserInfo = (String, (Nat, Nat, Nat));

/// Messages that go from this terminal binary to the server cansiter
#[derive(Debug, Clone)]
pub enum ServerCall {
    // Query a projected view of the remote canister
    View(render::Dim, Vec<event::EventInfo>),
    // Update the state of the remote canister
    Update(Vec<event::EventInfo>),
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

impl<T> std::convert::From<std::sync::mpsc::SendError<T>> for IcgtError {
    fn from(_s: std::sync::mpsc::SendError<T>) -> Self {
        IcgtError::String("send error".to_string())
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

const RETRY_PAUSE: Duration = Duration::from_millis(100);
const REQUEST_TIMEOUT: Duration = Duration::from_secs(60);

pub type IcgtResult<X> = Result<X, IcgtError>;

pub fn create_agent(url: &str) -> IcgtResult<Agent> {
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
        } => match keyboard::translate_event(kc, keymod) {
            Some(ev) => Some(event::Event::KeyDown(vec![ev])),
            None => None,
        },
        _ => None,
    }
}

pub async fn redraw<T: RenderTarget>(
    canvas: &mut Canvas<T>,
    dim: &render::Dim,
    rr: &Option<render::Result>,
) -> Result<(), String> {
    let pos = render::Pos {
        x: nat_zero(),
        y: nat_zero(),
    };
    let fill = render::Fill::Closed((nat_zero(), nat_zero(), nat_zero()));
    match rr {
        Some(render::Result::Ok(render::Out::Draw(elm))) => {
            draw_rect_elms(canvas, &pos, dim, &fill, &vec![elm.clone()])?;
        }
        Some(render::Result::Ok(render::Out::Redraw(elms))) => {
            if elms.len() == 1 && elms[0].0 == "screen" {
                draw_rect_elms(canvas, &pos, dim, &fill, &vec![elms[0].1.clone()])?;
            } else {
                warn!("unrecognized redraw elements {:?}", elms);
            }
        }
        Some(render::Result::Err(render::Out::Draw(elm))) => {
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

// skip events just have meta info, needed for _customized_ (per-user) views.
// alternatively, the "event" corresponding to getting the current view is the Skip event.
pub fn skip_event(ctx: &ConnectCtx) -> event::EventInfo {
    event::EventInfo {
        user_info: event::UserInfo {
            user_name: ctx.cfg.user_info.0.clone(),
            text_color: (
                ctx.cfg.user_info.1.clone(),
                (Nat::from(0), Nat::from(0), Nat::from(0)),
            ),
        },
        nonce: None,
        date_time_local: Local::now().to_rfc3339(),
        date_time_utc: Utc::now().to_rfc3339(),
        event: event::Event::Skip,
    }
}

async fn do_view_task(
    cfg: ConnectCfg,
    remote_in: mpsc::Receiver<Option<(render::Dim, Vec<event::EventInfo>)>>,
    remote_out: mpsc::Sender<Option<render::Result>>,
) -> IcgtResult<()> {
    /* Create our own agent here since we cannot Send it here from the main thread. */
    let canister_id = Principal::from_text(cfg.canister_id.clone()).unwrap();
    let agent = create_agent(&cfg.replica_url)?;
    let ctx = ConnectCtx {
        cfg: cfg.clone(),
        canister_id,
        agent,
    };

    loop {
        let events = remote_in.recv().unwrap();

        match events {
            None => return Ok(()),
            Some((window_dim, events)) => {
                let rr = server_call(&ctx, ServerCall::View(window_dim, events)).await?;
                remote_out.send(rr).unwrap();
            }
        }
    }
}

async fn do_redraw<T1: RenderTarget, T2: RenderTarget>(
    _cli: &CliOpt,
    window_dim: &render::Dim,
    window_canvas: &mut Canvas<T1>,
    file_canvas: &mut Canvas<T2>,
    data: &Option<render::Result>,
) -> IcgtResult<()> {
    // Window-video drawing, (to do -- only if enabled by CLI)
    redraw(window_canvas, window_dim, data).await?;

    // File drawing, (to do -- only if enabled by CLI)
    redraw(file_canvas, window_dim, data).await?;
    // to do -- write the canvas as a bitmap, to a timestamped image file

    Ok(())
}

async fn do_update_task(
    cfg: ConnectCfg,
    remote_in: mpsc::Receiver<ServerCall>,
    remote_out: mpsc::Sender<()>,
) -> IcgtResult<()> {
    /* Create our own agent here since we cannot Send it here from the main thread. */
    let canister_id = Principal::from_text(cfg.canister_id.clone()).unwrap();
    let agent = create_agent(&cfg.replica_url)?;
    let ctx = ConnectCtx {
        cfg,
        canister_id,
        agent,
    };
    loop {
        let sc = remote_in.recv().unwrap();
        if let ServerCall::FlushQuit = sc {
            return Ok(());
        };
        server_call(&ctx, sc).await?;
        remote_out.send(()).unwrap();
    }
}

async fn local_event_loop(ctx: ConnectCtx) -> Result<(), IcgtError> {
    let mut window_dim = render::Dim {
        width: Nat::from(320),
        height: Nat::from(240),
    }; // use CLI to init

    let sdl = sdl2::init()?;

    // to do --- if headless, do not do these steps; window_canvas is None
    let video_subsystem = sdl.video()?;
    let window = video_subsystem
        .window(
            "IC Game Terminal",
            nat_ceil(&window_dim.width),
            nat_ceil(&window_dim.height),
        )
        .position_centered()
        .resizable()
        /*.input_grabbed() // to do -- CI flag*/
        .build()
        .map_err(|e| e.to_string())?;

    let mut window_canvas = window
        .into_canvas()
        .target_texture()
        .present_vsync()
        .build()
        .map_err(|e| e.to_string())?;

    // to do --- if file-less, do not do these steps; file_canvas is None
    let mut file_canvas = {
        let surface = sdl2::surface::Surface::new(
            nat_ceil(&window_dim.width),
            nat_ceil(&window_dim.height),
            sdl2::pixels::PixelFormatEnum::RGBA8888,
        )?;
        surface.into_canvas()?
    };

    let mut view_events = vec![];
    let mut update_events = vec![];

    let (update_in, update_out) = /* Begin update task */ {
        let cfg = ctx.cfg.clone();

        // Interaction cycle as two halves (local/remote); each half is a thread.
        // There are four end points along the cycle's halves:
        let (local_out, remote_in) = mpsc::channel::<ServerCall>();
        let (remote_out, local_in) = mpsc::channel::<()>();

        // 1. Remote interactions via update calls to server.
        // (Consumes remote_in and produces remote_out).

        task::spawn(do_update_task(cfg, remote_in, remote_out));
        local_out.send(ServerCall::Update(vec![skip_event(&ctx)]))?;
        (local_in, local_out)
    };

    let (view_in, view_out) = /* Begin view task */ {
        let cfg = ctx.cfg.clone();

        // Interaction cycle as two halves (local/remote); each half is a thread.
        // There are four end points along the cycle's halves:
        let (local_out, remote_in) = mpsc::channel::<Option<(render::Dim, Vec<event::EventInfo>)>>();
        let (remote_out, local_in) = mpsc::channel::<Option<render::Result>>();

        // 1. Remote interactions via view calls to server.
        // (Consumes remote_in and produces remote_out).

        task::spawn(do_view_task(cfg, remote_in, remote_out));
        local_out.send(Some((window_dim.clone(), vec![skip_event(&ctx)])))?;
        (local_in, local_out)
    };

    let mut quit_request = false; // user has requested to quit: shut down gracefully.
    let mut dirty_flag = true; // more events ready for view task
    let mut ready_flag = true; // view task is ready for more events

    let mut update_requests = Nat::from(1); // count update task requests (already one).
    let mut update_responses = Nat::from(0); // count update task responses (none yet).

    let mut view_requests = Nat::from(1); // count view task requests (already one).
    let mut view_responses = Nat::from(0); // count view task responses (none yet).

    // 2. Local interactions via the SDL Event loop.
    let mut event_pump = {
        use sdl2::event::EventType;
        let mut p = sdl.event_pump()?;
        p.disable_event(EventType::FingerUp);
        p.disable_event(EventType::FingerDown);
        p.disable_event(EventType::FingerMotion);
        p.disable_event(EventType::MouseMotion);
        p
    };

    'running: loop {
        if let Some(system_event) = event_pump.wait_event_timeout(13) {
            // utc/local timestamps for event
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
                event::Event::Skip => {
                    // ignore
                }
                event::Event::Quit => {
                    debug!("Quit");
                    println!("Begin: Quitting...");
                    println!("Waiting for next update response...");
                    quit_request = true;
                }
                event::Event::WindowSize(new_dim) => {
                    debug!("WindowSize {:?}", new_dim);
                    dirty_flag = true;
                    window_dim = new_dim;
                    // to do -- add event to buffer, and send to server
                }
                event::Event::KeyDown(ref keys) => {
                    debug!("KeyDown {:?}", keys);
                    dirty_flag = true;
                    view_events.push(event::EventInfo {
                        user_info: event::UserInfo {
                            user_name: ctx.cfg.user_info.0.clone(),
                            text_color: (
                                ctx.cfg.user_info.1.clone(),
                                (Nat::from(0), Nat::from(0), Nat::from(0)),
                            ),
                        },
                        nonce: None,
                        date_time_local: Local::now().to_rfc3339(),
                        date_time_utc: Utc::now().to_rfc3339(),
                        event: event::Event::KeyDown(keys.clone()),
                    });
                }
            }
        };

        /* attend to update task */
        {
            match update_in.try_recv() {
                Ok(()) => {
                    update_responses += 1;
                    info!("update_responses = {}", update_responses);
                    update_out
                        .send(ServerCall::Update(view_events.clone()))
                        .unwrap();
                    if quit_request {
                        println!("Continue: Quitting...");
                        println!("Waiting for final update-task response.");
                        match update_in.try_recv() {
                            Ok(()) => {
                                update_out.send(ServerCall::FlushQuit).unwrap();
                                println!("Done.");
                            }
                            Err(e) => return Err(IcgtError::String(e.to_string())),
                        }
                    };
                    update_requests += 1;
                    info!("update_requests = {}", update_requests);
                    update_events = view_events;
                    view_events = vec![];
                    dirty_flag = true;
                }
                Err(mpsc::TryRecvError::Empty) => { /* not ready; do nothing */ }
                Err(e) => error!("{:?}", e),
            }
        };

        if quit_request {
            println!("Continue: Quitting view task...");
            view_out.send(None).unwrap();
            println!("Done.");
            match view_in.try_recv() {
                Ok(None) => {}
                Ok(Some(_)) => {
                    return Err(IcgtError::String(
                        "expected view task to reply None, not Some(_)".to_string(),
                    ))
                }
                Err(e) => return Err(IcgtError::String(e.to_string())),
            }
        } else
        /* attend to view task */
        {
            match view_in.try_recv() {
                Ok(rr) => {
                    view_responses += 1;
                    info!("view_responses = {}", view_responses);

                    do_redraw(
                        &(ctx.cfg).cli_opt,
                        &window_dim,
                        &mut window_canvas,
                        &mut file_canvas,
                        &rr,
                    )
                    .await?;

                    ready_flag = true;
                }
                Err(mpsc::TryRecvError::Empty) => { /* not ready; do nothing */ }
                Err(e) => error!("{:?}", e),
            };

            if dirty_flag && ready_flag {
                dirty_flag = false;
                ready_flag = false;
                let mut events = update_events.clone();
                events.append(&mut (view_events.clone()));

                view_out.send(Some((window_dim.clone(), events))).unwrap();

                view_requests += 1;
                info!("view_requests = {}", view_requests);
            }
        };

        // attend to next batch of local events, and loop everything above
        continue 'running;
    }
}

// to do -- fix hack; refactor to remove Option<_> in return type

pub async fn server_call(ctx: &ConnectCtx, call: ServerCall) -> IcgtResult<Option<render::Result>> {
    if let ServerCall::FlushQuit = call {
        return Ok(None);
    };
    debug!(
        "server_call: to canister_id {:?} at replica_url {:?}",
        ctx.cfg.canister_id, ctx.cfg.replica_url
    );
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
            let resp = ctx
                .agent
                .query(&ctx.canister_id, "view")
                .with_arg(arg_bytes)
                .call()
                .await?;
            Some(resp)
        }
        ServerCall::Update(_keys) => {
            let resp = ctx
                .agent
                .update(&ctx.canister_id, "update")
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
                    if ctx.cfg.cli_opt.log_trace {
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

fn main() -> IcgtResult<()> {
    use tokio::runtime::Runtime;
    let mut runtime = Runtime::new().expect("Unable to create a runtime");

    let cli_opt = CliOpt::from_args();
    init_log(
        match (cli_opt.log_trace, cli_opt.log_debug, cli_opt.log_info) {
            (true, _, _) => log::LevelFilter::Trace,
            (_, true, _) => log::LevelFilter::Debug,
            (_, _, true) => log::LevelFilter::Info,
            (_, _, _) => log::LevelFilter::Warn,
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
            user_info_text,
        } => {
            let raw_args: (String, (u8, u8, u8)) = ron::de::from_str(&user_info_text).unwrap();
            let user_info: UserInfo = {
                (
                    raw_args.0,
                    (
                        Nat::from((raw_args.1).0),
                        Nat::from((raw_args.1).1),
                        Nat::from((raw_args.1).2),
                    ),
                )
            };
            let cfg = ConnectCfg {
                canister_id,
                replica_url,
                cli_opt,
                user_info,
            };
            let canister_id = Principal::from_text(cfg.canister_id.clone()).unwrap();
            let agent = create_agent(&cfg.replica_url)?;
            let ctx = ConnectCtx {
                cfg,
                canister_id,
                agent,
            };
            info!("Connecting to IC canister: {:?}", ctx.cfg);
            runtime.block_on(local_event_loop(ctx)).ok();
        }
    };
    Ok(())
}

#![allow(unused_imports)]
use crate::types::*;
use actix::prelude::*;
use candid::{Decode, Encode, Nat};
use crossbeam::Sender;
use delay::Delay;
use futures_util::stream::repeat;
use ic_agent::{Agent, AgentConfig, Blob, CanisterId};
use log::*;
use num_traits::cast::ToPrimitive;
use sdl2::event::Event as SysEvent; // not to be confused with our own definition
use sdl2::event::WindowEvent;
use sdl2::keyboard::Keycode;
use std::io;
use std::sync::{Arc, RwLock};
use std::time::Duration;
use tokio::time;

const RETRY_PAUSE: Duration = Duration::from_millis(100);
const REQUEST_TIMEOUT: Duration = Duration::from_secs(60);

#[derive(Message, Clone)]
#[rtype(result = "()")]
struct Ping;

/// Provides 200ms events
pub struct Trigger {
    // pub f: Box<dyn Fn(()) -> render::Result>,
    cfg: ConnectConfig,
    pub chan: Sender<render::Result>,
    keys: Arc<RwLock<Vec<event::KeyEventInfo>>>,
}

impl Trigger {
    pub fn new(
        cfg: ConnectConfig,
        chan: Sender<render::Result>,
        keys: Arc<RwLock<Vec<event::KeyEventInfo>>>,
    ) -> Self {
        Self { cfg, chan, keys }
    }
}

impl StreamHandler<Ping> for Trigger {
    fn handle(&mut self, _: Ping, ctx: &mut Context<Trigger>) {
        ctx.wait(actix::fut::wrap_future(time::delay_for(
            Duration::from_millis(2000),
        )));
        // (self.f)(());
        let key_infos = self.keys.read().unwrap().clone();

        // TODO(eftychis): reduce the scope of the lock above most likely!
        let rr = server_call(&self.cfg, &ServerCall::UpdateKeyDown(key_infos)).unwrap();

        // Ping that's time to pull in state and synchronize current's
        // player's state with server's.
        self.chan.send(rr).unwrap();
        println!("PING");
    }

    fn finished(&mut self, _: &mut Self::Context) {
        println!("finished");
    }
}

impl Actor for Trigger {
    type Context = Context<Self>;

    fn started(&mut self, ctx: &mut Context<Self>) {
        Self::add_stream(repeat(Ping), ctx);
    }
}

pub fn server_call(cfg: &ConnectConfig, call: &ServerCall) -> Result<render::Result, String> {
    use tokio::runtime::Runtime;
    debug!(
        "server_call: to canister_id {:?} at replica_url {:?}",
        cfg.canister_id, cfg.replica_url
    );
    let mut runtime = Runtime::new().expect("Unable to create a runtime");
    let delay = Delay::builder()
        .throttle(RETRY_PAUSE)
        .timeout(REQUEST_TIMEOUT)
        .build();
    let agent = agent(&cfg.replica_url).unwrap();
    let canister_id = CanisterId::from_text(cfg.canister_id.clone()).unwrap();
    let timestamp = std::time::SystemTime::now();
    info!("server_call: {:?}", call);
    let arg_bytes = match call {
        ServerCall::Tick => Encode!((&cfg.player_id)).unwrap(),
        ServerCall::WindowSizeChange(window_dim) => Encode!(&cfg.player_id, window_dim).unwrap(),
        ServerCall::QueryKeyDown(keys) => Encode!(&cfg.player_id, keys).unwrap(),
        ServerCall::UpdateKeyDown(keys) => Encode!(&cfg.player_id, keys).unwrap(),
    };
    info!(
        "server_call: Encoded argument via Candid; Arg size {:?} bytes",
        arg_bytes.len()
    );
    info!("server_call: Awaiting response from server...");
    // do an update or query call, based on the ServerCall case:
    let blob_res = match call {
        ServerCall::Tick => {
            runtime.block_on(agent.call_and_wait(&canister_id, &"tick", &Blob(arg_bytes), delay))
        }
        ServerCall::WindowSizeChange(_window_dim) => runtime.block_on(agent.call_and_wait(
            &canister_id,
            &"windowSizeChange",
            &Blob(arg_bytes),
            delay,
        )),
        ServerCall::QueryKeyDown(_keys) => {
            runtime.block_on(agent.query(&canister_id, &"queryKeyDown", &Blob(arg_bytes)))
        }
        ServerCall::UpdateKeyDown(_keys) => runtime.block_on(agent.call_and_wait(
            &canister_id,
            &"updateKeyDown",
            &Blob(arg_bytes),
            delay,
        )),
    };
    let elapsed = timestamp.elapsed().unwrap();
    if let Ok(blob_res) = blob_res {
        info!(
            "server_call: Ok: Response size {:?} bytes; elapsed time {:?}",
            blob_res.0.len(),
            elapsed
        );
        match Decode!(&(*blob_res.0), render::Result) {
            Ok(res) => {
                if true {
                    let mut res_log = format!("{:?}", &res);
                    if res_log.len() > 1000 {
                        res_log.truncate(1000);
                        res_log.push_str("...(truncated)");
                    }
                    info!(
                        "server_call: Successful decoding of graphics output: {:?}",
                        res_log
                    );
                }
                Ok(res)
            }
            Err(candid_err) => Err(format!("Candid decoding error: {:?}", candid_err)),
        }
    } else {
        let res = format!("{:?}", blob_res);
        info!("..error result {:?}", res);
        Err(format!("do_canister_tick() failed: {:?}", res))
    }
}

fn agent(url: &str) -> Result<Agent, ic_agent::AgentError> {
    Agent::new(AgentConfig {
        url: format!("http://{}", url).as_str(),
        ..AgentConfig::default()
    })
}

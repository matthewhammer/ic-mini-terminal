use actix::prelude::*;
use crossbeam::Sender;
use futures_util::stream::repeat;
use tokio::time;

use std::time::Duration;

#[derive(Message, Clone)]
#[rtype(result = "()")]
struct Ping;

/// Provides 200ms events
pub struct Trigger {
    pub f: Box<dyn Fn(()) -> ()>,
    pub chan: Sender<()>,
}

impl Trigger {
    pub fn new(f: Box<dyn Fn(()) -> ()>, chan: Sender<()>) -> Self {
        Self { f, chan }
    }
}

impl StreamHandler<Ping> for Trigger {
    fn handle(&mut self, _: Ping, ctx: &mut Context<Trigger>) {
        ctx.wait(actix::fut::wrap_future(time::delay_for(
            Duration::from_millis(300),
        )));
        (self.f)(());
        // Ping that's time to pull in state and synchronize current's
        // player's state with server's.
        self.chan.send(()).unwrap();
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

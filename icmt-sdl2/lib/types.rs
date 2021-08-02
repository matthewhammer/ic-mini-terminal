//! Types of data sent to and from the game service canister.

use crate::cli::ConnectCtx;
use chrono::prelude::*;
use num_traits::cast::ToPrimitive;
pub type Nat = candid::Nat;

/// temp hack: username and user-chosen color
pub type UserInfoCli = (String, (Nat, Nat, Nat));

/// User kind.
#[derive(Debug, Clone)]
pub enum UserKind {
    Local(UserInfoCli),
    Replay(Vec<event::EventInfo>),
}

pub fn nat_ceil(n: &Nat) -> u32 {
    n.0.to_u32().unwrap()
}

pub fn byte_ceil(n: &Nat) -> u8 {
    match n.0.to_u8() {
        Some(byte) => byte,
        None => 255,
    }
}

/// user name.
pub fn user_name(ctx: &ConnectCtx) -> Option<String> {
    match &ctx.cfg.user_kind {
        UserKind::Local(user_info) => Some(user_info.0.clone()),
        UserKind::Replay(_) => None,
    }
}

/// text color.
pub fn text_color(ctx: &ConnectCtx) -> Option<(Nat, Nat, Nat)> {
    match &ctx.cfg.user_kind {
        UserKind::Local(user_info) => Some(user_info.1.clone()),
        UserKind::Replay(_) => None,
    }
}

/// Form a skip event.
///
/// Skip events do nothing but carry meta event info, needed for per-user views.
pub fn skip_event(ctx: &ConnectCtx) -> event::EventInfo {
    if let UserKind::Local(_) = ctx.cfg.user_kind {
        event::EventInfo {
            user_info: event::UserInfo {
                user_name: user_name(ctx).unwrap(),
                text_color: (
                    text_color(ctx).unwrap(),
                    (Nat::from(0), Nat::from(0), Nat::from(0)),
                ),
            },
            nonce: None,
            date_time_local: Local::now().to_rfc3339(),
            date_time_utc: Utc::now().to_rfc3339(),
            event: event::Event::Skip,
        }
    } else {
        unimplemented!("skip events only come from live interaction, the Local user kind.")
    }
}

/// Messages from terminal to service (IC canister).
#[derive(Debug, Clone)]
pub enum ServiceCall {
    // Query a projected view of the remote canister
    View(graphics::Dim, Vec<event::EventInfo>),
    // Update the state of the remote canister
    Update(Vec<event::EventInfo>, graphics::Request),
    // To process user request to quit interaction
    FlushQuit,
}

/// Message language
pub mod lang {
    use super::Nat;
    //use hashcons::merkle::Merkle;
    use candid::{CandidType, Deserialize};

    /// Directions in two dimensional space.
    #[derive(Debug, Clone, CandidType, Deserialize, Eq, PartialEq, Hash)]
    pub enum Dir2D {
        #[serde(rename = "up")]
        Up,
        #[serde(rename = "down")]
        Down,
        #[serde(rename = "left")]
        Left,
        #[serde(rename = "right")]
        Right,
    }

    /// Symbolic name (n-ary tree).
    #[derive(Debug, Clone, CandidType, Deserialize, Eq, PartialEq, Hash)]
    pub enum Name {
        Void,
        Atom(Atom),
        TaggedTuple(Box<Name>, Vec<Name>),
        //Merkle(Merkle<Name>),
    }

    /// Atomic name
    #[derive(Debug, Clone, CandidType, Deserialize, Eq, PartialEq, Hash)]
    pub enum Atom {
        Bool(bool),
        Nat(Nat),
        String(String),
    }
}

/// Terminal events, locally buffered as input to service.
pub mod event {
    use candid::{CandidType, Deserialize, Nat};

    /// User information for identifying events' user origins.
    #[derive(Clone, Debug, CandidType, Deserialize, Hash, PartialEq, Eq)]
    pub struct UserInfo {
        #[serde(rename = "userName")]
        pub user_name: String,
        #[serde(rename = "textColor")]
        pub text_color: ((Nat, Nat, Nat), (Nat, Nat, Nat)),
    }

    /// Event information (full record).
    #[derive(Clone, Debug, CandidType, Deserialize, Hash, PartialEq, Eq)]
    pub struct EventInfo {
        #[serde(rename = "userInfo")]
        pub user_info: UserInfo,
        pub nonce: Option<Nat>,
        #[serde(rename = "dateTimeUtc")]
        pub date_time_utc: String,
        #[serde(rename = "dateTimeLocal")]
        pub date_time_local: String,
        pub event: Event,
    }
    /// Event(-specific information).
    #[derive(Clone, Debug, CandidType, Deserialize, Hash, PartialEq, Eq)]
    pub enum Event {
        #[serde(rename = "skip")]
        Skip,
        #[serde(rename = "quit")]
        Quit,
        #[serde(rename = "keyDown")]
        KeyDown(Vec<KeyEventInfo>),
        #[serde(rename = "mouseDown")]
        MouseDown(super::graphics::Pos),
        #[serde(rename = "windowSize")]
        WindowSize(super::graphics::Dim),
        #[serde(rename = "clipBoard")]
        ClipBoard(String),
    }
    /// Keyboard event information.
    #[derive(Clone, Debug, CandidType, Deserialize, Hash, PartialEq, Eq)]
    pub struct KeyEventInfo {
        pub key: String,
        pub alt: bool,
        pub ctrl: bool,
        pub meta: bool,
        pub shift: bool,
    }
}

/// Terminal gaphics, service output to terminal.
pub mod graphics {
    use super::Nat;
    //use super::lang::Name;
    use candid::{CandidType, Deserialize};

    /// Color
    pub type Color = (Nat, Nat, Nat);

    /// (Update message's) request for graphics.
    #[derive(Debug, Clone, CandidType, Deserialize, Eq, PartialEq, Hash)]
    pub enum Request {
        #[serde(rename = "none")]
        None,
        #[serde(rename = "all")]
        All(Dim),
        #[serde(rename = "last")]
        Last(Dim),
    }

    /// Dimension
    #[derive(Clone, Debug, CandidType, Deserialize, Hash, PartialEq, Eq)]
    pub struct Dim {
        pub width: Nat,
        pub height: Nat,
    }
    /// Position
    #[derive(Clone, Debug, CandidType, Deserialize, Hash, PartialEq, Eq)]
    pub struct Pos {
        pub x: Nat,
        pub y: Nat,
    }
    /// Rectangle
    #[derive(Clone, Debug, CandidType, Deserialize, Hash, PartialEq, Eq)]
    pub struct Rect {
        pub pos: Pos,
        pub dim: Dim,
    }
    impl Rect {
        pub fn new(x: Nat, y: Nat, w: Nat, h: Nat) -> Rect {
            Rect {
                pos: Pos { x, y },
                dim: Dim {
                    width: w,
                    height: h,
                },
            }
        }
    }
    #[derive(Clone, Debug, CandidType, Deserialize, Hash, PartialEq, Eq)]
    pub struct Node {
        pub rect: Rect,
        pub fill: Fill,
        pub elms: Elms,
    }
    /// Fill
    #[derive(Clone, Debug, CandidType, Deserialize, Hash, PartialEq, Eq)]
    pub enum Fill {
        #[serde(rename = "open")]
        Open(Color, Nat), // border width
        #[serde(rename = "closed")]
        Closed(Color),
        #[serde(rename = "none")]
        None,
    }
    /// Element
    #[derive(Clone, Debug, CandidType, Deserialize, Hash, PartialEq, Eq)]
    pub enum Elm {
        #[serde(rename = "rect")]
        Rect(Rect, Fill),
        #[serde(rename = "node")]
        Node(Box<Node>),
    }
    /// Elements
    pub type Elms = Vec<Elm>;
    /// Named elements
    pub type NamedElms = Vec<(String, Elm)>;

    /// Output
    #[derive(Clone, Debug, CandidType, Deserialize, Hash, PartialEq, Eq)]
    pub enum Out {
        #[serde(rename = "draw")]
        Draw(Elm),
        #[serde(rename = "redraw")]
        Redraw(NamedElms),
    }
    /// Result
    #[derive(Clone, Debug, CandidType, Deserialize, Hash, PartialEq, Eq)]
    pub enum Result {
        #[serde(rename = "ok")]
        Ok(Out),
        #[serde(rename = "err")]
        Err(Option<String>),
    }
}

/// Types of data sent to and from the game server canister.

pub mod lang {
    use hashcons::merkle::Merkle;
    use serde::{Deserialize, Serialize};

    pub type Hash = u64;
    pub type Nat = usize;

    #[derive(Debug, Clone, Serialize, Deserialize, Eq, PartialEq, Hash)]
    pub enum Name {
        Void,
        Atom(Atom),
        TaggedTuple(Box<Name>, Vec<Name>),
        Merkle(Merkle<Name>),
    }

    #[derive(Debug, Clone, Serialize, Deserialize, Eq, PartialEq, Hash)]
    pub enum Atom {
        Bool(bool),
        Usize(usize),
        String(String),
    }
}

pub mod event {
    use serde::{Deserialize, Serialize};

    #[derive(Clone, Debug, Serialize, Deserialize, Hash)]
    pub enum Event {
        Quit,
        KeyDown(KeyEventInfo),
        KeyUp(KeyEventInfo),
        WindowSizeChange(super::render::Dim),
    }
    #[derive(Clone, Debug, Serialize, Deserialize, Hash)]
    pub struct KeyEventInfo {
        pub key: String,
        pub alt: bool,
        pub ctrl: bool,
        pub meta: bool,
        pub shift: bool,
    }
}

pub mod render {
    use super::lang::Name;
    use serde::{Deserialize, Serialize};

    pub type Color = (usize, usize, usize);

    #[derive(Clone, Debug, Serialize, Deserialize, Hash)]
    pub struct Dim {
        pub width: usize,
        pub height: usize,
    }
    #[derive(Clone, Debug, Serialize, Deserialize, Hash)]
    pub struct Pos {
        pub x: isize,
        pub y: isize,
    }
    #[derive(Clone, Debug, Serialize, Deserialize, Hash)]
    pub struct Rect {
        pub pos: Pos,
        pub dim: Dim,
    }
    impl Rect {
        pub fn new(x: isize, y: isize, w: usize, h: usize) -> Rect {
            Rect {
                pos: Pos { x, y },
                dim: Dim {
                    width: w,
                    height: h,
                },
            }
        }
    }
    #[derive(Clone, Debug, Serialize, Deserialize, Hash)]
    pub struct Node {
        pub name: Name,
        pub rect: Rect,
        pub fill: Fill,
        pub children: Elms,
    }
    #[derive(Clone, Debug, Serialize, Deserialize, Hash)]
    pub enum Fill {
        #[serde(rename(serialize = "open", deserialize = "open"))]
        Open(Color, usize), // border width
        #[serde(rename(serialize = "closed", deserialize = "closed"))]
        Closed(Color),
        #[serde(rename(serialize = "none", deserialize = "none"))]
        None,
    }
    #[derive(Clone, Debug, Serialize, Deserialize, Hash)]
    pub enum Elm {
        #[serde(rename(serialize = "rect", deserialize = "rect"))]
        Rect(Rect, Fill),
        #[serde(rename(serialize = "node", deserialize = "node"))]
        Node(Box<Node>),
    }
    pub type Elms = Vec<Elm>;
    pub type NamedElms = Vec<(Name, Elm)>;

    #[derive(Clone, Debug, Serialize, Deserialize, Hash)]
    pub enum Out {
        #[serde(rename(serialize = "draw", deserialize = "draw"))]
        Draw(Elm),
        #[serde(rename(serialize = "redraw", deserialize = "redraw"))]
        Redraw(NamedElms),
    }

    #[derive(Clone, Debug, Serialize, Deserialize, Hash)]
    pub enum Result {
        #[serde(rename(serialize = "ok", deserialize = "ok"))]
        Ok(Out),
        #[serde(rename(serialize = "err", deserialize = "err"))]
        Err(Out),
    }
}

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

    #[derive(Clone, Debug, Serialize, Deserialize, Hash)]
    pub enum Color {
        RGB(usize, usize, usize),
    }
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
        Open(Color, usize), // border width
        Closed(Color),
        None,
    }
    #[derive(Clone, Debug, Serialize, Deserialize, Hash)]
    pub enum Elm {
        Rect(Rect, Fill),
        Node(Box<Node>),
    }
    pub type Elms = Vec<Elm>;
    pub type NamedElms = Vec<(Name, Elm)>;

    #[derive(Clone, Debug, Serialize, Deserialize, Hash)]
    pub enum Out {
        Draw(Elm),
        Redraw(NamedElms),
    }
}

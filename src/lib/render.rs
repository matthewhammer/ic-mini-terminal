use candid::{CandidType, Deserialize};

use bitmap;
use glyph;
pub use types::{
    lang::{Atom, Dir2D, Name},
    render::{Color, Dim, Elm, Elms, Fill, NamedElms, Node, Out, Pos, Rect},
};

#[derive(Clone, Debug, CandidType, Deserialize, Hash)]
pub struct BitmapAtts {
    pub zoom: usize,
    pub fill_isset: Fill,
    pub fill_notset: Fill,
}

#[derive(Clone, Debug, CandidType, Deserialize, Hash)]
pub struct TextAtts {
    pub zoom: usize,
    pub fg_fill: Fill,
    pub bg_fill: Fill,
    pub glyph_dim: Dim,
    pub glyph_flow: FlowAtts,
}

#[derive(Clone, Debug, CandidType, Deserialize, Hash)]
pub struct FlowAtts {
    pub dir: Dir2D,
    pub intra_pad: usize,
    pub inter_pad: usize,
}

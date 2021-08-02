//! Mini-terminal utility library.
//!
//! (Note: Public modules and types for demonstration purposes; all are subject to change.)

extern crate log;
//extern crate hashcons;
extern crate candid;
extern crate serde;
extern crate serde_bytes;
//extern crate candid_derive;

pub mod cli;
pub mod color;
pub mod draw;
pub mod error;
pub mod keyboard;
pub mod types;
pub mod write;

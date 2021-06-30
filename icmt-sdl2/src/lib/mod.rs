//! Mini-terminal utility library.
//!
//! (Note: Public modules and types for demonstration purposes; all are subject to change.)

extern crate log;
//extern crate hashcons;
extern crate candid;
extern crate serde;
extern crate serde_bytes;
//extern crate candid_derive;

// common types.
pub mod types;

// all specific to SDL2-based IO:
pub mod cli;
pub mod write;
pub mod error;
pub mod color;
pub mod draw;
pub mod keyboard;

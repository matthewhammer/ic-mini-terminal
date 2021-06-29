use wasm_bindgen::prelude::*;

use std::f64;

use wasm_bindgen::JsCast;
use web_sys::{self, console};

use std::cell::Cell;
use std::rc::Rc;

extern crate icmt;
use icmt::{
    color,
    draw,
    error,
    keyboard,
    types::{
        event, graphics, nat_ceil, skip_event, text_color, user_name, ServiceCall, UserInfoCli,
        UserKind,
    },
};

fn console_log(m: String) {
    let message: JsValue = m.as_str().clone().into();
    console::log_1(&message);
}

fn get_context() -> web_sys::CanvasRenderingContext2d {
    // to do -- left this step outside of the recursion, for efficiency
    let document = web_sys::window().unwrap().document().unwrap();
    let canvas = document.get_element_by_id("canvas").unwrap();
    let canvas: web_sys::HtmlCanvasElement = canvas
        .dyn_into::<web_sys::HtmlCanvasElement>()
        .map_err(|_| ())
        .unwrap();
    let context = canvas
        .get_context("2d")
        .unwrap()
        .unwrap()
        .dyn_into::<web_sys::CanvasRenderingContext2d>()
        .unwrap();
    context
}

async fn draw_elms(elms: &Elms) -> OurResult<()> {
    let context = get_context();

    let pos = Pos { x: 0, y: 0 };
    let dim = Dim {
        width: 888,
        height: 666,
    };
    let fill = Fill::Closed(Color::RGB(0, 0, 0));
    draw_rect_elms(&mut context, &pos, &dim, &fill, &elms).await?;
}

// Called when the wasm module is instantiated
#[wasm_bindgen(start)]
pub async fn main() -> Result<(), JsValue> {

    draw_elms(&elms)?;
 
    let closure = Closure::wrap(Box::new(move |event: web_sys::KeyboardEvent| {
        let render_elms = {
            // translate each system event into zero, one or more in the engine's format.
            let events = match format!("{}", event.key()).as_str() {
                "Tab" | "Escape" | "ArrowUp" | "ArrowDown" | "ArrowLeft" | "ArrowRight" | " "
                | "Backspace" => vec![Event::KeyDown(KeyEventInfo {
                    key: event.key(),
                    alt: event.alt_key(),
                    ctrl: event.ctrl_key(),
                    shift: event.shift_key(),
                    meta: event.meta_key(),
                })],
                key => {
                    console_log(format!("unrecognized key: {}", key));
                    vec![]
                }
            };

            if false {
                console_log(format!("event key {} ==> events {:?}", event.key(), events));
            };
            // for each engine event, get commands from the engine,
            //   and run the commands in the engine, updating the state.
            for event in events.iter() {
                let commands = eval::commands_of_event(&mut state, event);
                match commands {
                    Ok(commands) => {
                        for command in commands.iter() {
                            let res = eval::command_eval(&mut state, command);
                            console_log(format!("eval({:?}) ==> {:?}", command, res))
                        }
                    }
                    Err(_) => {
                        // User is asking to escape; reset the state
                        console_log(format!("resetting state..."));
                        state = init::init_state();
                    }
                }
            }

            // get engine's render elements from updated state
            eval::render_elms(&mut state).unwrap()
        };
        // save updated state
        state_cell.set(state);

        // draw the engine elements onto the document's canvas element
        draw_elms(&render_elms);
    }) as Box<dyn FnMut(_)>);

    let document = web_sys::window().unwrap().document().unwrap();
    document.set_onkeydown(Some(closure.as_ref().unchecked_ref()));
    //document.set_onkeypress(Some(closure.as_ref().unchecked_ref()));
    //document.set_onkeyup(Some(closure.as_ref().unchecked_ref()));
    //document.set_oninput(Some(closure.as_ref().unchecked_ref()));
    closure.forget();

    Ok(())
}

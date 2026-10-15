import gleam/option.{type Option, None, Some}
import lustre
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html

//! MAIN ------------------------------------------------------------------------

pub fn main() {
  let app = lustre.application(init, update, view)

  let assert Ok(_) = lustre.start(app, "#app", Nil)

  Nil
}

//! MODEL -----------------------------------------------------------------------

type Model {
  Model(reply: Option(String))
}

fn init(_) -> #(Model, Effect(Msg)) {
  #(Model(reply: None), effect.none())
}

//! UPDATE ----------------------------------------------------------------------

type Msg

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    _ -> #(model, effect.none())
  }
}

//! VIEW ------------------------------------------------------------------------

fn view(model: Model) -> Element(Msg) {
  element.fragment([
    html.main(
      [
        attribute.class(
          "absolute inset-0 flex flex-col items-center justify-center gap-4",
        ),
      ],
      [
        html.img([
          attribute.class("p-24"),
          attribute.src("/melodink_fulllogo.png"),
        ]),
        case model.reply {
          Some(reply) ->
            html.p([attribute.class("text-xl text-white")], [
              element.text(reply),
            ])
          None -> element.none()
        },
      ],
    ),
  ])
}

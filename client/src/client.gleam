import client/theme
import gleam/option.{type Option, None, Some}
import lustre
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

//! MAIN ------------------------------------------------------------------------

pub fn main() {
  theme.apply(theme.cyan)

  let app = lustre.application(init, update, view)

  let assert Ok(_) = lustre.start(app, "#app", Nil)

  Nil
}

//! MODEL -----------------------------------------------------------------------

type Model {
  Model
}

fn init(_) -> #(Model, Effect(Msg)) {
  #(Model, effect.none())
}

//! UPDATE ----------------------------------------------------------------------

type Msg {
  UserClickedLogo
}

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    UserClickedLogo -> #(
      model,
      effect.from(fn(_) { theme.apply(theme.purple) }),
    )
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
          event.on_click(UserClickedLogo),
        ]),
      ],
    ),
  ])
}

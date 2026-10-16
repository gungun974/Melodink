pub type Theme {
  Theme(
    //
    a: #(Int, Int, Int),
    b: #(Int, Int, Int),
    c: #(Int, Int, Int),
  )
}

pub const default =
  Theme(
    //
    a: #(58, 91, 111),
    b: #(216, 232, 238),
    c: #(151, 201, 218),
  )

pub const dark =
  Theme(
    //
    a: #(50, 40, 50),
    b: #(20, 20, 30),
    c: #(60, 80, 80),
  )

pub const purple =
  Theme(
    //
    a: #(205, 207, 224),
    b: #(111, 86, 179),
    c: #(159, 108, 177),
  )

pub const grey =
  Theme(
    //
    a: #(235, 235, 235),
    b: #(195, 195, 195),
    c: #(133, 133, 133),
  )

pub const cyan =
  Theme(
    //
    a: #(128, 216, 183),
    b: #(79, 187, 151),
    c: #(48, 156, 217),
  )

pub fn apply(theme: Theme) {
  let a = compute_coord(127.0, 0.0, 0.9)
  let b = compute_coord(217.0, 0.0, 0.8)
  let c = compute_coord(336.0, 0.0, 1.0)

  update_resize_listener(fn() {
    do_apply(
      base: #(6, 6, 6, 1.0),
      a: #(
        a.0,
        a.1,
        #(theme.a.0, theme.a.1, theme.a.2, 0.55),
        a.2,
        #(theme.a.0, theme.a.1, theme.a.2, 0.0),
      ),
      b: #(
        b.0,
        b.1,
        #(theme.b.0, theme.b.1, theme.b.2, 0.55),
        b.2,
        #(theme.b.0, theme.b.1, theme.b.2, 0.1),
      ),
      c: #(
        c.0,
        c.1,
        #(theme.c.0, theme.c.1, theme.c.2, 0.55),
        c.2,
        #(theme.c.0, theme.c.1, theme.c.2, 0.05),
      ),
    )
  })
  Nil
}

@external(javascript, "./theme_ffi.mjs", "apply")
fn do_apply(
  base base: #(Int, Int, Int, Float),
  a a: #(Float, Float, #(Int, Int, Int, Float), Float, #(Int, Int, Int, Float)),
  b b: #(Float, Float, #(Int, Int, Int, Float), Float, #(Int, Int, Int, Float)),
  c c: #(Float, Float, #(Int, Int, Int, Float), Float, #(Int, Int, Int, Float)),
) -> Nil

@external(javascript, "./theme_ffi.mjs", "computeCoord")
fn compute_coord(
  angle: Float,
  start: Float,
  end: Float,
) -> #(Float, Float, Float)

@external(javascript, "./theme_ffi.mjs", "updateResizeListener")
fn update_resize_listener(callback: fn() -> Nil) -> Nil

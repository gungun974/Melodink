export function apply(base, a, b, c) {
  document.body.style.setProperty(
    "--app-gradient-base",
    `rgba(${base[0]}, ${base[1]}, ${base[2]}, ${base[3]})`,
  );

  document.body.style.setProperty("--app-gradient-a-angle", `${a[0]}deg`);
  document.body.style.setProperty("--app-gradient-a-start", `${a[1] * 100}%`);
  document.body.style.setProperty(
    "--app-gradient-a-from",
    `rgba(${a[2][0]}, ${a[2][1]}, ${a[2][2]}, ${a[2][3]})`,
  );
  document.body.style.setProperty("--app-gradient-a-end", `${a[3] * 100}%`);
  document.body.style.setProperty(
    "--app-gradient-a-to",
    `rgba(${a[4][0]}, ${a[4][1]}, ${a[4][2]}, ${a[4][3]})`,
  );

  document.body.style.setProperty("--app-gradient-b-angle", `${b[0]}deg`);
  document.body.style.setProperty("--app-gradient-b-start", `${b[1] * 100}%`);
  document.body.style.setProperty(
    "--app-gradient-b-from",
    `rgba(${b[2][0]}, ${b[2][1]}, ${b[2][2]}, ${b[2][3]})`,
  );
  document.body.style.setProperty("--app-gradient-b-end", `${b[3] * 100}%`);
  document.body.style.setProperty(
    "--app-gradient-b-to",
    `rgba(${b[4][0]}, ${b[4][1]}, ${b[4][2]}, ${b[4][3]})`,
  );

  document.body.style.setProperty("--app-gradient-c-angle", `${c[0]}deg`);
  document.body.style.setProperty("--app-gradient-c-start", `${c[1] * 100}%`);
  document.body.style.setProperty(
    "--app-gradient-c-from",
    `rgba(${c[2][0]}, ${c[2][1]}, ${c[2][2]}, ${c[2][3]})`,
  );
  document.body.style.setProperty("--app-gradient-c-end", `${c[3] * 100}%`);
  document.body.style.setProperty(
    "--app-gradient-c-to",
    `rgba(${c[4][0]}, ${c[4][1]}, ${c[4][2]}, ${c[4][3]})`,
  );

  requestAnimationFrame(() => {
    document.body.classList.add("animated");
  });
}

export function computeCoord(angle, start, end) {
  const radians = (angle * Math.PI) / 180;

  const sin = Math.sin(radians);
  const cos = Math.cos(radians);

  const w = window.innerWidth;
  const h = window.innerHeight;

  const w2 = w ** 2;
  const h2 = h ** 2;

  let newAngle = (Math.atan2(w * sin, h * cos) * 180) / Math.PI;

  if (newAngle < 0) {
    newAngle += 360;
  }

  const ratio =
    (w2 * sin * sin + h2 * cos * cos) /
    (w2 * Math.abs(sin) + h2 * Math.abs(cos));

  return [newAngle, 0.5 + (start - 0.5) * ratio, 0.5 + (end - 0.5) * ratio];
}

let handleResize;

export function updateResizeListener(callback) {
  window.removeEventListener("resize", handleResize);
  handleResize = callback;
  window.addEventListener("resize", handleResize);
  handleResize();
}

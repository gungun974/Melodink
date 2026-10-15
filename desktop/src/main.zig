const builtin = @import("builtin");

const Webview = @import("webview").Webview;

const std = @import("std");

pub fn main() !void {
    std.debug.print("", .{});

    const w = try Webview.create(builtin.mode == .debug, null);
    defer w.destroy() catch unreachable;
    try w.setTitle("Melodink");
    try w.setSize(800, 600, .none);

    try w.navigate("https://127.0.0.1:1234");

    try w.run();
}

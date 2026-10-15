const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});

    const optimize = b.standardOptimizeOption(.{});

    var macos_sdk = b.option([]const u8, "macos-sdk", "Path to macOS SDK (optional, macOS targets only)");
    if (macos_sdk == null and target.result.os.tag == .macos) {
        if (b.lazyDependency("macos_sdk", .{})) |dep| {
            macos_sdk = dep.builder.root.joinString(b.allocator, &.{}) catch @panic("OOM");
        }
    }

    const exe = b.addExecutable(.{
        .name = "desktop",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),

            .target = target,
            .optimize = optimize,

            .imports = &.{},
        }),
    });

    if (macos_sdk) |sdk| {
        const sdk_path: std.Build.LazyPath = .{ .cwd_relative = sdk };
        exe.root_module.addSystemIncludePath(sdk_path.path(b, "usr/include"));
        exe.root_module.addLibraryPath(sdk_path.path(b, "usr/lib"));
        exe.root_module.addSystemFrameworkPath(sdk_path.path(b, "System/Library/Frameworks"));
    }

    const webview_dep = b.dependency("webview", .{
        .target = target,
        .optimize = optimize,
        .@"macos-sdk" = macos_sdk,
    });

    exe.root_module.addImport("webview", webview_dep.module("webview"));

    b.installArtifact(exe);

    const run_step = b.step("run", "Run the app");

    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);

    run_cmd.step.dependOn(b.getInstallStep());
}

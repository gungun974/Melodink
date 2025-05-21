const std = @import("std");
const builtin = @import("builtin");

const auto_detect = @import("build/auto-detect.zig");

const XCFrameworkStep = @import("build/XCFrameworkStep.zig");

const ANDROID_TARGET_API_VERSION = "32";
const ANDROID_MIN_API_VERSION = "21";
const ANDROID_BUILD_TOOLS_VERSION = "34.0.0";
const ANDROID_NDK_VERSION = "23.1.7779620";

pub fn build(b: *std.Build) void {
    // Build
    const target = b.standardTargetOptions(.{});

    const optimize = b.standardOptimizeOption(.{});

    if (target.result.os.tag == .ios) {
        buildForIOS(b, optimize) catch unreachable;
        return;
    }

    if (target.result.os.tag == .macos) {
        buildForMacOS(b, optimize) catch unreachable;
        return;
    }

    const lib = try buildLibrary(
        b,
        target,
        optimize,
        .static,
    );

    lib.linkLibC();

    b.installArtifact(lib);
}

fn buildForMacOS(b: *std.Build, optimize: std.builtin.OptimizeMode) !void {
    const aarch64 = try buildLibrary(
        b,
        b.resolveTargetQuery(.{
            .cpu_arch = .aarch64,
            .os_tag = .macos,
        }),
        optimize,
        .static,
    );

    const x86_64 = try buildLibrary(
        b,
        b.resolveTargetQuery(.{
            .cpu_arch = .x86_64,
            .os_tag = .macos,
        }),
        optimize,
        .static,
    );

    const universal = buildLipo(
        b,
        aarch64.getEmittedBin(),
        x86_64.getEmittedBin(),
        "libmelodink_player.a",
    );

    const xcframework = buildXCFramework(b, &.{
        .{
            .library = universal,
            .headers = b.path("include"),
        },
    }, "MelodinkPlayer.xcframework");

    b.installDirectory(.{
        .source_dir = xcframework,
        .install_dir = .prefix,
        .install_subdir = "macos/MelodinkPlayer.xcframework",
    });

    const ffmpeg = b.lazyDependency("ffmpeg_macos", .{}) orelse return;

    b.installDirectory(.{
        .source_dir = ffmpeg.path("."),
        .install_dir = .prefix,
        .install_subdir = "macos",
    });
}

fn buildForIOS(b: *std.Build, optimize: std.builtin.OptimizeMode) !void {
    const ios = try buildLibrary(
        b,
        b.resolveTargetQuery(.{
            .cpu_arch = .aarch64,
            .os_tag = .ios,
            .abi = null,
        }),
        optimize,
        .static,
    );

    const ios_sim = try buildLibrary(
        b,
        b.resolveTargetQuery(.{
            .cpu_arch = .aarch64,
            .os_tag = .ios,
            .abi = .simulator,

            // We force the Apple CPU model because the simulator
            // doesn't support the generic CPU model as of Zig 0.14 due
            // to missing "altnzcv" instructions, which is false. This
            // surely can't be right but we can fix this if/when we get
            // back to running simulator builds.
            .cpu_model = .{ .explicit = &std.Target.aarch64.cpu.apple_a17 },
        }),
        optimize,
        .static,
    );

    const xcframework = buildXCFramework(b, &.{
        .{
            .library = ios.getEmittedBin(),
            .headers = b.path("include"),
        },
        .{
            .library = ios_sim.getEmittedBin(),
            .headers = b.path("include"),
        },
    }, "MelodinkPlayer.xcframework");

    b.installDirectory(.{
        .source_dir = xcframework,
        .install_dir = .prefix,
        .install_subdir = "ios/MelodinkPlayer.xcframework",
    });

    const ffmpeg = b.lazyDependency("ffmpeg_ios", .{}) orelse return;

    b.installDirectory(.{
        .source_dir = ffmpeg.path("."),
        .install_dir = .prefix,
        .install_subdir = "ios",
    });
}

const Library = struct {
    library: std.Build.LazyPath,

    headers: std.Build.LazyPath,
};

fn buildXCFramework(b: *std.Build, libraries: []const Library, name: []const u8) std.Build.LazyPath {
    const tool_run = b.addSystemCommand(&.{ "xcodebuild", "-create-xcframework" });

    for (libraries) |lib| {
        tool_run.addArg("-library");
        tool_run.addFileArg(lib.library);
        tool_run.addArg("-headers");
        tool_run.addDirectoryArg(lib.headers);
    }

    tool_run.addArg("-output");

    const ret = tool_run.addOutputDirectoryArg(name);
    b.getInstallStep().dependOn(&tool_run.step);
    return ret;
}

fn buildLipo(
    b: *std.Build,
    input_a: std.Build.LazyPath,
    input_b: std.Build.LazyPath,
    name: []const u8,
) std.Build.LazyPath {
    const tool_run = b.addSystemCommand(&.{ "lipo", "-create", "-output" });

    const ret = tool_run.addOutputFileArg(name);

    tool_run.addFileArg(input_a);
    tool_run.addFileArg(input_b);

    b.getInstallStep().dependOn(&tool_run.step);
    return ret;
}

fn buildLibrary(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode, linkage: std.builtin.LinkMode) !*std.Build.Step.Compile {
    const lib_mod = b.createModule(.{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    const lib = b.addLibrary(.{
        .linkage = linkage,
        .name = "melodink_player",
        .root_module = lib_mod,
    });

    try addSystemCompilePaths(b, target, lib);

    try addLibraries(b, target, lib);

    return lib;
}

fn addSystemCompilePaths(b: *std.Build, target: std.Build.ResolvedTarget, step: anytype) !void {
    if (target.result.os.tag == .ios or target.result.os.tag == .macos) {
        const sysroot = std.zig.system.darwin.getSdk(b.allocator, target.result) orelse b.sysroot;
        step.addLibraryPath(.{ .cwd_relative = b.pathJoin(&.{ sysroot orelse "", "/usr/lib" }) });
        step.addIncludePath(.{ .cwd_relative = b.pathJoin(&.{ sysroot orelse "", "/usr/include" }) });
        step.addFrameworkPath(.{ .cwd_relative = b.pathJoin(&.{ sysroot orelse "", "/System/Library/Frameworks" }) });
    } else if (target.result.abi.isAndroid()) {
        const target_dir_name = switch (target.result.cpu.arch) {
            .aarch64 => "aarch64-linux-android",
            .x86_64 => "x86_64-linux-android",
            else => @panic("unsupported arch for android build"),
        };
        _ = target_dir_name;

        const android_sdk = try auto_detect.findAndroidSDKConfig(b, &target.result, .{
            .api_version = ANDROID_TARGET_API_VERSION,
            .build_tools_version = ANDROID_BUILD_TOOLS_VERSION,
            .ndk_version = ANDROID_NDK_VERSION,
        });

        step.addIncludePath(.{ .cwd_relative = android_sdk.android_ndk_include });
        step.addIncludePath(.{ .cwd_relative = android_sdk.android_ndk_include_android });
        step.addIncludePath(.{ .cwd_relative = android_sdk.android_ndk_include_host });
        step.addIncludePath(.{ .cwd_relative = android_sdk.android_ndk_include_host_android });
        step.addIncludePath(.{ .cwd_relative = android_sdk.android_ndk_include_host_arch_android });

        step.addLibraryPath(.{ .cwd_relative = android_sdk.android_ndk_lib_host_arch_android });
    }
}

fn addLibraries(b: *std.Build, target: std.Build.ResolvedTarget, step: anytype) !void {
    if (target.result.os.tag == .ios) {
        step.bundle_compiler_rt = true;
        step.bundle_ubsan_rt = true;
        step.linker_allow_shlib_undefined = true;
    }

    // FFmpeg

    if (target.result.os.tag == .ios) {
        const target_dir_name = switch (target.result.abi) {
            .simulator => "ios-arm64_x86_64-simulator",
            else => "ios-arm64",
        };

        const ffmpeg = b.lazyDependency("ffmpeg_ios", .{}) orelse return;

        step.addFrameworkPath(ffmpeg.path(b.fmt("Avcodec.xcframework/{s}", .{target_dir_name})));
        step.addFrameworkPath(ffmpeg.path(b.fmt("Avformat.xcframework/{s}", .{target_dir_name})));
        step.addFrameworkPath(ffmpeg.path(b.fmt("Avutil.xcframework/{s}", .{target_dir_name})));
        step.addFrameworkPath(ffmpeg.path(b.fmt("Swresample.xcframework/{s}", .{target_dir_name})));

        step.addIncludePath(ffmpeg.path(b.fmt("Avcodec.xcframework/{s}/Avcodec.framework/Headers", .{target_dir_name})));
        step.addIncludePath(ffmpeg.path(b.fmt("Avformat.xcframework/{s}/Avformat.framework/Headers", .{target_dir_name})));
        step.addIncludePath(ffmpeg.path(b.fmt("Avutil.xcframework/{s}/Avutil.framework/Headers", .{target_dir_name})));
        step.addIncludePath(ffmpeg.path(b.fmt("Swresample.xcframework/{s}/Swresample.framework/Headers", .{target_dir_name})));

        step.linkFramework("Avcodec");
        step.linkFramework("Avformat");
        step.linkFramework("Avutil");
        step.linkFramework("Swresample");
    } else if (target.result.os.tag == .macos) {
        const ffmpeg = b.lazyDependency("ffmpeg_macos", .{}) orelse return;

        step.addFrameworkPath(ffmpeg.path("Avcodec.xcframework/macos-arm64_x86_64"));
        step.addFrameworkPath(ffmpeg.path("Avformat.xcframework/macos-arm64_x86_64"));
        step.addFrameworkPath(ffmpeg.path("Avutil.xcframework/macos-arm64_x86_64"));
        step.addFrameworkPath(ffmpeg.path("Swresample.xcframework/macos-arm64_x86_64"));

        step.addIncludePath(ffmpeg.path("Avcodec.xcframework/macos-arm64_x86_64/Avcodec.framework/Headers"));
        step.addIncludePath(ffmpeg.path("Avformat.xcframework/macos-arm64_x86_64/Avformat.framework/Headers"));
        step.addIncludePath(ffmpeg.path("Avutil.xcframework/macos-arm64_x86_64/Avutil.framework/Headers"));
        step.addIncludePath(ffmpeg.path("Swresample.xcframework/macos-arm64_x86_64/Swresample.framework/Headers"));

        step.linkFramework("Avcodec");
        step.linkFramework("Avformat");
        step.linkFramework("Avutil");
        step.linkFramework("Swresample");
    } else if (target.result.abi.isAndroid()) {
        const target_dir_name = switch (target.result.cpu.arch) {
            .aarch64 => "arm64-v8a",
            .armeb => "armeabi-v7a",
            .x86_64 => "x86_64",
            .x86 => "x86",
            else => @panic("unsupported arch for android build"),
        };

        step.addIncludePath(b.path(b.fmt("/home/gungun974/lab/perso/Melodink/client/build/app/ffmpeg/prefix/{s}/include", .{target_dir_name})));
        step.addLibraryPath(b.path(b.fmt("/home/gungun974/lab/perso/Melodink/client/build/app/ffmpeg/prefix/{s}/usr/local/lib", .{target_dir_name})));

        step.linkSystemLibrary2("avcodec", .{
            .use_pkg_config = .no,
        });
        step.linkSystemLibrary2("avformat", .{
            .use_pkg_config = .no,
        });
        step.linkSystemLibrary2("avutil", .{
            .use_pkg_config = .no,
        });
        step.linkSystemLibrary2("swresample", .{
            .use_pkg_config = .no,
        });
    } else {
        step.linkSystemLibrary("avcodec");
        step.linkSystemLibrary("avformat");
        step.linkSystemLibrary("avutil");
        step.linkSystemLibrary("swresample");
    }

    // Miniaudio

    if (target.result.os.tag == .ios or target.result.os.tag == .macos) {
        step.linkFramework("CoreFoundation");
        step.linkFramework("AVFoundation");
        step.linkFramework("AudioToolbox");

        step.addCSourceFile(.{ .file = b.addWriteFiles().addCopyFile(b.path("src/miniaudio/miniaudio.c"), "miniaudio.m"), .flags = &.{
            "-DMA_NO_DECODING",
            "-DMA_NO_ENCODING",
            "-DMA_NO_RUNTIME_LINKING",
            "-fwrapv",
        } });
    } else {
        step.addCSourceFile(.{ .file = b.path("src/miniaudio/miniaudio.c"), .flags = &.{
            "-DMA_NO_DECODING",
            "-DMA_NO_ENCODING",
            "-DMA_NO_RUNTIME_LINKING",
            "-fwrapv",
        } });
    }

    const miniaudio_path = prepareMiniaudio(b);
    step.addIncludePath(miniaudio_path.dirname());
}

fn prepareMiniaudio(b: *std.Build) std.Build.LazyPath {
    const tool_run = b.addSystemCommand(&.{"patch"});
    tool_run.addFileArg(b.path("src/miniaudio/miniaudio.h"));

    tool_run.addArg("-o");
    const ret = tool_run.addOutputFileArg("miniaudio.h");
    tool_run.addFileArg(b.path("src/miniaudio/zig_18247.patch"));
    b.getInstallStep().dependOn(&tool_run.step);
    return ret;
}

const std = @import("std");
const builtin = @import("builtin");

const auto_detect = @import("build/auto-detect.zig");


const ANDROID_TARGET_API_VERSION = "32";
const ANDROID_MIN_API_VERSION = "32";
const ANDROID_BUILD_TOOLS_VERSION = "34.0.0";
const ANDROID_NDK_VERSION = "26.1.10909125";


pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});

    const optimize = b.standardOptimizeOption(.{});

    const lib_mod = b.createModule(.{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Build

    const lib = b.addLibrary(.{
        .linkage = .static,
        .name = "melodink_player",
        .root_module = lib_mod,
    });

    if (target.result.abi.isAndroid()) {
        lib.addIncludePath(.{ .cwd_relative = "/home/gungun974/lab/perso/Melodink/client/build/app/ffmpeg/prefix/arm64-v8a/include" });
        lib.addLibraryPath(.{ .cwd_relative = "/home/gungun974/lab/perso/Melodink/client/build/app/ffmpeg/prefix/arm64-v8a/usr/local/lib" });

        lib.linkSystemLibrary2("avcodec", .{
            .use_pkg_config = .no,
        });
        lib.linkSystemLibrary2("avformat", .{
            .use_pkg_config = .no,
        });
        lib.linkSystemLibrary2("avutil", .{
            .use_pkg_config = .no,
        });
        lib.linkSystemLibrary2("swresample", .{
            .use_pkg_config = .no,
        });
    } else {
        //lib.linkSystemLibrary("avcodec");
        //lib.linkSystemLibrary("avformat");
        //lib.linkSystemLibrary("avutil");
        //lib.linkSystemLibrary("swresample");

        lib.addFrameworkPath(b.path("../ios/MelodinkPlayer/Frameworks/Avcodec.xcframework/ios-arm64"));
        lib.addFrameworkPath(b.path("../ios/MelodinkPlayer/Frameworks/Avformat.xcframework/ios-arm64"));
        lib.addFrameworkPath(b.path("../ios/MelodinkPlayer/Frameworks/Avutil.xcframework/ios-arm64"));
        lib.addFrameworkPath(b.path("../ios/MelodinkPlayer/Frameworks/Swresample.xcframework/ios-arm64"));

        lib.addIncludePath(b.path("../ios/MelodinkPlayer/Frameworks/Avcodec.xcframework/ios-arm64/Avcodec.framework/Headers"));
        lib.addIncludePath(b.path("../ios/MelodinkPlayer/Frameworks/Avformat.xcframework/ios-arm64/Avformat.framework/Headers"));
        lib.addIncludePath(b.path("../ios/MelodinkPlayer/Frameworks/Avutil.xcframework/ios-arm64/Avutil.framework/Headers"));
        lib.addIncludePath(b.path("../ios/MelodinkPlayer/Frameworks/Swresample.xcframework/ios-arm64/Swresample.framework/Headers"));

    lib.linkFramework("Avcodec");
    lib.linkFramework("Avformat");
    lib.linkFramework("Avutil");
    lib.linkFramework("Swresample");
    }

    lib.addCSourceFile(.{ .file = b.addWriteFiles().addCopyFile(b.path("src/miniaudio/miniaudio.c"), "miniaudio.m"), .flags = &.{
        "-DMA_NO_DECODING",
        "-DMA_NO_ENCODING",
        "-DMA_NO_RUNTIME_LINKING",
        "-fwrapv",
    } });
    lib.addIncludePath(b.path("src/miniaudio"));

    lib.linkFramework("CoreFoundation");
    lib.linkFramework("AVFoundation");
    lib.linkFramework("AudioToolbox");

            lib.linker_allow_shlib_undefined = true;


             addCompilePaths(b, target, lib) catch unreachable;


    if (target.result.abi.isAndroid()) {
        //these are the only tag options per https://developer.android.com/ndk/guides/other_build_systems
        const hostTuple = switch (builtin.target.os.tag) {
            .linux => "linux-x86_64",
            .windows => "windows-x86_64",
            .macos => "darwin-x86_64",
            else => @panic("unsupported host OS"),
        };

        const androidTriple = switch (target.result.cpu.arch) {
            .x86 => "i686-linux-android",
            .x86_64 => "x86_64-linux-android",
            .arm => "arm-linux-androideabi",
            .aarch64 => "aarch64-linux-android",
            .riscv64 => "riscv64-linux-android",
            else => error.InvalidAndroidTarget,
        } catch @panic("invalid android target!");

        const androidNdkPathString: []const u8 = "/nix/store/x04mvdyhkisg70a6i5jhbaqns9ya3a1q-android-sdk-env/share/android-sdk/ndk/23.1.7779620";
        if (androidNdkPathString.len < 1) @panic("no ndk path provided and ANDROID_NDK_HOME is not set");
        // const androidApiLevel: []const u8 = options.android_api_version;
        const androidApiLevel: []const u8 = "21";

        const androidSysroot = std.fs.path.join(b.allocator, &.{ androidNdkPathString, "/toolchains/llvm/prebuilt/", hostTuple, "/sysroot" }) catch unreachable;
        const androidLibPath = std.fs.path.join(b.allocator, &.{ androidSysroot, "/usr/lib/", androidTriple }) catch unreachable;
        const androidApiSpecificPath = std.fs.path.join(b.allocator, &.{ androidLibPath, androidApiLevel }) catch unreachable;
        const androidIncludePath = std.fs.path.join(b.allocator, &.{ androidSysroot, "/usr/include" }) catch unreachable;
        const androidArchIncludePath = std.fs.path.join(b.allocator, &.{ androidIncludePath, androidTriple }) catch unreachable;
        const androidAsmPath = std.fs.path.join(b.allocator, &.{ androidIncludePath, "/asm-generic" }) catch unreachable;
        const androidGluePath = std.fs.path.join(b.allocator, &.{ androidNdkPathString, "/sources/android/native_app_glue/" }) catch unreachable;

        var libcData = std.ArrayList(u8).init(b.allocator);
        const writer = libcData.writer();
        (std.zig.LibCInstallation{
            .include_dir = androidIncludePath,
            .sys_include_dir = androidIncludePath,
            .crt_dir = androidApiSpecificPath,
        }).render(writer) catch unreachable;

        const libcFile = b.addWriteFiles().add("android-libc.txt", libcData.toOwnedSlice() catch unreachable);

        lib.setLibCFile(libcFile);

        lib.root_module.addLibraryPath(.{ .cwd_relative = androidApiSpecificPath });
        lib.addSystemIncludePath(.{ .cwd_relative = androidIncludePath });
        lib.addSystemIncludePath(.{ .cwd_relative = androidArchIncludePath });
        lib.addSystemIncludePath(.{ .cwd_relative = androidAsmPath });
        lib.addSystemIncludePath(.{ .cwd_relative = androidGluePath });
    }

    b.installArtifact(lib);

    // Check

    const lib_check = b.addExecutable(.{
        .name = "MelodinkZigPlayer",
        .root_module = lib_mod,
    });

    // lib_check.linkLibC();
    lib_check.addIncludePath(b.path("src/miniaudio"));

    // Test

    const exe_unit_tests = b.addTest(.{
        .root_module = lib_mod,
    });

    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    const check = b.step("check", "Check if MelodinkZigPlayer compiles");
    check.dependOn(&lib_check.step);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_exe_unit_tests.step);
}

fn addCompilePaths(b: *std.Build, target: std.Build.ResolvedTarget, step: anytype) !void {
    if (target.result.os.tag == .ios) {
        const sysroot = std.zig.system.darwin.getSdk(b.allocator, target.result) orelse b.sysroot;
        step.addLibraryPath(.{ .cwd_relative = b.pathJoin(&.{ sysroot orelse "", "/usr/lib" }) }); //(.{ .cwd_relative = "/usr/lib" });
        step.addIncludePath(.{ .cwd_relative = b.pathJoin(&.{ sysroot orelse "", "/usr/include" }) }); //(.{ .cwd_relative = "/usr/include" });
        step.addFrameworkPath(.{ .cwd_relative = b.pathJoin(&.{ sysroot orelse "", "/System/Library/Frameworks" }) }); //(.{ .cwd_relative = "/System/Library/Frameworks" });
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

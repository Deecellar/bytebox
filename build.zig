const std = @import("std");

const CrossTarget = std.zig.CrossTarget;
const Builder = std.build.Builder;
const LibExeObjStep = std.build.LibExeObjStep;

const ExeOpts = struct {
    exe_name: []const u8,
    root_src: []const u8,
    step_name: []const u8,
    description: []const u8,
    step_dependencies: ?[]*std.build.Step = null,
};

pub fn build(b: *Builder) void {
    const target = b.standardTargetOptions(.{});

    var bench_add_one_step: *LibExeObjStep = buildWasmLib(b, "bench/samples/add-one.zig");
    var bench_fibonacci_step: *LibExeObjStep = buildWasmLib(b, "bench/samples/fibonacci.zig");
    var bench_mandelbrot_step: *LibExeObjStep = buildWasmLib(b, "bench/samples/mandelbrot.zig");

    buildExeWithStep(b, target, .{
        .exe_name = "run",
        .root_src = "run/main.zig",
        .step_name = "run",
        .description = "Run a wasm program",
    });
    buildExeWithStep(b, target, .{
        .exe_name = "testsuite",
        .root_src = "test/main.zig",
        .step_name = "test",
        .description = "Run the test suite",
    });
    buildExeWithStep(b, target, .{
        .exe_name = "benchmark",
        .root_src = "bench/main.zig",
        .step_name = "bench",
        .description = "Run the benchmark suite",
        .step_dependencies = &[_]*std.build.Step{
            &bench_add_one_step.step,
            &bench_fibonacci_step.step,
            &bench_mandelbrot_step.step,
        },
    });
}

fn buildExeWithStep(b: *Builder, target: CrossTarget, opts: ExeOpts) void {
    const exe = b.addExecutable(opts.exe_name, opts.root_src);

    exe.addPackage(std.build.Pkg{
        .name = "bytebox",
        .source = .{ .path = "src/core.zig" },
    });

    const mode = b.standardReleaseOptions();

    exe.setTarget(target);
    exe.setBuildMode(mode);
    exe.install();

    if (opts.step_dependencies) |steps| {
        for (steps) |step| {
            exe.step.dependOn(step);
        }
    }

    const run = exe.run();
    run.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run.addArgs(args);
    }

    const step = b.step(opts.step_name, opts.description);
    step.dependOn(&run.step);
}

fn buildWasmLib(b: *Builder, filepath: []const u8) *LibExeObjStep {
    var filename: []const u8 = std.fs.path.basename(filepath);
    var filename_no_extension: []const u8 = filename[0 .. filename.len - 4];

    const lib = b.addSharedLibrary(filename_no_extension, filepath, .unversioned);

    const mode = b.standardReleaseOptions();
    lib.setTarget(CrossTarget{
        .cpu_arch = .wasm32,
        .os_tag = .freestanding,
    });
    lib.setBuildMode(mode);
    lib.install();

    return lib;
}

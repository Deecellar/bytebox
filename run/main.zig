const std = @import("std");
const bytebox = @import("bytebox");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var allocator: std.mem.Allocator = gpa.allocator();

    var args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len != 2) {
        std.log.info("Usage: {s} <wasmfile>", .{args[0]});
    }

    const wasm_filename: []const u8 = args[1];

    var cwd = std.fs.cwd();
    var wasm_data: []u8 = try cwd.readFileAlloc(allocator, wasm_filename, 1024 * 1024 * 128);
    var module_def = bytebox.ModuleDefinition.init(allocator);
    defer module_def.deinit();
    try module_def.decode(wasm_data);

    var module_instance = bytebox.ModuleInstance.init(&module_def, allocator);
    defer module_instance.deinit();
    try module_instance.instantiate(.{});
}

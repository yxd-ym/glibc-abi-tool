const std = @import("std");
const Target = std.Target;
const Version = std.builtin.Version;
const mem = std.mem;
const log = std.log;
const fs = std.fs;
const fmt = std.fmt;

// Example abilist path:
// ./sysdeps/unix/sysv/linux/aarch64/libc.abilist
const AbiList = struct {
    targets: []const ZigTarget,
    path: []const u8,
};
const ZigTarget = struct {
    arch: std.Target.Cpu.Arch,
    abi: std.Target.Abi,

    fn getIndex(zt: ZigTarget) u16 {
        for (zig_targets) |other, i| {
            if (zt.eql(other)) {
                return @intCast(u16, i);
            }
        }
        unreachable;
    }

    fn eql(zt: ZigTarget, other: ZigTarget) bool {
        return zt.arch == other.arch and zt.abi == other.abi;
    }
};

const lib_names = [_][]const u8{
    "c",
    "dl",
    "m",
    "pthread",
    "rt",
    "ld",
    "util",
};

const zig_targets = [_]ZigTarget{
    // zig fmt: off
    .{ .arch = .aarch64    , .abi = .gnu },
    .{ .arch = .aarch64_be , .abi = .gnu },
    .{ .arch = .s390x      , .abi = .gnu },
    .{ .arch = .arm        , .abi = .gnueabi },
    .{ .arch = .armeb      , .abi = .gnueabi },
    .{ .arch = .arm        , .abi = .gnueabihf },
    .{ .arch = .armeb      , .abi = .gnueabihf },
    .{ .arch = .sparc      , .abi = .gnu },
    .{ .arch = .sparcel    , .abi = .gnu },
    .{ .arch = .sparcv9    , .abi = .gnu },
    .{ .arch = .mips64el   , .abi = .gnuabi64 },
    .{ .arch = .mips64     , .abi = .gnuabi64 },
    .{ .arch = .mips64el   , .abi = .gnuabin32 },
    .{ .arch = .mips64     , .abi = .gnuabin32 },
    .{ .arch = .mipsel     , .abi = .gnueabihf },
    .{ .arch = .mips       , .abi = .gnueabihf },
    .{ .arch = .mipsel     , .abi = .gnueabi },
    .{ .arch = .mips       , .abi = .gnueabi },
    .{ .arch = .x86_64     , .abi = .gnu },
    .{ .arch = .x86_64     , .abi = .gnux32 },
    .{ .arch = .i386       , .abi = .gnu },
    .{ .arch = .powerpc64le, .abi = .gnu },
    .{ .arch = .powerpc64  , .abi = .gnu },
    .{ .arch = .powerpc    , .abi = .gnueabi },
    .{ .arch = .powerpc    , .abi = .gnueabihf },
    // zig fmt: on
};

const versions = [_]Version{
    .{.major = 2, .minor = 0},
    .{.major = 2, .minor = 1},
    .{.major = 2, .minor = 1, .patch = 1},
    .{.major = 2, .minor = 1, .patch = 2},
    .{.major = 2, .minor = 1, .patch = 3},
    .{.major = 2, .minor = 2},
    .{.major = 2, .minor = 2, .patch = 1},
    .{.major = 2, .minor = 2, .patch = 2},
    .{.major = 2, .minor = 2, .patch = 3},
    .{.major = 2, .minor = 2, .patch = 4},
    .{.major = 2, .minor = 2, .patch = 5},
    .{.major = 2, .minor = 2, .patch = 6},
    .{.major = 2, .minor = 3},
    .{.major = 2, .minor = 3, .patch = 2},
    .{.major = 2, .minor = 3, .patch = 3},
    .{.major = 2, .minor = 3, .patch = 4},
    .{.major = 2, .minor = 4},
    .{.major = 2, .minor = 5},
    .{.major = 2, .minor = 6},
    .{.major = 2, .minor = 7},
    .{.major = 2, .minor = 8},
    .{.major = 2, .minor = 9},
    .{.major = 2, .minor = 10},
    .{.major = 2, .minor = 11},
    .{.major = 2, .minor = 12},
    .{.major = 2, .minor = 13},
    .{.major = 2, .minor = 14},
    .{.major = 2, .minor = 15},
    .{.major = 2, .minor = 16},
    .{.major = 2, .minor = 17},
    .{.major = 2, .minor = 18},
    .{.major = 2, .minor = 19},
    .{.major = 2, .minor = 20},
    .{.major = 2, .minor = 21},
    .{.major = 2, .minor = 22},
    .{.major = 2, .minor = 23},
    .{.major = 2, .minor = 24},
    .{.major = 2, .minor = 25},
    .{.major = 2, .minor = 26},
    .{.major = 2, .minor = 27},
    .{.major = 2, .minor = 28},
    .{.major = 2, .minor = 29},
    .{.major = 2, .minor = 30},
    .{.major = 2, .minor = 31},
    .{.major = 2, .minor = 32},
    .{.major = 2, .minor = 33},
    .{.major = 2, .minor = 34},
};

// fpu/nofpu are hardcoded elsewhere, based on .gnueabi/.gnueabihf with an exception for .arm
// n64/n32 are hardcoded elsewhere, based on .gnuabi64/.gnuabin32
const abi_lists = [_]AbiList{
    AbiList{
        .targets = &[_]ZigTarget{
            ZigTarget{ .arch = .aarch64, .abi = .gnu },
            ZigTarget{ .arch = .aarch64_be, .abi = .gnu },
        },
        .path = "aarch64",
    },
    AbiList{
        .targets = &[_]ZigTarget{ZigTarget{ .arch = .s390x, .abi = .gnu }},
        .path = "s390/s390-64",
    },
    AbiList{
        .targets = &[_]ZigTarget{
            ZigTarget{ .arch = .arm, .abi = .gnueabi },
            ZigTarget{ .arch = .armeb, .abi = .gnueabi },
            ZigTarget{ .arch = .arm, .abi = .gnueabihf },
            ZigTarget{ .arch = .armeb, .abi = .gnueabihf },
        },
        .path = "arm",
    },
    AbiList{
        .targets = &[_]ZigTarget{
            ZigTarget{ .arch = .sparc, .abi = .gnu },
            ZigTarget{ .arch = .sparcel, .abi = .gnu },
        },
        .path = "sparc/sparc32",
    },
    AbiList{
        .targets = &[_]ZigTarget{ZigTarget{ .arch = .sparcv9, .abi = .gnu }},
        .path = "sparc/sparc64",
    },
    AbiList{
        .targets = &[_]ZigTarget{
            ZigTarget{ .arch = .mips64el, .abi = .gnuabi64 },
            ZigTarget{ .arch = .mips64, .abi = .gnuabi64 },
        },
        .path = "mips/mips64",
    },
    AbiList{
        .targets = &[_]ZigTarget{
            ZigTarget{ .arch = .mips64el, .abi = .gnuabin32 },
            ZigTarget{ .arch = .mips64, .abi = .gnuabin32 },
        },
        .path = "mips/mips64",
    },
    AbiList{
        .targets = &[_]ZigTarget{
            ZigTarget{ .arch = .mipsel, .abi = .gnueabihf },
            ZigTarget{ .arch = .mips, .abi = .gnueabihf },
        },
        .path = "mips/mips32",
    },
    AbiList{
        .targets = &[_]ZigTarget{
            ZigTarget{ .arch = .mipsel, .abi = .gnueabi },
            ZigTarget{ .arch = .mips, .abi = .gnueabi },
        },
        .path = "mips/mips32",
    },
    AbiList{
        .targets = &[_]ZigTarget{ZigTarget{ .arch = .x86_64, .abi = .gnu }},
        .path = "x86_64/64",
    },
    AbiList{
        .targets = &[_]ZigTarget{ZigTarget{ .arch = .x86_64, .abi = .gnux32 }},
        .path = "x86_64/x32",
    },
    AbiList{
        .targets = &[_]ZigTarget{ZigTarget{ .arch = .i386, .abi = .gnu }},
        .path = "i386",
    },
    AbiList{
        .targets = &[_]ZigTarget{ZigTarget{ .arch = .powerpc64le, .abi = .gnu }},
        .path = "powerpc/powerpc64",
    },
    AbiList{
        .targets = &[_]ZigTarget{ZigTarget{ .arch = .powerpc64, .abi = .gnu }},
        .path = "powerpc/powerpc64",
    },
    AbiList{
        .targets = &[_]ZigTarget{
            ZigTarget{ .arch = .powerpc, .abi = .gnueabi },
            ZigTarget{ .arch = .powerpc, .abi = .gnueabihf },
        },
        .path = "powerpc/powerpc32",
    },
};

/// After glibc 2.33, mips64 put some files inside n64 and n32 directories.
const ver33 = std.builtin.Version{
    .major = 2,
    .minor = 33,
};

/// glibc 2.31 added sysdeps/unix/sysv/linux/arm/le and sysdeps/unix/sysv/linux/arm/be
/// Before these directories did not exist.
const ver30 = std.builtin.Version{
    .major = 2,
    .minor = 30,
};

/// Similarly, powerpc64 le and be were introduced in glibc 2.29
const ver28 = std.builtin.Version{
    .major = 2,
    .minor = 28,
};

/// Before this version the abilist files had a different structure.
const ver23 = std.builtin.Version{
    .major = 2,
    .minor = 23,
};

const Symbol = struct {
    type: [lib_names.len][zig_targets.len][versions.len]Type = empty_row3,
    is_fn: bool = undefined,

    const empty_row = [1]Type{.absent} ** versions.len;
    const empty_row2 = [1]@TypeOf(empty_row){empty_row} ** zig_targets.len;
    const empty_row3 = [1]@TypeOf(empty_row2){empty_row2} ** lib_names.len;

    const Type = union(enum) {
        absent,
        function,
        object: u16,

        fn eql(ty: Type, other: Type) bool {
            return switch (ty) {
                .absent => unreachable,
                .function => other == .function,
                .object => |ty_size| switch (other) {
                    .absent => unreachable,
                    .function => false,
                    .object => |other_size| ty_size == other_size,
                },
            };
        }
    };
};

// LSB is first version.
const VersionSet = u64;

pub fn main() !void {
    var arena_instance = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const arena = arena_instance.allocator();

    //const args = try std.process.argsAlloc(arena);

    var version_dir = try fs.cwd().openDir("glibc", .{ .iterate = true });
    defer version_dir.close();

    const fs_versions = v: {
        var fs_versions = std.ArrayList(Version).init(arena);

        var version_dir_it = version_dir.iterate();
        while (try version_dir_it.next()) |entry| {
            if (mem.eql(u8, entry.name, "COPYING")) continue;
            try fs_versions.append(try Version.parse(entry.name));
        }

        break :v fs_versions.items;
    };
    std.sort.sort(Version, fs_versions, {}, versionDescending);

    var symbols = std.StringHashMap(Symbol).init(arena);

    for (fs_versions) |fs_ver| {
        if (fs_ver.order(ver23) == .lt) {
            log.warn("skipping glibc version {} because the abilist files have a different format", .{fs_ver});
            continue;
        }
        log.info("scanning abilist files for glibc version: {}", .{fs_ver});

        const prefix = try fmt.allocPrint(arena, "{d}.{d}/sysdeps/unix/sysv/linux", .{
            fs_ver.major, fs_ver.minor, 
        });
        for (abi_lists) |*abi_list| {
            for (lib_names) |lib_name, lib_i| {
                const lib_prefix = if (std.mem.eql(u8, lib_name, "ld")) "" else "lib";
                const basename = try fmt.allocPrint(arena, "{s}{s}.abilist", .{ lib_prefix, lib_name });
                const abi_list_filename = blk: {
                    const is_c = std.mem.eql(u8, lib_name, "c");
                    const is_m = std.mem.eql(u8, lib_name, "m");
                    const is_ld = std.mem.eql(u8, lib_name, "ld");
                    const is_rt = std.mem.eql(u8, lib_name, "rt");
                    if ((abi_list.targets[0].arch == .mips64 or
                        abi_list.targets[0].arch == .mips64el) and
                        fs_ver.order(ver33) == .gt and (is_rt or is_c or is_ld))
                    {
                        if (abi_list.targets[0].abi == .gnuabi64) {
                            break :blk try fs.path.join(arena, &.{
                                prefix, abi_list.path, "n64", basename,
                            });
                        } else if (abi_list.targets[0].abi == .gnuabin32) {
                            break :blk try fs.path.join(arena, &.{
                                prefix, abi_list.path, "n32", basename,
                            });
                        } else {
                            unreachable;
                        }
                    } else if (abi_list.targets[0].abi == .gnuabi64 and (is_c or is_ld)) {
                        break :blk try fs.path.join(arena, &.{
                            prefix, abi_list.path, "n64", basename,
                        });
                    } else if (abi_list.targets[0].abi == .gnuabin32 and (is_c or is_ld)) {
                        break :blk try fs.path.join(arena, &.{
                            prefix, abi_list.path, "n32", basename,
                        });
                    } else if (abi_list.targets[0].arch != .arm and
                        abi_list.targets[0].abi == .gnueabihf and
                        (is_c or (is_m and abi_list.targets[0].arch == .powerpc)))
                    {
                        break :blk try fs.path.join(arena, &.{
                            prefix, abi_list.path, "fpu", basename,
                        });
                    } else if (abi_list.targets[0].arch != .arm and
                        abi_list.targets[0].abi == .gnueabi and
                        (is_c or (is_m and abi_list.targets[0].arch == .powerpc)))
                    {
                        break :blk try fs.path.join(arena, &.{
                            prefix, abi_list.path, "nofpu", basename,
                        });
                    } else if ((abi_list.targets[0].arch == .armeb or
                            abi_list.targets[0].arch == .arm) and fs_ver.order(ver30) == .gt)
                    {
                        const endian_suffix = switch (abi_list.targets[0].arch) {
                            .armeb => "be",
                            else => "le",
                        };
                        break :blk try fs.path.join(arena, &.{
                            prefix, abi_list.path, endian_suffix, basename,
                        });
                    } else if ((abi_list.targets[0].arch == .powerpc64le or
                            abi_list.targets[0].arch == .powerpc64)) {
                        if (fs_ver.order(ver28) == .gt) {
                            const endian_suffix = switch (abi_list.targets[0].arch) {
                                .powerpc64le => "le",
                                else => "be",
                            };
                            break :blk try fs.path.join(arena, &.{
                                prefix, abi_list.path, endian_suffix, basename,
                            });
                        }
                        // 2.28 and earlier, the files looked like this:
                        // libc.abilist
                        // libc-le.abilist
                        const endian_suffix = switch (abi_list.targets[0].arch) {
                            .powerpc64le => "-le",
                            else => "",
                        };
                        break :blk try fmt.allocPrint(arena, "{s}/{s}/{s}{s}{s}.abilist", .{
                            prefix, abi_list.path, lib_prefix, lib_name, endian_suffix,
                        });
                    }

                    break :blk try fs.path.join(arena, &.{ prefix, abi_list.path, basename });
                };

                const max_bytes = 10 * 1024 * 1024;
                const contents = version_dir.readFileAlloc(arena, abi_list_filename, max_bytes) catch |err| {
                    fatal("unable to open glibc/{s}: {}", .{ abi_list_filename, err });
                };
                var lines_it = std.mem.tokenize(u8, contents, "\n");
                while (lines_it.next()) |line| {
                    var tok_it = std.mem.tokenize(u8, line, " ");
                    const ver_text = tok_it.next().?;
                    if (mem.startsWith(u8, ver_text, "GCC_")) continue;
                    if (mem.startsWith(u8, ver_text, "_gp_disp")) continue;
                    if (!mem.startsWith(u8, ver_text, "GLIBC_")) {
                        fatal("line did not start with 'GLIBC_': '{s}'", .{line});
                    }
                    const ver = try Version.parse(ver_text["GLIBC_".len..]);
                    const name = tok_it.next() orelse {
                        fatal("symbol name not found in glibc/{s} on line '{s}'", .{
                            abi_list_filename, line,
                        });
                    };
                    const category = tok_it.next().?;
                    const ty: Symbol.Type = if (mem.eql(u8, category, "F"))
                        .{ .function = {} }
                    else if (mem.eql(u8, category, "D"))
                        .{ .object = try fmt.parseInt(u16, tok_it.next().?, 0) }
                    else if (mem.eql(u8, category, "A"))
                        continue
                    else
                        fatal("unrecognized symbol type '{s}' on line '{s}'", .{category, line});

                    const gop = try symbols.getOrPut(name);
                    if (!gop.found_existing) {
                        gop.value_ptr.* = .{};
                    }
                    for (abi_list.targets) |t| {
                        gop.value_ptr.type[lib_i][t.getIndex()][verIndex(ver)] = ty;
                    }
                }
            }
        }
    }

    // Our data format depends on the type of a symbol being consistently a function or an object
    // and not switching depending on target or version. Here we verify that premise.
    {
        var it = symbols.iterator();
        while (it.next()) |entry| {
            const name = entry.key_ptr.*;
            var prev_ty: @typeInfo(Symbol.Type).Union.tag_type.? = .absent;
            for (entry.value_ptr.type) |targets_row| {
                for (targets_row) |versions_row| {
                    for (versions_row) |ty| {
                        switch (ty) {
                            .absent => continue,
                            .function => switch (prev_ty) {
                                .absent => prev_ty = ty,
                                .function => continue,
                                .object => fatal("symbol {s} switches types", .{name}),
                            },
                            .object => switch (prev_ty) {
                                .absent => prev_ty = ty,
                                .function => fatal("symbol {s} switches types", .{name}),
                                .object => continue,
                            },
                        }
                    }
                }
            }
            entry.value_ptr.is_fn = switch (prev_ty) {
                .absent => unreachable,
                .function => true,
                .object => false,
            };
        }
        log.info("confirmed that every symbol is consistently either an object or a function", .{});
    }

    // Now we have all the data and we want to emit the fewest number of inclusions as possible.
    // The first split is functions vs objects.
    // For functions, the only type possibilities are `absent` or `function`.
    // We use a greedy algorithm, "spreading" the inclusion from a single point to
    // as many targets as possible, then to as many versions as possible.
}

fn versionDescending(context: void, a: Version, b: Version) bool {
    _ = context;
    return b.order(a) == .lt;
}

fn fatal(comptime format: []const u8, args: anytype) noreturn {
    log.err(format, args);
    std.process.exit(1);
}

fn verIndex(ver: Version) u6 {
    for (versions) |v, i| {
        if (v.order(ver) == .eq) {
            return @intCast(u6, i);
        }
    }
    unreachable;
}

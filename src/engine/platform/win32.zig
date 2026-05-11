const std = @import("std");
const windows = std.os.windows;
const config = @import("../config.zig");

pub const HINSTANCE = windows.HINSTANCE;
pub const HWND = windows.HWND;
const HICON = *opaque {};
const HCURSOR = *opaque {};
const HBRUSH = *opaque {};
const HMENU = *opaque {};
pub const HMODULE = *opaque {};
const WPARAM = usize;
const LPARAM = isize;
const LRESULT = isize;
const WNDPROC = *const fn (?HWND, u32, WPARAM, LPARAM) callconv(.winapi) LRESULT;

const WNDCLASSW = extern struct {
    style: u32,
    lpfnWndProc: WNDPROC,
    cbClsExtra: i32,
    cbWndExtra: i32,
    hInstance: HINSTANCE,
    hIcon: ?HICON,
    hCursor: ?HCURSOR,
    hbrBackground: ?HBRUSH,
    lpszMenuName: ?[*:0]const u16,
    lpszClassName: [*:0]const u16,
};

const MSG = extern struct {
    hwnd: ?HWND,
    message: u32,
    wParam: WPARAM,
    lParam: LPARAM,
    time: u32,
    pt: POINT,
};

const POINT = extern struct {
    x: i32,
    y: i32,
};

const RECT = extern struct {
    left: i32,
    top: i32,
    right: i32,
    bottom: i32,
};

const CS_OWNDC = 0x0020;
const CW_USEDEFAULT = @as(i32, -2147483648);
const WS_OVERLAPPEDWINDOW = 0x00CF0000;
const WS_VISIBLE = 0x10000000;
const PM_REMOVE = 0x0001;
const WM_DESTROY = 0x0002;
const WM_CLOSE = 0x0010;
const WM_SIZE = 0x0005;
const WM_QUIT = 0x0012;

extern "user32" fn RegisterClassW(lpWndClass: *const WNDCLASSW) callconv(.winapi) u16;
extern "user32" fn CreateWindowExW(dwExStyle: u32, lpClassName: [*:0]const u16, lpWindowName: [*:0]const u16, dwStyle: u32, x: i32, y: i32, nWidth: i32, nHeight: i32, hWndParent: ?HWND, hMenu: ?HMENU, hInstance: HINSTANCE, lpParam: ?*anyopaque) callconv(.winapi) ?HWND;
extern "user32" fn DefWindowProcW(hWnd: ?HWND, Msg: u32, wParam: WPARAM, lParam: LPARAM) callconv(.winapi) LRESULT;
extern "user32" fn DestroyWindow(hWnd: HWND) callconv(.winapi) i32;
extern "user32" fn PostQuitMessage(nExitCode: i32) callconv(.winapi) void;
extern "user32" fn PeekMessageW(lpMsg: *MSG, hWnd: ?HWND, wMsgFilterMin: u32, wMsgFilterMax: u32, wRemoveMsg: u32) callconv(.winapi) i32;
extern "user32" fn TranslateMessage(lpMsg: *const MSG) callconv(.winapi) i32;
extern "user32" fn DispatchMessageW(lpMsg: *const MSG) callconv(.winapi) LRESULT;
extern "user32" fn GetClientRect(hWnd: HWND, lpRect: *RECT) callconv(.winapi) i32;
extern "user32" fn AdjustWindowRectEx(lpRect: *RECT, dwStyle: u32, bMenu: i32, dwExStyle: u32) callconv(.winapi) i32;
extern "kernel32" fn GetModuleHandleW(lpModuleName: ?[*:0]const u16) callconv(.winapi) HINSTANCE;
pub extern "kernel32" fn LoadLibraryA(lpLibFileName: [*:0]const u8) callconv(.winapi) ?HMODULE;
pub extern "kernel32" fn GetProcAddress(hModule: HMODULE, lpProcName: [*:0]const u8) callconv(.winapi) ?*const anyopaque;
pub extern "kernel32" fn FreeLibrary(hLibModule: HMODULE) callconv(.winapi) i32;

pub const Window = struct {
    hinstance: HINSTANCE,
    hwnd: HWND,
    last_size: Size = .{ .width = config.WIDTH, .height = config.HEIGHT },

    pub fn create() !Window {
        const hinstance = GetModuleHandleW(null);
        const class_name = comptime std.unicode.utf8ToUtf16LeStringLiteral("WarlockWindow");
        const title = comptime std.unicode.utf8ToUtf16LeStringLiteral("Warlock - GPU Kernel Renderer");

        const wc = WNDCLASSW{
            .style = CS_OWNDC,
            .lpfnWndProc = windowProc,
            .cbClsExtra = 0,
            .cbWndExtra = 0,
            .hInstance = hinstance,
            .hIcon = null,
            .hCursor = null,
            .hbrBackground = null,
            .lpszMenuName = null,
            .lpszClassName = class_name,
        };
        if (RegisterClassW(&wc) == 0) return error.RegisterClassFailed;

        const window_style = WS_OVERLAPPEDWINDOW | WS_VISIBLE;
        var rect = RECT{
            .left = 0,
            .top = 0,
            .right = config.WIDTH,
            .bottom = config.HEIGHT,
        };
        if (AdjustWindowRectEx(&rect, window_style, 0, 0) == 0) return error.AdjustWindowRectFailed;

        const window_width = rect.right - rect.left;
        const window_height = rect.bottom - rect.top;
        const hwnd = CreateWindowExW(0, class_name, title, window_style, CW_USEDEFAULT, CW_USEDEFAULT, window_width, window_height, null, null, hinstance, null) orelse return error.CreateWindowFailed;
        return .{ .hinstance = hinstance, .hwnd = hwnd };
    }

    pub fn deinit(self: Window) void {
        _ = self;
    }
};

pub const Size = struct {
    width: u32,
    height: u32,
};

pub const MessagePumpResult = struct {
    should_run: bool = true,
    resized: bool = false,
    size: Size = .{ .width = config.WIDTH, .height = config.HEIGHT },
};

pub fn clientSize(hwnd: HWND) Size {
    var rect: RECT = undefined;
    _ = GetClientRect(hwnd, &rect);
    const width = @max(rect.right - rect.left, 0);
    const height = @max(rect.bottom - rect.top, 0);
    return .{ .width = @intCast(width), .height = @intCast(height) };
}

pub fn pumpMessages(window: *Window) MessagePumpResult {
    var result = MessagePumpResult{
        .size = window.last_size,
    };
    var should_run = true;
    var msg: MSG = undefined;
    while (PeekMessageW(&msg, null, 0, 0, PM_REMOVE) != 0) {
        if (msg.message == WM_QUIT) should_run = false;
        if (msg.message == WM_SIZE and msg.hwnd == window.hwnd) {
            const size = clientSize(window.hwnd);
            if (size.width != window.last_size.width or size.height != window.last_size.height) {
                window.last_size = size;
                result.resized = true;
                result.size = size;
            }
        }
        _ = TranslateMessage(&msg);
        _ = DispatchMessageW(&msg);
    }
    result.should_run = should_run;
    return result;
}

fn windowProc(hwnd: ?HWND, msg: u32, wparam: WPARAM, lparam: LPARAM) callconv(.winapi) LRESULT {
    switch (msg) {
        WM_CLOSE => {
            if (hwnd) |window| _ = DestroyWindow(window);
            return 0;
        },
        WM_DESTROY => {
            PostQuitMessage(0);
            return 0;
        },
        else => return DefWindowProcW(hwnd, msg, wparam, lparam),
    }
}

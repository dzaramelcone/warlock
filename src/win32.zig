const std = @import("std");
const windows = std.os.windows;
const config = @import("config.zig");

pub const HINSTANCE = windows.HINSTANCE;
pub const HWND = windows.HWND;
pub const HDC = windows.HDC;
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

const BITMAPINFOHEADER = extern struct {
    biSize: u32,
    biWidth: i32,
    biHeight: i32,
    biPlanes: u16,
    biBitCount: u16,
    biCompression: u32,
    biSizeImage: u32,
    biXPelsPerMeter: i32,
    biYPelsPerMeter: i32,
    biClrUsed: u32,
    biClrImportant: u32,
};

const RGBQUAD = extern struct {
    rgbBlue: u8,
    rgbGreen: u8,
    rgbRed: u8,
    rgbReserved: u8,
};

const BITMAPINFO = extern struct {
    bmiHeader: BITMAPINFOHEADER,
    bmiColors: [1]RGBQUAD,
};

const CS_OWNDC = 0x0020;
const CW_USEDEFAULT = @as(i32, -2147483648);
const WS_OVERLAPPEDWINDOW = 0x00CF0000;
const WS_VISIBLE = 0x10000000;
const PM_REMOVE = 0x0001;
const WM_DESTROY = 0x0002;
const WM_CLOSE = 0x0010;
const WM_QUIT = 0x0012;
const DIB_RGB_COLORS = 0;
const BI_RGB = 0;
const SRCCOPY = 0x00CC0020;

extern "user32" fn RegisterClassW(lpWndClass: *const WNDCLASSW) callconv(.winapi) u16;
extern "user32" fn CreateWindowExW(dwExStyle: u32, lpClassName: [*:0]const u16, lpWindowName: [*:0]const u16, dwStyle: u32, x: i32, y: i32, nWidth: i32, nHeight: i32, hWndParent: ?HWND, hMenu: ?HMENU, hInstance: HINSTANCE, lpParam: ?*anyopaque) callconv(.winapi) ?HWND;
extern "user32" fn DefWindowProcW(hWnd: ?HWND, Msg: u32, wParam: WPARAM, lParam: LPARAM) callconv(.winapi) LRESULT;
extern "user32" fn DestroyWindow(hWnd: HWND) callconv(.winapi) i32;
extern "user32" fn PostQuitMessage(nExitCode: i32) callconv(.winapi) void;
extern "user32" fn PeekMessageW(lpMsg: *MSG, hWnd: ?HWND, wMsgFilterMin: u32, wMsgFilterMax: u32, wRemoveMsg: u32) callconv(.winapi) i32;
extern "user32" fn TranslateMessage(lpMsg: *const MSG) callconv(.winapi) i32;
extern "user32" fn DispatchMessageW(lpMsg: *const MSG) callconv(.winapi) LRESULT;
extern "user32" fn GetDC(hWnd: HWND) callconv(.winapi) HDC;
extern "user32" fn ReleaseDC(hWnd: HWND, hDC: HDC) callconv(.winapi) i32;
extern "user32" fn GetClientRect(hWnd: HWND, lpRect: *RECT) callconv(.winapi) i32;
extern "kernel32" fn GetModuleHandleW(lpModuleName: ?[*:0]const u16) callconv(.winapi) HINSTANCE;
pub extern "kernel32" fn LoadLibraryA(lpLibFileName: [*:0]const u8) callconv(.winapi) ?HMODULE;
pub extern "kernel32" fn GetProcAddress(hModule: HMODULE, lpProcName: [*:0]const u8) callconv(.winapi) ?*const anyopaque;
pub extern "kernel32" fn FreeLibrary(hLibModule: HMODULE) callconv(.winapi) i32;
extern "gdi32" fn StretchDIBits(hdc: HDC, xDest: i32, yDest: i32, DestWidth: i32, DestHeight: i32, xSrc: i32, ySrc: i32, SrcWidth: i32, SrcHeight: i32, lpBits: *const anyopaque, lpbmi: *const BITMAPINFO, iUsage: u32, rop: u32) callconv(.winapi) i32;

pub const Window = struct {
    hwnd: HWND,
    hdc: HDC,

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

        const hwnd = CreateWindowExW(0, class_name, title, WS_OVERLAPPEDWINDOW | WS_VISIBLE, CW_USEDEFAULT, CW_USEDEFAULT, config.WIDTH, config.HEIGHT, null, null, hinstance, null) orelse return error.CreateWindowFailed;
        return .{ .hwnd = hwnd, .hdc = GetDC(hwnd) };
    }

    pub fn deinit(self: Window) void {
        _ = ReleaseDC(self.hwnd, self.hdc);
    }

    pub fn present(self: Window, pixels: *const [config.WIDTH * config.HEIGHT]u32) void {
        var rect: RECT = undefined;
        _ = GetClientRect(self.hwnd, &rect);

        const info = BITMAPINFO{
            .bmiHeader = .{
                .biSize = @sizeOf(BITMAPINFOHEADER),
                .biWidth = config.WIDTH,
                .biHeight = -config.HEIGHT,
                .biPlanes = 1,
                .biBitCount = 32,
                .biCompression = BI_RGB,
                .biSizeImage = 0,
                .biXPelsPerMeter = 0,
                .biYPelsPerMeter = 0,
                .biClrUsed = 0,
                .biClrImportant = 0,
            },
            .bmiColors = .{.{ .rgbBlue = 0, .rgbGreen = 0, .rgbRed = 0, .rgbReserved = 0 }},
        };

        _ = StretchDIBits(
            self.hdc,
            0,
            0,
            rect.right - rect.left,
            rect.bottom - rect.top,
            0,
            0,
            config.WIDTH,
            config.HEIGHT,
            pixels,
            &info,
            DIB_RGB_COLORS,
            SRCCOPY,
        );
    }
};

pub fn pumpMessages() bool {
    var should_run = true;
    var msg: MSG = undefined;
    while (PeekMessageW(&msg, null, 0, 0, PM_REMOVE) != 0) {
        if (msg.message == WM_QUIT) should_run = false;
        _ = TranslateMessage(&msg);
        _ = DispatchMessageW(&msg);
    }
    return should_run;
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

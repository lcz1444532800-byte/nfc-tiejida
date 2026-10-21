"""Generates the app's layered icon (foreground/background PNGs) and store icons.
Pure Python (zlib only). Usage: python -I make_icons.py <out_dir>"""
import math, struct, sys, zlib, os

def png(path, w, h, px):  # px: bytearray RGBA
    raw = b''.join(b'\x00' + bytes(px[y * w * 4:(y + 1) * w * 4]) for y in range(h))
    def chunk(t, d): return struct.pack('>I', len(d)) + t + d + struct.pack('>I', zlib.crc32(t + d) & 0xffffffff)
    with open(path, 'wb') as f:
        f.write(b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>IIBBBBB', w, h, 8, 6, 0, 0, 0))
                + chunk(b'IDAT', zlib.compress(raw, 9)) + chunk(b'IEND', b''))

# The original app mark: a white stroked "N" on solid blue (#1F4E8C), as in the first
# build's app_icon.svg (path M40 92 V36 l48 56 V36 on a 128 grid, stroke 12, round joins).
# Scaled to 1024 and shrunk ~0.8x about the centre to stay inside the layered-icon safe zone.
BG_TOP = BG_BOTTOM = (0x1F, 0x4E, 0x8C)
_K = 8.0 * 0.8
_P = [(512 + (x - 64) * _K, 512 + (y - 64) * _K) for x, y in ((40, 92), (40, 36), (88, 92), (88, 36))]
HALF = 12 * _K / 2

def _seg_dist(x, y, a, b):
    (ax, ay), (bx, by) = a, b
    vx, vy = bx - ax, by - ay
    t = max(0.0, min(1.0, ((x - ax) * vx + (y - ay) * vy) / (vx * vx + vy * vy)))
    return math.hypot(x - ax - t * vx, y - ay - t * vy)

def fg_coverage(x, y):
    return 1.0 if min(_seg_dist(x, y, _P[i], _P[i + 1]) for i in range(3)) <= HALF else 0.0

def render(size, kind):
    s = 1024.0 / size
    px = bytearray(size * size * 4)
    sub = (0.25, 0.75)
    for j in range(size):
        t = j / (size - 1)
        bg = tuple(round(BG_TOP[k] + (BG_BOTTOM[k] - BG_TOP[k]) * t) for k in range(3))
        for i in range(size):
            o = (j * size + i) * 4
            if kind == 'background':
                px[o:o + 4] = bytes((*bg, 255)); continue
            cov = sum(fg_coverage((i + a) * s, (j + b) * s) for a in sub for b in sub) / 4.0
            if kind == 'foreground':
                px[o:o + 4] = bytes((255, 255, 255, round(255 * cov)))
            else:  # flat composite for the start window and the store listing
                col = tuple(round(bg[k] + (255 - bg[k]) * cov) for k in range(3))
                px[o:o + 4] = bytes((*col, 255))
    return px

if __name__ == '__main__':
    out = sys.argv[1]
    os.makedirs(out, exist_ok=True)
    for name, size, kind in (('foreground.png', 1024, 'foreground'), ('background.png', 1024, 'background'),
                             ('startIcon.png', 512, 'flat'), ('store_icon_216.png', 216, 'flat')):
        png(os.path.join(out, name), size, size, render(size, kind))
        print('wrote', name)

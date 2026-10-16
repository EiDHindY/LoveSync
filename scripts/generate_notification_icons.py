import os
import math
from PIL import Image, ImageDraw

SIZE = 512
OUTPUT_SIZE = 192

def create_base_circle(grad_start, grad_end, rim_color):
    im = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    cx, cy = SIZE // 2, SIZE // 2
    radius = SIZE // 2 - 16
    
    for y in range(cy - radius, cy + radius):
        for x in range(cx - radius, cx + radius):
            dx = x - cx
            dy = y - cy
            dist = math.sqrt(dx * dx + dy * dy)
            if dist <= radius:
                diag = (dx + dy) / (2 * radius)
                t = (diag + 1.0) / 2.0
                t = max(0.0, min(1.0, t))
                
                r = int(grad_start[0] * (1 - t) + grad_end[0] * t)
                g = int(grad_start[1] * (1 - t) + grad_end[1] * t)
                b = int(grad_start[2] * (1 - t) + grad_end[2] * t)
                
                alpha = 255
                if dist > radius - 2:
                    alpha = int(255 * (radius - dist) / 2)
                
                im.putpixel((x, y), (r, g, b, alpha))
                
    rim_im = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    rim_draw = ImageDraw.Draw(rim_im)
    rim_draw.ellipse([cx - radius + 3, cy - radius + 3, cx + radius - 3, cy + radius - 3], 
                     outline=(rim_color[0], rim_color[1], rim_color[2], 120), width=6)
    
    rim_draw.arc([cx - radius + 12, cy - radius + 10, cx + radius - 12, cy + radius - 10], 
                 start=200, end=340, fill=(255, 255, 255, 90), width=8)
    
    im = Image.alpha_composite(im, rim_im)
    return im

def draw_heart(draw, cx, cy, w, h, fill, outline=None, outline_w=2):
    points = []
    steps = 100
    for i in range(steps):
        t = i * 2 * math.pi / steps
        x = 16 * (math.sin(t) ** 3)
        y = -(13 * math.cos(t) - 5 * math.cos(2*t) - 2 * math.cos(3*t) - math.cos(4*t))
        
        px = cx + (x / 16) * (w / 2)
        py = cy + (y / 16) * (h / 2)
        points.append((px, py))
    draw.polygon(points, fill=fill, outline=outline, width=outline_w)

def generate_spark_match():
    im = create_base_circle((139, 0, 41), (255, 30, 86), (255, 180, 200))
    layer = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    cx, cy = 256, 266
    
    draw_heart(draw, cx, cy + 10, 190, 180, fill=(255, 220, 50, 230))
    draw_heart(draw, cx, cy + 18, 140, 135, fill=(255, 255, 255, 255))
    
    flame_pts = [
        (cx - 50, cy - 20), (cx - 30, cy - 100), (cx - 10, cy - 60),
        (cx + 5, cy - 120), (cx + 25, cy - 70), (cx + 45, cy - 100),
        (cx + 50, cy - 20)
    ]
    draw.polygon(flame_pts, fill=(255, 200, 30, 220))
    
    inner_flame = [
        (cx - 25, cy - 20), (cx, cy - 90), (cx + 25, cy - 20)
    ]
    draw.polygon(inner_flame, fill=(255, 255, 255, 250))
    
    sparkle_coords = [(140, 180), (370, 170), (160, 340), (350, 330), (256, 120)]
    for sx, sy in sparkle_coords:
        draw.ellipse([sx-6, sy-6, sx+6, sy+6], fill=(255, 255, 255, 240))
        draw.line([sx-14, sy, sx+14, sy], fill=(255, 255, 255, 200), width=3)
        draw.line([sx, sy-14, sx, sy+14], fill=(255, 255, 255, 200), width=3)
        
    im = Image.alpha_composite(im, layer)
    return im

def generate_date_proposal():
    im = create_base_circle((74, 14, 46), (194, 24, 91), (255, 200, 220))
    layer = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    cx, cy = 256, 265
    
    env_w, env_h = 240, 160
    left, top = cx - env_w // 2, cy - env_h // 2
    right, bottom = cx + env_w // 2, cy + env_h // 2
    
    draw.rounded_rectangle([left+4, top+8, right+4, bottom+8], radius=16, fill=(30, 0, 20, 100))
    draw.rounded_rectangle([left, top, right, bottom], radius=16, fill=(255, 248, 240, 255), outline=(230, 200, 180, 255), width=4)
    
    draw.line([(left, top), (cx, cy + 25), (right, top)], fill=(210, 180, 160, 255), width=5)
    draw.line([(left, bottom), (cx - 40, cy + 10)], fill=(225, 195, 175, 255), width=4)
    draw.line([(right, bottom), (cx + 40, cy + 10)], fill=(225, 195, 175, 255), width=4)
    
    seal_r = 38
    draw.ellipse([cx - seal_r, cy + 20 - seal_r, cx + seal_r, cy + 20 + seal_r], fill=(212, 38, 78, 255), outline=(255, 215, 0, 255), width=4)
    draw_heart(draw, cx, cy + 20, 36, 34, fill=(255, 215, 0, 255))
    
    draw.ellipse([140, 150, 152, 162], fill=(255, 235, 150, 250))
    draw.line([134, 156, 158, 156], fill=(255, 235, 150, 250), width=3)
    draw.line([146, 144, 146, 168], fill=(255, 235, 150, 250), width=3)
    
    draw.ellipse([360, 140, 372, 152], fill=(255, 235, 150, 250))
    draw.line([354, 146, 378, 146], fill=(255, 235, 150, 250), width=3)
    draw.line([366, 134, 366, 158], fill=(255, 235, 150, 250), width=3)

    im = Image.alpha_composite(im, layer)
    return im

def generate_date_accepted():
    im = create_base_circle((59, 7, 32), (225, 29, 72), (255, 210, 160))
    layer = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    cx, cy = 256, 256
    
    left_glass = [
        (cx - 70, cy - 90), (cx - 20, cy - 70), (cx - 40, cy + 20),
        (cx - 55, cy + 20)
    ]
    draw.polygon(left_glass, fill=(255, 255, 255, 160), outline=(255, 255, 255, 255), width=4)
    draw.polygon([(cx - 65, cy - 60), (cx - 25, cy - 45), (cx - 42, cy + 16), (cx - 52, cy + 16)], fill=(255, 215, 0, 220))
    draw.line([(cx - 48, cy + 20), (cx - 65, cy + 100)], fill=(255, 255, 255, 240), width=5)
    draw.line([(cx - 85, cy + 96), (cx - 45, cy + 104)], fill=(255, 255, 255, 240), width=6)
    
    right_glass = [
        (cx + 20, cy - 70), (cx + 70, cy - 90), (cx + 55, cy + 20),
        (cx + 40, cy + 20)
    ]
    draw.polygon(right_glass, fill=(255, 255, 255, 160), outline=(255, 255, 255, 255), width=4)
    draw.polygon([(cx + 25, cy - 45), (cx + 65, cy - 60), (cx + 52, cy + 16), (cx + 42, cy + 16)], fill=(255, 215, 0, 220))
    draw.line([(cx + 48, cy + 20), (cx + 65, cy + 100)], fill=(255, 255, 255, 240), width=5)
    draw.line([(cx + 45, cy + 104), (cx + 85, cy + 96)], fill=(255, 255, 255, 240), width=6)
    
    draw.ellipse([cx - 10, cy - 80, cx + 10, cy - 60], fill=(255, 255, 255, 255))
    draw.line([cx - 30, cy - 70, cx + 30, cy - 70], fill=(255, 255, 255, 255), width=5)
    draw.line([cx, cy - 100, cx, cy - 40], fill=(255, 255, 255, 255), width=5)
    
    for bx, by in [(cx, cy - 120), (cx - 15, cy - 110), (cx + 18, cy - 115), (cx - 8, cy - 40)]:
        draw.ellipse([bx - 6, by - 6, bx + 6, by + 6], fill=(255, 235, 120, 230))
        
    im = Image.alpha_composite(im, layer)
    return im

def generate_date_nudge():
    im = create_base_circle((76, 29, 149), (219, 39, 119), (251, 207, 232))
    layer = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    cx, cy = 256, 256
    
    clock_r = 110
    draw.ellipse([cx - clock_r - 6, cy - clock_r - 6, cx + clock_r + 6, cy + clock_r + 6], 
                 fill=(40, 10, 80, 200), outline=(255, 215, 0, 255), width=8)
    draw.ellipse([cx - clock_r, cy - clock_r, cx + clock_r, cy + clock_r], 
                 fill=(255, 250, 245, 240), outline=(255, 180, 50, 255), width=4)
                 
    draw.rectangle([cx - 16, cy - clock_r - 28, cx + 16, cy - clock_r - 4], fill=(255, 215, 0, 255))
    draw.arc([cx - 26, cy - clock_r - 54, cx + 26, cy - clock_r - 14], start=180, end=360, fill=(255, 215, 0, 255), width=6)
    
    for angle in range(0, 360, 30):
        rad = math.radians(angle)
        x1 = cx + (clock_r - 16) * math.cos(rad)
        y1 = cy + (clock_r - 16) * math.sin(rad)
        x2 = cx + (clock_r - 6) * math.cos(rad)
        y2 = cy + (clock_r - 6) * math.sin(rad)
        draw.line([(x1, y1), (x2, y2)], fill=(120, 30, 80, 240), width=4 if angle % 90 == 0 else 2)
        
    rad_h = math.radians(180)
    draw.line([(cx, cy), (cx + 50 * math.cos(rad_h), cy + 50 * math.sin(rad_h))], fill=(190, 20, 60, 255), width=6)
    rad_m = math.radians(270)
    draw.line([(cx, cy), (cx + 75 * math.cos(rad_m), cy + 75 * math.sin(rad_m))], fill=(190, 20, 60, 255), width=4)
    
    draw_heart(draw, cx, cy, 26, 24, fill=(255, 20, 80, 255))
    
    im = Image.alpha_composite(im, layer)
    return im

def generate_canceled():
    im = create_base_circle((51, 65, 85), (100, 116, 139), (200, 210, 230))
    layer = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    cx, cy = 256, 256
    
    for r in [130, 95, 60]:
        draw.ellipse([cx - r, cy - r, cx + r, cy + r], outline=(255, 255, 255, 45), width=3)
        
    leaf_pts = [
        (cx - 70, cy + 40),
        (cx - 40, cy - 30),
        (cx + 30, cy - 70),
        (cx + 70, cy - 75),
        (cx + 50, cy - 20),
        (cx + 20, cy + 40),
        (cx - 30, cy + 60),
    ]
    draw.polygon(leaf_pts, fill=(251, 191, 36, 230), outline=(245, 158, 11, 255), width=4)
    draw.line([(cx - 70, cy + 40), (cx + 70, cy - 75)], fill=(217, 119, 6, 240), width=3)
    
    for dx, dy in [(cx - 20, cy - 80), (cx + 80, cy + 10), (cx - 60, cy - 10)]:
        draw.ellipse([dx - 5, dy - 5, dx + 5, dy + 5], fill=(224, 231, 255, 200))
        
    im = Image.alpha_composite(im, layer)
    return im

def generate_partner_connected():
    im = create_base_circle((88, 28, 135), (190, 24, 93), (255, 180, 220))
    layer = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    cx, cy = 256, 256
    
    draw.ellipse([cx - 120, cy - 65, cx - 10, cy + 45], outline=(255, 215, 0, 255), width=14)
    draw.ellipse([cx + 10, cy - 65, cx + 120, cy + 45], outline=(255, 215, 0, 255), width=14)
    
    draw_heart(draw, cx, cy + 15, 120, 115, fill=(255, 30, 86, 255), outline=(255, 255, 255, 255), outline_w=5)
    draw_heart(draw, cx, cy + 18, 70, 68, fill=(255, 220, 230, 255))
    
    for sx, sy in [(cx - 90, cy - 75), (cx + 90, cy - 75), (cx, cy + 95)]:
        draw.ellipse([sx - 6, sy - 6, sx + 6, sy + 6], fill=(255, 255, 255, 250))
        draw.line([sx - 12, sy, sx + 12, sy], fill=(255, 255, 255, 220), width=3)
        draw.line([sx, sy - 12, sx, sy + 12], fill=(255, 255, 255, 220), width=3)

    im = Image.alpha_composite(im, layer)
    return im

def generate_default():
    im = create_base_circle((107, 17, 59), (255, 30, 86), (255, 200, 220))
    layer = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    cx, cy = 256, 256
    draw_heart(draw, cx, cy + 5, 220, 210, fill=(255, 255, 255, 255), outline=(255, 200, 220, 255), outline_w=6)
    draw_heart(draw, cx, cy + 12, 160, 150, fill=(225, 29, 72, 255))
    draw_heart(draw, cx, cy + 18, 90, 85, fill=(255, 220, 230, 255))
    
    im = Image.alpha_composite(im, layer)
    return im

generators = {
    "notif_spark_match": generate_spark_match,
    "notif_date_proposal": generate_date_proposal,
    "notif_date_accepted": generate_date_accepted,
    "notif_date_nudge": generate_date_nudge,
    "notif_canceled": generate_canceled,
    "notif_partner_connected": generate_partner_connected,
    "notif_default": generate_default,
}

os.makedirs("android/app/src/main/res/drawable", exist_ok=True)
os.makedirs("assets/images/notifications", exist_ok=True)

for name, gen in generators.items():
    img_512 = gen()
    img_192 = img_512.resize((OUTPUT_SIZE, OUTPUT_SIZE), Image.Resampling.LANCZOS)
    
    drawable_path = f"android/app/src/main/res/drawable/{name}.png"
    img_192.save(drawable_path, format="PNG")
    
    asset_path = f"assets/images/notifications/{name}.png"
    img_192.save(asset_path, format="PNG")
    
    print(f"Generated {name} -> {drawable_path} and {asset_path}")

print("All notification icons successfully generated!")

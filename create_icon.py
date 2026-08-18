from PIL import Image, ImageDraw, ImageFont
import os

# Create a 1024x1024 image with white background
size = 1024
img = Image.new('RGB', (size, size), color='white')
draw = ImageDraw.draw(img)

# Draw a blue background
draw.rectangle([0, 0, size, size], fill='#2196F3')

# Draw barcode lines (simplified barcode pattern)
barcode_height = 500
barcode_top = (size - barcode_height) // 2
bar_width = 30
spacing = 20

# Generate barcode pattern
bars = [1, 0, 1, 1, 0, 1, 0, 1, 1, 0, 0, 1, 0, 1, 1, 0, 1, 0, 1, 1, 0, 1, 0]
x = 150

for bar in bars:
    if bar == 1:
        draw.rectangle(
            [x, barcode_top, x + bar_width, barcode_top + barcode_height],
            fill='white'
        )
    x += bar_width + spacing

# Save the icon
output_path = os.path.join('assets', 'icon.png')
img.save(output_path, 'PNG')
print(f"Icon created at: {output_path}")

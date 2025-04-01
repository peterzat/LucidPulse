#!/usr/bin/env python3
import os
from PIL import Image
import argparse

# Define all required sizes for watchOS app icons
ICON_SIZES = {
    # App Store
    'AppStore': [(1024, 1024)],
    
    # Quick Look
    'QuickLook': [
        (108, 108),  # 49mm
        (97, 97),    # 45mm
        (94, 94),    # 44mm
        (86, 86),    # 41mm
        (80, 80),    # 38mm
    ],
    
    # App Launcher
    'AppLauncher': [
        (100, 100),  # 49mm
        (92, 92),    # 45mm
        (88, 88),    # 44mm
    ],
    
    # Notification Center
    'NotificationCenter': [
        (66, 66),    # 45mm
        (58, 58),    # 41mm
    ],
    
    # Companion Settings
    'CompanionSettings': [
        (87, 87),    # @3x
    ],

    # Additional Sizes
    'Additional': [
        (48, 48),
        (55, 55),
        (66, 66),
        (58, 58),
        (87, 87),
        (80, 80),
        (88, 88),
        (92, 92),
        (100, 100),
        (102, 102),
        (108, 108),
        (172, 172),
        (196, 196),
        (216, 216),
        (234, 234),
        (258, 258),
    ]
}

def generate_icons(source_path, output_dir):
    """
    Generate all required watchOS app icon sizes from a source image.
    
    Args:
        source_path (str): Path to the source 1024x1024 PNG image
        output_dir (str): Directory to save the generated icons
    """
    # Create output directory if it doesn't exist
    os.makedirs(output_dir, exist_ok=True)
    
    # Open and validate source image
    try:
        source = Image.open(source_path)
        if source.size != (1024, 1024):
            raise ValueError(f"Source image must be 1024x1024 pixels, got {source.size}")
        if source.mode != 'RGBA':
            source = source.convert('RGBA')
    except Exception as e:
        print(f"Error opening source image: {e}")
        return
    
    # Get the base filename without extension
    base_name = os.path.splitext(os.path.basename(source_path))[0]
    
    # Generate icons for each size
    for category, sizes in ICON_SIZES.items():
        for width, height in sizes:
            # Create output filename with size suffix
            output_filename = f"{base_name}-{width}x{height}.png"
            output_path = os.path.join(output_dir, output_filename)
            
            try:
                # Resize image with high-quality resampling
                resized = source.resize((width, height), Image.Resampling.LANCZOS)
                resized.save(output_path, 'PNG', optimize=True)
                print(f"Generated: {output_filename}")
            except Exception as e:
                print(f"Error generating {output_filename}: {e}")

def main():
    parser = argparse.ArgumentParser(description='Generate watchOS app icon sizes from a 1024x1024 source image')
    parser.add_argument('source_image', help='Path to the source 1024x1024 PNG image')
    parser.add_argument('--output-dir', default='watch_icons', help='Directory to save the generated icons (default: watch_icons)')
    
    args = parser.parse_args()
    
    if not os.path.exists(args.source_image):
        print(f"Error: Source image '{args.source_image}' does not exist")
        return
    
    generate_icons(args.source_image, args.output_dir)
    print(f"\nAll icons have been generated in: {args.output_dir}")

if __name__ == '__main__':
    main() 
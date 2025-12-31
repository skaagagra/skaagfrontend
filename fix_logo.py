from PIL import Image


def process_logo(input_path, output_path):
    try:
        img = Image.open(input_path)
        img = img.convert("RGBA")
        datas = img.getdata()

        newData = []
        for item in datas:
            # item is (R, G, B, A)
            
            # Detect White Background (make transparent)
            if item[0] > 200 and item[1] > 200 and item[2] > 200:
                newData.append((255, 255, 255, 0))
            
            # Detect Black Text/Checkmark (make white)
            elif item[0] < 50 and item[1] < 50 and item[2] < 50:
                 newData.append((255, 255, 255, 255))
            
            # Else (e.g. Blue Shield), keep as is
            else:
                newData.append(item)

        img.putdata(newData)
        img.save(output_path, "PNG")
        print(f"Successfully saved to {output_path}")
    except Exception as e:
        print(f"Error processing image: {e}")
        # Fallback: Create a dummy transparent image if PIL fails? 
        # No, better to fail and let agent know.

if __name__ == "__main__":
    process_logo("assets/images/logo_full.png", "assets/images/logo_dark_mode.png")

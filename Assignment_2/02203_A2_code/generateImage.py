def generate_pgm():
    width = 352
    height = 288
    max_value = 255
    
    # Open file for writing
    with open('output.pgm', 'w') as f:
        # Write PGM header
        f.write(f'P2\n{width} {height}\n{max_value}\n')
        
        # Generate pixel values
        count = 0
        current_value = 0
        
        for y in range(height):
            for x in range(width):
                f.write(f'{current_value}\n')
                count += 1
                if count == 4:
                    count = 0
                    current_value = (current_value + 1) % 256

if __name__ == '__main__':
    generate_pgm()

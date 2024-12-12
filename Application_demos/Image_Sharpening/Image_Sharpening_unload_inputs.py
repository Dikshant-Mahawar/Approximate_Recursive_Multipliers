import cv2
import numpy as np
from matplotlib import pyplot as plt


def generate_multiplication_inputs(image_data):
    num_of_multiplications = 0

    # 5x5 MASK
    mask = np.array([
        [1,  4,  7,  4, 1],
        [4, 16, 26, 16, 4],
        [7, 26, 41, 26, 7],
        [4, 16, 26, 16, 4],
        [1,  4,  7,  4, 1]
    ])
    
    sharpened_image = np.zeros_like(image_data)
    
    # Padding to handle border pixels
    padded_image = np.pad(image_data, ((2,2), (2,2), (0,0)), mode='edge')
   
   
    multiplication_inputs = []
    
    # Manual convolution
    for i in range(2, padded_image.shape[0] - 2):
        for j in range(2, padded_image.shape[1] - 2):

            # For each color channel
            for c in range(3): 

                # Calculate the weighted sum using the mask
                sum = 0

                for m in range(-2, 3):
                    for n in range(-2, 3):
                        pixel_value = int(padded_image[i + m, j + n, c])

                        mask_value = mask[m + 2, n + 2]
                        
                        sum += pixel_value * mask_value
                        multiplication_inputs.append([pixel_value, mask_value])
                        num_of_multiplications += 1
                
                # Calculate final pixel value using the formula:

                # Y(i,j) = 2 * X(i,j) - (1/273) * sum

                original_pixel = int(padded_image[i, j, c])
                sharpened_value = 2 * original_pixel - (sum // 273)
                
                # Ensure values stay in valid range [0, 255]
                sharpened_image[i-2, j-2, c] = min(255, max(0, sharpened_value))

    print(num_of_multiplications) 
    return multiplication_inputs

    

def main():
    image      = cv2.imread('./Image_to_sharpen__256x248.png')
    image_data = np.array(image)

    multiplication_inputs = generate_multiplication_inputs(image_data)

    with open("./input_to_multiply_Image_Sharpen.dat", "w") as f:
        for input1, input2 in multiplication_inputs:
            f.write(f"{input1} {input2}\n")

    print("Inputs for Verilog multiplier generated successfully!")

if __name__ == "__main__":
  main()
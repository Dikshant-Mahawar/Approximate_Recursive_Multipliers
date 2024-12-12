import cv2
import numpy as np


def generate_multiplication_inputs(image_data):

    kernel = np.array([
        [ 97,  121,  97],
        [121,  151,  121],
        [ 97,  121,  97]
    ])


    multiplication_inputs = []
    num_of_multiplications = 0 
    # MANUAL CONVOLUTION 
    for i in range(1, image_data.shape[0] - 1):
        for j in range(1, image_data.shape[1] - 1):

            for c in range(3):  # For each color channel
                sum = 0

                # MANUAL CONVOLUTION
                for k in range(-1, 2):
                    for l in range(-1, 2):

                        multiplication_inputs.append([ int(image_data[i + k, j + l, c]), kernel[k + 1, l + 1]  ])
                        num_of_multiplications += 1
                        
    print(num_of_multiplications)
    return multiplication_inputs




def main():
    image = cv2.imread("./Lena_Original_Image__512x512-pixels_W640.jpg")
    image_data = np.array(image)

    multiplication_inputs = generate_multiplication_inputs(image_data)

    with open("./input_to_multiply.dat", "w") as f:
        for input1, input2 in multiplication_inputs:
            f.write(f"{input1} {input2}\n")

    print("Inputs for Verilog multiplier generated successfully!")

if __name__ == "__main__":
  main()



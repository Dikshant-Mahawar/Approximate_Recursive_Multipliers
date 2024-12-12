import cv2
import numpy as np

def reconstruct_smoothed_image(image_data, outputs):
    kernel = np.array([
        [ 97,  121,  97],
        [121,  151,  121],
        [ 97,  121,  97]
    ])

    kernel_sum = np.sum(kernel)
    smoothed_image = np.zeros_like(image_data)

    output_line = 0

    # MANUAL CONVOLUTION ; High density Gussian blurring
    for i in range(1, image_data.shape[0] - 1):
        for j in range(1, image_data.shape[1] - 1):

            for c in range(3):  # For each color channel
                sum = 0

                # MANUAL CONVOLUTION
                for _ in range(-1, 2):
                    for __ in range(-1, 2):

                        sum += outputs[output_line] 
                        output_line += 1
                
                smoothed_image[i, j, c] = min(255, max(0, sum // kernel_sum))

    print(output_line)
    return smoothed_image


def main():

    image = cv2.imread("./Lena_Original_Image__512x512-pixels_W640.jpg")

    image_data = np.array(image)

    with open("./data/output_from_multiplier_from_cuda_Reh8.dat", "r") as f:
        print(len(f.readlines())) # This HAS to be 8_619_075 ; 
        # f.readlines() CAN ONLY BE CALLED ONCE IN A FILE OBJECT ; what is the reason ?? 
        # The file pointer will be at the end of the file after one call of f.readlines()

        # Reset file pointer to beginning
        f.seek(0)

        outputs = []
        for line in f.readlines():
            # print(line)
            outputs.append(int(line))
    
    print(len(outputs))
    smoothed_image = reconstruct_smoothed_image(image_data, outputs)
    cv2.imwrite("./output/smoothed_image_Reh8.jpg", smoothed_image)

if __name__ == "__main__":
    main()
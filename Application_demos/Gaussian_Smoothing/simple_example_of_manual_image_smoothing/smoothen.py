import cv2
import numpy as np

image      = cv2.imread('image.jpg')
image_data = np.array(image)

print(image_data)

kernel = np.array([
    [97, 121, 97],
    [121, 151, 121],
    [97, 121, 97]
])

# Create a new image to store the smoothed results
smoothed_image = np.zeros_like(image_data)

# MANUAL CONVOLUTION 
for i in range(1, image_data.shape[0] - 1):
    for j in range(1, image_data.shape[1] - 1):
        sum = 0
        for k in range(-1, 2):
            for l in range(-1, 2):
                sum += image_data[i + k, j + l] * kernel[k + 1, l + 1]
        smoothed_image[i, j] = sum


print(smoothed_image)

 # Assuming grayscale, adjust if needed
smoothed_image_cv = cv2.cvtColor(smoothed_image, cv2.COLOR_GRAY2RGB) 
cv2.imwrite("smoothed_image.jpg", smoothed_image_cv)
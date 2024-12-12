import cv2
import numpy as np
from skimage.metrics import structural_similarity as ssim


# PSNR
def calculate_psnr(img1, img2):
    mse = np.mean((img1 - img2) ** 2)
    if mse == 0:
        return float('inf')
    max_pixel = 255.0
    psnr = 20 * np.log10(max_pixel / np.sqrt(mse))
    return psnr


# SSIM
def calculate_ssim(img1, img2):
    # Convert images to grayscale if they're color ; 
    # In the documentation it was written that :- 
    #  -> use the newer parameter channel_axis to specify which axis contains the color channels
    #  -> Convert the images to grayscale before calculating SSIM

    if len(img1.shape) == 3:
        img1_gray = cv2.cvtColor(img1, cv2.COLOR_BGR2GRAY)
        img2_gray = cv2.cvtColor(img2, cv2.COLOR_BGR2GRAY)
        return ssim(img1_gray, img2_gray)
    else:
        return ssim(img1, img2)

def compare_images(original_path, processed_path):
    img1 = cv2.imread(original_path)
    img2 = cv2.imread(processed_path)
    
    if img1 is None or img2 is None: raise ValueError("Failed to load one or both images")
        
    # Making sure If imaegs have the same dimensions
    if img1.shape != img2.shape:
        raise ValueError(f"Images have different dimensions: {img1.shape} vs {img2.shape}")
    
    # Calculate metrics
    psnr_value = calculate_psnr(img1, img2)
    ssim_value = calculate_ssim(img1, img2)
    
    return psnr_value, ssim_value

try:
    original_path = './Lena_Original_Image__512x512-pixels_W640.jpg'
    processed_path = './output/smoothed_image_N8_5.jpg'
    # processed_path = './output/smoothed_image_N8_6.jpg'
    
    psnr_value, ssim_value = compare_images(original_path, processed_path)
    print(f"PSNR: {psnr_value:.2f} dB")
    print(f"SSIM: {ssim_value:.4f}")
    
except Exception as e:
    print(f"Error: {e}")
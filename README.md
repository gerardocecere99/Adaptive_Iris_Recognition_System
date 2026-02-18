# 👁️ Iris Recognition System (MATLAB)

A complete biometric iris recognition pipeline implemented in MATLAB.
This project explores the challenges of **visible wavelength (VW)** iris recognition versus **near-infrared (NIR)**, performing a comparative analysis between the **UBIRIS.v2** (noisy, visible) and **CASIA-Iris-Interval** (clean, NIR) datasets.

The system implements the classic **Daugman's Algorithm** pipeline, featuring robust segmentation (Hough & Integro-Differential), rubber sheet normalization, Gabor wavelet encoding, and Hamming Distance matching.

## 🗝️ Key Features

* **Dual Segmentation Strategy:**
    * **Circular Hough Transform:** Optimized for robustness against impulsive noise (specular reflections).
    * **Daugman's Integro-Differential Operator:** Implemented with adaptive parameters and inpainting for reflection handling.
* **Adaptive Processing:** Automatically detects image characteristics (Macro vs Distance) to adjust ROI and search parameters dynamically.
* **Feature Extraction:** 2D Gabor Wavelet encoding to generate binary **IrisCodes**.
* **Matching:** Hamming Distance calculation with **Bit-Shifting** to compensate for head tilt/rotation.

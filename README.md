# 👁️ Adaptive Iris Recognition System

## 📌 Project Overview
This project implements an end-to-end adaptive biometric pipeline for **Iris Recognition**, developed in MATLAB. 
The core objective is to analyze and compare the performance of classic iris recognition algorithms (based on John Daugman's principles) across two radically different environmental scenarios:
1.  **Ideal Conditions (NIR):** Near-Infrared illumination, constrained environment (using the *CASIA-Iris-Interval* dataset).
2.  **Unconstrained Conditions (Visible Light):** "On-the-move" acquisition with visible wavelength and smartphone cameras (using the *UBIRIS.v2* dataset), analyzing the challenges highlighted by modern literature (e.g., Trokielewicz et al.).

## Key Features & Pipeline

### 1. Preprocessing & ROI Extraction
* Dynamic Region of Interest (ROI) extraction based on image resolution.
* **Visible Light Compensation:** Extraction of the Red Channel to maximize melanin penetration and reveal hidden stroma textures in dark irises.
* **Specular Reflection Removal:** Implementation of a White Top-Hat Transform followed by Laplace interpolation (`regionfill`) to eliminate corneal glare without introducing false high-frequency edges.
* **Contrast Enhancement & Denoising:** Application of Contrast-Limited Adaptive Histogram Equalization (CLAHE) followed by a non-linear Edge-Preserving Median Filter.

### 2. Geometric Segmentation 
* **Pupil Extraction:** Advanced feature engineering using a Spatial Prior (2D Gaussian Spotlight Mask) combined with Bottom-Hat morphology to suppress peripheral noise (eyelashes/shadows).
* **Iris Boundary Detection:** Implementation of the **Circular Hough Transform (CHT)**, fine-tuned with custom edge-thresholds and high sensitivity to overcome severe occlusions and low-contrast limbic boundaries typical of visible light images.

### 3. Feature Extraction 
* **Normalization:** Daugman's Rubber Sheet Model to unwrap the circular iris into a rectangular 2D array, ensuring scale and pupillary dilation invariance.
* **Encoding:** Application of **2D Gabor Filters** to generate the binary biometric signature.

### 4. Matching & Statistical Analysis
* Calculation of the **Hamming Distance**.
* **Rotational Compensation:** Implementation of a circular bit-shifting algorithm to compensate for head-tilt misalignments.

## 📚 References
* J. Daugman, *"How Iris Recognition Works"* (IEEE Transactions on Circuits and Systems for Video Technology, 2004).
* M. Trokielewicz et al., *"Iris Recognition in Visible Light"* (Biometrics Laboratory, NASK).

## 👨‍💻 Authors
* **Gerardo Antonio Cecere**
* **Veronica Loverre** 

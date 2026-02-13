# Legato
# 🎵 Music Genre Classification App (CNN + Flutter + FastAPI)

![Python](https://img.shields.io/badge/Python-3.8%2B-blue)
![TensorFlow](https://img.shields.io/badge/TensorFlow-2.x-orange)
![FastAPI](https://img.shields.io/badge/FastAPI-0.95-green)
![Flutter](https://img.shields.io/badge/Flutter-3.0-02569B)
![Librosa](https://img.shields.io/badge/Librosa-Audio_Analysis-yellow)

An end-to-end **Deep Learning application** that classifies music genres from raw audio files or real-time microphone recordings. 

The system converts audio into **Mel Spectrograms**, processes them using a custom **Convolutional Neural Network (CNN)**, and serves predictions via a high-performance **FastAPI** backend to a **Flutter** mobile app.

---

## 📸 Screenshots

| Home Screen | Recording | Result Screen |
|:---:|:---:|:---:|
| ![Home](https://via.placeholder.com/200x400?text=Home+Screen) | ![Recording](https://via.placeholder.com/200x400?text=Recording) | ![Result](https://via.placeholder.com/200x400?text=Genre+Result) |
> *(Replace these placeholders with actual screenshots of your app)*

---

## 🚀 Key Features

* **Real-Time Classification:** Record audio directly from the app and get instant results.
* **File Upload Support:** Upload MP3/WAV/M4A files from your device storage.
* **Visual Analysis:** Converts audio to Mel Spectrograms (Visual representation of sound).
* **Smart Preprocessing:** Automatically finds and analyzes the loudest part of the song (the chorus).
* **High Accuracy:** ~85%+ accuracy using a custom CNN architecture trained on the GTZAN dataset.
* **Robust Backend:** Fast, asynchronous API built with Python and FastAPI.

---

## 🛠️ Tech Stack

### **Machine Learning (The Brain)**
* **Language:** Python
* **Libraries:** TensorFlow (Keras), Librosa, NumPy, Scikit-learn, Matplotlib.
* **Techniques:** CNN, Mel Spectrograms, Data Augmentation (Noise Injection), L2 Regularization, Dropout.

### **Backend (The Engine)**
* **Framework:** FastAPI (Python).
* **Server:** Uvicorn (ASGI).
* **Tools:** FFmpeg (for audio decoding/conversion).

### **Frontend (The Interface)**
* **Framework:** Flutter (Dart).
* **Libraries:** `http` (API calls), `file_picker` (Uploads), `audio_waveforms` (Visualizer).

---

## 🧠 Model Architecture

We use a **Custom Sequential CNN** designed specifically for Spectrogram analysis.

1.  **Input:** Mel Spectrogram (128 x 130 x 1).
2.  **Feature Extraction:** * 4x Convolutional Blocks (`Conv2D` + `ReLU`).
    * `MaxPooling2D` for dimension reduction.
    * `BatchNormalization` for training stability.
3.  **Regularization:** * `L2 Regularization` to prevent large weights.
    * `Dropout (0.5)` to prevent overfitting.
4.  **Classification:** * `Flatten` layer.
    * `Dense` (Softmax) Output layer for 10 genres.
5.  **Optimizer:** Adam (`lr=0.0001`).

---

## 📂 Dataset

The model was trained on the **GTZAN Genre Collection**.
* **Total Songs:** 1,000 (30 seconds each).
* **Genres (10):** Blues, Classical, Country, Disco, Hiphop, Jazz, Metal, Pop, Reggae, Rock.
* **Preprocessing:** Sliced into 3-second windows with **50% Overlap** + Noise Augmentation = **~38,000 Training Samples**.

---

## ⚡ Installation & Setup

### 1. Prerequisites
* Python 3.8+
* Flutter SDK
* **FFmpeg** (Must be installed and added to system PATH).

### 2. Clone the Repository
```bash
git clone [https://github.com/your-username/music-genre-classifier.git](https://github.com/your-username/music-genre-classifier.git)
cd music-genre-classifier

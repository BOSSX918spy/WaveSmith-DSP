SpectroForge DSP
SpectroForge DSP is a MATLAB-based real-time digital signal processing project that combines live audio playback with dynamic spectral visualization and filtering capabilities. This project showcases an interactive GUI where users can:

Select an Audio File: Load your own WAV files via an intuitive file dialog.
Real-Time Playback: Enjoy real-time audio playback using MATLAB’s DSP tools.
Live FFT Display: Visualize the frequency spectrum of the incoming audio using a fast Fourier transform (FFT).
Dynamic Spectrogram: Monitor a live power spectrogram that updates continuously to show audio energy over time.
Customizable Filters: Choose between low-pass, band-pass, high-pass, or even set custom band-pass filters on the fly.
Parallel Processing: Offload computationally intensive tasks (FFT and spectrogram updates) to parallel workers, ensuring smooth real-time performance.
Features
Interactive GUI: Easy-to-use controls for playing/pausing audio and switching between different filter modes.
Real-Time DSP: Combines audio playback with real-time spectral analysis and filtering.
Parallel Computing: Utilizes MATLAB’s parallel processing features to maintain performance during intensive FFT computations.
Custom Filter Design: Adjust filter parameters to experiment with different frequency responses and effects.
Getting Started
Requirements:

MATLAB with DSP System Toolbox.
Parallel Computing Toolbox (for offloading FFT and spectrogram tasks).
A compatible audio file (preferably in WAV format).
Installation:

Clone the repository:
bash
Copy
Edit
git clone https://github.com/yourusername/SpectroForge-DSP.git
Open the liveFFTwithFiltersDSP.m script in MATLAB.
Usage:

Run the script in MATLAB.
Use the GUI to select an audio file and experiment with real-time filtering and spectral analysis.
Contributing
Contributions are welcome! If you have suggestions or improvements, feel free to open an issue or submit a pull request.

License
This project is licensed under the MIT License. See the LICENSE file for details.

SpectroForge DSP is designed for researchers, educators, and audio enthusiasts looking to explore real-time audio processing and visualization in MATLAB. Enjoy experimenting with sound in a whole new dimension!

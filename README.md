# WaveSmith DSP

**WaveSmith DSP** is a MATLAB-based real-time digital signal processing project that combines live audio playback with dynamic spectral visualization and filtering capabilities. Designed for audio engineers, researchers, educators, and enthusiasts, this interactive tool lets you explore sound in real time.

## Features

- **Audio File Selection:** Load your own WAV files using an intuitive file dialog.
- **Real-Time Playback:** Control audio with simple Play and Pause buttons.
- **Live FFT Display:** Visualize the frequency spectrum of your audio via fast Fourier transform (FFT) analysis.
- **Dynamic Spectrogram:** View a continuously updating spectrogram that displays power distribution across frequencies over time.
- **Customizable Filters:** Choose from low-pass, band-pass, high-pass, or set custom band-pass filters on the fly.
- **Parallel Processing:** Offload computationally intensive tasks (FFT and spectrogram updates) to parallel workers for smooth performance.

## Getting Started

### Requirements
- MATLAB with the DSP System Toolbox.
- MATLAB Parallel Computing Toolbox (optional- only needed for parpool code).
- Audio Toolkit
- A compatible audio file (preferably in WAV format).

### Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/BOSSX918spy/WaveSmith-DSP.git
This project is licensed under the MIT License. See the LICENSE file for details.

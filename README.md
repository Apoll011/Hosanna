# Hosanna - Music Repertory and Service Planner

Hosanna is a full-featured, responsive web application designed for church worship bands, music directors, and musicians. It facilitates chord sheet management, real-time transposition, setlist scheduling, and collaborative synchronization across devices.

## Core Features

### 1. Song Browser and ChordPro Parser
- Full support for ChordPro formatting, enabling structured lyric-chord relationship rendering.
- Dynamic transposition engine with instant pitch adjustments.
- Interactive fretboard guitar and piano keyboard chord diagram visualizers.
- Advanced organization including categorization by folders, custom tags, speed metrics (BPM), and favoriting options.

### 2. Service Setlist Planner
- Comprehensive scheduling interface for managing church services and sessions.
- Dynamic drag-and-drop song sorting within setlists.
- Band-specific arrangement annotations per song.
- PDF export capability:
   - Concise Service Outline format (one-page quick-reference sheet).
   - Complete Songbook format (including fully transposed chords and lyrics).
   - Automatic integration of the high-resolution application branding logo.

### 3. Integrated Metronome
- Precise tempo controller with tap-tempo capability.
- Visual pulse feedback paired with audio indication.
- Time signature configuration (2/4, 3/4, 4/4, 6/8).

### 4. Circle of Fifths Reference
- Interactive harmonic key visualizer.
- Seamless identification of relative keys, dominant/subdominant relationships, and accidental counts.

### 5. Multi-Source Synchronizer
- Bi-directional transactional synchronization engine.
- Instant cloud-database sync alongside automatic fallback local caches.
- Dynamic status tracking directly integrated into the main navigation controls.

### 6. User Interface and Navigation
- Responsive layout adhering to modern Design Systems.
- Immersive high-contrast dark and light modes.
- Floating iOS-style bottom pill navigation bar providing fluid transitions and micro-animations.

## Technical Architecture

The application is built on a modern frontend stack designed for performance, modularity, and offline capability:

- **Framework:** React 18 with TypeScript.
- **Build Tooling:** Vite for high-speed compilation and optimized dependency bundling.
- **Styling:** Tailwind CSS utility class architecture.
- **Animations:** Motion (motion/react) for layout transitions and modal popovers.
- **State Management:** Zustand-based decentralized store architecture (`appStore.ts`).
- **Icons:** Lucide React vector icon system.
- **Document Generation:** jsPDF for programmatic server-less PDF compilation.

## Development Workflow

### Prerequisites
- Node.js (v18.0.0 or higher)
- npm or yarn package manager

### Installation
1. Install dependencies:
   ```bash
   npm install
   ```

2. Run the local development server:
   ```bash
   npm run dev
   ```

3. Build the production package:
   ```bash
   npm run build
   ```

4. Run the production build locally:
   ```bash
   npm run start
   ```

## License
This project is proprietary and confidential. Authorized usage is restricted to designated worship team environments.

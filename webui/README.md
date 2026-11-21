# Fleet Route Optimizer

React-based web interface for the Fleet Route Optimizer [CVRPTW] - solving Capacitated Vehicle Routing Problem with Time Windows using real-world routing data.

## Features

- 📁 Load JSON problem files with customer data
- 🚀 Solve optimization problems via API (OR-Tools & Gurobi)
- 📊 View comprehensive solution statistics and metrics
- 🗺️ Interactive route visualization on Leaflet map
- 📦 Detailed route information with time windows and loads
- 🚚 Vehicle utilization and saturation metrics
- ⏱️ Real-time log streaming during optimization
- 🌍 Real-world distances using OSRM routing
- 🚦 Traffic-aware time windows (morning/afternoon/evening)

## Setup

1. Install dependencies:
```bash
npm install
```

2. Make sure the backend API is running on `http://localhost:8000`

3. Start the development server:
```bash
npm start
```

The app will open at `http://localhost:3000`

## Usage

1. **Load JSON File**: Click "Load JSON File" and select a problem file from the `inputs/` folder
2. **Solve**: Click the "Solve" button to send the problem to the backend
3. **View Results**: Examine the solution summary and individual routes
4. **View Map**: Click on any route card to see the interactive map with the complete route

## Project Structure

```
webui/
├── public/
│   └── index.html
├── src/
│   ├── components/
│   │   ├── FileUpload.js       # File upload component
│   │   ├── SolutionSummary.js  # Overall solution stats
│   │   ├── RoutesList.js       # List of all routes
│   │   └── RouteMap.js         # Interactive map view
│   ├── App.js                  # Main application
│   ├── App.css                 # Main styles
│   └── index.js                # Entry point
└── package.json
```

## Technologies

- **React 18**: UI framework
- **Leaflet**: Interactive maps
- **React-Leaflet**: React bindings for Leaflet
- **Axios**: HTTP client
- **OpenStreetMap**: Map tiles

## Build for Production

```bash
npm run build
```

This creates an optimized production build in the `build/` directory.

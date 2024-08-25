#!/bin/bash

#thanks to jay kumar gupta on hashnode

# Create a new Vite project with React template
npm create vite@latest "$1" -- --template react

cd "$1"

npm install -D tailwindcss postcss autoprefixer

# Initialize Tailwind CSS
npx tailwindcss init -p

# Update the Tailwind CSS configuration file
cat << EOF > tailwind.config.js
/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {},
  },
  plugins: [],
}
EOF

# Update the index.css file
cat << EOF > src/index.css
@tailwind base;
@tailwind components;
@tailwind utilities;
EOF


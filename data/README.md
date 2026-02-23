# LunrQuery Sample Data

This directory contains sample data for the sample app demonstrating LunrQuery with astronaut data.

## Setup

### 1. Install Node.js Dependencies

```bash
cd data
npm install
```

### 2. Build the Search Index

```bash
npm run build
```

This creates `astronauts_index.json` using Lunr.js.

### 3. Run the Sample App

From the DragonRuby root directory:

```bash
./dragonruby dr-lunr_query
```

## What It Does

The sample app demonstrates:

- Loading a pre-built Lunr.js index
- Performing various searches:
  - Simple term search: `apollo`
  - Field-scoped search: `name:armstrong`
  - Required terms: `+apollo +moon`
  - Prohibited terms: `apollo -13`
- Displaying scored results

## Index Structure

The astronaut index has three fields:

- `name` (boost: 10) - Astronaut name
- `bio` - Biography text
- `missions` (boost: 5) - Space missions

Field boosts make matches in `name` and `missions` rank higher than `bio` matches.

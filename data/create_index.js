// Node.js script to create Lunr.js index for astronaut data
// Run with: cd data && npm install && npm run build

const lunr = require('lunr');
const fs = require('fs');
const path = require('path');

// Load astronaut metadata from JSON
const astronautData = JSON.parse(
  fs.readFileSync(path.join(__dirname, 'astronauts.json'), 'utf8')
);

// Load biographies from text files
const astronauts = astronautData.map(astronaut => {
  const bioPath = path.join(__dirname, 'biographies', `${astronaut.id}.txt`);
  let bio = '';

  try {
    bio = fs.readFileSync(bioPath, 'utf8').trim();
    console.log(`Loaded biography for ${astronaut.name} (${bio.length} characters)`);
  } catch (err) {
    console.warn(`Warning: Could not load biography for ${astronaut.name}: ${err.message}`);
    bio = `Biography for ${astronaut.name} not available.`;
  }

  return {
    id: astronaut.id,
    name: astronaut.name,
    bio: bio,
    missions: astronaut.missions
  };
});

// Create index with stemmer and stop word filter
console.log('\nCreating Lunr.js index...');
const idx = lunr(function() {
  // Note: stemmer is already in the default pipeline
  // Add stop word filter to pipeline
  this.pipeline.add(lunr.stopWordFilter);

  // Include position metadata in serialized index
  this.metadataWhitelist = ['position'];

  // Configure fields
  this.ref('id');
  this.field('name', { boost: 10 });
  this.field('bio');
  this.field('missions', { boost: 5 });

  // Add documents
  astronauts.forEach(doc => this.add(doc));
});

// Serialize and save
console.log('Serializing index...');
const serialized = JSON.stringify(idx);
const outputPath = path.join(__dirname, 'astronauts_index.json');
fs.writeFileSync(outputPath, serialized);

console.log('\n' + '='.repeat(60));
console.log('Index created successfully!');
console.log('='.repeat(60));
console.log(`Output: ${outputPath}`);
console.log(`Indexed: ${astronauts.length} astronauts`);
console.log(`Fields: name (boost: 10), bio, missions (boost: 5)`);
console.log(`Pipeline: stemmer, stopWordFilter`);
console.log(`Index size: ${(serialized.length / 1024).toFixed(2)} KB`);
console.log('='.repeat(60));

const fs = require('fs');
const path = require('path');

const dbPath = path.join(__dirname, 'db.json');
try {
  if (fs.existsSync(dbPath)) {
    const raw = fs.readFileSync(dbPath, 'utf8');
    const data = JSON.parse(raw);
    let trimmed = 0;
    
    if (data.orders) {
      data.orders.forEach(order => {
        ['material_image', 'design_image', 'completed_image'].forEach(key => {
          if (order[key] && order[key].length > 500000) { // If base64 string > 500KB
            console.log(`Trimming ${key} for order ${order.order_id} (Length: ${order[key].length})`);
            // We can't really "compress" a base64 string easily here, but we can clear it or leave it.
            // Let's just clear it if it's over 3MB to prevent crashing the app.
            if (order[key].length > 3000000) { // 3MB limit
                console.log(`-> Removed completely because it is too large.`);
                delete order[key];
                trimmed++;
            }
          }
        });
      });
    }

    if (trimmed > 0) {
      fs.writeFileSync(dbPath, JSON.stringify(data, null, 2));
      console.log(`Database trimmed successfully. Modified ${trimmed} huge images.`);
    } else {
      console.log('No huge images found.');
    }
  }
} catch (e) {
  console.error('Error trimming DB:', e);
}

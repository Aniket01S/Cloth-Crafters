const http = require('http');
const url = require('url');

const fs = require('fs');
const pathModule = require('path');
const dbFilePath = pathModule.join(__dirname, 'db.json');

const defaultUsers = [
  { email: 'tailor1@test.com', password: 'password123', username: 'Shyam Tailor', user_type: 'Tailor', address: 'Saket Nagar', phone_number: '9999999991' },
  { email: 'tailor2@test.com', password: 'password123', username: 'Rohan Tailor', user_type: 'Tailor', address: 'LIG', phone_number: '9999999992' },
  { email: 'boutique1@test.com', password: 'password123', username: 'RadhaRani Boutique', user_type: 'Boutique', address: 'Saket Nagar', phone_number: '9999999993' },
  { email: 'user@test.com', password: 'password123', username: 'Demo User', user_type: 'User', address: 'Demo Addr', phone_number: '9999999994' },
  { email: 'boutique@gmail.com', password: '11111111', username: 'Boutique User', user_type: 'Boutique', address: 'Main Market', phone_number: '9876543210' },
  { email: 'test@gmail.com', password: '12345678', username: 'Test User', user_type: 'User', address: 'Main City', phone_number: '9876543211' },
  { email: 'aayush@gmail.com', password: '12345678', username: 'Aayush', user_type: 'User', address: 'Main City', phone_number: '9876543212' }
];

const defaultReviews = [
  { id: 'R1', boutique_email: 'boutique@gmail.com', customer_email: 'user@test.com', customer_name: 'Demo User', rating: 5, comment: 'Excellent tailoring! Perfect fit for my dress.', timestamp: 'Yesterday' },
  { id: 'R2', boutique_email: 'boutique@gmail.com', customer_email: 'test@gmail.com', customer_name: 'Test User', rating: 4, comment: 'Great quality stitching and delivered on time.', timestamp: '2 days ago' },
  { id: 'R3', boutique_email: 'boutique1@test.com', customer_email: 'aayush@gmail.com', customer_name: 'Aayush', rating: 5, comment: 'RadhaRani Boutique has the best designs in town!', timestamp: '3 days ago' },
  { id: 'R4', boutique_email: 'bhopal@gmail.com', customer_email: 'user@test.com', customer_name: 'Demo User', rating: 5, comment: 'Amazing work on my traditional outfit!', timestamp: '1 week ago' }
];

const defaultNotifications = [
  {
    id: 'N1',
    recipient_email: 'test@gmail.com',
    title: 'Order Status Update',
    message: 'Your order #ORD1000 is 100% Completed! Please leave a review.',
    type: 'order',
    read: false,
    timestamp: 'Today, 2:30 PM'
  },
  {
    id: 'N2',
    recipient_email: 'boutique@gmail.com',
    title: 'New Review Received',
    message: 'test@gmail.com gave your boutique a 4 star rating!',
    type: 'review',
    read: false,
    timestamp: 'Today, 3:15 PM'
  },
  {
    id: 'N3',
    recipient_email: 'tailor1@test.com',
    title: 'New Job Vacancy in Indore',
    message: 'A new vacancy was posted by RadhaRani Boutique in Saket Nagar, Indore.',
    type: 'job',
    read: false,
    timestamp: 'Yesterday, 10:00 AM'
  }
];

let db = {
  users: [...defaultUsers],
  vacancies: [
    {
      Vacancy_id: 'V101',
      address: '123 Fashion Street, Mumbai',
      working_hours: '9 AM - 6 PM',
      salary_offered: '25000',
      phone_number: '9876543210',
      email: 'boutique@example.com'
    }
  ],
  applications: [],
  measurements: {},
  alterRequests: {},
  customizeRequests: {},
  cartItems: {},
  orders: [],
  chats: {},
  reviews: [...defaultReviews],
  notifications: [...defaultNotifications]
};

function createNotification(recipientEmail, title, message, type = 'info') {
  if (!db.notifications) db.notifications = [...defaultNotifications];
  const newNotif = {
    id: 'NOTIF_' + Date.now() + '_' + Math.floor(Math.random() * 1000),
    recipient_email: (recipientEmail || '').toLowerCase(),
    title: title,
    message: message,
    type: type,
    read: false,
    timestamp: new Date().toLocaleString('en-US', { hour: 'numeric', minute: 'numeric', hour12: true, day: 'numeric', month: 'short' })
  };
  db.notifications.unshift(newNotif);
  saveDB();
  return newNotif;
}

function loadDB() {
  try {
    if (fs.existsSync(dbFilePath)) {
      const data = fs.readFileSync(dbFilePath, 'utf8');
      const loaded = JSON.parse(data);
      db = { ...db, ...loaded };
      if (!db.chats) db.chats = {};
      if (!db.reviews || db.reviews.length === 0) db.reviews = [...defaultReviews];
      if (!db.notifications || db.notifications.length === 0) db.notifications = [...defaultNotifications];
      for (const u of defaultUsers) {
        if (!db.users.some(x => x.email.toLowerCase() === u.email.toLowerCase())) {
          db.users.push(u);
        }
      }
    }
  } catch (e) {
    console.error('Error loading db.json', e);
  }
}

function saveDB() {
  try {
    fs.writeFileSync(dbFilePath, JSON.stringify(db, null, 2), 'utf8');
  } catch (e) {
    console.error('Error saving db.json', e);
  }
}

loadDB();

const users = db.users;
const vacancies = db.vacancies;
const applications = db.applications;
const measurements = db.measurements;
const alterRequests = db.alterRequests;
const customizeRequests = db.customizeRequests;
const cartItems = db.cartItems;
const orders = db.orders;
const chats = db.chats;

function createJWT(payload) {
  const header = Buffer.from(JSON.stringify({ alg: "HS256", typ: "JWT" })).toString('base64url');
  const body = Buffer.from(JSON.stringify(payload)).toString('base64url');
  const signature = Buffer.from("mock_signature").toString('base64url');
  return `${header}.${body}.${signature}`;
}

const server = http.createServer((req, res) => {
  // Set CORS headers
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  if (req.method === 'OPTIONS') {
    res.writeHead(200);
    res.end();
    return;
  }

  const parsedUrl = url.parse(req.url, true);
  const path = parsedUrl.pathname;

  let body = '';
  req.on('data', chunk => { body += chunk.toString(); });

  req.on('end', () => {
    let jsonBody = {};
    try {
      if (body) jsonBody = JSON.parse(body);
    } catch (e) {}

    // Parse multipart/form-data if jsonBody is empty
    if (body && Object.keys(jsonBody).length === 0) {
      const parts = body.split(/--+[^\r\n]+/);
      for (const part of parts) {
        const nameMatch = part.match(/name="([^"]+)"/);
        if (nameMatch) {
          const fieldName = nameMatch[1];
          const headerEnd = part.indexOf('\r\n\r\n');
          if (headerEnd !== -1) {
            jsonBody[fieldName] = part.substring(headerEnd + 4).replace(/\r?\n$/, '').trim();
          } else {
            const headerEndLF = part.indexOf('\n\n');
            if (headerEndLF !== -1) {
              jsonBody[fieldName] = part.substring(headerEndLF + 2).replace(/\n$/, '').trim();
            }
          }
        }
      }
    }

    console.log(`[${req.method}] ${path}`, jsonBody);

    // USER REGISTRATION
    if (path === '/register' && req.method === 'POST') {
      const existingUserIndex = users.findIndex(u => (u.email || '').toLowerCase() === (jsonBody.email || '').toLowerCase());
      if (existingUserIndex !== -1) {
        users[existingUserIndex] = { ...users[existingUserIndex], ...jsonBody };
      } else {
        users.push(jsonBody);
      }
      saveDB();
      res.writeHead(201, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ message: 'User registered successfully!' }));
      return;
    }

    // USER LOGIN
    if (path === '/login' && req.method === 'POST') {
      const email = (jsonBody.email || '').toLowerCase();
      const password = jsonBody.password;
      
      const foundUser = users.find(u => (u.email || '').toLowerCase() === email);

      if (!foundUser) {
        res.writeHead(401, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ message: 'Invalid credentials. User not found.' }));
        return;
      }

      if (foundUser.password !== password) {
        res.writeHead(401, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ message: 'Invalid credentials. Incorrect password.' }));
        return;
      }

      const token = createJWT({
        email: foundUser.email,
        username: foundUser.username || foundUser.email.split('@')[0],
        user_type: foundUser.user_type || 'User',
        address: foundUser.address || '',
        phone_number: foundUser.phone_number || '',
        exp: Math.floor(Date.now() / 1000) + (60 * 60 * 24)
      });

      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ token: token }));
      return;
    }

    // PROFILE API
    if (path === '/profile') {
      const userEmail = (jsonBody.email || parsedUrl.query.email || '').toLowerCase();
      const foundUser = users.find(u => (u.email || '').toLowerCase() === userEmail) || {
        username: 'User',
        email: userEmail || 'user@example.com',
        phone_number: '9876543210',
        address: 'Main City'
      };
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify(foundUser));
      return;
    }

    // PROFILE UPDATE API
    if (path === '/profile/update' && req.method === 'POST') {
      const userEmail = (jsonBody.email || '').toLowerCase();
      const foundUser = users.find(u => (u.email || '').toLowerCase() === userEmail);
      if (foundUser) {
        if (jsonBody.username) foundUser.username = jsonBody.username;
        if (jsonBody.phone_number) foundUser.phone_number = jsonBody.phone_number;
        if (jsonBody.address) foundUser.address = jsonBody.address;
        saveDB();
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ message: 'Profile updated successfully!', user: foundUser }));
      } else {
        res.writeHead(404, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ message: 'User not found' }));
      }
      return;
    }

    // REVIEWS API
    if (path === '/reviews/add' && req.method === 'POST') {
      const { boutique_email, customer_email, rating, comment } = jsonBody;
      if ((boutique_email || '').toLowerCase() === (customer_email || '').toLowerCase()) {
        res.writeHead(400, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: 'You cannot review your own profile.' }));
        return;
      }
      const customer = users.find(u => (u.email || '').toLowerCase() === (customer_email || '').toLowerCase());
      const newReview = {
        id: 'REV' + Date.now(),
        boutique_email: boutique_email,
        customer_email: customer_email,
        customer_name: customer ? customer.username : (customer_email ? customer_email.split('@')[0] : 'Customer'),
        rating: Number(rating) || 5,
        comment: comment || '',
        timestamp: 'Just now'
      };
      if (!db.reviews) db.reviews = [];
      db.reviews.push(newReview);

      if (boutique_email) {
        createNotification(
          boutique_email,
          'New Review Received ⭐',
          `${newReview.customer_name} left a ${newReview.rating}-star review: "${comment || 'Great service!'}"`,
          'review'
        );
      }

      saveDB();
      res.writeHead(201, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ message: 'Review submitted successfully!', review: newReview }));
      return;
    }

    if (path.startsWith('/reviews')) {
      const targetEmail = path.replace('/reviews/get/', '').replace('/reviews/get', '').replace('/reviews/', '').replace('/reviews', '');
      const queryEmail = parsedUrl.query.email || targetEmail;
      const reviewsList = (db.reviews || []).filter(r => !queryEmail || (r.boutique_email || '').toLowerCase() === queryEmail.toLowerCase());
      
      let avgRating = 5.0;
      if (reviewsList.length > 0) {
        const sum = reviewsList.reduce((acc, curr) => acc + (Number(curr.rating) || 5), 0);
        avgRating = Number((sum / reviewsList.length).toFixed(1));
      }
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({
        reviews: reviewsList,
        average_rating: avgRating,
        total_reviews: reviewsList.length
      }));
      return;
    }

    // NOTIFICATIONS API
    if (path.startsWith('/notifications')) {
      if (path === '/notifications/read' && req.method === 'POST') {
        const { email, notif_id } = jsonBody;
        if (!db.notifications) db.notifications = [...defaultNotifications];
        if (notif_id) {
          const item = db.notifications.find(n => n.id === notif_id);
          if (item) item.read = true;
        } else if (email) {
          db.notifications.forEach(n => {
            if ((n.recipient_email || '').toLowerCase() === email.toLowerCase()) n.read = true;
          });
        }
        saveDB();
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ message: 'Notifications marked as read' }));
        return;
      }

      if (path === '/notifications/add' && req.method === 'POST') {
        const { recipient_email, title, message, type } = jsonBody;
        const notif = createNotification(recipient_email, title, message, type || 'info');
        res.writeHead(201, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ message: 'Notification created', notification: notif }));
        return;
      }

      const targetEmail = path.replace('/notifications/get/', '').replace('/notifications/get', '').replace('/notifications/', '').replace('/notifications', '');
      const queryEmail = parsedUrl.query.email || targetEmail;
      if (!db.notifications) db.notifications = [...defaultNotifications];
      const userNotifs = db.notifications.filter(n => !queryEmail || (n.recipient_email || '').toLowerCase() === queryEmail.toLowerCase());
      const unreadCount = userNotifs.filter(n => !n.read).length;
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ notifications: userNotifs, unread_count: unreadCount }));
      return;
    }

    // TAILORS & BOUTIQUES
    if (path === '/tailors' && req.method === 'GET') {
      const tailors = users.filter(u => (u.user_type || '').toLowerCase() === 'tailor');
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify(tailors));
      return;
    }
    if (path === '/boutiques' && req.method === 'GET') {
      const boutiques = users.filter(u => (u.user_type || '').toLowerCase() === 'boutique');
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify(boutiques));
      return;
    }

    // MEASUREMENTS API
    if (path.startsWith('/measurements')) {
      if (req.method === 'POST') {
        const { email } = jsonBody;
        measurements[email] = jsonBody;
        res.writeHead(201, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ message: 'Measurements saved successfully!' }));
        return;
      }
      if (req.method === 'GET') {
        const email = path.replace('/measurements/', '').replace('/measurements', '');
        const m = measurements[email] || {
          chest_size: '38',
          waist_size: '32',
          hip_size: '36',
          height: '175',
          shoulder_width: '42'
        };
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify(m));
        return;
      }
    }

    // ALTER CLOTHES API
    if (path.startsWith('/alter_clothes')) {
      const email = path.replace('/alter_clothes/', '').replace('/alter_clothes', '');
      if (req.method === 'POST') {
        const userEmail = jsonBody.email || email || 'user@example.com';
        const category = jsonBody.category || 'General';
        const description = jsonBody.description || jsonBody.message || 'Alteration request';
        const boutiqueEmail = jsonBody.boutique_email || null;

        if (!alterRequests[userEmail]) alterRequests[userEmail] = [];
        alterRequests[userEmail].push({
          category: category,
          description: description
        });
        
        const newOrderId = 'ORD' + (orders.length + 1000);
        orders.push({
          order_id: newOrderId,
          customer_email: userEmail,
          type: 'Alteration',
          category: category,
          description: description,
          status: 'Pending',
          progress: '0%',
          boutique_email: boutiqueEmail
        });

        createNotification(
          userEmail,
          'Alteration Order Placed ✂️',
          `Your alteration request #${newOrderId} for ${category} has been submitted successfully.`,
          'order'
        );
        if (boutiqueEmail) {
          createNotification(
            boutiqueEmail,
            'New Direct Alteration Order 📩',
            `Customer ${userEmail} sent a new alteration request #${newOrderId}.`,
            'order'
          );
        }

        res.writeHead(201, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ message: 'Alter request successful!' }));
        return;
      }
      if (req.method === 'PUT' && path === '/orders/progress') {
        const { order_id, progress } = jsonBody;
        const order = orders.find(o => o.order_id === order_id);
        if (order) {
          order.progress = progress;
          if (progress === '100%') {
            order.status = 'Completed';
          }
          saveDB();
          res.writeHead(200, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({ message: 'Progress updated' }));
        } else {
          res.writeHead(404, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({ message: 'Order not found' }));
        }
        return;
      }
      if (req.method === 'DELETE') {
        alterRequests[email] = [];
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ message: 'Alter requests cleared successfully' }));
        return;
      }
      if (req.method === 'GET') {
        const list = alterRequests[email] || [];
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify(list));
        return;
      }
    }

    // CUSTOMIZE CLOTHES API
    if (path.startsWith('/customize_clothes')) {
      const email = path.replace('/customize_clothes/', '').replace('/customize_clothes', '');
      if (req.method === 'POST') {
        const userEmail = jsonBody.email || email || 'user@example.com';
        const category = jsonBody.category || 'General';
        const description = jsonBody.design_inspiration || jsonBody.description || jsonBody.message || 'Customization request';
        const boutiqueEmail = jsonBody.boutique_email || null;

        if (!customizeRequests[userEmail]) customizeRequests[userEmail] = [];
        customizeRequests[userEmail].push({
          category: category,
          design_inspiration: description,
          description: description
        });
        
        const newOrderId = 'ORD' + (orders.length + 1000);
        orders.push({
          order_id: newOrderId,
          customer_email: userEmail,
          type: 'Customization',
          category: category,
          description: description,
          status: 'Pending',
          progress: '0%',
          boutique_email: boutiqueEmail
        });

        createNotification(
          userEmail,
          'Customization Order Placed 👗',
          `Your customization request #${newOrderId} for ${category} has been submitted.`,
          'order'
        );
        if (boutiqueEmail) {
          createNotification(
            boutiqueEmail,
            'New Direct Customization Order 👗',
            `Customer ${userEmail} requested a custom order #${newOrderId}.`,
            'order'
          );
        }

        res.writeHead(201, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ message: 'Customization request successful!' }));
        return;
      }
      if (req.method === 'DELETE') {
        customizeRequests[email] = [];
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ message: 'Customize requests cleared successfully' }));
        return;
      }
      if (req.method === 'GET') {
        const list = customizeRequests[email] || [];
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify(list));
        return;
      }
    }

    // CART API
    if (path.startsWith('/cart')) {
      if (req.method === 'DELETE') {
        const email = path.replace('/cart/clear/', '').replace('/cart/clear', '');
        cartItems[email] = [];
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ message: 'Cart cleared successfully' }));
        return;
      }
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify([]));
      return;
    }

    // BOUTIQUE: POST NEW VACANCY
    if ((path === '/vacancy/create' || path === '/vacancy/post') && req.method === 'POST') {
      const boutiqueUser = users.find(u => u.email === jsonBody.email);
      const newVacancy = {
        Vacancy_id: 'V' + (vacancies.length + 101),
        address: jsonBody.address || (boutiqueUser ? boutiqueUser.address : '') || 'Main Market Address',
        working_hours: jsonBody.working_hours || '9 AM - 6 PM',
        salary_offered: jsonBody.salary_offered || '20000',
        phone_number: jsonBody.phone_number || (boutiqueUser ? boutiqueUser.phone_number : '') || '9876543210',
        email: jsonBody.email
      };
      vacancies.push(newVacancy);

      createNotification(
        jsonBody.email,
        'Vacancy Posted Successfully 💼',
        `Job Vacancy #${newVacancy.Vacancy_id} offering ₹${newVacancy.salary_offered} is now live.`,
        'job'
      );

      saveDB();

      res.writeHead(201, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ message: 'Vacancy Created Successfully!', status: 'success', vacancy: newVacancy }));
      return;
    }

    // TAILOR / PUBLIC: FETCH ALL VACANCIES
    if (path === '/vacancy/all' && req.method === 'GET') {
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ vacancies: vacancies }));
      return;
    }

    // TAILOR: APPLY FOR A VACANCY
    if (path === '/application/apply' && req.method === 'POST') {
      const tailorEmail = jsonBody.email;
      const vacancyId = jsonBody.Vacancy_id;
      const tailorUser = users.find(u => u.email === tailorEmail);
      const targetVacancy = vacancies.find(v => v.Vacancy_id == vacancyId);

      const existingApp = applications.find(a => a.email === tailorEmail && a.Vacancy_id == vacancyId);
      if (existingApp) {
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ message: 'Already applied for this vacancy!' }));
        return;
      }

      const newApp = {
        name: (tailorUser ? (tailorUser.username || tailorUser.email.split('@')[0]) : 'Tailor'),
        address: (tailorUser ? (tailorUser.address || 'Address Not Provided') : 'Address Not Provided'),
        phone_number: (tailorUser ? (tailorUser.phone_number || 'N/A') : 'N/A'),
        Vacancy_id: vacancyId ? vacancyId.toString() : '',
        email: tailorEmail,
        status: 'Pending',
        boutique_email: targetVacancy ? targetVacancy.email : ''
      };
      applications.push(newApp);

      createNotification(
        tailorEmail,
        'Job Application Submitted 📝',
        `Your application for Vacancy #${vacancyId} has been sent to boutique.`,
        'job'
      );
      if (targetVacancy && targetVacancy.email) {
        createNotification(
          targetVacancy.email,
          'New Applicant Alert 👔',
          `${newApp.name} applied for Vacancy #${vacancyId}.`,
          'job'
        );
      }

      saveDB();

      res.writeHead(201, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ message: 'Application submitted successfully!' }));
      return;
    }

    // BOUTIQUE: UPDATE APPLICATION STATUS (ACCEPT / REJECT)
    if (path === '/applications/status' && req.method === 'PUT') {
      const { Vacancy_id, email, status } = jsonBody;
      const app = applications.find(a => (a.Vacancy_id == Vacancy_id || a.vacancyId == Vacancy_id) && a.email === email);
      if (app) {
        app.status = status;

        createNotification(
          email,
          `Application ${status === 'Accepted' ? 'Accepted 🎉' : 'Status Update 📌'}`,
          `Your application for Vacancy #${Vacancy_id} is now ${status}.`,
          'job'
        );

        saveDB();
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ message: `Application status updated to ${status}` }));
      } else {
        res.writeHead(404, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ message: 'Application not found' }));
      }
      return;
    }

    // BOUTIQUE / TAILOR: FETCH APPLICATIONS
    if (path.startsWith('/applications') && req.method === 'GET') {
      const subPath = path.replace('/applications', '').replace('/', '');
      
      const enrichedApplications = applications.map(app => {
        const tailorEmail = app.email;
        const completedOrders = orders.filter(o => o.boutique_email === tailorEmail && (o.status === 'Completed' || o.progress === '100%')).length;
        
        // Fetch actual rating from reviews
        const reviewsList = (db.reviews || []).filter(r => (r.boutique_email || '').toLowerCase() === (tailorEmail || '').toLowerCase());
        let avgRating = 5.0; // Default rating if no reviews
        if (reviewsList.length > 0) {
          const sum = reviewsList.reduce((acc, curr) => acc + (Number(curr.rating) || 5), 0);
          avgRating = Number((sum / reviewsList.length).toFixed(1));
        }
        
        return {
          ...app,
          completed_jobs: completedOrders,
          rating: avgRating
        };
      });

      if (subPath) {
        const tailorApps = enrichedApplications.filter(a => a.email === subPath);
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify(tailorApps));
        return;
      } else {
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify(enrichedApplications));
        return;
      }
    }

    // PRODUCTS & FABRICS
    if (path === '/products' || path.startsWith('/products/')) {
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ id: 1, name: 'Custom Suit', price: 1500 }));
      return;
    }

    if (path === '/fabric' || path.startsWith('/fabric/')) {
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ id: 1, name: 'Cotton Fabric', price: 500 }));
      return;
    }

    // ORDERS API (Marketplace)
    if (path === '/orders/open' && req.method === 'GET') {
      const openOrders = orders.filter(o => o.status === 'Pending' && (!o.boutique_email));
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify(openOrders));
      return;
    }

    if (path.startsWith('/orders/boutique/') && req.method === 'GET') {
      const boutiqueEmail = path.replace('/orders/boutique/', '');
      const boutiqueOrders = orders.filter(o => o.boutique_email === boutiqueEmail);
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify(boutiqueOrders));
      return;
    }

    if (path.startsWith('/orders/customer/') && req.method === 'GET') {
      const customerEmail = path.replace('/orders/customer/', '');
      const customerOrders = orders.filter(o => o.customer_email === customerEmail);
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify(customerOrders));
      return;
    }

    if (path === '/orders/accept' && req.method === 'PUT') {
      const { order_id, boutique_email } = jsonBody;
      const order = orders.find(o => o.order_id === order_id);
      if (order) {
        order.status = 'Accepted';
        order.boutique_email = boutique_email;

        if (order.customer_email) {
          createNotification(
            order.customer_email,
            'Order Accepted 🎉',
            `Boutique (${boutique_email}) accepted your order #${order_id}.`,
            'order'
          );
        }

        saveDB();
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ message: 'Order accepted successfully' }));
      } else {
        res.writeHead(404, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ message: 'Order not found' }));
      }
      return;
    }

    if (path === '/orders/reject' && req.method === 'PUT') {
      const { order_id, reject_reason } = jsonBody;
      const order = orders.find(o => o.order_id === order_id);
      if (order) {
        order.status = 'Rejected';
        if (reject_reason) {
          order.reject_reason = reject_reason;
        }

        if (order.customer_email) {
          createNotification(
            order.customer_email,
            'Order Update ❌',
            `Your order #${order_id} was rejected. ${reject_reason ? 'Reason: ' + reject_reason : ''}`,
            'order'
          );
        }

        saveDB();
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ message: 'Order rejected successfully' }));
      } else {
        res.writeHead(404, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ message: 'Order not found' }));
      }
      return;
    }

    if (path === '/orders/progress' && req.method === 'PUT') {
      const { order_id, progress } = jsonBody;
      const order = orders.find(o => o.order_id === order_id);
      if (order) {
        order.progress = progress;
        if (progress === '100%') {
          order.status = 'Completed';
        }

        if (order.customer_email) {
          createNotification(
            order.customer_email,
            progress === '100%' ? 'Order Completed! 🏆' : 'Work Progress Update 🧵',
            `Order #${order_id} progress updated to ${progress}.`,
            'order'
          );
        }

        saveDB();
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ message: 'Progress updated successfully' }));
      } else {
        res.writeHead(404, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ message: 'Order not found' }));
      }
      return;
    }

    // CHAT API FOR ORDERS
    if (path.startsWith('/chat/')) {
      const parts = path.replace('/chat/', '').split('/');
      const orderId = parts[0];
      const messageId = parts[1];
      if (!chats[orderId]) chats[orderId] = [];

      if (req.method === 'DELETE' && messageId) {
        const initialLength = chats[orderId].length;
        chats[orderId] = chats[orderId].filter(msg => msg.id !== messageId);
        if (chats[orderId].length < initialLength) {
          saveDB();
          res.writeHead(200, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({ message: 'Message deleted successfully' }));
        } else {
          res.writeHead(404, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({ message: 'Message not found' }));
        }
        return;
      }

      if (req.method === 'GET') {
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify(chats[orderId]));
        return;
      }

      if (req.method === 'POST') {
        const newMessage = {
          id: 'MSG' + Date.now(),
          sender: jsonBody.sender || jsonBody.email || 'User',
          text: jsonBody.text || jsonBody.message || '',
          image: jsonBody.image || jsonBody.image_url || null,
          audio: jsonBody.audio || null,
          is_voice: jsonBody.is_voice || false,
          timestamp: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
        };
        chats[orderId].push(newMessage);

        const assocOrder = orders.find(o => o.order_id === orderId);
        if (assocOrder) {
          const senderEmail = (jsonBody.sender || jsonBody.email || '').toLowerCase();
          const targetRecipient = (senderEmail === (assocOrder.customer_email || '').toLowerCase())
            ? assocOrder.boutique_email
            : assocOrder.customer_email;
          if (targetRecipient) {
            createNotification(
              targetRecipient,
              'New Message 💬',
              `New message on order #${orderId}: "${newMessage.text.substring(0, 40) || 'Attachment'}"`,
              'system'
            );
          }
        }

        saveDB();

        res.writeHead(201, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ message: 'Message sent successfully', chat: newMessage }));
        return;
      }
    }

    // DEFAULT FALLBACK
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ status: 'ok', vacancies: vacancies, applications: applications, data: [] }));
  });
});

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
  console.log(`Backend server running at http://localhost:${PORT}`);
});

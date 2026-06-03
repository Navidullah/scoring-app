require('dotenv').config();
const express = require('express');
const cors = require('cors');

const tournamentRoutes = require('./routes/tournament.routes');
const matchRoutes = require('./routes/match.routes');
const teamRoutes = require('./routes/team.routes');
const syncRoutes = require('./routes/sync.routes');
const { errorHandler, notFound } = require('./middleware/error');

const app = express();

app.use(cors());
app.use(express.json({ limit: '5mb' }));

// Health check — handy for confirming the server + DB are alive.
app.get('/api/health', (req, res) => {
  res.json({ success: true, data: { status: 'ok', time: new Date().toISOString() } });
});

app.use('/api/tournaments', tournamentRoutes);
app.use('/api/matches', matchRoutes);
app.use('/api/teams', teamRoutes);
app.use('/api/sync', syncRoutes);

// 404 + centralized error handling (must be last).
app.use(notFound);
app.use(errorHandler);

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`🏏 Cricket Scoring API listening on http://localhost:${PORT}`);
});

module.exports = app;

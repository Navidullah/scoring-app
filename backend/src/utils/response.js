// Consistent JSON envelope helpers — see CLAUDE.md conventions.
const ok = (res, data, status = 200) => res.status(status).json({ success: true, data });
const fail = (res, error, status = 400) => res.status(status).json({ success: false, error });

module.exports = { ok, fail };

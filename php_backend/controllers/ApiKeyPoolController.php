<?php
/**
 * HealthExpress AI - Sarvam AI Key Pool & Failover Manager
 * 
 * Features:
 * 1. Zero Authentication Required (Public admin access as requested)
 * 2. Multi-Key Pool (Accepts multiple keys, rotates sequentially)
 * 3. Automatic Status Management: 'active' | 'exhausted' | 'invalid'
 * 4. Real-time Live Failover: switches to next available active key
 * 5. Standalone Responsive Management UI
 */

require_once __DIR__ . '/../helpers/Response.php';

class ApiKeyPoolController {

    private static function getStoragePath(): string {
        $dir = __DIR__ . '/../data';
        if (!is_dir($dir)) {
            @mkdir($dir, 0777, true);
        }
        return $dir . '/sarvam_api_keys.json';
    }

    private static function maskKey(string $key): string {
        $key = trim($key);
        if (strlen($key) <= 10) return '***';
        return substr($key, 0, 7) . '...' . substr($key, -5);
    }

    public static function loadPool(): array {
        $path = self::getStoragePath();
        if (file_exists($path)) {
            $data = json_decode(file_get_contents($path), true);
            if (is_array($data) && isset($data['keys'])) {
                return $data;
            }
        }

        // Default initial pool with primary environment key
        $defaultKey = 'sk_5ijbsyhu_co3XmcxZMgr0Rf0HAjfWvV4x';
        $initialStore = [
            'version' => '1.0',
            'updated_at' => date('c'),
            'active_key_id' => 'KEY-1',
            'keys' => [
                [
                    'id' => 'KEY-1',
                    'key' => $defaultKey,
                    'masked_key' => self::maskKey($defaultKey),
                    'label' => 'Primary Production Key',
                    'status' => 'active', // 'active' | 'exhausted' | 'invalid'
                    'added_at' => date('Y-m-d H:i:s'),
                    'last_used_at' => date('Y-m-d H:i:s'),
                    'last_checked_at' => null,
                    'failure_reason' => null,
                    'calls_count' => 0
                ]
            ]
        ];

        @file_put_contents($path, json_encode($initialStore, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES));
        return $initialStore;
    }

    private static function savePool(array $pool): bool {
        $pool['updated_at'] = date('c');
        $path = self::getStoragePath();
        return (bool) @file_put_contents($path, json_encode($pool, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES));
    }

    /**
     * Finds and returns the first available active key.
     * If current active is valid, returns it; otherwise rotates to next available.
     */
    private static function resolveActiveKey(array &$pool): ?array {
        $keys = &$pool['keys'];
        if (empty($keys)) return null;

        // Check if current active_key_id is still active
        $currentId = $pool['active_key_id'] ?? null;
        if ($currentId) {
            foreach ($keys as &$k) {
                if ($k['id'] === $currentId && $k['status'] === 'active') {
                    return $k;
                }
            }
        }

        // Otherwise find first key with status == 'active'
        foreach ($keys as &$k) {
            if ($k['status'] === 'active') {
                $pool['active_key_id'] = $k['id'];
                self::savePool($pool);
                return $k;
            }
        }

        // All keys are exhausted or invalid
        $pool['active_key_id'] = null;
        self::savePool($pool);
        return null;
    }

    /**
     * GET /api/public/sarvam-keys
     * Returns full pool information
     */
    public static function getKeys(): void {
        header('Cache-Control: no-store, no-cache, must-revalidate, max-age=0');
        header('Pragma: no-cache');
        header('Expires: 0');
        $pool = self::loadPool();
        $activeKey = self::resolveActiveKey($pool);

        Response::json([
            'status' => 'success',
            'active_key_id' => $pool['active_key_id'],
            'has_active_key' => $activeKey !== null,
            'active_key_masked' => $activeKey ? $activeKey['masked_key'] : null,
            'total_keys' => count($pool['keys']),
            'active_count' => count(array_filter($pool['keys'], fn($k) => $k['status'] === 'active')),
            'exhausted_count' => count(array_filter($pool['keys'], fn($k) => $k['status'] === 'exhausted')),
            'invalid_count' => count(array_filter($pool['keys'], fn($k) => $k['status'] === 'invalid')),
            'keys' => $pool['keys']
        ]);
    }

    /**
     * GET /api/public/sarvam-keys/active
     * Lightweight endpoint for live services (LiveKit Agent / Flutter) to get the active plaintext key
     */
    public static function getActiveKey(): void {
        $pool = self::loadPool();
        $activeKey = self::resolveActiveKey($pool);

        if (!$activeKey) {
            Response::json([
                'status' => 'exhausted',
                'error' => 'All Sarvam API keys in the pool are exhausted or invalid. Please add a new key in the manager.',
                'key' => null,
                'id' => null
            ], 402);
            return;
        }

        Response::json([
            'status' => 'success',
            'id' => $activeKey['id'],
            'key' => $activeKey['key'],
            'masked_key' => $activeKey['masked_key'],
            'label' => $activeKey['label'],
            'status_label' => $activeKey['status']
        ]);
    }

    /**
     * POST /api/public/sarvam-keys
     * Add 1 or multiple keys (comma-separated, newline-separated, or JSON array)
     */
    public static function addKeys(): void {
        $body = json_decode(file_get_contents('php://input'), true) ?? [];
        $rawKeys = $body['keys'] ?? $body['key'] ?? '';
        $label = trim($body['label'] ?? '');

        $keysToAdd = [];
        if (is_array($rawKeys)) {
            $keysToAdd = $rawKeys;
        } elseif (is_string($rawKeys)) {
            $split = preg_split('/[\r\n,;]+/', $rawKeys);
            foreach ($split as $k) {
                $trimmed = trim($k);
                if (!empty($trimmed)) {
                    $keysToAdd[] = $trimmed;
                }
            }
        }

        if (empty($keysToAdd)) {
            Response::error('No valid API keys provided. Please provide one or more Sarvam API keys.', 400);
            return;
        }

        $pool = self::loadPool();
        $added = [];
        $existingKeys = array_column($pool['keys'], 'key');

        foreach ($keysToAdd as $k) {
            $cleanKey = trim($k);
            if (empty($cleanKey)) continue;

            if (in_array($cleanKey, $existingKeys)) {
                continue; // Skip duplicate
            }

            $newId = 'KEY-' . (count($pool['keys']) + count($added) + 1);
            $newRecord = [
                'id' => $newId,
                'key' => $cleanKey,
                'masked_key' => self::maskKey($cleanKey),
                'label' => !empty($label) ? $label : 'Backup Key #' . substr($newId, 4),
                'status' => 'active',
                'added_at' => date('Y-m-d H:i:s'),
                'last_used_at' => null,
                'last_checked_at' => null,
                'failure_reason' => null,
                'calls_count' => 0
            ];

            $pool['keys'][] = $newRecord;
            $added[] = $newRecord;
        }

        // If no active key existed, set first added as active
        if (empty($pool['active_key_id']) && !empty($added)) {
            $pool['active_key_id'] = $added[0]['id'];
        }

        self::savePool($pool);

        Response::json([
            'status' => 'success',
            'message' => 'Successfully added ' . count($added) . ' new Sarvam API key(s) to the pool.',
            'added' => $added,
            'total_keys' => count($pool['keys']),
            'active_key_id' => $pool['active_key_id']
        ], 201);
    }

    /**
     * POST /api/public/sarvam-keys/mark-exhausted
     * Marks key as exhausted and auto-switches to next active key
     */
    public static function markKeyExhausted(): void {
        $body = json_decode(file_get_contents('php://input'), true) ?? [];
        $targetId = $body['id'] ?? null;
        $targetKey = $body['key'] ?? null;
        $reason = $body['reason'] ?? 'Credits exhausted (HTTP 402 Insufficient Balance)';

        $pool = self::loadPool();
        $matched = false;

        foreach ($pool['keys'] as &$k) {
            if (($targetId && $k['id'] === $targetId) || ($targetKey && $k['key'] === $targetKey) || (!$targetId && !$targetKey && $k['id'] === $pool['active_key_id'])) {
                $k['status'] = 'exhausted';
                $k['failure_reason'] = $reason;
                $k['last_checked_at'] = date('Y-m-d H:i:s');
                $matched = true;
                break;
            }
        }

        $nextActive = self::resolveActiveKey($pool);
        self::savePool($pool);

        Response::json([
            'status' => 'success',
            'message' => 'Key marked as EXHAUSTED.',
            'switched_to' => $nextActive ? $nextActive['masked_key'] : null,
            'next_active_id' => $nextActive ? $nextActive['id'] : null,
            'has_remaining_active' => $nextActive !== null
        ]);
    }

    /**
     * POST /api/public/sarvam-keys/mark-invalid
     * Marks key as invalid (401 / bad key) and auto-switches to next active key
     */
    public static function markKeyInvalid(): void {
        $body = json_decode(file_get_contents('php://input'), true) ?? [];
        $targetId = $body['id'] ?? null;
        $targetKey = $body['key'] ?? null;
        $reason = $body['reason'] ?? 'Invalid or Revoked API Key (HTTP 401/403)';

        $pool = self::loadPool();
        $matched = false;

        foreach ($pool['keys'] as &$k) {
            if (($targetId && $k['id'] === $targetId) || ($targetKey && $k['key'] === $targetKey) || (!$targetId && !$targetKey && $k['id'] === $pool['active_key_id'])) {
                $k['status'] = 'invalid';
                $k['failure_reason'] = $reason;
                $k['last_checked_at'] = date('Y-m-d H:i:s');
                $matched = true;
                break;
            }
        }

        $nextActive = self::resolveActiveKey($pool);
        self::savePool($pool);

        Response::json([
            'status' => 'success',
            'message' => 'Key marked as INVALID.',
            'switched_to' => $nextActive ? $nextActive['masked_key'] : null,
            'next_active_id' => $nextActive ? $nextActive['id'] : null,
            'has_remaining_active' => $nextActive !== null
        ]);
    }

    /**
     * POST /api/public/sarvam-keys/set-active
     * Explicitly set which key is active
     */
    public static function setActiveKey(): void {
        $body = json_decode(file_get_contents('php://input'), true) ?? [];
        $targetId = $body['id'] ?? null;

        if (!$targetId) {
            Response::error('Key ID is required.', 400);
            return;
        }

        $pool = self::loadPool();
        $found = false;

        foreach ($pool['keys'] as &$k) {
            if ($k['id'] === $targetId) {
                $k['status'] = 'active'; // Also reactivate if was marked exhausted
                $k['failure_reason'] = null;
                $pool['active_key_id'] = $targetId;
                $found = true;
                break;
            }
        }

        if (!$found) {
            Response::error('Key not found in pool.', 404);
            return;
        }

        self::savePool($pool);
        Response::json([
            'status' => 'success',
            'message' => "Key $targetId set as ACTIVE.",
            'active_key_id' => $targetId
        ]);
    }

    /**
     * POST /api/public/sarvam-keys/reactivate
     * Reactivate an exhausted key (e.g. after recharging credits on dashboard)
     */
    public static function reactivateKey(): void {
        $body = json_decode(file_get_contents('php://input'), true) ?? [];
        $targetId = $body['id'] ?? null;

        if (!$targetId) {
            Response::error('Key ID is required.', 400);
            return;
        }

        $pool = self::loadPool();
        $found = false;

        foreach ($pool['keys'] as &$k) {
            if ($k['id'] === $targetId) {
                $k['status'] = 'active';
                $k['failure_reason'] = null;
                $found = true;
                break;
            }
        }

        if (!$found) {
            Response::error('Key not found in pool.', 404);
            return;
        }

        self::resolveActiveKey($pool);
        self::savePool($pool);

        Response::json([
            'status' => 'success',
            'message' => "Key $targetId reactivated successfully.",
            'active_key_id' => $pool['active_key_id']
        ]);
    }

    /**
     * DELETE /api/public/sarvam-keys
     * Delete a key from the pool
     */
    public static function deleteKey(): void {
        $body = json_decode(file_get_contents('php://input'), true) ?? [];
        $targetId = $body['id'] ?? $_GET['id'] ?? null;

        if (!$targetId) {
            Response::error('Key ID is required to delete.', 400);
            return;
        }

        $pool = self::loadPool();
        $origCount = count($pool['keys']);
        $pool['keys'] = array_values(array_filter($pool['keys'], fn($k) => $k['id'] !== $targetId));

        if (count($pool['keys']) === $origCount) {
            Response::error('Key not found.', 404);
            return;
        }

        if ($pool['active_key_id'] === $targetId) {
            $pool['active_key_id'] = null;
            self::resolveActiveKey($pool);
        }

        self::savePool($pool);

        Response::json([
            'status' => 'success',
            'message' => "Key $targetId deleted.",
            'active_key_id' => $pool['active_key_id'],
            'total_keys' => count($pool['keys'])
        ]);
    }

    /**
     * GET /sarvam-keys OR /api/public/sarvam-keys-ui
     * Renders a standalone, responsive, modern non-authenticatable Admin UI
     */
    public static function renderUi(): void {
        header('Content-Type: text/html; charset=utf-8');
        header('Cache-Control: no-store, no-cache, must-revalidate, max-age=0');
        header('Pragma: no-cache');
        header('Expires: 0');
        $pool = self::loadPool();
        $inlineJson = json_encode(json_encode($pool, JSON_UNESCAPED_SLASHES));
        
        $html = <<<'HTML'
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>HealthExpress AI - Sarvam API Key Pool & Failover Manager</title>
  <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&family=JetBrains+Mono:wght@400;600&display=swap" rel="stylesheet">
  <style>
    :root {
      --primary: #2563EB;
      --primary-hover: #1D4ED8;
      --success: #10B981;
      --warning: #F59E0B;
      --danger: #EF4444;
      --bg: #0B0F19;
      --surface: #131B2E;
      --surface-border: #1E293B;
      --text: #F8FAFC;
      --text-muted: #94A3B8;
    }
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: 'Plus Jakarta Sans', sans-serif;
      background-color: var(--bg);
      color: var(--text);
      padding: 24px;
      line-height: 1.5;
    }
    .container {
      max-width: 1000px;
      margin: 0 auto;
    }
    header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 24px;
      flex-wrap: wrap;
      gap: 16px;
      padding-bottom: 20px;
      border-bottom: 1px solid var(--surface-border);
    }
    .brand {
      display: flex;
      align-items: center;
      gap: 12px;
    }
    .badge {
      background: rgba(37, 99, 235, 0.15);
      color: #60A5FA;
      padding: 4px 10px;
      border-radius: 20px;
      font-size: 11px;
      font-weight: 700;
      letter-spacing: 0.5px;
      border: 1px solid rgba(37, 99, 235, 0.3);
    }
    .status-pill {
      display: inline-flex;
      align-items: center;
      gap: 6px;
      padding: 4px 10px;
      border-radius: 12px;
      font-size: 12px;
      font-weight: 600;
    }
    .status-active { background: rgba(16, 185, 129, 0.15); color: #34D399; border: 1px solid rgba(16, 185, 129, 0.3); }
    .status-exhausted { background: rgba(245, 158, 11, 0.15); color: #FBBF24; border: 1px solid rgba(245, 158, 11, 0.3); }
    .status-invalid { background: rgba(239, 68, 68, 0.15); color: #F87171; border: 1px solid rgba(239, 68, 68, 0.3); }
    
    .stats-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
      gap: 16px;
      margin-bottom: 24px;
    }
    .card {
      background: var(--surface);
      border: 1px solid var(--surface-border);
      border-radius: 16px;
      padding: 20px;
    }
    .stat-val {
      font-size: 28px;
      font-weight: 800;
      margin-top: 4px;
    }
    .add-section {
      background: var(--surface);
      border: 1px solid var(--surface-border);
      border-radius: 16px;
      padding: 20px;
      margin-bottom: 24px;
    }
    textarea, input {
      width: 100%;
      background: #0F172A;
      border: 1px solid var(--surface-border);
      border-radius: 10px;
      padding: 12px;
      color: #fff;
      font-family: inherit;
      font-size: 14px;
      margin-top: 8px;
      margin-bottom: 14px;
    }
    textarea {
      font-family: 'JetBrains Mono', monospace;
      resize: vertical;
      min-height: 80px;
    }
    button {
      background: var(--primary);
      color: #fff;
      border: none;
      border-radius: 10px;
      padding: 10px 18px;
      font-weight: 700;
      font-size: 13px;
      cursor: pointer;
      transition: all 0.2s;
    }
    button:hover { background: var(--primary-hover); }
    button.btn-danger { background: rgba(239, 68, 68, 0.15); color: #F87171; border: 1px solid rgba(239, 68, 68, 0.3); }
    button.btn-danger:hover { background: var(--danger); color: #fff; }
    button.btn-warn { background: rgba(245, 158, 11, 0.15); color: #FBBF24; border: 1px solid rgba(245, 158, 11, 0.3); }
    button.btn-warn:hover { background: var(--warning); color: #000; }
    button.btn-success { background: rgba(16, 185, 129, 0.15); color: #34D399; border: 1px solid rgba(16, 185, 129, 0.3); }
    button.btn-success:hover { background: var(--success); color: #fff; }

    table {
      width: 100%;
      border-collapse: collapse;
      margin-top: 10px;
    }
    th, td {
      padding: 14px;
      text-align: left;
      border-bottom: 1px solid var(--surface-border);
      font-size: 13.5px;
    }
    th {
      color: var(--text-muted);
      font-size: 11.5px;
      text-transform: uppercase;
      letter-spacing: 0.5px;
    }
    .key-code {
      font-family: 'JetBrains Mono', monospace;
      background: #0B0F19;
      padding: 3px 6px;
      border-radius: 6px;
      border: 1px solid #1E293B;
    }
    .active-badge {
      background: #2563EB;
      color: #fff;
      font-size: 10px;
      padding: 2px 6px;
      border-radius: 6px;
      font-weight: 800;
      margin-left: 6px;
    }
  </style>
</head>
<body>
<div class="container">
  <header>
    <div class="brand">
      <div style="font-size: 26px;">⚡</div>
      <div>
        <h1 style="font-size: 20px; font-weight: 800;">Sarvam AI Multi-Key Pool & Failover Manager</h1>
        <p style="font-size: 12.5px; color: var(--text-muted);">Zero-Auth Open Admin Endpoint • Auto-Switches when credits exhaust</p>
      </div>
    </div>
    <span class="badge">LIVE HEALTHEXPRESS BACKEND</span>
  </header>

  <div class="stats-grid">
    <div class="card">
      <div style="color: var(--text-muted); font-size: 12px; font-weight: 700;">CURRENT ACTIVE KEY</div>
      <div class="stat-val" id="activeKeyDisplay" style="font-size: 18px; font-family: 'JetBrains Mono', monospace; color: #60A5FA;">Loading...</div>
    </div>
    <div class="card">
      <div style="color: var(--text-muted); font-size: 12px; font-weight: 700;">ACTIVE KEYS IN POOL</div>
      <div class="stat-val" id="activeCount" style="color: var(--success);">-</div>
    </div>
    <div class="card">
      <div style="color: var(--text-muted); font-size: 12px; font-weight: 700;">EXHAUSTED KEYS</div>
      <div class="stat-val" id="exhaustedCount" style="color: var(--warning);">-</div>
    </div>
    <div class="card">
      <div style="color: var(--text-muted); font-size: 12px; font-weight: 700;">TOTAL KEYS REGISTERED</div>
      <div class="stat-val" id="totalCount">-</div>
    </div>
  </div>

  <div class="add-section">
    <h3 style="font-size: 15px; margin-bottom: 6px;">Add New Sarvam API Key(s)</h3>
    <p style="font-size: 12px; color: var(--text-muted);">Paste 1 or multiple keys (separated by commas or new lines). They will automatically be added to the rotation queue.</p>
    
    <label style="font-size: 12px; font-weight: 700; color: #CBD5E1; margin-top: 10px; display: block;">API Keys (sk_...)</label>
    <textarea id="newKeysInput" placeholder="sk_5ijbsyhu_...&#10;sk_another_key_..."></textarea>
    
    <label style="font-size: 12px; font-weight: 700; color: #CBD5E1; display: block;">Optional Label / Note</label>
    <input type="text" id="newLabelInput" placeholder="e.g. Account #2 - Recharged ₹500">
    
    <button onclick="submitNewKeys()">+ Add Key(s) to Failover Pool</button>
  </div>

  <div class="card">
    <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 12px;">
      <h3 style="font-size: 16px; font-weight: 700;">Configured API Keys Queue</h3>
      <button style="background: #1E293B; font-size: 11px; padding: 6px 12px;" onclick="loadKeys()">↻ Refresh</button>
    </div>
    
    <div style="overflow-x: auto;">
      <table>
        <thead>
          <tr>
            <th>Key ID</th>
            <th>API Key</th>
            <th>Label</th>
            <th>Status</th>
            <th>Added At</th>
            <th>Actions</th>
          </tr>
        </thead>
        <tbody id="keysTableBody">
          <tr><td colspan="6" style="text-align: center; color: var(--text-muted);">Loading keys pool...</td></tr>
        </tbody>
      </table>
    </div>
  </div>
</div>

<script>
const path = window.location.pathname;
const prefix = path.includes('/healthexpress') ? '/healthexpress' : '';
const API_BASE = `${prefix}/api/public/sarvam-keys`;

function renderPool(data) {
  if (!data) return;
  const keys = data.keys || [];
  const activeCount = keys.filter(k => k.status === 'active').length;
  const exhaustedCount = keys.filter(k => k.status === 'exhausted').length;
  const activeKey = keys.find(k => k.id === data.active_key_id && k.status === 'active') || keys.find(k => k.status === 'active');

  document.getElementById('activeCount').innerText = activeCount;
  document.getElementById('exhaustedCount').innerText = exhaustedCount;
  document.getElementById('totalCount').innerText = keys.length;
  document.getElementById('activeKeyDisplay').innerText = activeKey ? activeKey.masked_key : 'NONE (Exhausted)';

  const tbody = document.getElementById('keysTableBody');
  if (keys.length === 0) {
    tbody.innerHTML = '<tr><td colspan="6" style="text-align: center; color: var(--text-muted);">No keys configured yet. Please add a key above.</td></tr>';
    return;
  }

  tbody.innerHTML = keys.map(k => {
    const isActive = activeKey && k.id === activeKey.id;
    const statusClass = k.status === 'active' ? 'status-active' : (k.status === 'exhausted' ? 'status-exhausted' : 'status-invalid');
    
    return `
      <tr>
        <td>
          <strong>${k.id}</strong>
          ${isActive ? '<span class="active-badge">ACTIVE</span>' : ''}
        </td>
        <td><span class="key-code">${k.masked_key}</span></td>
        <td>${k.label || 'Standard Key'}</td>
        <td>
          <span class="status-pill ${statusClass}">
            ● ${k.status.toUpperCase()}
          </span>
          ${k.failure_reason ? `<div style="font-size: 10.5px; color: #EF4444; margin-top: 2px;">${k.failure_reason}</div>` : ''}
        </td>
        <td style="color: var(--text-muted); font-size: 12px;">${k.added_at || '-'}</td>
        <td>
          <div style="display: flex; gap: 6px; flex-wrap: wrap;">
            ${!isActive && k.status === 'active' ? `<button style="padding: 4px 8px; font-size: 11px;" onclick="setActiveKey('${k.id}')">Make Active</button>` : ''}
            ${k.status === 'active' ? `<button class="btn-warn" style="padding: 4px 8px; font-size: 11px;" onclick="markExhausted('${k.id}')">Mark Exhausted</button>` : ''}
            ${k.status !== 'active' ? `<button class="btn-success" style="padding: 4px 8px; font-size: 11px;" onclick="reactivateKey('${k.id}')">Reactivate</button>` : ''}
            <button class="btn-danger" style="padding: 4px 8px; font-size: 11px;" onclick="deleteKey('${k.id}')">Delete</button>
          </div>
        </td>
      </tr>
    `;
  }).join('');
}

// Immediate initial render from server data
try {
  const initialPool = JSON.parse(%%INLINE_POOL_DATA%%);
  renderPool(initialPool);
} catch (e) {
  console.warn('Notice loading inline data:', e);
}

async function loadKeys() {
  try {
    const res = await fetch(API_BASE + '?_t=' + Date.now(), { cache: 'no-store' });
    const raw = await res.json();
    const data = (raw && raw.data) ? raw.data : raw;
    renderPool(data);
  } catch (err) {
    console.error('Error loading keys:', err);
  }
}

async function submitNewKeys() {
  const keys = document.getElementById('newKeysInput').value.trim();
  const label = document.getElementById('newLabelInput').value.trim();
  if (!keys) {
    alert('Please enter at least one API key.');
    return;
  }

  const res = await fetch(API_BASE, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ keys, label })
  });
  const raw = await res.json();
  const data = (raw && raw.data) ? raw.data : raw;
  if (data.status === 'success' || raw.success === true) {
    document.getElementById('newKeysInput').value = '';
    document.getElementById('newLabelInput').value = '';
    loadKeys();
  } else {
    alert(data.error || raw.error || 'Failed to add keys');
  }
}

async function markExhausted(id) {
  if (!confirm('Mark this key as EXHAUSTED? The system will automatically promote the next active key.')) return;
  await fetch(API_BASE + '/mark-exhausted', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ id, reason: 'Manually marked exhausted from admin panel' })
  });
  loadKeys();
}

async function reactivateKey(id) {
  await fetch(API_BASE + '/reactivate', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ id })
  });
  loadKeys();
}

async function setActiveKey(id) {
  await fetch(API_BASE + '/set-active', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ id })
  });
  loadKeys();
}

async function deleteKey(id) {
  if (!confirm('Delete this key from the pool?')) return;
  await fetch(API_BASE, {
    method: 'DELETE',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ id })
  });
  loadKeys();
}

loadKeys();
setInterval(loadKeys, 10000);
</script>
</body>
</html>
HTML;
        echo str_replace('%%INLINE_POOL_DATA%%', $inlineJson, $html);
    }
}

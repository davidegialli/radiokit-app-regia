# RadioKit Regia — Deploy & integrazione admin

## Cosa fa il workflow GitHub Actions

Su `release` o tag `v*.*.*` (e su push a `main`):
1. Build Android (APK debug / AAB release)
2. Build iOS (IPA release)
3. **Deploy su VPS radiokit.io** in `/var/www/radiokit.io/downloads/regia/`:
   - `v<version>/radiokit_regia.apk`
   - `v<version>/radiokit_regia.aab`
   - `v<version>/radiokit_regia.ipa`
   - `latest.json` con metadati versione + nomi file
   - symlink `latest/` → `v<version>/`
4. Ping admin radiokit.io per invalidare cache

## Secrets GitHub richiesti (impostare nel repo Settings → Secrets)

| Secret | Valore |
|---|---|
| `RADIOKIT_VPS_HOST` | `187.77.166.39` |
| `RADIOKIT_VPS_USER` | utente SSH (es. `radiokit` o `root`) |
| `RADIOKIT_VPS_SSH_KEY` | contenuto di `id_ed25519_ovh` (chiave privata) |
| `ANDROID_KEYSTORE_BASE64` | keystore release in base64 |
| `ANDROID_KEYSTORE_PASSWORD` | password keystore |
| `ANDROID_KEY_PASSWORD` | password chiave |
| `ANDROID_KEY_ALIAS` | alias chiave |
| `APPLE_TEAM_ID` | `88FJK4AB7N` |
| `APPLE_API_KEY_ID` | da App Store Connect |
| `APPLE_API_ISSUER_ID` | da App Store Connect |
| `APP_STORE_CONNECT_KEY_BASE64` | .p8 in base64 |

## Patch admin radiokit.io (1 riga)

L'admin esiste già con voci per Diretta, Timer, Speaker.
**Aggiungere la voce Regia** nello stesso file dove sono listate le altre app.

Tipicamente è un array tipo:

```php
$RK_APPS = [
    'diretta' => ['name' => 'RadioKit Diretta', 'key_prefix' => 'RKS-', 'path' => 'diretta'],
    'timer'   => ['name' => 'RadioKit Timer',   'key_prefix' => 'RKT-', 'path' => 'timer'],
    'speaker' => ['name' => 'RadioKit Speaker', 'key_prefix' => 'RKM-', 'path' => 'speaker'],
    // ⬇️ AGGIUNGERE QUESTA RIGA
    'regia'   => ['name' => 'RadioKit Regia',   'key_prefix' => 'RKR-', 'path' => 'regia'],
];
```

(Nomi e formato esatti dipendono dalla struttura corrente dell'admin —
cercare in `/var/www/radiokit.io/admin/` un array che contiene già `diretta` o `RKS-`).

## Endpoint admin di notifica (opzionale)

Il workflow chiama `http://127.0.0.1/api/admin/release-published.php?product=regia&version=X&channel=Y`.

Se questo endpoint non esiste, il workflow continua comunque (`|| true`).
Se vuoi tracciare le release nel DB, crea il file con questo schema minimo:

```php
<?php
// /var/www/radiokit.io/api/admin/release-published.php
require __DIR__ . '/../../includes/db.php';
$product = $_GET['product'] ?? '';
$version = $_GET['version'] ?? '';
$channel = $_GET['channel'] ?? 'beta';
if (in_array($product, ['regia','diretta','timer','speaker'], true)) {
    $stmt = $pdo->prepare(
      'INSERT INTO rk_releases (product, version, channel, released_at) VALUES (?, ?, ?, NOW())'
    );
    $stmt->execute([$product, $version, $channel]);
}
echo json_encode(['ok' => true]);
```

## URL pubblici risultanti

- Manifest: `https://radiokit.io/downloads/regia/latest.json`
- APK ultima: `https://radiokit.io/downloads/regia/latest/radiokit_regia.apk`
- AAB ultima: `https://radiokit.io/downloads/regia/latest/radiokit_regia.aab`
- IPA ultima: `https://radiokit.io/downloads/regia/latest/radiokit_regia.ipa`
- Versione specifica: `https://radiokit.io/downloads/regia/v0.1.0/radiokit_regia.apk`

## Prima volta — checklist

- [ ] Creato repo GitHub con questo codice
- [ ] Aggiunti tutti i secrets GitHub elencati sopra
- [ ] Sul VPS: `mkdir -p /var/www/radiokit.io/downloads/regia && chown www-data:www-data /var/www/radiokit.io/downloads/regia`
- [ ] Aggiunta voce `'regia' => [...]` all'admin radiokit.io
- [ ] Push su `main` per primo build → verifica che il deploy funzioni
- [ ] Crea release `v0.1.0` per primo deploy stable

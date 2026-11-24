<?php
// First-boot owner bootstrap for the Shoutrrr Railway template.
declare(strict_types=1);

require '/var/www/html/vendor/autoload.php';
$app = require '/var/www/html/bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

use App\Models\User;
use App\Services\Workspace\WorkspaceProvisioningService;
use App\Support\InstanceSettings;
use Illuminate\Support\Facades\DB;

$settings = $app->make(InstanceSettings::class);
if ($settings->ownerExists()) {
    fwrite(STDOUT, "[railway] instance owner already exists\n");
    exit(0);
}

$email = trim((string) getenv('SHOUTRRR_ADMIN_EMAIL')) ?: 'admin@example.com';
$password = (string) getenv('SHOUTRRR_ADMIN_PASSWORD');
$name = trim((string) getenv('SHOUTRRR_ADMIN_NAME')) ?: 'Admin';

if (! filter_var($email, FILTER_VALIDATE_EMAIL)) {
    fwrite(STDERR, "[railway] SHOUTRRR_ADMIN_EMAIL is not a valid email address\n");
    exit(1);
}
if (strlen($password) < 12) {
    fwrite(STDERR, "[railway] SHOUTRRR_ADMIN_PASSWORD must be set and at least 12 characters\n");
    exit(1);
}

DB::transaction(function () use ($app, $settings, $email, $password, $name): void {
    $user = User::query()->where('email', $email)->first();
    $isNew = $user === null;
    if ($isNew) {
        $user = User::create(['name' => $name, 'email' => $email, 'password' => $password]);
    }
    $user->forceFill(['email_verified_at' => now()])->save();
    $settings->claimOwnerIfMissing($user);
    if ($isNew || $user->current_workspace_id === null) {
        $app->make(WorkspaceProvisioningService::class)->provisionForNewUser($user, null);
    }
});

if (! $settings->ownerExists()) {
    fwrite(STDERR, "[railway] could not create the instance owner\n");
    exit(1);
}
fwrite(STDOUT, "[railway] created the instance owner {$email}; public sign-up stays closed\n");

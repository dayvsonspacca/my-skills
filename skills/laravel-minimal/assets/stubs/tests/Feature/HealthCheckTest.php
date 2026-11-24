<?php

declare(strict_types=1);

namespace Tests\Feature;

use PHPUnit\Framework\Attributes\Test;
use Tests\TestCase;

final class HealthCheckTest extends TestCase
{
    #[Test]
    public function health_endpoint_responds_ok(): void
    {
        $this->get('/up')->assertOk();
    }
}

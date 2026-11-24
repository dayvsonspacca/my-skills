<?php

declare(strict_types=1);

// Matches a fresh Laravel app; without this key the framework stores sessions with PHP serialize().
return [
    'serialization' => 'json',
];

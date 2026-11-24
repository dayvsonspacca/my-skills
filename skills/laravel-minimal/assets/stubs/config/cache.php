<?php

declare(strict_types=1);

// Matches a fresh Laravel app; without this key the framework unserializes any class from the cache.
return [
    'serializable_classes' => false,
];

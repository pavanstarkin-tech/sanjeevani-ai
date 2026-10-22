<?php
/**
 * HealthExpress AI - Mapbox Geocoding & Distance Helper
 * Real-time Location Resolution & Proximity Dispatch
 */

require_once __DIR__ . '/../config/config.php';

class MapboxHelper {
    /**
     * Reverse Geocode (Latitude, Longitude) -> Formatted Address, City, State, Pincode
     */
    public static function reverseGeocode(float $latitude, float $longitude): array {
        $token = defined('MAPBOX_ACCESS_TOKEN') ? MAPBOX_ACCESS_TOKEN : '';
        if (empty($token)) {
            return [
                'formatted_address' => 'Gachibowli, Hyderabad, Telangana',
                'city'              => 'Hyderabad',
                'state'             => 'Telangana',
                'pincode'           => '500081',
                'locality'          => 'Gachibowli'
            ];
        }

        $url = "https://api.mapbox.com/geocoding/v5/mapbox.places/{$longitude},{$latitude}.json?access_token={$token}&country=IN";

        $ch = curl_init($url);
        curl_setopt_array($ch, [
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_TIMEOUT => 4,
            CURLOPT_USERAGENT => 'HealthExpress-AI/1.0'
        ]);

        $response = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);

        if ($httpCode === 200 && $response) {
            $data = json_decode($response, true);
            if (!empty($data['features'])) {
                $feature = $data['features'][0];
                $formattedAddress = $feature['place_name'] ?? 'Telangana, India';
                
                $city = 'Hyderabad';
                $state = 'Telangana';
                $pincode = '500081';
                $locality = 'City Center';

                if (!empty($feature['context'])) {
                    foreach ($feature['context'] as $ctx) {
                        $id = $ctx['id'] ?? '';
                        if (strpos($id, 'postcode') !== false) {
                            $pincode = $ctx['text'] ?? $pincode;
                        } elseif (strpos($id, 'place') !== false || strpos($id, 'district') !== false) {
                            $city = $ctx['text'] ?? $city;
                        } elseif (strpos($id, 'region') !== false) {
                            $state = $ctx['text'] ?? $state;
                        } elseif (strpos($id, 'locality') !== false || strpos($id, 'neighborhood') !== false) {
                            $locality = $ctx['text'] ?? $locality;
                        }
                    }
                }

                return [
                    'formatted_address' => $formattedAddress,
                    'city'              => $city,
                    'state'             => $state,
                    'pincode'           => $pincode,
                    'locality'          => $locality
                ];
            }
        }

        return [
            'formatted_address' => 'Gachibowli, Hyderabad, Telangana',
            'city'              => 'Hyderabad',
            'state'             => 'Telangana',
            'pincode'           => '500081',
            'locality'          => 'Gachibowli'
        ];
    }

    /**
     * Calculate Haversine Distance in Kilometers between two coordinates
     */
    public static function getDistanceKm(float $lat1, float $lng1, float $lat2, float $lng2): float {
        $earthRadius = 6371; // km
        $dLat = deg2rad($lat2 - $lat1);
        $dLng = deg2rad($lng2 - $lng1);
        $a = sin($dLat / 2) * sin($dLat / 2) +
             cos(deg2rad($lat1)) * cos(deg2rad($lat2)) *
             sin($dLng / 2) * sin($dLng / 2);
        $c = 2 * atan2(sqrt($a), sqrt(1 - $a));
        return round($earthRadius * $c, 2);
    }

    /**
     * Calculate Estimated Travel Time in Minutes
     */
    public static function getEtaMinutes(float $distanceKm): int {
        // Average urban speed ~25 km/h + 3 min buffer
        return max(4, intval(round(($distanceKm / 25) * 60 + 3)));
    }
}

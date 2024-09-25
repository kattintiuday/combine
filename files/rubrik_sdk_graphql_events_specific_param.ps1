param (
    [string]$client_id,
    [string]$client_secret,
    [string]$access_token_uri,
    [string]$lastUpdatedTimeGt,
    [string]$lastUpdatedTimeLt,
    [string]$lastActivityType
)

$uri = "https://kyndrylinc.my.rubrik.com/api/graphql"

function Invoke-RubrikGQLQuery {
    param (
        [String] $payload,
        [Hashtable] $variables,
        [String] $pathToData
    )

    # Create hashtable to add query and variables together
    $htBody = [Ordered]@{
        "variables" = $variables
        "query" = $payload
    }

    # Convert Hashtable to JSON
    $body = $htBody | ConvertTo-Json -Depth 100

    # Execute Request
    $response = Invoke-RestMethod -Body $body -Headers $headers -Method Post -Uri $uri

    # Extract data if specified
    if ($pathToData) {
        $filters = $pathToData.Split('.')
        foreach ($filter in $filters) {
            $response = $response.$filter
        }
    }

    return $response
}

# Common Headers
$headers = @{
    "Content-Type" = "application/json"
}

# Payload to retrieve access token
$body = @{
    'client_id' = $client_id
    'client_secret' = $client_secret
} | ConvertTo-Json

# Get access token
$response = Invoke-RestMethod -Body $body -Headers $headers -Method Post -Uri $access_token_uri
$headers.Add("Authorization", "Bearer $($response.access_token)")

# Define the query and variables
$query = Get-Content ./queries/Getevents.gql -Raw
$variables = @{
    "after" = $null
    "filters" = @{
        "lastUpdatedTimeGt" = $lastUpdatedTimeGt
        "lastUpdatedTimeLt" = $lastUpdatedTimeLt
        "lastActivityType" = @(
            "BACKUP", "REPLICATION", "RECOVERY", "OWNERSHIP", "RESOURCE_OPERATIONS",
            "SCHEDULE_RECOVERY", "STORAGE", "SYNC", "SYSTEM", "TPR", "TENANT_OVERLAP",
            "TENANT_QUOTA", "TEST_FAILOVER", "THREAT_FEED", "THREAT_HUNT", 
            "THREAT_MONITORING", "USER_INTELLIGENCE", "RANSOMWARE_INVESTIGATION_ANALYSIS",
            "ARCHIVE", "AUTH_DOMAIN", "CLASSIFICATION", "CONNECTION", "CONVERSION",
            "DISCOVERY", "DOWNLOAD", "EMBEDDED_EVENT", "ENCRYPTION_MANAGEMENT_OPERATION",
            "FAILOVER", "HARDWARE", "LOCAL_RECOVERY", "INDEX", "INSTANTIATE", 
            "ISOLATED_RECOVERY", "LEGAL_HOLD", "LOCK_SNAPSHOT", "LOG_BACKUP", 
            "MAINTENANCE", "BULK_RECOVERY", "ANOMALY"
        )
    }
    "sortBy" = $null
    "sortOrder" = $null
}

$clusterData = Invoke-RubrikGQLQuery -payload $query -variables $variables -pathToData "data.activitySeriesConnection.edges"

# Process the fetched cluster data
$results = @()
foreach ($edge in $clusterData) {
    $node = $edge.node
    $activityConnection = $node.activityConnection.nodes

    # Unpack cluster details
    $cluster = $node.cluster
    $clusterDetails = @{
        ClusterID = $cluster.id
        ClusterName = $cluster.name
        ClusterStatus = $cluster.status
        ClusterTimezone = $cluster.timezone
    }

    # Add activity connection details
    foreach ($activity in $activityConnection) {
        $results += [PSCustomObject]@{
            ClusterDetails = $clusterDetails
            ActivityID = $activity.id
            ActivityMessage = $activity.message
            LastActivityType = $node.lastActivityType
        }
    }
}

# Export results to CSV
$outputFilePath = "/home/admin1/Desktop/GraphQL/backup_data.csv"
$results | Export-Csv -Path $outputFilePath -NoTypeInformation

Write-Output "Data exported to $outputFilePath successfully."

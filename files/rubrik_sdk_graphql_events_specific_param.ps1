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
    $htBody = [Ordered]@{}

    # Form Body Hashtable
    $htBody.Add("variables", $variables)
    $htBody.Add("query", $payload)
    # Convert Hashtable to JSON
    $body = $htBody | ConvertTo-Json -Depth 100

    # Execute Request
    $response = Invoke-RestMethod -Body $body -Headers $headers -Method Post -Uri $uri

    if ($pathToData) {
        $filters = $pathToData.Split('.')
        foreach ($filter in $filters) {
            $response = $response.$filter
        }
    }

    return $response
}

# Create Common Headers
$headers = @{
    "Content-Type" = "application/json"
}

# Payload to retrieve access token
$body = @{
    'client_id'     = $client_id
    'client_secret' = $client_secret
}

$body = $body | ConvertTo-Json

# Get access token
$response = Invoke-RestMethod -Body $body -Headers $headers -Method Post -Uri $access_token_uri

# Add access token to header
$headers.Add("Authorization", "Bearer $($response.access_token)")

# Define the query and variables
$query = Get-Content ./queries/Getevents.gql
$variables = @{
    "after" = $null # Replace with actual cursor if pagination is used
    "filters" = @{
        "objectType" = $null
        "lastActivityStatus" = $null
        "lastActivityType" = @(
            "BACKUP",
            "REPLICATION",
            "RECOVERY",
            "OWNERSHIP",
            "RESOURCE_OPERATIONS",
            "SCHEDULE_RECOVERY",
            "STORAGE",
            "SYNC",
            "SYSTEM",
            "TPR",
            "TENANT_OVERLAP",
            "TENANT_QUOTA",
            "TEST_FAILOVER",
            "THREAT_FEED",
            "THREAT_HUNT",
            "THREAT_MONITORING",
            "USER_INTELLIGENCE",
            "RANSOMWARE_INVESTIGATION_ANALYSIS",
            "ARCHIVE",
            "AUTH_DOMAIN",
            "CLASSIFICATION",
            "CONNECTION",
            "CONVERSION",
            "DISCOVERY",
            "DOWNLOAD",
            "EMBEDDED_EVENT",
            "ENCRYPTION_MANAGEMENT_OPERATION",
            "FAILOVER",
            "HARDWARE",
            "LOCAL_RECOVERY",
            "INDEX",
            "INSTANTIATE",
            "ISOLATED_RECOVERY",
            "LEGAL_HOLD",
            "LOCK_SNAPSHOT",
            "LOG_BACKUP",
            "MAINTENANCE",
            "BULK_RECOVERY",
            "ANOMALY"
        )
        "severity" = $null
        "clusterId" = $null
        "lastUpdatedTimeGt" = $lastUpdatedTimeGt
        "lastUpdatedTimeLt" = $lastUpdatedTimeLt
        "orgIds" = @()  # Empty array for organization IDs
        "userIds" = $null
        "objectName" = $null  # Use null if you prefer
    }
    "sortBy" = $null
    "sortOrder" = $null
  }


$clusterData = Invoke-RubrikGQLQuery -payload $query -variables $variables -pathToData "data.activitySeriesConnection.edges.node"
#Write-Output $clusterData

# Define the path for the raw data output file
$rawDataFilePath = "/home/admin1/Desktop/GraphQL/raw_cluster_data.json"

# Convert the raw data to JSON format and write it to the file
$clusterData | ConvertTo-Json -Depth 100 | Out-File -FilePath $rawDataFilePath -Encoding utf8

Write-Output "Raw data written to $rawDataFilePath successfully."

# Path to the JSON file
#$jsonFilePath = "C:\Users\UdayKumarKattinti\Desktop\Graphql\raw_cluster_data.json"

# Load the JSON data from the file
$jsonData = Get-Content -Path $rawDataFilePath | ConvertFrom-Json

# Define a list to store the flattened data
$flattenedData = @()

# Iterate through the data and flatten the nested structures
foreach ($entry in $jsonData) {
    # Extract top-level fields like ID, FID, etc.
    $id = $entry.ID
    $fid = $entry.FID
    $startTime = $entry.StartTime
    $activitySeriesId = $entry.ActivitySeriesId
    $lastUpdated = $entry.LastUpdated
    $lastActivityType = $entry.LastActivityType
    $lastActivityStatus = $entry.LastActivityStatus
    $objectId = $entry.objectId
    $objectName = $entry.ObjectName
    $objectType = $entry.ObjectType
    $severity = $entry.Severity
    $progress = $entry.Progress
    $isCancelable = $entry.IsCancelable
    $isPolarisEventSeries = $entry.IsPolarisEventSeries
    $location = $entry.Location
    $effectiveThroughput = $entry.EffectiveThroughput
    $dataTransferred = $entry.DataTransferred
    $logicalSize = $entry.LogicalSize
    #$organizations = $entry.Organizations
    $clusterUuid = $entry.ClusterUuid
    $clusterName = $entry.ClusterName

     # Extract organizations details
     $organizations = $entry.organizations
     $organizationsID = $organizations.id
     $organizationsName = $organizations.name

    # Extract cluster-related details
    $cluster = $entry.cluster
    $clusterID = $cluster.id
    $clusterNameDetail = $cluster.name
    $clusterStatusDetail = $cluster.status
    $clusterTimezone = $cluster.timezone
    $clusterTypename = $cluster.__typename

    # Loop through the activities inside activityConnection if there are multiple nodes
    $activityNodes = $entry.activityConnection.nodes
    foreach ($activity in $activityNodes) {
        # Extract all activity details
        $activityID = $activity.id
        $activityMessage = $activity.message
        $activityStatus = $activity.status
        $activityTime = $activity.time
        $activitySeverity = $activity.severity
        $activityLocation = $activity.location
        $activityObjectName = $activity.objectName

        # Add the flattened entry to the list
        $flattenedData += [PSCustomObject]@{
            "ID"                = $id
            "FID"               = $fid
            "StartTime"         = $startTime
            "ActivitySeriesId"  = $activitySeriesId
            "LastUpdated"       = $lastUpdated
            "LastActivityType"  = $lastActivityType
            "LastActivityStatus"= $lastActivityStatus
            "ObjectId"          = $objectId
            "ObjectName"        = $objectName
            "ObjectType"        = $objectType
            "Severity"          = $severity
            "Progress"          = $progress
            "IsCancelable"      = $isCancelable
            "IsPolarisEventSeries"  = $isPolarisEventSeries
            "Location"          = $location
            "EffectiveThroughput"   = $effectiveThroughput
            "DataTransferred"   = $dataTransferred
            "LogicalSize"       = $logicalSize
            "OrganizationsID"     = $organizationsID
            "OrganizationsName" = $organizationsName
            "ClusterUuid"       = $clusterUuid
            "ClusterStatus"     = $clusterStatus
            "ClusterID"         = $clusterID
            "ClusterNameDetail" = $clusterNameDetail
            "ClusterStatusDetail"= $clusterStatusDetail
            "ClusterTimezone"   = $clusterTimezone
            "ClusterTypename"   = $clusterTypename
            "ActivityID"        = $activityID
            "ActivityMessage"   = $activityMessage
            "ActivityStatus"    = $activityStatus
            "ActivityTime"      = $activityTime
            "ActivitySeverity"  = $activitySeverity
            "ActivityLocation"  = $activityLocation
            "ActivityObjectName"= $activityObjectName
        }
    }
}

# Define the output CSV file path
$outputCsvPath = "/home/admin1/Desktop/GraphQL/FinalResult.csv"

# Export the flattened data to CSV
$flattenedData | Export-Csv -Path $outputCsvPath -NoTypeInformation

Write-Host "Data exported to CSV successfully!"

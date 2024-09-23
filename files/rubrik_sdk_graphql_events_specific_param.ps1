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


# Write the cluster data to the file
$clusterData | Out-File -FilePath "/home/admin1/Desktop/GraphQL/backup.txt" -Encoding utf8

# Define the path to the data file
$dataFilePath = "/home/admin1/Desktop/GraphQL/backup.txt"

# Read the content of the data file
$dataContent = Get-Content -Path $dataFilePath -Raw

# Split the content into individual stanzas based on blank lines
$entries = $dataContent -split "\r?\n\r?\n"

# Initialize an array to hold filtered results
$filteredEntries = @()

# Iterate over each entry and filter based on lastActivityType
foreach ($entry in $entries) {
    if ($entry -match "lastActivityType\s*:\s*") {
        $filteredEntries += $entry
    }
}

# Output the filtered entries
$filteredEntries -join "`r`n`r`n" | Out-File -FilePath "/home/admin1/Desktop/GraphQL/filtered_data.txt"


# Define the path to your input and output files
$inputFilePath = "/home/admin1/Desktop/GraphQL/filtered_data.txt"
$outputFilePath = "/home/admin1/Desktop/GraphQL/filtered_data.csv"

# Initialize an array to hold the data
$dataList = @()
$allKeys = @{}

# Read the content of the text file
$content = Get-Content $inputFilePath -Raw

# Split the content into individual entries based on double newlines
$entries = $content -split "\r?\n\r?\n"

foreach ($entry in $entries) {
    # Create an ordered dictionary to hold key-value pairs for the current entry
    $dataItem = [ordered]@{}

    # Split the entry into lines
    $lines = $entry -split "\r?\n"

    foreach ($line in $lines) {
        # Split the line into key and value based on the first colon
        if ($line -match '^(.*?):\s*(.*)$') {
            $key = $matches[1].Trim()
            $value = $matches[2].Trim()
            $dataItem[$key] = $value

            # Collect all unique keys
            if (-not $allKeys.ContainsKey($key)) {
                $allKeys[$key] = $true
            }
        }
    }

    # Add the current data item to the list
    if ($dataItem.Count -gt 0) {
        $dataList += New-Object PSObject -Property $dataItem
    }
}

# Create an empty hashtable for each item to ensure all keys are present
foreach ($item in $dataList) {
    foreach ($key in $allKeys.Keys) {
        if (-not $item.PSObject.Properties[$key]) {
            $item | Add-Member -MemberType NoteProperty -Name $key -Value $null
        }
    }
}

# Export the collected data to a CSV file
$dataList | Export-Csv -Path $outputFilePath -NoTypeInformation

Write-Output "Data exported to $outputFilePath successfully."
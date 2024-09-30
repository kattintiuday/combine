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
        "name" = @("time")
        "values" = @{
            "start" = "2024-08-10T18:30:00.000Z"
            "end" = "2024-09-30T18:29:59.999Z"
        }
    }
    "sortBy" = $null
    "sortOrder" = $null
  }

$clusterData = Invoke-RubrikGQLQuery -payload $query -variables $variables -pathToData "data.reportTableData.edges.node"
#Write-Output $clusterData

# Define the path for the raw data output file
$rawDataFilePath = "/home/admin1/Desktop/GraphQL/raw_cluster_data.json"

# Convert the raw data to JSON format and write it to the file
$clusterData | ConvertTo-Json -Depth 100 | Out-File -FilePath $rawDataFilePath -Encoding utf8

Write-Output "Raw data written to $rawDataFilePath successfully."

# Path to the JSON file
$jsonFilePath = "C:\Users\UdayKumarKattinti\Desktop\Graphql\raw_cluster_data.json"
